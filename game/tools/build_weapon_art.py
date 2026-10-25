#!/usr/bin/env python3
"""Turns T-175's raw PixelLab generations into the weapons' game-ready art (no PixelLab call here).

Raw files (art-archive/T-175/, from game/tools/pixellab_client.py) become, in game/art/weapons/:
  underglow.png          224x112  the neon ring under the car (the 2.5-unit circle in the iso view)
  molotov_bottle.png      32x32   the bottle in flight
  molotov_fire.png       136x68   the fire area on the ground (the 1.5-unit circle in the iso view)
  molotov_fire_flip.png  136x68   the same, mirrored: the second frame of the flicker (free, by script)
  wiper_sheet.png       2048x512  the wiper arm in 32 directions (8 columns x 4 rows of 256x128): the raw
                                  arm turned by a script in the flat world, then projected by the run's iso
                                  transform, pivot at each cell's centre, so the engine never rotates pixel art

Rules (Visual style): hard edges, alpha 0 or 255 only, at most 30 colours per sprite (a free palette
reduction when a raw one has more; raw kept in the archive), 32 art pixels per unit, drawn at scale 0.5.

  python game/tools/build_weapon_art.py build   # writes the PNGs and records, then checks them
  python game/tools/build_weapon_art.py check   # checks the written PNGs (exit 1 on a fail)
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import reduce_palette as palette  # noqa: E402
from style_rules import REDGULL_RED, rgb_distance  # noqa: E402  (Visual style rule 6)

GAME = Path(__file__).resolve().parent.parent
REPO = GAME.parent
RAW = REPO / "art-archive" / "T-175"
OUT = GAME / "art" / "weapons"
MAX_COLORS = 30
DIRECTIONS = 32
COLS = 8
CELL = (256, 128)
# Nominal length of the wiper in art pixels (2.5 units x 32) from the pivot at the sprite's left end.
ARM_LEN_PX = 80.0
PIVOT = (48, 12)  # the pivot joint (the middle) of the raw 96x24 wiper, in its own pixels


def hard_alpha(im: Image.Image) -> Image.Image:
    """Alpha 0 or 255 only (anything under half becomes clear)."""
    im = im.convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
    return im


RED_NEAR = 60.0  # RGB distance (0..255) from the logo's red inside which a deep flame shade is pushed to orange


def near_redgull(c) -> bool:
    return rgb_distance(c, REDGULL_RED) < RED_NEAR


def unred(im: Image.Image) -> Image.Image:
    """Free fix: a colour close to Redgull's red (deep flame shades) is pushed to orange
    (green raised to 85, blue cut to 0), so the art never shows the brand red."""
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 255 and near_redgull((r, g, b)):
                px[x, y] = (max(r, 150), max(g, 85), 0, 255)
    return im


def clean(im: Image.Image) -> Image.Image:
    im = unred(hard_alpha(im))
    colours = {p[:3] for p in im.getdata() if p[3] == 255}
    if len(colours) > MAX_COLORS:
        im = palette.reduce_image(im, MAX_COLORS)
    return im


def wiper_frame(raw: Image.Image, i: int) -> Image.Image:
    """The arm pointing at flat-world angle i * 360 / DIRECTIONS, seen through the iso transform
    (screen = (x - y, (x + y) / 2)), pivot at the cell's centre; nearest neighbour only."""
    w, h = CELL
    theta = math.tau * i / DIRECTIONS
    c, s = math.cos(theta), math.sin(theta)
    out = Image.new("RGBA", CELL, (0, 0, 0, 0))
    po = out.load()
    pr = raw.load()
    rw, rh = raw.size
    ox, oy = w / 2, h / 2
    # Raw -> flat: (u, v) in the raw relative to its pivot; u along the arm. The raw is
    # 96 wide for a nominal 80 long arm, so 1 raw pixel is 1 flat pixel along the arm.
    for sy in range(h):
        for sx in range(w):
            dx, dy = sx + 0.5 - ox, sy + 0.5 - oy
            # inverse iso: x - y = dx, x + y = 2 dy
            fx, fy = dy + dx / 2.0, dy - dx / 2.0
            u = fx * c + fy * s
            v = -fx * s + fy * c
            if u < 0.0 or u > ARM_LEN_PX:
                continue  # only the arm's half past the pivot joint
            # The raw's right half (PIVOT[0] pixels) is stretched along the arm to the full length.
            rx = int(math.floor(PIVOT[0] + u * (rw - PIVOT[0]) / ARM_LEN_PX))
            ry = int(math.floor(v + PIVOT[1]))
            if 0 <= rx < rw and 0 <= ry < rh:
                po[sx, sy] = pr[rx, ry]
    return out


