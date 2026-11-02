#!/usr/bin/env python3
"""Draws Bricks' impact wave (task T-325; no PixelLab call).

Weapons, Decisions, "Bricks" (board, 2026-10-28): each landing after a jump sends an
impact wave out around the car. The art (T-325's description): a ring on the ground with
dust and brick chips, in the City's colours (Visual style, Decisions, "City colours":
cool blue-grey, pale white and pale blue), never Greenbull's, in the pixel rules
(Visual style, Content, "Rules"): hard pixel edges, every pixel opaque or transparent,
a dark selective outline, at most 30 colours.

One one-row sheet of FRAMES stepped frames per damage radius the tiers use (read from
game/data/weapons.json), so the ring is drawn at its final size at every tier and is
never scaled: 32 art pixels per unit, shown at 0.5 in the run (rule 3). The ground
circle of radius r is drawn as the run's isometric ellipse (run.gd ISO_TRANSFORM,
doubled to art pixels). The timing matches bricks.gd's BricksWave: FRAME_SECONDS a
frame, the ring easing out from START_RADIUS to the radius in RING_SECONDS, then
thinning and crumbling away; dust puffs kicked up behind the ring grow, rise and
shrink; brick chips hop out and drop. Nothing fades: pixels appear or go.

T-498: tier 8's widest wave (three rings, inner to outer) is one sheet too, but a
sparse one: see "the widest wave" below.

Commands (from the repo root):
  python game/tools/build_bricks_wave.py build                  # every radius into game/art/weapons/
  python game/tools/build_bricks_wave.py build --radius 4 --out X.png   # one sheet (style loop versions)
  python game/tools/build_bricks_wave.py check                  # checks the committed sheets
  python game/tools/build_bricks_wave.py preview --png X.png --out Y.png  # enlarged, dark and light ground

Running build twice gives byte-identical files.
"""
from __future__ import annotations

import argparse
import json
import math
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_rules as rules  # noqa: E402
from remove_car_shadow import write_png  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
REPO = GAME.parent
OUT_DIR = GAME / "art" / "weapons"
WEAPONS_JSON = GAME / "data" / "weapons.json"

ART_PX = 32            # art pixels per unit (rule 3)
FRAMES = 12
FRAME_SECONDS = 0.05   # bricks.gd BricksWave.FRAME_SECONDS
RING_SECONDS = 0.35    # bricks.gd BricksWave.RING_SECONDS
START_RADIUS = 0.6     # bricks.gd BricksWave.START_RADIUS
MARGIN = 10            # art px round the ring
TOP = 44               # art px above the ring for rising dust and hopping chips

# The City's colours (steel and glass, cool blue-grey), dust greys, brick browns.
OUTLINE = (20, 24, 40)
RING_WHITE = (250, 252, 255)   # the glowing core (rule 5: the glow is bright pixels)
RING_GLOW = (204, 226, 248)    # pale blue, the halo's first step
RING_PALE = (176, 200, 228)
RING_MID = (126, 148, 182)
RING_GREY = (88, 104, 134)
RING_DARK = (58, 70, 98)
DUST_WHITE = (216, 222, 230)
DUST_LIGHT = (180, 188, 200)
DUST_MID = (140, 148, 164)
DUST_DARK = (102, 110, 128)
# Dull, dark brick browns (not orange or amber, so the chips never read as fire).
BRICK_TOP = (170, 122, 102)
BRICK_LIGHT = (140, 94, 78)
BRICK = (112, 70, 60)
BRICK_DARK = (78, 48, 46)
COLOURS = [OUTLINE, RING_WHITE, RING_GLOW, RING_PALE, RING_MID, RING_GREY, RING_DARK, DUST_WHITE,
           DUST_LIGHT, DUST_MID, DUST_DARK, BRICK_TOP, BRICK_LIGHT, BRICK, BRICK_DARK]
# One shade darker on the far half of the ring (the side away from the viewer); the
# white core stays white all round, so the glow reads on both halves.
FAR = {RING_GLOW: RING_PALE, RING_PALE: RING_MID, RING_MID: RING_GREY, RING_GREY: RING_DARK}

PUFFS = 14
CHIPS = 24
SEGMENTS = 30          # the ring breaks into this many pieces as it crumbles
# Per frame after the ring stops (index = frames since it reached the radius).
AFTER_WIDTH = [0.26, 0.23, 0.21, 0.19, 0.18]   # band width, units
AFTER_GAP = [0.0, 0.16, 0.32, 0.48, 0.62]      # share of each piece broken away
AFTER_HALO = [2, 2, 1, 0, 0]                   # halo steps still shown
HALO_1 = 0.13          # units: the first, denser halo step's width
HALO_2 = 0.24          # units: where the second, sparser step ends
SEED = 325


# --- radii and names -------------------------------------------------------------

