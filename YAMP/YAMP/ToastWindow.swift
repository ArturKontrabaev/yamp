import Cocoa

class ToastWindow: NSWindow {
    private static var current: ToastWindow?
    private var hideTimer: Timer?

    static func show(_ message: String, icon: String = "♥", near statusItem: NSStatusItem? = nil) {
        // Dismiss previous toast
        current?.close()

        let toast = ToastWindow(message: message, icon: icon)
        current = toast

        // Position below menubar, centered on screen or near status item
        if let button = statusItem?.button, let buttonWindow = button.window {
            let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
            let x = buttonRect.midX - toast.frame.width / 2
            let y = buttonRect.minY - toast.frame.height - 4
            toast.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            guard let screen = NSScreen.main else { return }
            let x = screen.frame.midX - toast.frame.width / 2
            let y = screen.frame.maxY - 36 - toast.frame.height
            toast.setFrameOrigin(NSPoint(x: x, y: y))
        }

        toast.alphaValue = 0
        toast.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            toast.animator().alphaValue = 1.0
        }

        toast.hideTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false) { _ in
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.3
                toast.animator().alphaValue = 0
            }, completionHandler: {
                toast.close()
                if current === toast { current = nil }
            })
        }
    }

    private init(message: String, icon: String) {
        let padding: CGFloat = 12
        let iconWidth: CGFloat = 24
        let spacing: CGFloat = 6
        let font = NSFont.systemFont(ofSize: 13, weight: .medium)

        let textSize = (message as NSString).size(withAttributes: [.font: font])
        let width = padding + iconWidth + spacing + textSize.width + padding
        let height: CGFloat = 36

        let frame = NSRect(x: 0, y: 0, width: width, height: height)
        super.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .statusBar
        self.hasShadow = true
        self.isReleasedWhenClosed = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let effect = NSVisualEffectView(frame: frame)
        effect.material = .hudWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = height / 2
        effect.layer?.masksToBounds = true

        let iconLabel = NSTextField(labelWithString: icon)
        iconLabel.font = NSFont.systemFont(ofSize: 16)
        iconLabel.frame = NSRect(x: padding, y: (height - 20) / 2, width: iconWidth, height: 20)
        iconLabel.alignment = .center
        effect.addSubview(iconLabel)

        let textLabel = NSTextField(labelWithString: message)
        textLabel.font = font
        textLabel.textColor = .labelColor
        textLabel.frame = NSRect(x: padding + iconWidth + spacing, y: (height - textSize.height) / 2, width: textSize.width, height: textSize.height)
        effect.addSubview(textLabel)

        self.contentView = effect
    }
}
