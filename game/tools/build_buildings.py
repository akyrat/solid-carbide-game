#!/usr/bin/env python3
"""Free (no PixelLab call) steps of the building art, task T-064.

The plan (tasks/T-064-building-art.md, result notes): every 30 x 30 unit city
block holds a 4 x 4 grid of towers on 6 x 6 unit footprints with 2-unit alleys.
Each base tower is one PixelLab /create-image-pixflux image at the game's art
density (32 art px per unit, drawn at scale 0.5 like the car and the ground).
This script does everything around those images for free:

  palette   writes the forced palette image (color_image) from approved art only
            (the ground atlas's night navy and purple, the level-up particles'
            pink, cyan and violet; no Redgull red)
  request   writes the request body JSON for one base tower
  clean     removes PixelLab's blank background (it is not transparent above a
            200 x 200 area), maps every pixel to the palette, crops and checks
  mockup    builds the still mock-up of one whole block from cleaned towers
            (mirroring, pink-led / cyan-led neon swap, three heights, 4 x 4 with
            alleys) and a picture of it next to the car at game scale
  preview   nearest-neighbour enlargements on dark and light backgrounds

Run from the repo root, e.g.:
  python game/tools/build_buildings.py palette --out art-archive/T-064/palette.png
  python game/tools/build_buildings.py clean RAW.png --out CLEAN.png
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import math
import sys
from collections import deque
from pathlib import Path

from PIL import Image

TOOLS = Path(__file__).resolve().parent
GAME = TOOLS.parent
REPO = GAME.parent
sys.path.insert(0, str(TOOLS))

# Redgull red, as the HUD heart draws it (scripts/hud/hud.gd, HEART_COLOR = Color(0.86, 0.1, 0.16)).
REDGULL_RED = (219, 26, 41)
RED_MIN_DISTANCE = 0.5  # 0..1 RGB distance, as T-074

MAX_COLORS = 30
UNIT_W = 32   # art px for one unit along a ground axis, horizontally (iso: 1 unit = 32 x 16)
UNIT_H = 16
UNIT_UP = 32  # art px for one unit up

GROUND_ATLAS = GAME / "art" / "ground" / "ground_atlas.png"
PARTICLES = GAME / "art" / "effects" / "level_up_particles.png"
CAR_SHEET = GAME / "art" / "car" / "car_iso.png"


# ------------------------------------------------------------- palette ----

def red_distance(c):
    return math.sqrt(sum(((a - b) / 255.0) ** 2 for a, b in zip(c[:3], REDGULL_RED)))


def opaque_colors(img):
    img = img.convert("RGBA")
    return {p[:3] for p in img.getdata() if p[3] == 255}


def is_cool(c):
    """The ground atlas's night navy and purple shades (blue >= red, not the white lines)."""
    r, g, b = c
    return b >= r and b >= g and max(c) < 200


def build_palette(atlas=GROUND_ATLAS, particles=PARTICLES):
    """Night base from the ground atlas plus the particles' neon. Sorted by brightness."""
    base = sorted(c for c in opaque_colors(Image.open(atlas)) if is_cool(c))
    neon = sorted(opaque_colors(Image.open(particles)))
    room = MAX_COLORS - len(neon)
    if len(base) > room:  # keep an even spread from darkest to lightest
        base.sort(key=sum)
        step = (len(base) - 1) / (room - 1)
        base = [base[round(i * step)] for i in range(room)]
    pal = sorted(set(base) | set(neon), key=lambda c: (sum(c), c))
    assert len(pal) <= MAX_COLORS
    assert all(red_distance(c) > RED_MIN_DISTANCE for c in pal)
    return pal


def palette_image(pal, cell=4):
    """A strip of swatches, cell x cell px each (the color_image PixelLab reads)."""
    img = Image.new("RGBA", (cell * len(pal), cell), (0, 0, 0, 0))
    for i, c in enumerate(pal):
        for x in range(cell):
            for y in range(cell):
                img.putpixel((i * cell + x, y), c + (255,))
    return img


def palette_from_image(path):
    return sorted(opaque_colors(Image.open(path)), key=lambda c: (sum(c), c))


def b64_png(img):
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return base64.b64encode(buf.getvalue()).decode("ascii")


