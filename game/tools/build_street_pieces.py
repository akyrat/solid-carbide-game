#!/usr/bin/env python3
"""T-398: the level creator's sidewalk tiles (every curb piece) and meteor craters, as placeholders.

Free, no PixelLab: both are drawn by T-397's approved sample script (build_sidewalk_car_sample.py:
draw_sidewalk for the slabs, draw_crater for the crater), so they already fit the roads. T-399 swaps
the final art in by changing the files this script writes (and their json).

  python game/tools/build_street_pieces.py build   # writes the files below
  python game/tools/build_street_pieces.py check   # the committed files match a fresh build, and the rules

Writes:
  game/art/ground/sidewalk_tiles.png   one 128 x 64 ground tile (2 x 2 units) per curb piece, 8 to a row
  game/art/ground/sidewalk_tiles.json  per tile: name (the catalogue id), edges, corners, region
  game/art/craters/crater_<n>.png      CRATER_LOOKS ground decals (the road tile's diamond)
  game/data/level/craters.json         per crater: id, label, footprint_units, texture

A sidewalk tile's curb pieces (scripts/level_creator/sidewalk_curbs.gd picks them, the same names):
  edges   the sides with a road next to them, of "nesw" (n = -y, the screen's upper right; e = +x,
          lower right; s = +y, lower left; w = -x, upper left): a straight curb along each.
  corners the inner corners, of ne, se, sw, nw: a road diagonally next to the tile while neither side
          of that corner has one (where two sidewalks meet round a road's corner).
  Two edges next to each other make an outer corner by themselves. The name: "sidewalk", then
  "-<edges>" when it has edges, then "-in_<corner>_<corner>" when it has inner corners
  ("sidewalk-es", "sidewalk-n-in_se_sw", "sidewalk-in_ne").

Rules (check): alpha 0 or 255, at most 30 colours a file, no old-brand red. Same input, same pixels.
Needs Pillow and numpy.
"""
from __future__ import annotations

import itertools
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_sidewalk_car_sample as sample  # noqa: E402

GAME = Path(__file__).resolve().parents[1]
SHEET_PNG = GAME / "art/ground/sidewalk_tiles.png"
SHEET_JSON = GAME / "art/ground/sidewalk_tiles.json"
CRATER_DIR = GAME / "art/craters"
CRATERS_JSON = GAME / "data/level/craters.json"

TILE_W, TILE_H = sample.TILE_W, sample.TILE_H
COLS = 8
EDGES = "nesw"
CORNERS = ["ne", "se", "sw", "nw"]
CURB_PX = 3            # the sample's lift of the surface, art px (under the 0.1-unit curb rule)
SEED = 397             # the sample's seed: the same slabs and cracks as the approved tile
# Crater looks (proposal: three, as the ticket's "a few"): the sample's crater drawn with other seeds and
# hole sizes. Footprint 2 x 2 units (one ground tile), as the approved sample.
CRATER_LOOKS = [(397, 0.52), (4011, 0.46), (4012, 0.58)]
CRATER_FOOT = [2.0, 2.0]
MAX_COLORS = 30
RED_MIN, RED_OVER, RED_MAX_OTHER = 150, 70, 100


def tile_name(edges: str, corners: list[str]) -> str:
    s = "sidewalk"
    if edges:
        s += "-" + edges
    if corners:
        s += "-in_" + "_".join(corners)
    return s


def variants() -> list[tuple[str, list[str]]]:
    """Every (edges, corners) a tile can have: any edges, and an inner corner only where neither of its
    sides has an edge. The plain tile first."""
    out = []
    for n in range(16):
        edges = "".join(EDGES[i] for i in range(4) if n & (1 << i))
        free = [c for c in CORNERS if c[0] not in edges and c[1] not in edges]
        for k in range(len(free) + 1):
            for combo in itertools.combinations(free, k):
                out.append((edges, list(combo)))
    return out


