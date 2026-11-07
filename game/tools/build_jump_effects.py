#!/usr/bin/env python3
"""The five jump effects (task T-556), drawn by a free script (no PixelLab).

    python game/tools/build_jump_effects.py build [--out DIR]   # the five sheets + record
    python game/tools/build_jump_effects.py check               # rules check on the game sheets

One sheet per effect id in game/art/effects/jump/<id>.png: a single row of FRAMES frames of
SIZE x SIZE, transparent, every pixel opaque or empty (Visual style rules 1, 2, 5). The ground
point the car left from is at (ANCHOR_X, ANCHOR_Y) in every frame, so the game puts that texel on
the place the car left from. Ground shapes are 2:1 ellipses (the 3/4 isometric view). No effect
is drawn per direction: the dash cloud, sparks and ring are round, the spring and the jet thrust
stand straight under the car, so the car's heading changes nothing in them.
  dash_cloud     grey-white puffs spreading out on the ground, shrinking and breaking up
  spring         a steel coil standing up from a base plate, stretching, then collapsing
  jet_thrust     a flame hanging under the car down to the ground, flickering and shrinking
  stunt_sparks   a burst of sparks flying out from under the car and dropping
  shockwave_ring a ring rippling out flat on the ground, with a fainter second ring behind it
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from style_rules import art_checks, decode_png  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "game" / "art" / "effects" / "jump"
RECORD = OUT_DIR / "jump_effects.json"

IDS = ["dash_cloud", "spring", "jet_thrust", "stunt_sparks", "shockwave_ring"]
FRAMES = 8
SIZE = 96
ANCHOR_X, ANCHOR_Y = 48, 68

OUTLINE = (24, 22, 34)                                         # almost black
CLOUD = [(120, 124, 144), (170, 176, 196), (214, 220, 234), (240, 243, 250)]   # dark -> light
STEEL = [(70, 78, 98), (120, 132, 156), (176, 190, 212), (232, 240, 250)]
STEEL_DEEP = (44, 48, 66)                                      # the spring's deepest shadow band
HEAT = [(160, 48, 16), (210, 82, 18), (240, 118, 24), (255, 154, 40), (255, 196, 100), (255, 230, 168)]
WHITE = (255, 255, 255)
EMBER = [(92, 26, 18), (124, 36, 16)]                          # the jet glow's deepest outer bands
WAVE = [(60, 96, 150), (110, 160, 214), (176, 214, 246), (236, 248, 255)]


def put(im, x, y, col):
    x, y = int(round(x)), int(round(y))
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), col + (255,))


def blank():
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def lerp(a, b, t):
    return a + (b - a) * t


def dither_keep(x, y, keep):
    """True for a pixel that stays when `keep` (0..1) of a 4x4 ordered pattern is kept (dissolve)."""
    order = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
    return order[(y % 4) * 4 + (x % 4)] < keep * 16


def disc(im, cx, cy, rx, ry, cols, outline=OUTLINE, light=(-0.35, -0.45)):
    """A shaded ellipse: outline ring, then bands from dark to light toward `light` (top left)."""
    if rx < 1 or ry < 1:
        return
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            u, v = (x - cx) / rx, (y - cy) / ry
            d = u * u + v * v
            if d > 1.0:
                continue
            if d > 0.72:
                col = outline
            else:
                s = (u * light[0] + v * light[1]) / 0.8        # -1 shadow side .. 1 light side
                k = min(len(cols) - 1, max(0, int((s + 1.0) * 0.5 * len(cols) - 0.01 + (0.25 if d < 0.2 else 0))))
                col = cols[k]
            put(im, x, y, col)


def ellipse_ring(im, cx, cy, rx, ry, thick, cols, outline=True):
    """A ring on the ground (a 2:1 ellipse): a light core band between two darker bands and an outline."""
    n = int(max(rx, 4) * 8)
    for i in range(n):
        a = math.tau * i / n
        for w in range(-thick - 1, thick + 2):
            r = 1.0 + w / max(rx, 1.0)
            x, y = cx + math.cos(a) * rx * r, cy + math.sin(a) * ry * r
            aw = abs(w)
            if aw == thick + 1:
                col = OUTLINE if outline else None
            elif aw == thick:
                col = cols[0]
            elif aw == 0:
                col = cols[-1]
            else:
                col = cols[min(len(cols) - 1, 1 + (thick - aw) // 1)] if thick > 1 else cols[1]
            if col is not None:
                put(im, x, y, col)


# --- the five effects -------------------------------------------------------------------------

# dash cloud ramp at night: cool blue-violet shadow up to a near-white highlight, plus a cool rim
PUFF_OUTLINE = (4, 4, 8)
PUFF = [(58, 60, 92), (92, 98, 132), (138, 146, 176), (186, 194, 216), (226, 232, 244), (248, 250, 255)]
PUFF_RIM = (104, 132, 196)
# per puff: size scale, x/y squash, and the two lobes that make it lumpy (dx, dy, r scale)
PUFF_SHAPES = [
    (1.00, 1.00, 0.78, [(-0.45, 0.15, 0.70), (0.40, 0.20, 0.62)]),
    (0.72, 1.10, 0.72, [(0.35, 0.10, 0.70)]),
    (0.90, 1.05, 0.80, [(-0.40, 0.25, 0.65), (0.45, -0.05, 0.55)]),
    (0.62, 0.95, 0.85, [(-0.30, 0.20, 0.75)]),
    (0.95, 1.15, 0.75, [(0.42, 0.22, 0.66), (-0.38, 0.05, 0.58)]),
    (0.70, 1.00, 0.80, [(0.30, 0.25, 0.70)]),
    (0.82, 1.08, 0.78, [(-0.42, 0.18, 0.62)]),
]


def puff(im, cx, cy, r, shape):
    """A lumpy cloud puff: union of ellipses, 6-step ramp lit from the upper left with dithered steps,
    a cool rim on the lower right, and an almost-black outline broken by 1-2 highlight pixels."""
    scale, sx, sy, lobes = shape
    r *= scale
    if r < 1.2:
        return
    parts = [(cx, cy, r * sx, r * sy)] + [(cx + dx * r, cy + dy * r, r * sx * k, r * sy * k) for dx, dy, k in lobes]
    x0, x1 = int(cx - r * 2.2) - 2, int(cx + r * 2.2) + 3
    y0, y1 = int(cy - r * 1.6) - 2, int(cy + r * 1.6) + 3

    def inside(x, y):
        return any(((x - px) / max(rx, 0.5)) ** 2 + ((y - py) / max(ry, 0.5)) ** 2 <= 1.0 for px, py, rx, ry in parts)

    mask = {(x, y) for y in range(y0, y1) for x in range(x0, x1) if inside(x, y)}
    if not mask:
        return
    breaks = 0
    for (x, y) in sorted(mask, key=lambda p: (p[1], p[0])):
        edge_nb = [(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if (x + dx, y + dy) not in mask]
        u, v = (x - cx) / max(r * sx, 1), (y - cy) / max(r * sy, 1)
        d = min(1.0, u * u + v * v)
        z = math.sqrt(1.0 - d)                         # treat the puff as a ball: crescent-shaped bands
        s = (-0.55 * u - 0.6 * v + 0.58 * z) * 1.25 - 0.15   # lit from upper left and above
        f = max(0.0, min(0.999, (s + 1.0) / 2.0)) * len(PUFF)
        k = int(f)
        if (f - k) > 0.6 and (x + y) % 2 == 0:          # solid bands, a 2-3 px dithered seam between them
            k += 1
        k = max(0, min(len(PUFF) - 1, k))
        col = PUFF[k]
        if edge_nb:
            if s < -0.15:
                col = PUFF_RIM if (x + y) % 2 else PUFF[0]   # dithered cool rim on the shadow side
            elif k < 2:
                col = PUFF[1]
        put(im, x, y, col)
    # outline: every empty 4-neighbour of the puff, near-black; sorted so every run is the same
    ring = sorted({(x + dx, y + dy) for (x, y) in mask for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                   if (x + dx, y + dy) not in mask})
    for q in ring:
        qu, qv = (q[0] - cx) / max(r * sx, 1), (q[1] - cy) / max(r * sy, 1)
        # selective outline: along the lit upper-left arc the outline turns pale (a run of highlight
        # pixels with a dark pixel every few), so the outline is broken by light, not closed
        lit = (-qu * 0.55 - qv * 0.6) > 0.5 and qv < 0.0
        if lit and r >= 2.5:
            dark = (q[0] + 2 * q[1]) % 5 == 0
            put(im, *q, PUFF_OUTLINE if dark else (PUFF[-2] if (q[0] + q[1]) % 2 else PUFF[-3]))
            breaks += 1
        else:
            put(im, *q, PUFF_OUTLINE)
    if r >= 4:   # soft dust: a few dithered pale wisps just outside the lit top edge
        for q in ring:
            qu, qv = (q[0] - cx) / max(r * sx, 1), (q[1] - cy) / max(r * sy, 1)
            w = (q[0], q[1] - 1)
            if qv < -0.3 and w not in mask and im.getpixel(w)[3] == 0 and (q[0] * 5 + q[1] * 3) % 4 == 0:
                put(im, *w, PUFF[-3] if qu < 0 else PUFF[-4])
    for q in ring:   # heavier outline on the shadow side (lower right): a second dark pixel below
        qu, qv = (q[0] - cx) / max(r * sx, 1), (q[1] - cy) / max(r * sy, 1)
        if r >= 4 and qv > 0.3 and qu > -0.3:
            below = (q[0], q[1] + 1)
            if below not in mask and 0 <= below[0] < SIZE and below[1] < SIZE and im.getpixel(below)[3] == 0:
                put(im, *below, PUFF_OUTLINE)


def dash_cloud(i):
    im = blank()
    t = i / (FRAMES - 1)
    spread = lerp(7, 32, math.sin(t * math.pi * 0.5))
    size = lerp(11, 8.5, t) if t < 0.5 else lerp(9.5, 4.5, (t - 0.5) * 2)
    lift = -lerp(2, 8, t)
    pts = []
    for k in range(7):
        a = math.tau * k / 7 + 0.4
        jit = 1.0 + 0.12 * math.sin(k * 2.3)
        cx = ANCHOR_X + math.cos(a) * spread * jit
        cy = ANCHOR_Y + math.sin(a) * spread * 0.5 * jit + lift
        pts.append((cy, cx, k))
    for cy, cx, k in sorted(pts):      # back to front, so near puffs overlap far ones
        puff(im, cx, cy, size, PUFF_SHAPES[k])
    if t < 0.6:   # early frames: dither the outer rim pixels so the edge is ragged, not a clean circle
        px = im.load()
        for y in range(1, SIZE - 1):
            for x in range(1, SIZE - 1):
                if px[x, y][:3] == PUFF_OUTLINE and (x * 3 + y * 5) % 7 == 0:
                    nb = [px[x + dx, y + dy][3] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
                    if nb.count(0) >= 2:
                        px[x, y] = (0, 0, 0, 0)
    if t > 0.6:   # break up: dissolve with a dither, never a fade
        keep = 1.0 - (t - 0.6) / 0.4 * 0.85
        for y in range(SIZE):
            for x in range(SIZE):
                if im.getpixel((x, y))[3] and not dither_keep(x, y, keep):
                    im.putpixel((x, y), (0, 0, 0, 0))
    return im


def spring(i):
    im = blank()
    t = i / (FRAMES - 1)
    # up fast, hold, then collapse: stretch 0.3 -> 1 -> 0.2
    stretch = math.sin(min(t / 0.45, 1.0) * math.pi * 0.5) if t < 0.6 else lerp(1.0, 0.2, (t - 0.6) / 0.4)
    h = 22 + 30 * stretch       # frame 0 is already a compressed coil, never a squat cap
    # launch glow on the asphalt: a cool stepped halo, outer step dithered, shrinking after the push
    if t < 0.75:
        g = 1.0 - t / 0.75
        for rr, col, dith in ((19, WAVE[0], True), (16, WAVE[0], False), (14.5, WAVE[1], True)):
            rx = rr * (0.7 + 0.3 * g)
            for y in range(int(ANCHOR_Y - rx * 0.5) - 1, int(ANCHOR_Y + rx * 0.5) + 2):
                for x in range(int(ANCHOR_X - rx) - 1, int(ANCHOR_X + rx) + 2):
                    u, v = (x - ANCHOR_X) / rx, (y - ANCHOR_Y) / (rx * 0.5)
                    if u * u + v * v <= 1.0 and (not dith or (x + y) % 2 == 0):
                        put(im, x, y, col)
    # base plate: a steel disc with a lit rim
    # a thick plate: dark side band first, then the lit top, wider than the coil so it shows in every frame
    disc(im, ANCHOR_X, ANCHOR_Y + 2, 16, 7.5, [STEEL[0], STEEL[0], STEEL[1]])
    disc(im, ANCHOR_X, ANCHOR_Y, 16, 7.5, STEEL)
    disc(im, ANCHOR_X, ANCHOR_Y - 1, 11, 4.5, STEEL[:3])
    # the coil: a helix seen in 3/4, loops are 2:1 ellipses; back half dark, front half lit
    coils = 4.5
    rx, ry = 10.0, 4.0
    base_y, top_y = ANCHOR_Y - 4, ANCHOR_Y - 4 - h
    U = coils * math.tau
    back, front = {}, {}
    n = int(coils * 160)
    for s in range(n + 1):
        u = U * s / n
        x = ANCHOR_X + rx * math.cos(u + math.pi)
        y = lerp(base_y, top_y, s / n) + ry * math.sin(u + math.pi * 1.0) * -1
        nearside = math.sin(u) < 0                 # lower half of the loop faces the viewer
        cu = math.cos(u + math.pi)                 # -1 left (lit) .. 1 right (shadow)
        for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):   # 2 px wire
            p = (int(round(x)) + dx - 1, int(round(y)) + dy - 1)
            (front if nearside else back)[p] = (cu, dy)
    def nbrs(p):
        return [(p[0] + a, p[1] + b) for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))]
    # back strands: outline, then dark steel
    for p in back:
        for q in nbrs(p):
            if q not in back:
                put(im, *q, OUTLINE)
    for p, (cu, dy) in back.items():
        put(im, *p, STEEL[0] if cu > -0.3 else STEEL[1])
    # front strands: outline broken by highlights on the lit upper-left, then a 4-step ramp
    for p in front:
        for q in nbrs(p):
            if q not in front:
                cu = front[p][0]
                # selective: only a few white breaks, on the top edge of the lit left side
                lit_edge = q[1] < p[1] and cu < -0.6 and (q[0] + 2 * q[1]) % 4 == 0
                put(im, *q, WHITE if lit_edge else OUTLINE)
                # heavier outline on the shadow side: a second dark pixel under the right half
                if q[1] > p[1] and cu > 0.0:
                    below = (q[0], q[1] + 1)
                    if below not in front:
                        put(im, *below, OUTLINE)
    for p, (cu, dy) in front.items():
        # stronger bands: a white-hot lit edge, a hard dark shadow band on the right
        if cu < -0.75:
            col = WHITE if dy == 0 else STEEL[3]
        elif cu < -0.35:
            col = STEEL[3] if dy == 0 else STEEL[2]
        elif cu < 0.25:
            col = STEEL[2] if dy == 0 else STEEL[1]
        elif cu < 0.6:
            col = STEEL[1] if dy == 0 else STEEL[0]
        else:
            col = STEEL[0] if dy == 0 else STEEL_DEEP
        put(im, *p, col)
    # glints: a white pixel where each front loop faces the light
    for k in range(int(coils) + 1):
        u = math.tau * k + math.pi * 1.25
        if u <= U:
            x = ANCHOR_X + rx * math.cos(u + math.pi)
            y = lerp(base_y, top_y, u / U) - ry * math.sin(u + math.pi)
            put(im, x - 1, y - 1, WHITE)
    # top cap: the plate that pushes the car, its front rim lit by the energy push
    disc(im, ANCHOR_X, top_y - 1, 9, 4.0, STEEL)
    put(im, ANCHOR_X - 4, top_y - 3, WHITE)
    px = im.load()
    glow = 0.1 < t < 0.75
    strong = 0.25 < t < 0.65                       # stretch frames 2-4: the full glow
    if glow:
        for x in range(ANCHOR_X - 6, ANCHOR_X + 7):  # bright energy line along the cap's front rim
            y = int(round(top_y - 1 + 3.0 * math.sqrt(max(0.0, 1 - ((x - ANCHOR_X) / 8.0) ** 2))))
            if (x + y) % 3 or strong:
                put(im, x, y, WAVE[3])
    # the energy push glow around the cap: stepped ellipses of darker blues, drawn only in empty pixels,
    # outer steps dithered; and a halo hugging the coil's outer silhouette (never the gaps between turns)
    if glow:
        steps = ([(12.5, 6.5, WAVE[2], False), (15.5, 8.0, WAVE[1], False), (19.0, 10.0, WAVE[0], True)]
                 if strong else [(12.5, 6.5, WAVE[1], True), (15.5, 8.0, WAVE[0], True)])
        cy = top_y - 2
        filled = set()
        for erx, ery, col, dith in steps:
            for y in range(int(cy - ery) - 1, int(cy + ery) + 2):
                for x in range(int(ANCHOR_X - erx) - 1, int(ANCHOR_X + erx) + 2):
                    if not (0 <= x < SIZE and 0 <= y < SIZE) or (x, y) in filled or px[x, y][3]:
                        continue
                    u, v = (x - ANCHOR_X) / erx, (y - cy) / ery
                    if u * u + v * v <= 1.0:
                        filled.add((x, y))
                        if not dith or (x + y) % 2 == 0:
                            px[x, y] = col + (255,)
        lo, hi = int(top_y + 4), ANCHOR_Y - 6
        for y in range(lo, hi):
            xs = [x for x in range(SIZE) if px[x, y][3] and (x, y) not in filled]
            if not xs:
                continue
            for x, d in ((min(xs), -1), (max(xs), 1)):
                put(im, x + d, y, WAVE[1] if strong or y % 2 == 0 else WAVE[0])
                if strong and (x + y) % 2 == 0:
                    put(im, x + 2 * d, y, WAVE[0])
    if t > 0.75:
        # break up: dither out, but keep the dark outline longer and turn some survivors into bright flecks
        keep = 1.0 - (t - 0.75) / 0.25 * 0.7
        px = im.load()
        for y in range(SIZE):
            for x in range(SIZE):
                c = px[x, y]
                if not c[3]:
                    continue
                if c[:3] == OUTLINE:
                    if not dither_keep(x + 1, y + 2, min(1.0, keep + 0.25)):
                        px[x, y] = (0, 0, 0, 0)
                elif not dither_keep(x, y, keep):
                    px[x, y] = (0, 0, 0, 0)
                elif (x * 3 + y * 5) % 7 == 0:
                    px[x, y] = (WHITE if (x + y) % 2 else WAVE[3]) + (255,)
    return im


def jet_thrust(i):
    im = blank()
    t = i / (FRAMES - 1)
    life = 1.0 - t * 0.8
    top_y = ANCHOR_Y - 26                       # under the car's belly
    length = 27 - 4 * t                         # the flame always reaches the ground glow; it thins instead
    flick = (-1, 1, 0, -1, 1, 0, 1, -1)[i]
    pulse = (1.0, 0.82, 1.08, 0.88, 1.0, 0.8, 1.05, 0.9)[i]      # width breathes frame to frame
    # ground glow: stepped halos on the asphalt, dark orange dither outside, hot centre inside
    g = 0.45 + 0.55 * life
    # bands from a deep ember red outside to a white-hot spot under the flame; each inner band's outer
    # rim is dithered onto the band around it, so the steps read as halos, never as one flat disc
    glow = [(20, 10.0, EMBER[0], True), (17, 8.5, EMBER[0], False), (14, 7.0, EMBER[1], False),
            (11, 5.5, HEAT[0], False), (8, 4.0, HEAT[1], False), (5.5, 2.8, HEAT[3], False),
            (3.2, 1.6, HEAT[5], False), (1.4, 0.8, WHITE, False)]
    for n_, (rx0, ry0, col, dith) in enumerate(glow):
        rx, ry = max(rx0 * g * pulse ** 0.5, 1.0), max(ry0 * g, 0.8)
        for y in range(int(ANCHOR_Y - ry) - 1, int(ANCHOR_Y + ry) + 2):
            for x in range(int(ANCHOR_X - rx) - 1, int(ANCHOR_X + rx) + 2):
                u, v = (x - ANCHOR_X) / rx, (y - ANCHOR_Y) / ry
                d = u * u + v * v
                if d > 1.0:
                    continue
                if dith and (x + y) % 2:
                    continue
                if n_ > 0 and d > 0.72 and (x + y) % 2:   # dithered seam onto the band outside
                    continue
                put(im, x, y, col)
    # the flame: a jet tapering steadily from the nozzle to a ragged, forked tip just above the glow's
    # centre. Every layer follows one swaying centre line; its edges are jagged per row and per frame.
    def h(a, b):                                   # a fixed 0..1 hash, so every run is byte-identical
        return ((a * 73856093) ^ (b * 19349663) ^ 0x5bd1e995) % 1000 / 1000.0
    L = length - 4                                 # the tip ends a few pixels above the ground point
    width = 7.5 * (0.6 + 0.4 * life) * pulse     # late frames stay readable at 48 px

    def centre(yy):
        f = yy / max(L, 1)
        return ANCHOR_X + flick * f * f * 2.0 + math.sin(yy * 0.35 + i * 1.9) * 0.9 * f

    def layer(k, lf, jag):
        mask = set()
        Ll = L * lf
        for yy in range(int(Ll) + 1):
            f = yy / max(Ll, 1)
            half = width * k * (1.0 - f)           # straight taper: no waist, no flare
            if k == 1.0 and f < 0.8:
                half = max(half, 1.0)              # the body stays at least 3 px wide until the tip
            if k < 0.3:
                half = max(half, 0.6)              # the white core stays a visible line
            jl = round((h(i * 31 + yy, int(k * 10)) - 0.5) * 2 * jag * (0.3 + f))
            jr = round((h(yy, i * 17 + int(k * 10)) - 0.5) * 2 * jag * (0.3 + f))
            c = centre(yy)
            for x in range(int(round(c - half)) - jl, int(round(c + half)) + jr + 1):
                mask.add((x, top_y + yy))
        return mask
    outer = layer(1.0, 1.0, 1.2)
    # the forked tip: 2 or 3 tongues of different lengths, set differently each frame
    tip_c = centre(L)
    tongues = []                                   # drawn hot, after the outline, so they stay bright
    for k in range(2 + i % 2):
        dx = (-2, 1, 3, -1, 2, -3)[(i + k * 2) % 6]
        n = 2 + int(h(i, k + 5) * 4 * (0.4 + 0.6 * life))
        for d in range(n):
            tongues.append(((int(round(tip_c + dx * (d + 1) / n)), top_y + int(L) + d),
                            HEAT[4] if d < n // 2 else HEAT[2]))
    # six steps, one more orange than before; yellow and white core wider for contrast
    layers = [(outer, HEAT[1]), (layer(0.84, 0.94, 0.9), HEAT[2]), (layer(0.7, 0.88, 0.8), HEAT[3]),
              (layer(0.56, 0.8, 0.6), HEAT[4]), (layer(0.4, 0.7, 0.4), HEAT[5]), (layer(0.26, 0.58, 0.0), WHITE)]
    # a closed almost-black outline all round (tip included), broken by a few hot highlight pixels on
    # the lit upper-left side; a second dark pixel on the shadow (right) side makes it heavier there
    ring = sorted({(x + dx, y + dy) for (x, y) in outer for dx, dy in ((1, 0), (-1, 0), (0, 1))
                   if (x + dx, y + dy) not in outer})
    for x, y in ring:
        f = (y - top_y) / max(L, 1)
        left = x < centre(min(y - top_y, int(L)))
        if left and f < 0.8 and (y + i) % 3 == 0:
            put(im, x, y, HEAT[5] if (y // 4 + i) % 2 else WHITE)
        else:
            put(im, x, y, OUTLINE)
    # layers, inner ones with a 1 px dithered seam onto the layer below (stepped, never blended)
    for n_, (mask, col) in enumerate(layers):
        for p in mask:
            put(im, *p, col)
        if n_ + 1 < len(layers):
            nxt_col = layers[n_ + 1][1]
            nxt = layers[n_ + 1][0]
            for (x, y) in nxt:
                for q in ((x - 1, y), (x + 1, y)):
                    if q not in nxt and q in mask and (q[0] + q[1]) % 2 == 0:
                        put(im, *q, nxt_col)
    for p, col in tongues:
        put(im, *p, col)
    # sparks of heat drifting off the flame's sides, different each frame
    for k in range(3):
        sx = ANCHOR_X + (-1) ** (k + i) * (5 + (i * 2 + k * 3) % 6)
        sy = top_y + 6 + (i * 5 + k * 7) % max(int(length) - 6, 1)
        put(im, sx, sy, HEAT[5] if k % 2 else HEAT[3])
    # a nozzle plate under the car, its lit left rim with a white glint
    prx = 10 * life + 3
    disc(im, ANCHOR_X, top_y - 1, prx, 3.5, STEEL)
    # rim highlight: the plate's top-left outline turns to lit steel (a dark pixel every few), and the
    # front rim under it catches the flame's light, so the outline is broken by highlights
    px = im.load()
    for x in range(int(ANCHOR_X - prx) - 1, int(ANCHOR_X + prx) + 2):
        for y in range(top_y - 6, top_y + 3):
            if not (0 <= x < SIZE and 0 <= y < SIZE) or px[x, y][:3] != OUTLINE:
                continue
            u, v = (x - ANCHOR_X) / prx, (y - (top_y - 1)) / 3.5
            if v < -0.2 and u < 0.1 and (x + i) % 3 == 0:
                px[x, y] = (STEEL[3] if u < -0.3 else STEEL[2]) + (255,)
            elif v > 0.4 and abs(u) < 0.45 and (x + i) % 3 == 0:
                px[x, y] = HEAT[3] + (255,)
    put(im, ANCHOR_X - int(6 * life) - 1, top_y - 3, WHITE)
    return im


def stunt_sparks(i):
    """Sparks burst out from under the car and drop. Every spark is a 2 px wide streak (white-hot head,
    orange tail) so it survives the 0.5 draw scale; everything gets an almost-black outline, broken
    above the white heads; the start flash is a stepped, dithered halo with an outlined hot core."""
    im = blank()
    t = i / (FRAMES - 1)
    cy = ANCHOR_Y - 10                     # under the car, a little above the ground point
    layer = {}                             # (x, y) -> colour, painted back to front

    def dot(x, y, col):
        x, y = int(round(x)), int(round(y))
        if 3 <= x < SIZE - 3 and 3 <= y < SIZE - 3:
            layer[(x, y)] = col

    breaks = set()                         # outline pixels left out on purpose (the highlight breaks)
    if t < 0.3:    # the flash, frames 0-2: a big white core, then stepped rings with a 1 px dithered seam
        # between each pair, out to a dark red-brown dithered halo; it swells in frame 1 and rises
        r0 = (13, 16, 9)[i]
        fy = cy - (0, 3, 5)[i]             # the glow lifts off the ground as it spreads
        rays = i < 2
        steps = [(0.34, WHITE), (0.50, HEAT[5]), (0.64, HEAT[3]), (0.78, HEAT[1]), (0.90, EMBER[1]), (1.0, EMBER[0])]
        if i == 2:
            steps = [(0.2, HEAT[5])] + steps[2:]
        for y in range(int(fy - r0) - 1, int(fy + r0) + 2):
            for x in range(int(ANCHOR_X - r0) - 1, int(ANCHOR_X + r0) + 2):
                u, v = (x - ANCHOR_X) / r0, (y - fy) / (r0 * 0.7)
                d = math.sqrt(u * u + v * v)
                if d > 1.0:
                    continue
                j = next(n for n, (edge, _) in enumerate(steps) if d <= edge)
                inner = steps[j - 1][0] if j else 0.0
                # the inner 1/3 of each ring is a checker of this ring and the one inside it
                if j and (d - inner) < (steps[j][0] - inner) * 0.34 and (x + y) % 2 == 0:
                    j -= 1
                if j == len(steps) - 1 and (x + y) % 2:   # the outermost halo is a sparse dither
                    j -= 1
                dot(x, y, steps[j][1])
        # break the flash outline at its upper left with two highlight pixels
        bx, by = int(round(ANCHOR_X - r0 * 0.5)), int(round(fy - r0 * 0.7 * 0.85))
        breaks.update({(bx, by - 1), (bx + 1, by - 1), (bx - 1, by)})
        dot(bx, by, HEAT[5])
        dot(bx + 1, by, HEAT[4])
        if rays:   # four short stepped rays out of the core (up, down-ish, left, right): a burst, not a disc
            for (rx, ry), ln in (((0, -1), 6), ((-1, 0), 5), ((1, 0), 5), ((0, 1), 3)):
                for s in range(ln):
                    d0 = (r0 * (0.7 if ry else 1.0)) + s
                    col = (WHITE, HEAT[5], HEAT[5], HEAT[4], HEAT[3], HEAT[2])[s]
                    dot(ANCHOR_X + rx * d0, fy + ry * d0, col)

    # the sparks: short radial streaks fanned over the upper half, each thrown up and out from under
    # the car, peaking in frames 2-4, then dropping in an arc and landing (skidding a little) on the ground
    n = 16
    g = 120
    heads = []
    for k in range(n):
        a = -math.pi * (0.16 + 0.68 * ((k * 5) % n) / (n - 1))   # spread the fan, neighbours apart
        S = 70 + 30 * ((k * 7) % 5) / 4
        ts = max(0.0, t - 0.03 * (k % 3))           # a few sparks leave a moment later
        if ts <= 0.0:
            continue
        vx0, vy0 = math.cos(a) * S * 0.48, math.sin(a) * S
        ground = ANCHOR_Y + ((k % 5) - 2) * 3       # where this spark lands, around the ground point
        x0 = ANCHOR_X + vx0 * ts
        y0 = cy + vy0 * ts + g * ts * ts
        vx, vy = vx0, vy0 + 2 * g * ts
        landed = y0 >= ground and vy > 0
        if landed:                                  # landed: lies on the ground, a short skid sideways
            y0, vy = ground, 0.0
        m = math.hypot(vx, vy) or 1.0
        dx, dy = vx / m, vy / m
        hot = t < 0.6
        length = 4 if landed else (6 if t < 0.8 else 5)
        tail = [HEAT[5], HEAT[4], HEAT[3], HEAT[2], HEAT[1]] if hot else [HEAT[4], HEAT[3], HEAT[2], HEAT[1], HEAT[0]]
        for s in range(length - 1, 1, -1):          # a straight 1 px tail, cooling backward
            dot(x0 - dx * s, y0 - dy * s, tail[min((s - 2) * len(tail) // (length - 2), len(tail) - 1)])
        heads.append((int(round(x0)), int(round(y0)), hot))
    for hx, hy, hot in heads:   # the 2x2 head with its own small stepped halo, painted over the tails
        if hot:
            for oy in range(-1, 3):
                for ox in range(-1, 3):
                    if (ox in (-1, 2) or oy in (-1, 2)) and (hx + ox + hy + oy) % 2 == 0 \
                            and (hx + ox, hy + oy) not in layer:
                        dot(hx + ox, hy + oy, HEAT[2])
        dot(hx, hy, WHITE)
        dot(hx + 1, hy, HEAT[5])
        dot(hx, hy + 1, HEAT[5] if hot else HEAT[4])
        dot(hx + 1, hy + 1, HEAT[3])

    for (x, y), col in layer.items():
        put(im, x, y, col)
    # the outline: every empty 4-neighbour, except right above a white-hot pixel (the break)
    for (x, y), col in layer.items():
        for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            p = (x + ox, y + oy)
            if p in layer or p in breaks:
                continue
            if (oy == -1 and col in (WHITE, HEAT[5])) or (ox == -1 and col == WHITE):
                continue
            put(im, p[0], p[1], OUTLINE)
    return im


WAVE_HALO = [(36, 58, 104), (48, 76, 128)]                      # the ring glow's outer dithered bands


def _wave_band(im, r, w, fade, bright):
    """One glowing ground ring (2:1 ellipse) of radius r, drawn from a distance field. A solid pale
    blue-white body of half-width w (px; white centre line on the bright ring), then stepped darker
    blue bands dithered on both edges, and a few dark outline pixels on the outer edge only, broken by
    the dither. `fade` (0..1) thins the outer dithered bands only, so the body stays readable."""
    cx, cy = ANCHOR_X, ANCHOR_Y
    centre = WHITE if bright else WAVE[3]
    body = WAVE[3] if bright else WAVE[2]
    step1 = WAVE[2] if bright else WAVE[1]
    step2 = WAVE[1] if bright else WAVE[0]
    step3 = WAVE[0] if bright else None
    for y in range(SIZE):
        for x in range(SIZE):
            dx, dy = x - cx, (y - cy) * 2.0             # undo the 2:1 squash
            q = math.hypot(dx, dy) / r
            if q < 0.05:
                continue
            s = math.hypot(x - cx, y - cy) * (1.0 - 1.0 / q)   # signed distance along the ray, + outward
            a = abs(s)
            lead = s > 0
            col = None
            if a < 0.5:
                col = centre
            elif a < w:
                col = body
            elif a < w + 1.0:
                col = step1                                    # solid first step, both edges
            elif a < w + 2.0:
                if lead and bright and (x + 3 * y) % 7 == 0:
                    col = OUTLINE                              # a few dark outline pixels, outer edge only
                elif dither_keep(x, y, (0.5 if lead else 0.4) * (1.0 - fade)):
                    col = step2
            elif lead and step3 and a < w + 3.0:
                if dither_keep(x + 2, y + 1, 0.25 * (1.0 - fade)):
                    col = step3
            if col is not None:
                put(im, x, y, col)


def shockwave_ring(i):
    im = blank()
    t = i / (FRAMES - 1)
    ease = math.sin(t * math.pi * 0.5)
    r = lerp(9, 40, ease)
    w = lerp(1.6, 0.9, t)                     # body about 3 px wide at the start, thinning to 2 px
    fade = max(0.0, (t - 0.6) / 0.4) * 0.7    # the edge dither breaks up at the end; the body thins
    # the fainter second ring trails behind (inside) the first, from frame 1, kept well apart from it
    if i >= 1:
        t2 = (i - 1) / (FRAMES - 2)
        r2 = lerp(4, 23, math.sin(t2 * math.pi * 0.5))
        _wave_band(im, r2, lerp(1.1, 0.6, t2), min(1.0, fade + 0.2), False)
    _wave_band(im, r, w, fade, True)
    return im


DRAW = {"dash_cloud": dash_cloud, "spring": spring, "jet_thrust": jet_thrust,
        "stunt_sparks": stunt_sparks, "shockwave_ring": shockwave_ring}


def sheet(effect_id):
    out = Image.new("RGBA", (SIZE * FRAMES, SIZE), (0, 0, 0, 0))
    for i in range(FRAMES):
        out.paste(DRAW[effect_id](i), (i * SIZE, 0))
    return out


def build(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for effect_id in IDS:
        sheet(effect_id).save(out_dir / f"{effect_id}.png")
    record = {
        "ids": IDS, "frames": FRAMES, "frame_size": SIZE, "anchor": [ANCHOR_X, ANCHOR_Y],
        "task": "T-556",
        "made_by": "game/tools/build_jump_effects.py (a script; no PixelLab call). Byte-identical every run.",
        "used_by": "game/scripts/driving/jump_effect.gd (draw_effect), drawn at 0.5, one row of frames per sheet; "
                   "no per-direction art: every effect is round or stands straight under the car.",
    }
    (out_dir / "jump_effects.json").write_text(json.dumps(record, indent=1) + "\n", encoding="utf-8")


def check(out_dir: Path) -> int:
    bad = 0
    for effect_id in IDS:
        path = out_dir / f"{effect_id}.png"
        w, h, rows = decode_png(path.read_bytes())
        results = art_checks(rows, size=(SIZE, SIZE), frames=FRAMES)
        fails = [r for r in results if not r["ok"]]
        print(effect_id, "OK" if not fails else fails)
        bad += len(fails)
    return 1 if bad else 0


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    out = OUT_DIR
    if "--out" in argv:
        k = argv.index("--out")
        out = Path(argv[k + 1])
        del argv[k:k + 2]
    cmd = argv[0] if argv else "build"
    if cmd == "build":
        build(out)
        return 0
    if cmd == "check":
        return check(out)
    if cmd == "preview":   # preview <id> <dest.png>: the sheet x4, nearest, on a dark and a light band
        src = Image.open(out / f"{argv[1]}.png").convert("RGBA")
        big = src.resize((src.width * 4, src.height * 4), Image.NEAREST)
        canvas = Image.new("RGBA", (big.width, big.height * 2), (24, 26, 40, 255))
        canvas.paste((200, 204, 212, 255), (0, big.height, big.width, big.height * 2))
        canvas.alpha_composite(big, (0, 0))
        canvas.alpha_composite(big, (0, big.height))
        canvas.save(argv[2])
        print(argv[2], len(src.getcolors(1 << 16)), "colours incl. empty")
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
