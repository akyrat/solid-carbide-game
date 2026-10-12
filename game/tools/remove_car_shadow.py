#!/usr/bin/env python3
"""Makes a shadowless copy of the T-014 car sprite (no PixelLab call).

The shadow is drawn in the same darkest colour (6, 2, 27) as the windows, the
body side and the tyres, so colour alone is not enough. A pixel is made
transparent only when ALL of these hold:
  1. it is the darkest colour or one of its three near-black variants;
  2. it is connected (4-neighbours, through those colours only) to the
     transparent background;
  3. it lies below a hand-placed line (BOTTOM_EDGE) that follows the car's
     lower edge: under the bumper, under the sill, behind the rear wheel;
  4. it is outside the two wheel ellipses (so the tyres stay whole).
Every other pixel is copied unchanged.

Usage: python game/tools/remove_car_shadow.py IN.png OUT.png
"""
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import check_sprite_rules as c

DARK = (6, 2, 27)
# the shadow's dotted edge also uses a few near-black variants
SHADOW_COLORS = {DARK, (10, 4, 31), (12, 10, 33), (6, 9, 24)}
# (centre x, centre y, radius x, radius y) of the tyres, found by looking at the sprite
WHEELS = [(61.7, 94.8, 7.5, 10.5), (107.5, 66.3, 8.0, 10.5)]


# The car's lower edge as (x, y) sprite points, read off the enlarged sprite.
BOTTOM_EDGE = [(5.0, 80.0), (50.0, 97.0), (56.0, 97.0), (68.0, 86.0), (100.0, 71.5),
               (113.0, 62.0), (123.0, 57.0)]


def edge_y(x):
    pts = BOTTOM_EDGE
    if x <= pts[0][0]:
        return pts[0][1]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        if x <= x1:
            return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return pts[-1][1]


def in_wheel(x, y):
    return any(((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0 for cx, cy, rx, ry in WHEELS)


def shadow_pixels(rows):
    h, w = len(rows), len(rows[0])
    is_dark = lambda x, y: rows[y][x][3] == 255 and rows[y][x][:3] in SHADOW_COLORS
    nb = ((1, 0), (-1, 0), (0, 1), (0, -1))
    seen, stack = set(), []
    for y in range(h):
        for x in range(w):
            if is_dark(x, y) and (x, y) not in seen and any(
                    0 <= x + dx < w and 0 <= y + dy < h and rows[y + dy][x + dx][3] == 0
                    for dx, dy in nb):
                seen.add((x, y))
                stack.append((x, y))
    while stack:
        x, y = stack.pop()
        for dx, dy in nb:
            a, b = x + dx, y + dy
            if 0 <= a < w and 0 <= b < h and (a, b) not in seen and is_dark(a, b):
                seen.add((a, b))
                stack.append((a, b))
    return {(x, y) for x, y in seen
            if y > edge_y(x) and not in_wheel(x, y)}


def write_png(path, rows):
    h, w = len(rows), len(rows[0])
    raw = b"".join(b"\x00" + b"".join(bytes(p) for p in r) for r in rows)
    ch = lambda t, b: struct.pack(">I", len(b)) + t + b + struct.pack(">I", zlib.crc32(t + b))
    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + ch(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                           + ch(b"IDAT", zlib.compress(raw, 9)) + ch(b"IEND", b""))


def remove_shadow(rows):
    gone = shadow_pixels(rows)
    return [[(0, 0, 0, 0) if (x, y) in gone else p for x, p in enumerate(r)] for y, r in enumerate(rows)], gone


def main(argv=None):
    src, dst = (argv or sys.argv[1:])[:2]
    _, _, rows = c.decode_png(Path(src).read_bytes())
    out, gone = remove_shadow(rows)
    write_png(dst, out)
    print("made %d pixels transparent -> %s" % (len(gone), dst))


if __name__ == "__main__":
    main()
