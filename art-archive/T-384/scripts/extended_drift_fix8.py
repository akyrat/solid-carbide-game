"""Free script fix for T-384 run 8 (extended_drift), no PixelLab call.

extended_drift used all 4 of its generations in run 1 (opaque backgrounds).
This takes the best raw (extended_drift_v4.png: long curved pink arc, smoke,
car sideways at its end) and:
  1. removes the road/background (navy-purple road, lane dashes) -> alpha 0,
  2. keeps the neon pink arc, the car and the tire smoke,
  3. recolours the car's teal body to a dark green ramp around 12,76,44,
  4. adds a 1 px dark purple stepped halo around the trail and a near-black
     selective outline around the car,
  5. cuts the palette to <= 30 colours, alpha fully 0 or 255.

usage: python extended_drift_fix8.py SRC OUT
"""
import colorsys
import sys

from PIL import Image

W, H = 64, 48
CAR_BOX = (13, 19, 50, 45)  # x0, y0, x1, y1 (exclusive), around the car
SMOKE_BOX = (42, 8, 64, 34)
OUTLINE = (8, 6, 14)
HALO = (58, 26, 74)
HALO2 = (34, 20, 52)
GREENS = [(4, 26, 16), (8, 50, 30), (12, 76, 44), (22, 98, 58), (40, 122, 74)]
FORBIDDEN = [(104, 220, 96), (247, 208, 52)]


def hsv(c):
    h, s, v = colorsys.rgb_to_hsv(c[0] / 255, c[1] / 255, c[2] / 255)
    return h * 360, s, v


def in_box(x, y, b):
    return b[0] <= x < b[2] and b[1] <= y < b[3]


def is_pink(c):
    h, s, v = hsv(c)
    return 295 <= h <= 345 and s >= 0.3 and v >= 0.5


def is_road(c):
    h, s, v = hsv(c)
    return v < 0.47 and not (165 <= h <= 205 and s > 0.5) and not v < 0.07


def classify(src):
    keep = {}
    for y in range(H):
        for x in range(W):
            c = src.getpixel((x, y))[:3]
            h, s, v = hsv(c)
            if in_box(x, y, CAR_BOX) and not is_road(c):
                keep[(x, y)] = "car"
            elif is_pink(c):
                keep[(x, y)] = "trail"
            elif in_box(x, y, SMOKE_BOX) and s < 0.3 and v > 0.55:
                keep[(x, y)] = "smoke"
    return keep


def recolour_car(c):
    h, s, v = hsv(c)
    if 160 <= h <= 215 and s > 0.3:
        i = min(len(GREENS) - 1, int(v / 0.62 * len(GREENS)))
        return GREENS[i]
    if v < 0.08:
        return OUTLINE
    return c


def main(src_path, out_path):
    src = Image.open(src_path).convert("RGBA")
    keep = classify(src)
    # drop isolated single pixels (lane-dash leftovers)
    def neighbours(p):
        x, y = p
        return sum((x + dx, y + dy) in keep for dx in (-1, 0, 1)
                   for dy in (-1, 0, 1) if dx or dy)
    for p in [p for p in keep if neighbours(p) == 0]:
        del keep[p]

    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for (x, y), kind in keep.items():
        c = src.getpixel((x, y))[:3]
        if kind == "car":
            c = recolour_car(c)
        out.putpixel((x, y), c + (255,))

    # stepped halo around the trail, selective outline around the car
    def empty(x, y):
        return 0 <= x < W and 0 <= y < H and out.getpixel((x, y))[3] == 0
    adds = {}
    for (x, y), kind in keep.items():
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if empty(nx, ny):
                if kind == "car":
                    adds[(nx, ny)] = OUTLINE
                elif kind == "trail":
                    adds.setdefault((nx, ny), HALO)
    for p, c in adds.items():
        out.putpixel(p, c + (255,))
    # second, darker halo step outside the trail's first one
    adds2 = {}
    for p, c in adds.items():
        if c != HALO:
            continue
        x, y = p
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if empty(x + dx, y + dy) and (x + y) % 2 == 0:
                adds2[(x + dx, y + dy)] = HALO2
    for p, c in adds2.items():
        out.putpixel(p, c + (255,))

    # palette <= 30, keep alpha binary
    rgb = Image.new("RGB", (W, H))
    rgb.paste(out.convert("RGB"))
    q = rgb.quantize(colors=30, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    final = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for y in range(H):
        for x in range(W):
            if out.getpixel((x, y))[3]:
                c = q.getpixel((x, y))
                if c in FORBIDDEN:
                    c = (c[0] - 8, c[1] - 8, c[2] - 8)
                final.putpixel((x, y), c + (255,))
    final.save(out_path)
    n = len({final.getpixel((x, y)) for y in range(H) for x in range(W)} - {(0, 0, 0, 0)})
    print(f"{out_path}: {n} colours, kept {sum(1 for y in range(H) for x in range(W) if final.getpixel((x, y))[3])} px")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
