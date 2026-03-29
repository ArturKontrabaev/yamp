import Cocoa

print("Listening for ALL distributed notifications for 15 seconds...")
print("Switch tracks in Яндекс Музыка NOW!")
print("---")

let center = DistributedNotificationCenter.default()
let observer = center.addObserver(forName: nil, object: nil, queue: .main) { notification in
    let name = notification.name.rawValue
    // Filter out noisy system stuff
    if name.contains("com.apple.accessibility") || name.contains("AppleSystemUIS") || name.contains("Cursor") {
        return
    }
    print("[\(name)]")
    if let info = notification.userInfo, !info.isEmpty {
        for (key, value) in info {
            print("  \(key) = \(value)")
        }
    }
}

// Stop after 15 seconds
DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
    print("---")
    print("Done.")
    exit(0)
}

RunLoop.main.run()
