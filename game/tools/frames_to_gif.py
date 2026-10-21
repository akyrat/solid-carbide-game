#!/usr/bin/env python3
"""Turns a folder of numbered PNG frames (Godot --write-movie) into a GIF, cropped to the middle of the screen (task T-070)."""
import argparse
from pathlib import Path

from PIL import Image


def frames_to_gif(folder, out, fps=15, skip=2, scale=1.0, crop=0.85):
    files = sorted(Path(folder).glob("*.png"))[::skip]
    if not files:
        raise SystemExit("no frames in %s" % folder)
    ims = []
    for f in files:
        im = Image.open(f).convert("RGB")
        w, h = im.size
        cw, ch = int(w * crop), int(h * crop)
        im = im.crop(((w - cw) // 2, (h - ch) // 2, (w + cw) // 2, (h + ch) // 2))
        if scale != 1.0:
            im = im.resize((int(im.width * scale), int(im.height * scale)), Image.NEAREST)
        ims.append(im.quantize(colors=128, method=Image.MEDIANCUT, dither=Image.NONE))
    ims[0].save(out, save_all=True, append_images=ims[1:], duration=int(1000 / fps), loop=0, optimize=False)
    return len(ims)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("folder")
    ap.add_argument("out")
    ap.add_argument("--fps", type=int, default=15)
    ap.add_argument("--skip", type=int, default=2)
    ap.add_argument("--scale", type=float, default=1.0)
    ap.add_argument("--crop", type=float, default=0.85)
    a = ap.parse_args()
    print(frames_to_gif(a.folder, a.out, a.fps, a.skip, a.scale, a.crop), "frames")
