#!/usr/bin/env python3
"""The seven trick illustrations, drawn by script (task T-383; Visual style, Decisions, "Script-drawn trick illustrations").

Each is a still 64 x 48 pixel picture (the size in game/docs/hud-and-menus/tutorial-slides.md) showing the car's
movement as a path: a long curve (extended drift), a loop (360), an S (alternate drift), a dashed jump arc with a half
or a full turn drawn round the car (air 180, air 360), a high arc (airtime), a straight line between two obstacles
(thread the needle). The car is the Mustang in Greenbull's dark green with two white stripes and a gap (Visual style,
Rules, rule 10); the ground tricks run on a strip of night asphalt with twin neon pink tire marks; the air tricks have
a dashed neon cyan path. Transparent background, hard edges, opaque or empty pixels only, a dark selective outline
broken by lighter pixels, stepped glow halos, no Greenbull light green or yellow. No PixelLab (0 generations).
Deterministic.

  python game/tools/build_trick_illustrations.py build --out art-archive/T-383/script [--only ID] [--force]
  python game/tools/build_trick_illustrations.py build --only ID --file path/to/version.png
  python game/tools/build_trick_illustrations.py sheet --out sheet.png --bg dark|light|R,G,B [--scale 4]
"""
from __future__ import annotations

import argparse
import math
from pathlib import Path

from PIL import Image

W, H = 64, 48
TRICK_IDS = ["extended_drift", "three_sixty", "alternate_drift", "air_one_eighty",
             "air_three_sixty", "airtime", "thread_the_needle",
             "reverse_drift", "aura", "rail_grind"]       # the last three: T-543

OUT = (12, 10, 26)          # near-black outline
OUT_L = (70, 60, 120)       # lighter pixels breaking the outline on the lit (upper) side
PINK = (255, 90, 190)       # tire marks, neon pink
PINK_D = (170, 40, 130)     # older, darker part of the marks
PINK_H = (100, 28, 96)      # pink glow halo (darkest step)
PINK_W = (255, 205, 235)    # hot core near the car
CYAN = (70, 230, 255)       # air path and turn marks, neon cyan
CYAN_D = (30, 130, 190)
CYAN_H = (22, 66, 118)      # cyan glow halo
WHITE = (245, 245, 250)     # stripes
STRIPE_D = (190, 196, 215)
GREEN = (12, 76, 44)        # Greenbull's dark green: the car's body
GREEN_L = (32, 112, 68)     # lit panel
GREEN_D = (6, 44, 26)       # shaded side
GLASS = (110, 190, 225)
LIGHT = (205, 240, 255)     # headlights (pale blue-white, not Greenbull's yellow)
TAIL = (255, 70, 110)       # tail lights
ASPH = (36, 38, 72)         # night asphalt (lighter than the outline, so the outline reads)
ASPH_L = (60, 64, 110)
LANE = (170, 176, 200)      # pale lane dashes on the asphalt
GREEN_S = (8, 58, 34)       # the car's side face
ASPH_D = (18, 18, 40)        # the road's shaded front face (3/4 view depth)
CYAN_W = (200, 250, 255)     # cyan highlight pixel
ROCK = (74, 52, 120)        # obstacles: the boulders' purple
ROCK_L = (130, 70, 170)
ROCK_D = (38, 28, 74)
GROUND = (60, 70, 120)
GROUND_L = (100, 120, 180)


class Canvas:
    def __init__(self):
        self.px: dict[tuple[int, int], tuple[int, int, int]] = {}

    def put(self, x, y, c):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < W and 0 <= y < H:
            self.px[(x, y)] = c

    def blit(self, mask):
        for (x, y), c in mask.items():
            if 0 <= x < W and 0 <= y < H:
                self.px[(x, y)] = c

    def ring(self, cells, colour, only_empty=True):
        """Colour the empty cells next to `cells` (8 neighbours); returns the cells coloured."""
        new = set()
        for (x, y) in cells:
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    p = (x + dx, y + dy)
                    if p not in cells and 0 <= p[0] < W and 0 <= p[1] < H and (not only_empty or p not in self.px):
                        new.add(p)
        for p in new:
            self.px[p] = colour
        return new

    def outline(self, cells, halo=None):
        """A near-black outline round `cells`, with an optional glow halo between; lighter pixels break it on top."""
        cells = set(cells)
        if halo is not None:
            cells |= self.ring(cells, halo)
        for p in self.ring(cells, OUT):
            if (p[0], p[1] + 1) in cells and p[0] % 3 == 0:
                self.px[p] = OUT_L

    def image(self):
        im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        for (x, y), c in self.px.items():
            im.putpixel((x, y), c + (255,))
        return im


def sample(fn, t0, t1, n=300):
    return [fn(t0 + (t1 - t0) * i / n) for i in range(n + 1)]


