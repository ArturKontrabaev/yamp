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
        popoverView = NowPlayingPopover(frame: NSRect(x: 0, y: 0, width: 296, height: 148))
        super.init()

        popoverView.delegate = self

        let viewController = NSViewController()
        viewController.view = popoverView
        popover.contentViewController = viewController
        popover.contentSize = NSSize(width: 296, height: 148)
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
        let newDisplay = track.title.isEmpty ? "♪" : "\(track.truncatedDisplay(maxLength: maxLen))"
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

            // Close when clicking outside
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.popover.performClose(nil)
                if let monitor = self?.eventMonitor {
                    NSEvent.removeMonitor(monitor)
                    self?.eventMonitor = nil
                }
            }
        }
    }

    // MARK: - NowPlayingPopoverDelegate

    func didTapPlayPause() {
        CDPConnection.shared.evaluate(js: "(document.querySelector('[class*=\"PlayerBarDesktop\"] [aria-label=\"Playback\"]') || document.querySelector('[class*=\"PlayerBarDesktop\"] [aria-label=\"Pause\"]'))?.click()") { _ in }
    }

    func didTapNext() {
        CDPConnection.shared.evaluate(js: "document.querySelector('[class*=\"PlayerBarDesktop\"] [aria-label=\"Next song\"]')?.click()") { _ in }
    }

    func didTapPrev() {
        CDPConnection.shared.evaluate(js: "document.querySelector('[class*=\"PlayerBarDesktop\"] [aria-label=\"Previous song\"]')?.click()") { _ in }
    }

    func didTapLike() {
        CDPConnection.shared.evaluate(js: "document.querySelector('[class*=\"PlayerBarDesktop\"] [aria-label=\"Like\"]')?.click()") { _ in }
    }

    func didTapSettings() {
        popover.performClose(nil)
        settingsWindow.show()
    }
}
