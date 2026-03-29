import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menubarController: MenubarController!
    private var trackProvider: NowPlayingTrackProvider!
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        ensureWrapper()
        ensureYandexMusicWithCDP()
        trackProvider = NowPlayingTrackProvider()
        menubarController = MenubarController()

        HotkeyManager.shared.onAction = { [weak self] action in
            self?.menubarController.handleHotkeyAction(action)
        }
        HotkeyManager.shared.registerAll()


        startPolling()
    }

    private func ensureWrapper() {
        let appDir = "/Applications/YandexMusic.app/Contents/MacOS"
        let binary = appDir + "/Яндекс Музыка"
        let orig = appDir + "/Яндекс Музыка.orig"
        let fm = FileManager.default

        // If .orig doesn't exist — wrapper not installed or was overwritten by update
        if !fm.fileExists(atPath: orig) && fm.fileExists(atPath: binary) {
            // Check if current binary is already a wrapper (small shell script vs large Electron binary)
            if let attrs = try? fm.attributesOfItem(atPath: binary),
               let size = attrs[.size] as? Int,
               size > 10000 {
                // It's the real binary (large file), install wrapper
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: "/bin/bash")
                proc.arguments = ["-c", """
                    mv "\(binary)" "\(orig)" && \
                    printf '#!/bin/bash\\nexec "$(dirname "$0")/Яндекс Музыка.orig" --remote-debugging-port=9222 "$@"\\n' > "\(binary)" && \
                    chmod +x "\(binary)"
                """]
                proc.standardOutput = FileHandle.nullDevice
                proc.standardError = FileHandle.nullDevice
                try? proc.run()
                proc.waitUntilExit()
            }
        }
    }

    private func ensureYandexMusicWithCDP() {
        // Check if CDP is available
        let cdpAvailable: Bool
        if let url = URL(string: "http://localhost:9222/json"),
           let data = try? Data(contentsOf: url),
           let pages = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           pages.contains(where: { ($0["url"] as? String ?? "").contains("music") }) {
            cdpAvailable = true
        } else {
            cdpAvailable = false
        }

        if !cdpAvailable {
            // Kill Yandex Music if running without CDP
            let kill = Process()
            kill.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            kill.arguments = ["Яндекс Музыка"]
            kill.standardOutput = FileHandle.nullDevice
            kill.standardError = FileHandle.nullDevice
            try? kill.run()
            kill.waitUntilExit()

            Thread.sleep(forTimeInterval: 1.5)

            // Relaunch with CDP
            let launch = Process()
            launch.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            launch.arguments = ["-a", "Яндекс Музыка", "--args", "--remote-debugging-port=9222"]
            try? launch.run()

            // Wait for CDP to become available
            for _ in 0..<10 {
                Thread.sleep(forTimeInterval: 1.0)
                if let url = URL(string: "http://localhost:9222/json"),
                   let _ = try? Data(contentsOf: url) {
                    break
                }
            }
        }
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateTrack()
        }
    }

    private var cdpCheckCounter = 0

    private func updateTrack() {
        cdpCheckCounter += 1

        // Every 5 polls (~10 sec), check if YM is running without CDP
        if cdpCheckCounter % 5 == 0 {
            DispatchQueue.global().async { [weak self] in
                self?.ensureYandexMusicWithCDPBackground()
            }
        }

        trackProvider.getCurrentTrack { [weak self] track in
            DispatchQueue.main.async {
                self?.menubarController.update(with: track)
            }
        }
    }

    private func ensureYandexMusicWithCDPBackground() {
        // Check if YM process is running
        let check = Process()
        check.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        check.arguments = ["-f", "Яндекс Музыка"]
        check.standardOutput = FileHandle.nullDevice
        check.standardError = FileHandle.nullDevice
        try? check.run()
        check.waitUntilExit()
        let ymRunning = check.terminationStatus == 0

        if !ymRunning { return } // Not running, nothing to fix

        // YM is running — check CDP
        let cdpAvailable: Bool
        if let url = URL(string: "http://localhost:9222/json"),
           let data = try? Data(contentsOf: url),
           !data.isEmpty {
            cdpAvailable = true
        } else {
            cdpAvailable = false
        }

        if !cdpAvailable {
            // YM running without CDP — restart it
            let kill = Process()
            kill.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            kill.arguments = ["Яндекс Музыка"]
            kill.standardOutput = FileHandle.nullDevice
            kill.standardError = FileHandle.nullDevice
            try? kill.run()
            kill.waitUntilExit()

            Thread.sleep(forTimeInterval: 1.5)

            let launch = Process()
            launch.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            launch.arguments = ["-a", "Яндекс Музыка", "--args", "--remote-debugging-port=9222"]
            try? launch.run()
        }
    }
}
