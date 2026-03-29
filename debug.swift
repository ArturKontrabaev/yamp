import Foundation

let fm = FileManager.default
let home = fm.homeDirectoryForCurrentUser.path

// 1. yandex-music-app config
print("=== yandex-music-app/config.json ===")
let cfg = "\(home)/Library/Application Support/yandex-music-app/config.json"
if let data = fm.contents(atPath: cfg), let text = String(data: data, encoding: .utf8) {
    print(String(text.prefix(2000)))
}

// 2. Local Storage files
print("")
print("=== yandex-music-app/Local Storage ===")
let lsPath = "\(home)/Library/Application Support/yandex-music-app/Local Storage"
if let contents = try? fm.contentsOfDirectory(atPath: lsPath) {
    for item in contents {
        let full = "\(lsPath)/\(item)"
        let size = (try? fm.attributesOfItem(atPath: full)[.size] as? Int) ?? 0
        print("  \(item) [\(size) bytes]")
        // Try to read small files as text
        if size < 50000, let data = fm.contents(atPath: full) {
            // Try to find readable strings
            if let text = String(data: data, encoding: .utf8) {
                let interesting = text.components(separatedBy: "\0")
                    .filter { $0.count > 3 && $0.count < 500 }
                    .filter { $0.contains("track") || $0.contains("title") || $0.contains("artist")
                        || $0.contains("playing") || $0.contains("queue") || $0.contains("current")
                        || $0.contains("song") || $0.contains("name") || $0.contains("album") }
                for s in interesting.prefix(10) {
                    print("    >>> \(s)")
                }
            }
        }
    }
}

// 3. Also check YandexMusic Local Storage if exists
print("")
print("=== YandexMusic/Local Storage ===")
let ls2 = "\(home)/Library/Application Support/YandexMusic/Local Storage"
if let contents = try? fm.contentsOfDirectory(atPath: ls2) {
    for item in contents {
        let full = "\(ls2)/\(item)"
        let size = (try? fm.attributesOfItem(atPath: full)[.size] as? Int) ?? 0
        print("  \(item) [\(size) bytes]")
    }
} else {
    print("  not found")
}

// 4. Check WebStorage
print("")
print("=== YandexMusic/WebStorage ===")
let ws = "\(home)/Library/Application Support/YandexMusic/WebStorage"
if let contents = try? fm.contentsOfDirectory(atPath: ws) {
    for item in contents {
        let full = "\(ws)/\(item)"
        var isDir: ObjCBool = false
        fm.fileExists(atPath: full, isDirectory: &isDir)
        let size = (try? fm.attributesOfItem(atPath: full)[.size] as? Int) ?? 0
        print("  \(item) \(isDir.boolValue ? "[DIR]" : "[\(size) bytes]")")
        if isDir.boolValue, let sub = try? fm.contentsOfDirectory(atPath: full) {
            for s in sub.prefix(10) {
                let sf = "\(full)/\(s)"
                let ss = (try? fm.attributesOfItem(atPath: sf)[.size] as? Int) ?? 0
                print("    \(s) [\(ss) bytes]")
            }
        }
    }
}
