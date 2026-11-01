"""Free script fixes for the Jump power-up icon (T-465), made from PixelLab's raw picture.

    python game/tools/build_power_up_icon_jump.py <raw.png> <out.png> [--max-colors 30]
    python game/tools/build_power_up_icon_jump.py <raw.png> --dump      # prints the pixel grid

Fixes, all without a new generation:
- The car's body is recoloured from PixelLab's teal-grey into the car's dark green family (Visual style,
  rule 10), keeping each pixel's lightness, so its shading stays. Only car pixels are touched: the
  ones above the pad (``CAR_MAX_Y``) whose colour is a low-saturation teal/blue-grey, not the cyan or
  magenta glow and not the near-black outline.
- The colours are merged down to at most ``--max-colors`` (rule 1), always merging the closest pair,
  so the near-black outline and the brightest glow pixels survive.
- Alpha is made fully opaque or fully transparent (rule 1).
"""

from __future__ import annotations

import argparse
import colorsys
import sys

from PIL import Image

CAR_MAX_Y = 17          # rows 0..16 hold the car in the raw picture; the pad starts below
OUTLINE_MAX_V = 0.16    # near-black outline pixels are left alone
GREEN_HUE = 150 / 360   # the car's dark green (12, 76, 44) is about hue 150
GREENBULL_FORBIDDEN = {(104, 220, 96), (247, 208, 52)}


def is_car_body(rgb, y):
    if y >= CAR_MAX_Y:
        return False
    r, g, b = (c / 255 for c in rgb)
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    if v <= OUTLINE_MAX_V:
        return False
    hue = h * 360
    # teal / blue-grey paint: hue 160..220, not the saturated bright cyan glow
    return 150 <= hue <= 225 and not (s > 0.6 and v > 0.8)


def to_green(rgb):
    r, g, b = (c / 255 for c in rgb)
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    # keep lightness; dark green is fairly saturated in the mids, paler in the highlights
    s2 = min(0.85, max(0.35, s * 1.3))
    if v > 0.75:
        s2 = min(s2, 0.30)  # top-left highlights stay pale so they read as the white stripes' sheen
    v2 = v * 0.85
    nr, ng, nb = colorsys.hsv_to_rgb(GREEN_HUE, s2, v2)
    out = (round(nr * 255), round(ng * 255), round(nb * 255))
    return out


def binarize_alpha(im):
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)


def recolour_car(im):
    px = im.load()
    n = 0
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and is_car_body((r, g, b), y):
                px[x, y] = to_green((r, g, b)) + (255,)
                n += 1
    return n


def _dist(c1, c2):
    return sum((a - b) ** 2 for a, b in zip(c1, c2))


def merge_colours(im, max_colors):
    px = im.load()
    counts = {}
    for y in range(im.height):
        for x in range(im.width):
            p = px[x, y]
            if p[3]:
                counts[p[:3]] = counts.get(p[:3], 0) + 1
    mapping = {c: c for c in counts}
    while len(counts) > max_colors:
        cols = list(counts)
        best = None
        for i, a in enumerate(cols):
            for b in cols[i + 1:]:
                d = _dist(a, b)
                if best is None or d < best[0]:
                    best = (d, a, b)
        _, a, b = best
        keep, drop = (a, b) if counts[a] >= counts[b] else (b, a)
        counts[keep] += counts.pop(drop)
        for k, v in mapping.items():
            if v == drop:
                mapping[k] = keep
    for y in range(im.height):
        for x in range(im.width):
            p = px[x, y]
            if p[3]:
                px[x, y] = mapping[p[:3]] + (255,)
    return len(counts)


def build(raw_path, out_path, max_colors=30):
    im = Image.open(raw_path).convert("RGBA")
    binarize_alpha(im)
    n_car = recolour_car(im)
    n_cols = merge_colours(im, max_colors)
    im.save(out_path)
    return {"car_pixels_recoloured": n_car, "colours": n_cols, "bbox": im.getbbox()}


def dump(raw_path):
    im = Image.open(raw_path).convert("RGBA")
    px = im.load()
    for y in range(im.height):
        row = ""
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if not a:
                row += "."
            elif is_car_body((r, g, b), y):
                row += "C"
            elif max(r, g, b) < 41:
                row += "#"
            else:
                row += "o"
        print(f"{y:2d} {row}")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("raw")
    ap.add_argument("out", nargs="?")
    ap.add_argument("--max-colors", type=int, default=30)
    ap.add_argument("--dump", action="store_true")
    a = ap.parse_args(argv)
    if a.dump:
        dump(a.raw)
        return 0
    if not a.out:
        ap.error("out is required unless --dump")
    print(build(a.raw, a.out, a.max_colors))
    return 0


if __name__ == "__main__":
    sys.exit(main())
