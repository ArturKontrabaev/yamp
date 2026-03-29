import Foundation

let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))!

// Get function pointers
typealias MRInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
typealias MRRegisterFn = @convention(c) (DispatchQueue) -> Void

let infoPtr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString)!
let getInfo = unsafeBitCast(infoPtr, to: MRInfoFn.self)

// Try registering for notifications first
if let regPtr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString) {
    let register = unsafeBitCast(regPtr, to: MRRegisterFn.self)
    register(DispatchQueue.main)
    print("Registered for notifications")
}

// Wait a moment for registration, then query
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
    getInfo(DispatchQueue.main) { info in
        if info.isEmpty {
            print("EMPTY — still no data")
            print("")
            print("Trying AppleScript fallback...")

            // Try AppleScript to get browser tab title
            let script = """
            tell application "System Events"
                set appList to name of every application process whose visible is true
                return appList as text
            end tell
            """
            let appleScript = NSAppleScript(source: script)
            var error: NSDictionary?
            if let result = appleScript?.executeAndReturnError(&error) {
                print("Running apps: \(result.stringValue ?? "none")")
            }

            // Try getting Yandex Music window title
            let ymScript = """
            tell application "System Events"
                if exists (process "Yandex Music") then
                    tell process "Yandex Music"
                        set winTitle to name of front window
                        return winTitle
                    end tell
                else
                    return "Yandex Music not running"
                end if
            end tell
            """
            let ymApple = NSAppleScript(source: ymScript)
            if let result = ymApple?.executeAndReturnError(&error) {
                print("Yandex Music window: \(result.stringValue ?? "error")")
            } else {
                print("AppleScript error: \(error ?? [:])")
            }
        } else {
            print("SUCCESS! Keys found:")
            for (key, value) in info.sorted(by: { $0.key < $1.key }) {
                let v = "\(value)"
                if v.count > 100 {
                    print("  \(key) = [\(v.prefix(100))...]")
                } else {
                    print("  \(key) = \(v)")
                }
            }
        }
        exit(0)
    }
}

RunLoop.main.run()
