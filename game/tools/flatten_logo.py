#!/usr/bin/env python3
"""Flatten a logo PNG to one dark red (T-075): every visible pixel (alpha >= 128) becomes
DARK_RED, everything else transparent. Usage: flatten_logo.py <in.png> <out.png>"""
import sys
from PIL import Image

DARK_RED = (150, 24, 28, 255)


def flatten(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.putdata([DARK_RED if p[3] >= 128 else (0, 0, 0, 0) for p in im.getdata()])
    return out


if __name__ == "__main__":
    flatten(Image.open(sys.argv[1])).save(sys.argv[2])
