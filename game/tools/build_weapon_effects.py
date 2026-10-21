#!/usr/bin/env python3
"""Builds the weapon effects' game-ready art (task T-071). No PixelLab call here.

From the raw generations in art-archive/T-071/ (exhaust_flame_raw.png, burning_raw.png) and a script-drawn
bullet, it writes to game/art/effects/ (PNG plus record JSON each):
  exhaust_flame_sheet.png  1792x1792  the exhaust flame: 2 flicker frames x 32 screen directions in 224x224 cells
                                      (8 columns x 8 rows; frame f, direction d is cell f*32 + d), the base of the
                                      flame at each cell's centre, direction d points at screen angle d*11.25 degrees
                                      (0 = right, clockwise, as Godot's angle()). The raw's tailpipe is erased.
  burning_flames.png        96x54     the flames of a burning enemy: 2 frames of 48x54 (the second the mirror)
  bullet.png                24x12     the gun's bullet: 2 pulse frames of 12x12

Rules (Visual style): hard edges, alpha 0 or 255 only, at most 30 colours, no Redgull red, 32 art pixels per
unit drawn at scale 0.5. Rotation is nearest-neighbour from the raw, once, so the engine never rotates pixel art.

  python game/tools/build_weapon_effects.py build   # writes the PNGs and records, then checks them
  python game/tools/build_weapon_effects.py check   # checks the written PNGs
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_weapon_art as weapon_art  # noqa: E402  (hard_alpha, unred, near_redgull)
import reduce_palette as palette  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
REPO = GAME.parent
RAW = REPO / "art-archive" / "T-071"
OUT = GAME / "art" / "effects"
MAX_COLORS = 30
DIRECTIONS = 32
COLS = 8
CELL = 224
FLAME_FRAMES = 2
BURN_SIZE = (48, 54)
BULLET_SIZE = 12
# The brown and dark-red pixels of the burning raw's logs (it drew a campfire), at its bottom rows.
LOG_FROM_ROW = 54
LOG_COLOURS = {(194, 97, 51), (129, 52, 46), (71, 20, 29), (62, 17, 25), (130, 20, 31), (110, 19, 31),
               (164, 41, 43), (82, 17, 27), (163, 74, 49), (99, 33, 36), (23, 2, 5)}
LOG_ZONE_FROM_ROW = 48


def finish(im: Image.Image) -> Image.Image:
    """Hard alpha, no Redgull red, at most MAX_COLORS colours."""
    im = weapon_art.unred(weapon_art.hard_alpha(im))
    if len({p[:3] for p in im.getdata() if p[3] == 255}) > MAX_COLORS:
        im = palette.reduce_image(im, MAX_COLORS)
    return im


def erase_pipe(raw: Image.Image) -> Image.Image:
    """Removes the tailpipe PixelLab drew: every grey or near-black pixel (the flame is strongly orange/yellow)."""
    im = raw.convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and max(r, g, b) - min(r, g, b) <= 12:
                px[x, y] = (0, 0, 0, 0)
    return im


def plume_axis(im: Image.Image) -> tuple[tuple[float, float], float]:
    """The flame's base point and the angle (radians, screen) its plume points at."""
    pts = [(x, y) for y in range(im.height) for x in range(im.width) if im.getpixel((x, y))[3]]
    xs = [p[0] for p in pts]
    x0, x1 = min(xs), max(xs)
    base = [p for p in pts if p[0] <= x0 + 6]
    tip = [p for p in pts if p[0] >= x1 - 10]
    bx = (sum(p[0] for p in base) / len(base), sum(p[1] for p in base) / len(base))
    tx = (sum(p[0] for p in tip) / len(tip), sum(p[1] for p in tip) / len(tip))
    return bx, math.atan2(tx[1] - bx[1], tx[0] - bx[0])


def flame_cell(src: Image.Image, base: tuple[float, float], axis: float, direction: int, flip: bool) -> Image.Image:
    """The plume pointing at screen angle direction * 360 / DIRECTIONS, base at the cell's centre."""
    theta = math.tau * direction / DIRECTIONS
    turn = theta - axis  # rotate the raw by this much
    c, s = math.cos(turn), math.sin(turn)
    out = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    po, ps = out.load(), src.load()
    ca, sa = math.cos(axis), math.sin(axis)
    for oy in range(CELL):
        for ox in range(CELL):
            dx, dy = ox + 0.5 - CELL / 2, oy + 0.5 - CELL / 2
            # inverse rotation back into the raw, around the base
            ux, uy = dx * c + dy * s, -dx * s + dy * c
            if flip:  # mirror along the plume's own axis
                along, across = ux * ca + uy * sa, -ux * sa + uy * ca
                ux, uy = along * ca + across * sa, along * sa - across * ca
            sx, sy = int(math.floor(base[0] + ux)), int(math.floor(base[1] + uy))
            if 0 <= sx < src.width and 0 <= sy < src.height:
                po[ox, oy] = ps[sx, sy]
    return out