def tier_waves(path=WEAPONS_JSON):
    """Every wave Bricks' tiers reach (weapons.json `bricks`): {radius: rings}. The
    radius is the base radius times each `radius_multiplier` and `widest_wave` up to
    the tier, rounded to 0.01; rings is 1, or a widest_wave's value (T-498: the wave
    becomes that many rings, at the earlier radius times 1, 2, 3 ...)."""
    b = json.loads(Path(path).read_text(encoding="utf-8"))["bricks"]
    r, rings, out = float(b["radius"]), 1, {}
    out[round(r, 2)] = rings
    for t in sorted(b.get("tiers", []), key=lambda t: t["tier"]):
        if t.get("effect") == "radius_multiplier":
            r *= float(t["value"])
        elif t.get("effect") == "widest_wave":
            r *= float(t["value"])
            rings *= int(round(float(t["value"])))
        out[round(r, 2)] = rings
    return out


def tier_radii(path=WEAPONS_JSON):
    """Every damage radius Bricks' tiers reach, ascending (see tier_waves)."""
    return sorted(tier_waves(path))


def ring_interval(path=WEAPONS_JSON):
    """Seconds between one ring of a widest wave reaching its radius and the next
    (weapons.json bricks.ring_interval; bricks.gd hits each ring at that time)."""
    b = json.loads(Path(path).read_text(encoding="utf-8"))["bricks"]
    return float(b.get("ring_interval", 0.15))


def sheet_name(radius):
    """bricks_wave_r4_0, bricks_wave_r7_8, ... (the game finds a sheet by this name)."""
    return "bricks_wave_r" + ("%.1f" % radius).replace(".", "_")


def frame_size(radius):
    hw = math.ceil(radius * math.sqrt(2) * ART_PX) + MARGIN
    hh = math.ceil(radius * math.sqrt(2) * ART_PX / 2) + MARGIN
    return 2 * hw, TOP + 2 * hh, (hw, TOP + hh)


# --- timing (bricks.gd BricksWave) ---------------------------------------------------

def ring_radius(f, radius, start=START_RADIUS, travel=RING_SECONDS):
    """The ring's radius at frame f: eases out from `start` to `radius` in `travel` seconds."""
    t = min(f * FRAME_SECONDS / travel, 1.0)
    e = 1.0 - (1.0 - t) * (1.0 - t)
    return start + (radius - start) * e


def _x_ranges(cx, w, y_off, d_lo, d_hi, slack=2):
    """Art-pixel x ranges of the row at offset y_off from the centre whose ground
    distance can lie in [d_lo, d_hi] (a superset, `slack` px wider each side; the exact
    test is the caller's). One range across the middle, or two either side of it."""
    b = y_off / (ART_PX / 2)
    hi2 = 2 * d_hi * d_hi - b * b
    if hi2 < 0:
        return []
    a_hi = math.sqrt(hi2) * ART_PX
    lo2 = 2 * max(d_lo, 0.0) ** 2 - b * b
    x1 = max(0, int(cx - a_hi) - slack)
    x2 = min(w, int(cx + a_hi) + slack + 1)
    if lo2 <= 0:
        return [range(x1, x2)]
    a_lo = math.sqrt(lo2) * ART_PX
    return [range(x1, min(x2, int(cx - a_lo) + slack + 1)), range(max(x1, int(cx + a_lo) - slack), x2)]


def ground_dist(x, y):
    """Ground distance (units) of art pixel offset (x, y) from the centre (inverse iso)."""
    a, b = x / ART_PX, y / (ART_PX / 2)
    return math.sqrt((a * a + b * b) / 2.0)


def iso(u, v):
    return (u - v) * ART_PX, (u + v) * ART_PX / 2


def _hash(x, y, f):
    return ((x * 73856093) ^ (y * 19349663) ^ (f * 83492791)) & 1023


# --- drawing -------------------------------------------------------------------------

