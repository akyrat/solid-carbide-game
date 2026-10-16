#!/usr/bin/env python3
"""Draw a one-colour seagull-head silhouette (side profile, facing right) by script (T-075).
Coordinates are on a 64 px grid and scale with --size. Free, no PixelLab.
Variants: v1 (round 2, raptor-like, kept for the record), A, B, C (round 3: domed crown, long slim beak,
gonys bump under the bill, small eye, tapering neck with a diagonal cut).
Usage: draw_gull_silhouette.py <out.png> [--size 64] [--variant A]"""
import argparse
from PIL import Image, ImageDraw

DARK_RED = (150, 24, 28, 255)
SS = 8  # supersample, then threshold to hard pixels

VARIANTS = {
    "v1": dict(head=(23, 26, 12), cuts=[],
               fill=[[(26, 15), (33, 18), (46, 22), (58, 27), (61, 31), (61, 36), (58, 33), (56, 31), (46, 32), (34, 35)],
                     [(12, 30), (33, 33), (30, 54), (11, 56)]],
               holes=[[(25, 21), (33, 24), (33, 26), (26, 24)]]),
    # A: gape line, straight neck cut
    "A": dict(head=(24, 24, 12),
              fill=[[(30, 18), (46, 22), (58, 25.5), (61, 28.5), (60.5, 31.5), (57.5, 29.8), (52, 32), (46, 30.8), (34, 31.5), (30, 33)],
                    [(13, 30), (33, 32), (31, 46), (15, 56)]],
              holes=[[(24.5, 21.5), (29.5, 23), (29.5, 24.4), (25, 23)]],
              lines=[((34, 27.6), (51, 28.4), 1.0)]),
    # B: no gape line, bit smaller eye, neck curves back
    "B": dict(head=(24, 24, 12),
              fill=[[(30, 18), (46, 22), (58, 25.5), (61, 28.5), (60.5, 31.5), (57.5, 29.8), (52, 32), (46, 30.8), (34, 31.5), (30, 33)],
                    [(14, 30), (32, 32), (29, 44), (22, 52), (14, 54)]],
              holes=[[(25, 21.5), (29, 23), (29, 24.2), (25.3, 22.9)]], lines=[]),
    # D: B with a thicker bill (a gull's is stout) and a larger slanted eye
    "D": dict(head=(24, 24, 12),
              fill=[[(30, 18), (46, 21.5), (58, 25), (61.5, 28.5), (61, 32), (57.5, 30.2), (52, 33), (46, 31.8), (34, 32.5), (30, 34)],
                    [(14, 30), (32, 33), (29, 44), (22, 52), (14, 54)]],
              holes=[[(24, 21), (30, 23), (30, 25), (24.5, 23)]], lines=[]),
    # C: smaller round head, longer slimmer beak, short neck, gape line
    "C": dict(head=(22, 24, 11),
              fill=[[(28, 19), (46, 23), (59, 26), (62, 28.8), (61.5, 31), (58, 29.6), (52, 31.8), (46, 30.2), (32, 30.8), (28, 32)],
                    [(12, 29), (30, 32), (28, 42), (14, 50)]],
              holes=[[(23, 22), (28, 23.3), (28, 24.6), (23.5, 23.3)]],
              lines=[((32, 27.4), (52, 28.2), 1.0)]),
}


def draw(size: int = 64, variant: str = "A") -> Image.Image:
    v = VARIANTS[variant]
    k = size / 64 * SS
    big = Image.new("L", (size * SS, size * SS), 0)
    d = ImageDraw.Draw(big)
    cx, cy, r = v["head"]
    d.ellipse([(cx - r) * k, (cy - r) * k, (cx + r) * k, (cy + r) * k], fill=255)
    for poly in v["fill"]:
        d.polygon([(x * k, y * k) for x, y in poly], fill=255)
    for poly in v["holes"]:
        d.polygon([(x * k, y * k) for x, y in poly], fill=0)
    for a, b, w in v.get("lines", []):
        d.line([(a[0] * k, a[1] * k), (b[0] * k, b[1] * k)], fill=0, width=max(1, int(w * k)))
    mask = big.resize((size, size), Image.BOX).point(lambda p: 255 if p >= 128 else 0)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(Image.new("RGBA", (size, size), DARK_RED), mask=mask)
    return out


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--size", type=int, default=64)
    ap.add_argument("--variant", default="A", choices=sorted(VARIANTS))
    a = ap.parse_args()
    draw(a.size, a.variant).save(a.out)
