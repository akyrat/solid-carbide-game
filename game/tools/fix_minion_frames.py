#!/usr/bin/env python3
"""Free pixel fixes for the minion's generated walk frames (T-068).

PixelLab's animation sometimes loses the eye or leaves a stray bright pixel in
a frame. These helpers copy a small patch from a good frame, or recolour named
pixels, and never call PixelLab. Frames are PIL RGBA images.

Usage: python game/tools/fix_minion_frames.py IN_DIR OUT_DIR PREFIX DIRECTION
(DIRECTION is a key of FIXES; frames PREFIX_0.png .. PREFIX_7.png are read from IN_DIR).
"""
import sys
from pathlib import Path

from PIL import Image


def copy_patch(dst, src, box):
    """Copy the pixels of box (x0, y0, x1, y1; x1 and y1 included) from src onto dst."""
    x0, y0, x1, y1 = box
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            dst.putpixel((x, y), src.getpixel((x, y)))


def recolor(img, pixels, color):
    """Set the listed (x, y) pixels to color (r, g, b), keeping them opaque."""
    for xy in pixels:
        img.putpixel(xy, (*color, 255))


# direction -> list of ("eye", frame, from_frame, box) or ("recolor", frame, pixels, color)
FIXES = {
    "e": [
        ("eye", 4, 3, (36, 21, 40, 23)),
        ("eye", 5, 3, (36, 21, 40, 23)),
        ("recolor", 4, [(37, 27), (36, 28), (36, 29)], (86, 127, 4)),
    ],
}


def apply_fixes(frames, fixes):
    """Apply a FIXES list to a list of frames in place and return it."""
    for fx in fixes:
        if fx[0] == "eye":
            _, i, j, box = fx
            copy_patch(frames[i], frames[j], box)
        else:
            _, i, pixels, color = fx
            recolor(frames[i], pixels, color)
    return frames


def main(argv):
    in_dir, out_dir, prefix, direction = Path(argv[1]), Path(argv[2]), argv[3], argv[4]
    frames = [Image.open(in_dir / f"{prefix}_{i}.png").convert("RGBA") for i in range(8)]
    apply_fixes(frames, FIXES.get(direction, []))
    out_dir.mkdir(parents=True, exist_ok=True)
    for i, f in enumerate(frames):
        f.save(out_dir / f"{prefix}_{i}.png")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
