#!/usr/bin/env python3
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/img/icon-512.png"
OUT_512 = ROOT / "assets/img/icon-maskable-512.png"
OUT_192 = ROOT / "assets/img/icon-maskable-192.png"

with Image.open(SOURCE) as opened:
    source = opened.convert("RGB")
if source.size != (512, 512):
    raise SystemExit(f"expected 512x512 source, got {source.size}")

background = source.getpixel((0, 0))
canvas = Image.new("RGB", (512, 512), background)
inner = source.resize((432, 432), Image.Resampling.LANCZOS)
canvas.paste(inner, (40, 40))
canvas.save(OUT_512, format="PNG", optimize=True, compress_level=9)
canvas.resize((192, 192), Image.Resampling.LANCZOS).save(
    OUT_192, format="PNG", optimize=True, compress_level=9
)

for path in (OUT_192, OUT_512):
    with Image.open(path) as opened:
        image = opened.convert("RGB")
    size = image.width
    if image.size != (size, size):
        raise SystemExit(f"{path}: icon is not square: {image.size}")
    bg = image.getpixel((0, 0))
    radius = size * 0.4
    foreground = (
        (x, y)
        for y in range(size)
        for x in range(size)
        if image.getpixel((x, y)) != bg
    )
    distances = [
        ((x - size / 2) ** 2 + (y - size / 2) ** 2) ** 0.5
        for x, y in foreground
    ]
    if not distances or max(distances) > radius:
        raise SystemExit(f"{path}: foreground leaves the maskable safe circle")
    print(f"{path.relative_to(ROOT)}: {image.size}, safe")
