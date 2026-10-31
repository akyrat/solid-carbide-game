#!/usr/bin/env python3
"""The livestream HUD's art (task T-339; HUD and menus, Decisions, "The HUD looks like a livestream").

Draws the HUD pieces that a script draws as well as PixelLab would (Visual style, Content, "Rules"), and
post-processes PixelLab raws for the others. Every piece is HUD art shown at 2x (one art pixel is two screen
pixels, like the likes heart), with hard pixel edges, only opaque or empty pixels, a transparent background and
none of Greenbull's light green or yellow (rule 6).

Commands (run from the repo root; each writes one PNG to --out, never overwriting an existing file unless --force):
  python game/tools/build_hud_livestream_art.py clock-panel   --out X.png      # 100 x 36 dark clock panel
  python game/tools/build_hud_livestream_art.py viewers-panel --out X.png      # 120 x 36 panel, cyan inner rim
  python game/tools/build_hud_livestream_art.py subgoal-frame --out X.png      # 64 x 64 frame, black inside
  python game/tools/build_hud_livestream_art.py digits        --out X.png      # 12 frames of 16 x 26: 0-9, colon, unlit 8
  python game/tools/build_hud_livestream_art.py live-badge    --out X.png      # 34 x 13 red LIVE badge
  python game/tools/build_hud_livestream_art.py fire          --out X.png      # 12 frames of 136 x 64 flames round the viewers panel
  python game/tools/build_hud_livestream_art.py heart         --out X.png      # 18 x 16 full heart
  python game/tools/build_hud_livestream_art.py heart-empty   --from FULL.png --out X.png   # the empty heart from any full heart
  python game/tools/build_hud_livestream_art.py eye           --out X.png      # 16 x 11 eye icon in the viewers cyan
  python game/tools/build_hud_livestream_art.py subs          --out X.png      # 22 x 22 subs icon: a person with a pink plus badge
  python game/tools/build_hud_livestream_art.py post RAW.png --out X.png --size WxH [--max-colors N] [--outline]
  python game/tools/build_hud_livestream_art.py request --description "..." --size WxH [--init PNG] [--init-strength N] --out REQ.json
  python game/tools/build_hud_livestream_art.py split SHEET.png --frames N --names a,b,... --out-dir DIR
  python game/tools/build_hud_livestream_art.py contact --out SHEET.png FILE.png ...   # enlarged, on dark and light

Every drawing is deterministic: the same command gives the same pixels.
"""
from __future__ import annotations

import argparse
import base64
import json
import math
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import reduce_palette  # noqa: E402

OUT = (8, 8, 15, 255)          # Hud.OUTLINE_COLOR, the HUD's dark outline
CLEAR = (0, 0, 0, 0)
HEART_RED = (219, 26, 41)      # Hud.HEART_COLOR, the board-approved heart red
VIEWERS = (51, 225, 255)       # the live viewers colour on the board's layout page (#33e1ff, a proposal)
PINK = (255, 72, 160)          # the game's own effect pink (Visual style, Summary)
FIRE = [(255, 250, 209), (255, 224, 77), (255, 184, 41), (255, 153, 20)]   # LikesFire.PALETTE, hot to tips
FIRE_EDGE = (150, 44, 10)


def rgba(c):
    return tuple(c) + (255,) if len(c) == 3 else tuple(c)


def new(w, h):
    return Image.new("RGBA", (w, h), CLEAR)


def put(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), rgba(c))


def opaque(im, x, y):
    return 0 <= x < im.width and 0 <= y < im.height and im.getpixel((x, y))[3] == 255


# --- panels ---

def rounded_inside(x, y, w, h, r):
    """True inside a w x h rectangle with stepped corners of radius r (corner pixels cut)."""
    if not (0 <= x < w and 0 <= y < h):
        return False
    return min(x, w - 1 - x) + min(y, h - 1 - y) >= r


def ring_depth(x, y, w, h, r):
    """How many pixels in from the rounded edge (0 = the outline ring)."""
    d = 0
    while rounded_inside(x - d - 1, y, w, h, r) and rounded_inside(x + d + 1, y, w, h, r) \
            and rounded_inside(x, y - d - 1, w, h, r) and rounded_inside(x, y + d + 1, w, h, r) \
            and rounded_inside(x - d - 1, y - d - 1, w, h, r) and rounded_inside(x + d + 1, y + d + 1, w, h, r) \
            and rounded_inside(x - d - 1, y + d + 1, w, h, r) and rounded_inside(x + d + 1, y - d - 1, w, h, r):
        d += 1
        if d > 8:
            break
    return d


def nearest_side(x, y, w, h):
    dist = {"top": y, "bottom": h - 1 - y, "left": x, "right": w - 1 - x}
    return min(dist, key=lambda k: (dist[k], ["top", "left", "right", "bottom"].index(k)))


BEZEL = {"top": [(104, 114, 136), (66, 73, 90), (56, 62, 77)],
         "left": [(84, 92, 112), (58, 64, 80), (50, 56, 70)],
         "right": [(44, 49, 62), (38, 42, 54), (34, 38, 49)],
         "bottom": [(36, 40, 52), (30, 33, 43), (26, 29, 38)]}