PROMPT = (
    "a single narrow Tokyo-style cyberpunk skyscraper tower at night, isometric, square footprint, "
    "dark navy and purple concrete walls, rows of small lit windows, tall vertical neon sign boards "
    "on the corners with abstract glowing shapes and stripes, no letters, pink and cyan neon glow "
    "drawn in pixels, rooftop air conditioning units and an antenna, retro pixel art"
)
NEGATIVE = "text, letters, words, kanji, numbers, logo, red, ground, street, road, car, people, sky, background"


def request_body(palette_png, seed=64064):
    return {
        "description": PROMPT,
        "negative_description": NEGATIVE,
        "image_size": {"width": 384, "height": 400},
        "text_guidance_scale": 8,
        "outline": "selective outline",
        "shading": "detailed shading",
        "detail": "highly detailed",
        "view": "high top-down",
        "direction": "south-east",
        "isometric": True,
        "no_background": True,
        "color_image": {"type": "base64", "base64": b64_png(Image.open(palette_png).convert("RGBA"))},
        "seed": seed,
    }


# --------------------------------------------------------------- clean ----

def border_background(img):
    """The colours on the image border that look like a flat background (most common border colours)."""
    w, h = img.size
    px = img.load()
    border = [px[x, y] for x in range(w) for y in (0, h - 1)] + [px[x, y] for y in range(h) for x in (0, w - 1)]
    counts = {}
    for p in border:
        counts[p] = counts.get(p, 0) + 1
    return counts


def remove_background(img, tolerance=24):
    """Flood fill from the border: pixels close to a border background colour become transparent.

    Already transparent pixels count as background too. Returns a new RGBA image.
    """
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    counts = border_background(img)
    total = sum(counts.values())
    bg = [c for c, n in counts.items() if n >= 0.05 * total and c[3] == 255]

    def is_bg(p):
        if p[3] < 128:
            return True
        return any(max(abs(p[i] - c[i]) for i in range(3)) <= tolerance for c in bg)

    out = img.copy()
    op = out.load()
    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.append((x, 0)); q.append((x, h - 1))
    for y in range(h):
        q.append((0, y)); q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        if not (0 <= x < w and 0 <= y < h) or seen[y * w + x]:
            continue
        seen[y * w + x] = 1
        if not is_bg(px[x, y]):
            continue
        op[x, y] = (0, 0, 0, 0)
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return out


def nearest(c, pal):
    return min(pal, key=lambda p: (p[0] - c[0]) ** 2 + (p[1] - c[1]) ** 2 + (p[2] - c[2]) ** 2)


def map_to_palette(img, pal):
    """Every pixel with alpha >= 128 becomes the nearest palette colour, fully opaque; the rest transparent."""
    img = img.convert("RGBA")
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    src, dst = img.load(), out.load()
    cache = {}
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            p = src[x, y]
            if p[3] < 128:
                continue
            c = cache.get(p[:3])
            if c is None:
                c = cache[p[:3]] = nearest(p[:3], pal)
            dst[x, y] = c + (255,)
    return out


def drop_specks(img, min_size=4):
    """Removes isolated opaque islands smaller than min_size pixels (left-over background noise)."""
    w, h = img.size
    px = img.load()
    seen = bytearray(w * h)
    for y0 in range(h):
        for x0 in range(w):
            if seen[y0 * w + x0] or px[x0, y0][3] == 0:
                continue
            comp, q = [], deque([(x0, y0)])
            seen[y0 * w + x0] = 1
            while q:
                x, y = q.popleft()
                comp.append((x, y))
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and px[nx, ny][3]:
                        seen[ny * w + nx] = 1
                        q.append((nx, ny))
            if len(comp) < min_size:
                for p in comp:
                    px[p] = (0, 0, 0, 0)
    return img


def crop_to_content(img, pad=1):
    box = img.getbbox()
    if box is None:
        return img
    x0, y0, x1, y1 = box
    out = Image.new("RGBA", (x1 - x0 + 2 * pad, y1 - y0 + 2 * pad), (0, 0, 0, 0))
    out.paste(img.crop(box), (pad, pad))
    return out


def clean(raw, pal, tolerance=24):
    img = remove_background(Image.open(raw) if not isinstance(raw, Image.Image) else raw, tolerance)
    img = map_to_palette(img, pal)
    img = drop_specks(img)
    return crop_to_content(img)


