#!/usr/bin/env python3
"""Builds the level creator's tileable piece textures and panel icons (task T-251).

The level creator's rooftops and ramps of any size are drawn in the engine
(elevation_platform_drawing.gd, textured mode) from tileable textures projected
onto each face. Until T-255 makes new ones, the textures are T-198's PixelLab
textures (art-archive/T-198/), with the same free colour fix the sample map's art
has (build_elevation_sample_art.py, load_textures: teal pulled to City concrete).

Writes game/art/creator_pieces/:
  roof_top.png    a rooftop's top            (128 x 128, opaque)
  wall.png        a rooftop's walls          (128 x 128, opaque, lit windows)
  ramp_top.png    a ramp's driving surface   (128 x 128, opaque, lane lines along v)
  ramp_side.png   a ramp's two side walls    (128 x 128, opaque, rooftop concrete)
  parapet.png     the low wall on a rooftop's back edges (128 x PARAPET_PX, alpha 0 or 255)
  icon_<entry>.png  one small piece per catalogue entry, for the side panel's buttons,
                  rendered by build_elevation_sample_art.render with the same textures.
Each is reduced to at most 30 colours with no semi-transparent pixels. Which file
is which face is a setting in game/art/creator_pieces/piece_style.tres (not here).

Usage (from the repo root):
    python game/tools/build_creator_piece_art.py build   # writes the files
    python game/tools/build_creator_piece_art.py check   # rules on the committed files
Needs Pillow and numpy.
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_elevation_sample_art as sample  # noqa: E402

ROOT = sample.ROOT
OUT = os.path.join(ROOT, "game", "art", "creator_pieces")
MAX_COLORS = sample.MAX_COLORS

TEXTURES = ["roof_top", "wall", "ramp_top", "ramp_side", "parapet"]

# The panel icons: one small piece per catalogue entry (units; a ramp climbing north, so its
# slope shows). Shapes only, for the buttons; the placed piece is drawn in the engine.
ICONS = {
    "rooftop-3": ("platform", {"id": "icon", "x": 0, "y": 0, "w": 12, "h": 12, "height": 3}),
    "rooftop-6": ("platform", {"id": "icon", "x": 0, "y": 0, "w": 12, "h": 12, "height": 6}),
    "ramp-0-3": ("ramp", {"id": "icon", "x": 0, "y": 0, "w": 10, "h": 12, "side": "south",
                          "bottom_height": 0, "top_height": 3}),
    "ramp-3-6": ("ramp", {"id": "icon", "x": 0, "y": 0, "w": 10, "h": 12, "side": "south",
                          "bottom_height": 3, "top_height": 6}),
    "ramp-0-6": ("ramp", {"id": "icon", "x": 0, "y": 0, "w": 10, "h": 24, "side": "south",
                          "bottom_height": 0, "top_height": 6}),
}


def icon_name(entry_id):
    return "icon_" + entry_id.replace("-", "_")


def opaque(arr):
    """An RGB float texture as RGBA uint8, fully opaque."""
    rgb = np.clip(arr, 0, 255).astype(np.uint8)
    return np.concatenate([rgb, np.full(rgb.shape[:2] + (1,), 255, np.uint8)], axis=-1)


def hard_alpha(arr):
    """RGBA with alpha cut to 0 or 255 (transparent pixels black)."""
    out = arr.copy()
    keep = out[..., 3] > 127
    out[..., 3] = np.where(keep, 255, 0)
    out[~keep] = (0, 0, 0, 0)
    return out


def textures(tex):
    """The five face textures (RGBA uint8) from build_elevation_sample_art.load_textures()."""
    return {
        "roof_top": opaque(tex["roof"]),
        "wall": opaque(tex["wall"]),
        "ramp_top": opaque(tex["ramp"]),
        "ramp_side": opaque(tex["roof"]),
        "parapet": hard_alpha(tex["parapet"]),
    }


def icon(entry_id, tex):
    """An entry's panel icon: its small piece rendered with the sample art's projection."""
    kind, piece = ICONS[entry_id]
    plats = [piece] if kind == "platform" else []
    ramps = [piece] if kind == "ramp" else []
    arr, origin, _ = sample.render(piece, kind, tex, plats, ramps, {})
    arr, _ = sample.crop(sample.reduce_colors(arr), origin)
    return arr


def build(out_dir=OUT):
    tex = sample.load_textures()
    os.makedirs(out_dir, exist_ok=True)
    for name, arr in textures(tex).items():
        arr = sample.reduce_colors(arr)
        Image.fromarray(arr, "RGBA").save(os.path.join(out_dir, name + ".png"))
        print(name, arr.shape[1], arr.shape[0])
    for entry_id in ICONS:
        arr = icon(entry_id, tex)
        Image.fromarray(arr, "RGBA").save(os.path.join(out_dir, icon_name(entry_id) + ".png"))
        print(icon_name(entry_id), arr.shape[1], arr.shape[0])


def rules(path, need_transparent_corners):
    out = sample.rules(path)
    if not need_transparent_corners:
        out = [r for r in out if not r[0].startswith("transparent background")]
    return out


def check(out_dir=OUT):
    ok = True
    names = [(n, n == "parapet") for n in TEXTURES] + [(icon_name(e), True) for e in ICONS]
    for name, corners in names:
        png = os.path.join(out_dir, name + ".png")
        if not os.path.exists(png):
            print("FAIL  %s: missing" % name)
            ok = False
            continue
        for rule, good, detail in rules(png, corners):
            print("%s  %s %s: %s" % ("PASS" if good else "FAIL", name, rule, detail))
            ok = ok and good
    return 0 if ok else 1


def main(argv):
    cmd = argv[1] if len(argv) > 1 else "build"
    if cmd in ("build", "--build"):
        build()
        return 0
    if cmd in ("check", "--check"):
        return check()
    sys.exit("usage: build_creator_piece_art.py build|check")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
