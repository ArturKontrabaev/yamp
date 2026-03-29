import Cocoa

class MenubarController {
    private let statusItem: NSStatusItem
    private var currentTrack: Track = .empty

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "♪"
        statusItem.button?.font = NSFont.systemFont(ofSize: 13)
        buildMenu()
    }

    func update(with track: Track) {
        let maxLen = Settings.shared.maxDisplayLength
        let newDisplay = track.title.isEmpty ? "♪" : "⏵ \(track.truncatedDisplay(maxLength: maxLen))"
        if statusItem.button?.title != newDisplay {
            statusItem.button?.title = newDisplay
        }
        currentTrack = track
        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        if !currentTrack.title.isEmpty {
            let titleItem = NSMenuItem(title: currentTrack.menuTitle, action: nil, keyEquivalent: "")
            titleItem.isEnabled = false
            titleItem.attributedTitle = NSAttributedString(
                string: currentTrack.menuTitle,
                attributes: [.font: NSFont.boldSystemFont(ofSize: 14)]
            )
            menu.addItem(titleItem)

            let artistItem = NSMenuItem(title: currentTrack.menuArtist, action: nil, keyEquivalent: "")
            artistItem.isEnabled = false
            menu.addItem(artistItem)

            menu.addItem(NSMenuItem.separator())
        }

        // Playback controls — always visible
        let playPause = NSMenuItem(title: "⏵⏸  Play / Pause", action: #selector(togglePlayPause), keyEquivalent: " ")
        playPause.target = self
        menu.addItem(playPause)

        let next = NSMenuItem(title: "⏭  Next", action: #selector(nextTrack), keyEquivalent: "n")
        next.target = self
        menu.addItem(next)

        let prev = NSMenuItem(title: "⏮  Previous", action: #selector(prevTrack), keyEquivalent: "p")
        prev.target = self
        menu.addItem(prev)

        menu.addItem(NSMenuItem.separator())

        let openItem = NSMenuItem(title: "Open Yandex Music", action: #selector(openYandexMusic), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        // Settings submenu
        let settingsItem = NSMenuItem(title: "Max length: \(Settings.shared.maxDisplayLength)", action: nil, keyEquivalent: "")
        let settingsMenu = NSMenu()
        for len in [15, 20, 25, 30, 40, 50] {
            let item = NSMenuItem(title: "\(len) chars", action: #selector(setMaxLength(_:)), keyEquivalent: "")
            item.target = self
            item.tag = len
            if len == Settings.shared.maxDisplayLength {
                item.state = .on
            }
            settingsMenu.addItem(item)
        }
        settingsItem.submenu = settingsMenu
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        self.statusItem.menu = menu
    }

    // MARK: - Playback controls via CDP

    @objc private func togglePlayPause() {
        CDPCommand.execute(js: "document.querySelector('[class*=\"PlayerBarDesktop\"] button[class*=\"Play\"]')?.click()")
    }

    @objc private func nextTrack() {
        CDPCommand.execute(js: "document.querySelector('[class*=\"PlayerBarDesktop\"] button[title*=\"Следующ\"], [class*=\"PlayerBarDesktop\"] button[title*=\"Next\"], [class*=\"ControlButton\"][title*=\"Следующ\"], [class*=\"ControlButton\"][title*=\"Next\"]')?.click()")
    }

    @objc private func prevTrack() {
        CDPCommand.execute(js: "document.querySelector('[class*=\"PlayerBarDesktop\"] button[title*=\"Предыдущ\"], [class*=\"PlayerBarDesktop\"] button[title*=\"Prev\"], [class*=\"ControlButton\"][title*=\"Предыдущ\"], [class*=\"ControlButton\"][title*=\"Prev\"]')?.click()")
    }

    @objc private func setMaxLength(_ sender: NSMenuItem) {
        Settings.shared.maxDisplayLength = sender.tag
        update(with: currentTrack)
    }

    @objc private func openYandexMusic() {
        let bundleId = "ru.yandex.desktop.music"
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
        } else {
            if let webUrl = URL(string: "https://music.yandex.ru") {
                NSWorkspace.shared.open(webUrl)
            }
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

// Helper to send commands to Yandex Music via CDP
class CDPCommand {
    static func execute(js: String) {
        guard let url = URL(string: "http://localhost:9222/json") else { return }
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let pages = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }

            for page in pages {
                guard let type = page["type"] as? String, type == "page",
                      let pageUrl = page["url"] as? String, pageUrl.contains("music"),
                      let pageId = page["id"] as? String else { continue }

                // Fire and forget via HTTP
                let wsUrl = "ws://localhost:9222/devtools/page/\(pageId)"
                DispatchQueue.global().async {
                    guard let url = URL(string: wsUrl),
                          let host = url.host, let port = url.port else { return }

                    let sock = socket(AF_INET, SOCK_STREAM, 0)
                    guard sock >= 0 else { return }

                    var addr = sockaddr_in()
                    addr.sin_family = sa_family_t(AF_INET)
                    addr.sin_port = in_port_t(port).bigEndian
                    guard let hostEntry = gethostbyname(host) else { close(sock); return }
                    memcpy(&addr.sin_addr, hostEntry.pointee.h_addr_list[0], Int(hostEntry.pointee.h_length))

                    let connected = withUnsafePointer(to: &addr) {
                        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
                    }
                    guard connected == 0 else { close(sock); return }

                    let fh = FileHandle(fileDescriptor: sock, closeOnDealloc: true)

                    var keyBytes = [UInt8](repeating: 0, count: 16)
                    _ = SecRandomCopyBytes(kSecRandomDefault, 16, &keyBytes)
                    let key = Data(keyBytes).base64EncodedString()
                    let path = url.path

                    let handshake = "GET \(path) HTTP/1.1\r\nHost: \(host):\(port)\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: \(key)\r\nSec-WebSocket-Version: 13\r\n\r\n"
                    fh.write(handshake.data(using: .utf8)!)

                    var headers = Data()
                    let endMarker = "\r\n\r\n".data(using: .utf8)!
                    while !headers.contains(endMarker) {
                        let chunk = fh.readData(ofLength: 1)
                        if chunk.isEmpty { break }
                        headers.append(chunk)
                    }

                    let msg: [String: Any] = ["id": 1, "method": "Runtime.evaluate", "params": ["expression": js, "returnByValue": true] as [String: Any]]
                    guard let msgData = try? JSONSerialization.data(withJSONObject: msg),
                          let msgStr = String(data: msgData, encoding: .utf8) else { try? fh.close(); return }

                    let payload = Array(msgStr.utf8)
                    var frame = Data([0x81])
                    var maskKey = [UInt8](repeating: 0, count: 4)
                    _ = SecRandomCopyBytes(kSecRandomDefault, 4, &maskKey)
                    if payload.count < 126 { frame.append(UInt8(0x80 | payload.count)) }
                    else { frame.append(0xFE); frame.append(UInt8((payload.count >> 8) & 0xFF)); frame.append(UInt8(payload.count & 0xFF)) }
                    frame.append(contentsOf: maskKey)
                    frame.append(contentsOf: payload.enumerated().map { $0.element ^ maskKey[$0.offset % 4] })
                    fh.write(frame)

                    try? fh.close()
                }
                break
            }
        }
        task.resume()
    }
}

private extension Data {
    func contains(_ other: Data) -> Bool {
        guard other.count <= self.count else { return false }
        return self.range(of: other) != nil
    }
}
