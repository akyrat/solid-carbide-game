#!/usr/bin/env python3
"""Builds the gift pack package sprites by script (no PixelLab).

T-146 made them from T-140's red-and-gold gift box in the old sponsor's colours. T-304 rebuilds
them in Greenbull's colours (Visual style, Decisions, "The rebrand", "Greenbull's look";
rule 6): T-140's box (art-archive/T-146/gift_box_from_T-140_raw.png, read only) is
recoloured with the level-up screen's gift box mapping (build_level_up_art.recolour_box,
T-303: red box -> dark greens, gold ribbon -> light greens, small sparkles -> yellow),
scaled down to the in-world size (about 40 px wide on a 64x64 canvas, its bottom on the
canvas's bottom row so the sprite stands on the landing spot), and Greenbull's approved
emblem (game/art/logo/greenbull_emblem_32.png, the bull's head) is stamped on a pale tag
on its right face, snapped to the emblem's own five colours. The falling look hangs the
same box under a dark green and cream parachute.

    python game/tools/build_gift_package.py build
    python game/tools/build_gift_package.py check
    python game/tools/build_gift_package.py piece package|package_falling <png>   # the style loop's step
    python game/tools/build_gift_package.py archive    # copies the current game files to
                                                       # OLD_ARCHIVE in art-archive/T-304/ (never overwrites)

Output: game/art/gift_pack/package.png (on the ground, 64 x 64) and package_falling.png
(under the parachute, 64 x 96). Hard pixels only: alpha 0 or 255.
"""
from __future__ import annotations
import shutil
import sys
from pathlib import Path
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_rules as rules  # noqa: E402
from build_level_up_art import recolour_box  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "art-archive/T-146/gift_box_from_T-140_raw.png"
LOGO = ROOT / "game/art/logo/greenbull_emblem_32.png"
OUT = ROOT / "game/art/gift_pack"
OLD_ARCHIVE = ROOT / "art-archive/T-304" / rules.OLD_BRAND_DIR  # the old files' folder (T-312)
NAMES = ("package.png", "package_falling.png")
CANVAS = 64
FALL_H = 96
BOX_W = 40
LOGO_W = 16
MAX_COLOURS = 30

OUTLINE = (14, 22, 18, 255)          # the emblem's own near-black green
DG = rules.GREENBULL_DARK_GREEN + (255,)
DG_D = (6, 46, 26, 255)
DG_L = (24, 110, 58, 255)
CREAM = (240, 246, 226, 255)
CREAM_D = (206, 220, 190, 255)
CORD = (214, 222, 200, 255)


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
    raw = recolour_box(Image.open(RAW).convert("RGBA"))
    raw = raw.crop(raw.getbbox())
    h = round(raw.height * BOX_W / raw.width)
    small = hard_alpha(raw.resize((BOX_W, h), Image.BOX))
    return quantize(small, 22)


