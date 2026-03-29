# YAMP — Yandex Music Player for macOS

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0+-black?logo=apple" />
  <img src="https://img.shields.io/badge/Swift-5.8-orange?logo=swift" />
  <img src="https://img.shields.io/badge/license-MIT-green" />
  <img src="https://img.shields.io/github/v/release/ArturKontrabaev/yamp" />
</p>

A lightweight macOS menu bar app that shows the currently playing track from **Yandex Music** and gives you quick controls — without switching away from what you're doing.

## Why

The official Yandex Music desktop app doesn't expose track info to macOS Now Playing on newer versions, and doesn't support global hotkeys. YAMP fills that gap.

## Features

- **Current track in menu bar** — see artist and title at a glance
- **Now Playing popover** — click to see album art, track info, and controls
- **Playback controls** — play/pause, next, previous
- **Like button** — add to favorites without opening the app (won't accidentally unlike)
- **Dislike button** — never play this track again
- **Global hotkeys** — configure custom keyboard shortcuts for all actions
- **Customizable icon** — choose from Now Playing waveform, music note, headphones, and more
- **Smart pause** — optionally show only icon when paused, track name when playing
- **Launch at login** — start automatically with your Mac
- **Lightweight** — pure Swift, no Electron, minimal CPU usage

## Install

### Download

1. Go to [**Releases**](../../releases/latest)
2. Download `YAMP.app.zip`
3. Unzip and move `YAMP.app` to **Applications**
4. First launch: right-click → Open → Open (the app is unsigned)

### Requirements

- macOS 13.0 or later
- Yandex Music desktop app (official)
- On first launch, Yandex Music will be restarted with debug mode enabled

### Build from source

Requires Xcode Command Line Tools:

```bash
git clone https://github.com/ArturKontrabaev/yamp.git
cd yamp/YAMP
chmod +x build.sh
./build.sh
open build/YAMP.app
```

## Setup

YAMP connects to Yandex Music via Chrome DevTools Protocol. You need to launch Yandex Music with a special flag:

```bash
killall "Яндекс Музыка"
open -a "Яндекс Музыка" --args --remote-debugging-port=9222
```

YAMP will automatically detect the running instance.

## Settings

Click the ⚙ button in the popover to open settings:

- **Max display length** — how many characters to show in menu bar
- **Menu bar icon** — choose from several styles
- **Show icon only when paused** — hide track name when music is paused
- **Keyboard shortcuts** — click to record custom hotkeys for play/pause, next, previous, like, dislike
- **Launch at login** — auto-start with macOS

## How it works

Since macOS 26 (Tahoe) blocks the MediaRemote API for third-party apps, YAMP uses an alternative approach:

1. Connects to Yandex Music's Electron app via Chrome DevTools Protocol (CDP)
2. Reads track info directly from the app's DOM
3. Controls playback by clicking the actual UI buttons programmatically

This means YAMP works reliably regardless of macOS version restrictions.

## Tech stack

- **Swift** — native macOS app, no Electron
- **AppKit** — NSStatusItem, NSPopover
- **CDP** — Chrome DevTools Protocol via Python helper scripts
- **Carbon** — RegisterEventHotKey for global hotkeys

## License

MIT — see [LICENSE](LICENSE)

## Credits

Built by [Artur Kontrabaev](https://github.com/ArturKontrabaev)
