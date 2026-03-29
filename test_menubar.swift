import Cocoa
let app = NSApplication.shared
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
statusItem.button?.title = "YAMP TEST"
app.run()
