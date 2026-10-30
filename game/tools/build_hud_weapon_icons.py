#!/usr/bin/env python3
"""Draws the HUD's weapon icons: one row sheet of six 24 x 24 frames, shown at 2x (task T-429, goal G-008).

Each frame is a small redraw of the weapon's level-up card picture (game/art/level_up/weapon_<id>.png),
keeping its subject, silhouette and main colours, drawn to the HUD style sheet (Visual style, Decisions,
"The HUD style sheet"): 1x pixels with alpha 0 or 255, a 1 pixel outline in (8, 8, 15) round each icon,
two or three shading steps lit from the top left, a white glint on round things, no Greenbull light green
or yellow. Script-drawn, no PixelLab.

Run:
  python game/tools/build_hud_weapon_icons.py build [--out FILE.png]   the sheet (default game/art/hud/weapon_icons.png)
                                                                        and its json record beside it
  python game/tools/build_hud_weapon_icons.py sheet --out FILE.png      just the 144 x 24 sheet, no record
  python game/tools/build_hud_weapon_icons.py preview --out FILE.png    the cards and the icons enlarged, on dark and light
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
HUD_DIR = ROOT / "art" / "hud"
CARDS_DIR = ROOT / "art" / "level_up"
ORDER = ["gun", "flamethrower", "molotov", "bricks", "wiper", "underglow"]
FRAME = 24
OUTLINE = (8, 8, 15)
CLEAR = (0, 0, 0, 0)
GREENBULL = [(104, 220, 96), (247, 208, 52)]
WHITE = (255, 255, 255)

# The HUD's fire yellows (the burning likes bar, Visual style, "The HUD style sheet", rule 3).
FIRE_CORE = (255, 250, 209)
FIRE_YELLOW = (255, 224, 77)


class Canvas:
    """A 24 x 24 grid of colours (None = transparent). 'o' cells drawn with OUTLINE are inner lines."""

    RIM_SHARE = 0.10    # lighter pixels breaking the outline: under the sheet's 15% of the edge

    def __init__(self, size: int = FRAME, rim=None):
        self.size = size
        self.px: dict[tuple[int, int], tuple[int, int, int]] = {}
        self.rim = rim      # the colour of the highlight pixels that break the outline on the lit top-left side

    def put(self, x: int, y: int, c):
        if 0 <= x < self.size and 0 <= y < self.size and c is not None:
            self.px[(x, y)] = c

    def grid(self, x0: int, y0: int, rows: list[str], pal: dict[str, tuple]):
        for dy, row in enumerate(rows):
            for dx, ch in enumerate(row):
                if ch != ".":
                    self.put(x0 + dx, y0 + dy, pal[ch])

    def image(self) -> Image.Image:
        """Centres the drawing, adds the 1 pixel outline round it, returns the RGBA frame."""
        xs = [x for x, _ in self.px]
        ys = [y for _, y in self.px]
        w, h = max(xs) - min(xs) + 1, max(ys) - min(ys) + 1
        ox = (self.size - (w + 2)) // 2 + 1 - min(xs)
        oy = (self.size - (h + 2)) // 2 + 1 - min(ys)
        px = {(x + ox, y + oy): c for (x, y), c in self.px.items()}
        im = Image.new("RGBA", (self.size, self.size), CLEAR)
        for (x, y), c in px.items():
            im.putpixel((x, y), (*c, 255))
        ring = set()
        for (x, y) in list(px):
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (x + dx, y + dy)
                if n not in px and 0 <= n[0] < self.size and 0 <= n[1] < self.size:
                    im.putpixel(n, (*OUTLINE, 255))
                    ring.add(n)
        if self.rim:
            # Break the outline with lighter highlight pixels where the light hits: outline pixels on the
            # top or left of the drawing, in its top-left half, every other one, at most RIM_SHARE of the ring.
            sx = sum(x for x, _ in px) / len(px)
            sy = sum(y for _, y in px) / len(px)
            def flat(x, y):
                """On a straight run of the outline (a top edge or a left edge), so a lighter pixel there
                changes the outline's colour without making a bump in the silhouette."""
                top = (x, y + 1) in px and (x - 1, y) in ring and (x + 1, y) in ring \
                    and (x - 1, y + 1) in px and (x + 1, y + 1) in px
                left = (x + 1, y) in px and (x, y - 1) in ring and (x, y + 1) in ring \
                    and (x + 1, y - 1) in px and (x + 1, y + 1) in px
                step = (x, y + 1) in px and (x + 1, y) in px     # the inner corner of a diagonal staircase
                return top or left or step

            lit_side = sorted(
                ((x, y) for (x, y) in ring
                 if flat(x, y) and (x - sx) + (y - sy) < -2 and px.get((x, y + 1), px.get((x + 1, y))) == self.rim),
                key=lambda p: math.atan2(p[1] - sy, p[0] - sx))      # round the lit side, in order
            n = min(int(self.RIM_SHARE * len(ring)), (len(lit_side) + 2) // 3)
            for i in range(n):                                        # spread evenly, never side by side
                x, y = lit_side[int((i + 0.5) * len(lit_side) / n)]
                im.putpixel((x, y), (*self.rim, 255))
        return im


def lit(nx: float, ny: float) -> float:
    """How much a surface facing (nx, ny) catches the light from the top left (-1 .. 1)."""
    return (-nx - ny) / math.sqrt(2)


# ---------------------------------------------------------------- the six icons


def gun() -> Canvas:
    """The card's black pistol with its brown wood grip, muzzle to the right."""
    pal = {
        "G": (165, 152, 162),   # glint on the slide's top edge
        "L": (110, 102, 115),   # slide, lit top
        "S": (57, 52, 61),      # slide
        "K": (23, 18, 26),      # slide, shadow side
        "o": OUTLINE,           # serrations, muzzle, ejection port
        "w": (170, 110, 69),    # grip wood, lit
        "b": (111, 59, 27),     # grip wood
        "B": (68, 33, 13),      # grip wood, shadow
    }
    c = Canvas(rim=pal["L"])
    c.grid(0, 0, [
        ".GLLLLLLLLLLLLLLLLL.",
        "LLSSSSSSSSSSSSSSSSSL",
        "LSoSoSoSSSSoooSSSSSS",
        "SSoSoSoSSSSSSSSSSSSo",
        "SKKKKKKKKKKKKKKKKKKK",
        ".KSSSSSSSSSSSSSKKKK.",
        "..LwbbbbSK.K..K.....",
        "..wbbbbbBK..KK......",
        "..wbobbbB...........",
        ".wbbbobbB...........",
        ".wbobbbbB...........",
        ".wbbbobBB...........",
        "wbbobbbB............",
        "wbbbbbbB............",
        "BBBBBBB.............",
    ], pal)
    return c


def flamethrower() -> Canvas:
    """The card's flamethrower: a stepped steel nozzle on the left (wide body, narrower barrel, a muzzle ring),
    the flame leaving its mouth and flaring out to the right in jagged tongues."""
    steel = {"G": (163, 180, 203), "L": (114, 134, 150), "M": (68, 86, 101), "N": (53, 68, 81),
             "D": (37, 47, 55), "o": OUTLINE, "r": (186, 69, 7)}
    c = Canvas(rim=steel["L"])
    # The flame: a big round burst leaving the muzzle (x 8), flame tongues all round its rim, white-hot
    # next to the nozzle, then yellow, orange, red and a dark red rim.
    cx, cy = 13.5, 11.0
    for y in range(24):
        for x in range(8, 20):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            d = math.hypot(dx, dy)
            a = math.atan2(dy, dx)
            reach = 5.2 + (1.3 if math.cos(8 * a) > 0.2 else 0.0)
            neck = x < 11 and abs(dy) <= 2.0 + (x - 8) * 0.6     # where the flame leaves the muzzle
            if d > reach and not neck:
                continue
            core = math.hypot(dx + 3.0, dy * 1.1)                 # hottest towards the nozzle
            rim = reach - d
            if core < 2.4:
                col = FIRE_CORE
            elif core < 4.4:
                col = FIRE_YELLOW
            elif rim > 2.0:
                col = (253, 116, 1)
            elif rim > 0.8:
                col = (202, 3, 0)
            else:
                col = (111, 16, 4)
            c.put(x, y, col)
    # The nozzle, lit from the top left: the wide tank end, the barrel stepping down, the muzzle ring.
    c.grid(0, 7, [
        "GLLLL....",
        "LMMMMGLLG",
        "LMMMMLMML",
        "MMMMMMNNM",
        "MNNNNDDDN",
        "NDDDDDDDD",
        "DDDDD...D",
        "DDDD.....",
    ], steel)
    c.put(2, 6, steel["r"])       # the card's small orange valve on top of the tank
    c.put(3, 6, steel["r"])
    return c


def molotov() -> Canvas:
    """The card's green bottle with a brown rag in its neck and a flame on top."""
    glass = [(2, 86, 0), (1, 136, 0), (11, 201, 0)]   # shadow, body, lit
    glint = (236, 255, 231)
    rag = {"r": (149, 77, 50), "R": (74, 37, 24), "l": (173, 123, 95)}
    c = Canvas(rim=glass[2])
    # The body: a round flask.
    bx, by, br = 11.5, 14.5, 5.9
    for y in range(24):
        for x in range(24):
            dx, dy = x + 0.5 - bx, y + 0.5 - by
            d = math.hypot(dx * 0.88, dy)           # a round flask, a little wider than tall, like the card's
            if d > br - 0.2:                        # (- 0.2: no lone pixel bumps on the sides)
                continue
            k = lit(dx / br, dy / br)
            col = glass[2] if k > 0.45 else glass[1] if k > -0.35 else glass[0]
            c.put(x, y, col)
    # A white glint on the round body, top left: a short curved streak and a spark pixel.
    for (x, y) in ((8, 10), (7, 11), (6, 12), (6, 13)):
        c.put(x, y, WHITE)
    for (x, y) in ((9, 10), (7, 12), (7, 13), (6, 14)):
        c.put(x, y, glint)
    c.put(9, 12, WHITE)
    # The neck, with the rag stuffed in its mouth and tied round it, the end hanging to the right.
    for y in range(6, 10):
        c.put(10, y, glass[2])
        c.put(11, y, glass[1])
        c.put(12, y, glass[1])
        c.put(13, y, glass[0])
    c.grid(10, 5, [
        "lrrR",
    ], rag)
    c.grid(9, 7, [
        "lrrrrR.",
        "....RrR",
        ".....RR",
    ], rag)
    # The flame on the rag: a tall tongue, red outside, orange, a yellow heart.
    c.grid(8, 0, [
        "...AA...",
        "..AYA...",
        ".AYYYA..",
        ".AYWYYA.",
        "AYWWWYA.",
    ], {"A": (249, 57, 29), "Y": (252, 136, 0), "W": FIRE_YELLOW})
    return c


def bricks() -> Canvas:
    """The card's red-brown bricks: an isometric stack, light top, warm lit left face, dark right face."""
    top = [(232, 198, 163), (226, 168, 150), (193, 144, 126)]   # lit rim, top, top in the far half
    left_l = (226, 168, 150)
    left = (213, 123, 91)
    left_d = (171, 80, 61)
    right_l = (164, 76, 59)
    right = (137, 64, 53)
    right_d = (101, 44, 43)
    mortar = (83, 34, 35)
    c = Canvas(rim=top[0])
    x0, x1, xm = 1, 21, 11          # left edge, right edge, front corner
    yt, half, height = 6, 5, 10     # the top face's centre row, its half height, the sides' height
    for y in range(24):
        for x in range(x0, x1):
            px, py = x + 0.5, y + 0.5
            if abs(px - xm) / (xm - x0) + abs(py - yt) / half <= 1.0:
                # The top: two rows of brick tops, split along the left-to-back axis.
                u = (px - x0) * 0.5 + (py - yt)       # across the top, 0 at the left-front edge
                c.put(x, y, mortar if abs(u - 5.0) < 0.5 else top[1] if u < 5 else top[2])
                if py < yt + 0.5 and px < xm and abs(px - xm) / (xm - x0) + abs(py - yt) / half > 0.72:
                    c.put(x, y, top[0])                # the lit top-left rim
                continue
            if px <= xm:
                ytop = yt + (px - x0) * half / (xm - x0)
                v = py - ytop
                if 0 <= v <= height:
                    row = int(v) // 3
                    joint = (int(v) % 3 == 2 and v < 9) or ((x - x0 + (3 if row % 2 else 0)) % 6 == 5)
                    # Three steps, lit from the top left: each brick's top row and the face's left edge catch
                    # the light, the brick's body is the face colour, the lowest course falls into shadow.
                    if joint:
                        col = mortar
                    elif x == x0 or int(v) % 3 == 0:
                        col = left_l if row < 3 else left
                    else:
                        col = left if row < 2 else left_d
                    c.put(x, y, col)
            else:
                ytop = yt + half - (px - xm) * half / (x1 - xm)
                v = py - ytop
                if 0 <= v <= height:
                    row = int(v) // 3
                    joint = (int(v) % 3 == 2 and v < 9) or ((x - xm + (2 if row % 2 else 5)) % 6 == 5)
                    # The shadow side, three steps: brick tops a little lit, bodies dark, the bottom right darkest.
                    if joint:
                        col = mortar
                    elif int(v) % 3 == 0 and row < 3:
                        col = right_l
                    elif row >= 2 or x >= x1 - 2:
                        col = right_d
                    else:
                        col = right
                    c.put(x, y, col)
    return c


def wiper() -> Canvas:
    """The card's dark purple-grey wiper arm and blade, lying diagonally from the bottom left to the top right."""
    # The card's purple-greys, from its brightest: glint, lit edge, face, body, shadow, rubber.
    glint, edge, face, body, dark, deep = (195, 188, 205), (159, 153, 172), (110, 105, 124), (81, 77, 95), \
        (49, 44, 61), (30, 23, 40)
    c = Canvas(rim=edge)
    sx, sy = 3.0, 20.0                       # the pivot end
    ux, uy = 1 / math.sqrt(2), -1 / math.sqrt(2)
    nx, ny = 1 / math.sqrt(2), 1 / math.sqrt(2)
    for y in range(24):
        for x in range(24):
            px, py = x + 0.5 - sx, y + 0.5 - sy
            t = px * ux + py * uy
            s = px * nx + py * ny
            if not 1.0 <= t <= 23.2:
                continue
            # The arm in three steps: a lit top-left edge with glints, its face, a dark bottom-right edge.
            if -2.3 <= s < -1.3:
                c.put(x, y, glint if int(t) % 5 == 2 else edge)
            elif -1.3 <= s < -0.3:
                c.put(x, y, face)
            elif -0.3 <= s < 0.6:
                c.put(x, y, dark)
            elif 0.6 <= s < 1.3 and t > 6.0:
                clip = int(t) % 5 == 0                    # the clips holding the blade to the arm
                c.put(x, y, face if clip else OUTLINE)
            elif 1.3 <= s < 3.1 and t > 6.0:
                # The rubber blade, three steps too: a lit edge, its body, deep shadow at the bottom right.
                c.put(x, y, face if s < 1.9 else body if s < 2.5 else dark)
    # The pivot cap at the bottom left: round, with a glint.
    for y in range(24):
        for x in range(24):
            dx, dy = x + 0.5 - 4.0, y + 0.5 - 19.0
            d = math.hypot(dx, dy)
            if d <= 3.2:
                k = lit(dx / 3.2, dy / 3.2)
                c.put(x, y, edge if k > 0.4 else face if k > -0.4 else dark)
    c.put(3, 17, WHITE)          # the glint on the round cap
    c.put(2, 18, glint)
    c.put(4, 19, deep)           # the pivot bolt
    return c


def underglow() -> Canvas:
    """The card's dark blue car over its pink-violet glow."""
    # Drawn glow (rule 5): the light comes from under the car, so the glow is brightest right against the car
    # (white-pink core pixels) and steps down, one pixel at a time, through darker shades to a deep purple rim.
    glow = [(251, 228, 248), (240, 179, 252), (238, 122, 250), (203, 61, 216), (114, 30, 172), (90, 16, 114)]
    steps = [1.5, 2.5, 3.5, 4.5, 5.5]
    car = Canvas()
    c = Canvas(rim=(62, 141, 252))   # the car's lit blue edge
    pal = {
        "h": (62, 141, 252),    # lit edges
        "m": (50, 31, 126),     # body
        "d": (19, 1, 79),       # body, shadow
        "w": (50, 85, 193),     # windows
        "g": (240, 179, 252),   # glint on the glass
        "W": (251, 228, 248),   # headlight
        "P": (234, 81, 244),    # tail light
        "t": (35, 17, 104),     # tyres, lit by the glow from below
        "T": (12, 3, 21),       # tyres, shadow
        "o": OUTLINE,
    }
    # The car from above at three quarters, nose to the right: roof and windows in the middle, the near side dark.
    # A low sports car: a spoiler at the back (left), the roof between the rear window and a raked windshield,
    # a long hood to the headlights (right); lit blue edges on top, the near side in shadow.
    pal["r"] = pal["m"]         # the roof, body-coloured (a lighter roof read as a screen)
    car.grid(4, 5, [
        "h..TT......TT..",
        "hhhhhhhhhhhhhh.",
        "hmwwrrrrwwmmmmh",
        "mwgrrrrrrwgmmmW",
        "Pwgrrrrrrwwmmmm",
        "Pmwwrrrrwwmmmmm",
        "mmmmmmmmmmmmmmW",
        "ddddddddddddddd",
        ".tT........tT..",
    ], pal)
    gx, gy, ga, gb = 11.5, 13.5, 9.6, 6.5
    body = list(car.px)
    for y in range(24):
        for x in range(24):
            if ((x + 0.5 - gx) / ga) ** 2 + ((y + 0.5 - gy) / gb) ** 2 > 1.0 or (x, y) in car.px:
                continue
            d = min(math.hypot(x - bx, y - by) for bx, by in body)
            c.put(x, y, glow[sum(d >= s for s in steps)])
    # A few sparkle pixels in the halo, the brightest points of the light on the asphalt.
    for (x, y) in ((3, 16), (19, 15), (8, 18), (15, 18)):
        if (x, y) in c.px:
            c.put(x, y, WHITE)
    c.px.update(car.px)
    return c


DRAW = {"gun": gun, "flamethrower": flamethrower, "molotov": molotov, "bricks": bricks,
        "wiper": wiper, "underglow": underglow}


def frame(weapon: str) -> Image.Image:
    return DRAW[weapon]().image()


def draw() -> Image.Image:
    """The 144 x 24 row sheet, frames in ORDER."""
    sheet = Image.new("RGBA", (FRAME * len(ORDER), FRAME), CLEAR)
    for i, w in enumerate(ORDER):
        sheet.alpha_composite(frame(w), (i * FRAME, 0))
    return sheet


def record(out: Path) -> dict:
    return {
        "task": "T-429",
        "what": "The HUD's weapon icons: one 24 x 24 icon per weapon, a small redraw of its level-up card picture, "
                "shown at 2x in the weapon column's 48 x 48 slot (game/scripts/hud/weapon_icons.gd).",
        "size": [FRAME * len(ORDER), FRAME],
        "frames": len(ORDER),
        "frame_size": [FRAME, FRAME],
        "frame_order": ORDER,
        "shown_at_scale": 2,
        "made_by": "game/tools/build_hud_weapon_icons.py build (script-drawn)",
        "style_loop": {
            "brief": "art-archive/T-429/briefs/weapon_icons.md",
            "versions": "art-archive/T-429/style-loop/",
            "review": "tasks/T-429-the-hud-s-code-follows-the.md, Style review",
        },
        "pixellab_generations": 0,
        "references": [
            "docs/visual-style.md (Content, Rules; Decisions, The HUD style sheet)",
            "docs/extended-narrative.md",
            "game/art/level_up/weapon_<id>.png (the card pictures)",
            "game/art/hud/heart_full.png",
            "game/tools/hud_sheet_check.py",
        ],
    }


def build(out: Path, with_record: bool = True) -> Path:
    out.parent.mkdir(parents=True, exist_ok=True)
    draw().save(out)
    if with_record:
        out.with_suffix(".json").write_text(json.dumps(record(out), indent=1) + "\n", encoding="utf-8")
    return out


def preview(out: Path, scale: int = 8) -> Path:
    """Cards (64 x 64, shown at 3x) above their icons (24 x 24 at the scale), on a dark and a light background."""
    cell = FRAME * scale
    w = cell * len(ORDER) + 8 * (len(ORDER) + 1)
    h = 2 * (64 * 3 + cell + 24)
    im = Image.new("RGBA", (w, h), (24, 26, 34, 255))
    im.paste((228, 228, 232, 255), (0, h // 2, w, h))
    for band in range(2):
        y0 = band * h // 2 + 8
        for i, wpn in enumerate(ORDER):
            x0 = 8 + i * (cell + 8)
            card = Image.open(CARDS_DIR / f"weapon_{wpn}.png").convert("RGBA").resize((192, 192), Image.NEAREST)
            im.alpha_composite(card, (x0, y0))
            im.alpha_composite(frame(wpn).resize((cell, cell), Image.NEAREST), (x0, y0 + 192 + 8))
    out.parent.mkdir(parents=True, exist_ok=True)
    im.save(out)
    return out


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["build", "sheet", "preview", "info"])
    ap.add_argument("--out", type=Path)
    a = ap.parse_args(argv)
    if a.cmd == "info":
        for w in ORDER:
            f = frame(w)
            x0, y0, x1, y1 = f.getbbox()
            cols = {p for p in f.getdata() if p[3] == 255}
            n = sum(1 for p in f.getdata() if p[3] == 255)
            print(f"{w:13s} {x1 - x0:2d} x {y1 - y0:2d}  long side {max(x1 - x0, y1 - y0)}  "
                  f"{n} opaque px  {len(cols)} colours  margins l{x0} r{24 - x1} t{y0} b{24 - y1}")
        return 0
    if a.cmd == "build":
        print(build(a.out or HUD_DIR / "weapon_icons.png"))
    elif a.cmd == "sheet":
        print(build(a.out, with_record=False))
    else:
        print(preview(a.out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
