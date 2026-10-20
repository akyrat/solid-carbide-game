#!/usr/bin/env python3
"""Makes a shadowless copy of the car's 16-direction sheet (task T-204; no PixelLab call).

Reads game/art/car/car_iso.png and car_iso.json, writes car_iso_noshadow.png
and car_iso_noshadow.json (same size, frames, centre and frame fields).

The drop shadow is drawn in the same near-black as the car's outline, windows
and tyres, so colour alone is not enough. Per frame, a pixel is made fully
transparent only when ALL of these hold:
  1. it is one of the near-black colours (SHADOW_COLOURS), fully opaque;
  2. it is connected (4-neighbours, through near-black pixels only) to the
     transparent background, so it lies outside the car's silhouette (the
     near-black of windows and tyres is enclosed by lighter car pixels);
  3. it lies outside the convex hull of the frame's car pixels that are not
     near-black (the body's own dark panels, sills and tyre treads lie inside
     it; the shadow sticks out below and beside it);
  4. it is more than OUTLINE_REACH steps (4-neighbour, through near-black
     pixels) away from the nearest car pixel that is not near-black, so the
     thin outline hugging the body stays and only the wide shadow goes.
Every other pixel is copied unchanged; nothing is added, so no new colours.

Commands (run from the repo root):
  python game/tools/build_car_noshadow.py            # build
  python game/tools/build_car_noshadow.py --src A.png --dst B.png
Running it twice gives byte-identical files.
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
import zlib
from collections import deque
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent
SRC_PNG = GAME / "art" / "car" / "car_iso.png"
DST_PNG = GAME / "art" / "car" / "car_iso_noshadow.png"

SHADOW_COLOURS = {(6, 2, 27), (10, 4, 31), (12, 10, 33), (6, 9, 24)}
OUTLINE_REACH = 1
NEIGHBOURS = ((1, 0), (-1, 0), (0, 1), (0, -1))


def read_png(path):
    """Returns (width, height, rows of RGBA tuples) for an 8-bit RGBA PNG."""
    from PIL import Image
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = list(im.getdata())
    return w, h, [px[y * w:(y + 1) * w] for y in range(h)]


def write_png(path, rows):
    """Writes RGBA rows with a fixed encoder, so reruns are byte-identical."""
    h, w = len(rows), len(rows[0])
    raw = b"".join(b"\x00" + b"".join(bytes(p) for p in r) for r in rows)

    def chunk(t, b):
        return struct.pack(">I", len(b)) + t + b + struct.pack(">I", zlib.crc32(t + b))

    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def shadow_pixels(rows, x0, x1, reach=OUTLINE_REACH):
    """Set of (x, y) shadow pixels in the frame whose columns are x0..x1-1."""
    h = len(rows)

    def dark(x, y):
        p = rows[y][x]
        return p[3] == 255 and tuple(p[:3]) in SHADOW_COLOURS

    def inside(x, y):
        return x0 <= x < x1 and 0 <= y < h

    # 2. near-black pixels connected to the transparent background
    outside, queue = set(), deque()
    for y in range(h):
        for x in range(x0, x1):
            if dark(x, y) and any(inside(x + dx, y + dy) and rows[y + dy][x + dx][3] == 0
                                  for dx, dy in NEIGHBOURS):
                outside.add((x, y))
                queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        for dx, dy in NEIGHBOURS:
            n = (x + dx, y + dy)
            if inside(*n) and n not in outside and dark(*n):
                outside.add(n)
                queue.append(n)
    # 3. steps from the nearest opaque pixel that is not near-black
    dist, queue = {}, deque()
    for (x, y) in outside:
        if any(inside(x + dx, y + dy) and rows[y + dy][x + dx][3] == 255 and not dark(x + dx, y + dy)
               for dx, dy in NEIGHBOURS):
            dist[(x, y)] = 1
            queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        for dx, dy in NEIGHBOURS:
            n = (x + dx, y + dy)
            if n in outside and n not in dist:
                dist[n] = dist[(x, y)] + 1
                queue.append(n)
    # a near-black blob with no car pixel next to it at all is not reachable: treat as far (removed)
    hull = convex_hull([(x, y) for y in range(h) for x in range(x0, x1)
                        if rows[y][x][3] == 255 and not dark(x, y)])
    return {p for p in outside if dist.get(p, 10 ** 6) > reach and not in_hull(hull, p)}


def convex_hull(points):
    """Andrew's monotone chain; returns the hull's corners counter-clockwise."""
    pts = sorted(set(points))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def in_hull(hull, p):
    """True when p is inside or on the counter-clockwise convex polygon."""
    if len(hull) < 3:
        return p in hull
    for a, b in zip(hull, hull[1:] + hull[:1]):
        if (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0]) < 0:
            return False
    return True


def remove_shadow(rows, frame_width, reach=OUTLINE_REACH):
    gone = set()
    for x0 in range(0, len(rows[0]), frame_width):
        gone |= shadow_pixels(rows, x0, x0 + frame_width, reach)
    out = [[(0, 0, 0, 0) if (x, y) in gone else p for x, p in enumerate(r)] for y, r in enumerate(rows)]
    return out, gone


def build(src=SRC_PNG, dst=DST_PNG):
    rec = json.loads(Path(src).with_suffix(".json").read_text(encoding="utf-8"))
    _, _, rows = read_png(src)
    out, gone = remove_shadow(rows, rec["frame_width"])
    write_png(dst, out)
    rec["file"] = Path(dst).name
    rec["noshadow_note"] = ("made by game/tools/build_car_noshadow.py (task T-204) from car_iso.png: only drop-shadow "
                            "pixels outside the car's silhouette are made transparent; used only while the car is in the air")
    rec["noshadow_pixels_removed"] = len(gone)
    Path(dst).with_suffix(".json").write_text(json.dumps(rec, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return len(gone)


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=str(SRC_PNG))
    ap.add_argument("--dst", default=str(DST_PNG))
    a = ap.parse_args(argv)
    n = build(Path(a.src), Path(a.dst))
    print("made %d pixels transparent -> %s" % (n, a.dst))


if __name__ == "__main__":
    main()
