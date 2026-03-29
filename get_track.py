#!/usr/bin/env python3
"""Get current track from Yandex Music via CDP — no dependencies"""
import json
import urllib.request
import socket
import struct
import os
import sys

def get_ws_url():
    data = urllib.request.urlopen("http://localhost:9222/json").read()
    pages = json.loads(data)
    for p in pages:
        if p.get("type") == "page" and "music" in p.get("url", ""):
            return p["webSocketDebuggerUrl"]
    return None

def ws_connect(url):
    import base64
    url = url.replace("ws://", "")
    host_port, path = url.split("/", 1)
    host, port = host_port.split(":")
    path = "/" + path
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((host, int(port)))
    key = base64.b64encode(os.urandom(16)).decode()
    handshake = f"GET {path} HTTP/1.1\r\nHost: {host}:{port}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n"
    sock.send(handshake.encode())
    response = b""
    while b"\r\n\r\n" not in response:
        response += sock.recv(4096)
    return sock

def ws_send(sock, data):
    payload = data.encode("utf-8")
    frame = bytearray([0x81])
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
    frame.extend(bytearray(b ^ mask_key[i % 4] for i, b in enumerate(payload)))
    sock.send(frame)

def ws_recv(sock):
    header = sock.recv(2)
    if len(header) < 2: return ""
    length = header[1] & 0x7F
    if length == 126: length = struct.unpack(">H", sock.recv(2))[0]
    elif length == 127: length = struct.unpack(">Q", sock.recv(8))[0]
    data = b""
    while len(data) < length:
        chunk = sock.recv(length - len(data))
        if not chunk: break
        data += chunk
    return data.decode("utf-8", errors="replace")

def cdp_eval(sock, js):
    msg = json.dumps({"id": 1, "method": "Runtime.evaluate", "params": {"expression": js, "returnByValue": True}})
    ws_send(sock, msg)
    result = json.loads(ws_recv(sock))
    if "result" in result and "result" in result["result"]:
        return result["result"]["result"].get("value", "")
    return ""

# First pass: dump all relevant DOM structure to find correct selectors
JS_DUMP = """
(function() {
    var results = [];
    var all = document.querySelectorAll('a, span, div, button');
    for (var el of all) {
        var cls = (typeof el.className === 'string') ? el.className : '';
        var text = el.textContent.trim();
        var children = el.children.length;
        // Only leaf-ish elements with short text
        if (text && text.length > 0 && text.length < 100 && children < 3) {
            if (cls.toLowerCase().includes('track') || cls.toLowerCase().includes('title') ||
                cls.toLowerCase().includes('artist') || cls.toLowerCase().includes('player') ||
                cls.toLowerCase().includes('bar')) {
                results.push({tag: el.tagName, cls: cls.substring(0,80), text: text, href: el.href || ''});
            }
        }
    }
    return JSON.stringify(results);
})()
"""

JS_TRACK = """
(function() {
    // Based on known Yandex Music desktop app DOM
    var title = '';
    var artist = '';

    // Try specific selectors
    var titleEl = document.querySelector('.PlayerBarDesktop_title__kbMYh a')
        || document.querySelector('[class*="PlayerBarDesktop_title"] a')
        || document.querySelector('[class*="PlayerBar"] [class*="title"] a');
    if (titleEl) title = titleEl.textContent.trim();

    var artistEl = document.querySelector('.PlayerBarDesktop_artist__b4WT0 a')
        || document.querySelector('[class*="PlayerBarDesktop_artist"] a')
        || document.querySelector('[class*="PlayerBar"] [class*="artist"] a');
    if (artistEl) artist = artistEl.textContent.trim();

    return JSON.stringify({title: title, artist: artist});
})()
"""

if __name__ == "__main__":
    ws_url = get_ws_url()
    if not ws_url:
        print("Yandex Music not found on port 9222")
        exit(1)

    sock = ws_connect(ws_url)

    if len(sys.argv) > 1 and sys.argv[1] == "dump":
        # Dump mode: find all relevant elements
        raw = cdp_eval(sock, JS_DUMP)
        if raw:
            items = json.loads(raw)
            for item in items:
                print(f"{item['tag']:6} | {item['cls'][:60]:60} | {item['text'][:50]}")
    else:
        # Normal mode: get track
        raw = cdp_eval(sock, JS_TRACK)
        if raw:
            track = json.loads(raw)
            if track["title"]:
                print(json.dumps(track, ensure_ascii=False, indent=2))
            else:
                print("Selectors didn't match. Running dump mode...")
                print()
                raw2 = cdp_eval(sock, JS_DUMP)
                if raw2:
                    items = json.loads(raw2)
                    for item in items:
                        print(f"{item['tag']:6} | {item['cls'][:60]:60} | {item['text'][:50]}")

    sock.close()
