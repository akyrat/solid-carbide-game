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
import sys
from collections import deque
from pathlib import Path

from PIL import Image

TOOLS = Path(__file__).resolve().parent
GAME = TOOLS.parent
REPO = GAME.parent
sys.path.insert(0, str(TOOLS))
from style_rules import RED_MIN_DISTANCE, red_distance  # noqa: E402,F401  (Visual style rule 6)

MAX_COLORS = 30
UNIT_W = 32   # art px for one unit along a ground axis, horizontally (iso: 1 unit = 32 x 16)
UNIT_H = 16
UNIT_UP = 32  # art px for one unit up

GROUND_ATLAS = GAME / "art" / "ground" / "ground_atlas.png"
PARTICLES = GAME / "art" / "effects" / "level_up_particles.png"
CAR_SHEET = GAME / "art" / "car" / "car_iso.png"


# ------------------------------------------------------------- palette ----

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


# Base towers 2..8 (task T-064 full set): the sample's prompt with the roof, the sign placement,
# the window pattern and the height varied. The sample (tower 1) keeps PROMPT.
PROMPT_HEAD = "a single narrow Tokyo-style cyberpunk skyscraper tower at night, isometric, square footprint, "
PROMPT_TAIL = "pink and cyan neon glow drawn in pixels, retro pixel art"
TOWER_VARIANTS = {
    2: "flat roof with a water tank and a small antenna, dark navy concrete walls, narrow vertical columns of small lit windows, one very tall vertical neon sign board along the left edge with abstract glowing stripes and shapes, no letters, ",
    3: "stepped setback roof with a tall radio mast, dark purple concrete walls, wide horizontal bands of lit windows, vertical neon sign boards stacked on the right corner with abstract glowing shapes, no letters, ",
    4: "slanted roof with rooftop air conditioning units, dark navy and grey walls, a checkerboard pattern of lit and dark windows, a big vertical neon sign board hanging from the front corner with abstract glowing marks, no letters, ",
    5: "roof garden with a small glowing billboard on top, dark purple walls, tall arched windows in rows, two thin vertical neon signs on the left wall with abstract glowing stripes, no letters, ",
    6: "flat roof with a helipad circle and antennas, dark navy walls with horizontal ribs, dense rows of tiny lit windows, a vertical neon sign board on the right wall with abstract glowing shapes, no letters, ",
    7: "pointed spire roof with a blinking light, dark violet concrete walls, tall windows in pairs, vertical neon sign boards on both corners with abstract glowing stripes, no letters, ",
    8: "boxy roof with ventilation pipes and a satellite dish, dark navy walls with balconies, irregular scattered lit windows, a glowing vertical neon sign board on the left corner with abstract shapes, no letters, ",
}


def tower_prompt(n):
    return PROMPT if n == 1 else PROMPT_HEAD + TOWER_VARIANTS[n] + PROMPT_TAIL


