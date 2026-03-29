import Cocoa

// Try to find Now Playing info through various system processes
let processes = ["ControlCenter", "Control Center", "NowPlaying", "MediaRemote"]

for procName in processes {
    let script = """
    tell application "System Events"
        if exists process "\(procName)" then
            tell process "\(procName)"
                set output to ""
                repeat with w in windows
                    set output to output & "Window: " & (name of w) & linefeed
                    try
                        set elems to entire contents of w
                        repeat with e in elems
                            try
                                set r to role of e
                                if r is "AXStaticText" then
                                    set v to value of e
                                    if v is not missing value and v is not "" then
                                        set output to output & "  TEXT: " & (v as text) & linefeed
                                    end if
                                end if
                            end try
                        end repeat
                    end try
                end repeat
                return output
            end tell
        else
            return "NOT_FOUND"
        end if
    end tell
    """

    let as1 = NSAppleScript(source: script)
    var error: NSDictionary?
    if let result = as1?.executeAndReturnError(&error) {
        let text = result.stringValue ?? ""
        if text != "NOT_FOUND" && !text.isEmpty {
            print("=== Process: \(procName) ===")
            print(text)
        }
    }
}

// Also try menu bar items
print("=== Menu bar extras ===")
let menuScript = """
tell application "System Events"
    set output to ""
    repeat with proc in every process
        try
            set mbars to menu bars of proc
            repeat with mbar in mbars
                set items to menu bar items of mbar
                repeat with item in items
                    set t to title of item
                    if t is not missing value and t is not "" then
                        set pname to name of proc
                        set output to output & pname & ": " & t & linefeed
                    end if
                end repeat
            end repeat
        end try
    end repeat
    return output
end tell
"""
let as2 = NSAppleScript(source: menuScript)
var error2: NSDictionary?
if let result = as2?.executeAndReturnError(&error2) {
    let text = result.stringValue ?? ""
    let lines = text.components(separatedBy: "\n")
    for line in lines {
        if line.lowercased().contains("music") || line.lowercased().contains("музык") || line.lowercased().contains("play") || line.lowercased().contains("now") {
            print(line)
        }
    }
    if lines.filter({ $0.contains("music") || $0.contains("Music") || $0.contains("Музык") }).isEmpty {
        print("No music-related menu bar items found")
        print("Total menu bar items: \(lines.count)")
    }
}
