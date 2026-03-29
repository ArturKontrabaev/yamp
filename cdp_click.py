#!/usr/bin/env python3
"""Click a button in Yandex Music via CDP"""
import json, urllib.request, socket, os, struct, base64, sys

def ws_connect(url):
    url = url.replace("ws://", "")
    hp, path = url.split("/", 1)
    h, p = hp.split(":")
    path = "/" + path
    s = socket.socket()
    s.settimeout(3)
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

COMMANDS = {
    "play": """(function(){var bar=document.querySelector('[class*="PlayerBarDesktop"]');if(!bar)return;var btn=bar.querySelector('[aria-label="Playback"]')||bar.querySelector('[aria-label="Pause"]');if(btn)btn.click();})()""",
    "next": """document.querySelector('[class*="PlayerBarDesktop"] [aria-label="Next song"]')?.click()""",
    "prev": """document.querySelector('[class*="PlayerBarDesktop"] [aria-label="Previous song"]')?.click()""",
    "like": """(function(){var bar=document.querySelector('[class*="PlayerBarDesktop"]');if(!bar)return;var btn=bar.querySelector('[aria-label="Like"]');if(!btn)return;var use=btn.querySelector('use');var href=(use&&(use.getAttribute('xlink:href')||use.getAttribute('href')))||'';if(href.includes('liked'))return 'already liked';btn.click();return 'liked'})()""",
}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: cdp_click.py [play|next|prev|like]")
        exit(1)

    cmd = sys.argv[1]
    js = COMMANDS.get(cmd, cmd)

    try:
        pages = json.loads(urllib.request.urlopen("http://localhost:9222/json", timeout=3).read())
        wsu = [p["webSocketDebuggerUrl"] for p in pages if p.get("type") == "page" and "music" in p.get("url", "")]
        if not wsu:
            exit(1)
        s = ws_connect(wsu[0])
        ws_send(s, json.dumps({"id": 1, "method": "Runtime.evaluate", "params": {"expression": js}}))
        s.close()
    except Exception:
        exit(1)
