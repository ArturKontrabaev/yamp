#!/usr/bin/env python3
"""Check Like button state — full innerHTML"""
import json, urllib.request, socket, os, struct, base64

def ws_connect(url):
    url = url.replace("ws://", "")
    hp, path = url.split("/", 1)
    h, p = hp.split(":")
    path = "/" + path
    s = socket.socket()
    s.settimeout(5)
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

pages = json.loads(urllib.request.urlopen("http://localhost:9222/json").read())
wsu = [p["webSocketDebuggerUrl"] for p in pages if p.get("type") == "page" and "music" in p.get("url", "")][0]
s = ws_connect(wsu)

js = """
(function() {
    var bar = document.querySelector('[class*="PlayerBarDesktop"]');
    if (!bar) return 'NO BAR';
    var btn = bar.querySelector('[aria-label="Like"]');
    if (!btn) return 'NO LIKE BUTTON';
    return btn.innerHTML;
})()
"""

msg = json.dumps({"id": 1, "method": "Runtime.evaluate", "params": {"expression": js, "returnByValue": True}})
ws_send(s, msg)
res = json.loads(ws_recv(s))
s.close()
print(res.get("result", {}).get("result", {}).get("value", ""))
