#!/usr/bin/env python3
"""Inspect and clean a 32 x 32 power-up icon by script (T-587, the style loop's free fixes).

Free fixes applied before any paid regeneration (docs/working-with-the-board.md, "Art and money"):

- alpha cut: every pixel fully opaque or fully transparent (rule 1);
- stray pixels: opaque specks not connected (8-neighbour) to the main sprite are removed (rule 1,
  a transparent background);
- Greenbull's colours: pixels at or near Greenbull's yellow (247, 208, 52) or light green
  (104, 220, 96) are repainted orange-amber or blue-grey (rule 6: never on a power-up icon);
- colour count: a palette over the limit is reduced by merging the closest colours (rule 1);
- the result is written as an 8-bit RGBA PNG; the source is never overwritten.

Usage, from the repo root:

    python game/tools/fix_power_up_icon.py inspect <png> [--previews <dir>]
    python game/tools/fix_power_up_icon.py fix <in png> <out png> [--max-colors 30] [--keep-strays]
        [--recolor R,G,B=R,G,B ...]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

GREENBULL_YELLOW = (247, 208, 52)
GREENBULL_GREEN = (104, 220, 96)
# style_rules.py's "near" threshold for rule 6, so this script fixes what that check flags.
NEAR = 40
YELLOW_TO = (255, 150, 40)      # orange-amber: sparks stay orange, not yellow
GREEN_TO = (96, 140, 170)       # cool blue-grey

RGB = tuple[int, int, int]
RGBA = tuple[int, int, int, int]


def dist(a: RGB, b: RGB) -> int:
    return max(abs(a[0] - b[0]), abs(a[1] - b[1]), abs(a[2] - b[2]))


def near_greenbull(c: RGB) -> RGB | None:
    """The Greenbull colour this one is near (within NEAR on every channel), or None."""
    for g in (GREENBULL_YELLOW, GREENBULL_GREEN):
        if dist(c, g) <= NEAR:
            return g
    return None


def alpha_cut(im: Image.Image, threshold: int = 128) -> Image.Image:
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= threshold else (0, 0, 0, 0)
    return im


def components(im: Image.Image) -> list[set[tuple[int, int]]]:
    """8-connected groups of opaque pixels."""
    px = im.load()
    w, h = im.size
    seen: set[tuple[int, int]] = set()
    groups: list[set[tuple[int, int]]] = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0 or (x, y) in seen:
                continue
            group: set[tuple[int, int]] = set()
            stack = [(x, y)]
            seen.add((x, y))
            while stack:
                cx, cy = stack.pop()
                group.add((cx, cy))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and px[nx, ny][3] != 0:
                            seen.add((nx, ny))
                            stack.append((nx, ny))
            groups.append(group)
    return groups


def remove_strays(im: Image.Image, min_size: int = 3) -> int:
    """Clear opaque groups smaller than min_size pixels that are not the main sprite. Returns pixels cleared."""
    px = im.load()
    groups = components(im)
    if not groups:
        return 0
    largest = max(len(g) for g in groups)
    cleared = 0
    for g in groups:
        if len(g) < min_size and len(g) != largest:
            for x, y in g:
                px[x, y] = (0, 0, 0, 0)
                cleared += 1
    return cleared


def recolor_greenbull(im: Image.Image, yellow_to: RGB = YELLOW_TO, green_to: RGB = GREEN_TO) -> dict[RGB, RGB]:
    """Repaint every colour near Greenbull's yellow or light green. Returns the map applied."""
    px = im.load()
    w, h = im.size
    applied: dict[RGB, RGB] = {}
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            g_near = near_greenbull((r, g, b))
            if g_near is None:
                continue
            to = yellow_to if g_near == GREENBULL_YELLOW else green_to
            applied[(r, g, b)] = to
            px[x, y] = to + (255,)
    return applied


def recolor_map(im: Image.Image, mapping: dict[RGB, RGB]) -> int:
    """Replace exact colours. Returns pixels changed."""
    px = im.load()
    w, h = im.size
    n = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a and (r, g, b) in mapping:
                px[x, y] = mapping[(r, g, b)] + (255,)
                n += 1
    return n


def clear_pixels(im: Image.Image, points: list[tuple[int, int]]) -> int:
    px = im.load()
    n = 0
    for x, y in points:
        if px[x, y][3]:
            px[x, y] = (0, 0, 0, 0)
            n += 1
    return n


def trim_margin(im: Image.Image, margin: int, outline: RGB) -> int:
    """Clear the outer `margin` pixels and close the sprite with an outline where it was cut.

    An opaque pixel left next to a cleared one (4-neighbour) is painted the outline colour,
    unless it is already that dark. Returns pixels cleared.
    """
    if margin <= 0:
        return 0
    px = im.load()
    w, h = im.size
    cleared: set[tuple[int, int]] = set()
    for y in range(h):
        for x in range(w):
            if (x < margin or y < margin or x >= w - margin or y >= h - margin) and px[x, y][3]:
                px[x, y] = (0, 0, 0, 0)
                cleared.add((x, y))
    for x, y in cleared:
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] and (nx, ny) not in cleared:
                r, g, b, _ = px[nx, ny]
                if max(r, g, b) > 24:
                    px[nx, ny] = outline + (255,)
    return len(cleared)


