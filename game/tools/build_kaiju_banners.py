#!/usr/bin/env python3
"""Draws the kaiju alert banners (task T-130; no PixelLab call).

The board approved drawing them by script (Visual style, Decisions, "City brief"):
picture-only alert banners, a silly minimal pixel painting of the kaiju's head or its
Godzilla-like body (round back, back spikes, tail; never a copy of the film monster),
cyan or violet-leaning pink on a dark panel with a plain warning border (diagonal
hazard stripes), no letters, no Redgull red. 32 art pixels per unit (drawn at game
scale 0.5, like the car and the ground), no anti-aliasing, no semi-transparent pixels,
a transparent background, 30 colours or fewer, glow drawn into the pixels as stepped
halo rings.

Four designs, two colourways each:
  head / building banner   96 x 128 front-on, and 96 x 175 sheared onto a wall
  body / building banner   same
  head / pavement sign     48 x 96 (board 48 x 64 on a post), upright
  body / pavement sign     same
The sheared sprite slopes down to the right, 1 art px per 2 across (the 2:1 wall
slope); the other wall is the same sprite flipped in the game.

Commands (run from the repo root):
  python game/tools/build_kaiju_banners.py build     # PNGs + record in game/art/banners/, previews in art-archive/T-130/
  python game/tools/build_kaiju_banners.py check     # checks the committed PNGs (exit 1 on a fail)
  python game/tools/build_kaiju_banners.py preview   # only the previews

Running build twice gives byte-identical files.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_drift_mark as marks  # noqa: E402  (shared Redgull-red check)
import check_sprite_rules as rules  # noqa: E402
from remove_car_shadow import write_png  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
REPO = GAME.parent
OUT_DIR = GAME / "art" / "banners"
OUT_JSON = OUT_DIR / "banners.json"
ARCHIVE = REPO / "art-archive" / "T-130"
CAR_SHEET = GAME / "art" / "car" / "car_iso.png"

MAX_COLORS = 30
HEART_COLOR = (0.86, 0.1, 0.16)  # Hud.HEART_COLOR; nothing may be within 0.5 of it

BUILDING_SIZE = (96, 128)  # 3 x 4 units, front-on
SIGN_SIZE = (48, 96)       # 1.5 x 3 units: a 48 x 64 board on a post
SIGN_BOARD_H = 64

# Shared colours (night navy panel, dark outline, post).
SHARED = {
    "N1": (12, 14, 34),   # panel
    "N2": (22, 24, 56),   # panel, lighter (dither and the hazard stripes' dark)
    "O": (5, 7, 20),      # outline
    "P": (64, 70, 100),   # post
    "Q": (100, 108, 146),  # post, lit side
}
# The two colourways (A_L light, A_M mid, A_D dark, HI hot core, G halo).
COLOURWAYS = {
    "cyan": {"AL": (110, 240, 250), "AM": (40, 190, 220), "AD": (24, 110, 160), "HI": (214, 252, 255), "G": (18, 64, 100)},
    "pink": {"AL": (248, 140, 236), "AM": (210, 84, 214), "AD": (128, 50, 172), "HI": (255, 226, 250), "G": (62, 26, 92)},
}

# Pictures: polygons in the picture's box, x and y from 0 to 1, facing right.
HEAD_BODY = [
    (0.10, 1.00), (0.12, 0.84), (0.16, 0.74), (0.25, 0.50), (0.38, 0.30),
    (0.45, 0.16), (0.62, 0.14), (0.78, 0.22), (0.92, 0.36), (1.00, 0.46),
    (1.00, 0.58), (0.96, 0.66), (0.90, 0.76), (0.80, 0.84), (0.66, 0.88),
    (0.52, 0.92), (0.44, 1.00),
]
# Back spikes of the head: triangles (base a, base b, tip).
HEAD_SPIKES = [
    [(0.07, 0.96), (0.15, 0.66), (0.00, 0.72)],
    [(0.13, 0.66), (0.24, 0.40), (0.06, 0.40)],
    [(0.22, 0.42), (0.37, 0.20), (0.20, 0.14)],
    [(0.36, 0.26), (0.50, 0.08), (0.40, 0.00)],
]
HEAD_EYE = (0.64, 0.33)
HEAD_NOSTRIL = (0.93, 0.47)
HEAD_MOUTH = [(0.98, 0.64), (0.78, 0.68), (0.56, 0.70)]
HEAD_TEETH_Y = (0.64, 0.74)  # teeth hang below the mouth line between x 0.60 and 0.96

BODY_POLY = [
    (0.00, 0.62), (0.08, 0.68), (0.20, 0.64),  # tail tip, tail top
    (0.34, 0.42), (0.50, 0.30), (0.66, 0.28),  # round back
    (0.72, 0.18), (0.84, 0.10), (0.96, 0.14), (1.00, 0.24), (0.98, 0.34), (0.88, 0.38),  # head
    (0.80, 0.46), (0.82, 0.62), (0.78, 0.80), (0.84, 0.94), (0.84, 1.00),  # chest, front leg
    (0.60, 1.00), (0.60, 0.84), (0.50, 0.80),  # front foot, belly
    (0.42, 0.86), (0.46, 1.00), (0.20, 1.00), (0.24, 0.84),  # back leg, foot
    (0.14, 0.78), (0.00, 0.76),  # under the tail
]
BODY_ARM = [(0.78, 0.50), (0.90, 0.54), (0.88, 0.60), (0.78, 0.58)]
BODY_SPIKES = [
    [(0.26, 0.54), (0.34, 0.42), (0.20, 0.36)],
    [(0.34, 0.44), (0.44, 0.34), (0.32, 0.24)],
    [(0.44, 0.34), (0.56, 0.28), (0.48, 0.14)],
    [(0.54, 0.29), (0.66, 0.28), (0.62, 0.12)],
    [(0.64, 0.26), (0.72, 0.20), (0.70, 0.06)],
]
BODY_EYE = (0.88, 0.22)
BODY_MOUTH = [(0.99, 0.30), (0.90, 0.31)]
BODY_NOSTRIL = (0.96, 0.20)

T = (0, 0, 0, 0)


# ---------------------------------------------------------------- rasterising

def _inside(poly, px, py):
    """Even-odd point in polygon."""
    c = False
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        if (y1 > py) != (y2 > py) and px < (x2 - x1) * (py - y1) / (y2 - y1) + x1:
            c = not c
    return c


def poly_mask(polys, w, h):
    """Set of (x, y) pixels whose centre is in any of the polygons (given in 0..1 box coordinates)."""
    out = set()
    for poly in polys:
        pts = [(x * w, y * h) for x, y in poly]
        for y in range(h):
            for x in range(w):
                if _inside(pts, x + 0.5, y + 0.5):
                    out.add((x, y))
    return out


def line_pixels(p0, p1):
    """Bresenham."""
    (x0, y0), (x1, y1) = p0, p1
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    out = []
    while True:
        out.append((x0, y0))
        if (x0, y0) == (x1, y1):
            return out
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def blob(cx, cy, r):
    return {(x, y) for x in range(int(cx - r) - 1, int(cx + r) + 2) for y in range(int(cy - r) - 1, int(cy + r) + 2)
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r}


def neighbours8(p):
    x, y = p
    return [(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]


def ring_distance(mask, limit, w, h):
    """Distance (chessboard, 1..limit) of every outside pixel within the box to the mask."""
    dist = {}
    frontier = set(mask)
    for d in range(1, limit + 1):
        nxt = set()
        for p in frontier:
            for q in neighbours8(p):
                if q not in mask and q not in dist and 0 <= q[0] < w and 0 <= q[1] < h:
                    dist[q] = d
                    nxt.add(q)
        frontier = nxt
    return dist


# ------------------------------------------------------------------- pictures

def paint_picture(design, w, h):
    """A w x h dict {(x, y): letter} of the kaiju picture: letters AL AM AD HI O G (G halo, O outline)."""
    if design == "head":
        body = poly_mask([HEAD_BODY], w, h)
        spikes = poly_mask(HEAD_SPIKES, w, h)
        eye = blob(HEAD_EYE[0] * w, HEAD_EYE[1] * h, max(1.5, 0.07 * min(w, h)))
        nostril = blob(HEAD_NOSTRIL[0] * w, HEAD_NOSTRIL[1] * h, max(0.9, 0.025 * w))
        mouth = set()
        for a, b in zip(HEAD_MOUTH, HEAD_MOUTH[1:]):
            mouth |= set(line_pixels((int(a[0] * w), int(a[1] * h)), (int(b[0] * w), int(b[1] * h))))
        teeth = set()
        step = max(3, round(0.09 * w))
        for tx in range(int(0.62 * w), int(0.96 * w), step):
            my = [p[1] for p in mouth if p[0] == tx]
            if my:
                teeth |= {(tx, my[0] + 1), (tx + (1 if step > 3 else 0), my[0] + 1)} | ({(tx, my[0] + 2)} if h >= 40 else set())
        dark_inside = mouth | nostril
    else:
        body = poly_mask([BODY_POLY, BODY_ARM], w, h)
        spikes = poly_mask(BODY_SPIKES, w, h)
        eye = blob(BODY_EYE[0] * w, BODY_EYE[1] * h, max(1.5, 0.055 * min(w, h)))
        nostril = blob(BODY_NOSTRIL[0] * w, BODY_NOSTRIL[1] * h, max(0.9, 0.02 * w))
        mouth = set()
        for a, b in zip(BODY_MOUTH, BODY_MOUTH[1:]):
            mouth |= set(line_pixels((int(a[0] * w), int(a[1] * h)), (int(b[0] * w), int(b[1] * h))))
        teeth = set()
        dark_inside = mouth | nostril
    silhouette = body | spikes
    band = max(1, round(h * 0.035))
    out = {}
    for p in silhouette:
        x, y = p
        if (x, y - band) not in silhouette or (x - 1, y - band) not in silhouette and (x + 1, y - band) not in silhouette:
            letter = "AL"
        elif (x, y + band + 1) not in silhouette:
            letter = "AD"
        else:
            letter = "AM"
        if p in spikes and p not in body:
            letter = "AL" if (x, y - 1) in silhouette else "HI"
        out[p] = letter
    for p in teeth:
        if p in silhouette:
            out[p] = "HI"
    for p in dark_inside:
        if p in silhouette:
            out[p] = "O"
    for p in eye:
        if p in silhouette:
            out[p] = "HI"
    if eye:
        ex = sum(p[0] for p in eye) / len(eye)
        ey = sum(p[1] for p in eye) / len(eye)
        pup = [p for p in eye if p[0] >= ex and p[1] >= ey]
        small = len(eye) <= 6
        for p in (pup[:1] if small else pup[: max(1, len(pup) // 2)]):
            out[p] = "O"
    # outline and stepped halo around the silhouette
    dist = ring_distance(silhouette, 3, w, h)
    for p, d in dist.items():
        if d == 1:
            out[p] = "O"
        elif d == 2:
            out[p] = "G"
        elif d == 3 and (p[0] + p[1]) % 2 == 0:
            out[p] = "G"
    return out


def zigzag(w, h):
    """A seismic / alert pulse line across a w x h box: {(x, y): letter}."""
    n = 6
    pts = []
    for i in range(n * 2 + 1):
        x = round(i * (w - 1) / (n * 2))
        y = h // 2 if i % 2 == 0 else (1 if i % 4 == 1 else h - 2)
        if i in (0, n * 2):
            y = h // 2
        pts.append((x, y))
    out = {}
    for a, b in zip(pts, pts[1:]):
        for (x, y) in line_pixels(a, b):
            out[(x, y)] = "AM"
            out[(x, y + 1)] = "AD" if (x, y + 1) not in out else out[(x, y + 1)]
    for a, b in zip(pts, pts[1:]):
        for p in line_pixels(a, b):
            out[p] = "HI"
    return {p: v for p, v in out.items() if 0 <= p[0] < w and 0 <= p[1] < h}


# ---------------------------------------------------------------------- panel

def panel(w, h, stripe, pic, strip=None):
    """The banner board: a dict {(x, y): letter} for a w x h board.

    stripe: hazard border thickness; pic: (dict, x, y) picture to place; strip: (dict, x, y).
    """
    out = {}
    cut = {(0, 0), (1, 0), (0, 1), (w - 1, 0), (w - 2, 0), (w - 1, 1), (0, h - 1), (1, h - 1), (0, h - 2),
           (w - 1, h - 1), (w - 2, h - 1), (w - 1, h - 2)}
    for y in range(h):
        for x in range(w):
            if (x, y) in cut:
                continue
            ring = min(x, y, w - 1 - x, h - 1 - y)
            if ring == 0 or ring == stripe + 1:
                letter = "O"
            elif ring <= stripe:
                letter = "AM" if ((x + y) // max(2, stripe)) % 2 == 0 else "N2"
            elif ring == stripe + 2:
                letter = "AD"
            elif ring == stripe + 3 and (x + y) % 2 == 0:
                letter = "N2"
            else:
                letter = "N1"
            out[(x, y)] = letter
    for layer in (pic, strip):
        if layer:
            cells, ox, oy = layer
            for (x, y), v in cells.items():
                if (x + ox, y + oy) in out:
                    out[(x + ox, y + oy)] = v
    return out


def building_front(design):
    w, h = BUILDING_SIZE
    pw, ph = 76, 68
    pic = paint_picture(design, pw, ph)
    strip = zigzag(76, 14)
    return panel(w, h, 5, (pic, (w - pw) // 2, 12), (strip, (w - 76) // 2, 96))


def sign_cells(design):
    w, h = SIGN_SIZE
    bw, bh = w, SIGN_BOARD_H
    pw, ph = 36, 32
    pic = paint_picture(design, pw, ph)
    strip = zigzag(36, 9)
    out = panel(bw, bh, 3, (pic, (bw - pw) // 2, 7), (strip, (bw - 36) // 2, 46))
    cx = w // 2
    for y in range(bh, 90):  # post, 4 wide, lit on its left
        for k, letter in enumerate(("O", "Q", "P", "O")):
            out[(cx - 2 + k, y)] = letter
    for y, half in ((90, 7), (91, 8), (92, 8), (93, 8), (94, 7)):  # base
        for x in range(cx - half, cx + half):
            edge = x in (cx - half, cx + half - 1) or y in (90, 94)
            out[(x, y)] = "O" if edge else ("Q" if x < cx - 2 else "P")
    return out


# ------------------------------------------------------------------- to pixels

def colour_table(colourway):
    table = dict(SHARED)
    table.update(COLOURWAYS[colourway])
    return table


def to_rows(cells, w, h, colourway):
    table = colour_table(colourway)
    rows = [[T] * w for _ in range(h)]
    for (x, y), letter in cells.items():
        if 0 <= x < w and 0 <= y < h:
            rows[y][x] = table[letter] + (255,)
    return rows


def shear(rows, per=2):
    """Slope the sprite onto a wall: column x moves down by x // per (the 2:1 wall slope)."""
    h, w = len(rows), len(rows[0])
    extra = (w - 1) // per
    out = [[T] * w for _ in range(h + extra)]
    for x in range(w):
        dy = x // per
        for y in range(h):
            out[y + dy][x] = rows[y][x]
    return out


