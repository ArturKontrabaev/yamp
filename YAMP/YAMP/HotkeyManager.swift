import Cocoa
import Carbon

class HotkeyManager {
    static let shared = HotkeyManager()

    enum Action: String, CaseIterable {
        case playPause = "playPause"
        case next = "next"
        case prev = "prev"
        case like = "like"
        case dislike = "dislike"

        var displayName: String {
            switch self {
            case .playPause: return "Play / Pause"
            case .next: return "Next Track"
            case .prev: return "Previous Track"
            case .like: return "Like"
            case .dislike: return "Dislike (never play again)"
            }
        }
    }

    struct Shortcut: Codable, Equatable {
        let keyCode: UInt32
        let modifiers: UInt32

        var displayString: String {
            var parts: [String] = []
            if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
            if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
            if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
            if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
            parts.append(keyName(keyCode))
            return parts.joined()
        }

        private func keyName(_ code: UInt32) -> String {
            let names: [UInt32: String] = [
                0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
                8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
                16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
                38: "J", 40: "K", 45: "N", 46: "M",
                18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7",
                28: "8", 25: "9", 29: "0",
                49: "Space", 36: "Return", 48: "Tab", 51: "Delete",
                123: "←", 124: "→", 125: "↓", 126: "↑",
                122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5",
                97: "F6", 98: "F7", 100: "F8", 101: "F9", 109: "F10",
                103: "F11", 111: "F12",
                27: "-", 24: "=", 33: "[", 30: "]", 41: ";", 39: "'",
                43: ",", 47: ".", 44: "/",
            ]
            return names[code] ?? "Key\(code)"
        }
    }

    private var hotKeyRefs: [EventHotKeyRef?] = []
    var onAction: ((Action) -> Void)?

    private init() {}

    func registerAll() {
        unregisterAll()

        for (index, action) in Action.allCases.enumerated() {
            guard let shortcut = getShortcut(for: action) else { continue }

            var hotKeyID = EventHotKeyID()
            hotKeyID.signature = OSType(0x594D5030) // "YMP0"
            hotKeyID.id = UInt32(index)

            var hotKeyRef: EventHotKeyRef?
            let status = RegisterEventHotKey(
                shortcut.keyCode,
                shortcut.modifiers,
                hotKeyID,
                GetEventDispatcherTarget(),
                0,
                &hotKeyRef
            )

            if status == noErr {
                hotKeyRefs.append(hotKeyRef)
            }
        }

        installHandler()
    }

    func unregisterAll() {
        for ref in hotKeyRefs {
            if let ref = ref { UnregisterEventHotKey(ref) }
        }
        hotKeyRefs.removeAll()
    }

    private var handlerInstalled = false
    private func installHandler() {
        guard !handlerInstalled else { return }
        handlerInstalled = true

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetEventDispatcherTarget(), { (_, event, _) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, UInt32(kEventParamDirectObject), UInt32(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

            let actions = Action.allCases
            let index = Int(hotKeyID.id)
            if index < actions.count {
                HotkeyManager.shared.onAction?(actions[index])
            }
            return noErr
        }, 1, &eventType, nil, nil)
    }

    // MARK: - Storage

    func getShortcut(for action: Action) -> Shortcut? {
        guard let data = UserDefaults.standard.data(forKey: "hotkey_\(action.rawValue)"),
              let shortcut = try? JSONDecoder().decode(Shortcut.self, from: data) else {
            return nil
        }
        return shortcut
    }

    func setShortcut(_ shortcut: Shortcut?, for action: Action) {
        if let shortcut = shortcut,
           let data = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(data, forKey: "hotkey_\(action.rawValue)")
        } else {
            UserDefaults.standard.removeObject(forKey: "hotkey_\(action.rawValue)")
        }
        registerAll()
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        if flags.contains(.shift) { mods |= UInt32(shiftKey) }
        if flags.contains(.option) { mods |= UInt32(optionKey) }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        return mods
    }
}
