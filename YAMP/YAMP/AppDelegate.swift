import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menubarController: MenubarController!
    private var trackProvider: NowPlayingTrackProvider!
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("YAMP: starting...")
        trackProvider = NowPlayingTrackProvider()
        print("YAMP: provider created")
        menubarController = MenubarController()
        print("YAMP: menubar created")
        startPolling()
        print("YAMP: polling started")
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
