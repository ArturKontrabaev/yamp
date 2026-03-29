import Cocoa

class NowPlayingPopover: NSView {
    private var track: Track = .empty
    private let titleLabel = NSTextField(labelWithString: "")
    private let artistLabel = NSTextField(labelWithString: "")
    private let artworkView = NSImageView()
    private let progressBar = NSProgressIndicator()
    private let timeLabel = NSTextField(labelWithString: "")
    private let prevButton = NSButton()
    private let playPauseButton = NSButton()
    private let nextButton = NSButton()
    private let likeButton = NSButton()
    private let settingsButton = NSButton()

    weak var delegate: NowPlayingPopoverDelegate?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // Layout: 296 x 148
    // [16] artwork(56x56) [12] title/artist [16]
    // [16] progress bar [16]
    // [16] controls [16]

    private func setup() {
        wantsLayer = true

        // Artwork
        artworkView.frame = NSRect(x: 16, y: 76, width: 56, height: 56)
        artworkView.imageScaling = .scaleProportionallyUpOrDown
        artworkView.wantsLayer = true
        artworkView.layer?.cornerRadius = 8
        artworkView.layer?.masksToBounds = true
        artworkView.layer?.backgroundColor = NSColor.tertiaryLabelColor.cgColor
        addSubview(artworkView)

        // Title
        titleLabel.frame = NSRect(x: 84, y: 104, width: 196, height: 22)
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 1
        addSubview(titleLabel)

        // Artist
        artistLabel.frame = NSRect(x: 84, y: 84, width: 196, height: 18)
        artistLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        artistLabel.textColor = NSColor.secondaryLabelColor
        artistLabel.lineBreakMode = .byTruncatingTail
        artistLabel.maximumNumberOfLines = 1
        addSubview(artistLabel)

        // Progress bar
        progressBar.frame = NSRect(x: 16, y: 60, width: 264, height: 4)
        progressBar.style = .bar
        progressBar.minValue = 0
        progressBar.maxValue = 100
        progressBar.doubleValue = 0
        progressBar.isIndeterminate = false
        progressBar.controlSize = .small
        addSubview(progressBar)

        // Time label
        timeLabel.frame = NSRect(x: 16, y: 42, width: 264, height: 14)
        timeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        timeLabel.textColor = NSColor.tertiaryLabelColor
        timeLabel.alignment = .center
        addSubview(timeLabel)

        // Control buttons
        let buttonY: CGFloat = 8
        let buttonSize: CGFloat = 32

        setupButton(prevButton, title: "⏮", x: 60, y: buttonY, size: buttonSize, action: #selector(prevTapped))
        setupButton(playPauseButton, title: "▶", x: 104, y: buttonY, size: buttonSize, action: #selector(playPauseTapped))
        playPauseButton.font = NSFont.systemFont(ofSize: 18)
        setupButton(nextButton, title: "⏭", x: 148, y: buttonY, size: buttonSize, action: #selector(nextTapped))
        setupButton(likeButton, title: "♡", x: 200, y: buttonY, size: buttonSize, action: #selector(likeTapped))
        setupButton(settingsButton, title: "⚙", x: 248, y: buttonY, size: buttonSize, action: #selector(settingsTapped))
    }

    private func setupButton(_ btn: NSButton, title: String, x: CGFloat, y: CGFloat, size: CGFloat, action: Selector) {
        btn.frame = NSRect(x: x, y: y, width: size, height: size)
        btn.title = title
        btn.bezelStyle = .recessed
        btn.isBordered = false
        btn.font = NSFont.systemFont(ofSize: 15)
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

        // Progress
        if track.duration > 0 {
            progressBar.doubleValue = (track.currentTime / track.duration) * 100
            timeLabel.stringValue = "\(formatTime(track.currentTime)) / \(formatTime(track.duration))"
        } else {
            progressBar.doubleValue = 0
            timeLabel.stringValue = ""
        }

        // Artwork
        if let url = track.artworkURL, !url.isEmpty {
            loadArtwork(urlString: url)
        } else {
            artworkView.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: nil)
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var lastArtworkURL: String = ""
    private func loadArtwork(urlString: String) {
        guard urlString != lastArtworkURL else { return }
        lastArtworkURL = urlString
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = NSImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.artworkView.image = image
            }
        }.resume()
    }

    @objc private func prevTapped() { delegate?.didTapPrev() }
    @objc private func playPauseTapped() { delegate?.didTapPlayPause() }
    @objc private func nextTapped() { delegate?.didTapNext() }
    @objc private func likeTapped() { delegate?.didTapLike() }
    @objc private func settingsTapped() { delegate?.didTapSettings() }
}

protocol NowPlayingPopoverDelegate: AnyObject {
    func didTapPrev()
    func didTapPlayPause()
    func didTapNext()
    func didTapLike()
    func didTapSettings()
}