def small_emblem(width: int = LOGO_W) -> Image.Image:
    """The 32 px emblem scaled down, every pixel snapped to the emblem's own colours."""
    logo = Image.open(LOGO).convert("RGBA")
    logo = logo.crop(logo.getbbox())
    palette = sorted({p[:3] for p in logo.getdata() if p[3] == 255})
    lh = max(1, round(logo.height * width / logo.width))
    small = hard_alpha(logo.resize((width, lh), Image.BOX), cut=110)
    px = small.load()
    for y in range(lh):
        for x in range(width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = min(palette, key=lambda c: rules.rgb_distance(c, (r, g, b))) + (255,)
    return small


def stamp_logo(box: Image.Image) -> Image.Image:
    """A pale tag with Greenbull's emblem on the box's right face, where the gull was."""
    out = box.copy()
    logo = small_emblem()
    lw, lh = logo.size
    tw, th = lw + 2, lh + 2
    tx, ty = box.width - tw - 4, box.height - th - 8
    px = out.load()
    for y in range(th):
        for x in range(tw):
            edge = x in (0, tw - 1) or y in (0, th - 1)
            px[tx + x, ty + y] = OUTLINE if edge else (CREAM_D if x == tw - 2 or y == th - 2 else CREAM)
    out.alpha_composite(logo, (tx + 1, ty + 1))
    return out


def on_canvas(sprite: Image.Image) -> Image.Image:
    c = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    c.paste(sprite, ((CANVAS - sprite.width) // 2, CANVAS - sprite.height))
    return c


def parachute(box_canvas: Image.Image) -> Image.Image:
    """The box hung under a dark green and cream canopy, drawn pixel by pixel."""
    W = CANVAS
    c = Image.new("RGBA", (W, FALL_H), (0, 0, 0, 0))
    c.alpha_composite(box_canvas, (0, FALL_H - CANVAS))
    px = c.load()
    cx, top, rx, ry = 32, 2, 28, 18
    # half-ellipse canopy, 6 vertical gores alternating dark green and cream, lit on the left
    for y in range(top, top + ry + 1):
        dy = (top + ry - y) / ry
        half = round(rx * (1 - dy * dy) ** 0.5)
        for x in range(cx - half, cx + half + 1):
            gore = (x - (cx - rx)) * 6 // (2 * rx + 1)
            lit = x < cx - half // 3
            if gore % 2 == 0:
                col = DG_L if lit else DG
            else:
                col = CREAM if lit else CREAM_D
            if y == top + ry:  # the lower edge
                col = DG_D
            px[x, y] = col
    # outline of the canopy
    mask = [(x, y) for y in range(FALL_H) for x in range(W) if px[x, y][3] and y < top + ry + 1]
    edge = [(x, y) for x, y in mask if any(
        not (0 <= x + dx < W and 0 <= y + dy < FALL_H) or px[x + dx, y + dy][3] == 0
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for x, y in edge:
        px[x, y] = OUTLINE
    # cords from the canopy's rim to the box's top
    box_top = FALL_H - CANVAS + box_canvas.getbbox()[1]
    for sx, ex in ((cx - rx + 1, 24), (cx - 14, 28), (cx + 14, 36), (cx + rx - 1, 40)):
        y0 = top + ry + 1
        n = box_top - y0
        for i in range(n):
            x = round(sx + (ex - sx) * i / max(1, n))
            if px[x, y0 + i][3] == 0:
                px[x, y0 + i] = CORD
    return c


def package() -> Image.Image:
    return on_canvas(stamp_logo(box_sprite()))


def package_falling() -> Image.Image:
    return parachute(package())


PIECES = {"package": package, "package_falling": package_falling}


def build() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    pkg = package()
    pkg.save(OUT / "package.png")
    parachute(pkg).save(OUT / "package_falling.png")


def archive() -> list[Path]:
    """Copies the current game files to OLD_ARCHIVE (art-archive/T-304/), never overwriting."""
    OLD_ARCHIVE.mkdir(parents=True, exist_ok=True)
    done = []
    for name in NAMES:
        dst = OLD_ARCHIVE / name
        if not dst.exists():
            shutil.copy2(OUT / name, dst)
            done.append(dst)
    return done


def red_pixels(im: Image.Image) -> list:
    return sorted({p[:3] for p in im.getdata() if p[3] and rules.reads_as_red(p[:3])})


def check() -> list[str]:
    errs = []
    for name in NAMES:
        im = Image.open(OUT / name).convert("RGBA")
        alphas = {p[3] for p in im.getdata()}
        if not alphas <= {0, 255}:
            errs.append(f"{name}: semi-transparent pixels {sorted(alphas)}")
        if im.getpixel((0, 0))[3] != 0:
            errs.append(f"{name}: background not transparent")
        n = len({p for p in im.getdata() if p[3]})
        if n > MAX_COLOURS:
            errs.append(f"{name}: {n} colours")
        reds = red_pixels(im)
        if reds:
            errs.append(f"{name}: red pixels {reds}")
        print(f"{name}: {im.size}, {n} colours, alpha {sorted(alphas)}, red pixels: {len(reds)}")
    return errs


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "check"
    if cmd == "piece":
        PIECES[sys.argv[2]]().save(sys.argv[3])
        print(f"wrote {sys.argv[3]}")
        sys.exit(0)
    if cmd == "archive":
        for p in archive():
            print(f"archived {p}")
        sys.exit(0)
    if cmd == "build":
        build()
    errs = check()
    for e in errs:
        print("FAIL", e)
    sys.exit(1 if errs else 0)
