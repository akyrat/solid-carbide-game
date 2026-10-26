#!/usr/bin/env python3
"""Greenbull emblem helpers (T-294): free script steps around the PixelLab call.

  greenbull_emblem.py draw <out.png>             script-drawn angular bull head (run 2 shape), 128 x 128
  greenbull_emblem.py remap <in.png> <out.png>   snap every pixel to the brand palette; alpha < 128 -> transparent;
                                                 lone specks take their neighbours' colour
  greenbull_emblem.py preview <in.png> <out.png> x4 on dark and light, plus the 32 x 32 read; prints the colours
"""
import sys
from collections import Counter
from PIL import Image, ImageDraw

W = H = 128
CLEAR = (0, 0, 0, 0)
OUTLINE = (14, 22, 18, 255)       # near-black outline
DEEP = (6, 46, 26, 255)           # the one extra darker green
DARK = (12, 76, 44, 255)          # brand dark green: leads
LIGHT = (104, 220, 96, 255)       # brand light green
YELLOW = (247, 208, 52, 255)      # brand yellow: accent only
PALETTE = [OUTLINE, DEEP, DARK, LIGHT, YELLOW]


def _mirror(pts):
    return [(W - 1 - x, y) for x, y in pts]


def _both(d, pts, fill):
    d.polygon(pts, fill=fill)
    d.polygon(_mirror(pts), fill=fill)


def outline(fill: Image.Image, width: int = 2) -> Image.Image:
    """Grow the opaque shape by `width` pixels in OUTLINE, under the fill."""
    src = fill.load()
    out = Image.new("RGBA", fill.size, CLEAR)
    dst = out.load()
    w, h = fill.size
    for y in range(h):
        for x in range(w):
            if src[x, y][3]:
                continue
            hit = False
            for dy in range(-width, width + 1):
                for dx in range(-width, width + 1):
                    if abs(dx) + abs(dy) > width + 1:
                        continue
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3]:
                        hit = True
                        break
                if hit:
                    break
            if hit:
                dst[x, y] = OUTLINE
    out.alpha_composite(fill)
    return out


def draw() -> Image.Image:
    fill = Image.new("RGBA", (W, H), CLEAR)
    d = ImageDraw.Draw(fill)
    # Horns: thick at the skull, sweeping out, then up and forward to a sharp point.
    _both(d, [(46, 34), (36, 36), (24, 34), (16, 28), (11, 19), (10, 10), (14, 15), (20, 21),
              (28, 24), (38, 25), (48, 26)], LIGHT)
    _both(d, [(46, 34), (36, 36), (24, 34), (16, 28), (13, 22), (22, 28), (32, 31), (46, 31)], DEEP)
    # Ears: pointed blades out to the sides, under the horns.
    _both(d, [(40, 42), (18, 44), (26, 52), (42, 54)], DARK)
    _both(d, [(38, 45), (24, 46), (29, 50), (40, 51)], DEEP)
    # Head: an angular shield tapering to the muzzle.
    d.polygon([(42, 26), (85, 26), (94, 38), (90, 58), (82, 80), (80, 96), (76, 108), (68, 114),
               (59, 114), (51, 108), (47, 96), (45, 80), (37, 58), (33, 38)], fill=DARK)
    # Light-green cheek facets down the outer face.
    _both(d, [(34, 40), (40, 40), (46, 66), (48, 84), (44, 74), (37, 58)], LIGHT)
    # Lightning blaze down the face.
    d.polygon([(58, 28), (70, 28), (67, 46), (73, 46), (61, 80), (63, 58), (56, 58), (60, 42), (55, 42)],
              fill=LIGHT)
    # Heavy furrowed brow slanting down to the centre, narrow yellow eyes under it.
    _both(d, [(35, 46), (44, 46), (60, 56), (60, 61), (50, 59), (37, 52)], OUTLINE)
    _both(d, [(41, 55), (52, 60), (53, 63), (45, 61)], YELLOW)
    # Muzzle plate with flared nostrils and a nose ring.
    d.polygon([(48, 88), (79, 88), (82, 96), (78, 107), (70, 113), (57, 113), (49, 107), (45, 96)], fill=DEEP)
    _both(d, [(50, 94), (58, 97), (59, 103), (53, 104), (49, 99)], OUTLINE)
    d.rectangle((57, 108, 70, 113), fill=YELLOW)
    d.rectangle((60, 108, 67, 110), fill=DEEP)
    return outline(fill)


def nearest(rgb, palette=PALETTE):
    return min(palette, key=lambda p: sum((a - b) ** 2 for a, b in zip(rgb[:3], p[:3])))


def remap(im: Image.Image, palette=PALETTE) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    src = im.load()
    out = Image.new("RGBA", im.size, CLEAR)
    dst = out.load()
    for y in range(h):
        for x in range(w):
            p = src[x, y]
            if p[3] >= 128:
                dst[x, y] = nearest(p, palette)
    # Lone specks: a pixel unlike all 4 neighbours takes their most common colour.
    fixed = out.copy()
    fx = fixed.load()
    for y in range(h):
        for x in range(w):
            ns = [dst[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                  if 0 <= x + dx < w and 0 <= y + dy < h]
            if len(ns) == 4 and all(n != dst[x, y] for n in ns):
                fx[x, y] = Counter(ns).most_common(1)[0][0]
    return fixed


def preview(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    big = im.resize((512, 512), Image.NEAREST)
    small = im.resize((32, 32), Image.NEAREST).resize((128, 128), Image.NEAREST)
    sheet = Image.new("RGBA", (1040 + 128, 512), (0, 0, 0, 255))
    for i, bg in enumerate([(24, 20, 44, 255), (228, 228, 222, 255)]):
        tile = Image.new("RGBA", (512, 512), bg)
        tile.alpha_composite(big)
        sheet.paste(tile, (i * 520, 0))
        t2 = Image.new("RGBA", (128, 128), bg)
        t2.alpha_composite(small)
        sheet.paste(t2, (1040, i * 140))
    return sheet


def main(argv):
    if len(argv) >= 2 and argv[0] == "draw":
        draw().save(argv[1])
    elif len(argv) >= 3 and argv[0] == "remap":
        remap(Image.open(argv[1])).save(argv[2])
    elif len(argv) >= 3 and argv[0] == "preview":
        im = Image.open(argv[1]).convert("RGBA")
        print(sorted(im.getcolors(1 << 16), reverse=True)[:12])
        preview(im).save(argv[2])
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
