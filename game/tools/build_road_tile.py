#!/usr/bin/env python3
"""Processes the PixelLab road tiles of task T-063 and builds the mock-up (no PixelLab call).

PixelLab's /create-tiles-pro returned flat "top-down" diamonds on a 128 x 128
canvas (a square diamond, 1:1). The game's ground is a 2:1 isometric diamond
(Visual style, Decisions; game/README.md: screen = (x - y, (x + y) / 2)), so a
top-down square seen at 45 degrees is squashed to half its height: every second
pixel row is kept (nearest row, no new colours, no new pixels) to give 128 x 64.

Commands (run from the repo root):
  python game/tools/build_road_tile.py process RAW.png OUT.png   # 128x128 -> 128x64
  python game/tools/build_road_tile.py fix TILE.png OUT.png      # no outline, brighter line (board, 2026-10-12)
  python game/tools/build_road_tile.py check TILE.png            # technical rules for a tile
  python game/tools/build_road_tile.py mockup TILE.png CAR_SHEET.png OUT.png

The mock-up draws the tile as a road 24 units wide (Level design, Decisions) running
along the world y axis, 2 x 2 units per tile (128 x 64 art pixels at the car art's
own density, 32 art pixels per unit), with the car on it. The game draws that art
at scale 0.5 (16 world pixels per unit), tile and car alike, so they keep this ratio.
"""
from __future__ import annotations

import argparse
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_sprite_rules as rules  # noqa: E402
from remove_car_shadow import write_png  # noqa: E402

T = (0, 0, 0, 0)
TILE_W, TILE_H = 128, 64
UNITS_PER_TILE = 2
ART_PX_PER_UNIT = 32