def draw_frame(f, radius, rnd_puffs, rnd_chips, ring=None):
    """One frame of one ring. `ring` (T-498, a widest wave's outer rings): start (the
    radius it eases out from), inner (where its dust and chips start), travel (seconds
    to reach `radius`), frames (its own frame count), limit (the sheet's radius, the
    halo's bound). None: T-325's single wave (START_RADIUS, 0, RING_SECONDS, FRAMES,
    radius)."""
    ring = ring or {}
    start = ring.get("start", START_RADIUS)
    inner = ring.get("inner", 0.0)
    travel = ring.get("travel", RING_SECONDS)
    n_frames = ring.get("frames", FRAMES)
    w, h, (cx, cy) = frame_size(radius)
    px = [[None] * w for _ in range(h)]
    life = (f + 0.5) / n_frames
    travelling = f * FRAME_SECONDS < travel - 1e-9
    after = 0 if travelling else f - round(travel / FRAME_SECONDS)   # frames since the ring stopped
    rr = ring_radius(f, radius, start, travel)
    a_i = min(after, len(AFTER_WIDTH) - 1)
    bw = 0.34 if travelling else AFTER_WIDTH[a_i]
    core = 0.15 if travelling else 0.11          # the white leading edge, units (3 px at the ellipse's ends)
    gap = 0.0 if travelling else AFTER_GAP[a_i]
    halo_steps = 2 if travelling else AFTER_HALO[a_i]

    def piece(x, y):
        """(segment, place in it 0..1) of art pixel offset (x, y) round the ring."""
        a, b = x / ART_PX, y / (ART_PX / 2)
        th = math.atan2((b - a) / 2, (a + b) / 2) + math.pi
        t = th / math.tau * SEGMENTS
        seg = int(t) % SEGMENTS
        return seg, t - int(t)

    def broken(x, y):
        if gap <= 0:
            return False
        seg, p = piece(x, y)
        g = gap * (0.55 + 0.9 * (_hash(seg, 7, 1) / 1023.0))
        return p < min(g, 0.95)

    def band(r_out, width, inner_only_grey=False):
        hw = int(r_out * math.sqrt(2) * ART_PX) + 2
        hh = int(r_out * math.sqrt(2) * ART_PX / 2) + 2
        for y in range(max(0, cy - hh), min(h, cy + hh + 1)):
            for x in (x for xr in _x_ranges(cx, w, y - cy, r_out - width, r_out) for x in xr
                      if cx - hw <= x <= cx + hw):
                d = ground_dist(x - cx, y - cy)
                if not (r_out - width <= d <= r_out):
                    continue
                if broken(x - cx, y - cy):
                    continue
                s = (d - (r_out - width)) / width
                if inner_only_grey:
                    c = RING_GREY
                elif r_out - d <= core:
                    c = RING_WHITE
                elif s > 0.55:
                    c = RING_PALE if travelling else RING_GLOW
                elif s > 0.25:
                    c = RING_PALE
                else:
                    c = RING_MID
                if y < cy:
                    c = FAR.get(c, c)
                px[y][x] = c

    band(rr, bw)
    if travelling and rr > start + 0.5:
        band(rr * 0.7 if inner <= 0 else inner + (rr - inner) * 0.7, 0.07, inner_only_grey=True)
    _outline(px)
    # A second navy pixel on the ring's outer edge, so the white core stands off any ground.
    add = set()
    y_lo, y_hi = max(1, cy - int(rr * 23) - 4), min(h - 1, cy + int(rr * 23) + 5)
    for y in range(max(0, y_lo - 1), min(h, y_hi + 1)):
        row = px[y]
        for x in [x for x, c in enumerate(row) if c is not None and c == OUTLINE]:
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if y_lo <= ny < y_hi and 1 <= nx < w - 1 and px[ny][nx] is None:
                    if ground_dist(nx - cx, ny - cy) > rr:
                        add.add((nx, ny))
    for x, y in add:
        px[y][x] = OUTLINE
    # The glow's halo: checker-dithered steps just outside and inside the ring, no blur
    # (rule 5). The first step is pale blue on a checker, the second a sparser darker blue.
    if halo_steps:
        limit = ring.get("limit", radius) + (MARGIN - 1) / (math.sqrt(2) * ART_PX)   # the halo stays inside the frame
        hw = int((rr + HALO_2) * math.sqrt(2) * ART_PX) + 2
        hh = int((rr + HALO_2) * math.sqrt(2) * ART_PX / 2) + 2
        for y in range(max(0, cy - hh), min(h, cy + hh + 1)):
            for x in (x for xr in _x_ranges(cx, w, y - cy, rr - bw - HALO_2, rr + HALO_2) for x in xr
                      if cx - hw <= x <= cx + hw):
                if px[y][x] is not None or broken(x - cx, y - cy):
                    continue
                d = ground_dist(x - cx, y - cy)
                if d > limit:
                    continue
                out_d = d - rr                 # outside the ring's leading edge
                in_d = (rr - bw) - d           # inside its trailing edge
                c = None
                # Darker blues than the white core, so core and halo read as two things.
                if 0 < out_d <= HALO_1 and (x + y) % 2 == 0:
                    c = RING_MID
                elif halo_steps > 1 and HALO_1 < out_d <= HALO_2 and x % 2 == 0 and y % 2 == 0:
                    c = RING_GREY
                elif 0 < in_d <= HALO_1 and (x + y) % 2 == 0:
                    c = RING_MID
                elif halo_steps > 1 and HALO_1 < in_d <= HALO_2 and x % 2 == 0 and y % 2 == 0:
                    c = RING_GREY
                if c is not None:
                    px[y][x] = FAR.get(c, c) if y < cy else c
    # Pieces of the ring falling away into the gaps as it crumbles.
    if gap > 0:
        for seg in range(SEGMENTS):
            if _hash(seg, 11, 3) < 200:
                continue
            th = (seg + 0.5 * gap) / SEGMENTS * math.tau - math.pi
            u, v = math.cos(th) * rr, math.sin(th) * rr
            gx, gy = iso(u, v)
            drop = 1 + after * 2
            _fragment(px, int(round(cx + gx)), int(round(cy + gy + drop)), False)
    # Dust and chips, far ones first so the near ones cover them.
    sprites = []
    for p in rnd_puffs:
        sprites.append(("puff", p))
    for c in rnd_chips:
        sprites.append(("chip", c))
    placed = []
    for kind, s in sprites:
        u, v = math.cos(s["a"]), math.sin(s["a"])
        if kind == "puff":
            d = inner + s["frac"] * (min(rr, radius) - inner)
            gx, gy = iso(u * d, v * d)
            grow = min(life / 0.3, 1.0) if life < 0.3 else max(0.0, 1.0 - (life - 0.3) / 0.7)
            r = s["size"] * grow
            if r < 1.5:
                continue
            placed.append((gy, kind, (cx + gx + s["dx"], cy + gy - life * s["rise"]), r, s))
        else:
            if life >= 0.86:
                continue
            l = life / 0.86
            d = inner + s["frac"] * (radius - inner) * l
            gx, gy = iso(u * d, v * d)
            hop = s["hop"] * 4.0 * l * (1.0 - l)
            placed.append((gy, kind, (cx + gx, cy + gy - hop), 0, s))
    placed.sort(key=lambda t: t[0])
    for _, kind, (x, y), r, s in placed:
        if kind == "puff":
            _puff(px, x, y, r, s)
        else:
            _chip(px, int(round(x)), int(round(y)), (s["spin"] + f) % 4, s["small"])
    return px