def sprite_report(img):
    """Visual style's rules, as check_sprite_rules checks them, for any size; plus the red rule."""
    img = img.convert("RGBA")
    px = list(img.getdata())
    w, h = img.size
    corners = [img.getpixel(p) for p in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1))]
    colors = {p[:3] for p in px if p[3] == 255}
    closest_red = min((red_distance(c) for c in colors), default=9)
    return {
        "size": [w, h],
        "transparent_corners": all(c[3] == 0 for c in corners),
        "semi_transparent_pixels": sum(1 for p in px if 0 < p[3] < 255),
        "colors": len(colors),
        "opaque_pixels": sum(1 for p in px if p[3] == 255),
        "closest_to_redgull_red": round(closest_red, 3),
        "pass": all(c[3] == 0 for c in corners) and not any(0 < p[3] < 255 for p in px)
        and len(colors) <= MAX_COLORS and closest_red > RED_MIN_DISTANCE and len(colors) > 0,
    }


# ------------------------------------------------------------ variants ----

def hue_kind(c):
    """'pink', 'cyan' or None for a palette colour."""
    r, g, b = c
    if max(c) - min(c) < 60:
        return None
    if r > g + 40 and b > g:   # magenta / pink / violet side
        return "pink"
    if b > r + 40 and g > r + 40:  # cyan side
        return "cyan"
    return None


def neon_swap_map(pal):
    """Pairs each pink-side palette colour with the cyan-side one of the most similar brightness, and back.

    A colour mapping only (no new pixels, nothing moves towards red)."""
    pinks = sorted([c for c in pal if hue_kind(c) == "pink"], key=sum)
    cyans = sorted([c for c in pal if hue_kind(c) == "cyan"], key=sum)
    m = {}
    for src, dst in ((pinks, cyans), (cyans, pinks)):
        for c in src:
            if dst:
                m[c] = min(dst, key=lambda d: abs(sum(d) - sum(c)))
    return m


def recolor(img, mapping):
    out = img.copy()
    px = out.load()
    for y in range(out.size[1]):
        for x in range(out.size[0]):
            p = px[x, y]
            if p[3] and p[:3] in mapping:
                px[x, y] = mapping[p[:3]] + (255,)
    return out


def mirror(img):
    return img.transpose(Image.FLIP_LEFT_RIGHT)


def stretch(img, band_top, band_bottom, extra):
    """Taller tower: repeats the rows [band_top, band_bottom) until `extra` rows are added.

    The band is a stretch of the walls (whole floors) where moving straight up looks the same."""
    if extra <= 0:
        return img.copy()
    w, h = img.size
    band = img.crop((0, band_top, w, band_bottom))
    bh = band_bottom - band_top
    out = Image.new("RGBA", (w, h + extra), (0, 0, 0, 0))
    out.paste(img.crop((0, 0, w, band_bottom)), (0, 0))
    y = band_bottom
    added = 0
    while added < extra:
        n = min(bh, extra - added)
        out.paste(band.crop((0, 0, w, n)), (0, y))
        y += n
        added += n
    out.paste(img.crop((0, band_bottom, w, h)), (0, y))
    return out


# -------------------------------------------------------------- mockup ----

def iso(ux, uy, up=0.0):
    """Ground units to art px (origin = the block's north corner)."""
    return (ux - uy) * UNIT_W, (ux + uy) * UNIT_H - up * UNIT_UP


def base_line(img):
    """Lowest opaque row and the x of the tower's bottom corner (the middle of the lowest row)."""
    w, h = img.size
    px = img.load()
    for y in range(h - 1, -1, -1):
        xs = [x for x in range(w) if px[x, y][3]]
        if xs:
            return y, (xs[0] + xs[-1]) / 2.0
    return h - 1, w / 2.0


def preview(img, scale, bg):
    big = img.resize((img.size[0] * scale, img.size[1] * scale), Image.NEAREST)
    out = Image.new("RGBA", big.size, bg + (255,))
    out.alpha_composite(big)
    return out


def side_by_side(img, scale, dark=(14, 12, 24), light=(225, 225, 230), gap=8):
    a, b = preview(img, scale, dark), preview(img, scale, light)
    out = Image.new("RGBA", (a.size[0] * 2 + gap, a.size[1]), (128, 128, 128, 255))
    out.paste(a, (0, 0))
    out.paste(b, (a.size[0] + gap, 0))
    return out