def draw_tile(edges: str, corners: list[str]) -> np.ndarray:
    """One sidewalk tile with the curbs of `edges` and `corners` (the sample's colours). A front edge (e, s)
    shows the curb's top, its face and the gutter, as the approved sample; a back edge (n, w) shows its top
    and the gutter strip (its face looks away)."""
    img = sample.draw_sidewalk(CURB_PX, SEED, curb=False)
    ys, xs = np.mgrid[0:TILE_H, 0:TILE_W]
    u0, v0 = sample.ground_uv(xs, ys)
    u, v = sample.ground_uv(xs, ys, lift=CURB_PX)
    inside = (u0 >= 0) & (u0 < 2) & (v0 >= 0) & (v0 < 2)
    W, I = sample.CURB_WIDTH, sample.CURB_INSET
    edge = 2 - I

    def put(mask, colour):
        img[inside & mask] = [*colour, 255]

    def front(a, a0):
        top = (a >= edge - W) & (a < edge)
        face = (a >= edge) & (a0 < edge)
        strip = a0 >= edge
        put(top, sample.CURB_TOP)
        put(top & (a < edge - W + 0.045), sample.PAV_EDGE)
        put(face, sample.CURB_FACE)
        put(strip, sample.GUTTER_STRIP)
        return face, strip

    def back(a0):
        strip = a0 < I
        top = (a0 >= I) & (a0 < I + W)
        put(top, sample.CURB_TOP)
        put(top & (a0 >= I + W - 0.045), sample.PAV_EDGE)
        put(strip, sample.GUTTER_STRIP)
        put((a0 >= I - 0.05) & (a0 < I), sample.GUTTER)
        return strip

    faces = np.zeros_like(inside)
    strips = np.zeros_like(inside)
    if "n" in edges:
        strips |= back(v0)
    if "w" in edges:
        strips |= back(u0)
    if "e" in edges:
        f, s = front(u, u0)
        faces |= f
        strips |= s
    if "s" in edges:
        f, s = front(v, v0)
        faces |= f
        strips |= s
    # inner corners: a small square of curb in the corner, joining the curbs of the tiles beside it
    for c in corners:
        cu = (u0 >= edge - W) if "e" in c else (u0 < I + W)
        cv = (v0 >= edge - W) if "s" in c else (v0 < I + W)
        su = (u0 >= edge) if "e" in c else (u0 < I)
        sv = (v0 >= edge) if "s" in c else (v0 < I)
        put(cu & cv, sample.CURB_TOP)
        put(su & sv, sample.GUTTER_STRIP)
        strips |= inside & su & sv
    # the face's lowest row is shaded, and the gutter line runs where a front curb meets the road
    for x in range(TILE_W):
        col = np.nonzero(inside[:, x] & faces[:, x])[0]
        if len(col) >= 2:
            img[col.max(), x] = [*sample.CURB_FACE_LOW, 255]
    # the lit lip: a curb-top pixel right above a face pixel
    below = np.zeros_like(faces)
    below[:-1] = faces[1:]
    lip = inside & below & ~faces & ~strips
    img[lip] = [*sample.CURB_LIP, 255]
    img[lip & (xs % 5 == 1)] = [*sample.CURB_HIGHLIGHT, 255]
    return img


