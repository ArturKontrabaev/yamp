#!/bin/bash
set -e
APP_NAME="YAMP"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
echo "Building $APP_NAME..."
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
cp YAMP/Info.plist "$APP_BUNDLE/Contents/"
swiftc \
    -target arm64-apple-macosx13.0 \
    -sdk $(xcrun --show-sdk-path) \
    -framework AppKit \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    YAMP/main.swift \
    YAMP/Track.swift \
    YAMP/Settings.swift \
    YAMP/NowPlayingTrackProvider.swift \
    YAMP/NowPlayingPopover.swift \
    YAMP/HotkeyManager.swift \
    YAMP/SettingsWindow.swift \
    YAMP/ToastWindow.swift \
    YAMP/MenubarController.swift \
    YAMP/AppDelegate.swift
echo ""
echo "Done! App bundle: $APP_BUNDLE"
echo "Run:  open $APP_BUNDLE"
