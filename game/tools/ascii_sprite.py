"""Print a small sprite as a character map (one char per pixel) for planning script edits.

usage: python ascii_sprite.py <png>
'.' transparent; otherwise a letter per palette index (sorted by count), legend after.
"""
import sys
from collections import Counter

from PIL import Image


def char_map(im):
    im = im.convert("RGBA")
    cnt = Counter(p for p in im.getdata() if p[3])
    keys = [c for c, _ in cnt.most_common()]
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    idx = {c: alphabet[i % len(alphabet)] for i, c in enumerate(keys)}
    rows = []
    for y in range(im.height):
        rows.append("".join(idx[im.getpixel((x, y))] if im.getpixel((x, y))[3] else "."
                            for x in range(im.width)))
    return rows, idx


def main():
    rows, idx = char_map(Image.open(sys.argv[1]))
    for y, r in enumerate(rows):
        print(f"{y:2d} {r}")
    for c, ch in idx.items():
        print(ch, c[:3])


if __name__ == "__main__":
    main()
