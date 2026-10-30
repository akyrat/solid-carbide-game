#!/usr/bin/env python3
"""Builds the level creator's final prop sprites from PixelLab generations (task T-256).

One PixelLab generation per prop (art-archive/T-256/raw/<name>_raw.png) is turned, by script and
for free, into the four rotations of game/data/level/props.json: the picture is cropped to its
content, its alpha is made 0 or 255, its colours are reduced to at most 30, any old-brand red is
pushed to orange, and a horizontal mirror stands for the other axis (east and west; the footprint
swaps there). North and south use the picture, east and west its mirror. Nothing is scaled up; a
sprite wider than its footprint's diamond (+ a small margin) is scaled down with nearest neighbour.
The anchor ("anchor_px") is the pixel that stands on the footprint's centre on the ground: the
horizontal middle of the sprite and `base_up` pixels above its lowest opaque row.

Files are written as game/art/props/<name>_<rotation>_art.png; the code-drawn placeholders
(build_prop_art.py, <name>_<rotation>.png) stay on disk. `build` writes the files and points the
"textures" of props.json at them (nothing else in props.json changes). `check` runs the rules.

Usage (from the repo root):
    python game/tools/build_prop_final_art.py build [--raw art-archive/T-256/raw]
    python game/tools/build_prop_final_art.py check
Needs Pillow and numpy.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)
REPO = os.path.dirname(GAME)
PROPS_JSON = os.path.join(GAME, "data", "level", "props.json")
OUT = os.path.join(GAME, "art", "props")
RAW = os.path.join(REPO, "art-archive", "T-256", "raw")
MAX_COLORS = 30
ROTATIONS = ["north", "east", "south", "west"]
RED_MIN, RED_OVER, RED_MAX_OTHER = 150, 70, 100
OUTLINE = (12, 12, 22)

# base_up: pixels from the lowest opaque row up to the footprint's centre on the ground.
# None = the footprint's own half diamond, (w + h) * 8 art pixels. flip: mirror the picture first
# (when the generation's long axis ran the wrong way). base_x: "bottom" = the middle of the lowest
# rows (a pole), otherwise the middle of the sprite.
SPECS = {
    "barrier": {"raw": "barrier", "base_up": None, "flip": True},
    "cones": {"raw": "cones", "base_up": None},
    "crates": {"raw": "crates", "base_up": None},
    "ac_unit": {"raw": "ac_unit", "base_up": None},
    "water_tank": {"raw": "water_tank", "base_up": None},
    "roof_vent": {"raw": "roof_vent", "base_up": None},
    "street_lamp": {"raw": "street_lamp", "base_up": 6, "base_x": "bottom"},
    # The generation shows the sign on a rooftop with a building: keep only the panel and its two
    # legs (polygons in raw pixels) and stand the anchor between the feet. Its long axis already
    # runs the way east and west need, so the mirror is north and south.
    "roof_sign": {"raw": "roof_sign", "base_up": None, "flip": True, "anchor_raw": [79, 150], "glyphs": True,
                  "keep": [[(19, 52), (121, 18), (133, 24), (133, 74), (60, 112), (47, 112), (19, 102)],
                           [(42, 100), (61, 100), (61, 166), (42, 166)],
                           [(97, 78), (115, 78), (115, 143), (97, 143)]]},
}


def sprite_name(prop_id, rotation):
    return "%s_%s_art" % (prop_id[len("prop-"):].replace("-", "_"), rotation)


def is_red(rgb):
    r, g, b = (int(v) for v in rgb)
    return r >= RED_MIN and max(g, b) <= RED_MAX_OTHER and r - max(g, b) >= RED_OVER


def clean(arr):
    """Alpha 0 or 255, red pushed to orange, at most MAX_COLORS colours."""
    arr = arr.copy()
    a = arr[..., 3] >= 128
    arr[..., 3] = np.where(a, 255, 0)
    arr[~a] = (0, 0, 0, 0)
    rgb = arr[..., :3].astype(int)
    red = a & (rgb[..., 0] >= RED_MIN) & (np.maximum(rgb[..., 1], rgb[..., 2]) <= RED_MAX_OTHER) \
        & (rgb[..., 0] - np.maximum(rgb[..., 1], rgb[..., 2]) >= RED_OVER)
    if red.any():
        r = rgb[red, 0]
        arr[red, 1] = np.clip(r * 0.6, 0, 255).astype(np.uint8)  # orange, not old-brand red
        arr[red, 2] = np.clip(r * 0.15, 0, 255).astype(np.uint8)
    colours = {tuple(c[:3]) for c in arr[a]}
    if len(colours) > MAX_COLORS:
        q = arr[..., :3].copy()
        q[~a] = q[a][0]
        q = np.array(Image.fromarray(q, "RGB").quantize(colors=MAX_COLORS, method=Image.MEDIANCUT,
                                                          dither=Image.NONE).convert("RGB"))
        arr[..., :3] = q
        arr[~a] = (0, 0, 0, 0)
    return arr


def apply_keep(arr, polygons):
    """Makes everything outside the polygons (raw pixel coordinates) transparent."""
    from PIL import ImageDraw
    m = Image.new("L", (arr.shape[1], arr.shape[0]), 0)
    d = ImageDraw.Draw(m)
    for p in polygons:
        d.polygon(p, fill=255)
    out = arr.copy()
    out[np.array(m) == 0] = (0, 0, 0, 0)
    return out


# T-256 (QA round 1): the generated marks were real Chinese characters, and the City brief wants
# Japanese-like marks that are not real words. The marks are painted over with the panel's colour
# and four made-up glyphs, drawn here from a few strokes (not characters of any script), replace them.
GLYPH_STROKES = [
    [((4, 0), (4, 23)), ((4, 6), (13, 6)), ((4, 16), (12, 23)), ((9, 10), (9, 15))],
    [((0, 4), (13, 4)), ((7, 4), (7, 23)), ((0, 23), (13, 17)), ((2, 12), (7, 12))],
    [((2, 0), (2, 12)), ((2, 12), (12, 12)), ((12, 12), (12, 23)), ((6, 18), (12, 18))],
    [((0, 0), (10, 10)), ((10, 10), (0, 23)), ((5, 12), (13, 12)), ((13, 0), (13, 8))],
]
GLYPH_CORE = (255, 205, 70, 255)
GLYPH_HALO = (230, 130, 40, 255)


def replace_marks(arr):
    """Paints over the amber marks on the sign's panel and draws the four made-up glyphs."""
    from PIL import ImageDraw
    out = arr.copy()
    rgb = out[..., :3].astype(int)
    yy, xx = np.mgrid[0:out.shape[0], 0:out.shape[1]]
    region = (xx >= 38) & (xx <= 128) & (yy >= 30) & (yy <= 100) & (out[..., 3] > 0)
    amber = region & (rgb[..., 0] > 150) & (rgb[..., 0] - rgb[..., 2] > 50)
    grown = amber.copy()
    for _ in range(2):
        g = grown.copy()
        g[1:, :] |= grown[:-1, :]
        g[:-1, :] |= grown[1:, :]
        g[:, 1:] |= grown[:, :-1]
        g[:, :-1] |= grown[:, 1:]
        grown = g & region
    panel = region & ~grown & (rgb.sum(axis=2) < 330)
    fill = np.median(out[panel][:, :3], axis=0).astype(np.uint8)
    out[grown] = tuple(int(v) for v in fill) + (255,)
    img = Image.fromarray(out, "RGBA")
    d = ImageDraw.Draw(img)

    def pt(u0, p):
        u = u0 + p[0]
        return (u, 76 - 0.35 * (u - 52) + p[1] - 12)

    for width, col in ((4, GLYPH_HALO), (2, GLYPH_CORE)):
        for i, strokes in enumerate(GLYPH_STROKES):
            u0 = 46 + i * 20
            for a, b in strokes:
                d.line([pt(u0, a), pt(u0, b)], fill=col, width=width)
    return np.array(img)


