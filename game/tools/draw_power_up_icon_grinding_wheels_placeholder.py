"""Script-drawn PLACEHOLDER icon for Grinding Wheels (T-586), until T-587's art. Free: no PixelLab call.

    python game/tools/draw_power_up_icon_grinding_wheels_placeholder.py <out.png>

A 32x32 RGBA sketch of the idea (Visual style, Decisions: a wheel grinding on a rail with sparks
coming out of one side): a dark tyre with a grey rim on a steel bar, a fan of yellow, orange and red
spark pixels off its left side. Hard pixels only (alpha 0 or 255), none of Greenbull's colours.
"""

from __future__ import annotations

import math
import sys

from PIL import Image

SIZE = 32
OUTLINE = (14, 10, 22)
TYRE = (40, 34, 58)
TYRE_LIT = (70, 64, 96)
RIM = (157, 158, 177)
HUB = (220, 222, 232)
BAR = (120, 128, 156)
BAR_DARK = (60, 62, 90)
SPARKS = [(255, 250, 205), (255, 228, 90), (255, 172, 64), (246, 132, 32), (226, 46, 30)]


def draw() -> Image.Image:
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = im.load()

    def put(x, y, c):
        if 0 <= x < SIZE and 0 <= y < SIZE:
            px[x, y] = c + (255,)

    # The rail: a bar across the bottom, rows 25 to 28 (outline, lit top, body, dark).
    for x in range(1, 31):
        put(x, 25, OUTLINE)
        put(x, 26, BAR)
        put(x, 27, BAR_DARK)
        put(x, 28, OUTLINE)
    # The wheel: centre (18, 15), radius 10, sitting on the bar.
    cx, cy, r = 18, 15, 10
    for y in range(SIZE):
        for x in range(SIZE):
            d = math.hypot(x - cx, y - cy)
            if d <= r + 0.5:
                if d > r - 0.6:
                    c = OUTLINE
                elif d > 6.5:
                    c = TYRE_LIT if (x - cx) + (y - cy) < -4 else TYRE
                elif d > 5.5:
                    c = OUTLINE
                elif d > 2.0:
                    c = RIM
                else:
                    c = HUB
                put(x, y, c)
    # Spokes in the rim.
    for a in range(0, 360, 60):
        for t in range(2, 6):
            put(round(cx + t * math.cos(math.radians(a))), round(cy + t * math.sin(math.radians(a))), OUTLINE)
    # Sparks: a fan off the left side of the contact point (about x 12, y 24), hottest near it.
    fan = [(-1, -1), (-2, -1), (-3, -2), (-4, -2), (-5, -3), (-6, -3), (-7, -4), (-8, -5),
           (-2, -3), (-4, -4), (-6, -6), (-8, -7), (-3, 0), (-5, -1), (-7, -1), (-9, -2),
           (-10, -3), (-11, -1), (-10, -6), (-9, -9)]
    for i, (dx, dy) in enumerate(fan):
        dist = math.hypot(dx, dy)
        c = SPARKS[min(int(dist / 2.6), len(SPARKS) - 1)]
        put(12 + dx, 24 + dy, c)
    return im


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) != 1:
        print(__doc__)
        return 2
    draw().save(argv[0])
    return 0


if __name__ == "__main__":
    sys.exit(main())
