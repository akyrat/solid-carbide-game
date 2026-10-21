#!/usr/bin/env python3
"""Turns a folder of numbered PNG frames (Godot --write-movie) into a GIF, cropped to the middle of the screen (task T-070)."""
import argparse
from pathlib import Path

from PIL import Image


def frames_to_gif(folder, out, fps=15, skip=2, scale=1.0, crop=0.85, first=0, last=None, colors=128, shared=False):
    files = sorted(Path(folder).glob("*.png"))[first:last][::skip]
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
        ims.append(im)
    if shared:
        # One palette for the whole GIF, built from a strip of every few frames: smaller files.
        sample = ims[::max(1, len(ims) // 8)]
        strip = Image.new("RGB", (sample[0].width, sample[0].height * len(sample)))
        for i, im in enumerate(sample):
            strip.paste(im, (0, i * im.height))
        pal = strip.quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.NONE)
        ims = [im.quantize(palette=pal, dither=Image.NONE) for im in ims]
    else:
        ims = [im.quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.NONE) for im in ims]
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
    ap.add_argument("--first", type=int, default=0, help="first frame to use (T-217)")
    ap.add_argument("--last", type=int, default=None, help="stop before this frame (T-217)")
    ap.add_argument("--colors", type=int, default=128, help="palette size per frame (T-217)")
    ap.add_argument("--shared", action="store_true", help="one palette for all frames (T-217)")
    a = ap.parse_args()
    print(frames_to_gif(a.folder, a.out, a.fps, a.skip, a.scale, a.crop, a.first, a.last, a.colors, a.shared), "frames")