def build_flame_sheet(raw_path: Path) -> Image.Image:
    src = erase_pipe(Image.open(raw_path))
    base, axis = plume_axis(src)
    rows = math.ceil(FLAME_FRAMES * DIRECTIONS / COLS)
    sheet = Image.new("RGBA", (CELL * COLS, CELL * rows), (0, 0, 0, 0))
    for f in range(FLAME_FRAMES):
        for d in range(DIRECTIONS):
            i = f * DIRECTIONS + d
            sheet.paste(flame_cell(src, base, axis, d, f == 1), ((i % COLS) * CELL, (i // COLS) * CELL))
    return finish(sheet)


def build_burning(raw_path: Path) -> Image.Image:
    raw = Image.open(raw_path).convert("RGBA")
    px = raw.load()
    for y in range(raw.height):
        for x in range(raw.width):
            r, g, b, a = px[x, y]
            if a and (y >= LOG_FROM_ROW or (y >= LOG_ZONE_FROM_ROW and (r, g, b) in LOG_COLOURS)):
                px[x, y] = (0, 0, 0, 0)
    frame = raw.crop((0, 0, BURN_SIZE[0], BURN_SIZE[1]))
    out = Image.new("RGBA", (BURN_SIZE[0] * 2, BURN_SIZE[1]), (0, 0, 0, 0))
    out.paste(frame, (0, 0))
    out.paste(frame.transpose(Image.FLIP_LEFT_RIGHT), (BURN_SIZE[0], 0))
    return finish(out)


# The bullet's colours: a near-black navy outline, then a stepped cyan glow to a white-hot core.
BULLET_RINGS = [  # (radius up to, colour)
    (1.6, (255, 255, 255)),
    (2.6, (200, 255, 255)),
    (3.7, (70, 230, 255)),
    (4.7, (20, 140, 185)),
    (5.7, (8, 16, 38)),
]


def build_bullet() -> Image.Image:
    out = Image.new("RGBA", (BULLET_SIZE * 2, BULLET_SIZE), (0, 0, 0, 0))
    for f in range(2):
        grow = 0.0 if f == 0 else -0.6  # the second frame pulses in a little
        for y in range(BULLET_SIZE):
            for x in range(BULLET_SIZE):
                d = math.hypot(x + 0.5 - BULLET_SIZE / 2, y + 0.5 - BULLET_SIZE / 2)
                for radius, colour in BULLET_RINGS:
                    r = radius + (grow if radius > 3 else 0.0)
                    if d <= r:
                        out.putpixel((f * BULLET_SIZE + x, y), colour + (255,))
                        break
    return out


PIECES = {
    "exhaust_flame_sheet": (
        lambda: build_flame_sheet(RAW / "exhaust_flame_raw.png"),
        "exhaust_flame_raw.png", "req_exhaust_flame.json",
        "The exhaust flame: 2 flicker frames x 32 screen directions, 224x224 cells in 8 columns, the flame's base at "
        "each cell's centre; direction d points at screen angle d*11.25 degrees (0 = right, clockwise); cell = frame*32 + d.",
        {"frames": 2, "directions": 32, "cell": [CELL, CELL], "columns": COLS},
        "tailpipe erased (grey and near-black pixels), plume turned and mirrored by nearest-neighbour rotation, hard alpha"),
    "burning_flames": (
        lambda: build_burning(RAW / "burning_raw.png"),
        "burning_raw.png", "req_burning.json",
        "The flames of a burning enemy: 2 frames of 48x54 side by side, the second the mirror (the flicker).",
        {"frames": 2, "frame_size": list(BURN_SIZE)},
        "the logs PixelLab drew under the flames cut off (bottom rows and the brown pixels), mirrored second frame"),
    "bullet": (
        build_bullet, None, None,
        "The starting gun's bullet: a cyan neon ball with a white-hot core, 2 pulse frames of 12x12 side by side.",
        {"frames": 2, "frame_size": [BULLET_SIZE, BULLET_SIZE]},
        "drawn by script, no PixelLab call (about 10 art pixels wide)"),
}


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (make, raw_name, req_name, what, extra, fixes) in PIECES.items():
        im = make()
        im.save(OUT / (name + ".png"))
        rec = {"task": "T-071", "what": what, "size": list(im.size), **extra}
        if raw_name:
            req = json.loads((RAW / req_name).read_text(encoding="utf-8"))
            rec["prompt"] = req.get("description")
            rec["made_by"] = ("game/tools/build_weapon_effects.py from art-archive/T-071/%s (PixelLab "
                              "/create-image-pixflux, 1 generation; request art-archive/T-071/%s; record %s.json there)"
                              % (raw_name, req_name, raw_name[:-4]))
        else:
            rec["prompt"] = None
            rec["made_by"] = "game/tools/build_weapon_effects.py (drawn by script, no PixelLab call). Byte-identical every run."
        rec["resources_consulted"] = ["docs/visual-style.md", "docs/weapons.md"]
        rec["script_fixes"] = fixes
        rec["hand_edit"] = "none"
        (OUT / (name + ".json")).write_text(json.dumps(rec, indent=1) + "\n", encoding="utf-8")


def check_png(path: Path):
    im = Image.open(path).convert("RGBA")
    px = list(im.getdata())
    semi = sum(1 for p in px if 0 < p[3] < 255)
    colours = {p[:3] for p in px if p[3] == 255}
    red = [c for c in colours if weapon_art.near_redgull(c)]
    return [("no semi-transparent pixels", semi == 0, "%d" % semi),
            ("%d colours or fewer" % MAX_COLORS, len(colours) <= MAX_COLORS, "%d colours" % len(colours)),
            ("has opaque pixels", len(colours) > 0, ""),
            ("transparent corners", all(im.getpixel(p)[3] == 0 for p in
                                       [(0, 0), (im.width - 1, 0), (0, im.height - 1), (im.width - 1, im.height - 1)]), ""),
            ("no Redgull red", not red, str(red))], im.size


def check():
    ok_all = True
    for name in PIECES:
        f = OUT / (name + ".png")
        if not f.exists():
            print("FAIL  %s missing" % f.name)
            ok_all = False
            continue
        res, size = check_png(f)
        ok = all(r[1] for r in res)
        ok_all &= ok
        print("%s  %s %s  %s" % ("PASS" if ok else "FAIL", f.name, size,
                                 "; ".join("%s %s" % (a, "ok" if k else "FAIL (%s)" % d) for a, k, d in res)))
    return 0 if ok_all else 1


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    if cmd == "build":
        build()
    sys.exit(check())
