import Cocoa

class MenubarController: NSObject {
    private let statusItem: NSStatusItem
    private var currentTrack: Track = .empty

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        statusItem.button?.title = "♪"
        statusItem.button?.font = NSFont.systemFont(ofSize: 13)
        buildMenu()
    }

    func update(with track: Track) {
        let maxLen = Settings.shared.maxDisplayLength
        let newDisplay = track.title.isEmpty ? "♪" : "\(track.truncatedDisplay(maxLength: maxLen))"
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

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func cdpClick(ariaLabel: String) {
        DispatchQueue.global().async {
            let js = "document.querySelector('[class*=\"PlayerBarDesktop\"] [aria-label=\"\(ariaLabel)\"]')?.click()"
            let scriptPath = NSHomeDirectory() + "/yamp/cdp_click.py"

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["python3", scriptPath, js]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try? process.run()
        }
    }

    @objc private func togglePlayPause() {
        DispatchQueue.global().async {
            let js = "(document.querySelector('[class*=\"PlayerBarDesktop\"] [aria-label=\"Playback\"]') || document.querySelector('[class*=\"PlayerBarDesktop\"] [aria-label=\"Pause\"]'))?.click()"
            let scriptPath = NSHomeDirectory() + "/yamp/cdp_click.py"
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["python3", scriptPath, js]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try? process.run()
        }
    }

    @objc private func nextTrack() { cdpClick(ariaLabel: "Next song") }
    @objc private func prevTrack() { cdpClick(ariaLabel: "Previous song") }
    @objc private func likeTrack() { cdpClick(ariaLabel: "Like") }

    @objc private func quit() { NSApp.terminate(nil) }
}
