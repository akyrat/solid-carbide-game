"""Script-drawn Bouncy Bumpers power-up icon (T-465, style loop version 2 onward). Free: no PixelLab call.

    python game/tools/draw_power_up_icon_bouncy_bumpers.py <out.png> [--v2 | --v3] [--preview <png>]

Draws version 4 by default (a ribbed rubber cushion instead of the coil); --v2 and --v3 redraw the
archived earlier versions pixel for pixel. Prints the bbox and colour count.

Version 1 (PixelLab) was a brick wall filling the frame with a magenta pillar in it, so the icon is
drawn here part by part, keeping v1's palette (magenta coil, cyan arcs, navy-grey bricks, near-black
outline) and the matched set's car green (the Jump icon's car):

- the car's front, side on, facing right: windshield, lit hood, dark green side, a cyan headlight
  with a stepped halo, a dark grille, a wheel, and a chrome bumper bar;
- a chrome mounting plate on the bumper and a big magenta coil spring of three clear loops,
  lying horizontally, pressed against
- a short navy-grey brick wall on the right;
- a cyan/white star burst at the contact point, and curved cyan impact arcs above and below the
  spring, each with a darker stepped halo (rule 5).

Light from the top-left; every part has its own near-black outline, broken by lighter highlight
pixels on its top-left edges (rule 2).
"""

from __future__ import annotations

import math
import sys

from PIL import Image

SIZE = 32

P = {
    "#": (14, 10, 22),      # outline, near-black
    "h": (104, 118, 169),   # outline broken by a lighter highlight (top-left)
    "A": (150, 214, 182),   # paint highlight
    "L": (47, 129, 88),     # lit hood
    "G": (25, 113, 69),     # body
    "g": (12, 76, 44),      # car's dark green
    "d": (6, 44, 26),       # body shade
    "Q": (190, 182, 240),   # glass glint
    "B": (95, 89, 135),     # glass
    "b": (41, 33, 74),      # grille / glass dark
    "t": (24, 19, 44),      # tyre
    "W": (241, 248, 251),   # chrome highlight, star core
    "r": (157, 158, 177),   # chrome
    "R": (96, 100, 128),    # chrome shade
    "c": (42, 213, 239),    # cyan
    "C": (207, 251, 247),   # cyan core (near white)
    "k": (30, 140, 180),    # cyan mid halo
    "K": (16, 66, 92),      # cyan dark halo
    "M": (247, 153, 248),   # magenta highlight
    "m": (220, 70, 200),    # magenta
    "n": (110, 34, 104),    # magenta shade
    "s": (92, 84, 138),     # lit brick
    "S": (59, 52, 97),      # brick
    "x": (30, 25, 50),      # mortar
}


class Canvas:
    def __init__(self):
        self.g = [["." for _ in range(SIZE)] for _ in range(SIZE)]

    def get(self, x, y):
        return self.g[y][x] if 0 <= x < SIZE and 0 <= y < SIZE else None

    def set(self, x, y, ch, only_empty=False):
        if 0 <= x < SIZE and 0 <= y < SIZE and (not only_empty or self.g[y][x] == "."):
            self.g[y][x] = ch

    def part(self, cells, outline=True, highlight_every=2):
        """cells: {(x, y): ch}. Draws the part, then its own outline ring around it (overwriting what is
        under the ring, so parts stay separate). Ring pixels on the part's top or left edge are broken by
        a highlight pixel every `highlight_every` pixels."""
        for (x, y), ch in cells.items():
            self.set(x, y, ch)
        if not outline:
            return
        ring = {}
        for (x, y) in cells:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = (x + dx, y + dy)
                if q in cells:
                    continue
                lit = dy == -1 or dx == -1
                ring[q] = ring.get(q, False) or lit
        for (x, y), lit in sorted(ring.items()):
            hl = lit and highlight_every and (x + y) % highlight_every == 0
            self.set(x, y, "h" if hl else "#")

    def image(self, palette=None):
        palette = palette or P
        im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        for y in range(SIZE):
            for x in range(SIZE):
                ch = self.g[y][x]
                if ch != ".":
                    im.putpixel((x, y), palette[ch] + (255,))
        return im


def _rows(spec):
    """{y: (x0, x1)} -> set of cells."""
    return {(x, y) for y, (x0, x1) in spec.items() for x in range(x0, x1 + 1)}


