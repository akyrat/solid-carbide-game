#!/usr/bin/env python3
"""Draw the Grinding Wheels power-up icon by script (T-587, style loop version 3; 0 PixelLab generations).

A 32 x 32 icon (Visual style, Decisions, "Grinding Wheels icon"): a car wheel seen 3/4 from the side,
its tyre a dark blue-grey ellipse with a tread band on the right, a steel hub with five lug nuts,
resting on a horizontal steel rail, with a spray of orange and white sparks fanning out of the rear
(right) side with stepped halos and a few cyan and magenta accents. Light from the top-left, a dark
outline broken by highlight pixels, under 26 colours, alpha 0 or 255.

    python game/tools/build_grinding_wheels_icon.py <out png>
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

from PIL import Image

W = H = 32
OUTLINE = (6, 5, 10)
OUTLINE_HI = (112, 133, 189)

TYRE_LIT, TYRE, TYRE_DARK = (62, 74, 108), (36, 44, 72), (22, 27, 46)
TREAD, TREAD_NOTCH = (16, 20, 34), (58, 68, 98)
HUB_LIT, HUB, HUB_DARK, HUB_RING = (196, 226, 232), (130, 160, 190), (84, 100, 128), (46, 56, 84)
LUG = (28, 34, 56)
RAIL_HI, RAIL_TOP, RAIL_MID, RAIL_DARK = (184, 222, 223), (122, 153, 184), (77, 93, 119), (49, 66, 91)
SPARK = [(251, 238, 219), (255, 158, 46), (232, 112, 36), (150, 70, 26), (84, 40, 18)]
CYAN, MAGENTA = (90, 220, 240), (235, 80, 200)

CX, CY, RX, RY = 14, 14, 9, 9.6     # the tyre's face ellipse (9.6, not 10: a 10 would leave one lone pixel at the top)
SIDE = 4                            # the tread band's offset to the right (the 3/4 view)
HUB_RX, HUB_RY = 5, 6
RAIL_X0, RAIL_X1, RAIL_Y0 = 1, 30, 24   # the rail: 5 rows from RAIL_Y0, the tyre's bottom touches it

# The spray: (x, y, tier) from the contact point at the tyre's rear bottom, fanning right and up.
SPARKS = [
    (24, 23, 0), (25, 22, 0), (26, 23, 1), (25, 21, 1), (27, 21, 1), (26, 20, 1), (28, 22, 1),
    (28, 19, 1), (27, 18, 2), (29, 20, 1), (30, 21, 2), (29, 17, 2), (30, 18, 1), (31, 19, 2),
    (28, 16, 2), (30, 15, 2), (26, 17, 2), (31, 16, 2), (29, 23, 2), (31, 23, 2), (27, 24, 2),
    (30, 13, 3), (27, 15, 3), (31, 12, 3), (24, 20, 1), (25, 19, 2),
]
ACCENTS = {(26, 20): CYAN, (30, 18): CYAN, (28, 22): MAGENTA, (29, 17): MAGENTA}


def in_ellipse(x: int, y: int, cx: float, cy: float, rx: float, ry: float) -> bool:
    return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0


def light(x: int, y: int, cx: float, cy: float, rx: float, ry: float) -> float:
    """-1 (bottom-right) to 1 (top-left): how much the top-left light reaches this point."""
    return (-(x - cx) / rx - (y - cy) / ry) / math.sqrt(2)


def shade(value: float, lit, base, dark, hi: float = 0.45, lo: float = -0.45):
    return lit if value > hi else dark if value < lo else base


def draw() -> Image.Image:
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()

    def put(x: int, y: int, c) -> None:
        if 0 <= x < W and 0 <= y < H:
            px[x, y] = c + (255,)

    # The rail.
    y0 = RAIL_Y0
    for x in range(RAIL_X0, RAIL_X1 + 1):
        put(x, y0, OUTLINE)
        put(x, y0 + 1, RAIL_HI if x <= RAIL_X0 + 8 or x in (RAIL_X1 - 6, RAIL_X1 - 5) else RAIL_TOP)
        put(x, y0 + 2, RAIL_MID)
        put(x, y0 + 3, RAIL_DARK)
        put(x, y0 + 4, OUTLINE)
    for y in range(y0, y0 + 5):
        put(RAIL_X0, y, OUTLINE)
        put(RAIL_X1, y, OUTLINE)
    put(RAIL_X0 + 1, y0, OUTLINE_HI)     # highlight breaks in the rail's top outline
    put(RAIL_X0 + 2, y0, OUTLINE_HI)

    # The tyre: the face ellipse plus the tread band (the same ellipse shifted right).
    face = {(x, y) for y in range(H) for x in range(W) if in_ellipse(x, y, CX, CY, RX, RY)}
    band = {(x, y) for y in range(H) for x in range(W) if in_ellipse(x, y, CX + SIDE, CY, RX, RY)} - face
    body = face | band
    edge = {(x, y) for (x, y) in body
            if any((x + dx, y + dy) not in body for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    for x, y in band:
        put(x, y, TREAD_NOTCH if (y - CY) % 3 == 0 and (x, y) not in edge else TREAD)
    for x, y in face:
        put(x, y, shade(light(x, y, CX, CY, RX, RY), TYRE_LIT, TYRE, TYRE_DARK))
    # The face's inner rim: a lit ring just inside the hub, so the tyre reads apart from the metal.
    for x, y in edge:
        put(x, y, OUTLINE)
    # Highlight breaks in the outline, top-left.
    for x, y in edge:
        if light(x, y, CX, CY, RX, RY) > 0.82 and (x, y) in face:
            put(x, y, OUTLINE_HI)

    # The hub: steel, lit from the top-left, a dark ring round it and five lug nuts.
    hub = {(x, y) for y in range(H) for x in range(W) if in_ellipse(x, y, CX, CY, HUB_RX, HUB_RY)}
    hub_edge = {(x, y) for (x, y) in hub
                if any((x + dx, y + dy) not in hub for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    for x, y in hub:
        put(x, y, HUB_RING if (x, y) in hub_edge else shade(light(x, y, CX, CY, HUB_RX, HUB_RY), HUB_LIT, HUB, HUB_DARK))
    for i in range(5):
        a = math.radians(-90 + i * 72)
        put(round(CX + 2.6 * math.cos(a)), round(CY + 3.2 * math.sin(a)), LUG)
    put(CX, CY, HUB_LIT)

    # The sparks, then their stepped halos (rule 5): each transparent 4-neighbour of a white or bright
    # spark gets a colour two tiers darker, so the glow steps down to dark orange. The fainter sparks
    # get no halo, so the spray stays a spray of separate dots, not a cloud.
    for x, y, tier in SPARKS:
        put(x, y, ACCENTS.get((x, y), SPARK[tier]))
    for x, y, tier in SPARKS:
        if (x, y) in ACCENTS or tier > 1:
            continue
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < W and 0 <= ny < H and px[nx, ny][3] == 0:
                put(nx, ny, SPARK[min(tier + 2, len(SPARK) - 1)])
    return im


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) != 1:
        print(__doc__, file=sys.stderr)
        return 2
    out = Path(argv[0])
    if out.exists():
        print(f"ERROR: {out} exists: never overwrite an earlier version", file=sys.stderr)
        return 1
    out.parent.mkdir(parents=True, exist_ok=True)
    draw().save(out, "PNG")
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