def build_wiper_sheet(raw_path: Path) -> Image.Image:
    raw = clean(Image.open(raw_path))
    rows = math.ceil(DIRECTIONS / COLS)
    sheet = Image.new("RGBA", (CELL[0] * COLS, CELL[1] * rows), (0, 0, 0, 0))
    for i in range(DIRECTIONS):
        sheet.paste(wiper_frame(raw, i), ((i % COLS) * CELL[0], (i // COLS) * CELL[1]))
    return sheet


PIECES = {
    "underglow": ("underglow_raw.png", "req_underglow.json", "The neon ring under the car: the underglow's damage circle (2.5 units) in the iso view."),
    "molotov_bottle": ("molotov_bottle_raw.png", "req_molotov_bottle.json", "The molotov bottle in flight."),
    "molotov_fire": ("molotov_fire_raw.png", "req_molotov_fire.json", "The molotov fire area on the ground: the 1.5-unit circle in the iso view."),
}


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (raw_name, req_name, what) in PIECES.items():
        im = clean(Image.open(RAW / raw_name))
        write(name, im, raw_name, req_name, what)
        if name == "molotov_fire":
            write("molotov_fire_flip", im.transpose(Image.FLIP_LEFT_RIGHT), raw_name, req_name,
                  "The fire area mirrored: the flicker's second frame, made by script.")
    sheet = build_wiper_sheet(RAW / "wiper_raw.png")
    write("wiper_sheet", sheet, "wiper_raw.png", "req_wiper.json",
          "The wiper arm in 32 flat-world directions, iso-projected, pivot at the cell centre "
          "(cells 256x128, 8 columns x 4 rows, frame i = angle i*11.25 degrees).")


def write(name, im, raw_name, req_name, what):
    im.save(OUT / (name + ".png"))
    req = json.loads((RAW / req_name).read_text(encoding="utf-8"))
    rec = {
        "task": "T-175", "what": what, "size": list(im.size), "prompt": req.get("description"),
        "made_by": "game/tools/build_weapon_art.py from art-archive/T-175/%s (PixelLab /create-image-pixflux, "
                   "1 generation; request art-archive/T-175/%s; record %s.json there)" % (raw_name, req_name, raw_name[:-4]),
        "resources_consulted": ["docs/visual-style.md", "docs/weapons.md"],
        "script_fixes": "hard alpha, palette cut to 30 colours if over", "hand_edit": "none",
    }
    (OUT / (name + ".json")).write_text(json.dumps(rec, indent=1) + "\n", encoding="utf-8")


def check_png(path: Path):
    im = Image.open(path).convert("RGBA")
    px = list(im.getdata())
    semi = sum(1 for p in px if 0 < p[3] < 255)
    colours = {p[:3] for p in px if p[3] == 255}
    red = [c for c in colours if near_redgull(c)]
    return [("no semi-transparent pixels", semi == 0, "%d" % semi),
            ("%d colours or fewer" % MAX_COLORS, len(colours) <= MAX_COLORS, "%d colours" % len(colours)),
            ("has opaque pixels", len(colours) > 0, ""),
            ("transparent corners", all(im.getpixel(p)[3] == 0 for p in
                                       [(0, 0), (im.width - 1, 0), (0, im.height - 1), (im.width - 1, im.height - 1)]), ""),
            ("no Redgull red", not red, str(red))], im.size


def check():
    ok_all = True
    for f in sorted(OUT.glob("*.png")):
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
