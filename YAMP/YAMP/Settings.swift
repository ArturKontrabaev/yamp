import Foundation

class Settings {
    static let shared = Settings()

    private let defaults = UserDefaults.standard

    var maxDisplayLength: Int {
        get { defaults.integer(forKey: "maxDisplayLength").clamped(10, 60) }
        set { defaults.set(newValue, forKey: "maxDisplayLength") }
    }

    var hideTrackOnPause: Bool {
        get { defaults.bool(forKey: "hideTrackOnPause") }
        set { defaults.set(newValue, forKey: "hideTrackOnPause") }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: "launchAtLogin") }
        set { defaults.set(newValue, forKey: "launchAtLogin") }
    }

    var menuBarFontSize: Int {
        get { defaults.integer(forKey: "menuBarFontSize").clamped(10, 18) }
        set { defaults.set(newValue, forKey: "menuBarFontSize") }
    }

    var menuBarIcon: String {
        get { defaults.string(forKey: "menuBarIcon") ?? "music.quarternote.3" }
        set { defaults.set(newValue, forKey: "menuBarIcon") }
    }

    static let iconOptions: [(id: String, label: String, isSFSymbol: Bool)] = [
        ("music.quarternote.3", "Now Playing", true),
        ("music.note", "Note", true),
        ("headphones", "Headphones", true),
        ("waveform", "Waveform", true),
        ("guitars", "Guitar", true),
        ("♪", "♪", false),
        ("Y", "Y", false),
    ]

    private init() {
        defaults.register(defaults: ["maxDisplayLength": 30, "hideTrackOnPause": true, "menuBarIcon": "music.quarternote.3", "menuBarFontSize": 12])
    }
}

private extension Int {
    func clamped(_ min: Int, _ max: Int) -> Int {
        if self < min { return min }
        if self > max { return max }
        return self
    }
}
