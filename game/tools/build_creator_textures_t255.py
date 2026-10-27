#!/usr/bin/env python3
"""Builds the level creator's second texture set from T-255's PixelLab raws (task T-255).

The raws (art-archive/T-255/raw_*.png, 7 generations, never altered) are turned into
tileable 128 x 128 textures by free script fixes: the vignette (a bright centre and dark
corners, which would show as a repeating blob when tiled) is divided out with a wrapped
low-pass, colours are pulled to City concrete (cool blue-grey), the rooftop's big paving
is halved in scale, and the office wall is the window grid cropped out of the generated
building picture (a whole building cannot tile). Each is reduced to at most 30 colours.
Writes game/art/creator_pieces/t255/:  roof_top, carpark_top, wall_office, wall_garage,
ramp_top, ramp_side, parapet (.png).  The engine tiles them mirrored, so edges always meet;
`seam_score` (used by the tests) measures how much the tile would show if tiled plainly.

    python game/tools/build_creator_textures_t255.py build | check
Needs Pillow and numpy. Never calls PixelLab.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_elevation_sample_art as sample  # noqa: E402

ROOT = sample.ROOT
RAW = os.path.join(ROOT, "art-archive", "T-255")
OUT = os.path.join(ROOT, "game", "art", "creator_pieces", "t255")
NAMES = ["roof_top", "carpark_top", "wall_office", "wall_garage", "ramp_top", "ramp_side", "parapet"]


def load(name):
    return np.array(Image.open(os.path.join(RAW, "raw_%s.png" % name)).convert("RGB"), dtype=np.float32)


def lum(a):
    return a[..., 0] * 0.3 + a[..., 1] * 0.59 + a[..., 2] * 0.11


def lowpass(a, sigma):
    """Gaussian blur that wraps round the edges (tiles 3 x 3 first)."""
    h, w = a.shape[:2]
    big = np.tile(a, (3, 3, 1)).astype(np.uint8)
    img = Image.fromarray(big).filter(ImageFilter.GaussianBlur(sigma))
    return np.array(img, dtype=np.float32)[h:2 * h, w:2 * w]


def flatten(a, sigma=22, strength=1.0):
    """Divide out the slow brightness change (the vignette), keeping the mean."""
    low = lowpass(a, sigma)
    mean = low.mean(axis=(0, 1), keepdims=True)
    return np.clip(a * (1 + (mean / np.maximum(low, 1) - 1) * strength), 0, 255)


def concrete(a, amount, gain):
    return np.clip(sample.to_concrete(a, amount, 1.0) * gain, 0, 255)


def tile_mirror2(a):
    """A 64 x 64 piece mirrored into a 128 x 128 tile (it tiles with no seam)."""
    top = np.concatenate([a, a[:, ::-1]], axis=1)
    return np.concatenate([top, top[::-1]], axis=0)


def halve(a):
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).resize((64, 64), Image.BOX)
    return tile_mirror2(np.array(img, dtype=np.float32))


def office_wall(a):
    """The window grid of the generated building, 4 x 4 windows, tiled 2 x 2 (lifted, lighter)."""
    best = None
    for y0 in range(26, 40):
        for x0 in range(20, 36):
            c = a[y0:y0 + 68, x0:x0 + 64]
            seam = np.abs(c[:, 0] - c[:, -1]).mean() + np.abs(c[0] - c[-1]).mean()
            if best is None or seam < best[0]:
                best = (seam, c)
    c = np.array(Image.fromarray(best[1].astype(np.uint8)).resize((64, 64), Image.NEAREST), dtype=np.float32)
    t = np.tile(c, (2, 2, 1))
    l = lum(t)[..., None]
    lit = (t[..., 0] > t[..., 2] + 20)[..., None]   # warm windows stay as they are
    lifted = np.clip(t * 1.5 + 22, 0, 255)
    out = np.where(lit, t, lifted)
    return np.clip(out, 0, 255)


def build(out_dir=OUT):
    os.makedirs(out_dir, exist_ok=True)
    roof = concrete(halve(flatten(load("roof_top"), 18)), 0.6, 1.1)
    car = concrete(flatten(load("carpark_top"), 20), 0.5, 1.45)
    garage = concrete(flatten(load("wall_garage"), 24, 0.7), 0.7, 0.8)
    ramp = concrete(flatten(load("ramp_top"), 20), 0.4, 1.5)
    side = concrete(halve(load("ramp_side")), 0.5, 0.85)   # mirrored in 4: seamless when tiled plainly
    out = {"roof_top": roof, "carpark_top": car, "wall_office": office_wall(load("wall_office")),
           "wall_garage": garage, "ramp_top": ramp, "ramp_side": side}
    for name, arr in out.items():
        rgba = np.concatenate([np.clip(arr, 0, 255).astype(np.uint8), np.full(arr.shape[:2] + (1,), 255, np.uint8)], axis=-1)
        Image.fromarray(sample.reduce_colors(rgba), "RGBA").save(os.path.join(out_dir, name + ".png"))
    par = np.array(Image.open(os.path.join(RAW, "raw_parapet.png")).convert("RGBA").resize((128, 20), Image.NEAREST))
    par = sample.reduce_colors(par)
    Image.fromarray(par, "RGBA").save(os.path.join(out_dir, "parapet.png"))
    for n in NAMES:
        print("wrote", n)


def seam_score(path):
    """Mean colour jump across a plain (non-mirrored) wrap, against the mean jump between neighbours."""
    a = np.array(Image.open(path).convert("RGB"), dtype=np.float32)
    wrap = (np.abs(a[:, 0] - a[:, -1]).mean() + np.abs(a[0] - a[-1]).mean()) / 2
    inner = (np.abs(np.diff(a, axis=1)).mean() + np.abs(np.diff(a, axis=0)).mean()) / 2
    return wrap, inner


def check(out_dir=OUT):
    ok = True
    for n in NAMES:
        png = os.path.join(out_dir, n + ".png")
        if not os.path.exists(png):
            print("FAIL  %s: missing" % n)
            ok = False
            continue
        for rule, good, detail in sample.rules(png):
            if rule.startswith("transparent") and n != "parapet":
                continue
            print("%s  %s %s: %s" % ("PASS" if good else "FAIL", n, rule, detail))
            ok = ok and good
    return 0 if ok else 1


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    if cmd == "build":
        build()
    elif cmd == "check":
        sys.exit(check())
    else:
        sys.exit("usage: build_creator_textures_t255.py build|check")
