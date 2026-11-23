#!/usr/bin/env python3
"""Rebuild dsh/client.js by re-embedding dist/startup-anim.html and dist/score.mp3.

The plugin bundle is a single browser module with the whole page and the score
inlined as base64, so editing the animation only needs this one pass:

    python build.py

No npm, no bundler, no network.
"""
import base64
import os
import re
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
HTML = os.path.join(ROOT, "dist", "startup-anim.html")
MP3 = os.path.join(ROOT, "dist", "score.mp3")
CLIENT = os.path.join(ROOT, "dsh", "client.js")

if not os.path.exists(CLIENT):
    sys.exit("missing dsh/client.js")

html = open(HTML, encoding="utf-8").read()
# the overlay is a full-screen iframe: no dev hint bar, and no local <audio>
# (the parent frame owns the score and its gesture handling)
html = html.replace('<div id="hintbar">空格 跳过 · R 重播 · ESC 结束</div>', "")
html = re.sub(r"<!--AUDIO-START-->.*?<!--AUDIO-END-->", "", html, flags=re.S)

mp3 = b""
if os.path.exists(MP3):
    mp3 = open(MP3, "rb").read()

html_b64 = base64.b64encode(html.encode("utf-8")).decode("ascii")
music_b64 = base64.b64encode(mp3).decode("ascii") if mp3 else ""

src = open(CLIENT, encoding="utf-8").read()
src, n1 = re.subn(r"var HTML_B64 = '[A-Za-z0-9+/=]*'", "var HTML_B64 = '" + html_b64 + "'", src, count=1)
src, n2 = re.subn(r"var MUSIC_B64 = '[A-Za-z0-9+/=]*'", "var MUSIC_B64 = '" + music_b64 + "'", src, count=1)
if not n1 or not n2:
    sys.exit("could not find HTML_B64 / MUSIC_B64 markers in dsh/client.js")

open(CLIENT, "w", encoding="utf-8", newline="\n").write(src)
print("rebuilt %s\n  html %.1f KB -> b64 %.1f KB\n  mp3  %.1f KB -> b64 %.1f KB"
      % (CLIENT, len(html) / 1024, len(html_b64) / 1024, len(mp3) / 1024, len(music_b64) / 1024))
