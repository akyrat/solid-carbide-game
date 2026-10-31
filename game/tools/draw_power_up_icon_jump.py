"""Script-drawn Jump power-up icon (T-465, style loop version 2 onward). Free: no PixelLab call.

    python game/tools/draw_power_up_icon_jump.py <out.png>

Version 1 (PixelLab, recoloured by build_power_up_icon_jump.py) read as a blob on a pedestal, so the
icon is drawn here part by part, keeping v1's idea and palette (dark green car, cyan/magenta pad,
near-black outline, purple-grey steel):

- the car: the 1967 fastback in 3/4 view (top deck with two white stripes and a gap, windows,
  the side, two wheels), near-black outline broken by blue-grey highlight pixels on the top-left,
  light from the top-left, a cyan headlight at the front and a magenta tail light;
- three short upward motion streaks under it (cyan, magenta, cyan), brightest at the car,
  each with a stepped darker halo; a clear gap;
- the bounce pad: a flat neon ellipse with the car's dark shadow in its middle, a magenta inner ring,
  a cyan outer ring and two stepped halo bands outside its outline (rule 5), on a steel base.
"""

from __future__ import annotations

import sys

from PIL import Image

SIZE = 32

P = {
    "#": (14, 10, 22),      # outline, near-black
    "h": (104, 118, 169),   # outline broken by a lighter highlight (top-left)
    "A": (150, 214, 182),   # paint highlight
    "L": (47, 129, 88),     # lit top deck
    "G": (25, 113, 69),     # top deck
    "g": (12, 76, 44),      # car's dark green (side)
    "d": (6, 44, 26),       # side shade (bottom right)
    "W": (241, 248, 251),   # stripe
    "w": (190, 200, 214),   # stripe shade
    "Q": (190, 182, 240),   # glass glint
    "B": (95, 89, 135),     # glass
    "b": (41, 33, 74),      # glass dark / pillars
    "t": (24, 19, 44),      # tyre
    "r": (157, 158, 177),   # rim
    "c": (42, 213, 239),    # cyan
    "C": (207, 251, 247),   # cyan core (near white)
    "k": (30, 140, 180),    # cyan mid halo
    "K": (16, 66, 92),      # cyan dark halo
    "M": (247, 153, 248),   # magenta core
    "m": (220, 70, 200),    # magenta
    "n": (110, 34, 104),    # magenta dark halo
    "S": (59, 52, 97),      # pad steel
    "s": (81, 73, 124),     # pad steel lit
    "x": (34, 28, 56),      # car's shadow on the pad
}


def _car_rows():
    """Car rows as (y, x0, string); '.' inside a string is transparent."""
    rows = [
        (3, 12, "hhhhhhh##"),
        (4, 10, "hhALLLLLGg#"),
        (5, 8, "hQQBBBBbBBBBb#"),
        (6, 5, "hhhQBBBBBBbBBBBBBb##"),
        (7, 4, "hA" + "L" * 19 + "Gg#"),
        (8, 4, "hL" + "W" * 17 + "wwGc#"),
        (9, 4, "#m" + "G" * 19 + "cC#"),
        (10, 4, "#m" + "w" + "W" * 16 + "wwGc#"),
        (11, 4, "#d" + "G" * 20 + "g#"),
        (12, 4, "#" + "g" * 21 + "d#"),
        (13, 4, "#" + "g" * 21 + "d#"),
        (14, 5, "#" * 22),
    ]
    return rows


WHEEL = ["#tt#", "tArt", "trrt", "#tt#"]
WHEEL_X = (7, 20)
WHEEL_Y = 12
PAD_TOP = 22  # first row of the pad's halo; the pad's outline starts one row below
TILT = 0.16 # nose-up: each column right of the centre is lifted by this many px per px


def _streaks_v3(px):
    """v3: brighter, longer streaks, starting 1 px under the car, with two-step halos."""
    for x, cols, mid, dark in (
        (10, "CCcck", "k", "K"),
        (15, "MMmmn", "m", "n"),
        (20, "CCcck", "k", "K"),
    ):
        y0 = max(y for (cx, y) in px if abs(cx - x) <= 1) + 2
        n = min(len(cols), PAD_TOP - 1 - y0)
        for i in range(n):
            px[(x, y0 + i)] = cols[i]
        for i in range(min(2, n)):
            for dx in (-1, 1):
                px.setdefault((x + dx, y0 + i), mid if i == 0 else dark)


def _close_outline(car):
    """Close the 1 px outline around the tilted car; top-left-facing outline pixels are broken by
    lighter highlight pixels every other pixel (rule 2)."""
    solid = dict(car)
    add = {}
    for (x, y), ch in solid.items():
        if ch in "#h":
            continue
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy)
            if q in solid or q in add:
                continue
            # a diagonal outline neighbour already closes it (8-connected outline): don't thicken
            if any(solid.get((q[0] + ax, q[1] + ay), ".") in "#h"
                   for ax in (-1, 0, 1) for ay in (-1, 0, 1) if (ax, ay) != (0, 0)):
                continue
            top_left = dx < 0 or dy < 0
            add[q] = "h" if top_left and (q[0] + q[1]) % 2 == 0 else "#"
    car.update(add)
    # existing outline pixels on the top-left of the silhouette: break every other one too
    for (x, y), ch in list(car.items()):
        if ch == "#" and ((x - 1, y) not in car or (x, y - 1) not in car) and y < 9 and (x + y) % 2 == 0:
            car[(x, y)] = "h"
    return car


