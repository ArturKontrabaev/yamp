import Cocoa

let script = """
tell application "System Events"
    tell process "Яндекс Музыка"
        set output to ""
        tell front window
            set allElems to every UI element
            repeat with elem in allElems
                try
                    set r to role of elem
                    set d to description of elem
                    set t to title of elem
                    set v to value of elem
                    set output to output & r & " | title:" & (t as text) & " | desc:" & (d as text) & " | val:" & (v as text) & linefeed
                end try
                try
                    set subElems to every UI element of elem
                    repeat with sub in subElems
                        try
                            set r2 to role of sub
                            set d2 to description of sub
                            set t2 to title of sub
                            set v2 to value of sub
                            set output to output & "  " & r2 & " | title:" & (t2 as text) & " | desc:" & (d2 as text) & " | val:" & (v2 as text) & linefeed
                        end try
                    end repeat
                end try
            end repeat
        end tell
        return output
    end tell
end tell
"""

var error: NSDictionary?
let as1 = NSAppleScript(source: script)
if let result = as1?.executeAndReturnError(&error) {
    let text = result.stringValue ?? "empty"
    print(String(text.prefix(3000)))
} else {
    print("Error: \(error?["NSAppleScriptErrorMessage"] ?? "unknown")")
}
