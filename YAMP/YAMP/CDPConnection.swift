import Foundation

/// Single shared CDP connection — all operations go through serial queue
class CDPConnection {
    static let shared = CDPConnection()

    private let queue = DispatchQueue(label: "cdp.serial")
    private let port = 9222

    private init() {}

    func evaluate(js: String, completion: @escaping (String) -> Void) {
        queue.async { [self] in
            guard let pageId = self.getPageId() else {
                DispatchQueue.main.async { completion("") }
                return
            }

            let result = self.evalSync(pageId: pageId, js: js)
            DispatchQueue.main.async { completion(result) }
        }
    }

    private func getPageId() -> String? {
        guard let url = URL(string: "http://localhost:\(port)/json"),
              let data = try? Data(contentsOf: url),
              let pages = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }
        for p in pages {
            if p["type"] as? String == "page",
               (p["url"] as? String ?? "").contains("music") {
                return p["id"] as? String
            }
        }
        return nil
    }

    private func evalSync(pageId: String, js: String) -> String {
        let wsUrl = "ws://localhost:\(port)/devtools/page/\(pageId)"
        guard let url = URL(string: wsUrl),
              let host = url.host,
              let port = url.port else { return "" }

        let path = url.path
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else { return "" }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(port).bigEndian
        guard let he = gethostbyname(host) else { close(sock); return "" }
        memcpy(&addr.sin_addr, he.pointee.h_addr_list[0], Int(he.pointee.h_length))

        let c = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard c == 0 else { close(sock); return "" }

        let fh = FileHandle(fileDescriptor: sock, closeOnDealloc: true)

        // WebSocket handshake
        var kb = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, 16, &kb)
        let key = Data(kb).base64EncodedString()
        fh.write("GET \(path) HTTP/1.1\r\nHost: \(host):\(port)\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: \(key)\r\nSec-WebSocket-Version: 13\r\n\r\n".data(using: .utf8)!)

        var hdr = Data()
        let endMarker = "\r\n\r\n".data(using: .utf8)!
        while !hdr.containsSequence(endMarker) {
            let ch = fh.readData(ofLength: 1)
            if ch.isEmpty { break }
            hdr.append(ch)
        }

        // Send
        let msg: [String: Any] = ["id": 1, "method": "Runtime.evaluate", "params": ["expression": js, "returnByValue": true] as [String: Any]]
        guard let md = try? JSONSerialization.data(withJSONObject: msg),
              let ms = String(data: md, encoding: .utf8) else {
            try? fh.close(); return ""
        }
        wsSend(fh: fh, text: ms)

        // Receive
        let response = wsRecv(fh: fh)
        try? fh.close()

        guard let rd = response.data(using: .utf8),
              let ro = try? JSONSerialization.jsonObject(with: rd) as? [String: Any],
              let rr = ro["result"] as? [String: Any],
              let ri = rr["result"] as? [String: Any],
              let rv = ri["value"] as? String else {
            return ""
        }
        return rv
    }

    private func wsSend(fh: FileHandle, text: String) {
        let pl = Array(text.utf8)
        var fr = Data([0x81])
        var mk = [UInt8](repeating: 0, count: 4)
        _ = SecRandomCopyBytes(kSecRandomDefault, 4, &mk)
        if pl.count < 126 {
            fr.append(UInt8(0x80 | pl.count))
        } else {
            fr.append(0x80 | 126)
            fr.append(UInt8((pl.count >> 8) & 0xFF))
            fr.append(UInt8(pl.count & 0xFF))
        }
        fr.append(contentsOf: mk)
        fr.append(contentsOf: pl.enumerated().map { $0.element ^ mk[$0.offset % 4] })
        fh.write(fr)
    }

    private func wsRecv(fh: FileHandle) -> String {
        let rh = fh.readData(ofLength: 2)
        guard rh.count == 2 else { return "" }
        var len = Int(rh[1] & 0x7F)
        if len == 126 {
            let ld = fh.readData(ofLength: 2)
            len = Int(ld[0]) << 8 | Int(ld[1])
        } else if len == 127 {
            let ld = fh.readData(ofLength: 8)
            len = 0
            for i in 0..<8 { len = (len << 8) | Int(ld[i]) }
        }
        var rd = Data()
        while rd.count < len {
            let ch = fh.readData(ofLength: len - rd.count)
            if ch.isEmpty { break }
            rd.append(ch)
        }
        return String(data: rd, encoding: .utf8) ?? ""
    }
}

private extension Data {
    func containsSequence(_ other: Data) -> Bool {
        guard other.count <= self.count else { return false }
        return self.range(of: other) != nil
    }
}
