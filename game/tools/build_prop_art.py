#!/usr/bin/env python3
"""Builds the level creator's placeholder prop sprites (task T-253).

Reads game/data/level/props.json (each prop's footprint and its placeholder "look": boxes and
cylinders) and draws, in code and with no PixelLab, one isometric sprite per prop and rotation
(north, east, south, west) into game/art/props/<name>_<rotation>.png. Each sprite is a few
shapes with a top and two visible faces (the south and east ones), a dark outline, and a lighter
arrow on the top showing which way the prop faces. The scale is the art's: 32 art pixels per unit
along each isometric axis, drawn at 0.5 (screen x = (x - y) * 32, screen y = (x + y) * 16 - z * 32).

It also writes the "textures" key of each prop in props.json: the PNG and "anchor_px", the pixel
of it that stands on the footprint's centre on the ground. Nothing else in props.json changes.
T-256 replaces the art by changing the files and those textures.

Rules for the sprites (checked by "check"): at most 30 colours, alpha 0 or 255, no Redgull red.

Usage (from the repo root):
    python game/tools/build_prop_art.py build   # writes the sprites and the textures key
    python game/tools/build_prop_art.py check   # the rules on the committed sprites
Needs Pillow and numpy.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)
PROPS_JSON = os.path.join(GAME, "data", "level", "props.json")
OUT = os.path.join(GAME, "art", "props")
MAX_COLORS = 30
OUTLINE = (12, 12, 22)
MARKER = (214, 244, 250)  # the facing arrow: a pale cyan, never red
MARGIN = 3
# A pixel is "Redgull red" when it is strongly red with little green and blue (orange is not).
RED_MIN, RED_OVER, RED_MAX_OTHER = 150, 70, 100

ROTATIONS = ["north", "east", "south", "west"]
FACING = {"north": (0, -1), "east": (1, 0), "south": (0, 1), "west": (-1, 0)}


def load():
    with open(PROPS_JSON, encoding="utf-8") as f:
        return json.load(f)


def sprite_name(prop_id, rotation):
    return "%s_%s" % (prop_id[len("prop-"):].replace("-", "_"), rotation)


def turn(x, y, rotation):
    """A point of the prop facing north, turned to face `rotation` (north is -y, east +x)."""
    if rotation == "east":
        return -y, x
    if rotation == "south":
        return -x, -y
    if rotation == "west":
        return y, -x
    return x, y


def hexcolor(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def shade(c, f):
    return tuple(max(0, min(255, int(round(v * f)))) for v in c)


def proj(x, y, z, k):
    return ((x - y) * k, (x + y) * k / 2.0 - z * k)


class Canvas:
    """Draws in unit space, collects shapes, and rasterises them with a shared origin."""

    def __init__(self, k):
        self.k = k
        self.ops = []  # (depth, kind, args)

    def box(self, cx, cy, z0, w, d, h, color):
        self.ops.append((cx + cy, "box", (cx, cy, z0, w, d, h, color)))

    def cylinder(self, cx, cy, z0, r, h, color):
        self.ops.append((cx + cy, "cyl", (cx, cy, z0, r, h, color)))

    def marker(self, cx, cy, z, facing):
        self.ops.append((1e9, "arrow", (cx, cy, z, facing)))

    def bounds(self):
        k = self.k
        xs, ys = [], []
        for _, kind, a in self.ops:
            if kind == "box":
                cx, cy, z0, w, d, h, _c = a
                for sx in (-0.5, 0.5):
                    for sy in (-0.5, 0.5):
                        for z in (z0, z0 + h):
                            p = proj(cx + sx * w, cy + sy * d, z, k)
                            xs.append(p[0])
                            ys.append(p[1])
            elif kind == "cyl":
                cx, cy, z0, r, h, _c = a
                c0 = proj(cx, cy, z0, k)
                c1 = proj(cx, cy, z0 + h, k)
                rx, ry = r * k * math.sqrt(2), r * k * math.sqrt(2) / 2.0
                xs += [c0[0] - rx, c0[0] + rx]
                ys += [c1[1] - ry, c0[1] + ry]
        return min(xs), min(ys), max(xs), max(ys)

    def render(self):
        k = self.k
        x0, y0, x1, y1 = self.bounds()
        ox, oy = MARGIN - math.floor(x0), MARGIN - math.floor(y0)
        w = int(math.ceil(x1) - math.floor(x0)) + 2 * MARGIN + 1
        h = int(math.ceil(y1) - math.floor(y0)) + 2 * MARGIN + 1
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        dr = ImageDraw.Draw(img)

        def pt(x, y, z):
            p = proj(x, y, z, k)
            return (round(p[0] + ox), round(p[1] + oy))

        for _, kind, a in sorted(self.ops, key=lambda o: o[0]):
            if kind == "box":
                cx, cy, z0, bw, bd, bh, col = a
                x_a, x_b, y_a, y_b = cx - bw / 2, cx + bw / 2, cy - bd / 2, cy + bd / 2
                top = [pt(x_a, y_a, z0 + bh), pt(x_b, y_a, z0 + bh), pt(x_b, y_b, z0 + bh), pt(x_a, y_b, z0 + bh)]
                south = [pt(x_a, y_b, z0 + bh), pt(x_b, y_b, z0 + bh), pt(x_b, y_b, z0), pt(x_a, y_b, z0)]
                east = [pt(x_b, y_b, z0 + bh), pt(x_b, y_a, z0 + bh), pt(x_b, y_a, z0), pt(x_b, y_b, z0)]
                dr.polygon(south, fill=shade(col, 0.62) + (255,))
                dr.polygon(east, fill=shade(col, 0.8) + (255,))
                dr.polygon(top, fill=shade(col, 1.0) + (255,))
            elif kind == "cyl":
                cx, cy, z0, r, ch, col = a
                rx, ry = r * k * math.sqrt(2), r * k * math.sqrt(2) / 2.0
                c0 = pt(cx, cy, z0)
                c1 = pt(cx, cy, z0 + ch)
                dr.rectangle([c0[0] - rx, c1[1], c0[0] + rx, c0[1]], fill=shade(col, 0.62) + (255,))
                dr.rectangle([c0[0], c1[1], c0[0] + rx, c0[1]], fill=shade(col, 0.8) + (255,))
                # the lower half-ellipse closes the body, then the top
                dr.pieslice([c0[0] - rx, c0[1] - ry, c0[0] + rx, c0[1] + ry], 90, 180, fill=shade(col, 0.62) + (255,))
                dr.pieslice([c0[0] - rx, c0[1] - ry, c0[0] + rx, c0[1] + ry], 0, 90, fill=shade(col, 0.8) + (255,))
                dr.ellipse([c1[0] - rx, c1[1] - ry, c1[0] + rx, c1[1] + ry], fill=shade(col, 1.0) + (255,))
            elif kind == "arrow":
                cx, cy, z, (fx, fy) = a
                px, py = -fy, fx
                tip = (cx + fx * 0.55, cy + fy * 0.55)
                back = (cx - fx * 0.25, cy - fy * 0.25)
                poly = [pt(tip[0], tip[1], z), pt(back[0] + px * 0.35, back[1] + py * 0.35, z),
                        pt(back[0] - px * 0.35, back[1] - py * 0.35, z)]
                dr.polygon(poly, fill=MARKER + (255,))

        arr = np.array(img)
        arr = outline(arr)
        arr = reduce_colors(arr)
        return arr, (ox, oy)


def outline(arr):
    """A one pixel dark outline round the opaque pixels."""
    a = arr[..., 3] > 0
    grown = a.copy()
    grown[1:, :] |= a[:-1, :]
    grown[:-1, :] |= a[1:, :]
    grown[:, 1:] |= a[:, :-1]
    grown[:, :-1] |= a[:, 1:]
    ring = grown & ~a
    out = arr.copy()
    out[ring] = OUTLINE + (255,)
    return out


def reduce_colors(arr):
    alpha = arr[..., 3] > 127
    rgb = arr[..., :3].copy()
    if not alpha.any():
        return arr
    if len({tuple(c) for c in rgb[alpha]}) <= MAX_COLORS:
        out = arr.copy()
        out[..., 3] = np.where(alpha, 255, 0)
        out[~alpha] = (0, 0, 0, 0)
        return out
    rgb[~alpha] = rgb[alpha][0]
    q = Image.fromarray(rgb, "RGB").quantize(colors=MAX_COLORS, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGB")
    res = np.concatenate([np.array(q), np.where(alpha, 255, 0).astype(np.uint8)[..., None]], axis=-1)
    res[~alpha] = (0, 0, 0, 0)
    return res


def draw_prop(prop, rotation, k):
    cv = Canvas(k)
    look = prop["look"]
    for part in look["parts"]:
        x, y, z = part["at"]
        x, y = turn(x, y, rotation)
        col = hexcolor(part["color"])
        if part["shape"] == "box":
            w, d = part["size"]
            if rotation in ("east", "west"):
                w, d = d, w
            cv.box(x, y, z, w, d, part["height"], col)
        else:
            cv.cylinder(x, y, z, part["radius"], part["height"], col)
    mx, my, mz = look["marker"]
    mx, my = turn(mx, my, rotation)
    cv.marker(mx, my, mz, FACING[rotation])
    return cv.render()


def build():
    data = load()
    k = int(data["art_px_per_unit"])
    os.makedirs(OUT, exist_ok=True)
    for prop in data["props"]:
        textures = {}
        for rot in ROTATIONS:
            arr, anchor = draw_prop(prop, rot, k)
            name = sprite_name(prop["id"], rot)
            Image.fromarray(arr, "RGBA").save(os.path.join(OUT, name + ".png"))
            textures[rot] = {"texture": "res://art/props/%s.png" % name, "anchor_px": [anchor[0], anchor[1]]}
        prop["textures"] = textures
    with open(PROPS_JSON, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1)
        f.write("\n")
    print("Wrote %d props x %d rotations to %s" % (len(data["props"]), len(ROTATIONS), OUT))


def rules(png):
    """[(rule, passed, detail)] for one sprite."""
    arr = np.array(Image.open(png).convert("RGBA"))
    out = []
    a = arr[..., 3]
    out.append(("alpha is 0 or 255", bool(np.all((a == 0) | (a == 255))), "values %s" % sorted(set(a.flatten().tolist()))))
    colours = {tuple(int(v) for v in c[:3]) for c in arr[a == 255]}
    out.append(("at most %d colours" % MAX_COLORS, len(colours) <= MAX_COLORS, "%d colours" % len(colours)))
    reds = [c for c in colours if c[0] >= RED_MIN and max(c[1], c[2]) <= RED_MAX_OTHER and c[0] - max(c[1], c[2]) >= RED_OVER]
    out.append(("no Redgull red", not reds, "%d red colours" % len(reds)))
    return out


def check():
    data = load()
    ok = True
    for prop in data["props"]:
        for rot in ROTATIONS:
            name = sprite_name(prop["id"], rot)
            png = os.path.join(OUT, name + ".png")
            if not os.path.exists(png):
                print("FAIL  %s: missing" % name)
                ok = False
                continue
            for rule, good, detail in rules(png):
                if not good:
                    print("FAIL  %s %s: %s" % (name, rule, detail))
                ok = ok and good
    print("OK" if ok else "FAILED")
    return 0 if ok else 1


def main(argv):
    cmd = argv[1] if len(argv) > 1 else "build"
    if cmd == "build":
        build()
        return 0
    if cmd == "check":
        return check()
    sys.exit("usage: build_prop_art.py build|check")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