def build_sheet():
    vs = variants()
    rows = (len(vs) + COLS - 1) // COLS
    sheet = np.zeros((rows * TILE_H, COLS * TILE_W, 4), dtype=np.uint8)
    tiles = []
    for k, (edges, corners) in enumerate(vs):
        x, y = (k % COLS) * TILE_W, (k // COLS) * TILE_H
        sheet[y:y + TILE_H, x:x + TILE_W] = draw_tile(edges, corners)
        tiles.append({"name": tile_name(edges, corners), "edges": edges, "corners": corners,
                      "region": [x, y, TILE_W, TILE_H]})
    record = {
        "about": "T-398: the level creator's sidewalk tiles, one per curb piece (placeholders drawn by "
                 "game/tools/build_street_pieces.py from T-397's approved sample; T-399 swaps the art). "
                 "edges: the sides with a road next to them (n -y, e +x, s +y, w -x); corners: the inner "
                 "corners (a road diagonally next to it, neither side has one). Do not edit by hand.",
        "file": "res://art/ground/sidewalk_tiles.png", "tile_px": [TILE_W, TILE_H],
        "cell_units": 2, "tiles": tiles}
    return sheet, record


def build_craters():
    out, images = [], {}
    for n, (seed, r_hole) in enumerate(CRATER_LOOKS, start=1):
        name = "crater_%d" % n
        images[name] = sample.draw_crater(seed=seed, r_hole=r_hole)
        out.append({"id": "crater-%d" % n, "label": "piece_meteor_crater",
                    "footprint_units": list(CRATER_FOOT), "texture": "res://art/craters/%s.png" % name})
    record = {
        "about": "T-398: the level creator's meteor craters (Level design, Decisions, \"Sidewalks and parked "
                 "cars in the level creator\", Meteor craters): ground decals the car drives over, no crash. "
                 "Placeholders drawn by game/tools/build_street_pieces.py from T-397's approved crater; T-399 "
                 "swaps the art by changing the textures here and the PNGs. The footprint is a square of "
                 "whole ground cells; the texture is its diamond (128 x 64 art px per 2 x 2 units, drawn at "
                 "draw_scale). Do not edit by hand.",
        "draw_scale": 0.5, "craters": out}
    return images, record


def dump(obj) -> str:
    return json.dumps(obj, indent=1) + "\n"


def build():
    sheet, record = build_sheet()
    SHEET_PNG.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(sheet, "RGBA").save(SHEET_PNG)
    SHEET_JSON.write_text(dump(record), encoding="utf-8", newline="\n")
    images, crec = build_craters()
    CRATER_DIR.mkdir(parents=True, exist_ok=True)
    for name, img in images.items():
        Image.fromarray(img, "RGBA").save(CRATER_DIR / (name + ".png"))
    CRATERS_JSON.write_text(dump(crec), encoding="utf-8", newline="\n")
    print("Wrote %d sidewalk tiles and %d craters" % (len(record["tiles"]), len(images)))


def rules(arr: np.ndarray) -> list[str]:
    problems = []
    a = arr[..., 3]
    if not np.all((a == 0) | (a == 255)):
        problems.append("alpha is not 0 or 255")
    colours = {tuple(int(v) for v in c[:3]) for c in arr[a == 255]}
    if len(colours) > MAX_COLORS:
        problems.append("%d colours (at most %d)" % (len(colours), MAX_COLORS))
    reds = [c for c in colours if c[0] >= RED_MIN and max(c[1], c[2]) <= RED_MAX_OTHER and c[0] - max(c[1], c[2]) >= RED_OVER]
    if reds:
        problems.append("%d old-brand red colours" % len(reds))
    return problems


def check() -> int:
    ok = True
    sheet, record = build_sheet()
    if not SHEET_PNG.exists() or not np.array_equal(np.array(Image.open(SHEET_PNG).convert("RGBA")), sheet):
        print("FAIL  %s differs from a fresh build" % SHEET_PNG.name)
        ok = False
    if not SHEET_JSON.exists() or SHEET_JSON.read_text(encoding="utf-8") != dump(record):
        print("FAIL  %s differs from a fresh build" % SHEET_JSON.name)
        ok = False
    for t in record["tiles"]:
        x, y, w, h = t["region"]
        for p in rules(sheet[y:y + h, x:x + w]):
            print("FAIL  %s: %s" % (t["name"], p))
            ok = False
    images, crec = build_craters()
    for name, img in images.items():
        png = CRATER_DIR / (name + ".png")
        if not png.exists() or not np.array_equal(np.array(Image.open(png).convert("RGBA")), img):
            print("FAIL  %s differs from a fresh build" % png.name)
            ok = False
        for p in rules(img):
            print("FAIL  %s: %s" % (name, p))
            ok = False
    if not CRATERS_JSON.exists() or CRATERS_JSON.read_text(encoding="utf-8") != dump(crec):
        print("FAIL  craters.json differs from a fresh build")
        ok = False
    print("OK" if ok else "FAILED")
    return 0 if ok else 1


def main(argv=None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    cmd = argv[0] if argv else "build"
    if cmd == "build":
        build()
        return 0
    if cmd == "check":
        return check()
    print("usage: build_street_pieces.py build|check")
    return 2


if __name__ == "__main__":
    sys.exit(main())