SCREEN, SCAN, GLARE = (10, 12, 17), (14, 17, 23), (25, 30, 40)


def panel(w, h, rim=None):
    """A dark device panel: a dark outline, a 3 pixel bevelled steel bezel lit from the top left, four screws, an
    inner rim (dark, or the given colour as a light and a dark step) and a black screen with scanlines and a glare."""
    im = new(w, h)
    for y in range(h):
        for x in range(w):
            if not rounded_inside(x, y, w, h, 2):
                continue
            d = ring_depth(x, y, w, h, 2)
            side = nearest_side(x, y, w, h)
            if d == 0:
                c = OUT
            elif d <= 3:
                c = BEZEL[side][d - 1]
            elif d == 4:
                if rim:
                    lit = side in ("top", "left")
                    c = rim if lit else tuple(int(v * 0.62) for v in rim)
                else:
                    c = (4, 5, 8)
            else:
                c = SCAN if (y % 2 == 1) else SCREEN
                k = x - y
                if 5 <= y <= 9 and 8 <= k - 4 <= 9:
                    c = GLARE
            put(im, x, y, c)
    for sx, sy in ((2, 2), (w - 4, 2), (2, h - 4), (w - 4, h - 4)):
        put(im, sx, sy, (150, 158, 176))
        put(im, sx + 1, sy, (92, 100, 118))
        put(im, sx, sy + 1, (92, 100, 118))
        put(im, sx + 1, sy + 1, (22, 24, 31))
    return im


PANEL_RADIUS = 2   # the HUD style sheet's stepped corner (Visual style, Decisions, "The HUD style sheet"; T-430)


def subgoal_frame(size=64, radius=PANEL_RADIUS):
    """The sub goal square: a dark outline, a 2 pixel white ring that reads over the street (shaded to blue-grey
    on its bottom and right), an inner dark outline and a black inside (from (4, 4) to (size-5, size-5)). Its
    corners are the sheet's stepped corner of radius 2, like every panel (T-339 had radius 3: pass 3 for that)."""
    im = new(size, size)
    for y in range(size):
        for x in range(size):
            if not rounded_inside(x, y, size, size, radius):
                continue
            d = ring_depth(x, y, size, size, radius)
            side = nearest_side(x, y, size, size)
            lit = side in ("top", "left")
            if d == 0 or d == 3:
                c = OUT
            elif d in (1, 2):
                if lit:
                    c = (250, 250, 252) if d == 1 else (226, 230, 238)
                else:
                    c = (180, 186, 200) if d == 1 else (150, 156, 172)
            else:
                c = (6, 7, 10)
            put(im, x, y, c)
    for i, (x, y) in enumerate(((5, 1), (6, 1), (1, 5), (1, 6))):
        put(im, x, y, (255, 255, 255))
    return im


# --- digits ---

DW, DH = 16, 26
SEGMENTS = {"a": ("h", 3), "g": ("h", 12), "d": ("h", 21), "f": ("v", 3, 5, 10), "b": ("v", 12, 5, 10),
            "e": ("v", 3, 14, 19), "c": ("v", 12, 14, 19)}
DIGIT_SEGS = {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd", "6": "afgedc",
              "7": "abc", "8": "abcdefg", "9": "abcdfg"}
GREY_CORE, GREY_SIDE, GREY_HALO1, GREY_HALO2, GREY_OFF = 255, 214, 138, 70, 40


def segment_pixels(name):
    """Pixels of one segment as {(x, y): is_centre_line}: a 3 pixel bar with tapered ends."""
    s = SEGMENTS[name]
    px = {}
    if s[0] == "h":
        yc = s[1]
        for x in range(5, 11):
            px[(x, yc)] = True
        for x in range(6, 10):
            px[(x, yc - 1)] = False
            px[(x, yc + 1)] = False
    else:
        xc, y0, y1 = s[1], s[2], s[3]
        for y in range(y0, y1 + 1):
            px[(xc, y)] = True
        for y in range(y0 + 1, y1):
            px[(xc - 1, y)] = False
            px[(xc + 1, y)] = False
    return px


def glyph_pixels(ch):
    if ch == ":":
        return {(x, y): (x == 7 and y in (9, 16)) for x in (7, 8) for y in (9, 10, 16, 17)}
    px = {}
    for seg in DIGIT_SEGS[ch]:
        px.update(segment_pixels(seg))
    return px


def draw_glyph(ch, off=False):
    """One digit frame in greyscale so the game can tint it: a white centre line, light grey sides and a two step
    halo (the drawn glow). `off` draws all seven segments dim with no halo, the unlit segments of an LCD."""
    im = new(DW, DH)
    px = glyph_pixels("8" if off else ch)
    if off:
        for (x, y) in px:
            put(im, x, y, (GREY_OFF,) * 3)
        return im
    near = lambda pts: {(x + dx, y + dy) for (x, y) in pts for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))}
    ring1 = near(px) - set(px)
    ring2 = near(set(px) | ring1) - set(px) - ring1
    for (x, y) in ring2:
        put(im, x, y, (GREY_HALO2,) * 3)
    for (x, y) in ring1:
        put(im, x, y, (GREY_HALO1,) * 3)
    for (x, y), centre in px.items():
        put(im, x, y, (GREY_CORE if centre else GREY_SIDE,) * 3)
    return im


