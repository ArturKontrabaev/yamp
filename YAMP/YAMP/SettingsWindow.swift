import Cocoa

class SettingsWindow {
    private var window: NSWindow?

    func show() {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = "YAMP Settings"
        w.center()
        w.isReleasedWhenClosed = false

        let contentView = NSView(frame: w.contentView!.bounds)

        // Max display length
        let lengthLabel = NSTextField(labelWithString: "Max display length:")
        lengthLabel.frame = NSRect(x: 20, y: 148, width: 160, height: 20)
        lengthLabel.font = NSFont.systemFont(ofSize: 13)
        contentView.addSubview(lengthLabel)

        let lengthSlider = NSSlider(value: Double(Settings.shared.maxDisplayLength), minValue: 10, maxValue: 60, target: nil, action: nil)
        lengthSlider.frame = NSRect(x: 20, y: 120, width: 200, height: 20)
        lengthSlider.numberOfTickMarks = 11
        lengthSlider.allowsTickMarkValuesOnly = true
        contentView.addSubview(lengthSlider)

        let lengthValue = NSTextField(labelWithString: "\(Settings.shared.maxDisplayLength) chars")
        lengthValue.frame = NSRect(x: 230, y: 120, width: 70, height: 20)
        lengthValue.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        contentView.addSubview(lengthValue)

        lengthSlider.target = self
        lengthSlider.action = #selector(lengthChanged(_:))
        lengthSlider.tag = 1

        // Store references for the action
        lengthValue.tag = 100
        contentView.addSubview(lengthValue)

        // Open Yandex Music button
        let openButton = NSButton(title: "Open Yandex Music", target: self, action: #selector(openYandexMusic))
        openButton.frame = NSRect(x: 20, y: 70, width: 160, height: 32)
        openButton.bezelStyle = .rounded
        contentView.addSubview(openButton)

        // Quit button
        let quitButton = NSButton(title: "Quit YAMP", target: self, action: #selector(quit))
        quitButton.frame = NSRect(x: 20, y: 20, width: 100, height: 32)
        quitButton.bezelStyle = .rounded
        contentView.addSubview(quitButton)

        // Version label
        let versionLabel = NSTextField(labelWithString: "YAMP v1.0")
        versionLabel.frame = NSRect(x: 200, y: 20, width: 100, height: 16)
        versionLabel.font = NSFont.systemFont(ofSize: 11)
        versionLabel.textColor = NSColor.tertiaryLabelColor
        versionLabel.alignment = .right
        contentView.addSubview(versionLabel)

        w.contentView = contentView
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }

    @objc private func lengthChanged(_ sender: NSSlider) {
        let value = Int(sender.doubleValue)
        Settings.shared.maxDisplayLength = value

        // Update the label
        if let contentView = sender.superview {
            for sub in contentView.subviews {
                if let label = sub as? NSTextField, label.tag == 100 {
                    label.stringValue = "\(value) chars"
                }
            }
        }
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