def _outline(px, colour=OUTLINE):
    """Every empty pixel next to a drawn one (not of `colour`) becomes `colour`. Walks
    only the drawn pixels (T-498: a widest wave's frames are mostly empty)."""
    h, w = len(px), len(px[0])
    add = set()
    for y in range(h):
        row = px[y]
        for x in [x for x, c in enumerate(row) if c is not None and c != colour]:
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < w and 0 <= ny < h and px[ny][nx] is None:
                    add.add((nx, ny))
    for x, y in add:
        px[y][x] = colour


def _puff(px, x, y, r, s):
    """A dust cloud: five lumps with ragged, stepped edges (each lump's radius jumps
    from one angle step to the next), five shade steps lit from the top left, a navy
    outline broken by light dust on the lit side, and loose specks round it."""
    h, w = len(px), len(px[0])
    seed = int(s["a"] * 1000) & 1023
    # A wide, low cloud of uneven lumps (wider than tall, so it reads as kicked-up dust,
    # not a ball): small wisps out to the sides and on top.
    lumps = [(0.0, 0.0, r * 0.8), (-r * 0.85, r * 0.25, r * 0.55), (r * 0.9, r * 0.2, r * 0.6),
             (-r * 1.45, r * 0.45, r * 0.32), (r * 1.5, r * 0.4, r * 0.3),
             (-r * 0.45, -r * 0.45, r * 0.5), (r * 0.5, -r * 0.4, r * 0.45)]
    cells = {}
    for li, (lx, ly, lr) in enumerate(lumps):
        for yy in range(int(y + ly - lr) - 2, int(y + ly + lr) + 3):
            for xx in range(int(x + lx - lr * 1.3) - 2, int(x + lx + lr * 1.3) + 3):
                dx, dy = (xx + 0.5 - (x + lx)) / 1.3, yy + 0.5 - (y + ly)
                step = int((math.atan2(dy, dx) + math.pi) / math.tau * 7) % 7
                rag = 0.55 + 0.6 * (_hash(step, li, seed) / 1023.0)   # stepped, ragged edge
                if dx * dx + dy * dy <= (lr * rag) ** 2:
                    cells[(xx, yy)] = True
    for (xx, yy) in cells:
        k = (0.6 * (xx + 0.5 - x) / 1.3 + 1.4 * (yy + 0.5 - y)) / r
        if k < -0.75:
            cells[(xx, yy)] = DUST_WHITE
        elif k < -0.25:
            cells[(xx, yy)] = DUST_LIGHT
        elif k < 0.1:
            cells[(xx, yy)] = DUST_MID
        elif k < 0.3:
            # dithered step into the underside's shadow
            cells[(xx, yy)] = DUST_DARK if (xx + yy) % 2 else DUST_MID
        elif k < 0.55:
            cells[(xx, yy)] = DUST_DARK
        elif k < 0.75:
            cells[(xx, yy)] = RING_DARK if (xx + yy) % 2 else DUST_DARK
        else:
            cells[(xx, yy)] = RING_DARK
    # One bright highlight pixel pair on each billow's lit top-left.
    for lx, ly, lr in lumps[:3] + lumps[5:]:
        hx, hy = int(x + lx - lr * 0.45), int(y + ly - lr * 0.45)
        for p in ((hx, hy), (hx + 1, hy)):
            if p in cells:
                cells[p] = RING_WHITE
    edge = set()
    for (xx, yy) in cells:
        for nx, ny in ((xx - 1, yy), (xx + 1, yy), (xx, yy - 1), (xx, yy + 1)):
            if (nx, ny) not in cells:
                edge.add((nx, ny))
    for (xx, yy) in edge:
        if 0 <= xx < w and 0 <= yy < h:
            # Selective outline: the lit top-left edge breaks it with light dust pixels.
            lit = (xx - x) + (yy - y) < -r * 0.5
            px[yy][xx] = (DUST_LIGHT if (xx + yy) % 2 == 0 else DUST_WHITE) if lit else OUTLINE
    for (xx, yy), c in cells.items():
        if 0 <= xx < w and 0 <= yy < h:
            px[yy][xx] = c
    # Loose specks of dust round the cloud (2 x 1 and single pixels).
    for i in range(5):
        a = (_hash(i, seed, 5) / 1023.0) * math.tau
        dd = r * (1.25 + 0.4 * (_hash(i, seed, 9) / 1023.0))
        sx, sy = int(round(x + math.cos(a) * dd)), int(round(y + math.sin(a) * dd * 0.8))
        for ox in ((0, 1) if i % 2 == 0 else (0,)):
            if 0 <= sx + ox < w and 0 <= sy < h and px[sy][sx + ox] is None:
                px[sy][sx + ox] = DUST_LIGHT if i % 3 else DUST_MID


