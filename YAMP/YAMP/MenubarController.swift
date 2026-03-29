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

        statusItem.button?.title = "♪"
        statusItem.button?.font = NSFont.systemFont(ofSize: 13)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp])
    }

    func update(with track: Track) {
        let maxLen = Settings.shared.maxDisplayLength
        let showIcon = track.title.isEmpty || (!track.isPlaying && Settings.shared.hideTrackOnPause)
        let newDisplay = showIcon ? "♪" : "\(track.truncatedDisplay(maxLength: maxLen))"
        if statusItem.button?.title != newDisplay {
            statusItem.button?.title = newDisplay
        }
        currentTrack = track
        popoverView.update(with: track)
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

    // MARK: - CDP commands

    private func cdpCommand(_ cmd: String) {
        DispatchQueue.global().async {
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
        case .like: cdpCommand("like")
        case .dislike: cdpCommand("dislike")
        }
    }

    // MARK: - NowPlayingPopoverDelegate

    func didTapPlayPause() { cdpCommand("play") }
    func didTapNext() { cdpCommand("next") }
    func didTapPrev() { cdpCommand("prev") }
    func didTapLike() { cdpCommand("like") }
    func didTapSettings() {
        popover.performClose(nil)
        settingsWindow.show()
    }
}
