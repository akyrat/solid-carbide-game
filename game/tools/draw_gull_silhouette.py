#!/usr/bin/env python3
"""Draw a one-colour seagull-head silhouette (side profile, facing right) by script (T-075).
Coordinates are on a 64 px grid and scale with --size. Free, no PixelLab.
Usage: draw_gull_silhouette.py <out.png> [--size 64]"""
import argparse
from PIL import Image, ImageDraw

DARK_RED = (150, 24, 28, 255)
SS = 8  # supersample, then threshold to hard pixels

HEAD_CIRCLE = (23, 26, 12)  # cx, cy, r
BEAK = [(26, 15), (33, 18), (46, 22), (58, 27), (61, 31), (61, 36), (58, 33), (56, 31), (46, 32), (34, 35)]
NECK = [(12, 30), (33, 33), (30, 54), (11, 56)]
EYE = [(25, 21), (33, 24), (33, 26), (26, 24)]  # angled slit under a brow, cut out


def draw(size: int = 64) -> Image.Image:
    k = size / 64 * SS
    big = Image.new("L", (size * SS, size * SS), 0)
    d = ImageDraw.Draw(big)
    cx, cy, r = HEAD_CIRCLE
    d.ellipse([(cx - r) * k, (cy - r) * k, (cx + r) * k, (cy + r) * k], fill=255)
    d.polygon([(x * k, y * k) for x, y in BEAK], fill=255)
    d.polygon([(x * k, y * k) for x, y in NECK], fill=255)
    d.polygon([(x * k, y * k) for x, y in EYE], fill=0)
    mask = big.resize((size, size), Image.BOX).point(lambda v: 255 if v >= 128 else 0)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(Image.new("RGBA", (size, size), DARK_RED), mask=mask)
    return out


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--size", type=int, default=64)
    a = ap.parse_args()
    draw(a.size).save(a.out)
