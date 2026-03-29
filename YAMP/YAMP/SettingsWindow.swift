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
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 160),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = "YAMP Settings"
        w.center()
        w.isReleasedWhenClosed = false

        let cv = NSView(frame: w.contentView!.bounds)

        let label = NSTextField(labelWithString: "Max display length:")
        label.frame = NSRect(x: 20, y: 110, width: 160, height: 20)
        label.font = NSFont.systemFont(ofSize: 13)
        cv.addSubview(label)

        let slider = NSSlider(value: Double(Settings.shared.maxDisplayLength), minValue: 10, maxValue: 60, target: self, action: #selector(lengthChanged(_:)))
        slider.frame = NSRect(x: 20, y: 82, width: 180, height: 20)
        cv.addSubview(slider)

        let valLabel = NSTextField(labelWithString: "\(Settings.shared.maxDisplayLength)")
        valLabel.frame = NSRect(x: 210, y: 82, width: 60, height: 20)
        valLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        valLabel.tag = 100
        cv.addSubview(valLabel)

        let quitBtn = NSButton(title: "Quit YAMP", target: self, action: #selector(quit))
        quitBtn.frame = NSRect(x: 20, y: 20, width: 100, height: 32)
        quitBtn.bezelStyle = .rounded
        cv.addSubview(quitBtn)

        let ver = NSTextField(labelWithString: "YAMP v0.1")
        ver.frame = NSRect(x: 200, y: 24, width: 80, height: 14)
        ver.font = NSFont.systemFont(ofSize: 11)
        ver.textColor = NSColor.tertiaryLabelColor
        ver.alignment = .right
        cv.addSubview(ver)

        w.contentView = cv
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }

    @objc private func lengthChanged(_ sender: NSSlider) {
        let v = Int(sender.doubleValue)
        Settings.shared.maxDisplayLength = v
        if let cv = sender.superview {
            for sub in cv.subviews {
                if let l = sub as? NSTextField, l.tag == 100 { l.stringValue = "\(v)" }
            }
        }
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
