#!/usr/bin/env python3
"""Get current track from Yandex Music via CDP — no dependencies"""
import json
import urllib.request
import socket
import hashlib
import base64
import struct
import os

def get_ws_url():
    data = urllib.request.urlopen("http://localhost:9222/json").read()
    pages = json.loads(data)
    for p in pages:
        if p.get("type") == "page" and "music" in p.get("url", ""):
            return p["webSocketDebuggerUrl"]
    return None

def ws_connect(url):
    """Minimal WebSocket client — no dependencies"""
    url = url.replace("ws://", "")
    host_port, path = url.split("/", 1)
    host, port = host_port.split(":")
    path = "/" + path

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((host, int(port)))

    key = base64.b64encode(os.urandom(16)).decode()
    handshake = (
        f"GET {path} HTTP/1.1\r\n"
        f"Host: {host}:{port}\r\n"
        f"Upgrade: websocket\r\n"
        f"Connection: Upgrade\r\n"
        f"Sec-WebSocket-Key: {key}\r\n"
        f"Sec-WebSocket-Version: 13\r\n"
        f"\r\n"
    )
    sock.send(handshake.encode())

    response = b""
    while b"\r\n\r\n" not in response:
        response += sock.recv(4096)

    return sock

def ws_send(sock, data):
    payload = data.encode("utf-8")
    frame = bytearray()
    frame.append(0x81)  # text frame
    length = len(payload)
    mask_key = os.urandom(4)

    if length < 126:
        frame.append(0x80 | length)
    elif length < 65536:
        frame.append(0x80 | 126)
        frame.extend(struct.pack(">H", length))
    else:
        frame.append(0x80 | 127)
        frame.extend(struct.pack(">Q", length))

    frame.extend(mask_key)
    masked = bytearray(b ^ mask_key[i % 4] for i, b in enumerate(payload))
    frame.extend(masked)
    sock.send(frame)

def ws_recv(sock):
    header = sock.recv(2)
    if len(header) < 2:
        return ""
    length = header[1] & 0x7F
    if length == 126:
        length = struct.unpack(">H", sock.recv(2))[0]
    elif length == 127:
        length = struct.unpack(">Q", sock.recv(8))[0]

    data = b""
    while len(data) < length:
        chunk = sock.recv(length - len(data))
        if not chunk:
            break
        data += chunk
    return data.decode("utf-8", errors="replace")

js_code = """
(function() {
    var selectors = [
        '.player-controls__title-track',
        '.d-track__title',
        '[class*="trackTitle"]',
        '[class*="track-title"]',
        '[class*="PlayerBarDesktop"]',
        '.track-name',
        '.player__title',
    ];
    var artistSelectors = [
        '.player-controls__title-artist',
        '.d-track__artists',
        '[class*="trackArtist"]',
        '[class*="track-artist"]',
        '.track-artist',
        '.player__artist',
    ];
    var title = '';
    var artist = '';
    for (var s of selectors) {
        var el = document.querySelector(s);
        if (el && el.textContent.trim()) { title = el.textContent.trim(); break; }
    }
    for (var s of artistSelectors) {
        var el = document.querySelector(s);
        if (el && el.textContent.trim()) { artist = el.textContent.trim(); break; }
    }
    if (!title) {
        var all = document.querySelectorAll('*');
        var found = [];
        for (var el of all) {
            var cls = el.className;
            if (typeof cls === 'string' && (cls.includes('rack') || cls.includes('layer') || cls.includes('itle'))) {
                var t = el.textContent.trim().substring(0, 80);
                if (t && t.length > 1 && t.length < 80) found.push(cls.substring(0,60) + ': ' + t);
            }
        }
        title = 'DEBUG:' + found.slice(0,15).join('|');
    }
    return JSON.stringify({title: title, artist: artist});
})()
"""

if __name__ == "__main__":
    ws_url = get_ws_url()
    if not ws_url:
        print("Yandex Music not found on port 9222")
        exit(1)

    sock = ws_connect(ws_url)
    msg = json.dumps({"id": 1, "method": "Runtime.evaluate", "params": {"expression": js_code, "returnByValue": True}})
    ws_send(sock, msg)
    result = json.loads(ws_recv(sock))
    sock.close()

    if "result" in result and "result" in result["result"]:
        val = result["result"]["result"].get("value", "")
        if val:
            track = json.loads(val)
            print(json.dumps(track, ensure_ascii=False, indent=2))
            exit(0)

    print(json.dumps(result, ensure_ascii=False, indent=2)[:1000])
