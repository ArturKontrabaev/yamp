import Cocoa

class ToastWindow: NSPanel {
    private static var current: ToastWindow?
    private var hideWork: DispatchWorkItem?

    static func show(_ message: String, icon: String = "♥", near statusItem: NSStatusItem? = nil) {
        DispatchQueue.main.async {
            current?.orderOut(nil)
            current = nil

            let toast = ToastWindow(message: message, icon: icon)
            current = toast

            // Position below menubar
            if let button = statusItem?.button,
               let bw = button.window {
                let rect = bw.convertToScreen(button.convert(button.bounds, to: nil))
                toast.setFrameOrigin(NSPoint(
                    x: rect.midX - toast.frame.width / 2,
                    y: rect.minY - toast.frame.height - 4
                ))
            } else if let screen = NSScreen.main {
                toast.setFrameOrigin(NSPoint(
                    x: screen.frame.midX - toast.frame.width / 2,
                    y: screen.visibleFrame.maxY - toast.frame.height - 8
                ))
            }

            toast.alphaValue = 1.0
            toast.orderFrontRegardless()

            let work = DispatchWorkItem {
                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration = 0.3
                    toast.animator().alphaValue = 0
                }, completionHandler: {
                    toast.orderOut(nil)
                    if current === toast { current = nil }
                })
            }
            toast.hideWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
        }
    }

    private init(message: String, icon: String) {
        let padding: CGFloat = 14
        let iconWidth: CGFloat = 20
        let spacing: CGFloat = 6
        let font = NSFont.systemFont(ofSize: 13, weight: .medium)

        let textSize = (message as NSString).size(withAttributes: [.font: font])
        let width = ceil(padding + iconWidth + spacing + textSize.width + padding)
        let height: CGFloat = 34

        let frame = NSRect(x: 0, y: 0, width: width, height: height)
        super.init(contentRect: frame,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .screenSaver
        self.hasShadow = true
        self.isReleasedWhenClosed = false
        self.ignoresMouseEvents = true
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        let bg = NSView(frame: frame)
        bg.wantsLayer = true
        bg.layer?.cornerRadius = height / 2
        bg.layer?.masksToBounds = true
        bg.layer?.backgroundColor = NSColor(white: 0.15, alpha: 0.85).cgColor

        let iconLabel = NSTextField(labelWithString: icon)
        iconLabel.font = NSFont.systemFont(ofSize: 15)
        iconLabel.textColor = .white
        iconLabel.frame = NSRect(x: padding, y: (height - 20) / 2, width: iconWidth, height: 20)
        iconLabel.alignment = .center
        bg.addSubview(iconLabel)

        let textLabel = NSTextField(labelWithString: message)
        textLabel.font = font
        textLabel.textColor = .white
        textLabel.frame = NSRect(x: padding + iconWidth + spacing,
                                  y: (height - textSize.height) / 2,
                                  width: ceil(textSize.width),
                                  height: ceil(textSize.height))
        bg.addSubview(textLabel)

        self.contentView = bg
    }
}
