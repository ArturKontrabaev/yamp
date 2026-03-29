#!/usr/bin/env python3
"""Get current track from Yandex Music via Chrome DevTools Protocol"""
import json
import urllib.request
import websocket  # pip3 install websocket-client

def get_ws_url():
    data = urllib.request.urlopen("http://localhost:9222/json").read()
    pages = json.loads(data)
    for p in pages:
        if p.get("type") == "page" and "music" in p.get("url", ""):
            return p["webSocketDebuggerUrl"]
    return None

def get_track(ws_url):
    ws = websocket.create_connection(ws_url)

    # Try multiple selectors to find the track
    js = """
    (function() {
        // Try common selectors for Yandex Music player
        var selectors = [
            '.player-controls__title-track',
            '.d-track__title',
            '[class*="trackTitle"]',
            '[class*="track-title"]',
            '[data-test="track-title"]',
            '.track-name',
            '.player__title',
        ];
        var artistSelectors = [
            '.player-controls__title-artist',
            '.d-track__artists',
            '[class*="trackArtist"]',
            '[class*="track-artist"]',
            '[data-test="track-artist"]',
            '.track-artist',
            '.player__artist',
        ];

        var title = '';
        var artist = '';

        for (var s of selectors) {
            var el = document.querySelector(s);
            if (el && el.textContent.trim()) {
                title = el.textContent.trim();
                break;
            }
        }

        for (var s of artistSelectors) {
            var el = document.querySelector(s);
            if (el && el.textContent.trim()) {
                artist = el.textContent.trim();
                break;
            }
        }

        // If nothing found, try to get from document title or any visible player element
        if (!title) {
            // Look for any element with track-like content in the player area
            var playerEl = document.querySelector('[class*="player"]') || document.querySelector('[class*="Player"]');
            if (playerEl) {
                var allText = playerEl.innerText;
                if (allText) title = 'PLAYER_TEXT: ' + allText.substring(0, 200);
            }
        }

        // Last resort: dump all class names containing 'track' or 'player' or 'title'
        if (!title) {
            var allEls = document.querySelectorAll('*');
            var classes = [];
            for (var el of allEls) {
                var cls = el.className;
                if (typeof cls === 'string' && (cls.includes('track') || cls.includes('Track') || cls.includes('player') || cls.includes('Player'))) {
                    var text = el.textContent.trim().substring(0, 100);
                    if (text) classes.push(cls.substring(0, 80) + ' => ' + text);
                }
            }
            if (classes.length > 0) title = 'CLASSES: ' + classes.slice(0, 10).join(' | ');
        }

        return JSON.stringify({title: title, artist: artist});
    })()
    """

    msg = json.dumps({
        "id": 1,
        "method": "Runtime.evaluate",
        "params": {"expression": js, "returnByValue": True}
    })

    ws.send(msg)
    result = json.loads(ws.recv())
    ws.close()

    if "result" in result and "result" in result["result"]:
        val = result["result"]["result"].get("value", "")
        if val:
            track = json.loads(val)
            return track

    return {"title": "", "artist": "", "raw": str(result)[:500]}

if __name__ == "__main__":
    ws_url = get_ws_url()
    if not ws_url:
        print("Yandex Music not found. Launch with: open -a 'Яндекс Музыка' --args --remote-debugging-port=9222")
    else:
        track = get_track(ws_url)
        print(json.dumps(track, ensure_ascii=False, indent=2))