DIGIT_ORDER = list("0123456789") + [":", "off"]
DIGIT_NAMES = [f"clock_digit_{c}" for c in "0123456789"] + ["clock_digit_colon", "clock_digit_off"]


def digits_sheet():
    sheet = new(DW * len(DIGIT_ORDER), DH)
    for i, ch in enumerate(DIGIT_ORDER):
        sheet.paste(draw_glyph("8", off=True) if ch == "off" else draw_glyph(ch), (i * DW, 0))
    return sheet


# --- the LIVE badge ---

LETTERS = {
    "L": ["XX...", "XX...", "XX...", "XX...", "XX...", "XXXXX", "XXXXX"],
    "I": ["XX", "XX", "XX", "XX", "XX", "XX", "XX"],
    "V": ["XX..XX", "XX..XX", "XX..XX", "XX..XX", ".XXXX.", ".XXXX.", "..XX.."],
    "E": ["XXXXX", "XX...", "XX...", "XXXX.", "XX...", "XXXXX", "XXXXX"],
}
DOT = [".XXX.", "XXXXX", "XXXXX", "XXXXX", ".XXX."]
BADGE_RED, BADGE_LIGHT, BADGE_DARK, BADGE_SHADOW = (228, 32, 44), (255, 98, 104), (166, 18, 30), (112, 10, 20)


def live_badge(highlights=True):
    """A stream's red LIVE badge: a white dot and LIVE in bold white pixel letters with a dark red drop shadow,
    on a red plate with a light top row and a dark bottom row, in the HUD's dark outline with stepped corners."""
    w, h = 34, 13
    im = new(w, h)
    for y in range(h):
        for x in range(w):
            if not rounded_inside(x, y, w, h, 2):
                continue
            d = ring_depth(x, y, w, h, 2)
            if d == 0:
                c = OUT
            elif y == 1:
                c = BADGE_LIGHT
            elif y == h - 2:
                c = BADGE_DARK
            else:
                c = BADGE_RED
            put(im, x, y, c)
    marks = []
    for r, line in enumerate(DOT):
        for c, ch in enumerate(line):
            if ch == "X":
                marks.append((3 + c, 4 + r))
    x = 10
    for letter in "LIVE":
        rows = LETTERS[letter]
        for r, line in enumerate(rows):
            for c, ch in enumerate(line):
                if ch == "X":
                    marks.append((x + c, 3 + r))
        x += len(rows[0]) + 1
    if highlights:
        for x in range(3, w - 3):  # light row also runs under the top; dark shade two rows deep at the bottom
            put(im, x, h - 3, BADGE_DARK)
        for y in range(3, h - 2):  # dark shade down the right inner edge, light down the left
            put(im, w - 2, y, BADGE_DARK)
            put(im, 1, y, BADGE_LIGHT)
        for x in range(3, 8):  # gloss on the top-left
            put(im, x, 2, BADGE_LIGHT)
        for x in (4, 5, 6):  # highlight pixels break the outline
            put(im, x, 0, BADGE_LIGHT)
        put(im, 1, 3, BADGE_LIGHT)
        put(im, w - 2, 2, BADGE_RED)
    mset = set(marks)
    for (mx, my) in marks:
        if (mx + 1, my + 1) not in mset and opaque(im, mx + 1, my + 1) and im.getpixel((mx + 1, my + 1))[:3] != OUT[:3]:
            put(im, mx + 1, my + 1, BADGE_SHADOW)
    for (mx, my) in marks:
        put(im, mx, my, (250, 250, 250))
    put(im, 4, 5, (255, 255, 255))
    return im


# --- the fire round the viewers panel ---

FIRE_W, FIRE_H, FIRE_FRAMES = 136, 64, 12
PANEL_X, PANEL_Y, PANEL_W, PANEL_H = 8, 24, 120, 36
REACH_TOP, REACH_SIDE, REACH_BOTTOM = 30, 7, 3
TONGUE_GAP = 9


def _hash(a, b, c=0):
    n = (a * 374761393 + b * 668265263 + c * 2147483647) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