def request_body(palette_png, seed=64064, prompt=None):
    return {
        "description": prompt or PROMPT,
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


def keep_main(img, min_fraction=0.01):
    """Keeps the largest 8-connected opaque island and every island of at least
    `min_fraction` of its size; drops the rest (PixelLab sometimes draws tiny
    stray letters or marks beside a tower)."""
    w, h = img.size
    px = img.load()
    seen = bytearray(w * h)
    comps = []
    for y0 in range(h):
        for x0 in range(w):
            if seen[y0 * w + x0] or px[x0, y0][3] == 0:
                continue
            comp, q = [], deque([(x0, y0)])
            seen[y0 * w + x0] = 1
            while q:
                x, y = q.popleft()
                comp.append((x, y))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and px[nx, ny][3]:
                            seen[ny * w + nx] = 1
                            q.append((nx, ny))
            comps.append(comp)
    if not comps:
        return img
    biggest = max(len(c) for c in comps)
    for c in comps:
        if len(c) < biggest * min_fraction:
            for p in c:
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
    img = keep_main(img)
    return crop_to_content(img)


def sprite_report(img):
    """Visual style's rules, as style_rules checks them, for any size; plus the red rule."""
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


HEIGHTS = (9, 12, 15)


def variant_plan(n=4, block_seed=0, heights=HEIGHTS):
    """n x n places of a block: (mirror, swap, height), from a fixed hash so neighbours vary."""
    plan = []
    for gy in range(n):
        row = []
        for gx in range(n):
            hsh = ((gx * 73856093) ^ (gy * 19349663) ^ (block_seed * 83492791)) & 0xFFFF
            row.append({
                "mirror": (gx + gy) % 2 == 1,
                "swap": (gx + 2 * gy + block_seed) % 3 == 0,
                "height": heights[(hsh + gx + 2 * gy) % len(heights)],
            })
        plan.append(row)
    return plan


def tower_version(tower, v, band, base_height_units, swap):
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
    return img


def build_mockup(tower, band, base_height_units, footprint_units, n=4, cell=6, pitch=8,
                 block=30, alley_color=(24, 23, 36), block_seed=0):
    """One block x block unit block: an n x n grid of cells (cell units, `pitch` apart, so
    pitch - cell units of alley), one tower per cell with its footprint centred, back to front.
    Returns (image, origin): origin is the block's north corner in the image."""
    from PIL import ImageDraw
    pal = sorted(opaque_colors(tower), key=sum)
    swap = neon_swap_map(pal)
    plan = variant_plan(n, block_seed)
    top = int(max(HEIGHTS) * UNIT_UP + footprint_units * UNIT_H * 2 + 96)
    W, H = block * UNIT_W * 2 + 64, block * UNIT_H * 2 + top + 64
    ox, oy = W // 2, top
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(out)
    pts = [iso(0, 0), iso(block, 0), iso(block, block), iso(0, block)]
    d.polygon([(ox + x, oy + y) for x, y in pts], fill=alley_color + (255,))
    start = (block - ((n - 1) * pitch + cell)) / 2.0
    off = (cell - footprint_units) / 2.0
    order = sorted(((gx, gy) for gx in range(n) for gy in range(n)), key=lambda t: (t[0] + t[1], t[0]))
    for gx, gy in order:
        img = tower_version(tower, plan[gy][gx], band, base_height_units, swap)
        ux = start + gx * pitch + off + footprint_units  # the footprint's south corner
        uy = start + gy * pitch + off + footprint_units
        sx, sy = iso(ux, uy)
        by, bx = base_line(img)
        out.alpha_composite(img, (int(round(ox + sx - bx)), int(round(oy + sy - by))))
    return out, (ox, oy)


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


def measure(tower):
    """The clean tower's geometry: footprint (units, from its width), wall height (units,
    from the left corner's vertical edge), and a band of whole floors to repeat (period by
    autocorrelation of the rows in the middle of the walls)."""
    w, h = tower.size
    px = tower.load()
    left = []
    for y in range(h):
        xs = [x for x in range(w) if px[x, y][3]]
        left.append(xs[0] if xs else None)
    xmin = min(x for x in left if x is not None)
    rows = [y for y, x in enumerate(left) if x is not None and x <= xmin + 1]
    wall_top, wall_bottom = rows[0], rows[-1]
    footprint = round((w - 2) / (2 * UNIT_W) * 2) / 2  # to the nearest half unit
    wall_units = (wall_bottom - wall_top) / UNIT_UP
    mid = (wall_top + wall_bottom) // 2
    lo, hi = mid - 50, mid + 30

    def diff(P):
        tot = 0
        for y in range(lo, hi):
            for x in range(w):
                a, b = px[x, y], px[x, y + P]
                tot += abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2]) + abs(a[3] - b[3])
        return tot

    period = min(range(12, 48), key=diff)
    return {"footprint_units": footprint, "wall_top": wall_top, "wall_bottom": wall_bottom,
            "wall_units": round(wall_units, 2), "band": [mid, mid + period], "floor_period_px": period}


def variants_sheet(tower, band, base_units, swap, gap=8):
    """All 12 script versions of one tower (mirror x swap x 3 heights) in one row."""
    vs = [{"mirror": m, "swap": sw, "height": ht} for ht in HEIGHTS for sw in (False, True) for m in (False, True)]
    imgs = [tower_version(tower, v, band, base_units, swap) for v in vs]
    H = max(i.size[1] for i in imgs)
    out = Image.new("RGBA", (sum(i.size[0] for i in imgs) + gap * (len(imgs) - 1), H), (0, 0, 0, 0))
    x = 0
    for im in imgs:
        out.alpha_composite(im, (x, H - im.size[1]))
        x += im.size[0] + gap
    return out, vs


def with_car(block_img, origin, car_index=6, at=(12.0, 33.5), bg=(14, 12, 24)):
    """The block mock-up with the car (frame `car_index` of the game's sheet, same art
    density) on the street at ground units `at` relative to the block's north corner."""
    out = Image.new("RGBA", block_img.size, bg + (255,))
    out.alpha_composite(block_img)
    car = car_frame(car_index)
    sx, sy = iso(*at)
    out.alpha_composite(car, (int(origin[0] + sx - 64), int(origin[1] + sy - 64)))
    return out


