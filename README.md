# YAMP — Yandex Music Player for macOS Menu Bar

Shows the currently playing track from Yandex Music right in your macOS menu bar.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- Current track name and artist in menu bar
- Auto-updates every 2 seconds
- Shows play/pause status
- Quick access to Yandex Music app
- Lightweight, no Electron, pure Swift
- No dock icon — lives only in menu bar

## Install

### Download (recommended)

1. Go to [Releases](../../releases)
2. Download `YAMP.app.zip`
3. Unzip and move `YAMP.app` to Applications
4. First launch: right-click → Open → Open (unsigned app)

### Build from source

Requires macOS 13+ with Xcode Command Line Tools:

```bash
git clone https://github.com/ArturKontrabaev/yamp.git
cd yamp/YAMP
chmod +x build.sh
./build.sh
open build/YAMP.app
```

## How it works

YAMP reads track information from the macOS system Now Playing center via the MediaRemote private framework. This works with any app that publishes to Now Playing — including the Yandex Music desktop app.

## Menu

Click the track name in menu bar to see:

- Full track title
- Artist name
- Play/Pause status
- Open Yandex Music
- Quit

## License

MIT
