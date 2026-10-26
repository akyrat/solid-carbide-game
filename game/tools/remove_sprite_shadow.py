#!/usr/bin/env python3
"""Removes a flat-coloured ground shadow from a sprite (no PixelLab call).

A pixel becomes transparent only when it has one of the given shadow colours AND is
connected (4-neighbours, through shadow colours only) to the transparent background.
Every other pixel is copied unchanged, so no new colours appear.

Usage: python remove_sprite_shadow.py IN.png OUT.png R,G,B [R,G,B ...]
"""
import sys
from PIL import Image


def shadow_pixels(im, colours):
    w, h = im.size
    px = im.load()
    cols = {tuple(c) for c in colours}
    is_sh = lambda x, y: px[x, y][3] == 255 and px[x, y][:3] in cols
    nb = ((1, 0), (-1, 0), (0, 1), (0, -1))
    seen, stack = set(), []
    for y in range(h):
        for x in range(w):
            if is_sh(x, y) and any(0 <= x + dx < w and 0 <= y + dy < h and px[x + dx, y + dy][3] == 0
                                   or not (0 <= x + dx < w and 0 <= y + dy < h) for dx, dy in nb):
                seen.add((x, y))
                stack.append((x, y))
    while stack:
        x, y = stack.pop()
        for dx, dy in nb:
            a, b = x + dx, y + dy
            if 0 <= a < w and 0 <= b < h and (a, b) not in seen and is_sh(a, b):
                seen.add((a, b))
                stack.append((a, b))
    return seen


def remove_shadow(im, colours):
    im = im.convert("RGBA")
    gone = shadow_pixels(im, colours)
    out = im.copy()
    for x, y in gone:
        out.putpixel((x, y), (0, 0, 0, 0))
    return out, len(gone)


def main(argv=None):
    a = sys.argv[1:] if argv is None else argv
    colours = [tuple(int(v) for v in s.split(",")) for s in a[2:]]
    out, n = remove_shadow(Image.open(a[0]), colours)
    out.save(a[1])
    print(f"removed {n} shadow pixels")


if __name__ == "__main__":
    main()
