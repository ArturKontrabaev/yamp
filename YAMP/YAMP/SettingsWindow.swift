import Cocoa

class SettingsWindow {
    private var window: NSWindow?
    private var hotkeyButtons: [HotkeyManager.Action: NSButton] = [:]
    private var recordingAction: HotkeyManager.Action?
    private var eventMonitor: Any?

    func show() {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 490),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = "YAMP Settings"
        w.center()
        w.isReleasedWhenClosed = false

        let cv = NSView(frame: w.contentView!.bounds)

        var y: CGFloat = 450

        // Display length
        let label = NSTextField(labelWithString: "Max display length:")
        label.frame = NSRect(x: 20, y: y, width: 160, height: 20)
        label.font = NSFont.systemFont(ofSize: 13)
        cv.addSubview(label)
        y -= 28

        let slider = NSSlider(value: Double(Settings.shared.maxDisplayLength), minValue: 10, maxValue: 60, target: self, action: #selector(lengthChanged(_:)))
        slider.frame = NSRect(x: 20, y: y, width: 240, height: 20)
        cv.addSubview(slider)

        let valLabel = NSTextField(labelWithString: "\(Settings.shared.maxDisplayLength)")
        valLabel.frame = NSRect(x: 270, y: y, width: 60, height: 20)
        valLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        valLabel.tag = 100
        cv.addSubview(valLabel)
        y -= 30

        // Font size
        let fontLabel = NSTextField(labelWithString: "Menu bar font size:")
        fontLabel.frame = NSRect(x: 20, y: y, width: 160, height: 20)
        fontLabel.font = NSFont.systemFont(ofSize: 13)
        cv.addSubview(fontLabel)
        y -= 28

        let fontSlider = NSSlider(value: Double(Settings.shared.menuBarFontSize), minValue: 10, maxValue: 18, target: self, action: #selector(fontSizeChanged(_:)))
        fontSlider.frame = NSRect(x: 20, y: y, width: 240, height: 20)
        fontSlider.numberOfTickMarks = 9
        fontSlider.allowsTickMarkValuesOnly = true
        cv.addSubview(fontSlider)

        let fontVal = NSTextField(labelWithString: "\(Settings.shared.menuBarFontSize)pt")
        fontVal.frame = NSRect(x: 270, y: y, width: 60, height: 20)
        fontVal.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        fontVal.tag = 101
        cv.addSubview(fontVal)
        y -= 30

        // Icon size
        let iconSzLabel = NSTextField(labelWithString: "Icon size:")
        iconSzLabel.frame = NSRect(x: 20, y: y, width: 120, height: 20)
        iconSzLabel.font = NSFont.systemFont(ofSize: 13)
        cv.addSubview(iconSzLabel)

        let iconSzSlider = NSSlider(value: Double(Settings.shared.menuBarIconSize), minValue: 12, maxValue: 22, target: self, action: #selector(iconSizeChanged(_:)))
        iconSzSlider.frame = NSRect(x: 150, y: y, width: 140, height: 20)
        iconSzSlider.numberOfTickMarks = 11
        iconSzSlider.allowsTickMarkValuesOnly = true
        cv.addSubview(iconSzSlider)

        let iconSzVal = NSTextField(labelWithString: "\(Settings.shared.menuBarIconSize)pt")
        iconSzVal.frame = NSRect(x: 300, y: y, width: 40, height: 20)
        iconSzVal.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        iconSzVal.tag = 102
        cv.addSubview(iconSzVal)
        y -= 30

        // Icon picker
        let iconLabel = NSTextField(labelWithString: "Menu bar icon:")
        iconLabel.frame = NSRect(x: 20, y: y, width: 120, height: 20)
        iconLabel.font = NSFont.systemFont(ofSize: 13)
        cv.addSubview(iconLabel)

        let iconPopup = NSPopUpButton(frame: NSRect(x: 150, y: y - 2, width: 180, height: 24))
        let currentIcon = Settings.shared.menuBarIcon
        for opt in Settings.iconOptions {
            iconPopup.addItem(withTitle: opt.label)
            if opt.id == currentIcon {
                iconPopup.selectItem(at: iconPopup.numberOfItems - 1)
            }
        }
        iconPopup.target = self
        iconPopup.action = #selector(iconChanged(_:))
        cv.addSubview(iconPopup)
        y -= 32

        // Hide on pause
        let hideCheck = NSButton(checkboxWithTitle: "Show icon only when paused", target: self, action: #selector(hideToggled(_:)))
        hideCheck.frame = NSRect(x: 20, y: y, width: 300, height: 20)
        hideCheck.state = Settings.shared.hideTrackOnPause ? .on : .off
        cv.addSubview(hideCheck)
        y -= 36

        // Hotkeys header
        let hkLabel = NSTextField(labelWithString: "Keyboard Shortcuts:")
        hkLabel.frame = NSRect(x: 20, y: y, width: 200, height: 20)
        hkLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        cv.addSubview(hkLabel)
        y -= 6

        // Hotkey rows
        for action in HotkeyManager.Action.allCases {
            y -= 28
            let actionLabel = NSTextField(labelWithString: action.displayName)
            actionLabel.frame = NSRect(x: 20, y: y, width: 120, height: 22)
            actionLabel.font = NSFont.systemFont(ofSize: 13)
            cv.addSubview(actionLabel)

            let shortcut = HotkeyManager.shared.getShortcut(for: action)
            let btnTitle = shortcut?.displayString ?? "Click to set"

            let btn = NSButton(title: btnTitle, target: self, action: #selector(hotkeyButtonClicked(_:)))
            btn.frame = NSRect(x: 150, y: y, width: 130, height: 24)
            btn.bezelStyle = .rounded
            btn.font = NSFont.systemFont(ofSize: 12)
            btn.tag = HotkeyManager.Action.allCases.firstIndex(of: action)!
            cv.addSubview(btn)
            hotkeyButtons[action] = btn

            let clearBtn = NSButton(title: "✕", target: self, action: #selector(clearHotkey(_:)))
            clearBtn.frame = NSRect(x: 288, y: y, width: 30, height: 24)
            clearBtn.bezelStyle = .rounded
            clearBtn.font = NSFont.systemFont(ofSize: 11)
            clearBtn.tag = btn.tag
            cv.addSubview(clearBtn)
        }

        y -= 36

        // Quit
        // Launch at login
        let loginCheck = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(loginToggled(_:)))
        loginCheck.frame = NSRect(x: 20, y: 52, width: 200, height: 20)
        loginCheck.state = Settings.shared.launchAtLogin ? .on : .off
        cv.addSubview(loginCheck)

        let quitBtn = NSButton(title: "Quit YAMP", target: self, action: #selector(quit))
        quitBtn.frame = NSRect(x: 20, y: 12, width: 100, height: 32)
        quitBtn.bezelStyle = .rounded
        cv.addSubview(quitBtn)

        let ver = NSTextField(labelWithString: "YAMP v0.3")
        ver.frame = NSRect(x: 260, y: 16, width: 80, height: 14)
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

    @objc private func iconSizeChanged(_ sender: NSSlider) {
        let v = Int(sender.doubleValue)
        Settings.shared.menuBarIconSize = v
        if let cv = sender.superview {
            for sub in cv.subviews {
                if let l = sub as? NSTextField, l.tag == 102 { l.stringValue = "\(v)pt" }
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name("YAMPIconChanged"), object: nil)
    }

    @objc private func fontSizeChanged(_ sender: NSSlider) {
        let v = Int(sender.doubleValue)
        Settings.shared.menuBarFontSize = v
        if let cv = sender.superview {
            for sub in cv.subviews {
                if let l = sub as? NSTextField, l.tag == 101 { l.stringValue = "\(v)pt" }
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name("YAMPIconChanged"), object: nil)
    }

    @objc private func iconChanged(_ sender: NSPopUpButton) {
        let idx = sender.indexOfSelectedItem
        if idx >= 0 && idx < Settings.iconOptions.count {
            Settings.shared.menuBarIcon = Settings.iconOptions[idx].id
            // Notify to update icon immediately
            NotificationCenter.default.post(name: NSNotification.Name("YAMPIconChanged"), object: nil)
        }
    }

    @objc private func loginToggled(_ sender: NSButton) {
        let enable = sender.state == .on
        Settings.shared.launchAtLogin = enable

        // Add/remove login item via osascript
        let script: String
        if enable {
            let appPath = Bundle.main.bundlePath
            script = "tell application \"System Events\" to make login item at end with properties {path:\"\(appPath)\", hidden:false}"
        } else {
            script = "tell application \"System Events\" to delete login item \"YAMP\""
        }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script]
        try? proc.run()
    }

    @objc private func hideToggled(_ sender: NSButton) {
        Settings.shared.hideTrackOnPause = sender.state == .on
    }

    @objc private func hotkeyButtonClicked(_ sender: NSButton) {
        let actions = HotkeyManager.Action.allCases
        let action = actions[sender.tag]

        // Start recording
        recordingAction = action
        sender.title = "Press shortcut..."

        // Unregister all hotkeys while recording
        HotkeyManager.shared.unregisterAll()

        // Listen for key press
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, let action = self.recordingAction else { return event }

            let mods = HotkeyManager.carbonModifiers(from: event.modifierFlags)

            // Need at least one modifier
            if mods == 0 {
                sender.title = "Need modifier key"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    let s = HotkeyManager.shared.getShortcut(for: action)
                    sender.title = s?.displayString ?? "Click to set"
                }
                self.stopRecording()
                return nil
            }

            let shortcut = HotkeyManager.Shortcut(keyCode: UInt32(event.keyCode), modifiers: mods)
            HotkeyManager.shared.setShortcut(shortcut, for: action)
            sender.title = shortcut.displayString

            self.stopRecording()
            return nil
        }
    }

    @objc private func clearHotkey(_ sender: NSButton) {
        let actions = HotkeyManager.Action.allCases
        let action = actions[sender.tag]
        HotkeyManager.shared.setShortcut(nil, for: action)
        hotkeyButtons[action]?.title = "Click to set"
    }

    private func stopRecording() {
        recordingAction = nil
        if let m = eventMonitor {
            NSEvent.removeMonitor(m)
            eventMonitor = nil
        }
        HotkeyManager.shared.registerAll()
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
