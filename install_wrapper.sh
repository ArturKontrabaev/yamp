#!/bin/bash
# Install CDP wrapper for Yandex Music
APP_DIR="/Applications/Яндекс Музыка.app/Contents/MacOS"
BINARY="$APP_DIR/Яндекс Музыка"
ORIG="$APP_DIR/Яндекс Музыка.orig"

if [ -f "$ORIG" ]; then
    echo "Wrapper already installed."
    exit 0
fi

if [ ! -f "$BINARY" ]; then
    echo "Yandex Music not found at $BINARY"
    exit 1
fi

echo "Installing CDP wrapper..."
mv "$BINARY" "$ORIG"
cat > "$BINARY" << 'WRAPPER'
#!/bin/bash
exec "$(dirname "$0")/Яндекс Музыка.orig" --remote-debugging-port=9222 "$@"
WRAPPER
chmod +x "$BINARY"
echo "Done! Yandex Music will now always start with CDP enabled."