FRAGMENT = [".WWG", "WWGP", "GPPM", ".MM."]
FRAGMENT_SMALL = ["WG", "PM"]
FRAGMENT_COLOURS = {"W": RING_WHITE, "G": RING_GLOW, "P": RING_PALE, "M": RING_MID}


def _fragment(px, x, y, small):
    """A piece of the ring falling away as it crumbles, outlined in navy."""
    _stamp(px, x, y, FRAGMENT_SMALL if small else FRAGMENT, FRAGMENT_COLOURS)


def _stamp(px, x, y, shape, colours):
    h, w = len(px), len(px[0])
    sh, sw = len(shape), len(shape[0])
    x0, y0 = x - sw // 2, y - sh // 2
    cells = {(x0 + i, y0 + j): colours[ch] for j, row in enumerate(shape)
             for i, ch in enumerate(row) if ch != "."}
    for (xx, yy) in list(cells):
        for nx, ny in ((xx - 1, yy), (xx + 1, yy), (xx, yy - 1), (xx, yy + 1)):
            if (nx, ny) not in cells and 0 <= nx < w and 0 <= ny < h:
                px[ny][nx] = OUTLINE
    for (xx, yy), c in cells.items():
        if 0 <= xx < w and 0 <= yy < h:
            px[yy][xx] = c


# Brick chips: T is the lit top face, L the front face, B the side, D the shadow edge.
# H is the one bright highlight pixel on the top face's lit corner.
CHIP_SHAPES = [
    ["...HTTTT", "..TTTTTL", ".TTTTTLB", "LLLLLLBD", "BBBBBBBD", "DDDDDDD."],   # flat
    ["...HT...", "..TTTL..", ".TTTLBB.", "TTLLBBBD", ".LLBBBD.", "..BBDD..", "...D...."],   # turned
    ["HTTL", "TTLB", "LLBB", "LLBD", "LLBD", "LBBD", "BBDD", "DD.."],   # on end
    ["HTTTT...", "LTTTTTT.", "BLLTTTTL", ".BBLLLBD", "..BBBBBD", "...DDDD."],   # turned the other way
]
CHIP_SMALL = [
    [".HTT", "TTLB", "LLBD", "BBD."],
    ["HTT.", "LTTB", "LLBD", ".BD."],
    ["HT", "TL", "LB", "BD"],
    ["HTTL", "LLBD", "BBD."],
]
CHIP_COLOURS = {"H": RING_WHITE, "T": BRICK_TOP, "L": BRICK_LIGHT, "B": BRICK, "D": BRICK_DARK}


def _chip(px, x, y, phase, small=False):
    """A tumbling brick chip: one of four turns, lit top face, outlined in the dark navy."""
    _stamp(px, x, y, (CHIP_SMALL if small else CHIP_SHAPES)[phase], CHIP_COLOURS)


