#!/usr/bin/env python3
"""Draws the kaiju alert signs (task T-130; no PixelLab call).

Quick tuning from the board (2026-10-14): road-sign style, not neon. Each sign is a
real-looking warning triangle or prohibition circle: a thick traffic-sign red outline, a
plain white inside and only the kaiju's solid black silhouette (no eye, teeth, shading,
glow, stripes or lettering). Picture-only, no letters. 32 art pixels per unit (drawn at
game scale 0.5, like the car and the ground), no anti-aliasing, no semi-transparent pixels,
a transparent background.

Two designs, in the two classic sign shapes:
  head  -> warning triangle (apex up): "danger ahead", and the compact head fits it
  body  -> prohibition circle: the long body with its tail needs the wider round sign
Each as a building banner (front-on, and sheared onto a wall at 2:1, 1 art px per 2 across,
sloping down to the right; flip it in the game for the other wall) and as a pavement sign
on a post. The sign red is the only red outside Redgull's look allowed in the art
(Visual style, Decisions): it is used on these signs and nowhere else. Colours: that red,
white, black, and the post's two greys: 5 in all.

Commands (run from the repo root):
  python game/tools/build_kaiju_banners.py build     # PNGs + record in game/art/banners/, previews in art-archive/T-130/
  python game/tools/build_kaiju_banners.py check     # checks the committed PNGs (exit 1 on a fail)
  python game/tools/build_kaiju_banners.py preview   # only the previews

Running build twice gives byte-identical files. The first (neon) version is archived in
art-archive/T-130/first-version/.
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
ARCHIVE = REPO / "art-archive" / "T-130"
CAR_SHEET = GAME / "art" / "car" / "car_iso.png"

MAX_COLORS = 30

SIGN_RED = (204, 18, 28)  # traffic-sign red: the one red allowed, on these signs only
WHITE = (250, 250, 250)
BLACK = (10, 10, 14)
POST = (64, 70, 100)
POST_LIT = (100, 108, 146)
COLOURS = {"R": SIGN_RED, "W": WHITE, "K": BLACK, "P": POST, "Q": POST_LIT}
ALLOWED = set(COLOURS.values())

SHAPES = {"head": "triangle", "body": "circle"}
BUILDING_SIZE = {"triangle": (96, 84), "circle": (96, 96)}  # 3 units wide
SIGN_SIZE = (48, 96)  # a 48 wide board on a post
SIGN_BOARD_H = {"triangle": 42, "circle": 48}
RED_BAND = {"building": {"triangle": 7, "circle": 9}, "pavement": {"triangle": 4, "circle": 5}}

# The kaiju's shapes: polygons in a box, x and y from 0 to 1, facing right. Solid black, no details.
HEAD_BODY = [  # a neck rising from the bottom, the head in profile with an open mouth
    (0.18, 1.00), (0.22, 0.70), (0.28, 0.45), (0.30, 0.28), (0.42, 0.18), (0.60, 0.16),
    (0.80, 0.26), (1.00, 0.36), (1.00, 0.46), (0.64, 0.52), (0.92, 0.58), (0.90, 0.66),
    (0.66, 0.70), (0.52, 0.74), (0.50, 1.00),
]
HEAD_SPIKES = [
    [(0.19, 0.92), (0.23, 0.72), (0.05, 0.80)],
    [(0.23, 0.72), (0.28, 0.48), (0.07, 0.54)],
    [(0.28, 0.48), (0.31, 0.28), (0.09, 0.28)],
    [(0.31, 0.30), (0.44, 0.17), (0.26, 0.06)],
]
HEAD_CUT = []
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


# ---------------------------------------------------------------------- signs

def sign_cells(shape, w, h, band):
    """A w x h sign board (triangle or circle) as {(x, y): letter}: red outline, white inside."""
    out = {}
    if shape == "circle":
        r = w / 2.0
        for y in range(h):
            for x in range(w):
                d = ((x + 0.5 - r) ** 2 + (y + 0.5 - r) ** 2) ** 0.5
                if d <= r:
                    out[(x, y)] = "R" if d > r - band else "W"
        return out
    outer = [(0.5 * w, 0.0), (2.0, float(h)), (w - 2.0, float(h))]  # base corners inset so the sprite corners stay transparent
    cx, cy = 0.5 * w, 2.0 * h / 3.0  # the incentre of an equilateral triangle
    k = 1.0 - band / (h / 3.0)
    inner = [(cx + (x - cx) * k, cy + (y - cy) * k) for x, y in outer]
    for y in range(h):
        for x in range(w):
            if _inside(outer, x + 0.5, y + 0.5):
                out[(x, y)] = "W" if _inside(inner, x + 0.5, y + 0.5) else "R"
    return out


def silhouette(design, box_w, box_h):
    """The kaiju's solid shape (a set of (x, y)) filling a box_w x box_h box, facing right."""
    if design == "head":
        return poly_mask([HEAD_BODY] + HEAD_SPIKES, box_w, box_h) - poly_mask(HEAD_CUT, box_w, box_h)
    return poly_mask([BODY_POLY, BODY_ARM] + BODY_SPIKES, box_w, box_h)