def _light_halos(car):
    """Stepped halos (rule 5) around the cyan headlight (front, right) and magenta tail light (rear)."""
    lit_rows = {y for (x, y), ch in car.items() if ch in "cC"}
    for y in lit_rows:
        xr = max(x for (x, yy) in car if yy == y)
        for dx, k in ((1, "k"), (2, "K")):
            if xr + dx < SIZE:
                car[(xr + dx, y)] = k
    for (x, y), ch in list(car.items()):
        if ch == "m" and x < 8:
            for dx, k in ((-2, "n"),):
                q = (x + dx, y)
                if q not in car:
                    car[q] = k


def _streaks(px):
    # (x, top y, length, colours bright->dark, halo)
    for x, n, cols, halo in (
        (10, 3, "Cck", "K"),
        (15, 4, "MMmn", "n"),
        (20, 4, "Ccck", "K"),
    ):
        # start 2 px under the car's lowest pixel near this column
        y0 = max(y for (cx, y) in px if abs(cx - x) <= 1) + 2
        n = min(n, PAD_TOP - 1 - y0)  # end 2 rows above the pad's halo, leaving a clear gap
        for i in range(n):
            px[(x, y0 + i)] = cols[i] if i < len(cols) else cols[-1]
        # stepped halo: beside the two brightest pixels, dark shade; one mid pixel tail
        for i in range(2):
            for dx in (-1, 1):
                px.setdefault((x + dx, y0 + i), halo)


def _pad(px):
    cx, cy, rx, ry = 15.5, PAD_TOP + 4.0, 11.6, 2.7
    top = {}
    for y in range(SIZE):
        for x in range(SIZE):
            d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if d <= 1.0:
                top[(x, y)] = d
    # steel side of the pad: 1 px below the top ellipse
    for (x, y) in list(top):
        for k in (1,):
            if (x, y + k) not in top:
                px.setdefault((x, y + k), "S" if x > cx - 4 else "s")
    for (x, y), d in top.items():
        lit = (x - cx) / rx + (y - cy) / ry < -0.3  # top-left of the ring catches the light
        if d <= 0.30:
            px[(x, y)] = "x"            # the car's shadow on the pad
        elif d <= 0.45:
            px[(x, y)] = "n"
        elif d <= 0.62:
            px[(x, y)] = "M" if lit else "m"
        elif d <= 0.80:
            px[(x, y)] = "C" if lit else "c"
        else:
            px[(x, y)] = "k"
    # outline around top + side
    body = set(px_k for px_k in px if px_k[1] >= PAD_TOP)
    outline = set()
    for (x, y) in body:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy)
            if q not in body and 0 <= q[0] < SIZE and 0 <= q[1] < SIZE and q[1] >= PAD_TOP:
                outline.add(q)
    for q in outline:
        px[q] = "#"
    # rule 5: stepped halos above the pad's rim, dark cyan then dark magenta, broken (every other pixel)
    halo1 = set()
    for (x, y) in outline:
        q = (x, y - 1)
        if q not in px and y - 1 >= PAD_TOP:
            halo1.add(q)
    for (x, y) in halo1:
        px[(x, y)] = "n" if 10 <= x <= 21 and x % 2 else "K"
    # and at the pad's two ends, a dark cyan step outside the outline
    for y in range(PAD_TOP + 2, PAD_TOP + 8):
        row = [x for (x, yy) in outline if yy == y]
        if row:
            for q, k in (((min(row) - 1, y), "K"), ((max(row) + 1, y), "K")):
                if 0 <= q[0] < SIZE and q not in px:
                    px[q] = k


def _car():
    car = {}
    for y, x0, s in _car_rows():
        for i, ch in enumerate(s):
            if ch != ".":
                car[(x0 + i, y)] = ch
    for wx in WHEEL_X:
        for j, s in enumerate(WHEEL):
            for i, ch in enumerate(s):
                car[(wx + i, WHEEL_Y + j)] = ch
    # tilt nose-up by shifting whole columns (keeps hard pixels, no rotation blur)
    tilted = {}
    for (x, y), ch in car.items():
        tilted[(x, y - round((x - 15.5) * TILT))] = ch
    return tilted


def draw(version=3):
    px = _car()
    if version >= 3:
        _close_outline(px)
        _light_halos(px)
        _streaks_v3(px)
    else:
        _streaks(px)
    _pad(px)
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    for (x, y), k in px.items():
        if 0 <= x < SIZE and 0 <= y < SIZE:
            im.putpixel((x, y), P[k] + (255,))
    return im


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    version = 3
    if "--v2" in argv:
        argv = [a for a in argv if a != "--v2"]
        version = 2
    if len(argv) != 1:
        print(__doc__)
        return 2
    im = draw(version)
    im.save(argv[0])
    print({"bbox": im.getbbox(), "colours": len({p for p in im.getdata() if p[3]})})
    return 0


if __name__ == "__main__":
    sys.exit(main())
