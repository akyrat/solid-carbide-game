"""T-294 run 2, version 1: script-drawn angular bull-head emblem (free), used as init_image for pixflux
and as the shape the remap snaps back to. 128 x 128, transparent, brand colours only.

Usage: python draw_v1-2.py <out.png>
"""
import sys
from PIL import Image, ImageDraw

W = H = 128
OUTLINE = (14, 22, 18, 255)       # near-black outline
DARK = (12, 76, 44, 255)          # brand dark green, leads
DEEP = (6, 46, 26, 255)           # the one extra darker green
LIGHT = (104, 220, 96, 255)       # brand light green
YELLOW = (247, 208, 52, 255)      # brand yellow, accent only


def mirror(pts):
    return [(W - 1 - x, y) for x, y in pts]


def both(draw, pts, fill):
    draw.polygon(pts, fill=fill)
    draw.polygon(mirror(pts), fill=fill)


def draw():
    fill = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(fill)

    # Horns: thick at the skull, sweeping out, then up and forward to a sharp point.
    horn = [(46, 34), (36, 36), (24, 34), (16, 28), (11, 19), (10, 10), (14, 15), (20, 21),
            (28, 24), (38, 25), (48, 26)]
    both(d, horn, LIGHT)
    horn_shade = [(46, 34), (36, 36), (24, 34), (16, 28), (13, 22), (22, 28), (32, 31), (46, 31)]
    both(d, horn_shade, DEEP)

    # Ears: pointed blades out to the sides, under the horns.
    ear = [(40, 42), (18, 44), (26, 52), (42, 54)]
    both(d, ear, DARK)
    both(d, [(38, 45), (24, 46), (29, 50), (40, 51)], DEEP)

    # Head: an angular shield tapering to the muzzle.
    head = [(42, 26), (85, 26), (94, 38), (90, 58), (82, 80), (80, 96), (76, 108), (68, 114),
            (59, 114), (51, 108), (47, 96), (45, 80), (37, 58), (33, 38)]
    d.polygon(head, fill=DARK)

    # Light-green cheek facets down the outer face.
    both(d, [(34, 40), (40, 40), (46, 66), (48, 84), (44, 74), (37, 58)], LIGHT)

    # Lightning blaze down the face.
    blaze = [(58, 28), (70, 28), (67, 46), (73, 46), (61, 80), (63, 58), (56, 58), (60, 42), (55, 42)]
    d.polygon(blaze, fill=LIGHT)

    # Heavy furrowed brow: a dark wedge slanting down to the centre.
    both(d, [(35, 46), (44, 46), (60, 56), (60, 61), (50, 59), (37, 52)], OUTLINE)
    # Narrow, intense eyes under it.
    both(d, [(41, 55), (52, 60), (53, 63), (45, 61)], YELLOW)

    # Muzzle: deeper green plate with flared nostrils and a nose ring.
    muzzle = [(48, 88), (79, 88), (82, 96), (78, 107), (70, 113), (57, 113), (49, 107), (45, 96)]
    d.polygon(muzzle, fill=DEEP)
    both(d, [(50, 94), (58, 97), (59, 103), (53, 104), (49, 99)], OUTLINE)
    d.rectangle((57, 108, 70, 110), fill=YELLOW)
    d.rectangle((57, 111, 70, 113), fill=YELLOW)
    d.rectangle((60, 108, 67, 110), fill=DEEP)

    # Near-black outline: grow the shape by 2 pixels.
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    src = fill.load()
    dst = out.load()
    for y in range(H):
        for x in range(W):
            if src[x, y][3]:
                continue
            for dy in range(-2, 3):
                for dx in range(-2, 3):
                    if abs(dx) + abs(dy) > 3:
                        continue
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and src[nx, ny][3]:
                        dst[x, y] = OUTLINE
                        break
                else:
                    continue
                break
    out.alpha_composite(fill)
    return out


if __name__ == "__main__":
    draw().save(sys.argv[1])
