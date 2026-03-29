import Foundation

// Try getting track from window title of Яндекс Музыка
let script = """
tell application "System Events"
    if exists (process "Яндекс Музыка") then
        tell process "Яндекс Музыка"
            set winNames to name of every window
            return winNames as text
        end tell
    else
        return "NOT_RUNNING"
    end if
end tell
"""

let appleScript = NSAppleScript(source: script)
var error: NSDictionary?
if let result = appleScript?.executeAndReturnError(&error) {
    print("Window titles: \(result.stringValue ?? "empty")")
} else {
    print("Error: \(error ?? [:])")
}