# where the silhouette sits in the board: (box width, box height, centre x fraction, centre y fraction)
PICTURE = {
    ("head", "building"): (36, 33, 0.5, 0.64),
    ("head", "pavement"): (16, 14, 0.46, 0.68),
    ("body", "building"): (54, 34, 0.5, 0.50),
    ("body", "pavement"): (27, 17, 0.5, 0.50),
}


def board(design, kind):
    shape = SHAPES[design]
    if kind == "building":
        w, h = BUILDING_SIZE[shape]
    else:
        w, h = SIGN_SIZE[0], SIGN_BOARD_H[shape]
    cells = sign_cells(shape, w, h, RED_BAND[kind][shape])
    bw, bh, fx, fy = PICTURE[(design, kind)]
    ox, oy = round(fx * w - bw / 2), round(fy * h - bh / 2)
    for (x, y) in silhouette(design, bw, bh):
        cells[(x + ox, y + oy)] = "K"
    return cells, w, h


def sign_on_post(design):
    cells, w, h = board(design, "pavement")
    cx = SIGN_SIZE[0] // 2
    for y in range(h, 90):  # post, 4 wide, lit on its left
        for k, letter in enumerate(("K", "Q", "P", "K")):
            cells[(cx - 2 + k, y)] = letter
    for y, half in ((90, 7), (91, 8), (92, 8), (93, 8), (94, 7)):  # base
        for x in range(cx - half, cx + half):
            edge = x in (cx - half, cx + half - 1) or y in (90, 94)
            cells[(x, y)] = "K" if edge else ("Q" if x < cx - 2 else "P")
    return cells


# ------------------------------------------------------------------- to pixels

