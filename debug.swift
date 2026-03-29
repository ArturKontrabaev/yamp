import Foundation

let fm = FileManager.default
let home = fm.homeDirectoryForCurrentUser.path

// 1. Read Electron Preferences (often has app state)
print("=== YandexMusic/Preferences ===")
let prefsPath = "\(home)/Library/Application Support/YandexMusic/Preferences"
if let data = fm.contents(atPath: prefsPath), let text = String(data: data, encoding: .utf8) {
    print(String(text.prefix(2000)))
}

// 2. Read config.json
print("")
print("=== YandexMusic/config.json ===")
let configPath = "\(home)/Library/Application Support/YandexMusic/config.json"
if let data = fm.contents(atPath: configPath), let text = String(data: data, encoding: .utf8) {
    print(text)
}

// 3. Check yandex-music-app folder
print("")
print("=== yandex-music-app contents ===")
let ymAppPath = "\(home)/Library/Application Support/yandex-music-app"
if let contents = try? fm.contentsOfDirectory(atPath: ymAppPath) {
    for item in contents {
        let fullPath = "\(ymAppPath)/\(item)"
        var isDir: ObjCBool = false
        fm.fileExists(atPath: fullPath, isDirectory: &isDir)
        let size = (try? fm.attributesOfItem(atPath: fullPath)[.size] as? Int) ?? 0
        print("  \(item) \(isDir.boolValue ? "[DIR]" : "[\(size) bytes]")")
    }
}

// 4. Read plist
print("")
print("=== ru.yandex.desktop.music.plist ===")
let plistPath = "\(home)/Library/Preferences/ru.yandex.desktop.music.plist"
if let dict = NSDictionary(contentsOfFile: plistPath) {
    for (key, value) in dict {
        let k = "\(key)"
        let v = "\(value)"
        if v.count > 200 {
            print("  \(k) = \(v.prefix(200))...")
        } else {
            print("  \(k) = \(v)")
        }
    }
}

// 5. Check Local State / Session Storage
print("")
print("=== Session Storage ===")
let sessionPath = "\(home)/Library/Application Support/YandexMusic/Session Storage"
if let contents = try? fm.contentsOfDirectory(atPath: sessionPath) {
    for item in contents {
        print("  \(item)")
    }
}