def palette(im: Image.Image) -> dict[RGB, int]:
    counts: dict[RGB, int] = {}
    for r, g, b, a in im.getdata():
        if a:
            counts[(r, g, b)] = counts.get((r, g, b), 0) + 1
    return counts


def reduce_colors(im: Image.Image, max_colors: int) -> int:
    """Merge the closest colour pairs (the rarer into the commoner) until at most max_colors. Returns merges."""
    merges = 0
    while True:
        counts = palette(im)
        if len(counts) <= max_colors:
            return merges
        cols = list(counts)
        best = None
        for i, a in enumerate(cols):
            for b in cols[i + 1:]:
                d = sum((a[k] - b[k]) ** 2 for k in range(3))
                if best is None or d < best[0]:
                    best = (d, a, b)
        _, a, b = best
        rare, common = (a, b) if counts[a] <= counts[b] else (b, a)
        recolor_map(im, {rare: common})
        merges += 1


def inspect(path: Path, previews: Path | None) -> dict:
    with Image.open(path) as opened:
        mode = opened.mode
        im = opened.convert("RGBA")
    counts = palette(im)
    semi = sum(1 for p in im.getdata() if 0 < p[3] < 255)
    groups = components(im)
    strays = [g for g in groups if len(g) < 3 and len(g) != max(len(x) for x in groups)] if groups else []
    info = {
        "size": im.size,
        "colours": len(counts),
        "bbox": im.getbbox(),
        "semi_transparent": semi,
        "near_greenbull": sorted(c for c in counts if near_greenbull(c)),
        "stray_groups": [sorted(g) for g in strays],
        "mode": mode,
    }
    if previews is not None:
        previews.mkdir(parents=True, exist_ok=True)
        for bg, n in (((18, 16, 28), "dark"), ((235, 235, 235), "light")):
            b = Image.new("RGBA", im.size, bg + (255,))
            b.alpha_composite(im)
            b.resize((im.width * 8, im.height * 8), Image.NEAREST).save(previews / f"{path.stem}_prev_{n}.png")
    return info


def fix(src: Path, dst: Path, *, max_colors: int = 30, keep_strays: bool = False,
        recolors: dict[RGB, RGB] | None = None, clears: list[tuple[int, int]] | None = None,
        margin: int = 0, outline: RGB = (4, 3, 2)) -> dict:
    if dst.exists():
        raise FileExistsError(f"{dst} exists: never overwrite an earlier version")
    with Image.open(src) as opened:
        im = alpha_cut(opened)
    report: dict = {}
    if recolors:
        report["recolored_pixels"] = recolor_map(im, recolors)
    report["greenbull_repainted"] = {str(k): v for k, v in recolor_greenbull(im).items()}
    if clears:
        report["cleared"] = clear_pixels(im, clears)
    report["margin_cleared"] = trim_margin(im, margin, outline)
    if not keep_strays:
        report["strays_cleared"] = remove_strays(im)
    report["merges"] = reduce_colors(im, max_colors)
    report["colours"] = len(palette(im))
    dst.parent.mkdir(parents=True, exist_ok=True)
    im.save(dst, "PNG")   # Pillow writes an RGBA image as 8-bit RGBA
    return report


def parse_rgb(text: str) -> RGB:
    parts = [int(p) for p in text.split(",")]
    if len(parts) != 3:
        raise argparse.ArgumentTypeError(f"not R,G,B: {text}")
    return (parts[0], parts[1], parts[2])


def parse_point(text: str) -> tuple[int, int]:
    parts = [int(p) for p in text.split(",")]
    if len(parts) != 2:
        raise argparse.ArgumentTypeError(f"not X,Y: {text}")
    return (parts[0], parts[1])


def parse_recolor(text: str) -> tuple[RGB, RGB]:
    a, _, b = text.partition("=")
    return parse_rgb(a), parse_rgb(b)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    i = sub.add_parser("inspect")
    i.add_argument("png", type=Path)
    i.add_argument("--previews", type=Path, help="write 8x previews on dark and light backgrounds here")
    f = sub.add_parser("fix")
    f.add_argument("src", type=Path)
    f.add_argument("dst", type=Path)
    f.add_argument("--max-colors", type=int, default=30)
    f.add_argument("--keep-strays", action="store_true")
    f.add_argument("--recolor", type=parse_recolor, action="append", default=[], metavar="R,G,B=R,G,B")
    f.add_argument("--clear", type=parse_point, action="append", default=[], metavar="X,Y",
                   help="make this pixel transparent")
    f.add_argument("--margin", type=int, default=0,
                   help="clear the outer N pixels and close the cut with the outline colour")
    f.add_argument("--outline", type=parse_rgb, default=(4, 3, 2), metavar="R,G,B")
    args = p.parse_args(argv)
    if args.cmd == "inspect":
        print(inspect(args.png, args.previews))
        return 0
    print(fix(args.src, args.dst, max_colors=args.max_colors, keep_strays=args.keep_strays,
              recolors=dict(args.recolor), clears=args.clear, margin=args.margin, outline=args.outline))
    return 0


if __name__ == "__main__":
    sys.exit(main())
