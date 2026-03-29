import Foundation

class NowPlayingTrackProvider {
    private let cdpPort = 9222
    private var wsURL: String?
    private var pageId: String?

    func getCurrentTrack(completion: @escaping (Track) -> Void) {
        // Step 1: get WebSocket URL from CDP
        guard let url = URL(string: "http://localhost:\(cdpPort)/json") else {
            completion(.empty)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else {
                completion(.empty)
                return
            }

            guard let pages = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                completion(.empty)
                return
            }

            // Find the main music page
            var targetId: String?
            for page in pages {
                if let type = page["type"] as? String,
                   let pageUrl = page["url"] as? String,
                   type == "page" && pageUrl.contains("music") {
                    targetId = page["id"] as? String
                    break
                }
            }

            guard let pageId = targetId else {
                completion(.empty)
                return
            }

            // Step 2: evaluate JS via HTTP endpoint (simpler than WebSocket)
            self.evaluateJS(pageId: pageId, completion: completion)
        }
        task.resume()
    }

    private func evaluateJS(pageId: String, completion: @escaping (Track) -> Void) {
        let js = """
        (function() {
            var title = '';
            var artist = '';
            var titleEl = document.querySelector('[class*="Meta_titleContainer"] a')
                || document.querySelector('[class*="PlayerBarDesktop"] [class*="Meta_albumLink"]');
            if (titleEl) {
                var ariaT = titleEl.getAttribute('aria-label') || '';
                if (ariaT.startsWith('Track ')) title = ariaT.substring(6);
                else title = titleEl.textContent.trim();
            }
            var artistEls = document.querySelectorAll('[class*="PlayerBarDesktop"] [class*="Meta_text"] [class*="Meta_link"]');
            if (artistEls.length > 0) {
                var ariaA = artistEls[0].getAttribute('aria-label') || '';
                if (ariaA.startsWith('Artist ')) artist = ariaA.substring(7);
                else artist = artistEls[0].textContent.trim();
            }
            var pauseBtn = document.querySelector('[aria-label="Pause"]');
            var playBtn = document.querySelector('[aria-label="Playback"]');
            var isPlaying = pauseBtn !== null && playBtn === null;
            return JSON.stringify({title: title, artist: artist, playing: isPlaying});
        })()
        """

        let jsEncoded = js.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = "http://localhost:\(cdpPort)/json/evaluate?pageId=\(pageId)&expression=\(jsEncoded)"

        // CDP doesn't have a simple HTTP evaluate endpoint, use WebSocket
        connectAndEvaluate(pageId: pageId, js: js, completion: completion)
    }

    private func connectAndEvaluate(pageId: String, js: String, completion: @escaping (Track) -> Void) {
        let wsURLString = "ws://localhost:\(cdpPort)/devtools/page/\(pageId)"

        DispatchQueue.global().async {
            guard let url = URL(string: wsURLString),
                  let host = url.host,
                  let port = url.port else {
                completion(.empty)
                return
            }

            let path = url.path
            guard let sock = self.wsConnect(host: host, port: port, path: path) else {
                completion(.empty)
                return
            }

            let msg: [String: Any] = [
                "id": 1,
                "method": "Runtime.evaluate",
                "params": ["expression": js, "returnByValue": true] as [String : Any]
            ]

            guard let msgData = try? JSONSerialization.data(withJSONObject: msg),
                  let msgStr = String(data: msgData, encoding: .utf8) else {
                try? sock.close()
                completion(.empty)
                return
            }

            self.wsSend(sock: sock, text: msgStr)
            let response = self.wsRecv(sock: sock)
            try? sock.close()

            guard let respData = response.data(using: .utf8),
                  let respObj = try? JSONSerialization.jsonObject(with: respData) as? [String: Any],
                  let result = respObj["result"] as? [String: Any],
                  let innerResult = result["result"] as? [String: Any],
                  let value = innerResult["value"] as? String,
                  let trackData = value.data(using: .utf8),
                  let trackObj = try? JSONSerialization.jsonObject(with: trackData) as? [String: Any] else {
                completion(.empty)
                return
            }

            let title = trackObj["title"] as? String ?? ""
            let artist = trackObj["artist"] as? String ?? ""
            let isPlaying = trackObj["playing"] as? Bool ?? false

            completion(Track(title: title, artist: artist, isPlaying: isPlaying))
        }
    }

    // MARK: - Minimal WebSocket client

    private func wsConnect(host: String, port: Int, path: String) -> FileHandle? {
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else { return nil }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(port).bigEndian

        guard let hostEntry = gethostbyname(host) else {
            close(sock)
            return nil
        }

        memcpy(&addr.sin_addr, hostEntry.pointee.h_addr_list[0], Int(hostEntry.pointee.h_length))

        let connectResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard connectResult == 0 else {
            close(sock)
            return nil
        }

        let fh = FileHandle(fileDescriptor: sock, closeOnDealloc: true)

        // Generate WebSocket key
        var keyBytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, 16, &keyBytes)
        let key = Data(keyBytes).base64EncodedString()

        let handshake = "GET \(path) HTTP/1.1\r\nHost: \(host):\(port)\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: \(key)\r\nSec-WebSocket-Version: 13\r\n\r\n"

        fh.write(handshake.data(using: .utf8)!)

        // Read response headers
        var headers = Data()
        let endMarker = "\r\n\r\n".data(using: .utf8)!
        while !headers.contains(endMarker) {
            let chunk = fh.readData(ofLength: 1)
            if chunk.isEmpty { break }
            headers.append(chunk)
        }

        return fh
    }

    private func wsSend(sock: FileHandle, text: String) {
        let payload = Array(text.utf8)
        var frame = Data()
        frame.append(0x81)

        var maskKey = [UInt8](repeating: 0, count: 4)
        _ = SecRandomCopyBytes(kSecRandomDefault, 4, &maskKey)

        if payload.count < 126 {
            frame.append(UInt8(0x80 | payload.count))
        } else if payload.count < 65536 {
            frame.append(0xFE)
            frame.append(UInt8((payload.count >> 8) & 0xFF))
            frame.append(UInt8(payload.count & 0xFF))
        }

        frame.append(contentsOf: maskKey)
        let masked = payload.enumerated().map { $0.element ^ maskKey[$0.offset % 4] }
        frame.append(contentsOf: masked)
        sock.write(frame)
    }

    private func wsRecv(sock: FileHandle) -> String {
        let header = sock.readData(ofLength: 2)
        guard header.count == 2 else { return "" }

        var length = Int(header[1] & 0x7F)
        if length == 126 {
            let lenData = sock.readData(ofLength: 2)
            length = Int(lenData[0]) << 8 | Int(lenData[1])
        } else if length == 127 {
            let lenData = sock.readData(ofLength: 8)
            length = 0
            for i in 0..<8 { length = (length << 8) | Int(lenData[i]) }
        }

        var data = Data()
        while data.count < length {
            let chunk = sock.readData(ofLength: length - data.count)
            if chunk.isEmpty { break }
            data.append(chunk)
        }

        return String(data: data, encoding: .utf8) ?? ""
    }
}

private extension Data {
    func contains(_ other: Data) -> Bool {
        guard other.count <= self.count else { return false }
        return self.range(of: other) != nil
    }
}
