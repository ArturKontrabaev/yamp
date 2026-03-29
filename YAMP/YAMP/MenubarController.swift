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

        // Expanded zone: button + panel + gap between them
        var isInZone = isInButton
        if let panel = controlsPanel {
            let panelFrame = panel.frame
            // Union of button, panel, and the gap between
            let combined = buttonFrame.union(panelFrame).insetBy(dx: -5, dy: -5)
            isInZone = combined.contains(mouseLocation)
        }

        if isInButton && !isHovering {
            isHovering = true
            hideTimer?.invalidate()
            showControlsPanel()
        } else if !isInZone && isHovering {
            hideTimer?.invalidate()
            hideTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                self?.isHovering = false
                self?.hideControlsPanel()
            }
        } else if isInZone {
            hideTimer?.invalidate()
        }
    }

    private func showControlsPanel() {
        if controlsPanel != nil { return }

        guard let button = statusItem.button,
              let buttonWindow = button.window else { return }

        let buttonFrame = buttonWindow.frame

        let panelWidth: CGFloat = 130
        let panelHeight: CGFloat = 32
        let panelX = buttonFrame.midX - panelWidth / 2
        let panelY = buttonFrame.minY - panelHeight

        let panel = NSPanel(
            contentRect: NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.acceptsMouseMovedEvents = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.worksWhenModal = true
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.hasShadow = true
        panel.isOpaque = false

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))

        let prevBtn = makeButton(title: "⏮", x: 5, action: #selector(prevTrack))
        let playBtn = makeButton(title: "⏵⏸", x: 35, action: #selector(togglePlayPause))
        let nextBtn = makeButton(title: "⏭", x: 65, action: #selector(nextTrack))
        let likeBtn = makeButton(title: "♡", x: 95, action: #selector(likeTrack))

        contentView.addSubview(prevBtn)
        contentView.addSubview(playBtn)
        contentView.addSubview(nextBtn)
        contentView.addSubview(likeBtn)

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
        btn.bezelStyle = .recessed
        btn.isBordered = true
        btn.font = NSFont.systemFont(ofSize: 14)
        btn.target = self
        btn.action = action
        btn.focusRingType = .none
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

        let like = NSMenuItem(title: "♡  Like", action: #selector(likeTrack), keyEquivalent: "l")
        like.target = self
        menu.addItem(like)

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
        CDPConnection.shared.evaluate(js: "(document.querySelector('[aria-label=\"Playback\"]') || document.querySelector('[aria-label=\"Pause\"]'))?.click()") { _ in }
    }

    @objc private func nextTrack() {
        CDPConnection.shared.evaluate(js: "document.querySelector('[aria-label=\"Next song\"]')?.click()") { _ in }
    }

    @objc private func prevTrack() {
        CDPConnection.shared.evaluate(js: "document.querySelector('[aria-label=\"Previous song\"]')?.click()") { _ in }
    }

    @objc private func likeTrack() {
        CDPConnection.shared.evaluate(js: "document.querySelector('[aria-label=\"Like\"]')?.click()") { _ in }
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
        CDPConnection.shared.evaluate(js: js) { [weak self] result in
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