def crop(arr):
    ys, xs = np.nonzero(arr[..., 3] > 0)
    return arr[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def fit_width(arr, footprint):
    """Scale down (nearest) when wider than the footprint's diamond plus 12 px; never up."""
    limit = (footprint[0] + footprint[1]) * 32 + 12
    h, w = arr.shape[:2]
    if w <= limit:
        return arr, 1.0
    f = limit / float(w)
    im = Image.fromarray(arr, "RGBA").resize((limit, max(1, round(h * f))), Image.NEAREST)
    return np.array(im), f


def anchor_for(arr, footprint, spec):
    h, w = arr.shape[:2]
    a = arr[..., 3] > 0
    ys = np.nonzero(a.any(axis=1))[0]
    bottom = int(ys.max())
    up = spec["base_up"] if spec["base_up"] is not None else (footprint[0] + footprint[1]) * 8
    if spec.get("base_x") == "bottom":
        xs = np.nonzero(a[max(0, bottom - 5):bottom + 1].any(axis=0))[0]
        ax = int(round((xs.min() + xs.max()) / 2.0))
    else:
        ax = (w - 1) // 2
    return [ax, max(0, bottom - up)]


def make_rotations(arr, anchor):
    """{rotation: (array, anchor)}: north and south the picture, east and west its mirror."""
    h, w = arr.shape[:2]
    mir = arr[:, ::-1].copy()
    m_anchor = [w - 1 - anchor[0], anchor[1]]
    return {"north": (arr, anchor), "east": (mir, m_anchor), "south": (arr, anchor), "west": (mir, m_anchor)}


def build(raw_dir=RAW, out_dir=OUT, props_json=PROPS_JSON, write_json=True):
    with open(props_json, encoding="utf-8") as f:
        data = json.load(f)
    os.makedirs(out_dir, exist_ok=True)
    for prop in data["props"]:
        name = prop["id"][len("prop-"):].replace("-", "_")
        if name not in SPECS:
            continue  # T-398: a prop still on its placeholder (the cars, until T-399's art)
        spec = SPECS[name]
        raw = np.array(Image.open(os.path.join(raw_dir, spec["raw"] + "_raw.png")).convert("RGBA"))
        if spec.get("keep"):
            raw = apply_keep(raw, spec["keep"])
        if spec.get("glyphs"):
            raw = replace_marks(raw)
        arr = clean(raw)
        ys, xs = np.nonzero(arr[..., 3] > 0)
        ox, oy = int(xs.min()), int(ys.min())
        arr = crop(arr)
        if spec.get("flip"):
            arr = arr[:, ::-1].copy()
        arr, scale = fit_width(arr, prop["footprint_units"])
        arr = clean(arr)
        if spec.get("anchor_raw"):
            ax, ay = spec["anchor_raw"][0] - ox, spec["anchor_raw"][1] - oy
            if spec.get("flip"):
                ax = (arr.shape[1] - 1 if scale == 1.0 else arr.shape[1] - 1) - ax
            anchor = [int(ax * scale), int(ay * scale)]
        else:
            anchor = anchor_for(arr, prop["footprint_units"], spec)
        textures = {}
        for rot, (img, anc) in make_rotations(arr, anchor).items():
            fn = sprite_name(prop["id"], rot)
            Image.fromarray(img, "RGBA").save(os.path.join(out_dir, fn + ".png"))
            textures[rot] = {"texture": "res://art/props/%s.png" % fn, "anchor_px": anc}
        prop["textures"] = textures
    if write_json:
        with open(props_json, "w", encoding="utf-8", newline="\n") as f:
            json.dump(data, f, indent=1)
            f.write("\n")
    return data


def rules(png):
    arr = np.array(Image.open(png).convert("RGBA"))
    a = arr[..., 3]
    out = [("alpha is 0 or 255", bool(np.all((a == 0) | (a == 255))))]
    colours = {tuple(int(v) for v in c[:3]) for c in arr[a == 255]}
    out.append(("at most %d colours (%d)" % (MAX_COLORS, len(colours)), len(colours) <= MAX_COLORS))
    out.append(("no old-brand red", not any(is_red(c) for c in colours)))
    out.append(("transparent corners", bool(a[0, 0] == 0 and a[0, -1] == 0 and a[-1, 0] == 0 and a[-1, -1] == 0)))
    return out


def check():
    with open(PROPS_JSON, encoding="utf-8") as f:
        data = json.load(f)
    ok = True
    for prop in data["props"]:
        if prop["id"][len("prop-"):].replace("-", "_") not in SPECS:
            continue  # T-398: still a placeholder (build_prop_art.py checks it)
        for rot in ROTATIONS:
            t = prop["textures"][rot]
            png = os.path.join(GAME, t["texture"].replace("res://", ""))
            if not t["texture"].endswith("_art.png") or not os.path.isfile(png):
                print("FAIL  %s %s: not the final art or missing" % (prop["id"], rot))
                ok = False
                continue
            for rule, good in rules(png):
                if not good:
                    print("FAIL  %s %s: %s" % (prop["id"], rot, rule))
                    ok = False
    print("OK" if ok else "FAILED")
    return 0 if ok else 1


def main(argv):
    cmd = argv[1] if len(argv) > 1 else "build"
    if cmd == "build":
        raw = argv[argv.index("--raw") + 1] if "--raw" in argv else RAW
        build(raw_dir=raw)
        print("Wrote final prop art to %s" % OUT)
        return 0
    if cmd == "check":
        return check()
    sys.exit("usage: build_prop_final_art.py build|check")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