def _cells(pts, radius):
    out = set()
    r = int(math.ceil(radius))
    for x, y in pts:
        cx, cy = int(round(x)), int(round(y))
        for dx in range(-r, r + 1):
            for dy in range(-r, r + 1):
                if dx * dx + dy * dy <= radius * radius:
                    out.add((cx + dx, cy + dy))
    return {p for p in out if 0 <= p[0] < W and 0 <= p[1] < H}


def _offset_points(pts, offset):
    """The path moved sideways by `offset` pixels (along its normal)."""
    n = len(pts)
    out = []
    for i, (x, y) in enumerate(pts):
        a, b = pts[max(i - 2, 0)], pts[min(i + 2, n - 1)]
        d = math.hypot(b[0] - a[0], b[1] - a[1]) or 1.0
        out.append((x - offset * (b[1] - a[1]) / d, y + offset * (b[0] - a[0]) / d))
    return out


def draw_road(cv, pts, radius=7.0, lane=True, kerb=False):
    """A strip of night asphalt under a ground trail: lit along its upper edge, a shaded front face below it (the 3/4
    view's depth), white lane dashes along one side, and a near-black outline broken by lighter pixels. `kerb` lines
    the lit edge with neon cyan (hot white-cyan pixels in it) and a two-step glow under it on the asphalt."""
    cells = _cells(pts, radius)
    face = {(x, y + d) for (x, y) in cells for d in (1, 2) if (x, y + d) not in cells and y + d < H}
    cv.blit({p: ASPH_D for p in face})
    cv.blit({p: (ASPH_L if (p[0], p[1] - 1) not in cells else ASPH) for p in cells})
    if kerb:
        for (x, y) in [p for p in cells if (p[0], p[1] - 1) not in cells]:
            cv.px[(x, y)] = CYAN_W if x % 5 == 2 else CYAN
            for d, c in ((1, CYAN_D), (2, CYAN_H)):
                if (x, y + d) in cells and cv.px.get((x, y + d)) == ASPH:
                    cv.px[(x, y + d)] = c
    if lane:                                                   # lane dashes: 3 on, 4 off, by distance along the road
        total, last = 0.0, None
        for (x, y) in _offset_points(pts, radius - 2.2):
            if last is not None:
                total += math.hypot(x - last[0], y - last[1])
            last = (x, y)
            p = (int(round(x)), int(round(y)))
            if p in cells and int(total) % 7 < 3 and cv.px.get(p) in (ASPH, ASPH_L):
                cv.px[p] = WHITE                               # white lane dashes (rule 10: asphalt, white lines)
    cv.outline(cells | face)
    for p, c in list(cv.px.items()):                           # extra light breaks along the road's top outline
        if c == OUT and (p[0], p[1] + 1) in cells and p[0] % 4 == 1:
            cv.px[p] = OUT_L


