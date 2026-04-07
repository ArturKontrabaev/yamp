import Cocoa

class MenubarController: NSObject, NowPlayingPopoverDelegate {
    private let statusItem: NSStatusItem
    private var currentTrack: Track = .empty
    private let popover = NSPopover()
    private let popoverView: NowPlayingPopover
    private var eventMonitor: Any?
    private let settingsWindow = SettingsWindow()

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popoverView = NowPlayingPopover(frame: NSRect(x: 0, y: 0, width: 296, height: 100))
        super.init()

        popoverView.delegate = self

        let vc = NSViewController()
        vc.view = popoverView
        popover.contentViewController = vc
        popover.contentSize = NSSize(width: 296, height: 100)
        popover.behavior = .transient
        popover.animates = true

        statusItem.button?.font = NSFont.systemFont(ofSize: 13)
        applyIcon()
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp])

        NotificationCenter.default.addObserver(forName: NSNotification.Name("YAMPIconChanged"), object: nil, queue: .main) { [weak self] _ in
            self?.applyIcon()
        }

    }

    func applyIcon() {
        let iconId = Settings.shared.menuBarIcon
        let opt = Settings.iconOptions.first { $0.id == iconId } ?? Settings.iconOptions[0]
        let iconSize = CGFloat(Settings.shared.menuBarIconSize)
        if opt.isSFSymbol {
            let config = NSImage.SymbolConfiguration(pointSize: iconSize, weight: .regular)
            let img = NSImage(systemSymbolName: opt.id, accessibilityDescription: "YAMP")?.withSymbolConfiguration(config)
            img?.isTemplate = true
            statusItem.button?.image = img
            statusItem.button?.imagePosition = .imageLeading
            statusItem.button?.title = ""
        } else {
            statusItem.button?.image = nil
            statusItem.button?.title = opt.id
        }
    }

    func update(with track: Track) {
        currentTrack = track
        popoverView.update(with: track)

        let maxLen = Settings.shared.maxDisplayLength
        let showIcon = track.title.isEmpty || (!track.isPlaying && Settings.shared.hideTrackOnPause)

        let iconId = Settings.shared.menuBarIcon
        let opt = Settings.iconOptions.first { $0.id == iconId } ?? Settings.iconOptions[0]
        let fontSize = CGFloat(Settings.shared.menuBarFontSize)
        let iconSize = CGFloat(Settings.shared.menuBarIconSize)

        if opt.isSFSymbol {
            let config = NSImage.SymbolConfiguration(pointSize: iconSize, weight: .regular)
            let img = NSImage(systemSymbolName: opt.id, accessibilityDescription: "YAMP")?.withSymbolConfiguration(config)
            img?.isTemplate = true
            statusItem.button?.image = img
            statusItem.button?.imagePosition = .imageLeading
        } else {
            statusItem.button?.image = nil
        }

        if showIcon {
            if !opt.isSFSymbol {
                statusItem.button?.title = opt.id
            } else {
                statusItem.button?.title = ""
            }
        } else {
            statusItem.button?.title = track.truncatedDisplay(maxLength: maxLen)
        }
        statusItem.button?.font = NSFont.systemFont(ofSize: fontSize, weight: .regular)
    }

    @objc private func statusItemClicked() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            guard let button = statusItem.button else { return }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.popover.performClose(nil)
                if let m = self?.eventMonitor { NSEvent.removeMonitor(m); self?.eventMonitor = nil }
            }
        }
    }

    // MARK: - Notifications

    private func sendNotification(_ body: String) {
        DispatchQueue.global().async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", "display notification \"\(body)\" with title \"YAMP\""]
            try? process.run()
        }
    }

    // MARK: - CDP commands

    private func cdpCommand(_ cmd: String) {
        DispatchQueue.global().async {
            // Check if CDP is available
            let cdpAvailable: Bool
            if let url = URL(string: "http://localhost:9222/json"),
               let data = try? Data(contentsOf: url),
               !data.isEmpty {
                cdpAvailable = true
            } else {
                cdpAvailable = false
            }

            if !cdpAvailable {
                // Launch Yandex Music with CDP
                let launch = Process()
                launch.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                launch.arguments = ["-a", "Яндекс Музыка", "--args", "--remote-debugging-port=9222"]
                try? launch.run()

                // Wait for CDP
                for _ in 0..<10 {
                    Thread.sleep(forTimeInterval: 1.0)
                    if let url = URL(string: "http://localhost:9222/json"),
                       let _ = try? Data(contentsOf: url) {
                        break
                    }
                }
            }

            let scriptPath = NSHomeDirectory() + "/yamp/cdp_click.py"
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["python3", scriptPath, cmd]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try? process.run()
        }
    }

    // MARK: - Hotkeys

    func handleHotkeyAction(_ action: HotkeyManager.Action) {
        switch action {
        case .playPause: cdpCommand("play")
        case .next: cdpCommand("next")
        case .prev: cdpCommand("prev")
        case .like:
            cdpCommand("like")
            sendNotification("♥ Добавлено в избранное")
        case .dislike:
            cdpCommand("dislike")
            sendNotification("👎 Дизлайк")
        }
    }

    // MARK: - NowPlayingPopoverDelegate

    func didTapPlayPause() { cdpCommand("play") }
    func didTapNext() { cdpCommand("next") }
    func didTapPrev() { cdpCommand("prev") }
    func didTapLike() {
        cdpCommand("like")
        sendNotification("♥ Добавлено в избранное")
    }
    func didTapSettings() {
        popover.performClose(nil)
        settingsWindow.show()
    }
}
