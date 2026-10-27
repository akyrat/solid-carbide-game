#!/usr/bin/env python3
"""Prints the opaque colours of a PNG with their pixel counts, most used first (T-303, a helper for recolours).

  python game/tools/palette_dump.py <png> [<png> ...]
"""
import colorsys
import sys
from collections import Counter

from PIL import Image


def palette(path):
    im = Image.open(path).convert("RGBA")
    return Counter(p[:3] for p in im.getdata() if p[3] == 255).most_common()


def main(paths):
    for path in paths:
        cols = palette(path)
        print("%s: %d colours" % (path, len(cols)))
        for c, n in cols:
            h, s, v = colorsys.rgb_to_hsv(*(x / 255.0 for x in c))
            print("  %-16s %6d  hue %3d sat %.2f val %.2f" % (c, n, round(h * 360), s, v))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
