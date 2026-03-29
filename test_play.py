#!/usr/bin/env python3
"""Test different play/pause approaches"""
import json, urllib.request, socket, os, struct, base64, sys

def ws_connect(url):
    url = url.replace("ws://", "")
    hp, path = url.split("/", 1)
    h, p = hp.split(":")
    path = "/" + path
    s = socket.socket()
    s.connect((h, int(p)))
    k = base64.b64encode(os.urandom(16)).decode()
    s.send(f"GET {path} HTTP/1.1\r\nHost:{h}:{p}\r\nUpgrade:websocket\r\nConnection:Upgrade\r\nSec-WebSocket-Key:{k}\r\nSec-WebSocket-Version:13\r\n\r\n".encode())
    r = b""
    while b"\r\n\r\n" not in r:
        r += s.recv(4096)
    return s

def ws_send(s, t):
    p = t.encode()
    f = bytearray([0x81])
    m = os.urandom(4)
    if len(p) < 126:
        f.append(0x80 | len(p))
    else:
        f.append(0x80 | 126)
        f.extend(struct.pack(">H", len(p)))
    f.extend(m)
    f.extend(bytearray(b ^ m[i % 4] for i, b in enumerate(p)))
    s.send(f)

def ws_recv(s):
    h = s.recv(2)
    l = h[1] & 0x7F
    if l == 126:
        d = s.recv(2)
        l = struct.unpack(">H", d)[0]
    elif l == 127:
        d = s.recv(8)
        l = struct.unpack(">Q", d)[0]
    r = b""
    while len(r) < l:
        r += s.recv(l - len(r))
    return r.decode()

def cdp_eval(s, js):
    msg = json.dumps({"id": 1, "method": "Runtime.evaluate", "params": {"expression": js, "returnByValue": True}})
    ws_send(s, msg)
    res = json.loads(ws_recv(s))
    return res.get("result", {}).get("result", {}).get("value", "")

pages = json.loads(urllib.request.urlopen("http://localhost:9222/json").read())
wsu = [p["webSocketDebuggerUrl"] for p in pages if p.get("type") == "page" and "music" in p.get("url", "")][0]

s = ws_connect(wsu)

approach = sys.argv[1] if len(sys.argv) > 1 else "space"

if approach == "space":
    print("Approach: dispatch Space keypress to document")
    js = """
    (function() {
        document.dispatchEvent(new KeyboardEvent('keydown', {key: ' ', code: 'Space', keyCode: 32, bubbles: true}));
        document.dispatchEvent(new KeyboardEvent('keyup', {key: ' ', code: 'Space', keyCode: 32, bubbles: true}));
        return 'dispatched space';
    })()
    """
elif approach == "click":
    print("Approach: click button")
    js = """
    (function() {
        var btn = document.querySelector('[aria-label="Playback"]') || document.querySelector('[aria-label="Pause"]');
        if (btn) { btn.click(); return 'clicked: ' + btn.getAttribute('aria-label'); }
        return 'not found';
    })()
    """
elif approach == "mouse":
    print("Approach: dispatch mouse events")
    js = """
    (function() {
        var btn = document.querySelector('[aria-label="Playback"]') || document.querySelector('[aria-label="Pause"]');
        if (btn) {
            var rect = btn.getBoundingClientRect();
            var x = rect.x + rect.width/2;
            var y = rect.y + rect.height/2;
            btn.dispatchEvent(new MouseEvent('mousedown', {bubbles: true, clientX: x, clientY: y}));
            btn.dispatchEvent(new MouseEvent('mouseup', {bubbles: true, clientX: x, clientY: y}));
            btn.dispatchEvent(new MouseEvent('click', {bubbles: true, clientX: x, clientY: y}));
            return 'mouse events on: ' + btn.getAttribute('aria-label');
        }
        return 'not found';
    })()
    """
elif approach == "api":
    print("Approach: Yandex Music internal API")
    js = """
    (function() {
        // Try to find the player API in window/global scope
        var keys = Object.keys(window).filter(k => k.toLowerCase().includes('player') || k.toLowerCase().includes('audio') || k.toLowerCase().includes('music'));
        if (keys.length > 0) return 'window keys: ' + keys.join(', ');

        // Try externalAPI (used by yandex-music-app)
        if (window.externalAPI) {
            try { window.externalAPI.togglePause(); return 'externalAPI.togglePause()'; } catch(e) { return 'externalAPI error: ' + e; }
        }

        // Try to find audio element
        var audio = document.querySelector('audio');
        if (audio) {
            if (audio.paused) { audio.play(); return 'audio.play()'; }
            else { audio.pause(); return 'audio.pause()'; }
        }

        return 'no API found, window keys sample: ' + Object.keys(window).slice(0, 20).join(', ');
    })()
    """

result = cdp_eval(s, js)
print("Result:", result)
s.close()
