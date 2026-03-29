import Cocoa

class MenubarController: NSObject, NowPlayingPopoverDelegate {
    private let statusItem: NSStatusItem
    private var currentTrack: Track = .empty
    private let popover = NSPopover()
    private let popoverView: NowPlayingPopover
    private var eventMonitor: Any?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popoverView = NowPlayingPopover(frame: NSRect(x: 0, y: 0, width: 296, height: 128))
        super.init()

        popoverView.delegate = self

        let viewController = NSViewController()
        viewController.view = popoverView
        popover.contentViewController = viewController
        popover.contentSize = NSSize(width: 296, height: 128)
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

        let menu = NSMenu()

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

        let openItem = NSMenuItem(title: "Open Yandex Music", action: #selector(openYandexMusic), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit YAMP", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.statusItem.menu = nil
        }
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