def _wall():
    cells = {}
    for y in range(4, 28):
        for x in range(25, 30):
            row = (y - 4) % 3
            if row == 2:
                ch = "x"
            else:
                joint = 27 if ((y - 4) // 3) % 2 == 0 else 28
                ch = "x" if x == joint else ("s" if x == 25 or row == 0 else "S")
            cells[(x, y)] = ch
    return cells


def _car():
    body = _rows({7: (2, 4), 8: (1, 5), 9: (1, 6), 10: (1, 8), 11: (1, 10), 12: (1, 10),
                  13: (1, 10), 14: (1, 10), 15: (1, 10)})
    cells = {}
    for (x, y) in body:
        if y <= 9 and x <= 5 - (9 - y) + 1:
            ch = "B"                          # windshield
        elif y == 10:
            ch = "A" if x in (6, 7) else "L"  # hood, lit
        elif y == 11:
            ch = "L"
        elif y in (12, 13):
            ch = "G"
        elif y == 14:
            ch = "g"
        else:
            ch = "d"
        cells[(x, y)] = ch
    for p in ((2, 7), (1, 8), (2, 8)):
        cells[p] = "Q"                        # glass glint (top-left)
    cells[(5, 8)] = "b"
    cells[(6, 9)] = "b"
    # headlight at the front with a stepped halo
    cells[(10, 12)] = "C"
    cells[(9, 12)] = "c"
    cells[(10, 13)] = "c"
    cells[(9, 13)] = "k"
    cells[(8, 12)] = "k"
    # grille
    for y in (14, 15):
        cells[(10, y)] = "b"
        cells[(9, y)] = "R" if y == 14 else "b"
    return cells


def _wheel():
    cells = {}
    cx, cy = 4.5, 19.5
    for y in range(16, 24):
        for x in range(1, 10):
            d = math.hypot(x - cx, y - cy)
            if d <= 3.6:
                cells[(x, y)] = "r" if d <= 1.2 else ("R" if d <= 1.9 else "t")
    return cells


def _bumper():
    cells = {}
    for y, ch in ((16, "W"), (17, "r"), (18, "r"), (19, "R")):
        for x in range(1 if y in (17, 18) else 2, 12):
            cells[(x, y)] = ch
    for y in range(12, 24):                   # mounting plate for the spring
        cells[(12, y)] = "W" if y <= 13 else ("r" if y <= 20 else "R")
    return cells


def _spring():
    """A helix of three loops lying along x: the back half of each turn in shade, the front half
    (drawn over it) lit from the top-left, each stroke 2 px thick."""
    x0, x1, cy, rad = 14.0, 23.4, 17.5, 5.6
    turns = 3.0
    back, front = {}, {}
    steps = 900
    for i in range(steps + 1):
        t = turns * 2 * math.pi * i / steps
        x = x0 + (x1 - x0) * i / steps
        y = cy - rad * math.cos(t)
        px, py = int(round(x)), int(round(y))
        if math.sin(t) > 0:
            front[(px, py)] = "M" if py <= 14 else ("m" if py <= 20 else "n")
        else:
            back.setdefault((px, py), "n")
    cells = dict(back)
    cells.update(front)
    return cells


def _arcs(cv):
    """Curved impact arcs around the contact point, above and below the spring, on empty pixels only."""
    cx, cy = 25.0, 17.5
    for r, core in ((8.0, "C"), (11.0, "c")):
        for y in range(SIZE):
            for x in range(SIZE):
                if not (y <= 9 or y >= 26) or x > 24 or x < 12:
                    continue
                d = math.hypot(x - cx, y - cy)
                if abs(d - r) <= 0.5:
                    cv.set(x, y, core, only_empty=True)
    for y in range(SIZE):
        for x in range(SIZE):
            ch = cv.get(x, y)
            if ch in ("C", "c") and (y <= 9 or y >= 26):
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    cv.set(x + dx, y + dy, "k" if ch == "C" else "K", only_empty=True)


def _star(cv):
    cx, cy = 25, 17
    cv.set(cx, cy, "W")
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        cv.set(cx + dx, cy + dy, "C")
        cv.set(cx + 2 * dx, cy + 2 * dy, "c")
        cv.set(cx + 3 * dx, cy + 3 * dy, "k")
    for dx, dy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        cv.set(cx + dx, cy + dy, "c")
        cv.set(cx + 2 * dx, cy + 2 * dy, "K")


def draw_v2():
    cv = Canvas()
    cv.part(_wall())
    cv.part(_wheel())
    cv.part(_car())
    cv.part(_bumper())
    cv.part(_spring())
    _arcs(cv)
    _star(cv)
    return cv.image()


# ---- version 3: bolder at 32 x 32 -------------------------------------------------------------
# The evaluator judges at native size, so v3 makes every read louder: a taller, brighter wall with a
# lit face, a bigger star burst, three impact arcs with stepped halos on both sides, a stepped magenta
# glow around the coil, brighter outline highlight pixels, and more shading steps on car and bumper.

P3 = dict(P)
P3.update({
    "h": (150, 162, 214),   # brighter highlight pixels in the outline
    "u": (150, 142, 200),   # wall's lit face (towards the light and the car)
    "p": (62, 18, 66),      # magenta glow, darkest step / coil back
    "e": (205, 214, 228),   # chrome mid-light
})


def _wall_v3():
    cells = {}
    for y in range(2, 30):
        for x in range(25, 30):
            row = (y - 2) % 3
            if row == 2:
                ch = "x"
            else:
                joint = 27 if ((y - 2) // 3) % 2 == 0 else 28
                if x == joint:
                    ch = "x"
                elif x == 25:
                    ch = "u"
                elif row == 0:
                    ch = "s"
                else:
                    ch = "S"
            cells[(x, y)] = ch
    return cells


def _car_v3():
    cells = _car()
    for x in range(1, 11):                    # door line and a sill ramp for more shading steps
        if cells.get((x, 13)) == "G" and x not in (9, 10):
            cells[(x, 13)] = "g" if x in (3, 7) else "G"
    cells[(2, 11)] = "A"
    cells[(3, 10)] = "A"
    return cells


def _wheel_v3():
    cells = _wheel()
    cells[(3, 18)] = "W"                      # rim glint, top-left
    return cells


def _bumper_v3():
    cells = {}
    for y, ch in ((16, "W"), (17, "e"), (18, "r"), (19, "R")):
        for x in range(1 if y in (17, 18) else 2, 12):
            cells[(x, y)] = ch
    cells[(3, 16)] = "W"
    for y in range(12, 24):                   # mounting plate for the spring
        cells[(12, y)] = "W" if y <= 13 else ("e" if y <= 16 else ("r" if y <= 20 else "R"))
    return cells


def _spring_v3():
    x0, x1, cy, rad = 14.0, 23.0, 17.5, 5.6
    turns = 3.0
    back, front = {}, {}
    steps = 900
    for i in range(steps + 1):
        t = turns * 2 * math.pi * i / steps
        x = x0 + (x1 - x0) * i / steps
        y = cy - rad * math.cos(t)
        px, py = int(round(x)), int(round(y))
        if math.sin(t) > 0:
            front[(px, py)] = "M" if py <= 15 else ("m" if py <= 20 else "n")
        else:
            back.setdefault((px, py), "p")
    cells = dict(back)
    cells.update(front)
    return cells


def _glow_ring(cv, cells, ch, dist):
    """Stepped halo: empty pixels exactly `dist` steps (4-neighbour) outside the part."""
    frontier = set(cells)
    seen = set(cells)
    for step in range(1, dist + 1):
        nxt = set()
        for (x, y) in frontier:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = (x + dx, y + dy)
                if q not in seen:
                    seen.add(q)
                    nxt.add(q)
        frontier = nxt
    for (x, y) in frontier:
        cv.set(x, y, ch, only_empty=True)


def _arcs_v3(cv, top=8, bottom=27):
    """Two thin impact arcs above and two below the coil, centred on the contact point; each is a
    bright core with darker steps outward (radially), so they stay separate lines."""
    cx, cy = 24.5, 17.5
    for r, core_ch, steps in ((9.0, "C", ("k", "K")), (12.0, "c", ("K",))):
        for y in range(1, 31):
            for x in range(11, 25):
                if not (y <= top or y >= bottom):
                    continue
                d = math.hypot(x - cx, y - cy)
                if abs(d - r) <= 0.5:
                    cv.set(x, y, core_ch, only_empty=True)
                else:
                    for i, ch in enumerate(steps, start=1):
                        if abs(d - (r + i)) <= 0.5:
                            cv.set(x, y, ch, only_empty=True)


def _star_v3(cv):
    cx, cy = 24, 17
    cv.set(cx, cy, "W")
    steps = ("W", "C", "c", "k", "K")
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        for i, ch in enumerate(steps[1:], start=1):
            cv.set(cx + i * dx, cy + i * dy, ch)
    for dx, dy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        cv.set(cx + dx, cy + dy, "C")
        cv.set(cx + 2 * dx, cy + 2 * dy, "k")
        cv.set(cx + 3 * dx, cy + 3 * dy, "K")


def draw():
    cv = Canvas()
    cv.part(_wall_v3())
    cv.part(_wheel_v3())
    cv.part(_car_v3())
    cv.part(_bumper_v3())
    spring = _spring_v3()
    cv.part(spring)
    _glow_ring(cv, spring, "n", 2)            # stepped magenta glow outside the coil's outline
    _arcs_v3(cv)
    _star_v3(cv)
    return cv.image(P3)


def draw_v3():
    return draw()


# ---- version 4: one clean symbol at 32 x 32 --------------------------------------------------
# v3's coil outline, with highlight breaks and a glow band, read as teeth at native size. v4 draws the
# spring as a chunky zigzag (two peaks) with clear gaps, a bright core and a darker edge, and only a
# few outline highlight breaks; no glow band around it.

def _zigzag_v4():
    pts = [(13.0, 17.5), (15.5, 12.0), (18.5, 23.0), (21.5, 12.0), (23.0, 17.5)]
    cells = {}
    for (xa, ya), (xb, yb) in zip(pts, pts[1:]):
        n = 200
        for i in range(n + 1):
            x = xa + (xb - xa) * i / n
            y = ya + (yb - ya) * i / n
            px, py = int(round(x)), int(round(y))
            cells[(px, py)] = "M" if py <= 15 else "m"
            cells.setdefault((px + 1, py), "n" if py >= 20 else "m")
    for (x, y), ch in list(cells.items()):   # the lit core stays lit, a shade pixel only to its right
        if ch == "m" and (x - 1, y) not in cells:
            cells[(x, y)] = "M" if y <= 15 else "m"
    return cells


def _cushion_v4():
    """A big ribbed rubber cushion (bellows), squashed against the wall: a rounded capsule lit from
    the top-left (light-magenta band), magenta body, shaded bottom, three dark rib grooves."""
    x0, x1, y0, y1, rad = 14, 23, 12, 23, 3
    cells = {}
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            cx = min(max(x, x0 + rad), x1 - rad)
            cy = min(max(y, y0 + rad), y1 - rad)
            if (x - cx) ** 2 + (y - cy) ** 2 > rad * rad + 1:
                continue
            if x in (17, 20):
                ch = "p" if y >= 15 else "n"          # rib grooves
            elif y <= 14:
                ch = "M"
            elif y >= 21:
                ch = "n"
            elif y == 15 and x in (15, 18, 21):
                ch = "M"                            # rib tops catch the light
            else:
                ch = "m"
            cells[(x, y)] = ch
    return cells


def draw_v4():
    cv = Canvas()
    cv.part(_wall_v3())
    cv.part(_wheel_v3())
    cv.part(_car_v3())
    cv.part(_bumper_v3())
    cv.part(_cushion_v4(), highlight_every=3)
    _arcs_v3(cv, top=10, bottom=25)
    _star_v3(cv)
    return cv.image(P3)


def info(im):
    cols = {p for p in im.getdata() if p[3]}
    return "bbox %s, %d colours" % (im.getbbox(), len(cols))


def preview(im, path, scale=8):
    """Enlarged (nearest-neighbour) copies on a dark and a light background, side by side."""
    big = im.resize((SIZE * scale, SIZE * scale), Image.NEAREST)
    out = Image.new("RGBA", (big.width * 2 + 16, big.height), (0, 0, 0, 0))
    for i, bg in enumerate(((20, 20, 28, 255), (230, 230, 230, 255))):
        b = Image.new("RGBA", big.size, bg)
        b.alpha_composite(big)
        out.paste(b, (i * (big.width + 16), 0))
    out.save(path)


def main(argv):
    args = argv[1:]
    prev = None
    if "--preview" in args:
        i = args.index("--preview")
        prev = args[i + 1]
        del args[i:i + 2]
    fn = draw_v4
    for flag, f in (("--v2", draw_v2), ("--v3", draw_v3)):
        if flag in args:
            args.remove(flag)
            fn = f
    if len(args) != 1:
        print(__doc__)
        return 2
    im = fn()
    print(info(im))
    im.save(args[0])
    if prev:
        preview(im, prev)
    print("wrote", args[0])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
