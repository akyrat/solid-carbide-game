#!/usr/bin/env python3
"""Turns a folder of numbered PNG frames (Godot --write-movie) into a GIF of
the bottom centre of the screen (the likes bar and what sits on it), for the
likes bar's spring (task T-273). Every frame is kept (30 fps in, 30 fps out)
so the spring's 0.25 s shows. Since T-337, `--box X0 Y0 X1 Y1` crops any
rectangle instead (the sub goal square on the right edge).

Usage: python game/tools/likes_spring_gif.py <frames folder> <out.gif> [--scale N] [--box X0 Y0 X1 Y1]
"""
import argparse
from pathlib import Path

from PIL import Image


def crop_bottom(im: Image.Image) -> Image.Image:
    """The bottom centre: the combo counter, the likes row and the 64 px bar."""
    w, h = im.size
    box_h = min(190, h)
    return im.crop((w // 4 - 16, h - box_h, w - w // 4 + 16, h))


def crop_box(im: Image.Image, box) -> Image.Image:
    """The given rectangle (x0, y0, x1, y1), kept inside the frame."""
    w, h = im.size
    x0, y0, x1, y1 = box
    return im.crop((max(0, x0), max(0, y0), min(w, x1), min(h, y1)))


def build(folder, out, fps=30, scale=1, colors=64, box=None) -> int:
    files = sorted(Path(folder).glob("*.png"))
    if not files:
        raise SystemExit("no frames in %s" % folder)
    ims = []
    for f in files:
        im = Image.open(f).convert("RGB")
        im = crop_box(im, box) if box else crop_bottom(im)
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
    ap.add_argument("--box", type=int, nargs=4, default=None)
    a = ap.parse_args()
    print(build(a.folder, a.out, scale=a.scale, box=a.box), "frames")
