import Foundation

struct Track {
    let title: String
    let artist: String
    let isPlaying: Bool
    let artworkURL: String?
    let currentTime: Double
    let duration: Double

    var displayString: String {
        if title.isEmpty { return "" }
        if artist.isEmpty { return title }
        return "\(artist) — \(title)"
    }

    var menuTitle: String {
        if title.isEmpty { return "Not Playing" }
        return title
    }

    var menuArtist: String {
        if artist.isEmpty { return "" }
        return artist
    }

    func truncatedDisplay(maxLength: Int) -> String {
        let s = displayString
        if s.count <= maxLength { return s }
        return String(s.prefix(maxLength - 1)) + "…"
    }

    static let empty = Track(title: "", artist: "", isPlaying: false, artworkURL: nil, currentTime: 0, duration: 0)
}
