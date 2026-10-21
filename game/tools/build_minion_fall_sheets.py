#!/usr/bin/env python3
"""Builds the minion's falling sheets (T-227) from the PixelLab frames.

Free script fix first: every opaque colour of a raw frame is moved to the
nearest colour of the minion's walk sheets (game/art/minion/minion_<dir>.png),
so the fall uses the minion's own palette. Alpha is made 0 or 255. Output:
game/art/minion/minion_fall_<dir>.png, FRAMES frames of 48 x 48 in one row.
Run from the repo root: python game/tools/build_minion_fall_sheets.py [dir ...]
"""
import sys
from pathlib import Path

from PIL import Image

FRAME = 48
FRAMES = 8
ROOT = Path(__file__).resolve().parents[2]
MINION = ROOT / "game" / "art" / "minion"
# direction -> (raw folder under art-archive/T-227, file prefix)
SOURCES = {"se": ("fall_se", "minion_fall_se")}


def walk_palette():
    """The set of opaque RGB colours in the minion's walk sheets."""
    pal = set()
    for d in ("s", "se", "e", "ne", "n"):
        im = Image.open(MINION / f"minion_{d}.png").convert("RGBA")
        pal |= {p[:3] for p in im.getdata() if p[3] > 0}
    return sorted(pal)


def snap_frame(img, palette):
    """Alpha to 0/255 and every opaque colour to its nearest palette colour (RGB distance)."""
    img = img.convert("RGBA")
    cache = {}
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    px = out.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = img.getpixel((x, y))
            if a < 128:
                continue
            c = (r, g, b)
            if c not in cache:
                cache[c] = min(palette, key=lambda p: sum((p[i] - c[i]) ** 2 for i in range(3)))
            px[x, y] = (*cache[c], 255)
    return out


def build_sheet(frame_paths, palette):
    sheet = Image.new("RGBA", (FRAME * len(frame_paths), FRAME), (0, 0, 0, 0))
    for i, p in enumerate(frame_paths):
        f = Image.open(p)
        if f.size != (FRAME, FRAME):
            raise ValueError(f"{p} is {f.size}, expected {FRAME}x{FRAME}")
        sheet.paste(snap_frame(f, palette), (i * FRAME, 0))
    return sheet


def main(argv):
    palette = walk_palette()
    for d in argv or SOURCES:
        folder, prefix = SOURCES[d]
        src = ROOT / "art-archive" / "T-227" / folder
        sheet = build_sheet([src / f"{prefix}_{i}.png" for i in range(FRAMES)], palette)
        sheet.save(MINION / f"minion_fall_{d}.png")
        print("wrote", MINION / f"minion_fall_{d}.png")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
