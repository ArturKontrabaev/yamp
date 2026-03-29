import Cocoa

protocol NowPlayingPopoverDelegate: AnyObject {
    func didTapPrev()
    func didTapPlayPause()
    func didTapNext()
    func didTapLike()
    func didTapSettings()
}

class NowPlayingPopover: NSView {
    private var track: Track = .empty
    private let artworkView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let artistLabel = NSTextField(labelWithString: "")
    private let prevButton = NSButton()
    private let playPauseButton = NSButton()
    private let nextButton = NSButton()
    private let likeButton = NSButton()
    private let settingsButton = NSButton()
    private let quitButton = NSButton()

    weak var delegate: NowPlayingPopoverDelegate?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true

        // Artwork — 56x56 rounded
        artworkView.frame = NSRect(x: 16, y: 36, width: 56, height: 56)
        artworkView.imageScaling = .scaleProportionallyUpOrDown
        artworkView.wantsLayer = true
        artworkView.layer?.cornerRadius = 8
        artworkView.layer?.masksToBounds = true
        artworkView.layer?.backgroundColor = NSColor.tertiaryLabelColor.cgColor
        artworkView.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: nil)
        addSubview(artworkView)

        // Title
        titleLabel.frame = NSRect(x: 84, y: 64, width: 196, height: 22)
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 1
        addSubview(titleLabel)

        // Artist
        artistLabel.frame = NSRect(x: 84, y: 44, width: 196, height: 18)
        artistLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        artistLabel.textColor = NSColor.secondaryLabelColor
        artistLabel.lineBreakMode = .byTruncatingTail
        artistLabel.maximumNumberOfLines = 1
        addSubview(artistLabel)

        // Controls row
        let y: CGFloat = 6
        let sz: CGFloat = 30
        makeBtn(prevButton, "⏮", x: 70, y: y, sz: sz, action: #selector(prevTap), fontSize: 14)
        makeBtn(playPauseButton, "▶", x: 108, y: y, sz: sz, action: #selector(playPauseTap), fontSize: 18)
        makeBtn(nextButton, "⏭", x: 146, y: y, sz: sz, action: #selector(nextTap), fontSize: 14)
        makeBtn(likeButton, "♡", x: 192, y: y, sz: sz, action: #selector(likeTap), fontSize: 16)
        makeBtn(settingsButton, "⚙", x: 236, y: y, sz: 24, action: #selector(settingsTap), fontSize: 13)
        settingsButton.frame.origin.y = y + 3
        makeBtn(quitButton, "✕", x: 266, y: y, sz: 24, action: #selector(quitTap), fontSize: 12)
        quitButton.frame.origin.y = y + 3
        quitButton.contentTintColor = NSColor.secondaryLabelColor
    }

    private func makeBtn(_ btn: NSButton, _ title: String, x: CGFloat, y: CGFloat, sz: CGFloat, action: Selector, fontSize: CGFloat) {
        btn.frame = NSRect(x: x, y: y, width: sz, height: sz)
        btn.title = title
        btn.bezelStyle = .recessed
        btn.isBordered = false
        btn.font = NSFont.systemFont(ofSize: fontSize)
        btn.target = self
        btn.action = action
        btn.focusRingType = .none
        addSubview(btn)
    }

    func update(with track: Track) {
        self.track = track
        titleLabel.stringValue = track.title.isEmpty ? "Not Playing" : track.title
        artistLabel.stringValue = track.artist
        playPauseButton.title = track.isPlaying ? "⏸" : "▶"
        likeButton.title = track.isLiked ? "♥" : "♡"

        if let url = track.artworkURL, !url.isEmpty {
            loadArtwork(url)
        } else {
            artworkView.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: nil)
        }
    }

    private var lastArtworkURL = ""
    private func loadArtwork(_ urlString: String) {
        guard urlString != lastArtworkURL else { return }
        lastArtworkURL = urlString
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let img = NSImage(data: data) else { return }
            DispatchQueue.main.async { self?.artworkView.image = img }
        }.resume()
    }

    @objc private func prevTap() { delegate?.didTapPrev() }
    @objc private func playPauseTap() { delegate?.didTapPlayPause() }
    @objc private func nextTap() { delegate?.didTapNext() }
    @objc private func likeTap() { delegate?.didTapLike() }
    @objc private func settingsTap() { delegate?.didTapSettings() }
    @objc private func quitTap() { NSApp.terminate(nil) }
}
