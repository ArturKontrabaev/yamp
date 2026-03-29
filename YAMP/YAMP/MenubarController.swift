import Cocoa

class MenubarController: NSObject {
    private let statusItem: NSStatusItem
    private var currentTrack: Track = .empty
    private var controlsPanel: NSPanel?
    private var trackingArea: NSTrackingArea?
    private var hideTimer: Timer?
    private var isHovering = false

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        statusItem.button?.title = "♪"
        statusItem.button?.font = NSFont.systemFont(ofSize: 13)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp])

        setupTracking()
    }

    func update(with track: Track) {
        let maxLen = Settings.shared.maxDisplayLength
        let newDisplay = track.title.isEmpty ? "♪" : "\(track.truncatedDisplay(maxLength: maxLen))"
        if statusItem.button?.title != newDisplay {
            statusItem.button?.title = newDisplay
        }
        currentTrack = track
    }

    // MARK: - Hover tracking

    private func setupTracking() {
        guard let button = statusItem.button else { return }

        // Monitor mouse events globally for hover
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMove(event)
        }
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMove(event)
            return event
        }
    }

    private func handleMouseMove(_ event: NSEvent) {
        guard let button = statusItem.button,
              let buttonWindow = button.window else { return }

        let buttonFrame = buttonWindow.frame
        let mouseLocation = NSEvent.mouseLocation

        let isInButton = buttonFrame.contains(mouseLocation)

        if isInButton && !isHovering {
            isHovering = true
            hideTimer?.invalidate()
            showControlsPanel()
        } else if !isInButton && isHovering {
            // Check if mouse is in the controls panel
            if let panel = controlsPanel, panel.frame.contains(mouseLocation) {
                return
            }
            hideTimer?.invalidate()
            hideTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                self?.isHovering = false
                self?.hideControlsPanel()
            }
        }
    }

    private func showControlsPanel() {
        if controlsPanel != nil { return }

        guard let button = statusItem.button,
              let buttonWindow = button.window else { return }

        let buttonFrame = buttonWindow.frame

        let panelWidth: CGFloat = 100
        let panelHeight: CGFloat = 32
        let panelX = buttonFrame.midX - panelWidth / 2
        let panelY = buttonFrame.minY - panelHeight - 2

        let panel = NSPanel(
            contentRect: NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.hasShadow = true
        panel.isOpaque = false

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))

        let prevBtn = makeButton(title: "⏮", x: 5, action: #selector(prevTrack))
        let playBtn = makeButton(title: "⏵⏸", x: 35, action: #selector(togglePlayPause))
        let nextBtn = makeButton(title: "⏭", x: 70, action: #selector(nextTrack))

        contentView.addSubview(prevBtn)
        contentView.addSubview(playBtn)
        contentView.addSubview(nextBtn)

        panel.contentView = contentView

        // Track mouse exit on panel
        let area = NSTrackingArea(
            rect: contentView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: ["panel": true as Any]
        )
        contentView.addTrackingArea(area)

        panel.orderFront(nil)
        controlsPanel = panel
    }

    private func makeButton(title: String, x: CGFloat, action: Selector) -> NSButton {
        let btn = NSButton(frame: NSRect(x: x, y: 2, width: 28, height: 28))
        btn.title = title
        btn.bezelStyle = .inline
        btn.isBordered = false
        btn.font = NSFont.systemFont(ofSize: 14)
        btn.target = self
        btn.action = action
        return btn
    }

    private func hideControlsPanel() {
        controlsPanel?.orderOut(nil)
        controlsPanel = nil
    }

    func handleMouseExited() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.isHovering = false
            self?.hideControlsPanel()
        }
    }

    // MARK: - Click → Popover with lyrics + settings

    @objc private func statusItemClicked() {
        hideControlsPanel()
        isHovering = false

        let menu = NSMenu()

        // Track info
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

        // Controls
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

        // Lyrics
        let lyricsItem = NSMenuItem(title: "Show Lyrics", action: #selector(showLyrics), keyEquivalent: "l")
        lyricsItem.target = self
        menu.addItem(lyricsItem)

        menu.addItem(NSMenuItem.separator())

        // Open Yandex Music
        let openItem = NSMenuItem(title: "Open Yandex Music", action: #selector(openYandexMusic), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

        // Settings
        let settingsItem = NSMenuItem(title: "Max length: \(Settings.shared.maxDisplayLength)", action: nil, keyEquivalent: "")
        let settingsMenu = NSMenu()
        for len in [15, 20, 25, 30, 40, 50] {
            let item = NSMenuItem(title: "\(len) chars", action: #selector(setMaxLength(_:)), keyEquivalent: "")
            item.target = self
            item.tag = len
            if len == Settings.shared.maxDisplayLength { item.state = .on }
            settingsMenu.addItem(item)
        }
        settingsItem.submenu = settingsMenu
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Reset menu so next click goes through action again
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    // MARK: - Actions

    @objc private func togglePlayPause() {
        sendMediaKey(keyCode: 16)
    }

    @objc private func nextTrack() {
        sendMediaKey(keyCode: 17)
    }

    @objc private func prevTrack() {
        sendMediaKey(keyCode: 18)
    }

    private func sendMediaKey(keyCode: UInt32) {
        func postSystemEvent(keyDown: Bool) {
            let flags: UInt32 = keyDown ? 0xa : 0xb
            let data1 = Int((keyCode << 16) | (flags << 8))
            let modFlags = NSEvent.ModifierFlags(rawValue: UInt(flags) << 8)

            guard let event = NSEvent.otherEvent(
                with: .systemDefined, location: .zero,
                modifierFlags: modFlags,
                timestamp: 0, windowNumber: 0, context: nil,
                subtype: 8, data1: data1, data2: -1
            ) else { return }

            let cgEvent = event.cgEvent
            cgEvent?.post(tap: .cghidEventTap)
        }
        postSystemEvent(keyDown: true)
        postSystemEvent(keyDown: false)
    }

    @objc private func showLyrics() {
        // Get lyrics from Yandex Music via CDP
        let js = """
        (function() {
            var el = document.querySelector('[class*="Lyrics"]')
                || document.querySelector('[class*="lyrics"]');
            if (el) return el.innerText.substring(0, 2000);
            return 'NO_LYRICS';
        })()
        """
        CDPEval.run(js: js) { [weak self] result in
            DispatchQueue.main.async {
                let text = result.isEmpty || result == "NO_LYRICS"
                    ? "Lyrics not available for this track"
                    : result
                self?.showLyricsWindow(text: text)
            }
        }
    }

    private func showLyricsWindow(text: String) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "\(currentTrack.menuArtist) — \(currentTrack.menuTitle)"
        panel.center()

        let scroll = NSScrollView(frame: panel.contentView!.bounds)
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true

        let textView = NSTextView(frame: scroll.bounds)
        textView.isEditable = false
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.string = text
        textView.autoresizingMask = [.width]

        scroll.documentView = textView
        panel.contentView?.addSubview(scroll)
        panel.makeKeyAndOrderFront(nil)
    }

    @objc private func setMaxLength(_ sender: NSMenuItem) {
        Settings.shared.maxDisplayLength = sender.tag
        update(with: currentTrack)
    }

    @objc private func openYandexMusic() {
        let bundleId = "ru.yandex.desktop.music"
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
        } else if let webUrl = URL(string: "https://music.yandex.ru") {
            NSWorkspace.shared.open(webUrl)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

// MARK: - CDP helper for one-off JS evaluation

class CDPEval {
    static func run(js: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "http://localhost:9222/json") else {
            completion("")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let pages = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                completion("")
                return
            }

            var pageId: String?
            for p in pages {
                if p["type"] as? String == "page", (p["url"] as? String ?? "").contains("music") {
                    pageId = p["id"] as? String
                    break
                }
            }

            guard let id = pageId else { completion(""); return }

            DispatchQueue.global().async {
                let wsUrl = "ws://localhost:9222/devtools/page/\(id)"
                guard let url = URL(string: wsUrl), let host = url.host, let port = url.port else {
                    completion("")
                    return
                }

                let sock = socket(AF_INET, SOCK_STREAM, 0)
                guard sock >= 0 else { completion(""); return }

                var addr = sockaddr_in()
                addr.sin_family = sa_family_t(AF_INET)
                addr.sin_port = in_port_t(port).bigEndian
                guard let he = gethostbyname(host) else { close(sock); completion(""); return }
                memcpy(&addr.sin_addr, he.pointee.h_addr_list[0], Int(he.pointee.h_length))

                let c = withUnsafePointer(to: &addr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
                }
                guard c == 0 else { close(sock); completion(""); return }

                let fh = FileHandle(fileDescriptor: sock, closeOnDealloc: true)

                var kb = [UInt8](repeating: 0, count: 16)
                _ = SecRandomCopyBytes(kSecRandomDefault, 16, &kb)
                let key = Data(kb).base64EncodedString()
                let path = url.path
                fh.write("GET \(path) HTTP/1.1\r\nHost: \(host):\(port)\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: \(key)\r\nSec-WebSocket-Version: 13\r\n\r\n".data(using: .utf8)!)

                var hdr = Data()
                while !hdr.contains("\r\n\r\n".data(using: .utf8)!) {
                    let ch = fh.readData(ofLength: 1)
                    if ch.isEmpty { break }
                    hdr.append(ch)
                }

                let msg: [String: Any] = ["id": 1, "method": "Runtime.evaluate", "params": ["expression": js, "returnByValue": true] as [String: Any]]
                guard let md = try? JSONSerialization.data(withJSONObject: msg), let ms = String(data: md, encoding: .utf8) else {
                    try? fh.close(); completion(""); return
                }

                let pl = Array(ms.utf8)
                var fr = Data([0x81])
                var mk = [UInt8](repeating: 0, count: 4)
                _ = SecRandomCopyBytes(kSecRandomDefault, 4, &mk)
                if pl.count < 126 { fr.append(UInt8(0x80 | pl.count)) }
                else { fr.append(0xFE); fr.append(UInt8((pl.count >> 8) & 0xFF)); fr.append(UInt8(pl.count & 0xFF)) }
                fr.append(contentsOf: mk)
                fr.append(contentsOf: pl.enumerated().map { $0.element ^ mk[$0.offset % 4] })
                fh.write(fr)

                // Read response
                let rh = fh.readData(ofLength: 2)
                guard rh.count == 2 else { try? fh.close(); completion(""); return }
                var len = Int(rh[1] & 0x7F)
                if len == 126 { let ld = fh.readData(ofLength: 2); len = Int(ld[0]) << 8 | Int(ld[1]) }
                else if len == 127 { let ld = fh.readData(ofLength: 8); len = 0; for i in 0..<8 { len = (len << 8) | Int(ld[i]) } }
                var rd = Data()
                while rd.count < len { let ch = fh.readData(ofLength: len - rd.count); if ch.isEmpty { break }; rd.append(ch) }
                try? fh.close()

                guard let _ = String(data: rd, encoding: .utf8),
                      let ro = try? JSONSerialization.jsonObject(with: rd) as? [String: Any],
                      let rr = ro["result"] as? [String: Any],
                      let ri = rr["result"] as? [String: Any],
                      let rv = ri["value"] as? String else {
                    completion("")
                    return
                }
                completion(rv)
            }
        }.resume()
    }
}

private extension Data {
    func contains(_ other: Data) -> Bool {
        guard other.count <= self.count else { return false }
        return self.range(of: other) != nil
    }
}