def draw_tire_marks(cv, pts, offset=2.0):
    """Twin neon pink tire marks: broken and darker where old, brighter with a hot core near the car, with a stepped
    glow on the asphalt (a dark pink halo step beside each mark, never blurred)."""
    n = len(pts)
    marks = {}
    for side in (-1, 1):
        for i, (x, y) in enumerate(pts):
            a, b = pts[max(i - 2, 0)], pts[min(i + 2, n - 1)]
            d = math.hypot(b[0] - a[0], b[1] - a[1]) or 1.0
            nx, ny = -(b[1] - a[1]) / d, (b[0] - a[0]) / d
            p = (int(round(x + side * offset * nx)), int(round(y + side * offset * ny)))
            f = i / n
            if f < 0.3 and (i // 3) % 4 == 3:
                continue                                     # broken where old
            hot = f > 0.88 or (f > 0.6 and i % 9 == 0)       # bright core pixels: solid near the car, spaced before
            marks[p] = PINK_D if f < 0.4 else (PINK_W if hot else PINK)
    road = (ASPH, ASPH_L, ASPH_D, None)
    halo, halo2 = {}, {}
    for (x, y), c in marks.items():                            # stepped glow on the asphalt: PINK_D, then PINK_H
        if c == PINK_D:
            continue                                           # old marks: no glow
        for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if q not in marks and cv.px.get(q) in road:
                halo[q] = PINK_D if c == PINK_W else PINK_H
    for (x, y), c in halo.items():
        if c != PINK_D:
            continue
        for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if q not in marks and q not in halo and cv.px.get(q) in road:
                halo2[q] = PINK_H
    cv.blit(halo2)
    cv.blit(halo)
    cv.blit(marks)


def draw_dashed(cv, pts, colours=(CYAN_D, CYAN), dash=(4, 3), glow_steps=1):
    """A dashed neon cyan path (the air), 2 pixels wide, with a halo and an outline. glow_steps=2 adds a hot white-cyan
    pixel in each bright dash and a mid cyan step inside the dark halo (a two-step glow), where the frame has room."""
    n = len(pts)
    cells = {}
    total, last = 0.0, None
    for i, (x, y) in enumerate(pts):
        if last is not None:
            total += math.hypot(x - last[0], y - last[1])
        last = (x, y)
        if int(total) % (dash[0] + dash[1]) >= dash[0]:
            continue
        c = colours[1] if i > n * 0.35 else colours[0]
        for dx, dy in ((0, 0), (1, 0), (0, 1)):
            cells[(int(round(x)) + dx, int(round(y)) + dy)] = c
        if glow_steps > 1 and c == colours[1] and int(total) % (dash[0] + dash[1]) == 1:
            cells[(int(round(x)), int(round(y)))] = CYAN_W            # a hot pixel in each bright dash
    cv.blit(cells)
    inner = set(cells)
    if glow_steps > 1:
        inner |= cv.ring(inner, CYAN_D)                               # the mid step of the glow
    cv.outline(inner, halo=CYAN_H)
    return cells


CAR_HALF_L, CAR_HALF_W = 9.0, 4.8     # the car's top: about 18 x 10 pixels before its outline
CAR_SIDE = 3                          # pixels of side face under the top: the 3/4 view


def _car_local(px, py, x, y, ca, sa, scale):
    """Screen pixel centre -> the car's own (u along the nose, v across) coordinates."""
    dx, dy = px - x, py - y
    return (dx * ca + dy * sa) / scale, (-dx * sa + dy * ca) / scale


def _in_car(u, v):
    au, av = abs(u), abs(v)
    if au > CAR_HALF_L or av > CAR_HALF_W:
        return False
    if au > CAR_HALF_L - 1.2 and av > CAR_HALF_W - 1.0:     # rounded corners
        return False
    return not (u > CAR_HALF_L - 0.6 and av > CAR_HALF_W - 1.8)  # a slightly narrower nose


def draw_car(cv, x, y, angle, scale=1.0):
    """The Mustang fastback, about 16 x 9 pixels seen from above at an angle, nose along `angle` (radians, 0 = right,
    y down). Drawn per screen pixel (no gaps when rotated): a dark green top with the two centred white stripes and a
    1 px gap, windscreen and long fastback rear window, pale headlights, pink tail lights, a lit rim along its upper
    edge, a shaded side face with wheels under it (the 3/4 hint), and a dark outline broken by lighter pixels."""
    ca, sa = math.cos(angle), math.sin(angle)
    r = int(math.ceil((CAR_HALF_L + 1) * scale))
    cx, cy = int(round(x)), int(round(y))
    top = {}
    for py in range(cy - r, cy + r + 1):
        for px in range(cx - r, cx + r + 1):
            u, v = _car_local(px, py, x, y, ca, sa, scale)
            if not _in_car(u, v):
                continue
            au, av = abs(u), abs(v)
            c = GREEN
            if 0.5 <= av < 1.7 and au <= CAR_HALF_L - 0.6:
                c = WHITE if u > -CAR_HALF_L + 1.5 else STRIPE_D  # the two stripes, the gap between them
            elif 1.7 <= av < CAR_HALF_W - 1.4 and (1.5 <= u < 3.0 or -5.0 <= u < -3.0):
                c = GLASS                                        # small windscreen and fastback window: green dominates
            if u >= CAR_HALF_L - 1.2 and av >= 1.7:
                c = LIGHT
            elif u <= -CAR_HALF_L + 1.0 and av >= 1.7:
                c = TAIL
            top[(px, py)] = c
    cells = set(top)
    for (px, py), c in list(top.items()):                       # lit upper rim, shaded lower rim (screen space)
        if c == GREEN and (px, py - 1) not in cells:
            top[(px, py)] = GREEN_L
        elif c == GREEN and (px, py + 1) not in cells:
            top[(px, py)] = GREEN_D
    side = {}
    for (px, py) in cells:                                      # the side face: the body dropped by CAR_SIDE pixels
        for d in range(1, CAR_SIDE + 1):
            p = (px, py + d)
            if p not in cells and p[1] < H and not any((p[0], p[1] - k) in cells for k in range(1, d)):
                u, _ = _car_local(p[0], p[1] - d, x, y, ca, sa, scale)
                wheel = abs(abs(u) - CAR_HALF_L * 0.6) < 1.6
                if d == CAR_SIDE:
                    side[p] = OUT if wheel else GREEN_D
                else:
                    side[p] = GREEN_S if d == 1 else GREEN_D
    cv.blit(side)
    cv.blit(top)
    cv.outline(cells | set(side))


def draw_line(cv, x0, y0, x1, y1, c):
    n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
    for i in range(n + 1):
        t = i / n
        cv.put(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, c)


def draw_ground(cv, y=42, x0=2, x1=61):
    cells = {}
    for x in range(x0, x1 + 1):
        cells[(x, y)] = GROUND_L if x % 4 else GROUND
        cells[(x, y + 1)] = GROUND
    cv.blit(cells)
    cv.outline(set(cells))


def heading(pts, i=-1, back=3):
    a, b = pts[i - back], pts[i]
    return math.atan2(b[1] - a[1], b[0] - a[0])


def draw_ring(cv, cx, cy, r, start, end, c=CYAN, d=CYAN_D):
    """A turn mark: an arc of a circle (radians) in neon cyan with a darker tail and an arrow head at its end."""
    n = int(r * abs(end - start) * 1.5) + 2
    cells = {}
    for i in range(n + 1):
        a = start + (end - start) * i / n
        p = (int(round(cx + r * math.cos(a))), int(round(cy + r * math.sin(a))))
        cells[p] = (CYAN_W if (i * 7) % 11 == 0 else c) if i > n * 0.3 else d   # hot highlight pixels on the stroke
        q = (int(round(cx + (r - 1) * math.cos(a))), int(round(cy + (r - 1) * math.sin(a))))
        if q not in cells:
            cells[q] = CYAN_D                                  # a darker inner step: the stroke is 2 px and stepped
    direction = 1 if end > start else -1
    tx, ty = cx + r * math.cos(end), cy + r * math.sin(end)
    tang = end + direction * math.pi / 2
    for k in (-2, 2):                                      # the arrow head
        bx = tx - math.cos(tang) * 3 + math.cos(end) * k
        by = ty - math.sin(tang) * 3 + math.sin(end) * k
        m = int(max(abs(bx - tx), abs(by - ty))) + 1
        for j in range(m + 1):
            cells[(int(round(tx + (bx - tx) * j / m)), int(round(ty + (by - ty) * j / m)))] = c
    cv.blit(cells)
    # Stepped glow: a mid cyan step on the outer side only (so the inside stays clear round the car), then a dark one.
    outer = {(x + dx, y + dy) for (x, y) in cells for dx in (-1, 0, 1) for dy in (-1, 0, 1)}
    outer = {p for p in outer - set(cells) if p not in cv.px and 0 <= p[0] < W and 0 <= p[1] < H
             and math.hypot(p[0] - cx, p[1] - cy) > r}
    cv.blit({p: CYAN_D for p in outer})
    inner = set(cells) | outer
    cv.outline(inner, halo=CYAN_H)


def draw_ramp(cv, x, y):
    cells = {}
    for i in range(10):
        top = y - int(i * 0.6)
        for yy in range(top, y + 1):
            cells[(x + i, yy)] = (PINK_W if i == 9 else PINK) if yy == top else (PINK_H if yy == top + 1 else ROCK)
    cv.blit(cells)                                          # a neon pink kerb along the ramp's top, a dark pink step
    cv.outline(set(cells))


NAVY = (30, 34, 84)          # the boulders' dark navy rock (Visual style rule 8: navy, purple, magenta)
NAVY_L = (54, 60, 128)       # its lit upper facets


def draw_boulder(cv, cx, cy, rx, ry, cracks, phase=0.7):
    """A crashed meteor boulder in 3/4 view: a lumpy navy rock top (lit facets above, purple shading below), a dark
    purple front face 2 px deep, glowing magenta cracks (a hot core pixel, pink, a dark pink step beside them), then a
    one-step dark magenta glow halo round the whole rock and the near-black outline broken by lighter pixels.
    `cracks` is a list of (dx, dy) offsets from the centre, drawn in order as a jagged line."""
    top = {}
    for y in range(cy - ry - 1, cy + ry + 2):
        for x in range(cx - rx - 1, cx + rx + 2):
            a = math.atan2(y - cy, x - cx)
            bump = 1.0 + 0.14 * math.cos(3 * a + phase) + 0.08 * math.cos(5 * a + 2 * phase)  # lumpy; phase varies it
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= bump * bump:
                s = (x - cx) / rx + 1.6 * (y - cy) / ry                         # light from the upper left
                top[(x, y)] = (NAVY_L if s < -0.9 else NAVY if s < 0.3 else ROCK if s < 0.9 else ROCK_D)  # 4 steps
    cells = set(top)
    face = {(x, y + d): ROCK_D if d == 1 else ROCK for (x, y) in cells for d in (1, 2)
            if (x, y + d) not in cells and not ((x, y + 1) in cells and d == 2)}
    for (x, y) in list(top):                                    # purple facet pixels on the lit side
        if top[(x, y)] == NAVY_L and (x * 3 + y) % 5 == 0:
            top[(x, y)] = ROCK_L
    crack = {}
    for (ax, ay), (bx, by) in zip(cracks, cracks[1:]):
        n = max(abs(bx - ax), abs(by - ay)) or 1
        for i in range(n + 1):
            p = (cx + int(round(ax + (bx - ax) * i / n)), cy + int(round(ay + (by - ay) * i / n)))
            crack[p] = PINK_W if i % 3 == 1 else PINK           # hot core pixels along the crack
            q = (p[0], p[1] + 1)                                # 2 px thick, so it reads at full size
            if q in cells and q not in crack:
                crack[q] = PINK
    glow = {}
    for (x, y) in crack:                                        # a dark pink step beside each crack pixel, on the rock
        for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if q in cells and q not in crack:
                glow[q] = PINK_D
    cv.blit(face)
    cv.blit(top)
    cv.blit(glow)
    cv.blit(crack)
    cv.outline(cells | set(face), halo=PINK_H)


# ------------------------------------------------------------------ the seven tricks ----

def _ground_trail(cv, pts, road=7.0, car_at=(0, 0)):
    """A ground trick: the road with its cyan kerb, the twin pink tire marks, and the shared 3/4 car (the same car as
    every other picture) at the trail's end, moved by `car_at` so the marks run into its rear wheels."""
    draw_road(cv, pts, radius=road, kerb=True)
    draw_tire_marks(cv, pts, offset=2.6)          # far enough apart that each mark's stepped glow reads on its own
    draw_car_34(cv, pts[-1][0] + car_at[0], pts[-1][1] + car_at[1])


def extended_drift(cv):
    """One long unbroken curve, the car sliding sideways at its end."""
    # One sweep turning the same way all along: in along the bottom left, curving up to the right. At its end the trail
    # climbs steeply while the car faces right across it: the car slides sideways, its tail kicked out over the marks.
    pts = sample(lambda a: (6 + 38.4 * math.cos(a), 8.5 + 35.5 * math.sin(a)), math.pi * 0.5 - 0.06, math.pi * 0.5 - 1.3)
    _ground_trail(cv, pts, road=5.5, car_at=(5, -2))


# The Mustang fastback in 3/4 view, nose to the right: a lit top face with the two centred white stripes and the gap
# between them, glass (windscreen and the long fastback rear window), and a shaded side face with its wheels.
# The top face is five rows, green / stripe / gap / stripe / green, so the two stripes sit centred with the gap between
# them; the roof above slopes long and low to the tail (the fastback), with a glint pixel in the windscreen.
_CAR_34 = [
    "          LwLL      ",
    "     LLggggggghL    ",
    "  LwLGGGGGGGGGGgLw  ",
    " tGGGGGGGGGGGGGGGGh ",
    " sWWWWWWWWWWWWWWWWW ",
    " GGGGGGGGGGGGGGGGGG ",
    " sWWWWWWWWWWWWWWWWW ",
    " tGGGGGGGGGGGGGGGGh ",
    " DDDDDDDDDDDDDDDDDD ",
    " SSSSSSSSSSSSSSSSSS ",
    " SkokSSSSSSSSSSkokS ",
    "  kkk          kkk  ",
]
_CAR_KEY = {"L": GREEN_L, "G": GREEN, "D": GREEN_D, "W": WHITE, "s": STRIPE_D, "g": GLASS, "h": LIGHT, "t": TAIL,
            "k": OUT, "S": GREEN_S, "o": LANE, "w": WHITE}   # w: highlight pixels on the roof and rim


def draw_car_34(cv, x, y, shadow=True, flip=False):
    """The larger 3/4 view car (nose right, or nose left with `flip`) centred on (x, y), so both stripes and the gap
    read; an optional drop shadow under it, and the near-black outline."""
    cx, cy = int(round(x)), int(round(y))
    x0, y0 = cx - 10, cy - 5
    if shadow:
        cv.blit({(x0 + 1 + dx, y0 + 8 + dy): ASPH_D for dx in range(19) for dy in range(4)})
    car = {}
    for dy, row in enumerate(_CAR_34):
        if flip:
            row = row[::-1]                                  # the mirror image: headlights left, tail lights right
        for dx, ch in enumerate(row):
            if ch in _CAR_KEY:
                car[(x0 + dx, y0 + dy)] = _CAR_KEY[ch]
    cv.blit(car)
    cv.outline(set(car))
    for (px, py) in car:                                     # extra light pixels breaking the top outline
        if (px, py - 1) not in car and cv.px.get((px, py - 1)) == OUT and px % 3 == 1:
            cv.px[(px, py - 1)] = OUT_L
    for (px, py), c in list(cv.px.items()):                 # light breaks along the outline's lit left end too
        if c == OUT and (px + 1, py) in car and py % 3 == 0 and (px, py) not in car:
            cv.px[(px, py)] = OUT_L
    return set(car)


def three_sixty(cv):
    """A path with one full loop in it, laid flat on the ground in 3/4 view (the loop squashed, the road with a dark
    front face), a cyan neon kerb on the road's lit edge, and a larger car at the end so its stripes read."""
    pts = sample(lambda s: (30 + 4.6 * s - 12 * math.sin(s), 21 - 8 * math.cos(s)), -3.9, 3.4)
    top = _cells(pts, 5.5)
    face = {(x, y + d) for (x, y) in top for d in (1, 2) if (x, y + d) not in top and y + d < H}
    cv.blit({p: ASPH_D for p in face})                                 # the road's front face: depth in 3/4 view
    edge = {p for p in top if (p[0], p[1] - 1) not in top}
    glow = {(x, y + 1) for (x, y) in edge} & top - edge               # 1 px stepped halo under the kerb
    cv.blit({p: ((CYAN if p[0] % 4 else CYAN_W) if p in edge else (CYAN_H if p in glow else ASPH)) for p in top})
    cv.outline(top | face)
    draw_tire_marks(cv, pts, offset=1.6)
    for (x, y), c in list(cv.px.items()):                              # highlight pixels on the pink strokes
        if c == PINK and (x + 2 * y) % 5 == 0:
            cv.px[(x, y)] = PINK_W
    for (x, y) in list(glow):                                         # a second, darker halo step under the first
        if (x, y + 1) in top and cv.px.get((x, y + 1)) == ASPH:
            cv.px[(x, y)] = CYAN_D
            cv.px[(x, y + 1)] = CYAN_H
    draw_car_34(cv, pts[-1][0], pts[-1][1])
    for x in range(1, W - 1):                                         # sparse dark-blue night ground round the road
        for y in range(2, H - 1):
            if (x, y) not in cv.px and (x * 7 + y * 13) % 23 == 0:
                cv.put(x, y, GROUND if (x + y) % 3 else GROUND_L)


def alternate_drift(cv):
    """An S: the car drifts one way, then the other. A full sine period on a wider road fills the frame; it ends at
    x 44 so the larger car fits, and the car is swung sideways (drifting) so its stripes lie near level and read."""
    pts = sample(lambda t: (7 + 37 * t, 24 - 12 * math.sin(t * 2 * math.pi)), 0, 1)
    # The car is drawn level (nose right), swung sideways across the rising path: a drift, and at 0 radians the two
    # stripes and the gap between them stay straight pixel rows instead of breaking into steps.
    _ground_trail(cv, pts, road=8.0)


def _jump(cv, top, land_x, clear=None, glow_steps=1):
    """A dashed jump arc from a ramp to a landing on the ground line. `clear` = (x, y, r): leave the arc out inside
    that circle (where a turn ring is drawn), so the arc and the ring never cross."""
    draw_road(cv, [(4 + i * 0.5, 43.0) for i in range(111)], radius=2.6)   # the night road strip under the jump
    if glow_steps > 1:                                     # a neon pink kerb on the road's lit edge, a stepped glow under
        for (x, y), c in list(cv.px.items()):
            if c == ASPH_L:
                cv.px[(x, y)] = PINK_W if x % 5 == 0 else PINK
                if cv.px.get((x, y + 1)) in (ASPH, LANE):
                    cv.px[(x, y + 1)] = PINK_D
                if cv.px.get((x, y + 2)) in (ASPH, LANE):
                    cv.px[(x, y + 2)] = PINK_H
    draw_ramp(cv, 4, 41)
    x0, y0 = 14, 38
    pts = [(x0 + (land_x - x0) * i / 120, y0 - top * 4 * (i / 120) * (1 - i / 120)) for i in range(121)]
    shown = pts if clear is None else [p for p in pts if math.hypot(p[0] - clear[0], p[1] - clear[1]) > clear[2]]
    dash = (4, 3) if glow_steps == 1 else (4, 7)            # wider gaps when the glow is two steps wide
    cv.jump_path = draw_dashed(cv, shown, dash=dash, glow_steps=glow_steps)
    draw_tire_marks(cv, [(land_x - 16 + i * 0.1, 43.0) for i in range(141)], offset=1.0)  # fresh pink landing marks
    return pts


def air_one_eighty(cv):
    """The same layout as air_three_sixty, with the larger shared 3/4 car (so both stripes and the gap read): the car
    at the top of the arc facing forward, a half-turn arrow over it, kept clear of the arc, and the car landed facing
    back (mirrored, nose left)."""
    ax, ay, r = 29, 16, 14                                         # the top car and its half-turn ring
    # The arc stops at the ring and resumes after it, with airtime's two-step glow (hot dash pixels, a mid and a dark
    # cyan step) and the road's pink kerb with its two darker steps; it lands at x 40, short of the car, not under it.
    _jump(cv, 24, 40, clear=(ax, ay, r + 3), glow_steps=2)
    draw_car_34(cv, 53, 36, shadow=False, flip=True)               # landed facing back
    draw_car_34(cv, ax, ay, shadow=False)
    draw_ring(cv, ax, ay, r, math.pi, math.pi * 2.0)                # a half turn over the car, arrow head on the right


def air_three_sixty(cv):
    ax, ay, r = 29, 16, 14                                         # the top car and its turn ring, high and left
    _jump(cv, 24, 44, clear=(ax, ay, r + 3))                       # the arc stops at the ring and resumes after it
    draw_car_34(cv, 53, 36, shadow=False)                          # landed, facing forward, clear of the ring
    draw_car_34(cv, ax, ay, shadow=False)
    # Nearly a full turn, open by about 50 degrees at the top so it reads as an arrow, not a closed hoop; at radius 14
    # the ring passes round the car without touching its body.
    draw_ring(cv, ax, ay, r, -math.pi * 0.5 + 0.45, math.pi * 1.5 - 0.45)


def airtime(cv):
    """One high dashed arc off the ramp and a single car, landed at its end (the larger shared 3/4 car, so the two
    stripes and the gap read); under the arc's top a height mark: a measuring line with end ticks, kept clear of the
    arc, in the same outlined, haloed cyan as the path."""
    pts = _jump(cv, 30, 50, glow_steps=2)                          # the arc with a two-step glow
    ax, ay = min(pts, key=lambda p: p[1])
    ax, top = int(round(ax)), int(round(ay)) + 7                    # below the arc's top: clear of its glow
    bottom = 38
    mark = {}
    for y in range(top, bottom + 1):                               # the height mark: a 2 px line, hot core on the left
        mark[(ax, y)] = CYAN_W if y < (top + bottom) // 2 else CYAN
        mark[(ax + 1, y)] = CYAN if y < (top + bottom) // 2 else CYAN_D
    for k in (1, 2, 3):                                            # arrow heads: up at the top, down at the bottom
        for dx in range(-k, k + 2):
            mark[(ax + dx, top + k)] = CYAN_W if dx in (0, 1) else CYAN
            mark[(ax + dx, bottom - k)] = CYAN if dx in (0, 1) else CYAN_D
    cv.blit(mark)
    cv.outline(set(mark), halo=CYAN_H)
    draw_car_34(cv, pts[-1][0] + 2, 37)                            # landed at the arc's end, nose forward, its shadow


def thread_the_needle(cv):
    """The car passes between two obstacles: a straight road through the middle of the frame, a boulder above and one
    below it at the same x with the road centred in the gap, and the larger shared 3/4 car just past the gap, level,
    so both stripes and the gap between them read and nothing is drawn over it."""
    pts = [(2 + i * 0.25, 24.0) for i in range(169)]            # x 2 to 44, under the car's tail
    draw_road(cv, pts, radius=6.5)                              # wider asphalt, with its pale lane dashes
    draw_tire_marks(cv, pts, offset=2.0)
    path = {}                                                   # the route: a neon cyan centre line of dashes
    for x in range(4, 42):
        if x % 6 < 4:
            path[(x, 24)] = CYAN_W if x % 6 == 3 else CYAN
            for q in ((x, 23), (x, 25)):
                path[q] = CYAN_H                                # its stepped glow on the asphalt
    for k in range(1, 4):                                       # an arrow head where it meets the car
        path[(41 - k, 24 - k)] = path[(41 - k, 24 + k)] = CYAN
    cv.blit(path)
    draw_boulder(cv, 25, 7, 11, 5, [(-6, -1), (-3, 1), (0, -1), (3, 0), (6, -2)], phase=0.7)
    draw_boulder(cv, 27, 41, 9, 5, [(-5, -2), (-2, 0), (1, -2), (4, 1)], phase=2.6)
    draw_car_34(cv, 52, 23)


def reverse_drift(cv):
    """T-543: the extended drift's curve, but the car faces back along it (mirrored, nose left): it slides
    backwards, tail first, with the twin pink marks running out of its nose."""
    pts = sample(lambda a: (6 + 38.4 * math.cos(a), 8.5 + 35.5 * math.sin(a)), math.pi * 0.5 - 0.06, math.pi * 0.5 - 1.3)
    draw_road(cv, pts, radius=5.5, kerb=True)
    draw_tire_marks(cv, pts, offset=2.6)
    draw_car_34(cv, pts[-1][0] + 5, pts[-1][1] - 2, flip=True)


def aura(cv):
    """T-543: a parked car on a short strip of road, no tire marks, with rings of neon cyan spreading out round it
    (the aura), the outer one dimmer."""
    pts = [(6 + i * 0.25, 30.0) for i in range(209)]
    draw_road(cv, pts, radius=5.5, kerb=True)
    draw_car_34(cv, 32, 27)
    draw_ring(cv, 32, 27, 15, -math.pi * 0.95, math.pi * 0.95, c=CYAN, d=CYAN_D)
    draw_ring(cv, 32, 27, 21, -math.pi * 0.85, -math.pi * 0.15, c=CYAN_D, d=CYAN_H)


def rail_grind(cv):
    """T-543: the car on a rail: a long pale metal rail from the lower left to the upper right on posts, the car on
    top of it nose to the right, and a spray of hot sparks (white, pink and cyan pixels) trailing back along the rail."""
    pts = [(4 + i * 0.3, 40.0 - i * 0.12) for i in range(190)]
    rail = {}
    for (x, y) in pts:
        xi, yi = int(round(x)), int(round(y))
        rail[(xi, yi)] = WHITE if xi % 5 else CYAN_W
        rail[(xi, yi + 1)] = STRIPE_D
        rail[(xi, yi + 2)] = ASPH_L
    for px in (10, 26, 42, 58):                                    # posts under the rail
        py = int(round(40.0 - (px - 4) * 0.4))
        for d in range(3, 8):
            rail[(px, py + d)] = ASPH_L if d < 6 else ASPH_D
    cv.blit(rail)
    cv.outline(set(rail))
    cx, cy = 38, 21
    draw_car_34(cv, cx, cy, shadow=False)
    for i, (dx, dy, c) in enumerate([(-14, 10, PINK_W), (-17, 11, PINK), (-20, 13, CYAN_W), (-16, 8, WHITE), (-23, 12, CYAN),
                                      (-12, 12, PINK), (-26, 14, PINK_D), (-19, 9, WHITE), (-21, 15, CYAN_D)]):
        cv.put(cx + dx, cy + dy - 1, c)
        if i % 2 == 0:
            cv.put(cx + dx + 1, cy + dy - 1, c)


DRAWERS = {"extended_drift": extended_drift, "three_sixty": three_sixty, "alternate_drift": alternate_drift,
           "air_one_eighty": air_one_eighty, "air_three_sixty": air_three_sixty, "airtime": airtime,
           "thread_the_needle": thread_the_needle,
           "reverse_drift": reverse_drift, "aura": aura, "rail_grind": rail_grind}


def draw(trick_id: str) -> Image.Image:
    cv = Canvas()
    DRAWERS[trick_id](cv)
    return cv.image()


def build(out_dir: Path, only=None, force=False) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    ids = [only] if only else TRICK_IDS
    paths = []
    for tid in ids:
        if tid not in DRAWERS:
            raise SystemExit(f"unknown trick id {tid}")
        p = out_dir / f"{tid}.png"
        if p.exists() and not force:
            raise SystemExit(f"{p} exists (use --force)")
        draw(tid).save(p)
        paths.append(p)
    return paths


def sheet(src_dir: Path, out: Path, bg, scale=4, cols=4, gap=4) -> Path:
    """All seven in a grid of `cols` columns, enlarged with nearest filtering, on a background colour."""
    ims = []
    for t in TRICK_IDS:
        with Image.open(src_dir / f"{t}.png") as im:
            ims.append(im.convert("RGBA"))
    rows = (len(ims) + cols - 1) // cols
    sw, sh = cols * (W + gap) + gap, rows * (H + gap) + gap
    s = Image.new("RGBA", (sw, sh), tuple(bg) + (255,))
    for i, im in enumerate(ims):
        s.alpha_composite(im, (gap + (i % cols) * (W + gap), gap + (i // cols) * (H + gap)))
    out.parent.mkdir(parents=True, exist_ok=True)
    s.resize((sw * scale, sh * scale), Image.NEAREST).save(out)
    return out


def preview(src: Path, out: Path, scale=8) -> Path:
    """One picture enlarged with nearest filtering, on a dark and a light background side by side."""
    with Image.open(src) as im:
        im = im.convert("RGBA")
    w, h = im.size
    s = Image.new("RGBA", (2 * w + 1, h), (0, 0, 0, 255))
    for i, bg in enumerate([(24, 26, 40), (225, 225, 230)]):
        panel = Image.new("RGBA", (w, h), bg + (255,))
        panel.alpha_composite(im)
        s.paste(panel, (i * (w + 1), 0))
    out.parent.mkdir(parents=True, exist_ok=True)
    s.resize((s.width * scale, s.height * scale), Image.NEAREST).save(out)
    return out


def main(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("sheet")
    s.add_argument("--src", default="art-archive/T-383/script")
    s.add_argument("--out", required=True)
    s.add_argument("--bg", default="dark")
    s.add_argument("--scale", type=int, default=4)
    b = sub.add_parser("build")
    b.add_argument("--out", default="art-archive/T-383/script")
    b.add_argument("--only")
    b.add_argument("--force", action="store_true")
    b.add_argument("--file", help="write the one picture named by --only to exactly this file (overwrites)")
    p = sub.add_parser("preview")
    p.add_argument("src")
    p.add_argument("--out", required=True)
    p.add_argument("--scale", type=int, default=8)
    a = ap.parse_args(argv)
    if a.cmd == "preview":
        print(preview(Path(a.src), Path(a.out), a.scale))
        return
    if a.cmd == "sheet":
        bg = {"dark": (24, 26, 40), "light": (225, 225, 230)}.get(a.bg) or tuple(int(v) for v in a.bg.split(","))
        print(sheet(Path(a.src), Path(a.out), bg, a.scale))
        return
    if a.file:
        if not a.only:
            raise SystemExit("--file needs --only")
        f = Path(a.file)
        f.parent.mkdir(parents=True, exist_ok=True)
        draw(a.only).save(f)
        print(f)
        return
    for p in build(Path(a.out), a.only, a.force):
        print(p)


if __name__ == "__main__":
    main()
