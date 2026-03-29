import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menubarController: MenubarController!
    private var trackProvider: NowPlayingTrackProvider!
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        trackProvider = NowPlayingTrackProvider()
        menubarController = MenubarController()

        HotkeyManager.shared.onAction = { [weak self] action in
            self?.menubarController.handleHotkeyAction(action)
        }
        HotkeyManager.shared.registerAll()

        // Cmd+Q to quit
        let quitItem = NSMenuItem(title: "Quit YAMP", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appMenu = NSMenu()
        appMenu.addItem(quitItem)
        let menuBarItem = NSMenuItem()
        menuBarItem.submenu = appMenu
        let mainMenu = NSMenu()
        mainMenu.addItem(menuBarItem)
        NSApp.mainMenu = mainMenu

        startPolling()
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateTrack()
        }
    }

    private func updateTrack() {
        trackProvider.getCurrentTrack { [weak self] track in
            DispatchQueue.main.async {
                self?.menubarController.update(with: track)
            }
        }
    }
}