def scatter(seed=SEED, n_puffs=PUFFS, n_chips=CHIPS):
    """The puffs and chips (the same pattern at every radius, scaled with it; a widest
    wave's outer rings have their own, more of them round the longer ring)."""
    rnd = random.Random(seed)
    puffs = []
    for i in range(n_puffs):
        puffs.append({"a": math.tau * (i + rnd.uniform(-0.3, 0.3)) / n_puffs, "frac": rnd.uniform(0.55, 0.95),
                      "size": rnd.uniform(8.0, 12.0), "rise": rnd.uniform(14.0, 26.0), "dx": rnd.uniform(-2, 2)})
    chips = []
    for i in range(n_chips):
        chips.append({"a": math.tau * (i + rnd.uniform(-0.4, 0.4)) / n_chips, "frac": rnd.uniform(0.3, 0.85),
                      "hop": rnd.uniform(16.0, 36.0), "spin": rnd.randrange(4), "small": i % 3 == 2})
    return puffs, chips


def build_sheet(radius):
    """The sheet's rows (RGBA tuples) and its record."""
    w, h, centre = frame_size(radius)
    puffs, chips = scatter()
    frames = [draw_frame(f, radius, puffs, chips) for f in range(FRAMES)]
    clear = (0, 0, 0, 0)
    rows = []
    for y in range(h):
        row = []
        for fr in frames:
            row.extend(clear if c is None else c + (255,) for c in fr[y])
        rows.append(row)
    record = {
        "file": sheet_name(radius) + ".png",
        "task": "T-325",
        "generator": "game/tools/build_bricks_wave.py (script-drawn, no PixelLab)",
        "radius_units": radius,
        "frames": FRAMES,
        "frame_width": w,
        "frame_height": h,
        "centre": list(centre),
        "frame_seconds": FRAME_SECONDS,
        "ring_seconds": RING_SECONDS,
        "start_radius_units": START_RADIUS,
        "art_px_per_unit": ART_PX,
        "draw_scale": 0.5,
        "resources_consulted": ["docs/visual-style.md", "docs/weapons.md", "docs/extended-narrative.md",
                                "game/scripts/weapons/bricks.gd"],
    }
    return rows, record


# --- the widest wave (T-498) ------------------------------------------------------------
#
# Tier 8 (Widest Wave, board, 2026-11-02): the radius times 3 and two extra crash rings
# round the usual one, the wave travelling from the inner ring out. Ring k (1 to rings)
# is drawn at its own radius (the tier 7 radius times k) by draw_frame: ring 1 is the
# tier 7 wave as it is (12 frames); ring k > 1 sets off when ring k - 1 reaches its
# radius, eases out from there to its own in ring_interval seconds (weapons.json, when
# bricks.gd hits it), then crumbles like the first. Its dust and chips are its own, more
# of them round the longer ring. One frame of all of it is 2304 x 1250 art pixels, too
# big for a one-row sheet (27 000 px wide, 130 MB in memory), and almost all of it is
# empty, so the sheet keeps only the CELL-high strips that hold pixels, packed into an
# atlas ATLAS_WIDTH wide; the record lists each frame's strips ("runs": atlas x, atlas y,
# frame x, frame y, width; all CELL high), and bricks.gd draws a frame strip by strip.

CELL = 16
ATLAS_WIDTH = 4096


def widest_timing(rings, interval):
    """[(first frame, frame count, travel seconds)] for rings 1 to `rings`, and the
    sheet's frame count."""
    out = [(0, FRAMES, RING_SECONDS)]
    reach = RING_SECONDS
    for _ in range(2, rings + 1):
        out.append((round(reach / FRAME_SECONDS), round(interval / FRAME_SECONDS) + len(AFTER_WIDTH), interval))
        reach += interval
    return out, max(s + n for s, n, _ in out)


def ring_reach_seconds(rings, interval):
    """Seconds after the landing at which ring k (1 to rings) reaches its radius."""
    return [RING_SECONDS + k * interval for k in range(rings)]


def draw_widest_frame(f, radius, rings, interval, scatters=None):
    """Frame f of a widest wave as an (h, w, 4) uint8 array (rows, then columns)."""
    import numpy as np
    W, H, (CX, CY) = frame_size(radius)
    canvas = np.zeros((H, W, 4), dtype=np.uint8)
    timing, _ = widest_timing(rings, interval)
    r1 = round(radius / rings, 2)
    scatters = scatters or {k: scatter() if k == 1 else scatter(SEED + k, PUFFS * k, CHIPS * k)
                            for k in range(1, rings + 1)}
    for k in range(rings, 0, -1):   # the outer rings first, the inner ones drawn over them
        first, n, travel = timing[k - 1]
        fl = f - first
        if fl < (0 if k == 1 else 1) or fl >= n:
            continue   # an outer ring shows once it has left the ring inside it
        rk = round(r1 * k, 2)
        ring = None if k == 1 else {"start": r1 * (k - 1), "inner": r1 * (k - 1), "travel": travel, "frames": n}
        px = draw_frame(fl, rk, *scatters[k], ring=ring)
        _, _, (cx, cy) = frame_size(rk)
        ox, oy = CX - cx, CY - cy
        for y, row in enumerate(px):
            for x in [x for x, c in enumerate(row) if c is not None]:
                canvas[y + oy, x + ox] = row[x] + (255,)
    return canvas