def build_all(raw, palette_png, out_dir):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    pal = palette_from_image(palette_png)
    tower = clean(raw, pal)
    tower.save(out_dir / "tower_01_clean.png")
    geo = measure(tower)
    band, fp, base = geo["band"], geo["footprint_units"], geo["wall_units"]
    swap = neon_swap_map(pal)
    side_by_side(tower, 2).save(out_dir / "tower_01_preview_2x.png")
    side_by_side(tower, 4).save(out_dir / "tower_01_preview_4x.png")
    sheet, vs = variants_sheet(tower, band, base, swap)
    sheet.save(out_dir / "tower_01_variants.png")
    side_by_side(sheet, 2).save(out_dir / "tower_01_variants_preview_2x.png")
    outputs = {}
    layouts = {
        "plan": dict(n=4, cell=6, pitch=8),       # the plan: 16 towers, 6 x 6 cells, 2-unit alleys
        "dense": dict(n=7, cell=3, pitch=4.5),    # free alternative fitted to the tower's real 2 x 2 footprint
    }
    for name, lay in layouts.items():
        blk, origin = build_mockup(tower, band, base, fp, **lay)
        cropped = crop_to_content(blk, pad=4)
        cropped.save(out_dir / f"block_mockup_{name}.png")
        with_car(blk, origin).save(out_dir / f"block_mockup_{name}_with_car.png")
        outputs[name] = lay
    report = sprite_report(tower)
    variant_reports = [sprite_report(tower_version(tower, v, band, base, swap)) for v in vs]
    record = {
        "task": "T-064",
        "generator": "game/tools/build_buildings.py build (free, no PixelLab call)",
        "source": str(Path(raw).as_posix()),
        "palette": str(Path(palette_png).as_posix()),
        "geometry": geo,
        "clean_tower_check": report,
        "variants": [dict(v, check=r) for v, r in zip(vs, variant_reports)],
        "neon_swap_map": {"%d,%d,%d" % k: list(v) for k, v in swap.items()},
        "mockups": outputs,
    }
    (out_dir / "build_record.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    return record


# ---------------------------------------------------------------- main ----

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("palette"); p.add_argument("--out", required=True)
    p = sub.add_parser("request"); p.add_argument("--palette", required=True); p.add_argument("--out", required=True)
    p = sub.add_parser("requests"); p.add_argument("--palette", required=True); p.add_argument("--out-dir", required=True)
    p = sub.add_parser("clean"); p.add_argument("raw"); p.add_argument("--palette", required=True)
    p.add_argument("--out", required=True); p.add_argument("--tolerance", type=int, default=24)
    p = sub.add_parser("check"); p.add_argument("png")
    p = sub.add_parser("build"); p.add_argument("raw"); p.add_argument("--palette", required=True)
    p.add_argument("--out-dir", required=True)
    a = ap.parse_args(argv)
    if a.cmd == "palette":
        pal = build_palette()
        palette_image(pal).save(a.out)
        print(len(pal), "colours:", pal)
    elif a.cmd == "request":
        body = request_body(a.palette)
        Path(a.out).write_text(json.dumps(body, indent=2) + "\n", encoding="utf-8")
        print("wrote", a.out)
    elif a.cmd == "requests":
        for n in range(2, 9):
            body = request_body(a.palette, seed=64064 + n, prompt=tower_prompt(n))
            f = Path(a.out_dir) / f"tower_{n:02d}_request.json"
            f.write_text(json.dumps(body, indent=2) + "\n", encoding="utf-8")
            print("wrote", f)
    elif a.cmd == "clean":
        img = clean(a.raw, palette_from_image(a.palette), a.tolerance)
        img.save(a.out)
        print(json.dumps(sprite_report(img)))
    elif a.cmd == "build":
        rec = build_all(a.raw, a.palette, a.out_dir)
        print(json.dumps({"geometry": rec["geometry"], "check": rec["clean_tower_check"]}))
        return 0 if rec["clean_tower_check"]["pass"] and all(v["check"]["pass"] for v in rec["variants"]) else 1
    elif a.cmd == "check":
        rep = sprite_report(Image.open(a.png))
        print(json.dumps(rep))
        return 0 if rep["pass"] else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