def squash_half(rows):
    """Keep every second row (the lower of each pair): a 1:1 diamond becomes a 2:1 diamond."""
    return [rows[2 * y + 1] for y in range(len(rows) // 2)]


def check_tile(rows, max_colors=30):
    """Technical rules for a diamond ground tile: list of (rule, ok, detail)."""
    h, w = len(rows), len(rows[0])
    px = [p for r in rows for p in r]
    out = [("size %dx%d" % (TILE_W, TILE_H), (w, h) == (TILE_W, TILE_H), "%dx%d" % (w, h))]
    semi = sum(1 for p in px if 0 < p[3] < 255)
    out.append(("no semi-transparent pixels", semi == 0, "%d semi-transparent" % semi))
    corners = [rows[0][0], rows[0][-1], rows[-1][0], rows[-1][-1]]
    out.append(("transparent background outside the diamond (corners)", all(c[3] == 0 for c in corners), str(corners)))
    stray = 0
    for y, r in enumerate(rows):
        for x, p in enumerate(r):
            d = abs(x + 0.5 - w / 2) / (w / 2) + abs(y + 0.5 - h / 2) / (h / 2)
            if d > 1.04 and p[3]:
                stray += 1
    out.append(("no opaque pixels outside the diamond", stray == 0, "%d stray" % stray))
    colors = {p[:3] for p in px if p[3] == 255}
    out.append(("about %d colours or fewer" % max_colors, len(colors) <= max_colors, "%d colours" % len(colors)))
    opaque = sum(1 for p in px if p[3] == 255)
    out.append(("diamond is filled (about half the canvas)", 0.4 * w * h <= opaque <= 0.6 * w * h,
                "%d opaque of %d" % (opaque, w * h)))
    return out


def footprint(x, y):
    """True if pixel (x, y) is inside the exact 2:1 diamond that tiles the plane with offsets (+-64, +32).

    Rows 0..31 are 4 * (y + 1) pixels wide, rows 32..62 are 4 * (63 - y), row 63 is empty,
    so a row of the plane is always covered exactly once (no gaps, no overlaps).
    """
    if y < 32:
        return 62 - 2 * y <= x <= 65 + 2 * y
    k = y - 32
    return 2 + 2 * k <= x <= 125 - 2 * k


def inner_distance(x, y):
    """Rough distance in pixels from the diamond's edge, measured along the row."""
    if y < 32:
        return min(x - (62 - 2 * y), (65 + 2 * y) - x)
    k = y - 32
    return min(x - (2 + 2 * k), (125 - 2 * k) - x)


def remove_outline(rows, band=4, dark=60):
    """Script fix (T-063, tile 1): no dotted dark outline along the diamond edge.

    1. Pixels outside the exact tiling footprint become transparent (this also removes the
       edge pixels that overlap or leave gaps between neighbouring tiles).
    2. Every dark pixel (luminance below `dark`) within `band` pixels of the edge is replaced by
       the colour of the pixel `band` pixels further in along its row (from the tile's own pixels);
       if that is dark too, it is looked for further in, then by the tile's usual asphalt colour.
    """
    lum = lambda p: 0.3 * p[0] + 0.59 * p[1] + 0.11 * p[2]
    h, w = len(rows), len(rows[0])
    out = [[p if footprint(x, y) else T for x, p in enumerate(r)] for y, r in enumerate(rows)]
    asphalt = Counter(p for r in out for p in r if p[3] and 30 < lum(p) < 60).most_common(1)[0][0]
    for y in range(h):
        for x in range(w):
            p = out[y][x]
            if not p[3] or lum(p) >= dark or inner_distance(x, y) >= band:
                continue
            step = 1 if x < w / 2 else -1
            new = asphalt
            for d in (band, band + 2, band + 4, band + 6):
                q = rows[y][x + step * d] if 0 <= x + step * d < w else T
                if q[3] and lum(q) >= dark:
                    new = q
                    break
            out[y][x] = new
    # holes inside the footprint (the raw tile had a few transparent pixels there): the colour of the
    # nearest opaque pixel in the same row
    for y in range(h):
        for x in range(w):
            if footprint(x, y) and not out[y][x][3]:
                for d in range(1, w):
                    cand = [out[y][x + s] for s in (-d, d) if 0 <= x + s < w and out[y][x + s][3]]
                    if cand:
                        out[y][x] = cand[0]
                        break
    return out


def brighten_line(rows, threshold=100):
    """Script fix: every line pixel (luminance at least `threshold`) becomes the tile's own brightest white."""
    lum = lambda p: 0.3 * p[0] + 0.59 * p[1] + 0.11 * p[2]
    white = max((p for r in rows for p in r if p[3]), key=lum)
    return [[white if p[3] and lum(p) >= threshold else p for p in r] for r in rows]


def tiling_report(rows):
    """Tiles the diamond on the lattice and counts gaps and overlaps in the middle: (gaps, overlaps)."""
    cov = Counter()
    for i in range(-3, 4):
        for j in range(-3, 4):
            ox, oy = (i - j) * 64, (i + j) * 32
            for y, r in enumerate(rows):
                for x, p in enumerate(r):
                    if p[3]:
                        cov[(ox + x, oy + y)] += 1
    cells = [(x, y) for x in range(-120, 120) for y in range(-40, 40)]
    gaps = sum(1 for c in cells if cov[c] == 0)
    overlaps = sum(1 for c in cells if cov[c] > 1)
    return gaps, overlaps


def paint_out_lines(rows):
    """Mock-up only: replace the near-white lane-line pixels by the tile's usual asphalt colour,
    to stand in for a plain asphalt tile that does not exist yet."""
    lum = lambda p: 0.3 * p[0] + 0.59 * p[1] + 0.11 * p[2]
    dark = Counter(p for r in rows for p in r if p[3] == 255 and lum(p) < 60)
    fill = dark.most_common(1)[0][0]
    return [[fill if p[3] == 255 and lum(p) > 85 else p for p in r] for r in rows]


def blit(canvas, rows, ox, oy):
    cw, ch = len(canvas[0]), len(canvas)
    for y, r in enumerate(rows):
        for x, p in enumerate(r):
            if p[3] and 0 <= ox + x < cw and 0 <= oy + y < ch:
                canvas[oy + y][ox + x] = p


def build_mockup(line_tile, car_frame, car_center, road_units=24, length_tiles=8, line_col=None, car_col=2):
    """The tile repeated as a road running along world y, with the car on it. Returns rows."""
    cols = road_units // UNITS_PER_TILE
    line_col = cols // 2 if line_col is None else line_col
    plain = paint_out_lines(line_tile)
    # screen position of tile (i across = world x, j along = world y): ((i - j) * 64, (i + j) * 32)
    pad = 24
    width = (cols + length_tiles) * (TILE_W // 2) + 2 * pad
    height = (cols + length_tiles) * (TILE_H // 2) + 2 * pad + 40
    bg = (10, 9, 22, 255)
    canvas = [[bg] * width for _ in range(height)]
    x0 = pad + length_tiles * (TILE_W // 2)
    y0 = pad
    for s in range(cols + length_tiles - 1):  # painter's order, back to front
        for i in range(cols):
            j = s - i
            if 0 <= j < length_tiles:
                tile = line_tile if i == line_col else plain
                blit(canvas, tile, x0 + (i - j) * (TILE_W // 2), y0 + (i + j) * (TILE_H // 2))
    # the car, heading along world +y (frame 4 of the car sheet, 90 degrees), in lane column car_col
    u = ART_PX_PER_UNIT
    wx = (car_col + 0.5) * UNITS_PER_TILE
    wy = (length_tiles / 2) * UNITS_PER_TILE
    sx = x0 + TILE_W // 2 + (wx - wy) * u
    sy = y0 + TILE_H // 2 + (wx + wy) * u / 2
    blit(canvas, car_frame, round(sx - car_center[0]), round(sy - car_center[1]))
    return canvas


def scale_nearest(rows, k):
    return [[p for p in r for _ in range(k)] for r in rows for _ in range(k)]


def load(path):
    w, h, rows = rules.decode_png(Path(path).read_bytes())
    return rows


def main(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("process")
    p.add_argument("raw")
    p.add_argument("out")
    c = sub.add_parser("check")
    c.add_argument("tile")
    c.add_argument("--max-colors", type=int, default=30)
    f = sub.add_parser("fix")
    f.add_argument("tile")
    f.add_argument("out")
    m = sub.add_parser("mockup")
    m.add_argument("tile")
    m.add_argument("car_sheet")
    m.add_argument("out")
    m.add_argument("--car-center", default="64.5,65.5")
    m.add_argument("--frame", type=int, default=4)
    m.add_argument("--line-col", type=int, default=None)
    a = ap.parse_args(argv)
    if a.cmd == "process":
        rows = squash_half(load(a.raw))
        write_png(a.out, rows)
        print("wrote", a.out, "%dx%d" % (len(rows[0]), len(rows)))
        return 0
    if a.cmd == "fix":
        rows = brighten_line(remove_outline(load(a.tile)))
        write_png(a.out, rows)
        print("wrote", a.out, "gaps, overlaps when tiled:", tiling_report(rows))
        return 0
    if a.cmd == "check":
        res = check_tile(load(a.tile), a.max_colors)
        for rule, ok, detail in res:
            print("%s  %s: %s" % ("PASS" if ok else "FAIL", rule, detail))
        return 0 if all(ok for _, ok, _ in res) else 1
    sheet = load(a.car_sheet)
    frame = [r[a.frame * 128:(a.frame + 1) * 128] for r in sheet]
    cx, cy = (float(v) for v in a.car_center.split(","))
    rows = build_mockup(load(a.tile), frame, (cx, cy), line_col=a.line_col)
    write_png(a.out, rows)
    print("wrote", a.out, "%dx%d" % (len(rows[0]), len(rows)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