def build_widest(radius, rings, interval):
    """The widest wave's atlas (an (h, w, 4) uint8 array) and its record."""
    import numpy as np
    W, H, centre = frame_size(radius)
    _, total = widest_timing(rings, interval)
    r1 = round(radius / rings, 2)
    scatters = {k: scatter() if k == 1 else scatter(SEED + k, PUFFS * k, CHIPS * k) for k in range(1, rings + 1)}
    strips, runs = [], []   # strips: (frame, y, x, width) to copy; runs: per frame
    shelf_x, shelf_y = 0, 0
    frames = []
    for f in range(total):
        fr = draw_widest_frame(f, radius, rings, interval, scatters)
        frames.append(fr)
        mine = []
        for y in range(0, H, CELL):
            band = fr[y:y + CELL, :, 3]
            full = [bool(band[:, x:x + CELL].any()) for x in range(0, W, CELL)]
            c = 0
            while c < len(full):
                if not full[c]:
                    c += 1
                    continue
                e = c
                while e < len(full) and full[e]:
                    e += 1
                x0, width = c * CELL, min(e * CELL, W) - c * CELL
                if shelf_x + width > ATLAS_WIDTH:
                    shelf_x, shelf_y = 0, shelf_y + CELL
                mine.append([shelf_x, shelf_y, x0, y, width])
                strips.append((f, y, x0, width, shelf_x, shelf_y))
                shelf_x += width
                c = e
        runs.append(mine)
    atlas = np.zeros((shelf_y + CELL, ATLAS_WIDTH, 4), dtype=np.uint8)
    for f, y, x0, width, ax, ay in strips:
        part = frames[f][y:y + CELL, x0:x0 + width]
        atlas[ay:ay + part.shape[0], ax:ax + width] = part
    record = {
        "file": sheet_name(radius) + ".png",
        "task": "T-498",
        "generator": "game/tools/build_bricks_wave.py (script-drawn, no PixelLab)",
        "radius_units": radius,
        "rings": rings,
        "ring_radii_units": [round(r1 * k, 2) for k in range(1, rings + 1)],
        "ring_interval": interval,
        "ring_reach_seconds": [round(t, 4) for t in ring_reach_seconds(rings, interval)],
        "frames": total,
        "frame_width": W,
        "frame_height": H,
        "centre": list(centre),
        "layout": "runs",
        "cell": CELL,
        "atlas_width": ATLAS_WIDTH,
        "atlas_height": int(atlas.shape[0]),
        "runs": runs,
        "frame_seconds": FRAME_SECONDS,
        "ring_seconds": RING_SECONDS,
        "start_radius_units": START_RADIUS,
        "art_px_per_unit": ART_PX,
        "draw_scale": 0.5,
        "resources_consulted": ["docs/visual-style.md", "docs/weapons.md", "docs/extended-narrative.md",
                                "game/scripts/weapons/bricks.gd", "game/art/weapons/bricks_wave_r8_4.png"],
    }
    return atlas, record


def frames_of(atlas, record):
    """A runs sheet's frames, rebuilt as (h, w, 4) uint8 arrays (previews, tests)."""
    import numpy as np
    out = []
    for runs in record["runs"]:
        fr = np.zeros((record["frame_height"], record["frame_width"], 4), dtype=np.uint8)
        for ax, ay, fx, fy, width in runs:
            part = atlas[ay:ay + record["cell"], ax:ax + width]
            h = min(part.shape[0], fr.shape[0] - fy)
            fr[fy:fy + h, fx:fx + width] = part[:h]
        out.append(fr)
    return out


def write_png_array(path, arr):
    """write_png for an (h, w, 4) uint8 array (the same PNG, built fast)."""
    import struct
    import zlib
    h, w = arr.shape[0], arr.shape[1]
    raw = b"".join(b"\x00" + arr[y].tobytes() for y in range(h))
    ch = lambda t, b: struct.pack(">I", len(b)) + t + b + struct.pack(">I", zlib.crc32(t + b))
    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + ch(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                           + ch(b"IDAT", zlib.compress(raw, 9)) + ch(b"IEND", b""))


def write_sheet(radius, out_png, rings=1, interval=None):
    out_png = Path(out_png)
    out_png.parent.mkdir(parents=True, exist_ok=True)
    if rings > 1:
        atlas, record = build_widest(radius, rings, ring_interval() if interval is None else interval)
        write_png_array(out_png, atlas)
        rows = None
    else:
        rows, record = build_sheet(radius)
        write_png(out_png, rows)
    out_png.with_suffix(".json").write_text(json.dumps(record, indent=2 if rings == 1 else 1) + "\n", encoding="utf-8")
    return rows, record


