#!/usr/bin/env python3
"""Draws the first frame for the kaiju's explosion (T-613): a small hard-edged white and pale cyan burst in the middle
of a 224 x 224 transparent canvas, the start PixelLab's /animate-with-text-v3 grows into the big explosion. Free.

Run from the repo root: python game/tools/make_kaiju_explosion_seed.py [OUT.png]
"""
import sys
from pathlib import Path

from PIL import Image

SIZE = 224
WHITE = (235, 255, 255)
CYAN = (140, 235, 235)
PURPLE = (184, 46, 255)
OUTLINE = (24, 12, 40)


def seed():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = im.load()
    c = SIZE // 2
    for y in range(SIZE):
        for x in range(SIZE):
            d = ((x - c) ** 2 + (y - c) ** 2) ** 0.5
            if d <= 9:
                px[x, y] = (*WHITE, 255)
            elif d <= 15:
                px[x, y] = (*CYAN, 255)
            elif d <= 18:
                px[x, y] = (*PURPLE, 255)
            elif d <= 20:
                px[x, y] = (*OUTLINE, 255)
    return im


def main(argv):
    out = Path(argv[0]) if argv else Path(__file__).resolve().parents[2] / "art-archive" / "T-613" / "explosion_seed.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    seed().save(out)
    print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1:])
