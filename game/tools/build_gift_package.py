#!/usr/bin/env python3
"""T-146: builds the gift pack package sprites by script (no PixelLab).

Takes T-140's red-and-gold gift box (art-archive/T-146/gift_box_from_T-140_raw.png),
scales it down to the in-world size (about 40 px wide on a 64x64 canvas, its
bottom on the canvas's bottom row so the sprite stands on the landing spot),
stamps the approved Redgull logo (game/art/logo/redgull_logo_32.png) on a pale
tag on its left face, and draws the parachute variant for the falling look.

    python game/tools/build_gift_package.py build
    python game/tools/build_gift_package.py check

Output: game/art/gift_pack/package.png (on the ground) and package_falling.png
(the same box under a parachute). Hard pixels only: alpha 0 or 255.
"""
from __future__ import annotations
import sys
from pathlib import Path
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from style_rules import REDGULL_RED  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "art-archive/T-146/gift_box_from_T-140_raw.png"
LOGO = ROOT / "game/art/logo/redgull_logo_32.png"
OUT = ROOT / "game/art/gift_pack"
CANVAS = 64
BOX_W = 40
MAX_COLOURS = 30
OUTLINE = (24, 10, 20, 255)
TAG = (236, 224, 200, 255)
TAG_EDGE = (120, 70, 40, 255)
LOGO_RED = REDGULL_RED + (255,)


def hard_alpha(im: Image.Image, cut: int = 128) -> Image.Image:
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= cut else (0, 0, 0, 0)
    return im


def quantize(im: Image.Image, colours: int) -> Image.Image:
    alpha = im.getchannel("A")
    q = im.convert("RGB").quantize(colors=colours, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGBA")
    q.putalpha(alpha)
    return hard_alpha(q)


def box_sprite() -> Image.Image:
    raw = Image.open(RAW).convert("RGBA")
    raw = raw.crop(raw.getbbox())
    h = round(raw.height * BOX_W / raw.width)
    small = hard_alpha(raw.resize((BOX_W, h), Image.BOX))
    small = quantize(small, 24)
    return small


def stamp_logo(box: Image.Image) -> Image.Image:
    """A pale tag with the logo on the right face's lower part."""
    out = box.copy()
    logo = Image.open(LOGO).convert("RGBA")
    logo = logo.crop(logo.getbbox())
    lw = 13
    lh = max(1, round(logo.height * lw / logo.width))
    logo = hard_alpha(logo.resize((lw, lh), Image.BOX))
    tw, th = lw + 2, lh + 2
    tx, ty = box.width - tw - 5, box.height - th - 10
    px = out.load()
    for y in range(th):
        for x in range(tw):
            px[tx + x, ty + y] = TAG_EDGE if x in (0, tw - 1) or y in (0, th - 1) else TAG
    lp = logo.load()
    for y in range(lh):
        for x in range(lw):
            if lp[x, y][3]:
                px[tx + 1 + x, ty + 1 + y] = LOGO_RED
    return out


def on_canvas(sprite: Image.Image, top_room: int = 0) -> Image.Image:
    c = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    c.paste(sprite, ((CANVAS - sprite.width) // 2, CANVAS - sprite.height))
    return c


def parachute(box_canvas: Image.Image) -> Image.Image:
    """The box hung under a red and cream canopy, drawn pixel by pixel."""
    W, H = 64, 64
    # the box is shifted down to leave room; canvas stays 64 wide, 96 tall
    c = Image.new("RGBA", (W, 96), (0, 0, 0, 0))
    c.alpha_composite(box_canvas, (0, 96 - 64))
    px = c.load()
    red, dark, cream = (150, 24, 34, 255), (96, 14, 28, 255), (236, 224, 200, 255)
    cx, top, rx, ry = 32, 2, 28, 18
    # half-ellipse canopy, 6 vertical gores alternating red and cream
    for y in range(top, top + ry + 1):
        dy = (top + ry - y) / ry
        half = round(rx * (1 - dy * dy) ** 0.5)
        for x in range(cx - half, cx + half + 1):
            gore = (x - (cx - rx)) * 6 // (2 * rx + 1)
            col = red if gore % 2 == 0 else cream
            if y == top + ry:  # scalloped lower edge
                col = dark
            px[x, y] = col
    # outline of the canopy
    mask = [(x, y) for y in range(96) for x in range(W) if px[x, y][3] and y < top + ry + 1]
    edge = [(x, y) for x, y in mask if any(
        not (0 <= x + dx < W and 0 <= y + dy < 96) or px[x + dx, y + dy][3] == 0
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for x, y in edge:
        px[x, y] = OUTLINE
    # lines from the canopy's rim to the box's top
    box_top = 96 - 64 + box_canvas.getbbox()[1]
    for sx, ex in ((cx - rx + 1, 24), (cx - 14, 28), (cx + 14, 36), (cx + rx - 1, 40)):
        y0 = top + ry + 1
        n = box_top - y0
        for i in range(n):
            x = round(sx + (ex - sx) * i / max(1, n))
            if px[x, y0 + i][3] == 0:
                px[x, y0 + i] = (210, 200, 180, 255)
    return c


def build() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    pkg = on_canvas(stamp_logo(box_sprite()))
    pkg.save(OUT / "package.png")
    parachute(pkg).save(OUT / "package_falling.png")


def check() -> list[str]:
    errs = []
    for name in ("package.png", "package_falling.png"):
        im = Image.open(OUT / name).convert("RGBA")
        alphas = {p[3] for p in im.getdata()}
        if not alphas <= {0, 255}:
            errs.append(f"{name}: semi-transparent pixels {sorted(alphas)}")
        if im.getpixel((0, 0))[3] != 0:
            errs.append(f"{name}: background not transparent")
        n = len({p for p in im.getdata() if p[3]})
        if n > MAX_COLOURS:
            errs.append(f"{name}: {n} colours")
        print(f"{name}: {im.size}, {n} colours, alpha {sorted(alphas)}")
    return errs


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "check"
    if cmd == "build":
        build()
    errs = check()
    for e in errs:
        print("FAIL", e)
    sys.exit(1 if errs else 0)