def to_rows(cells, w, h):
    rows = [[T] * w for _ in range(h)]
    for (x, y), letter in cells.items():
        if 0 <= x < w and 0 <= y < h:
            rows[y][x] = COLOURS[letter] + (255,)
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
    for design, shape in SHAPES.items():
        cells, w, h = board(design, "building")
        front = to_rows(cells, w, h)
        base = "kaiju_%s_%s_building" % (design, shape)
        info = {"kind": "building", "design": design, "shape": shape, "units": [3, round(h / 32, 2)],
                "anchor_px": [0, h - 1], "anchor_note": "bottom-left corner of the sign"}
        out[base + "_front.png"] = (front, dict(info, form="front-on"))
        out[base + "_wall.png"] = (shear(front), dict(info, form="sheared onto a wall, sloping down to the right (flip horizontally for the other wall)",
                                                      anchor_note="bottom-left corner of the sign (the column the slope starts from)"))
        sw, sh = SIGN_SIZE
        out["kaiju_%s_%s_sign.png" % (design, shape)] = (to_rows(sign_on_post(design), sw, sh), {
            "kind": "pavement", "design": design, "shape": shape, "form": "upright board on a post", "units": [1.5, 3],
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
    stray = sorted(colors - ALLOWED)
    out.append(("only the sign red, white, black and the post greys", not stray, "others: %s" % stray if stray else "none"))
    reds = sorted(c for c in colors if marks.is_redgull_red(c) and c != SIGN_RED)
    out.append(("no red but the one sign red", not reds, "other reds: %s" % reds if reds else "none"))
    out.append(("has the sign red outline", SIGN_RED in colors, "present" if SIGN_RED in colors else "missing"))
    out.append(("at most 5 colours", len(colors) <= 5, "%d colours" % len(colors)))
    opaque = sum(1 for p in px if p[3] == 255)
    out.append(("a real sign: at least 25% of the pixels are drawn", opaque >= 0.25 * w * h, "%d of %d" % (opaque, w * h)))
    return out


def expected_size(name):
    if name.endswith("_sign.png"):
        return SIGN_SIZE
    w, h = BUILDING_SIZE["triangle" if "_triangle_" in name else "circle"]
    return (w, h + (w - 1) // 2) if name.endswith("_wall.png") else (w, h)


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
    for name in sorted(sprites()):
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
    """Place sprites (rows) left to right, bottom aligned, on a bg canvas."""
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
    n = {d: "kaiju_%s_%s_" % (d, sh) for d, sh in SHAPES.items()}
    designs = [s[n[d] + "building_front.png"][0] for d in SHAPES] + [s[n[d] + "sign.png"][0] for d in SHAPES]
    write_png(archive / "signs_designs_dark_light_x4.png", side_by_side(designs, 4, gap=6))
    walls = [s[n[d] + "building_wall.png"][0] for d in SHAPES]
    write_png(archive / "signs_on_wall_dark_light_x4.png", side_by_side(walls, 4, gap=6))
    # The car is 96 art px long, a banner 96 px wide: the game draws both at scale 0.5,
    # so relative sizes here are exactly those on screen.
    scene = [s[n["head"] + "building_wall.png"][0], car_frame(), s[n["head"] + "sign.png"][0], s[n["body"] + "sign.png"][0],
             s[n["body"] + "building_wall.png"][0]]
    write_png(archive / "signs_next_to_car_dark_light_x3.png", side_by_side(scene, 3, bgs=(ASPHALT_BG, LIGHT_BG)))
    return archive


# ------------------------------------------------------------------------ build

def record(all_sprites):
    files = []
    for name, (rows, info) in all_sprites.items():
        colors = sorted({p[:3] for r in rows for p in r if p[3]})
        files.append(dict(file=name, size=[len(rows[0]), len(rows)], colours=len(colors), **info))
    return {
        "task": "T-130",
        "what": "Kaiju alert signs in road-sign style (board's quick tuning, 2026-10-14): head in a warning triangle, body in a prohibition circle; thick traffic-sign red outline, plain white inside, solid black kaiju silhouette only. Building banners front-on and sheared onto a wall (2:1), and pavement signs on a post. No letters.",
        "made_by": "game/tools/build_kaiju_banners.py (a script; no PixelLab call, board 2026-10-14). Byte-identical every run.",
        "scale_note": "32 art px per unit; drawn in the game at scale 0.5 like the car and the ground, texture_filter nearest",
        "palette": {k: list(v) for k, v in COLOURS.items()},
        "red_note": "SIGN_RED is the only red outside Redgull's look allowed in the art (Visual style, Decisions), only on these signs",
        "rules": "no anti-aliasing, no semi-transparent pixels, transparent background, only the sign red, white, black and the post greys, no letters",
        "check": "python game/tools/build_kaiju_banners.py check",
        "archive": "art-archive/T-130/: previews; first-version/ holds the first (neon) drawings",
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
        print("wrote the signs in", build(), "and the previews in", ARCHIVE)
    ok, lines = check_dir()
    for line in lines:
        print(line)
    print("ALL RULES PASS (%d sprites)" % len(sprites()) if ok else "SOME RULES FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