def check_rows(rows, record):
    """Rule checks on one sheet: [(name, ok, detail)]."""
    out = []
    w, h = record["frame_width"] * record["frames"], record["frame_height"]
    if record.get("layout") == "runs":
        w, h = record["atlas_width"], record["atlas_height"]
    out.append(("sheet size", len(rows) == h and len(rows[0]) == w, "%dx%d" % (len(rows[0]), len(rows))))
    alphas = {p[3] for r in rows for p in r}
    out.append(("opaque or transparent", alphas <= {0, 255}, str(sorted(alphas))))
    cols = {p[:3] for r in rows for p in r if p[3] == 255}
    out.append(("at most 30 colours", len(cols) <= 30, "%d colours" % len(cols)))
    gb = [c for c in cols if rules.greenbull_colour(c)]
    out.append(("none of Greenbull's colours", not gb, str(gb)))
    corners = [rows[0][0][3], rows[-1][-1][3]]
    out.append(("transparent background", corners == [0, 0], str(corners)))
    return out


def preview(png, out, scale=2, frames=None):
    """The sheet enlarged (nearest neighbour), on the asphalt's dark grey above and a light grey below.
    frames: (first, last) to show only those frames (a close-up)."""
    from PIL import Image
    im = Image.open(png).convert("RGBA")
    record = json.loads(Path(png).with_suffix(".json").read_text(encoding="utf-8")) \
        if Path(png).with_suffix(".json").is_file() else {}
    if record.get("layout") == "runs":
        return preview_widest(png, record, out, frames)
    if frames:
        fw = im.size[0] // FRAMES
        im = im.crop((frames[0] * fw, 0, (frames[1] + 1) * fw, im.size[1]))
    w, h = im.size
    canvas = Image.new("RGBA", (w, h * 2), (40, 42, 52, 255))
    canvas.paste((206, 210, 218, 255), (0, h, w, h * 2))
    canvas.alpha_composite(im, (0, 0))
    canvas.alpha_composite(im, (0, h))
    canvas = canvas.resize((w * scale, h * 2 * scale), Image.NEAREST)
    canvas.convert("RGB").save(out)


def preview_widest(png, record, out, frames=None, columns=6, shrink=4):
    """A widest wave's frames on the asphalt's dark grey, `columns` a row, each shown at
    1/`shrink` (nearest neighbour; 4 is half the run's own size), numbered."""
    import numpy as np
    from PIL import Image, ImageDraw
    atlas = np.array(Image.open(png).convert("RGBA"))
    all_frames = frames_of(atlas, record)
    first, last = frames or (0, len(all_frames) - 1)
    chosen = list(range(first, last + 1))
    fw, fh = record["frame_width"] // shrink, record["frame_height"] // shrink
    rows = (len(chosen) + columns - 1) // columns
    canvas = Image.new("RGBA", (fw * min(columns, len(chosen)), fh * rows), (40, 42, 52, 255))
    draw = ImageDraw.Draw(canvas)
    for i, f in enumerate(chosen):
        im = Image.fromarray(all_frames[f], "RGBA").resize((fw, fh), Image.NEAREST)
        x, y = (i % columns) * fw, (i // columns) * fh
        canvas.alpha_composite(im, (x, y))
        draw.text((x + 6, y + 4), "frame %d  %.2f s" % (f, f * FRAME_SECONDS), fill=(230, 230, 230, 255))
    canvas.convert("RGB").save(out)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("--radius", type=float)
    b.add_argument("--out")
    sub.add_parser("check")
    p = sub.add_parser("preview")
    p.add_argument("--png", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--scale", type=int, default=2)
    p.add_argument("--frames", help="first-last frame to show, e.g. 3-5 (a close-up)")
    a = ap.parse_args(argv)
    if a.cmd == "build":
        if a.radius is not None or a.out:
            if a.radius is None or not a.out:
                ap.error("--radius and --out go together")
            write_sheet(a.radius, a.out, tier_waves().get(round(a.radius, 2), 1))
            print("wrote", a.out)
            return 0
        for r, rings in sorted(tier_waves().items()):
            path = OUT_DIR / (sheet_name(r) + ".png")
            write_sheet(r, path, rings)
            print("wrote", path.relative_to(REPO).as_posix())
        return 0
    if a.cmd == "preview":
        fr = tuple(int(v) for v in a.frames.split("-")) if a.frames else None
        preview(a.png, a.out, a.scale, fr)
        return 0
    bad = 0
    for r in tier_radii():
        path = OUT_DIR / (sheet_name(r) + ".png")
        if not path.is_file():
            print("missing", path)
            bad += 1
            continue
        _, _, rows = rules.decode_png(path.read_bytes())
        record = json.loads(path.with_suffix(".json").read_text(encoding="utf-8"))
        for name, ok, detail in check_rows(rows, record):
            print("%s %s: %s (%s)" % ("ok  " if ok else "FAIL", path.name, name, detail))
            bad += 0 if ok else 1
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
