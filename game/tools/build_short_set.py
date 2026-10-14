#!/usr/bin/env python3
"""Builds the full set of short buildings (T-129): 4 designs x 2 looks = 8 bodies in palette B, for free.

  python game/tools/build_short_set.py --raw art-archive/T-129/raw --out-dir art-archive/T-129/full --game-dir game/art/buildings

Designs (what the PixelLab results allowed; the c_facade_* results came back nearly black and are not used,
see the task's result notes): A = a_facade_left + a_facade_right, B = b_facade_left on both walls (the right one
mirrored), C = b_facade_left + d_facade_right, D = d_facade_left + d_facade_right. Look 2 of each design is the
mirrored body with the pink-led accent swapped to the pale-blue one. All shop signs are drawn by script
(abstract marks, no glyphs) over the PixelLab sign text. Roofs and props as in sample_short_building.py.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_short_buildings as sb  # noqa: E402
import build_skyscrapers as bs  # noqa: E402

H = 138                      # wall rows of designs B, C and D (A keeps its 134)
LILAC = (215, 180, 255)
KEEP_AC = [(16, 36), (36, 27), (52, 12), (68, 12), (82, 24), (82, 48), (72, 52), (60, 54), (46, 63), (44, 70), (35, 74), (16, 62)]
KEEP_RUBBLE = [(40, 26), (52, 19), (62, 20), (67, 29), (85, 37), (88, 43), (80, 52), (66, 58), (50, 59), (38, 52), (29, 42), (32, 33)]
KEEP_DISH = [(14, 52), (26, 6), (72, 6), (84, 30), (84, 66), (48, 80), (14, 66)]
# Scripted abstract signs painted over the PixelLab sign text (x0, y0, x1, y1 in the cleaned facade's px).
SIGNS = {
    "a_left": [(147, 86, 236, 130)], "a_right": [(139, 91, 224, 129)],
    "b_left": [(190, 96, 272, 112)],
    "d_left": [(249, 96, 274, 124), (300, 96, 346, 125)],
    "d_right": [(112, 100, 172, 118)],
}
ROOF_LOADS = {
    "a": ["tank", "ac", "rubble", "ac2", "rubble2", "tank2"],
    "b": ["sign", "antenna", "sign2", "antenna2"],
    "c": ["dish", "rubble", "dish2", "rubble2", "rubble3"],
    "d": ["tank", "antenna", "rubble", "tank2", "antenna2"],
}
PLACES = {
    "tank": (3.5, 4.0), "ac": (8.0, 3.5), "rubble": (5.5, 8.5), "ac2": (3.0, 8.5), "rubble2": (9.5, 8.0), "tank2": (9.0, 9.5),
    "sign": (4.0, 4.5), "antenna": (9.0, 3.5), "sign2": (8.5, 8.5), "antenna2": (3.5, 9.0),
    "dish": (3.5, 4.0), "dish2": (9.0, 9.0), "rubble3": (6.0, 6.0),
}
DESIGNS = {"a": ("a_left", "a_right"), "b": ("b_left", "b_left_mirror"), "c": ("b_left", "d_right"), "d": ("d_left", "d_right")}
RAW_NAME = {"a_left": "a_facade_left", "a_right": "a_facade_right", "b_left": "b_facade_left", "d_left": "d_facade_left", "d_right": "d_facade_right"}


def load(raw, name):
    return np.array(Image.open(Path(raw) / f"{RAW_NAME.get(name, name)}.png").convert("RGBA"))


def facade(raw, key, pal):
    """A cleaned, signed facade of the planned height."""
    mirror = key.endswith("_mirror")
    base = key[:-7] if mirror else key
    arr = load(raw, base)
    rows = 134 if base.startswith("a_") else H
    if base == "d_left":   # the raw image starts with sky above the roofline: rebuild the top 24 rows from the wall below
        arr = arr.copy()
        arr[:24] = arr[24:48][::-1]
    f = sb.clean_facade(arr, pal, rows)
    if mirror:
        f = f[:, ::-1].copy()
    boxes = SIGNS.get(base, [])
    if mirror:
        boxes = [(f.shape[1] - b[2], b[1], f.shape[1] - b[0], b[3]) for b in boxes]
    for i, box in enumerate(boxes):
        sb.paint_sign(f, box, 129 + i + len(key), pal)
    return f


def build_all(raw, out_dir, game_dir=None):
    pal = bs.load_palette()
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    props = {
        "tank": sb.clean_prop(load(raw, "a_prop_tank"), pal),
        "ac": sb.clean_prop(load(raw, "a_prop_ac"), pal, polygon=KEEP_AC),
        "rubble": sb.clean_prop(load(raw, "a_prop_rubble"), pal, polygon=KEEP_RUBBLE, drop=LILAC),
        "sign": sb.clean_prop(load(raw, "b_prop_signboard"), pal),
        "antenna": sb.clean_prop(load(raw, "b_prop_antenna"), pal),
        "dish": sb.clean_prop(load(raw, "c_prop_dish"), pal, polygon=KEEP_DISH),
    }
    for n, a in props.items():
        bs.to_img(a).save(out / f"prop_{n}_clean.png")
    flip = lambda x: x[:, ::-1].copy()  # noqa: E731
    bodies, record = [], {}
    for d, (lk, rk) in DESIGNS.items():
        fl, fr = facade(raw, lk, pal), facade(raw, rk, pal)
        for k, name in enumerate(ROOF_LOADS[d]):
            pass
        placed = []
        for name in ROOF_LOADS[d]:
            base = name.rstrip("23")
            if base == "rubble" and name.endswith("3"):
                spr = props["rubble"]
            else:
                spr = props[base]
            if name.endswith("2"):
                spr = flip(spr)
            placed.append((spr, PLACES[name]))
        old = sb.build_body(fl, fr, pal, placed, seed=7 + ord(d), cracks=90 if d == "d" else 40)
        for look in (0, 1):
            arr = old
            if look == 1:
                arr = bs.recolor_pink_cyan(old)
                arr = arr[:, ::-1].copy()
            b = sb.recolor_b(arr)
            idx = len(bodies)
            bodies.append(b)
            bs.to_img(b).save(out / f"short_{idx}_design_{d}_look_{look}.png")
            record[f"short_{idx}"] = {"design": d, "look": look, "size": [b.shape[1], b.shape[0]], **bs.sprite_rules(b)}
            if game_dir:
                bs.to_img(b).save(Path(game_dir) / f"short_body_{idx}.png")
    (out / "full_record.json").write_text(json.dumps(record, indent=1))
    return bodies, record


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default="art-archive/T-129/raw")
    ap.add_argument("--out-dir", default="art-archive/T-129/full")
    ap.add_argument("--game-dir", default=None)
    a = ap.parse_args(argv)
    _, rec = build_all(a.raw, a.out_dir, a.game_dir)
    bad = {k: v for k, v in rec.items() if v["semi_transparent"] or not v["colors_ok"] or not v["red_ok"]}
    print(json.dumps({k: (v["colors"], v["size"]) for k, v in rec.items()}), "failing:", bad or "none")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
