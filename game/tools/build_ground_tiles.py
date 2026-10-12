#!/usr/bin/env python3
"""Builds the MVP map's ground (task T-103): the tile atlas and the map's ground layout.

No PixelLab call. It reads:
  - game/art/ground/road_tile.png: the board-approved road tile (T-063), 128 x 64, 2 x 2 units;
  - art-archive/T-103/raw/ground_tile_N_tile-N.png: the one PixelLab /create-tiles-pro call of
    T-103 (style image: the approved tile), tiles 0-3 dusty gravel, 4-9 plain asphalt;
  - game/data/level/mvp_map.json: the map's layout (read only; never changed here).
and writes:
  - game/art/ground/ground_atlas.png (+ ground_atlas.json, the record of every tile in it);
  - game/data/level/mvp_ground.json: which atlas tile goes on each 2 x 2 unit cell of the map.

Every tile is a 2:1 isometric diamond of 128 x 64 art pixels covering 2 x 2 units (the approved
tile's size and exact tiling footprint). Every edge, block, road and the gravel square of the map
lies on even units, so the cells fit the layout exactly.

What the script makes from the approved and generated tiles (no new colours except none: every
pixel is a pixel of one of those tiles):
  - edge fix: the generated tiles have a dark outline along their diamond edge (a visible grid when
    repeated); the pixels near the edge are replaced by their mirror image further in;
  - plain asphalt: the approved tile with its white line pixels replaced by the asphalt beside them;
  - centre line: a 24-unit road is 12 tiles across, so its centre is a tile edge. The approved
    tile's own line, moved by 1 unit, is split into a right-half tile (line on its right edge)
    and a left-half tile, drawn over the plain asphalt;
  - zebra crossings: white stripes along the road (the approved tile's own white), 0.5 units wide,
    1 unit apart, 1.5 units long, over the asphalt; dark crack pixels stay over the paint;
  - roads along world x: every along-y tile mirrored left-right (swapping world x and y flips the
    2:1 diamond left-right).

Commands (run from the repo root):
  python game/tools/build_ground_tiles.py            # build the atlas, its record and the layout
  python game/tools/build_ground_tiles.py check      # technical rules for every atlas tile
  python game/tools/build_ground_tiles.py mockup OUT.png [X0 Y0 X1 Y1]   # a picture of the ground
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_road_tile as road  # noqa: E402
from remove_car_shadow import write_png  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
APPROVED = REPO / "game/art/ground/road_tile.png"
RAW_DIR = REPO / "art-archive/T-103/raw"
LAYOUT = REPO / "game/data/level/mvp_map.json"
ATLAS_PNG = REPO / "game/art/ground/ground_atlas.png"
ATLAS_JSON = REPO / "game/art/ground/ground_atlas.json"
GROUND_JSON = REPO / "game/data/level/mvp_ground.json"

T = (0, 0, 0, 0)
W, H = road.TILE_W, road.TILE_H
CELL = road.UNITS_PER_TILE  # units per tile side
ATLAS_COLS = 8
WHITE = (223, 221, 218, 255)  # the approved tile's own line white

# The generated tiles used (index in the T-103 call -> role). Tiles 3 and 8 are not used (result notes).
GRAVEL_RAW = [0, 1, 2]
ASPHALT_RAW = [4, 5, 6, 7, 9]
# How often each asphalt base is picked (its name -> weight), so the cracks do not repeat regularly.
BASE_WEIGHTS = {"a0": 4, "a0m": 2, "g4": 1, "g5": 1, "g6": 3, "g7": 2, "g9": 3}
GRAVEL_WEIGHTS = {"gravel0": 1, "gravel1": 1, "gravel2": 1}
# Zebra crossings: the band starts this many units from a junction's box, one tile deep.
ZEBRA_GAP = 2
# The centre line stops this many units from a junction's box (the zebra band and a gap of 2).
LINE_STOP = 6


# ---- pixels -----------------------------------------------------------------------------------

def lum(p):
    return 0.3 * p[0] + 0.59 * p[1] + 0.11 * p[2]


def local_units(x, y):
    """World units (wx, wy) inside the tile of the centre of art pixel (x, y); top vertex = (0, 0)."""
    sx, sy = x + 0.5 - W / 2, y + 0.5
    return (sx / 32 + sy / 16) / 2, (sy / 16 - sx / 32) / 2


def plane_pixel(tile, X, Y):
    """The pixel at (X, Y) of the plane tiled with `tile` (one copy at the origin, neighbours at
    (+-64, +32)), using the exact footprint, so every plane pixel comes from exactly one copy."""
    for a in range(-3, 4):
        for b in range(-3, 4):
            lx, ly = X - (a - b) * 64, Y - (a + b) * 32
            if 0 <= lx < W and 0 <= ly < H and road.footprint(lx, ly):
                return tile[ly][lx]
    return T


def cut_to_footprint(rows):
    return [[p if road.footprint(x, y) else T for x, p in enumerate(r)] for y, r in enumerate(rows)]


def fix_edges(rows, band=4):
    """Removes the dark outline along a generated tile's diamond edge: every pixel within `band`
    pixels of the edge (measured along its row) takes the pixel mirrored the same distance further
    in; in the short rows near the top and bottom vertices, the pixel 2 * band rows nearer the centre."""
    src = cut_to_footprint(rows)
    out = [list(r) for r in src]
    for y in range(H):
        for x in range(W):
            if not road.footprint(x, y):
                continue
            d = road.inner_distance(x, y)
            if d >= band:
                continue
            q = T
            if y < 32:
                left, right = 62 - 2 * y, 65 + 2 * y
            else:
                k = y - 32
                left, right = 2 + 2 * k, 125 - 2 * k
            if right - left + 1 >= 4 * band:
                m = 2 * band - 1 - d
                xx = left + m if x - left <= right - x else right - m
                q = src[y][xx]
            else:
                yy = y + 2 * band if y < 32 else y - 2 * band
                for dx in range(0, W):
                    for xx in (x - dx, x + dx):
                        if 0 <= xx < W and road.footprint(xx, yy) and road.inner_distance(xx, yy) >= band:
                            q = src[yy][xx]
                            break
                    if q[3]:
                        break
            out[y][x] = q
    return out


def flip(rows):
    """Mirror left-right: swaps world x and y on the 2:1 diamond (its footprint is symmetric)."""
    return [list(reversed(r)) for r in rows]


def is_line(p):
    return p[3] == 255 and p[:3] == WHITE[:3]


def remove_line(tile):
    """The approved tile without its white line: each line pixel takes the asphalt 1/4 unit across
    the road (8 pixels right, 4 down, on the tile's own seamless repeat)."""
    out = [list(r) for r in tile]
    for y in range(H):
        for x in range(W):
            if is_line(tile[y][x]):
                for k in (1, -1, 2, -2):
                    q = plane_pixel(tile, x + 8 * k, y + 4 * k)
                    if q[3] and not is_line(q):
                        out[y][x] = q
                        break
    return out


def line_mask(approved):
    """The approved line moved by 1 unit along world x: it then lies on the tile's edges
    (wx = 0 and wx = 2). Returns the set of its pixels."""
    pts = set()
    for y in range(H):
        for x in range(W):
            if road.footprint(x, y) and is_line(plane_pixel(approved, x - 32, y - 16)):
                pts.add((x, y))
    return pts


def with_line(base, mask, side):
    """`base` with the half of the line on its right edge (wx near 2, side 'r') or left edge
    (wx near 0, side 'l'), for the tiles either side of a road's centre."""
    out = [list(r) for r in base]
    for (x, y) in mask:
        wx, _ = local_units(x, y)
        if (side == "r" and wx > 1) or (side == "l" and wx < 1):
            out[y][x] = WHITE
    return out


def with_zebra(base, skip=()):
    """`base` with zebra stripes along world y: stripes k = 0, 1 at wx in [k + 0.25, k + 0.75),
    wy in [0.25, 1.75). Stripes in `skip` are left out (the road's edge). Dark crack pixels
    (darker than the asphalt's main colour) stay over the paint."""
    out = [list(r) for r in base]
    main = max(((sum(1 for r in base for p in r if p == c)), c) for c in {p for r in base for p in r if p[3]})[1]
    for y in range(H):
        for x in range(W):
            p = base[y][x]
            if not p[3]:
                continue
            wx, wy = local_units(x, y)
            k = int(wx // 1)
            if k in (0, 1) and k not in skip and 0.25 <= wx - k < 0.75 and 0.25 <= wy < 1.75:
                if lum(p) >= lum(main):
                    out[y][x] = WHITE
    return out


# ---- tiles ------------------------------------------------------------------------------------

def raw_path(i):
    return RAW_DIR / ("ground_tile_%d_tile-%d.png" % (i, i))


def build_tiles(approved=None, raws=None):
    """All atlas tiles, in order: a list of (name, rows, how it was made)."""
    approved = road.load(APPROVED) if approved is None else approved
    raws = {i: road.load(raw_path(i)) for i in GRAVEL_RAW + ASPHALT_RAW} if raws is None else raws
    tiles = []
    for i in GRAVEL_RAW:
        tiles.append(("gravel%d" % i, fix_edges(raws[i]),
                      "T-103 PixelLab tile %d (dusty gravel), edge outline removed (fix_edges)" % i))
    a0 = cut_to_footprint(remove_line(approved))
    bases = {"a0": (a0, "the approved road_tile.png with its line removed (remove_line)"),
             "a0m": (flip(a0), "a0 mirrored left-right (cracks run the other way)")}
    for i in ASPHALT_RAW:
        bases["g%d" % i] = (fix_edges(raws[i]), "T-103 PixelLab tile %d (plain asphalt), edge outline removed" % i)
    mask = line_mask(approved)
    for bname in BASE_WEIGHTS:
        base, how = bases[bname]
        kinds = [
            ("plain", base, how),
            ("line_r", with_line(base, mask, "r"), "%s + the approved line moved 1 unit, right half" % bname),
            ("line_l", with_line(base, mask, "l"), "%s + the approved line moved 1 unit, left half" % bname),
            ("zebra", with_zebra(base), "%s + zebra stripes" % bname),
            ("zebra_e0", with_zebra(base, skip=(0,)), "%s + zebra stripes, road edge at wx = 0" % bname),
            ("zebra_e1", with_zebra(base, skip=(1,)), "%s + zebra stripes, road edge at wx = 2" % bname),
        ]
        for kind, rows, h in kinds:
            tiles.append(("y_%s_%s" % (kind, bname), rows, "along world y: " + h))
            tiles.append(("x_%s_%s" % (kind, bname), flip(rows), "along world x (mirrored): " + h))
    return tiles


def atlas_rows(tiles):
    n = len(tiles)
    rows_n = (n + ATLAS_COLS - 1) // ATLAS_COLS
    canvas = [[T] * (ATLAS_COLS * W) for _ in range(rows_n * H)]
    for k, (_, rows, _) in enumerate(tiles):
        ox, oy = (k % ATLAS_COLS) * W, (k // ATLAS_COLS) * H
        for y in range(H):
            canvas[oy + y][ox:ox + W] = rows[y]
    return canvas


def atlas_tile(atlas, k):
    ox, oy = (k % ATLAS_COLS) * W, (k // ATLAS_COLS) * H
    return [atlas[oy + y][ox:ox + W] for y in range(H)]


# ---- the map's ground layout ------------------------------------------------------------------

def bands(intervals, lo, hi):
    """The gaps in [lo, hi] between sorted intervals: the road bands across one axis."""
    out, cur = [], lo
    for a, b in sorted(set(intervals)):
        if a > cur:
            out.append((cur, a))
        cur = max(cur, b)
    if cur < hi:
        out.append((cur, hi))
    return out


def in_band(v, bs):
    for b in bs:
        if b[0] <= v < b[1]:
            return b
    return None


def pick(weights, i, j, salt):
    """A deterministic, well-spread pick from `weights` for cell (i, j)."""
    h = (i * 73856093) ^ (j * 19349663) ^ (salt * 83492791)
    h = (h ^ (h >> 13)) * 0x5BD1E995 & 0xFFFFFFFF
    h ^= h >> 15
    total = sum(weights.values())
    r = h % total
    for name, w in weights.items():
        if r < w:
            return name
        r -= w
    return name


def build_ground(layout, names):
    """The tile name for every cell, rows of cells top to bottom (world y), each left to right."""
    m = layout["map"]["rect"]
    x0, y0 = int(m["x"]), int(m["y"])
    size = int(m["w"])
    n = size // CELL
    grid = layout["ground_rows"]

    def ground(ux, uy):
        if not (x0 <= ux < x0 + size and y0 <= uy < y0 + size):
            return None
        return grid[uy - y0][ux - x0]

    xs = bands([(b["x"], b["x"] + b["w"]) for b in layout["buildings"]], x0, x0 + size)
    ys = bands([(b["y"], b["y"] + b["h"]) for b in layout["buildings"]], y0, y0 + size)
    xs = [(int(a), int(b)) for a, b in xs]
    ys = [(int(a), int(b)) for a, b in ys]

    def road(ux, uy):
        return ground(ux, uy) == "R"

    # junction boxes: where a road band along x meets one along y; count the road arms
    arms = {}
    for vb in xs:
        for hb in ys:
            if not road(vb[0], hb[0]):
                continue
            a = 0
            a += road(vb[0], hb[0] - 1)
            a += road(vb[0], hb[1])
            a += road(vb[0] - 1, hb[0])
            a += road(vb[1], hb[0])
            arms[(vb, hb)] = a

    def near_junction(pos, band_other, other_bands, fixed_band, along_y):
        """Distance in units from the cell span [pos, pos + 2) to the nearest box edge along the
        road, and whether that box is a junction (3 or 4 arms)."""
        best = None
        for ob in other_bands:
            key = (fixed_band, ob) if along_y else (ob, fixed_band)
            if key not in arms:
                continue
            if pos + CELL <= ob[0]:
                d = ob[0] - (pos + CELL)
            elif pos >= ob[1]:
                d = pos - ob[1]
            else:
                continue
            if best is None or d < best[0]:
                best = (d, arms[key] >= 3)
        return best

    cells = []
    for j in range(n):
        row = []
        uy = y0 + j * CELL
        for i in range(n):
            ux = x0 + i * CELL
            g = ground(ux, uy)
            if g == "G":
                row.append(pick(GRAVEL_WEIGHTS, i, j, 2))
                continue
            if g != "R":
                row.append(None)
                continue
            base = pick(BASE_WEIGHTS, i, j, 1)
            vb, hb = in_band(ux, xs), in_band(uy, ys)
            if vb and hb:
                row.append("y_plain_" + base)
                continue
            along_y = vb is not None
            band = vb if along_y else hb
            pos = uy if along_y else ux  # position along the road
            across = ux if along_y else uy  # position across the road
            near = near_junction(pos, None, ys if along_y else xs, band, along_y)
            p = "y_" if along_y else "x_"
            kind = "plain"
            centre = (band[0] + band[1]) // 2
            if near is not None and near[1] and ZEBRA_GAP <= near[0] < ZEBRA_GAP + CELL:
                kind = "zebra"
                if across == band[0]:
                    kind = "zebra_e0"
                elif across + CELL == band[1]:
                    kind = "zebra_e1"
            elif near is None or not near[1] or near[0] >= LINE_STOP:
                if across + CELL == centre:
                    kind = "line_r"
                elif across == centre:
                    kind = "line_l"
            row.append(p + kind + "_" + base)
        cells.append(row)
    return {
        "what": "The MVP map's ground tiles (task T-103): the atlas tile on each 2 x 2 unit cell.",
        "generated_by": "python game/tools/build_ground_tiles.py",
        "atlas": "res://art/ground/ground_atlas.png",
        "atlas_record": "res://art/ground/ground_atlas.json",
        "cell_units": CELL,
        "origin": [x0, y0],
        "cols": n,
        "rows": n,
        "tile_px": [W, H],
        "atlas_columns": ATLAS_COLS,
        "names": names,
        "cells": [[(-1 if c is None else names.index(c)) for c in r] for r in cells],
        "road_bands_x": xs,
        "road_bands_y": ys,
    }


# ---- record, check, mock-up -------------------------------------------------------------------

def record(tiles):
    return {
        "file": "ground_atlas.png",
        "task": "T-103",
        "what": "The MVP map's ground tiles: a grid of %d columns of 128 x 64 isometric diamonds "
                "(2 x 2 units each, drawn at scale 0.5), dusty gravel and asphalt with its white centre "
                "line and zebra crossings, roads along world y and along world x." % ATLAS_COLS,
        "made_by": "python game/tools/build_ground_tiles.py (no PixelLab call in this step)",
        "sources": {
            "approved road tile": "game/art/ground/road_tile.png (board-approved, T-063)",
            "PixelLab call": "one /create-tiles-pro call of T-103 (job f6cf663e-3d60-472a-b5df-b03c6d79fc71, "
                             "15 generations, style image road_tile.png); raw tiles and their records in "
                             "art-archive/T-103/raw/",
            "used": "gravel: tiles %s; asphalt: tiles %s; not used: 3 and 8" % (GRAVEL_RAW, ASPHALT_RAW),
        },
        "pixellab_calls": [{
            "endpoint": "/create-tiles-pro",
            "job_id": "f6cf663e-3d60-472a-b5df-b03c6d79fc71",
            "settings": "style_images: [game/art/ground/road_tile.png] (128 x 64); tile_type isometric, "
                        "tile_size 128, tile_view top-down (ignored with a style image); no tile_feature",
            "prompt": "in the log line of the call (game/art/pixellab-generation-log.jsonl) and in each raw "
                      "record in art-archive/T-103/raw/",
            "cost": "15 generations ($0.00, subscription)",
            "balance_before": 4971,
            "balance_after": 4956,
            "result": "10 tiles: 0-3 dusty gravel, 4-9 plain asphalt; one round, nothing regenerated",
        }],
        "size": "each tile 128 x 64 pixels = 2 x 2 units; neighbours at (+64, +32) along world x and (-64, +32) along world y; exact footprint",
        "layout": "game/data/level/mvp_ground.json",
        "tiles": [{"index": k, "name": name, "atlas_xy": [(k % ATLAS_COLS) * W, (k // ATLAS_COLS) * H], "made": how}
                  for k, (name, _, how) in enumerate(tiles)],
    }


def check_atlas(atlas, n, max_colors=30):
    """Runs the tile rules (build_road_tile.check_tile) and the tiling check on every atlas tile."""
    results = []
    for k in range(n):
        t = atlas_tile(atlas, k)
        res = road.check_tile(t, max_colors)
        g, o = road.tiling_report(t) if k < 3 or k % 12 in (3, 4) else (0, 0)
        res.append(("tiles with 0 gaps and 0 overlaps", (g, o) == (0, 0), "%d gaps, %d overlaps" % (g, o)))
        results.append((k, res))
    return results


def mockup(atlas, ground, area=None):
    """The ground as the game draws it, at the art's own size (1 art pixel per pixel)."""
    n = ground["cols"]
    i0, j0, i1, j1 = area if area else (0, 0, n, n)
    cw = ((i1 - i0) + (j1 - j0)) * 64 + 64
    chh = ((i1 - i0) + (j1 - j0)) * 32 + 64
    canvas = [[(10, 9, 22, 255)] * cw for _ in range(chh)]
    ox = (j1 - j0) * 64
    for j in range(j0, j1):
        for i in range(i0, i1):
            k = ground["cells"][j][i]
            if k < 0:
                continue
            road.blit(canvas, atlas_tile(atlas, k), ox + ((i - i0) - (j - j0)) * 64, ((i - i0) + (j - j0)) * 32)
    return canvas


def build():
    tiles = build_tiles()
    names = [t[0] for t in tiles]
    atlas = atlas_rows(tiles)
    layout = json.loads(LAYOUT.read_text(encoding="utf-8"))
    ground = build_ground(layout, names)
    return tiles, atlas, ground


def dump(obj):
    return json.dumps(obj, indent=1) + "\n"


def ground_text(ground):
    """mvp_ground.json with one row of cells per line (smaller and easy to read)."""
    g = dict(ground)
    cells = g.pop("cells")
    text = json.dumps(g, indent=1)[:-2]
    rows = ",\n  ".join(json.dumps(r, separators=(",", ":")) for r in cells)
    return text + ',\n "cells": [\n  ' + rows + "\n ]\n}\n"


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if argv and argv[0] == "check":
        atlas = road.load(ATLAS_PNG)
        rec = json.loads(ATLAS_JSON.read_text(encoding="utf-8"))
        ok = True
        for k, res in check_atlas(atlas, len(rec["tiles"])):
            bad = [r for r in res if not r[1]]
            ok = ok and not bad
            print("%3d %-22s %s" % (k, rec["tiles"][k]["name"], "PASS" if not bad else "FAIL " + str(bad)),
                  "(%s)" % next(r[2] for r in res if r[0].startswith("about")))
        print("ALL PASS" if ok else "SOME FAIL")
        return 0 if ok else 1
    tiles, atlas, ground = build()
    if argv and argv[0] == "mockup":
        area = tuple(int(v) for v in argv[2:6]) if len(argv) >= 6 else None
        write_png(argv[1], mockup(atlas, ground, area))
        return 0
    write_png(ATLAS_PNG, atlas)
    ATLAS_JSON.write_text(dump(record(tiles)), encoding="utf-8", newline="\n")
    GROUND_JSON.write_text(ground_text(ground), encoding="utf-8", newline="\n")
    print("wrote %s (%d tiles), %s, %s" % (ATLAS_PNG.name, len(tiles), ATLAS_JSON.name, GROUND_JSON.name))
    return 0


if __name__ == "__main__":
    sys.exit(main())
