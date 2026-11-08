#!/usr/bin/env python3
"""Print a region of a PNG as a grid of pixels, one short code per pixel (T-587).

    python game/tools/dump_pixels.py <png> [--box x0,y0,x1,y1] [--legend]

Transparent pixels print as '..'; opaque ones print a two-character index into the
image's palette, listed with --legend.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

CODES = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"


def dump(path: Path, box: tuple[int, int, int, int] | None, legend: bool) -> str:
    with Image.open(path) as opened:
        im = opened.convert("RGBA")
    x0, y0, x1, y1 = box or (0, 0, im.width, im.height)
    counts: dict[tuple[int, int, int], int] = {}
    for r, g, b, a in im.getdata():
        if a:
            counts[(r, g, b)] = counts.get((r, g, b), 0) + 1
    order = sorted(counts, key=lambda c: -counts[c])
    index = {c: i for i, c in enumerate(order)}
    px = im.load()
    lines = ["    " + " ".join(f"{x:2d}" for x in range(x0, x1))]
    for y in range(y0, y1):
        row = []
        for x in range(x0, x1):
            r, g, b, a = px[x, y]
            row.append(".." if a == 0 else f"{CODES[index[(r, g, b)] % len(CODES)]:>2}")
        lines.append(f"{y:2d}  " + " ".join(row))
    if legend:
        lines.append("")
        for c in order:
            lines.append(f"{CODES[index[c] % len(CODES)]:>2}  {c}  x{counts[c]}")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("png", type=Path)
    p.add_argument("--box", help="x0,y0,x1,y1 (x1 and y1 exclusive)")
    p.add_argument("--legend", action="store_true")
    args = p.parse_args(argv)
    box = tuple(int(v) for v in args.box.split(",")) if args.box else None
    print(dump(args.png, box, args.legend))   # type: ignore[arg-type]
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
