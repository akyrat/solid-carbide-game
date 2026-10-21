#!/usr/bin/env python3
"""Assembles the car-turning GIF of task T-102 from car_turn_gif_demo's images.

Usage, from the repo root:

    python game/tools/make_turn_gif.py IN_DIR OUT.gif [--up PX] [--size W H] [--scale N] [--ms MS]
                                       [--glob PATTERN] [--every N]

Reads IN_DIR/turn_000.png, turn_001.png, ... (viewport screenshots with the
camera on the car), crops W x H pixels around the screen centre, moved PX up
(for the car in the air, drawn above its ground point), enlarges by N with
nearest neighbour and writes a looping GIF, MS milliseconds per image.

Task T-219: --glob picks other images (default "turn_*.png"), for example the
"f*.png" frames of Godot's movie maker (--write-movie), and --every N keeps
every Nth of them (sorted by name).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def crop_box(w: int, h: int, cw: int, ch: int, up: int) -> tuple[int, int, int, int]:
    x0 = (w - cw) // 2
    y0 = max(0, (h - ch) // 2 - up)
    return x0, y0, x0 + cw, y0 + ch


def make(in_dir: Path, out: Path, size=(320, 240), up=0, scale=2, ms=80,
         pattern: str = "turn_*.png", every: int = 1) -> int:
    from PIL import Image
    paths = sorted(in_dir.glob(pattern))[::max(1, every)]
    if not paths:
        raise FileNotFoundError(f"no {pattern} in {in_dir}")
    frames = []
    for p in paths:
        im = Image.open(p).convert("RGB")
        im = im.crop(crop_box(im.width, im.height, size[0], size[1], up))
        frames.append(im.resize((size[0] * scale, size[1] * scale), Image.NEAREST))
    out.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=ms, loop=0, optimize=False)
    return len(frames)


def main(argv=None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("in_dir")
    p.add_argument("out")
    p.add_argument("--up", type=int, default=0)
    p.add_argument("--size", type=int, nargs=2, default=[320, 240])
    p.add_argument("--scale", type=int, default=2)
    p.add_argument("--ms", type=int, default=80)
    p.add_argument("--glob", default="turn_*.png")
    p.add_argument("--every", type=int, default=1)
    a = p.parse_args(argv)
    n = make(Path(a.in_dir), Path(a.out), tuple(a.size), a.up, a.scale, a.ms, a.glob, a.every)
    print(f"wrote {a.out} ({n} images)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
