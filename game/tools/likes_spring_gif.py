#!/usr/bin/env python3
"""Turns a folder of numbered PNG frames (Godot --write-movie) into a GIF of
the bottom centre of the screen (the likes bar and what sits on it), for the
likes bar's spring (task T-273). Every frame is kept (30 fps in, 30 fps out)
so the spring's 0.25 s shows.

Usage: python game/tools/likes_spring_gif.py <frames folder> <out.gif> [--scale N]
"""
import argparse
from pathlib import Path

from PIL import Image


def crop_bottom(im: Image.Image) -> Image.Image:
    """The bottom centre: the combo counter, the likes row and the 64 px bar."""
    w, h = im.size
    box_h = min(190, h)
    return im.crop((w // 4 - 16, h - box_h, w - w // 4 + 16, h))


def build(folder, out, fps=30, scale=1, colors=64) -> int:
    files = sorted(Path(folder).glob("*.png"))
    if not files:
        raise SystemExit("no frames in %s" % folder)
    ims = []
    for f in files:
        im = crop_bottom(Image.open(f).convert("RGB"))
        if scale != 1:
            im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
        ims.append(im)
    ims = [im.quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.NONE) for im in ims]
    ims[0].save(out, save_all=True, append_images=ims[1:], duration=int(1000 / fps), loop=0, optimize=False)
    return len(ims)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("folder")
    ap.add_argument("out")
    ap.add_argument("--scale", type=int, default=1)
    a = ap.parse_args()
    print(build(a.folder, a.out, scale=a.scale), "frames")
