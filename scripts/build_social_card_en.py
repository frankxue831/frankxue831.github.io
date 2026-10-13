#!/usr/bin/env python3
"""Redraw the headline on assets/img/social-card.png, the English share card.

    python3 scripts/build_social_card_en.py

Dev-only tool, like build_social_card_zh.py. CI does not run it: `scripts/` is
excluded from the Jekyll build, and the card is committed as a PNG. Run it when
the English hero headline changes, then commit the regenerated image.

WHAT IT CHANGES
    Only the headline band (rows 181-504). The badge, eyebrow, accent rule and
    footer are kept exactly as committed; the card has no from-scratch
    generator. The band is cleared by interpolating each column between rows
    180 and 505 (row 506 carries the accent rule's light halo), which works because the card's background is a smooth
    gradient (local noise measured at one colour level or less). The headline
    is then drawn again, so running the script twice gives the same image.

WHY HEADLESS CHROME
    The brand faces ship as woff2 (assets/fonts/) and Pillow cannot read woff2.
    Chrome sets the headline from the same @font-face files the site uses, on a
    transparent background, and Pillow composites the result onto the card.

GEOMETRY
    Calibrated on 2026-10-12 against the previous card ("Building auditable
    tools / for code, crypto, and / agents."). A replica drawn with these
    settings matched it to within anti-aliasing:
        ink line     EB Garamond 600, 100px, x=66   (the hero's 600 weight)
        accent line  EB Garamond italic 400, 106px, x=65, 101px lower
    The two-line headline starts its ink at y=242, the same as the first line
    of the Chinese card, so the pair keeps one vertical rhythm.

REQUIREMENTS
    * Pillow            pip3 install Pillow
    * Google Chrome     set CHROME to override the macOS path below
"""
import html
import http.server
import os
import pathlib
import subprocess
import sys
import tempfile
import threading

try:
    from PIL import Image
except ImportError:  # pragma: no cover - dependency hint
    sys.exit("Pillow is required: pip3 install Pillow")

REPO = pathlib.Path(__file__).resolve().parent.parent
CARD = REPO / "assets/img/social-card.png"
CHROME = os.environ.get("CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")

W, H = 1200, 630
BAND_TOP, BAND_BOTTOM = 180, 505  # clean rows bounding the cleared band (506 carries the rule's halo)

# Design tokens (assets/css/style.css :root)
INK = "#1a1814"     # --fg
ACCENT = "#1e40af"  # --accent

# Painted copy. Mirrors the EN hero on / ("Building useful software / with AI.").
TOP = 231  # CSS top of the ink line; its ink starts 11px lower, at y=242
LINES = (
    {"text": "Building useful software", "x": 66, "y": TOP, "size": 100, "weight": 600, "italic": False, "color": INK},
    {"text": "with AI.", "x": 65, "y": TOP + 101, "size": 106, "weight": 400, "italic": True, "color": ACCENT},
)

PAGE = """<!doctype html>
<html><head><meta charset="utf-8"><title>card headline</title><style>
@font-face { font-family: 'EBG'; font-style: normal; font-weight: 400 800;
  src: url('/assets/fonts/eb-garamond-latin.woff2') format('woff2'); }
@font-face { font-family: 'EBG'; font-style: italic; font-weight: 400 800;
  src: url('/assets/fonts/eb-garamond-italic-latin.woff2') format('woff2'); }
html, body { margin: 0; padding: 0; background: transparent; }
.c { position: relative; width: 1200px; height: 630px; overflow: hidden; }
.l { position: absolute; white-space: nowrap; line-height: 1; letter-spacing: 0; font-family: 'EBG'; }
</style></head><body><div class="c">%s</div></body></html>
"""


def page_bytes():
    rows = []
    for line in LINES:
        style = (
            f"left:{line['x']}px;top:{line['y']}px;font-size:{line['size']}px;"
            f"font-weight:{line['weight']};font-style:{'italic' if line['italic'] else 'normal'};"
            f"color:{line['color']}"
        )
        rows.append(f'<div class="l" style="{style}">{html.escape(line["text"])}</div>')
    return (PAGE % "".join(rows)).encode("utf-8")


class Handler(http.server.SimpleHTTPRequestHandler):
    """Serves the repository (for the woff2 files) plus the generated page."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(REPO), **kwargs)

    def log_message(self, *args):  # keep the console quiet
        pass

    def do_GET(self):
        if self.path == "/__card_headline__.html":
            body = page_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()


def render_headline(workdir):
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        shot = workdir / "headline.png"
        url = f"http://127.0.0.1:{server.server_address[1]}/__card_headline__.html"
        subprocess.run(
            [CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
             f"--user-data-dir={workdir / 'profile'}", "--force-device-scale-factor=1",
             f"--window-size={W},{H}", "--default-background-color=00000000",
             "--virtual-time-budget=3000", f"--screenshot={shot}", url],
            check=True, capture_output=True,
        )
        return Image.open(shot).convert("RGBA")
    finally:
        server.shutdown()


def main():
    if not pathlib.Path(CHROME).exists():
        sys.exit(f"Chrome not found at {CHROME}; set CHROME to its path.")
    card = Image.open(CARD).convert("RGB")
    if card.size != (W, H):
        sys.exit(f"expected a {W}x{H} card, got {card.size}")

    # Clear the headline band by column-wise interpolation between its clean edges.
    px = card.load()
    for x in range(W):
        top, bottom = px[x, BAND_TOP], px[x, BAND_BOTTOM]
        for y in range(BAND_TOP + 1, BAND_BOTTOM):
            t = (y - BAND_TOP) / (BAND_BOTTOM - BAND_TOP)
            px[x, y] = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))

    with tempfile.TemporaryDirectory(prefix="social-card-en-") as tmp:
        headline = render_headline(pathlib.Path(tmp))
    if headline.size != (W, H):
        sys.exit(f"headline render is {headline.size}, expected {(W, H)}")
    ink = headline.getchannel("A").getbbox()
    if ink is None:
        sys.exit("headline render is empty (fonts not loaded?)")
    if ink[1] <= BAND_TOP or ink[3] > BAND_BOTTOM:
        sys.exit(f"headline ink {ink} leaves the cleared band rows {BAND_TOP + 1}-{BAND_BOTTOM - 1}")

    out = Image.alpha_composite(card.convert("RGBA"), headline).convert("RGB")
    out.save(CARD, "PNG", optimize=True)

    # scripts/validate_site.rb enforces this on the built site; fail loudly here
    # too, so a bad card never reaches a commit.
    written = Image.open(CARD)
    if written.size != (W, H):
        sys.exit(f"wrote {written.size}, expected {(W, H)} — Open Graph requires 1200x630")
    print(f"wrote {CARD.relative_to(REPO)} ({W}x{H}); headline ink box {ink}")


if __name__ == "__main__":
    main()