def sprites():
    """Every sprite: {file name: (rows, info)} in a stable order."""
    out = {}
    for design in ("head", "body"):
        front_cells = building_front(design)
        sign = sign_cells(design)
        for colour in COLOURWAYS:
            bw, bh = BUILDING_SIZE
            front = to_rows(front_cells, bw, bh, colour)
            base = "kaiju_%s_building_%s" % (design, colour)
            out[base + "_front.png"] = (front, {"kind": "building", "design": design, "colour": colour, "form": "front-on",
                                                "units": [3, 4], "anchor_px": [0, bh - 1], "anchor_note": "bottom-left corner of the panel"})
            wall = shear(front)
            out[base + "_wall.png"] = (wall, {"kind": "building", "design": design, "colour": colour, "form": "sheared onto a wall, sloping down to the right (flip horizontally for the other wall)",
                                               "units": [3, 4], "anchor_px": [0, bh - 1], "anchor_note": "bottom-left corner of the panel (the column the slope starts from)"})
            sw, sh = SIGN_SIZE
            out["kaiju_%s_sign_%s.png" % (design, colour)] = (to_rows(sign, sw, sh, colour), {
                "kind": "pavement", "design": design, "colour": colour, "form": "upright board on a post", "units": [1.5, 3],
                "anchor_px": [sw // 2, sh - 1], "anchor_note": "bottom centre of the base, where the sign touches the pavement"})
    return out


# ---------------------------------------------------------------------- checks

def check_rows(rows, max_colors=MAX_COLORS):
    """Every rule for one sprite: list of (rule, ok, detail)."""
    h, w = len(rows), len(rows[0])
    results, _ = rules.check_rows(rows, w, max_colors)
    out = [r for r in results if not r[0].startswith("frame size")]
    px = [p for r in rows for p in r]
    colors = {p[:3] for p in px if p[3] == 255}
    reds = sorted(c for c in colors if marks.is_redgull_red(c))
    out.append(("no Redgull red (nor any red)", not reds, "reds: %s" % reds if reds else "none"))
    heart = [c for c in colors if sum((a / 255 - b) ** 2 for a, b in zip(c, HEART_COLOR)) ** 0.5 < 0.5]
    out.append(("every colour 0.5 or more from Hud.HEART_COLOR", not heart, "too close: %s" % heart if heart else "none"))
    opaque = sum(1 for p in px if p[3] == 255)
    out.append(("a real banner: at least 25% of the pixels are drawn", opaque >= 0.25 * w * h, "%d of %d" % (opaque, w * h)))
    return out


def expected_size(name):
    if "_sign_" in name:
        return SIGN_SIZE
    if name.endswith("_wall.png"):
        return (BUILDING_SIZE[0], BUILDING_SIZE[1] + (BUILDING_SIZE[0] - 1) // 2)
    return BUILDING_SIZE


def check_file(path):
    _, _, rows = rules.decode_png(Path(path).read_bytes())
    results = check_rows(rows)
    want = expected_size(Path(path).name)
    got = (len(rows[0]), len(rows))
    results.append(("size %dx%d" % want, got == want, "%dx%d" % got))
    return results


def check_dir(directory=OUT_DIR):
    ok_all = True
    lines = []
    names = sorted(sprites())
    for name in names:
        path = Path(directory) / name
        if not path.exists():
            lines.append("FAIL  %s: missing" % name)
            ok_all = False
            continue
        for rule, ok, detail in check_file(path):
            if not ok:
                ok_all = False
                lines.append("FAIL  %s: %s: %s" % (name, rule, detail))
    return ok_all, lines


# --------------------------------------------------------------------- previews

DARK_BG = (14, 14, 28, 255)
LIGHT_BG = (214, 214, 224, 255)
ASPHALT_BG = (42, 44, 58, 255)


def enlarge(rows, k):
    out = []
    for r in rows:
        wide = [p for p in r for _ in range(k)]
        out.extend([wide] * k)
    return out


def compose(items, bg, width, height, gap=8):
    """Place sprites (rows) left to right, bottom aligned, on a bg canvas. items: list of rows."""
    canvas = [[bg] * width for _ in range(height)]
    x0 = gap
    for rows in items:
        h, w = len(rows), len(rows[0])
        y0 = height - gap - h
        for y in range(h):
            for x in range(w):
                if rows[y][x][3] and 0 <= x0 + x < width and 0 <= y0 + y < height:
                    canvas[y0 + y][x0 + x] = rows[y][x]
        x0 += w + gap
    return canvas


def side_by_side(items, k, bgs=(DARK_BG, LIGHT_BG), gap=8):
    width = gap + sum(len(r[0]) + gap for r in items)
    height = max(len(r) for r in items) + 2 * gap
    halves = [enlarge(compose(items, bg, width, height, gap), k) for bg in bgs]
    return [a + [(0, 0, 0, 255)] * 4 + b for a, b in zip(*halves)]


def car_frame():
    """The car's frame 0 (nose down-right), cropped to its pixels."""
    _, _, rows = rules.decode_png(CAR_SHEET.read_bytes())
    frame = [r[:128] for r in rows]
    ys = [y for y, r in enumerate(frame) if any(p[3] for p in r)]
    xs = [x for r in frame for x, p in enumerate(r) if p[3]]
    return [r[min(xs):max(xs) + 1] for r in frame[min(ys):max(ys) + 1]]


def previews(all_sprites=None, archive=ARCHIVE):
    s = all_sprites or sprites()
    archive.mkdir(parents=True, exist_ok=True)
    designs = [s["kaiju_%s_building_%s_front.png" % (d, c)][0] for c in COLOURWAYS for d in ("head", "body")]
    designs += [s["kaiju_%s_sign_%s.png" % (d, c)][0] for c in COLOURWAYS for d in ("head", "body")]
    write_png(archive / "banners_designs_dark_light_x3.png", side_by_side(designs, 3, gap=6))
    walls = [s["kaiju_%s_building_%s_wall.png" % (d, c)][0] for c in COLOURWAYS for d in ("head", "body")]
    write_png(archive / "banners_on_wall_dark_light_x4.png", side_by_side(walls, 4, gap=6))
    car = car_frame()
    scene = [s["kaiju_head_building_cyan_wall.png"][0], car, s["kaiju_head_sign_cyan.png"][0], s["kaiju_body_sign_pink.png"][0],
             s["kaiju_body_building_pink_wall.png"][0]]
    # The car is 96 art px long, the banner 96 px wide: the game draws both at scale 0.5,
    # so relative sizes here are exactly those on screen.
    write_png(archive / "banners_next_to_car_dark_light_x3.png", side_by_side(scene, 3, bgs=(ASPHALT_BG, LIGHT_BG)))
    return archive


# ------------------------------------------------------------------------ build

def record(all_sprites):
    files = []
    for name, (rows, info) in all_sprites.items():
        colors = sorted({p[:3] for r in rows for p in r if p[3]})
        files.append(dict(file=name, size=[len(rows[0]), len(rows)], colours=len(colors), **info))
    return {
        "task": "T-130",
        "what": "Kaiju alert banners: 4 designs (head, body; building banner and pavement sign) in cyan and violet-leaning pink; building banners front-on and sheared onto a wall (2:1). Picture-only: no letters.",
        "made_by": "game/tools/build_kaiju_banners.py (a script; no PixelLab call, board 2026-10-14). Byte-identical every run.",
        "scale_note": "32 art px per unit; drawn in the game at scale 0.5 like the car and the ground, texture_filter nearest",
        "palette": {"shared": {k: list(v) for k, v in SHARED.items()}, **{k: {a: list(b) for a, b in v.items()} for k, v in COLOURWAYS.items()}},
        "rules": "Visual style, Decisions and City brief: no anti-aliasing, no semi-transparent pixels, transparent background, 30 colours or fewer, no Redgull red (every colour 0.5 or more from Hud.HEART_COLOR), no letters (checked by eye in the previews)",
        "check": "python game/tools/build_kaiju_banners.py check",
        "archive": "art-archive/T-130/: previews on dark and light backgrounds, and next to the car",
        "pixellab_calls": 0,
        "status": "candidates for the board's review (T-130); not placed in the game yet (waits for T-064's skyscrapers)",
        "files": files,
    }


def build(out_dir=OUT_DIR, archive=ARCHIVE):
    out_dir.mkdir(parents=True, exist_ok=True)
    all_sprites = sprites()
    for name, (rows, _) in all_sprites.items():
        write_png(out_dir / name, rows)
    (out_dir / "banners.json").write_text(json.dumps(record(all_sprites), indent=1) + "\n", encoding="utf-8", newline="\n")
    if archive is not None:
        previews(all_sprites, archive)
    return out_dir


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("command", choices=["build", "check", "preview"])
    a = ap.parse_args(argv)
    if a.command == "preview":
        print("wrote previews in", previews())
        return 0
    if a.command == "build":
        print("wrote the banners in", build(), "and the previews in", ARCHIVE)
    ok, lines = check_dir()
    for line in lines:
        print(line)
    print("ALL RULES PASS (%d sprites)" % len(sprites()) if ok else "SOME RULES FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
