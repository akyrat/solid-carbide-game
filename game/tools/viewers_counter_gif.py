#!/usr/bin/env python3
"""Turns a folder of numbered PNG frames (Godot --write-movie) into a GIF of the
right half of the screen, from the car's trick popups at the centre down to the
live viewers counter at the bottom right (task T-336). Every frame is kept.

Usage: python game/tools/viewers_counter_gif.py <frames folder> <out.gif> [--fps 30] [--box x0,y0,x1,y1]
"""
import argparse
from pathlib import Path

from PIL import Image

# At 1152 x 648: the car and its popups (centre) to the counter (bottom right).
DEFAULT_BOX = (380, 180, 1152, 648)


def build(folder, out, fps=30, box=DEFAULT_BOX, colors=96) -> int:
    files = sorted(Path(folder).glob("*.png"))
    if not files:
        raise SystemExit("no frames in %s" % folder)
    ims = [Image.open(f).convert("RGB").crop(box) for f in files]
    ims = [im.quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.NONE) for im in ims]
    ims[0].save(out, save_all=True, append_images=ims[1:], duration=int(1000 / fps), loop=0, optimize=False)
    return len(ims)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("folder")
    ap.add_argument("out")
    ap.add_argument("--fps", type=int, default=30)
    ap.add_argument("--box", default=",".join(str(v) for v in DEFAULT_BOX))
    a = ap.parse_args()
    print(build(a.folder, a.out, fps=a.fps, box=tuple(int(v) for v in a.box.split(","))), "frames")