def variant_plan(block_seed=0):
    """16 places of a 4 x 4 block: (mirror, swap, height). Neighbours differ (a fixed hash)."""
    heights = (9, 12, 15)
    plan = []
    for gy in range(4):
        row = []
        for gx in range(4):
            hsh = (gx * 73856093) ^ (gy * 19349663) ^ (block_seed * 83492791)
            row.append({
                "mirror": (gx + gy) % 2 == 1,
                "swap": (gx + 2 * gy + block_seed) % 3 == 0,
                "height": heights[(hsh + gx + gy) % 3],
            })
        plan.append(row)
    return plan


def build_mockup(tower, band, base_height_units, alley_color=(24, 23, 36), ground=None, pal=None, block_seed=0):
    """One 30 x 30 block: a 4 x 4 grid of 6 x 6 towers with 2-unit alleys, drawn back to front."""
    pal = pal or sorted(opaque_colors(tower), key=sum)
    swap = neon_swap_map(pal)
    plan = variant_plan(block_seed)
    margin_top = 15 * UNIT_UP + 64
    W, H = 30 * UNIT_W * 2 + 32, 30 * UNIT_H * 2 + margin_top + 32
    ox, oy = W // 2, margin_top
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # the block's ground: the dark night colour (no ground tiles under the blocks, T-103)
    from PIL import ImageDraw
    d = ImageDraw.Draw(out)
    pts = [iso(0, 0), iso(30, 0), iso(30, 30), iso(0, 30)]
    d.polygon([(ox + x, oy + y) for x, y in pts], fill=alley_color + (255,))
    order = sorted(((gx, gy) for gx in range(4) for gy in range(4)), key=lambda t: (t[0] + t[1], t[0]))
    for gx, gy in order:
        v = plan[gy][gx]
        img = tower
        if v["swap"]:
            img = recolor(img, swap)
        if v["mirror"]:
            img = mirror(img)
        extra = int(round((v["height"] - base_height_units) * UNIT_UP))
        if extra > 0:
            img = stretch(img, band[0], band[1], extra)
        elif extra < 0:
            img = shorten(img, band[0], band[1], -extra)
        # place the tower's bottom corner on the footprint's south corner
        ux, uy = gx * 8 + 6, gy * 8 + 6
        sx, sy = iso(ux, uy)
        by, bx = base_line(img)
        out.alpha_composite(img, (int(round(ox + sx - bx)), int(round(oy + sy - by))))
    return crop_to_content(out, pad=4)


def shorten(img, band_top, band_bottom, remove):
    """Lower tower: drops up to `remove` rows from inside the wall band."""
    w, h = img.size
    remove = min(remove, band_bottom - band_top - 1)
    out = Image.new("RGBA", (w, h - remove), (0, 0, 0, 0))
    out.paste(img.crop((0, 0, w, band_top)), (0, 0))
    out.paste(img.crop((0, band_top + remove, w, h)), (0, band_top))
    return out


def car_frame(index=0):
    sheet = Image.open(CAR_SHEET).convert("RGBA")
    return sheet.crop((index * 128, 0, index * 128 + 128, 128))


# ---------------------------------------------------------------- main ----

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("palette"); p.add_argument("--out", required=True)
    p = sub.add_parser("request"); p.add_argument("--palette", required=True); p.add_argument("--out", required=True)
    p = sub.add_parser("clean"); p.add_argument("raw"); p.add_argument("--palette", required=True)
    p.add_argument("--out", required=True); p.add_argument("--tolerance", type=int, default=24)
    p = sub.add_parser("check"); p.add_argument("png")
    a = ap.parse_args(argv)
    if a.cmd == "palette":
        pal = build_palette()
        palette_image(pal).save(a.out)
        print(len(pal), "colours:", pal)
    elif a.cmd == "request":
        body = request_body(a.palette)
        Path(a.out).write_text(json.dumps(body, indent=2) + "\n", encoding="utf-8")
        print("wrote", a.out)
    elif a.cmd == "clean":
        img = clean(a.raw, palette_from_image(a.palette), a.tolerance)
        img.save(a.out)
        print(json.dumps(sprite_report(img)))
    elif a.cmd == "check":
        rep = sprite_report(Image.open(a.png))
        print(json.dumps(rep))
        return 0 if rep["pass"] else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
