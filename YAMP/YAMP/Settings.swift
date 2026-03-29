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

    private init() {
        defaults.register(defaults: ["maxDisplayLength": 30, "hideTrackOnPause": true])
    }
}

private extension Int {
    func clamped(_ min: Int, _ max: Int) -> Int {
        if self < min { return min }
        if self > max { return max }
        return self
    }
}
