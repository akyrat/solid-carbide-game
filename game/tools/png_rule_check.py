"""Check a sprite PNG against Visual style rule 1 and rule 6 before the style loop scores it (T-577).

    python game/tools/png_rule_check.py SPRITE.png [--size WxH] [--max-colours 30] [--diff OTHER.png]

Prints the size, mode, opaque colour count, half-transparent pixel count and whether any Greenbull colour
(Visual style, Content, "Rules", rule 6) is present; with --diff, how many pixels differ from OTHER.png.
Exits 1 when a check fails (wrong size, more than --max-colours colours, any half-transparent pixel, or a
Greenbull colour). Needs Pillow.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

GREENBULL = {(12, 76, 44), (104, 220, 96), (247, 208, 52)}


def check(path: Path, size: tuple[int, int] | None = None, max_colours: int = 30,
          diff: Path | None = None) -> tuple[dict, list[str]]:
    with Image.open(path) as src:
        im = src.convert("RGBA")
    px = list(im.getdata())
    opaque = [p[:3] for p in px if p[3] == 255]
    half = sum(1 for p in px if 0 < p[3] < 255)
    colours = set(opaque)
    report = {
        "size": im.size, "colours": len(colours), "half_alpha": half, "opaque": len(opaque),
        "greenbull": sorted(colours & GREENBULL),
    }
    problems = []
    if size is not None and im.size != size:
        problems.append(f"size {im.size} is not {size}")
    if len(colours) > max_colours:
        problems.append(f"{len(colours)} colours, more than {max_colours}")
    if half:
        problems.append(f"{half} half-transparent pixels")
    if report["greenbull"]:
        problems.append(f"Greenbull colours present: {report['greenbull']}")
    if diff is not None:
        with Image.open(diff) as other:
            o = list(other.convert("RGBA").getdata())
        report["diff"] = sum(1 for a, b in zip(px, o) if a != b) if len(o) == len(px) else None
    return report, problems


def parse_size(text: str) -> tuple[int, int]:
    w, h = text.lower().split("x")
    return int(w), int(h)


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("png")
    p.add_argument("--size", type=parse_size)
    p.add_argument("--max-colours", type=int, default=30)
    p.add_argument("--diff")
    p.add_argument("--palette", action="store_true", help="list the opaque colours with their pixel counts")
    args = p.parse_args(argv)
    report, problems = check(Path(args.png), args.size, args.max_colours, Path(args.diff) if args.diff else None)
    for k, v in report.items():
        print(f"{k}: {v}")
    if args.palette:
        with Image.open(args.png) as src:
            counts: dict[tuple[int, int, int], int] = {}
            for px in src.convert("RGBA").getdata():
                if px[3] == 255:
                    counts[px[:3]] = counts.get(px[:3], 0) + 1
        for colour, n in sorted(counts.items(), key=lambda kv: -kv[1]):
            print("  #%02x%02x%02x %d" % (*colour, n))
    for problem in problems:
        print("FAIL:", problem)
    print("OK" if not problems else f"{len(problems)} problem(s)")
    return 0 if not problems else 1


if __name__ == "__main__":
    sys.exit(main())
