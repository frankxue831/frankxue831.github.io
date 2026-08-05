#!/usr/bin/env python3
"""Regenerate assets/img/social-card.zh.png — the Chinese share card.

    python3 scripts/build_social_card_zh.py

Dev-only tool. CI does not run it: `scripts/` is excluded from the Jekyll build,
and the card is committed as a PNG, exactly like its English counterpart. Run it
when the Chinese hero copy changes, then commit the regenerated image.

WHY THIS EXISTS AT ALL, AND WHY IT IS ZH-ONLY
    The English card (assets/img/social-card.png) has no generator — it is a
    committed artifact. This script does not try to reproduce it, because the
    brand faces ship as woff2 (assets/fonts/) and Pillow cannot read woff2.
    That does not block the Chinese card: EB Garamond and IBM Plex Mono carry
    no CJK glyphs anyway, so a Chinese card was always going to be set in the
    CJK fallbacks the site's own font stacks already name.

REQUIREMENTS
    * Pillow            pip3 install Pillow
    * macOS system fonts, all members of this site's declared stacks in
      assets/css/style.css:
        Songti SC   -- from --serif's '...Songti SC', 'STSong', 'SimSun'
        Menlo       -- from --mono's '...SFMono-Regular, Menlo,...'
        Georgia It. -- from --serif's '...Georgia,...' (the badge mark)
      On another OS, substitute equivalents and re-check the layout: this
      script positions text by measured advance, so a metrically different
      face will shift the eyebrow and footer runs.

GEOMETRY AND PALETTE
    Both are measured from the shipped English card so the two read as one
    brand: 1200x630, 64px side margins, 64px badge at (64,64), accent rule at
    y=507..508 spanning x=64..1135, and a background that is a bilinear blend
    of the English card's four sampled corner colours. Colour values are the
    :root design tokens. Only the painted copy differs.

REPRODUCIBILITY
    Byte-identical output was verified against the committed card under
    Pillow 12.2.0. A different Pillow (or zlib) may encode the same pixels
    into different PNG bytes — a hash mismatch after an environment change
    means re-encoding, not visual drift. Compare pixels, not bytes, before
    concluding the card changed.
"""
import pathlib
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:  # pragma: no cover - dependency hint
    sys.exit("Pillow is required: pip3 install Pillow")

REPO = pathlib.Path(__file__).resolve().parent.parent
OUT = REPO / "assets/img/social-card.zh.png"

W, H = 1200, 630
MARGIN_L, MARGIN_R = 64, 1136

# Design tokens (assets/css/style.css :root)
FG = (26, 24, 20)           # --fg        #1a1814
FG_MUTED = (107, 101, 87)   # --fg-muted  #6b6557
FG_SUBTLE = (114, 106, 90)  # --fg-subtle #726a5a
ACCENT = (30, 64, 175)      # --accent    #1e40af
RULE = (212, 205, 184)      # --rule      #d4cdb8
BG_SUNK = (250, 247, 240)   # --bg-sunk   #faf7f0

# Corner samples from assets/img/social-card.png (TL, TR, BL, BR)
CORNERS = ((245, 241, 232), (236, 234, 230), (238, 234, 225), (245, 241, 232))

SONGTI = "/System/Library/Fonts/Supplemental/Songti.ttc"
MENLO = "/System/Library/Fonts/Menlo.ttc"
GEORGIA_IT = "/System/Library/Fonts/Supplemental/Georgia Italic.ttf"

# Painted copy. Mirrors the ZH hero on /zh/ — domain first, claim second — and
# the English card's colour semantics, where the closing clause takes accent.
EYEBROW_LATIN = "FRANK XUE  /  "
EYEBROW_CJK = "软件工程师"
HEAD_INK = "为代码、密码学与 Agent，"
HEAD_ACCENT = "写可审计的工具。"
URL = "frankxue.dev"
TAGS = (("Rust  ·  ", "latin"), ("密码学", "cjk"), ("  ·  ", "latin"), ("Agent 工具", "cjk"))


def load_font(path, size, index=0):
    try:
        return ImageFont.truetype(path, size, index=index)
    except OSError:
        sys.exit(
            f"Missing font: {path}\n"
            "This script depends on macOS system fonts — see the module docstring."
        )


def songti(size, bold=True):
    # index 1 = Songti SC Bold, index 6 = Songti SC Regular
    return load_font(SONGTI, size, index=1 if bold else 6)


def menlo(size):
    return load_font(MENLO, size, index=0)


def background():
    """Bilinear blend of the English card's four corner colours."""
    small = Image.new("RGB", (2, 2))
    for xy, colour in zip(((0, 0), (1, 0), (0, 1), (1, 1)), CORNERS):
        small.putpixel(xy, colour)
    return small.resize((W, H), Image.BICUBIC)


def run_width(draw, runs, tracking):
    """Advance width of (text, font) runs drawn with per-character tracking."""
    total = 0.0
    for text, font in runs:
        for ch in text:
            total += draw.textlength(ch, font=font) + tracking
    return total - tracking if total else 0.0


def draw_runs(draw, x, y, runs, tracking, fill):
    """Draw (text, font) runs char by char so Latin and CJK can differ."""
    for text, font in runs:
        for ch in text:
            draw.text((x, y), ch, font=font, fill=fill)
            x += draw.textlength(ch, font=font) + tracking
    return x


def main():
    img = background()
    d = ImageDraw.Draw(img)

    # Badge: 64x64 rounded square with an italic serif "f"
    d.rounded_rectangle([MARGIN_L, 64, MARGIN_L + 64, 128], radius=10,
                        fill=BG_SUNK, outline=RULE, width=1)
    mark = load_font(GEORGIA_IT, 46)
    box = d.textbbox((0, 0), "f", font=mark)
    d.text((MARGIN_L + 32 - (box[0] + box[2]) / 2, 96 - (box[1] + box[3]) / 2),
           "f", font=mark, fill=ACCENT)

    # Eyebrow
    draw_runs(d, 148, 86,
              [(EYEBROW_LATIN, menlo(19)), (EYEBROW_CJK, songti(20, bold=False))],
              tracking=3.6, fill=FG_MUTED)

    # Headline
    head = songti(92)
    d.text((MARGIN_L, 214), HEAD_INK, font=head, fill=FG)
    d.text((MARGIN_L, 364), HEAD_ACCENT, font=head, fill=ACCENT)

    # Accent rule
    d.rectangle([MARGIN_L, 507, MARGIN_R - 1, 508], fill=ACCENT)

    # Footer
    d.text((MARGIN_L, 536), URL, font=menlo(26), fill=FG)
    tag_fonts = {"latin": menlo(21), "cjk": songti(22, bold=False)}
    tag_runs = [(text, tag_fonts[kind]) for text, kind in TAGS]
    width = run_width(d, tag_runs, 1.6)
    draw_runs(d, MARGIN_R - width, 538, tag_runs, tracking=1.6, fill=FG_SUBTLE)

    img.save(OUT, "PNG", optimize=True)

    # scripts/validate_site.rb enforces this on the built site; fail loudly here
    # too, so a bad card never reaches a commit.
    written = Image.open(OUT)
    if written.size != (W, H):
        sys.exit(f"wrote {written.size}, expected {(W, H)} — Open Graph requires 1200x630")
    print(f"wrote {OUT.relative_to(REPO)} ({W}x{H})")


if __name__ == "__main__":
    main()
