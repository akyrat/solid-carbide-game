#!/usr/bin/env python3
"""Free check for T-064 round 2: at the real camera zoom, does a tall skyscraper wall's top
leave the screen near the car? Units: a slot is 15 x 15, a block 2 x 2 slots (30 x 30) with
10-unit roads (the map's pitch is 40); footprint 12 x 12 centred in its slot. Art px: 1 unit
along x or y = (32, 16), 1 unit up = 32. The window is 1152 x 648; the camera shows
2 x size units top to bottom in the flat world, i.e. 2 x size x 32 art px in height.

  python game/tools/zoom_check_skyscrapers.py [--out art-archive/T-064/round2/zoom_mockup.png]
"""
import argparse
import itertools
import sys

from PIL import Image, ImageDraw

PITCH, BLOCK, SLOT, FOOT = 40.0, 30.0, 15.0, 12.0
WIN_W, WIN_H = 1152, 648


def iso(ux, uy, up=0.0):
    return ((ux - uy) * 32.0, (ux + uy) * 16.0 - up * 32.0)


def footprints(xmin, xmax, ymin, ymax):
    """All skyscraper footprints (x0, y0, x1, y1) of blocks near the area."""
    out = []
    for bi in range(int(xmin // PITCH) - 1, int(xmax // PITCH) + 2):
        for bj in range(int(ymin // PITCH) - 1, int(ymax // PITCH) + 2):
            for si, sj in itertools.product((0, 1), (0, 1)):
                x0 = bi * PITCH + si * SLOT + (SLOT - FOOT) / 2
                y0 = bj * PITCH + sj * SLOT + (SLOT - FOOT) / 2
                out.append((x0, y0, x0 + FOOT, y0 + FOOT))
    return out


def silhouette(fp, h):
    x0, y0, x1, y1 = fp
    return [iso(x0, y1), iso(x1, y1), iso(x1, y0), iso(x1, y0, h), iso(x0, y0, h), iso(x0, y1, h)]


def point_in_poly(p, poly):
    x, y = p
    inside = False
    for (ax, ay), (bx, by) in zip(poly, poly[1:] + poly[:1]):
        if (ay > y) != (by > y) and x < ax + (y - ay) * (bx - ax) / (by - ay):
            inside = not inside
    return inside


def top_edge_y(fp, h, x):
    """Screen y of the wall's upper outline (back corner side of the top) at screen x."""
    x0, y0, x1, y1 = fp
    left, back, right = iso(x0, y1, h), iso(x0, y0, h), iso(x1, y0, h)
    a, b = (left, back) if x <= back[0] else (back, right)
    return a[1] + (b[1] - a[1]) * ((x - a[0]) / (b[0] - a[0]))


def stats(h, size, step=2.0):
    """Over every car position on the roads: how often the car is hidden behind a skyscraper, the
    median height of the NEAREST hiding wall's top above the car (as a share of the half screen
    height; over 1 means off the top of the screen), and the share of positions where it is off screen."""
    half_h = size * 32.0
    fps = footprints(-PITCH * 2, 4 * PITCH, -PITCH * 2, 4 * PITCH)
    heights, total = [], 0
    for i in range(int(PITCH / step)):
        for j in range(int(PITCH / step)):
            cx, cy = BLOCK + i * step, BLOCK + j * step
            if (cx % PITCH) < BLOCK and (cy % PITCH) < BLOCK:
                continue  # the car never drives inside a block
            total += 1
            cam = iso(cx, cy)
            near = None
            for fp in fps:
                if abs(iso(fp[0], fp[1])[0] - cam[0]) > 1500 or abs(iso(fp[0], fp[1])[1] - cam[1]) > 2500:
                    continue
                if point_in_poly(cam, silhouette(fp, h)):
                    d = cam[1] - top_edge_y(fp, h, cam[0])
                    near = d if near is None else min(near, d)
            if near is not None:
                heights.append(near / half_h)
    heights.sort()
    med = heights[len(heights) // 2] if heights else float("nan")
    return total, len(heights), med, sum(1 for d in heights if d > 1.0)


def mockup(path, h=24, sizes=(11.6, 14.4, 17.0)):
    panels = []
    for size in sizes:
        half_h = size * 32.0
        half_w = half_h * WIN_W / WIN_H
        scale = 0.5 * (WIN_H / (2 * half_h)) * 2  # screen px per art px
        # a car just north-west of a block corner, behind the front-left tower
        cx, cy = 21.0, 36.0
        cam = iso(cx, cy)
        img = Image.new("RGB", (WIN_W, WIN_H), (14, 12, 24))
        d = ImageDraw.Draw(img)
        def to_screen(p):
            return ((p[0] - cam[0]) / (2 * half_w) * WIN_W + WIN_W / 2,
                    (p[1] - cam[1]) / (2 * half_h) * WIN_H + WIN_H / 2)
        fps = footprints(cx - 60, cx + 60, cy - 60, cy + 60)
        fps.sort(key=lambda f: f[2] + f[3])
        for fp in fps:
            poly = [to_screen(p) for p in silhouette(fp, h)]
            d.polygon(poly, fill=(40, 34, 78), outline=(120, 110, 190))
            x0, y0, x1, y1 = fp
            for a, b in ((iso(x0, y1), iso(x0, y1, h)), (iso(x1, y1), iso(x1, y1, h)), (iso(x1, y0), iso(x1, y0, h))):
                d.line([to_screen(a), to_screen(b)], fill=(120, 110, 190))
            tops = [to_screen(iso(x0, y1, h)), to_screen(iso(x0, y0, h)), to_screen(iso(x1, y0, h)), to_screen(iso(x1, y1, h))]
            d.line(tops[:3] + [tops[3], tops[0]], fill=(255, 220, 60), width=3)  # the top outline
        car = to_screen(cam)
        r = 96 / 2 * (WIN_H / (2 * half_h))
        d.rectangle([car[0] - r, car[1] - r / 3, car[0] + r, car[1] + r / 3], fill=(0, 230, 255))
        d.text((8, 8), f"zoom {size}  wall {h} units  (yellow = a wall top on screen)", fill=(255, 255, 255))
        panels.append(img.resize((WIN_W // 2, WIN_H // 2), Image.NEAREST))
    out = Image.new("RGB", (WIN_W // 2 * len(panels) + 8 * (len(panels) - 1), WIN_H // 2), (128, 128, 128))
    for k, p in enumerate(panels):
        out.paste(p, (k * (WIN_W // 2 + 8), 0))
    out.save(path)


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="art-archive/T-064/round2/zoom_mockup.png")
    ap.add_argument("--heights", type=float, nargs="+", default=[24, 34])
    a = ap.parse_args(argv)
    print("wall height / zoom: car hidden | median height of the nearest hiding wall's top above the car (1.0 = top of the screen) | share of hidden cases with the top off the screen")
    for h in a.heights:
        for size in (11.0, 11.6, 14.4, 17.0):
            t, c, med, off = stats(h, size)
            print(f"wall {h:>3.0f} units, zoom {size:>4}: hidden {100*c/t:5.1f}%   median top at {med:4.2f}   off screen {100*off/c:4.0f}%")
    mockup(a.out)
    print("wrote", a.out)


if __name__ == "__main__":
    sys.exit(main())
