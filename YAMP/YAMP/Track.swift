import Foundation

struct Track {
    let title: String
    let artist: String
    let isPlaying: Bool

    var displayString: String {
        if title.isEmpty { return "" }
        if artist.isEmpty { return title }
        return "\(artist) — \(title)"
    }

    var menuTitle: String {
        if title.isEmpty { return "No track" }
        return title
    }

    var menuArtist: String {
        if artist.isEmpty { return "—" }
        return artist
    }

    var truncatedDisplay: String {
        let max = 30
        let s = displayString
        if s.count <= max { return s }
        return String(s.prefix(max - 1)) + "…"
    }

    static let empty = Track(title: "", artist: "", isPlaying: false)
}
