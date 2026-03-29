import Foundation

// 1. Find Yandex Music app data
let fm = FileManager.default
let home = fm.homeDirectoryForCurrentUser.path
let paths = [
    "\(home)/Library/Application Support/YandexMusic",
    "\(home)/Library/Application Support/Yandex Music",
    "\(home)/Library/Application Support/ru.yandex.desktop.music",
    "\(home)/Library/Application Support/Яндекс Музыка",
    "\(home)/Library/Caches/ru.yandex.desktop.music",
    "\(home)/Library/Caches/YandexMusic",
]

print("=== Looking for Yandex Music data ===")
for path in paths {
    if fm.fileExists(atPath: path) {
        print("FOUND: \(path)")
        if let contents = try? fm.contentsOfDirectory(atPath: path) {
            for item in contents.prefix(20) {
                print("  \(item)")
            }
        }
    }
}

// 2. Broader search
print("")
print("=== Searching Library for yandex/music ===")
let searchPaths = [
    "\(home)/Library/Application Support",
    "\(home)/Library/Caches",
    "\(home)/Library/Preferences",
]
for searchPath in searchPaths {
    if let contents = try? fm.contentsOfDirectory(atPath: searchPath) {
        for item in contents {
            let lower = item.lowercased()
            if lower.contains("yandex") || lower.contains("яндекс") || lower.contains("music") || lower.contains("музык") {
                print("  \(searchPath)/\(item)")
            }
        }
    }
}

// 3. Check if Electron debug port is open
print("")
print("=== Checking for Electron debug port ===")
let pipe = Pipe()
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
process.arguments = ["lsof", "-i", "-P"]
process.standardOutput = pipe
try? process.run()
process.waitUntilExit()
let data = pipe.fileHandleForReading.readDataToEndOfFile()
let output = String(data: data, encoding: .utf8) ?? ""
let lines = output.components(separatedBy: "\n")
for line in lines {
    if line.contains("Яндекс") || line.contains("Yandex") || line.contains("Electron") {
        print(line)
    }
}
