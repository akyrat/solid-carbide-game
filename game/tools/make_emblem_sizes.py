#!/usr/bin/env python3
"""Make the 64 and 32 px Greenbull emblems (T-294) from the 128 px master, keeping its palette.

A plain resize blends colours and leaves semi-transparent edges, so each small pixel instead takes
one of the master's own colours:
  1. coverage: the small pixel is opaque only if at least half of its source block is opaque;
  2. colour: the most common opaque colour in the block, with small features weighted up so they
     survive (yellow eyes and nose ring, light green blaze and horns);
  3. closing the outline: a transparent pixel that touches (4-neighbour) a filled, non-outline
     pixel becomes outline, so the silhouette keeps a closed dark edge (at 32 the block vote
     opens gaps in the 2 px master outline; at 64 this step changes nothing).
No new colours, hard edges, no semi-transparent pixels.

Usage: make_emblem_sizes.py <master_128.png> <out_dir> [--prefix greenbull_emblem]
"""
import argparse
from collections import Counter
from pathlib import Path

from PIL import Image

CLEAR = (0, 0, 0, 0)
OUTLINE = (14, 22, 18, 255)
LIGHT = (104, 220, 96, 255)
YELLOW = (247, 208, 52, 255)

# Per-size colour weights (tuned by eye on the run 2 master, 2026-10-26).
WEIGHTS = {64: {YELLOW: 2.0, LIGHT: 1.2}, 32: {YELLOW: 3.0, LIGHT: 1.3}}


def downscale(master: Image.Image, size: int, weights: dict | None = None) -> Image.Image:
    master = master.convert("RGBA")
    f = master.width // size
    if f * size != master.width or master.width != master.height:
        raise ValueError("master must be square and a whole multiple of the size")
    weights = WEIGHTS.get(size, {}) if weights is None else weights
    px = master.load()
    out = Image.new("RGBA", (size, size), CLEAR)
    for y in range(size):
        for x in range(size):
            c = Counter(px[x * f + i, y * f + j] for i in range(f) for j in range(f))
            opaque = {k: n for k, n in c.items() if k[3]}
            if sum(opaque.values()) * 2 < f * f:
                continue
            best = max(sorted(opaque), key=lambda k: opaque[k] * weights.get(k, 1.0))
            out.putpixel((x, y), best)
    return out


def close_outline(im: Image.Image, outline=OUTLINE) -> int:
    """Add outline around filled non-outline pixels that touch transparency. Returns pixels added."""
    s = im.width
    px = im.load()
    add = []
    for y in range(im.height):
        for x in range(s):
            if px[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < s and 0 <= ny < im.height and px[nx, ny][3] and px[nx, ny] != outline:
                    add.append((x, y))
                    break
    for p in add:
        px[p] = outline
    return len(add)


def make_size(master: Image.Image, size: int) -> tuple[Image.Image, int]:
    small = downscale(master, size)
    added = close_outline(small)
    return small, added


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("master")
    ap.add_argument("out_dir")
    ap.add_argument("--prefix", default="greenbull_emblem")
    a = ap.parse_args(argv)
    master = Image.open(a.master).convert("RGBA")
    for size in (64, 32):
        small, added = make_size(master, size)
        path = Path(a.out_dir) / f"{a.prefix}_{size}.png"
        small.save(path)
        counts = sorted(((n, c) for n, c in small.getcolors(1 << 16) if c[3]), reverse=True)
        print(f"{path}: outline pixels added {added}; colours {counts}")


if __name__ == "__main__":
    main()
