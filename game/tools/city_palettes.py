#!/usr/bin/env python3
"""Free recolouring of the round-2 sample into three candidate city palettes (T-064 quick tuning).

The board: the city must not share the boulders' navy / purple / magenta glow and should be less neon.
  A  concrete and sodium light: warm greys and beige, warm yellow-orange lit windows, small muted signs
  B  steel and glass: cool blue-grey walls, pale white and pale blue windows, small amber accents
  C  muted neon: the current layout much less saturated, signs cyan and amber instead of magenta

Every source colour of the sample body / pavement is one of the 29 palette colours, so a recolour is a
colour map (no new shapes, no semi-transparent pixels). Neutral greys go through a brightness ramp; the
neon, blue and purple colours are mapped by name. Each result has at most 30 colours and no Redgull red.

  python game/tools/city_palettes.py --out-dir game/art/buildings
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_skyscrapers as bs  # noqa: E402

# Non-neutral source colours by role.
ROLES = {
    (255, 64, 200): "neon", (255, 200, 240): "neon_light", (170, 36, 168): "neon_dark", (96, 20, 104): "neon_dark2",
    (0, 229, 255): "cyan", (190, 255, 255): "cyan_light", (0, 150, 214): "cyan_dark", (20, 72, 140): "blue",
    (52, 28, 112): "purple", (100, 50, 190): "purple_mid", (160, 90, 255): "purple_light", (215, 180, 255): "lilac",
    (255, 255, 255): "white",
}

# Brightness ramp stops for the neutral greys: (luminance 0..1, rgb).
PALETTES = {
    "A": {
        "ramp": [(0.09, (27, 25, 22)), (0.22, (62, 56, 48)), (0.34, (112, 102, 88)), (0.55, (176, 162, 136))],
        "roles": {
            "neon": (222, 162, 56), "neon_light": (250, 210, 140), "neon_dark": (124, 116, 60), "neon_dark2": (92, 62, 36),
            "cyan": (200, 170, 100), "cyan_light": (236, 214, 160), "cyan_dark": (130, 120, 84), "blue": (104, 92, 76),
            "purple": (74, 56, 46), "purple_mid": (120, 108, 88), "purple_light": (196, 150, 100), "lilac": (214, 190, 150),
            "white": (255, 226, 160),
        },
    },
    "B": {
        "ramp": [(0.09, (20, 26, 36)), (0.22, (52, 64, 80)), (0.34, (96, 114, 134)), (0.55, (156, 176, 196))],
        "roles": {
            "neon": (255, 178, 60), "neon_light": (255, 214, 140), "neon_dark": (168, 150, 56), "neon_dark2": (90, 84, 44),
            "cyan": (170, 210, 240), "cyan_light": (214, 234, 250), "cyan_dark": (96, 140, 180), "blue": (56, 92, 128),
            "purple": (38, 52, 70), "purple_mid": (74, 96, 122), "purple_light": (130, 160, 190), "lilac": (190, 208, 224),
            "white": (240, 248, 255),
        },
    },
    "C": {
        "ramp": [(0.09, (28, 29, 34)), (0.22, (52, 54, 62)), (0.34, (94, 96, 104)), (0.55, (150, 152, 160))],
        "roles": {
            "neon": (226, 160, 70), "neon_light": (244, 214, 160), "neon_dark": (130, 122, 64), "neon_dark2": (96, 70, 44),
            "cyan": (86, 184, 184), "cyan_light": (176, 224, 224), "cyan_dark": (52, 118, 126), "blue": (56, 84, 104),
            "purple": (50, 50, 58), "purple_mid": (84, 82, 96), "purple_light": (150, 140, 150), "lilac": (196, 190, 196),
            "white": (232, 232, 226),
        },
    },
}


def lum(c):
    return sum(c) / 765.0


def ramp_color(stops, l):
    if l <= stops[0][0]:
        return stops[0][1]
    for (l0, c0), (l1, c1) in zip(stops, stops[1:]):
        if l <= l1:
            t = (l - l0) / (l1 - l0)
            return tuple(int(round(a + (b - a) * t)) for a, b in zip(c0, c1))
    return stops[-1][1]


def color_map(name, sources):
    p = PALETTES[name]
    out = {}
    for c in sources:
        out[c] = p["roles"][ROLES[c]] if c in ROLES else ramp_color(p["ramp"], lum(c))
    return out


def recolor(arr, name):
    srcs = {tuple(px[:3]) for px in arr.reshape(-1, 4).tolist() if px[3] == 255}
    m = color_map(name, srcs)
    out = arr.copy()
    for src, dst in m.items():
        sel = (arr[..., :3] == np.array(src)).all(axis=-1) & (arr[..., 3] == 255)
        out[sel, :3] = dst
    return out


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--out-dir", default="game/art/buildings")
    ap.add_argument("--preview-dir", default="art-archive/T-064/round2")
    a = ap.parse_args(argv)
    out = Path(a.out_dir)
    base = json.loads((out / "skyscrapers.json").read_text())
    src_bodies = [np.array(Image.open(out / f"sky_body_{i}.png").convert("RGBA")) for i in range(4)]
    src_pavs = {(si, sj): np.array(Image.open(out / f"sky_pavement_{si}{sj}.png").convert("RGBA")) for si, sj in ((0, 0), (1, 0), (0, 1), (1, 1))}
    palettes = {}
    report = {}
    for name in "ABC":
        bodies, pavs = [], []
        for i, b in enumerate(src_bodies):
            r = recolor(b, name)
            fn = f"city{name}_body_{i}.png"
            bs.to_img(r).save(out / fn)
            bodies.append(f"res://art/buildings/{fn}")
            report[fn] = bs.sprite_rules(r)
        for (si, sj), p in src_pavs.items():
            r = recolor(p, name)
            fn = f"city{name}_pavement_{si}{sj}.png"
            bs.to_img(r).save(out / fn)
            pavs.append(f"res://art/buildings/{fn}")
            report[fn] = bs.sprite_rules(r)
        palettes[name] = {"bodies": bodies, "pavements": pavs}
    base["palettes"] = palettes
    base["texture"] = palettes["A"]["bodies"][0]
    base["bodies"] = palettes["A"]["bodies"]
    base["pavements"] = palettes["A"]["pavements"]
    (out / "skyscrapers.json").write_text(json.dumps(base, indent=1))
    bad = {k: v for k, v in report.items() if v["semi_transparent"] or not v["colors_ok"] or not v["red_ok"]}
    print("palettes written; failing sprites:", bad or "none")
    print("max colours:", max(v["colors"] for v in report.values()))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
