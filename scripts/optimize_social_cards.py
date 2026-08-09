#!/usr/bin/env python3
from pathlib import Path
from tempfile import NamedTemporaryFile

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
CARD = ROOT / "assets/img/social-card.png"

before_bytes = CARD.stat().st_size
with Image.open(CARD) as opened:
    if opened.size != (1200, 630):
        raise SystemExit(f"expected 1200x630 card, got {opened.size}")
    baseline = opened.convert("RGBA")
    with NamedTemporaryFile(
        prefix="social-card-", suffix=".png", dir=CARD.parent, delete=False
    ) as temporary:
        temporary_path = Path(temporary.name)
    opened.save(temporary_path, format="PNG", optimize=True, compress_level=9)

try:
    with Image.open(temporary_path) as candidate_opened:
        candidate = candidate_opened.convert("RGBA")
    if candidate.size != baseline.size:
        raise SystemExit("optimized card changed dimensions")
    if ImageChops.difference(baseline, candidate).getbbox() is not None:
        raise SystemExit("optimized card changed decoded pixels")
    after_bytes = temporary_path.stat().st_size
    if after_bytes < before_bytes:
        temporary_path.replace(CARD)
        print(f"{CARD.relative_to(ROOT)}: {before_bytes} -> {after_bytes} bytes")
    else:
        temporary_path.unlink()
        print(f"{CARD.relative_to(ROOT)}: kept {before_bytes} bytes")
finally:
    if temporary_path.exists():
        temporary_path.unlink()
