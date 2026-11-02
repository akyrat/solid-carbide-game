"""Placeholder icon for the Polarized Steering Wheel power-up (T-502). Free: no PixelLab call.

    python game/tools/draw_power_up_icon_polarized_steering_wheel.py <out.png> [--preview <png>]

A simple steering wheel, 32 x 32 RGBA, drawn by maths until T-503's real icon replaces it
(Drifting, Decisions, "Rusty Paintjob and the Polarized Steering Wheel": its icon is a steering
wheel). A thick dark rim with a chrome highlight on its top-left, three spokes (left, right, down)
to a round hub split cyan and magenta (the "polarized" two poles), and a near-black outline round
every part. Opaque pixels only, a small palette, none of Greenbull's colours, transparent corners.
Prints the bounding box and the colour count.
"""

from __future__ import annotations

import math
import sys

from PIL import Image

SIZE = 32
C = (SIZE - 1) / 2.0  # 15.5: the centre between the middle pixels

OUTLINE = (14, 10, 22)
RIM_DARK = (41, 33, 74)
RIM = (95, 89, 135)
RIM_LIGHT = (157, 158, 177)
CHROME = (241, 248, 251)
SPOKE = (96, 100, 128)
SPOKE_LIGHT = (157, 158, 177)
CYAN = (42, 213, 239)
CYAN_DARK = (30, 140, 180)
MAGENTA = (220, 70, 200)
MAGENTA_DARK = (110, 34, 104)

R_OUT = 14.6   # the rim's outer edge
R_IN = 10.4    # its inner edge
HUB = 4.6      # the hub's radius
SPOKE_HALF = 1.6  # half a spoke's width


def _part(x: float, y: float) -> tuple | None:
    """The colour of the wheel's part at a pixel centre (x, y), or None for empty."""
    dx, dy = x - C, y - C
    r = math.hypot(dx, dy)
    if R_IN <= r <= R_OUT:
        # The rim: lit from the top-left.
        light = -(dx + dy) / (r * math.sqrt(2.0)) if r else 0.0
        if light > 0.75 and r > (R_IN + R_OUT) / 2:
            return CHROME
        if light > 0.3:
            return RIM_LIGHT
        if light < -0.5:
            return RIM_DARK
        return RIM
    if r <= HUB:
        # The hub: cyan on the left half, magenta on the right, darker at the bottom.
        if dx < 0:
            return CYAN_DARK if dy > 2 else CYAN
        return MAGENTA_DARK if dy > 2 else MAGENTA
    if r < R_IN:
        # The spokes: left, right (a horizontal bar a little above the centre) and down.
        if abs(dy + 1.0) <= SPOKE_HALF:
            return SPOKE_LIGHT if dy + 1.0 < -0.5 else SPOKE
        if dy > 0 and abs(dx) <= SPOKE_HALF:
            return SPOKE_LIGHT if dx < -0.5 else SPOKE
    return None


def draw() -> Image.Image:
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    fill = {}
    for y in range(SIZE):
        for x in range(SIZE):
            c = _part(x, y)
            if c is not None:
                fill[(x, y)] = c
    # A one-pixel near-black outline round every part (and between rim and spokes' gaps).
    outline = set()
    for y in range(SIZE):
        for x in range(SIZE):
            if (x, y) in fill:
                continue
            if any((x + ox, y + oy) in fill for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                outline.add((x, y))
    for xy in outline:
        fill[xy] = OUTLINE
    for (x, y), c in fill.items():
        im.putpixel((x, y), c + (255,))
    return im


def preview(im: Image.Image, path: str, scale: int = 8) -> None:
    """The icon enlarged (nearest neighbour) on a dark and a light background, side by side."""
    big = im.resize((SIZE * scale, SIZE * scale), Image.NEAREST)
    out = Image.new("RGBA", (SIZE * scale * 2 + 3 * scale, SIZE * scale + 2 * scale), (255, 255, 255, 255))
    dark = Image.new("RGBA", (SIZE * scale + 2 * scale, SIZE * scale + 2 * scale), (13, 13, 27, 255))
    out.paste(dark, (0, 0))
    out.alpha_composite(big, (scale, scale))
    out.alpha_composite(big, (SIZE * scale + 2 * scale, scale))
    out.save(path)


def main(argv: list[str]) -> int:
    args = argv[1:]
    prev = None
    if "--preview" in args:
        i = args.index("--preview")
        prev = args[i + 1]
        del args[i:i + 2]
    if len(args) != 1:
        print(__doc__)
        return 2
    im = draw()
    im.save(args[0])
    cols = {p[:3] for p in im.getdata() if p[3]}
    print("bbox", im.getbbox(), "colours", len(cols))
    if prev:
        preview(im, prev)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