def tongue_height(x, t, frames=FIRE_FRAMES):
    """How far up the flames reach over column x in frame t, 0.3 to 1: tongues every TONGUE_GAP pixels, each with
    its own phase, swelling and dropping a whole number of times over the loop (so it loops), with a low
    trough between two tongues."""
    ph = 2 * math.pi * t / frames
    best = 0.3
    for k in range(-1, FIRE_W // TONGUE_GAP + 2):
        cx = k * TONGUE_GAP + 4 + int(_hash(k, 7) * 3)
        half = 3.5 + _hash(k, 11) * 2.0
        d = abs(x - cx) / half
        if d >= 1:
            continue
        swell = 0.62 + 0.38 * math.sin((1 + (k % 2)) * ph + _hash(k, 3) * 6.283)
        best = max(best, (1 - d * d) * swell)
    return best


def fire_heat(x, y, t, frames=FIRE_FRAMES):
    """Heat at a pixel in frame t (the kept version 1, 7/10): 1 at the panel's edge, falling with the distance
    out (far reach upwards over the tongues, short at the sides and below), plus flame noise that rises a whole
    number of periods over the loop, so the last frame runs into the first."""
    inside_x = PANEL_X <= x < PANEL_X + PANEL_W
    dx = 0 if inside_x else (PANEL_X - x if x < PANEL_X else x - (PANEL_X + PANEL_W - 1))
    above, below = PANEL_Y - y, y - (PANEL_Y + PANEL_H - 1)
    if dx == 0 and above <= -2 and below <= 0:
        return 0.0                                     # the panel itself stays clear (2 rows lick its top)
    ph = 2 * math.pi * t / frames
    reach = REACH_TOP * tongue_height(x, t, frames)
    e_top = max(above, 0) / reach
    e_side = dx / REACH_SIDE
    e_bot = max(below, 0) / REACH_BOTTOM
    if dx > 0 and y < PANEL_Y:                         # above a corner: flames climb, a bit shorter
        e = max(e_side, max(above, 0) / (reach * 0.7))
    else:
        e = max(e_top, e_side, e_bot)
    bx, by = x // 2, y // 2
    n = (0.5 * math.sin(0.9 * bx + 1.3 * by + 2 * ph)
         + 0.3 * math.sin(0.37 * bx - 0.8 * by + 1 * ph + 1.7)
         + 0.2 * math.sin(1.7 * bx + 0.6 * by + 3 * ph + 0.4))
    tongues = 0.5 + 0.5 * math.sin(2 * math.pi * x / 13.0 + 0.6 * math.sin(ph)) * math.cos(ph + x * 0.21)
    flick = _hash(bx, by, t % frames) - 0.5
    return 1.0 - e + 0.34 * n + 0.22 * (tongues - 0.5) * (1 if above > 0 else 0.3) + 0.12 * flick


def fire_frame(t, frames=FIRE_FRAMES):
    """One frame of the kept fire (version 1)."""
    im = new(FIRE_W, FIRE_H)
    flame = set()
    heat = {}
    for y in range(FIRE_H):
        for x in range(FIRE_W):
            h = fire_heat(x, y, t, frames)
            if h > 0.42:
                flame.add((x, y))
                heat[(x, y)] = h
    for (x, y) in flame:
        h = heat[(x, y)]
        c = FIRE[0] if h > 0.98 else FIRE[1] if h > 0.82 else FIRE[2] if h > 0.64 else FIRE[3]
        edge = any((x + dx, y + dy) not in flame for dx, dy in ((1, 0), (-1, 0), (0, -1)))
        inside_panel = PANEL_X <= x < PANEL_X + PANEL_W and PANEL_Y <= y
        if edge and not inside_panel and h < 0.7:
            c = FIRE_EDGE
        put(im, x, y, c)
    for k in range(7):                                 # sparks: rise 1 px a frame on a 12 px path, so they loop
        sx = 10 + int(_hash(k, 99) * (FIRE_W - 20))
        sy = PANEL_Y - 8 - ((t + k * 5) % frames)
        if (sx, sy) not in flame and sy >= 0:
            put(im, sx, sy, FIRE[1] if k % 2 else FIRE[0])
    return im


# The style loop's later fire versions (refines 2 to 4, scored 6, 7 and 6; the loop kept version 1). Kept for the
# record, so the drawing of version 4 can be read and redrawn: fire_frame_v4(t).



def _hash_unused(a, b, c=0):
    n = (a * 374761393 + b * 668265263 + c * 2147483647) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


def lick(s, a, t, frames, gap, hw, hmin, hmax, seed, sway):
    """Heat of one edge's flames at coordinate s along the edge, a px out from the panel, in frame t: tongues every
    `gap` px that taper to a tip, move, and curl (the tip leans); each swells and drops a whole number of times over
    the loop (so it loops), and the tall ones shed a detached tip. 0 outside every tongue, else 0.1 to 1."""
    ph = 2 * math.pi * t / frames
    best = 0.0
    for k in range(-1, int(FIRE_W / gap) + 3):
        r = _hash(k, seed)
        c = k * gap + gap / 2 + 3 * (r - 0.5)
        tall = k % 2 == 0
        lo, hi = (hmin, max(hmin + 1, hmax - 0.2 * hmax * r)) if tall else (hmin * 0.5, hmax * 0.5)      # tall ones vary in height
        H = lo + (hi - lo) * (0.5 + 0.5 * math.sin((1 + (k % 3 == 0 and not tall)) * ph + r * 6.283))
        u = a / H
        if u >= 1 or (tall and H > 14 and 0.8 <= u < 0.87):    # past the tip, or the gap before a detached tip
            continue
        cu = c + 2 * math.sin(ph + r * 6.283) + sway * math.sin(2 * ph + k) * u * u * hw * 0.5
        d = abs(s - cu) / (hw * (1 - u) ** 0.6 + 0.4)
        if d < 1:
            best = max(best, 1.0 - 0.55 * u ** 1.3 - 0.34 * d ** 1.5)
    return best


def fire_heat_v4(x, y, t, frames=FIRE_FRAMES):
    """Heat at a pixel in frame t, 0 where there is no flame: tall curling tongues above (some with a detached
    tip), short flames on the sides, a very low rim below. The last frame runs into the first."""
    above, below = PANEL_Y - y, y - (PANEL_Y + PANEL_H - 1)
    dx = 0 if PANEL_X <= x < PANEL_X + PANEL_W else (PANEL_X - x if x < PANEL_X else x - (PANEL_X + PANEL_W - 1))
    h = 0.0
    if above >= 0:
        h = max(lick(x, above, t, frames, 16, 8, 13, 23, 7, 1.0), 0.95 - 0.12 * above if above < 3 else 0.0)
    elif dx > 0 and below <= 0:
        h = lick(y - PANEL_Y + (40 if x > PANEL_X else 0), dx, t, frames, 12, 5, 6, 12, 23 + (x > PANEL_X), 0.6)
        h = max(h, 0.9 - 0.15 * dx if dx < 3 else 0.0)
    elif 0 < below <= 3:
        h = lick(x, below - 1, t, frames, 10, 3.5, 1, 3, 31, 0.0)
        h = max(h, 0.8 if below == 1 else 0.0)
    return h


def _clear(x, y):
    """The panel's clear zone: nothing is drawn here (the 2 top rows lick over it)."""
    corner = x in (0, FIRE_W - 1) and y in (0, FIRE_H - 1)     # the frame's corners stay transparent
    return corner or (PANEL_X <= x < PANEL_X + PANEL_W and PANEL_Y + 2 <= y < PANEL_Y + PANEL_H)


def fire_frame_v4(t, frames=FIRE_FRAMES):
    im = new(FIRE_W, FIRE_H)
    flame = set()
    heat = {}
    for y in range(FIRE_H):
        for x in range(FIRE_W):
            h = fire_heat_v4(x, y, t, frames)
            if h > 0 and not _clear(x, y):
                flame.add((x, y))
                heat[(x, y)] = h
    # glow: a solid dark edge ring round the flame, then a checkerboard halo one step further out
    ring, halo = set(), set()
    n4 = ((1, 0), (-1, 0), (0, -1), (0, 1))
    for (x, y) in flame:
        for dx, dy in n4:
            q = (x + dx, y + dy)
            if q not in flame and not _clear(*q):
                ring.add(q)
    for (x, y) in ring:
        for dx, dy in n4:
            q = (x + dx, y + dy)
            if q not in flame and q not in ring and not _clear(*q) and (q[0] + q[1]) % 2 == 0:
                halo.add(q)
    halo2 = set()                                      # a second, sparser halo step (1 px in 4) further out
    for (x, y) in halo | ring:
        for dx, dy in n4:
            q = (x + dx, y + dy)
            if q not in flame and q not in ring and q not in halo and not _clear(*q) and q[0] % 2 == 0 and q[1] % 2 == 0:
                halo2.add(q)
    for (x, y) in halo2:
        put(im, x, y, FIRE_EDGE)
    for (x, y) in halo:
        put(im, x, y, FIRE[3])
    for (x, y) in ring:
        put(im, x, y, FIRE_EDGE)
    for (x, y) in flame:
        h = heat[(x, y)]
        put(im, x, y, FIRE[0] if h > 0.8 else FIRE[1] if h > 0.64 else FIRE[2] if h > 0.46 else FIRE[3])
    for k in range(7):                                 # sparks: rise 1 px a frame on a 12 px path, drift sideways (loops)
        sx = 8 + int(_hash(k, 99) * (FIRE_W - 20)) + int(round(2 * math.sin(2 * math.pi * (t + k * 2) / frames)))
        sy = 3 + (k * 5) % 6 + 8 - ((t + k * 5) % frames)
        c = FIRE[1] if k % 2 else FIRE[0]
        cells = [(sx, sy), (sx + 1, sy), (sx, sy + 1), (sx + 1, sy + 1)] if k % 2 == 0 else [(sx, sy), (sx + 1, sy)]
        for q in cells:
            if q not in flame and q not in ring and q not in halo and q not in halo2 and 0 <= q[1] < FIRE_H:
                put(im, q[0], q[1], c)
    return im


def fire_sheet(frames=FIRE_FRAMES):
    sheet = new(FIRE_W * frames, FIRE_H)
    for t in range(frames):
        sheet.paste(fire_frame(t, frames), (t * FIRE_W, 0))
    return sheet


# --- icons ---

def heart_inside(x, y, w, h):
    """The classic heart curve, (u^2 + v^2 - 1)^3 - u^2 v^3 <= 0, fitted to the w x h box (pixel centres)."""
    u = ((x + 0.5) / w - 0.5) * 2.6
    v = -(((y + 0.5) / h) * 2.45 - 1.32)
    return (u * u + v * v - 1) ** 3 - u * u * v ** 3 <= 0


def heart(w=18, h=16):
    """The full heart: the board's heart red, a darker red on its lower right, a light red rim and a white glint
    on the upper left lobe, in the HUD's dark outline (a thick, comic outline: 1 art pixel is 2 screen pixels)."""
    iw, ih = w - 2, h - 2
    fill = {(x + 1, y + 1) for y in range(ih) for x in range(iw) if heart_inside(x, y, iw, ih)}
    im = new(w, h)
    shade = tuple(int(c * 0.66) for c in HEART_RED)
    light = (255, 112, 116)
    for (x, y) in fill:
        c = HEART_RED
        if (x + 1, y + 1) not in fill or (x + 1, y) not in fill:
            c = shade
        elif x - y > iw * 0.55:
            c = shade
        if (x - 1, y) not in fill or (x, y - 1) not in fill:
            if x < w * 0.55 and y < h * 0.55:
                c = light
        put(im, x, y, c)
    for (x, y) in ((4, 3), (5, 3), (3, 4), (3, 5)):
        if (x, y) in fill:
            put(im, x, y, (255, 238, 238))
    for y in range(h):
        for x in range(w):
            if (x, y) not in fill and any((x + dx, y + dy) in fill for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                put(im, x, y, OUT)
    return im


def heart_empty(full):
    """The empty heart from a full one: the same outline and the same shading steps, with the fill mapped by
    brightness onto a dark slate ramp, so the pair always matches."""
    im = full.copy().convert("RGBA")
    px = [im.getpixel((x, y)) for y in range(im.height) for x in range(im.width)]
    fills = sorted({p[:3] for p in px if p[3] == 255 and sum(abs(a - b) for a, b in zip(p[:3], OUT[:3])) > 40},
                   key=lambda c: 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2])
    lo, hi = (26, 29, 38), (104, 112, 130)
    ramp = {}
    for i, c in enumerate(fills):
        f = i / max(1, len(fills) - 1)
        ramp[c] = tuple(int(lo[k] + (hi[k] - lo[k]) * f ** 1.6) for k in range(3))
    for y in range(im.height):
        for x in range(im.width):
            p = im.getpixel((x, y))
            if p[3] == 255 and p[:3] in ramp:
                im.putpixel((x, y), ramp[p[:3]] + (255,))
    return im


def eye(w=16, h=11):
    """The viewers' eye: an almond eye in the viewers cyan, light on top and darker below, a dark iris ring, a
    black pupil and a white catchlight, in the HUD's dark outline."""
    im = new(w, h)
    cx, cy = (w - 1) / 2, (h - 1) / 2
    a, b = w / 2 - 1.0, h / 2 - 1.0
    inside = set()
    for y in range(h):
        for x in range(w):
            dx, dy = (x - cx) / a, (y - cy) / b
            if abs(dy) <= (1 - dx * dx) * 1.05 and abs(dx) < 1:
                inside.add((x, y))
    dark = tuple(int(c * 0.55) for c in VIEWERS)
    light = (196, 250, 255)
    for (x, y) in inside:
        r = math.hypot(x - cx, (y - cy) * 1.0)
        if r <= 1.3:
            c = OUT[:3]
        elif r <= 2.4:
            c = (14, 70, 96)
        elif r <= 3.3:
            c = dark
        else:
            c = light if y < cy - 1 else (VIEWERS if y <= cy + 1 else dark)
        put(im, x, y, c)
    put(im, int(cx) - 1, int(cy) - 1, (255, 255, 255))
    for y in range(h):
        for x in range(w):
            if (x, y) not in inside and any((x + dx, y + dy) in inside for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                put(im, x, y, OUT)
    return im


def subs_icon(size=22):
    """The subs icon at 22 x 22 (the brief's largest size): a subscriber, a head and shoulders in four greys (white
    highlight, light, mid, shade, dark underside) with a neck, and a round hot pink badge with a 7 px white plus at the
    lower right, inside a closed dark ring, all in the HUD's 1 px dark outline."""
    im = new(size, size)
    HI, LIT, MID, SH, DK = (255, 255, 255), (232, 237, 247), (182, 190, 208), (136, 145, 168), (96, 104, 128)
    hx, hy, hr = 8.5, 6.5, 4.3
    bx, by, br = 16, 16, 4.6
    body = set()
    for y in range(size):
        for x in range(size):
            if math.hypot(x - hx, y - hy) <= hr:
                body.add((x, y))
            u, v = (x - 8.5) / 7.8, (y - 19.0) / 7.2
            if 12 <= y <= 19 and u * u + v * v <= 1:
                body.add((x, y))
    for x in range(6, 12):                              # neck
        body.add((x, 11))
    badge = {(x, y) for y in range(size) for x in range(size) if math.hypot(x - bx, y - by) <= br}
    for (x, y) in body:
        if y <= 10:
            d = (x - hx) + (y - hy)
            c = HI if (x, y) in ((6, 3), (7, 3), (5, 4)) else LIT if d < 0 else MID if d < 3 else SH
            if (x + 1, y) not in body or (x, y + 1) not in body:
                c = SH if d > -1 else MID
        elif y == 11:
            c = SH
        else:
            c = HI if (x, y) in ((3, 14), (4, 13)) else LIT if x < 7 else MID if x < 11 else SH
            if (x + 1, y) not in body:
                c = SH
            if (x, y + 1) not in body:
                c = DK if x >= 7 else SH
        put(im, x, y, c)
    for (x, y) in badge:                                # a closed dark ring keeps the badge apart from the person
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
            q = (x + dx, y + dy)
            if q not in badge and q in body:
                put(im, q[0], q[1], OUT)
    for (x, y) in badge:
        c = PINK if y <= by else (196, 40, 120)
        if y < by - 2:
            c = (255, 140, 196)
        if y >= by + 3:
            c = (150, 24, 96)
        put(im, x, y, c)
    for d in range(-3, 4):
        put(im, bx + d, by, (255, 255, 255))
        put(im, bx, by + d, (255, 255, 255))
    shape = {(x, y) for y in range(size) for x in range(size) if opaque(im, x, y)}
    for y in range(size):
        for x in range(size):
            if (x, y) not in shape and any((x + dx, y + dy) in shape for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                put(im, x, y, OUT)
    return im


def subs_icon_v2(size=18):
    """Proposal for the subs icon: a subscriber, a person's head and shoulders in pale grey with shading, with a
    round hot pink badge with a white plus at the lower right (a new subscriber), in the HUD's dark outline."""
    im = new(size, size)
    body = set()
    hx, hy, hr = 7.0, 5.0, 3.4
    for y in range(size):
        for x in range(size):
            if math.hypot(x - hx, y - hy) <= hr:
                body.add((x, y))
            u, v = (x - 7.0) / 6.2, (y - 16.0) / 6.0
            if y <= 16 and u * u + v * v <= 1 and y >= 10:
                body.add((x, y))
    bcx, bcy, br = 13.0, 13.0, 3.6
    badge = {(x, y) for y in range(size) for x in range(size) if math.hypot(x - bcx, y - bcy) <= br}
    for y in (9,):                                     # neck, so the head and shoulders read as a person
        for x in (5, 6, 7, 8, 9):
            body.add((x, y))
    HI, LIT, MID, SH, DK = (255, 255, 255), (232, 237, 247), (182, 190, 208), (136, 145, 168), (96, 104, 128)
    for (x, y) in body:
        if y < 8:                                      # head: highlight top-left, light, mid, shade lower right
            d = (x - hx) + (y - hy)
            c = HI if (x, y) in ((5, 3), (6, 2)) else LIT if d < 0.5 else MID if d < 2.5 else SH
        elif y < 10:                                   # neck sits in the head's shadow
            c = SH if x >= 7 else MID
        else:                                          # shoulders: lit left, mid centre, shaded right, dark underside
            c = HI if (x, y) == (3, 11) else LIT if x < 6 else MID if x < 9 else SH
            if (x + 1, y) not in body:
                c = SH
            if (x, y + 1) not in body and y >= 14:
                c = DK if x >= 6 else SH
        put(im, x, y, c)
    for (x, y) in badge:                               # a dark gap ring keeps the badge apart from the person
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in badge and (x + dx, y + dy) in body:
                put(im, x + dx, y + dy, OUT)
    for (x, y) in badge:
        c = PINK if y <= bcy else (196, 40, 120)
        if y < bcy - 2:
            c = (255, 140, 196)
        put(im, x, y, c)
    for d in (-2, -1, 0, 1, 2):
        put(im, int(bcx) + d, int(bcy), (255, 255, 255))
        put(im, int(bcx), int(bcy) + d, (255, 255, 255))
    shape = {(x, y) for y in range(size) for x in range(size) if opaque(im, x, y)}
    for y in range(size):
        for x in range(size):
            if (x, y) not in shape and any((x + dx, y + dy) in shape for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                put(im, x, y, OUT)
    return im


# --- PixelLab raws ---

def post(raw, size, max_colors=30, outline=False, threshold=128):
    """A PixelLab raw made game-ready without new pixels: alpha to 0 or 255, an opaque flat background removed
    (flood fill from the border by the corner colour), cropped to the subject and centred on the w x h canvas
    (never scaled), optionally a 1 pixel HUD outline round it, and at most `max_colors` of its own colours."""
    im = raw.convert("RGBA")
    w0, h0 = im.size
    px = im.load()
    for y in range(h0):
        for x in range(w0):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= threshold else CLEAR
    corner = px[0, 0]
    if corner[3] == 255:
        stack = [(x, y) for x in range(w0) for y in (0, h0 - 1)] + [(x, y) for y in range(h0) for x in (0, w0 - 1)]
        seen = set()
        while stack:
            x, y = stack.pop()
            if (x, y) in seen or not (0 <= x < w0 and 0 <= y < h0):
                continue
            seen.add((x, y))
            p = px[x, y]
            if p[3] == 255 and sum(abs(p[k] - corner[k]) for k in range(3)) <= 24:
                px[x, y] = CLEAR
                stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    box = im.getbbox()
    if box is None:
        raise ValueError("the raw has no opaque pixels")
    im = im.crop(box)
    pad = 1 if outline else 0
    w, h = size
    if im.width + 2 * pad > w or im.height + 2 * pad > h:
        raise ValueError(f"the subject is {im.width}x{im.height} (+{2 * pad} outline), bigger than {w}x{h}; "
                         "it is never scaled: generate it smaller")
    out = new(w, h)
    out.paste(im, ((w - im.width) // 2, (h - im.height) // 2))
    if outline:
        shape = {(x, y) for y in range(h) for x in range(w) if opaque(out, x, y)}
        for y in range(h):
            for x in range(w):
                if (x, y) not in shape and any((x + dx, y + dy) in shape for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    put(out, x, y, OUT)
    return reduce_palette.reduce_image(out, max_colors)


def request(description, size, init=None, init_strength=150, shading="medium shading", detail="highly detailed"):
    """A /create-image-pixflux request body (T-339's settings: black outline, no background), optionally from an
    init image (a PNG's bytes) at the given strength."""
    w, h = size
    body = {"description": description, "image_size": {"width": w, "height": h}, "no_background": True,
            "outline": "single color black outline", "shading": shading, "detail": detail,
            "text_guidance_scale": 8}
    if init is not None:
        body["init_image"] = {"type": "base64", "base64": base64.b64encode(init).decode()}
        body["init_image_strength"] = init_strength
    return body


def split(sheet, frames, names, out_dir):
    fw = sheet.width // frames
    paths = []
    for i, name in enumerate(names):
        p = Path(out_dir) / f"{name}.png"
        sheet.crop((i * fw, 0, (i + 1) * fw, sheet.height)).save(p)
        paths.append(p)
    return paths


def contact(paths, scale=4, pad=8):
    """Every image enlarged (nearest), in a row on a dark and, below it, a light background."""
    ims = [Image.open(p).convert("RGBA") for p in paths]
    rows, row, roww, maxw = [], [], 0, 1100
    for im in ims:
        w = im.width * scale + pad
        if row and roww + w > maxw:
            rows.append(row)
            row, roww = [], 0
        row.append(im)
        roww += w
    if row:
        rows.append(row)
    width = max(sum(i.width * scale + pad for i in r) for r in rows) + pad
    height = sum(max(i.height * scale for i in r) + pad for r in rows) + pad
    sheet = Image.new("RGBA", (width, height * 2), (0, 0, 0, 255))
    for half, bg in enumerate(((22, 26, 36, 255), (226, 228, 232, 255))):
        sheet.paste(Image.new("RGBA", (width, height), bg), (0, half * height))
        y = half * height + pad
        for r in rows:
            x = pad
            for im in r:
                big = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
                sheet.alpha_composite(big, (x, y))
                x += big.width + pad
            y += max(i.height * scale for i in r) + pad
    return sheet


BUILDERS = {
    "clock-panel": lambda a: panel(100, 36),
    "viewers-panel": lambda a: panel(120, 36, rim=VIEWERS),
    "subgoal-frame": lambda a: subgoal_frame(64),
    "digits": lambda a: digits_sheet(),
    "live-badge": lambda a: live_badge(),
    "fire": lambda a: fire_sheet(),
    "heart": lambda a: heart(),
    "heart-empty": lambda a: heart_empty(Image.open(a.from_png)),
    "eye": lambda a: eye(),
    "subs": lambda a: subs_icon(),
}


def save(im, out, force=False):
    out = Path(out)
    if out.exists() and not force:
        raise SystemExit(f"{out} exists; never overwritten (use a new name, or --force for a scratch file)")
    out.parent.mkdir(parents=True, exist_ok=True)
    im.save(out)
    print(out)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in BUILDERS:
        p = sub.add_parser(name)
        p.add_argument("--out", required=True)
        p.add_argument("--force", action="store_true")
        if name == "heart-empty":
            p.add_argument("--from", dest="from_png", required=True)
    p = sub.add_parser("post")
    p.add_argument("raw")
    p.add_argument("--out", required=True)
    p.add_argument("--size", required=True)
    p.add_argument("--max-colors", type=int, default=30)
    p.add_argument("--outline", action="store_true")
    p.add_argument("--threshold", type=int, default=128)
    p.add_argument("--force", action="store_true")
    p = sub.add_parser("request")
    p.add_argument("--description", required=True)
    p.add_argument("--size", required=True)
    p.add_argument("--init", help="a PNG of the canvas size to start from")
    p.add_argument("--init-strength", type=int, default=150)
    p.add_argument("--shading", default="medium shading")
    p.add_argument("--detail", default="highly detailed")
    p.add_argument("--out", required=True)
    p = sub.add_parser("split")
    p.add_argument("sheet")
    p.add_argument("--frames", type=int, required=True)
    p.add_argument("--names", required=True)
    p.add_argument("--out-dir", required=True)
    p = sub.add_parser("contact")
    p.add_argument("files", nargs="+")
    p.add_argument("--out", required=True)
    p.add_argument("--scale", type=int, default=4)
    a = ap.parse_args(argv)
    if a.cmd in BUILDERS:
        save(BUILDERS[a.cmd](a), a.out, a.force)
    elif a.cmd == "post":
        w, h = (int(v) for v in a.size.lower().split("x"))
        save(post(Image.open(a.raw), (w, h), a.max_colors, a.outline, a.threshold), a.out, a.force)
    elif a.cmd == "request":
        w, h = (int(v) for v in a.size.lower().split("x"))
        init = Path(a.init).read_bytes() if a.init else None
        if init is not None and Image.open(a.init).size != (w, h):
            raise SystemExit("--init must be exactly the canvas size")
        body = request(a.description, (w, h), init, a.init_strength, a.shading, a.detail)
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Path(a.out).write_text(json.dumps(body), encoding="utf-8")
        print(a.out)
    elif a.cmd == "split":
        names = a.names.split(",")
        if len(names) != a.frames:
            raise SystemExit("--names must name every frame")
        for p in split(Image.open(a.sheet).convert("RGBA"), a.frames, names, a.out_dir):
            print(p)
    elif a.cmd == "contact":
        contact(a.files, a.scale).save(a.out)
        print(a.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
