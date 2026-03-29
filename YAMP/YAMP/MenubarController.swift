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
        sendMediaKey(keyCode: 16) // NX_KEYTYPE_PLAY
    }

    @objc private func nextTrack() {
        sendMediaKey(keyCode: 17) // NX_KEYTYPE_NEXT
    }

    @objc private func prevTrack() {
        sendMediaKey(keyCode: 18) // NX_KEYTYPE_PREVIOUS
    }

    private func sendMediaKey(keyCode: UInt32) {
        // Key down
        let keyDown = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xa00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyCode << 16) | (0xa << 8)),
            data2: -1
        )
        // Key up
        let keyUp = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xb00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyCode << 16) | (0xb << 8)),
            data2: -1
        )
        if let e = keyDown { CGEvent(event: e)?.post(tap: .cghidEventTap) }
        if let e = keyUp { CGEvent(event: e)?.post(tap: .cghidEventTap) }
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

