import Cocoa

// Approach 1: Try Accessibility API to read UI elements
let script1 = """
tell application "System Events"
    tell process "Яндекс Музыка"
        set uiDesc to entire contents of front window
        set output to ""
        repeat with elem in uiDesc
            try
                set r to role of elem
                set v to value of elem as text
                if v is not "" and v is not missing value then
                    set output to output & r & ": " & v & linefeed
                end if
            end try
        end repeat
        return output
    end tell
end tell
"""

// Approach 2: Try reading from browser (if web version is open)
let script2 = """
tell application "System Events"
    set browserList to {"Safari", "Google Chrome", "Yandex"}
    repeat with browserName in browserList
        if exists process browserName then
            tell process browserName
                repeat with w in windows
                    set t to name of w
                    if t contains "Яндекс Музыка" or t contains "Yandex Music" then
                        return "BROWSER:" & t
                    end if
                end repeat
            end tell
        end if
    end repeat
    return "NO_BROWSER_TAB"
end tell
"""

print("=== Accessibility (UI elements) ===")
var error: NSDictionary?
let as1 = NSAppleScript(source: script1)
if let result = as1?.executeAndReturnError(&error) {
    let text = result.stringValue ?? ""
    // Print first 2000 chars
    if text.isEmpty {
        print("No UI elements found (need Accessibility permission)")
        print("Go to: System Settings > Privacy & Security > Accessibility")
        print("Add Terminal.app")
    } else {
        print(String(text.prefix(2000)))
    }
} else {
    print("Error: \(error?["NSAppleScriptErrorMessage"] ?? "unknown")")
    print("Likely need Accessibility permission for Terminal")
    print("Go to: System Settings > Privacy & Security > Accessibility > add Terminal")
}

print("")
print("=== Browser tab check ===")
let as2 = NSAppleScript(source: script2)
if let result = as2?.executeAndReturnError(&error) {
    print(result.stringValue ?? "empty")
} else {
    print("Error: \(error?["NSAppleScriptErrorMessage"] ?? "unknown")")
}
