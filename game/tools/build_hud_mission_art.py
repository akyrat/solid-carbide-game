#!/usr/bin/env python3
"""The mission notebook page's art (task T-464; Game loop architecture, Decisions, "Mission packs").

Script-drawn HUD art shown at 2x (one art pixel is two screen pixels), with hard pixel edges, only opaque or
empty pixels, a transparent background, the HUD's dark outline and none of Greenbull's light green or yellow
(Visual style, Content, "Rules", rule 6). One function per piece; every drawing is deterministic.

Commands (run from the repo root; each writes one PNG to --out and never overwrites an existing file):
  python game/tools/build_hud_mission_art.py page --out X.png     # 88 x 90 ripped-out spiral-notebook page
  python game/tools/build_hud_mission_art.py checkbox --out X.png # 7 x 7 empty ink checkbox
  python game/tools/build_hud_mission_art.py tick --out X.png     # 7 x 7 ink check mark
  python game/tools/build_hud_mission_art.py cross --out X.png    # 24 x 4 strike-through (x 8..15 repeats)
  python game/tools/build_hud_mission_art.py card --out X.png     # 170 x 170 power-up card frame (9-slice, 12 px)
  python game/tools/build_hud_mission_art.py post RAW.png --out X.png --size WxH [--max-colors N]
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

OUT = (8, 8, 15, 255)            # Hud.OUTLINE_COLOR, the HUD's dark outline
CLEAR = (0, 0, 0, 0)
PAPER = (245, 240, 217)          # HudStyle.MISSION_PAPER
PAPER_SHADE = (228, 220, 192)    # the darker shade along the bottom and right edge
RULE = (158, 189, 224)           # pale blue ruled line (HudStyle.MISSION_RULE)
RULE_SHADE = (144, 172, 206)     # the ruled line where it crosses the shade
MARGIN = (217, 77, 77)           # red margin line (HudStyle.MISSION_MARGIN)
MARGIN_SHADE = (196, 66, 66)
TAPE = (198, 208, 206)           # a strip of grey-blue tape
TAPE_LIGHT = (220, 228, 226)
TAPE_DARK = (168, 178, 178)

PAGE_W, PAGE_H = 88, 90
TOP, RIGHT, BOTTOM = 1, 87, 89   # the outline's top row, right column and bottom row
MARGIN_X = 8                     # the red margin line's column
RULE_FIRST, RULE_STEP = 24, 10   # the first ruled line's row, then every 10 px
HEADER_BOTTOM = 14               # rows 0..14 are the header band the game writes "MISSION" over
WRITE_X = (12, 82)               # the writing area right of the margin, kept clear
HOLE_X = 4                       # the punched binding holes: 2 x 2, at columns 4..5
HOLE_ROWS = [8 + 10 * i for i in range(8)]   # each hole's top row (8, 18, ... 78), between the ruled lines
TAPE_BOX = (68, 0, 83, 6)        # x0, y0, x1, y1 of the tape strip at the top right, right of the header text
SHADE_W = 2                      # how many paper pixels in from the right and bottom edge are shaded


def rgba(c):
    return tuple(c) + (255,) if len(c) == 3 else tuple(c)


def new(w, h):
    return Image.new("RGBA", (w, h), CLEAR)


def torn_left(y):
    """The left edge's column on row y: an irregular 1 pixel zig-zag where the page was ripped out."""
    return (0, 1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 1)[y % 12]


def page_shape():
    """The set of the page's pixels (outline included): a torn left edge, stepped radius 2 corners on the
    other side, and the punched binding holes cut out."""
    shape = set()
    for y in range(TOP, BOTTOM + 1):
        step = 2 if y in (TOP, BOTTOM) else 1 if y in (TOP + 1, BOTTOM - 1) else 0
        left = torn_left(y) + step
        for x in range(left, RIGHT - step + 1):
            shape.add((x, y))
    for hy in HOLE_ROWS:
        for dy in (0, 1):
            for dx in (0, 1):
                shape.discard((HOLE_X + dx, hy + dy))
    return shape


def outline_of(shape):
    """The shape's pixels that touch the outside (4-neighbours): its 1 pixel outline, holes included."""
    return {(x, y) for (x, y) in shape
            if any((x + dx, y + dy) not in shape for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}


def shaded(x, y, shape, edge):
    """True for paper within SHADE_W pixels of the right or bottom outline."""
    return any((x + d, y) in edge or (x + d, y) not in shape for d in range(1, SHADE_W + 1)) \
        or any((x, y + d) in edge or (x, y + d) not in shape for d in range(1, SHADE_W + 1))


def draw_paper(im, shape, edge):
    for (x, y) in shape - edge:
        im.putpixel((x, y), rgba(PAPER_SHADE if shaded(x, y, shape, edge) and x > HOLE_X + 3 else PAPER))


def draw_rules(im, shape, edge):
    for y in range(RULE_FIRST, BOTTOM - 2, RULE_STEP):
        for x in range(MARGIN_X + 1, RIGHT):
            if (x, y) in shape and (x, y) not in edge:
                im.putpixel((x, y), rgba(RULE_SHADE if shaded(x, y, shape, edge) else RULE))


def draw_margin(im, shape, edge):
    for y in range(TOP, BOTTOM + 1):
        if (MARGIN_X, y) in shape and (MARGIN_X, y) not in edge:
            im.putpixel((MARGIN_X, y), rgba(MARGIN_SHADE if shaded(MARGIN_X, y, shape, edge) else MARGIN))


def draw_outline(im, edge):
    for p in edge:
        im.putpixel(p, OUT)


def tape_shape():
    """The tape strip's pixels: a slightly tilted band with torn (stepped) short ends."""
    x0, y0, x1, y1 = TAPE_BOX
    shape = set()
    half = (x0 + x1 + 1) // 2
    for x in range(x0, x1 + 1):
        top, bottom = (y0 + 1, y1) if x < half else (y0, y1 - 1)   # the strip steps up one pixel halfway
        if x in (x0, x1):
            top, bottom = top + 1, bottom - 1                       # torn ends
        for y in range(top, bottom + 1):
            shape.add((x, y))
    return shape


def draw_tape(im):
    shape = tape_shape()
    edge = outline_of(shape)
    for (x, y) in shape:
        if (x, y) in edge:
            c = OUT
        elif (x, y - 1) in edge:
            c = TAPE_LIGHT
        elif (x, y + 1) in edge:
            c = TAPE_DARK
        else:
            c = TAPE
        im.putpixel((x, y), rgba(c))


def page():
    """The 88 x 90 mission page: cream paper, ruled lines, red margin, torn and punched left edge, tape."""
    im = new(PAGE_W, PAGE_H)
    shape = page_shape()
    edge = outline_of(shape)
    draw_paper(im, shape, edge)
    draw_rules(im, shape, edge)
    draw_margin(im, shape, edge)
    draw_outline(im, edge)
    draw_tape(im)
    return im


INK = (31, 33, 51)               # HudStyle.MISSION_INK, the pen ink of the marks
PAPER_LIGHT = (252, 249, 236)    # the checkbox's one lighter inner pixel
CHECKBOX_GAP_Y = 4               # the row of the one pen-lift gap in the checkbox's right stroke
CROSS_W, CROSS_H = 24, 4
CROSS_REPEAT = (8, 15)           # the cross-off mark's plain middle stretch the game repeats


def checkbox():
    """The 7 x 7 empty checkbox: a 1 px ink square drawn by hand, all four corner pixels clear (a lightly
    rounded box), one pen-lift gap in the right stroke, paper inside, one lighter pixel."""
    im = new(7, 7)
    for i in range(1, 6):
        im.putpixel((i, 0), rgba(INK))          # top stroke
        im.putpixel((i, 6), rgba(INK))          # bottom stroke
        im.putpixel((0, i), rgba(INK))          # left stroke
        if i != CHECKBOX_GAP_Y:
            im.putpixel((6, i), rgba(INK))      # right stroke, with the pen lifting once
    for y in range(1, 6):
        for x in range(1, 6):
            im.putpixel((x, y), rgba(PAPER))
    im.putpixel((2, 2), rgba(PAPER_LIGHT))
    return im


TICK_PIXELS = [(0, 3), (0, 4), (1, 4), (1, 5), (2, 5), (2, 6),   # the short down stroke, 2 px thick
               (3, 4), (3, 5), (3, 6), (4, 3), (4, 4), (4, 5),   # the long up stroke, 2 px thick
               (4, 2), (5, 2), (5, 3),                           # a slight wobble where the pen steadies
               (5, 1), (6, 1), (5, 0)]                           # the quick flick up to the box's top right
# All four corner pixels stay clear (Visual style, Content, "Rules", rule 1).


def tick():
    """The 7 x 7 ink check mark that overlays the checkbox; transparent elsewhere."""
    im = new(7, 7)
    for p in TICK_PIXELS:
        im.putpixel(p, rgba(INK))
    return im


def cross_rows(x):
    """The rows the cross-off stroke covers in column x: a 1 px rounded cap at each end, a slight dip at the
    start and a lift before the end, and a plain rows 1..2 stretch in the middle that tiles."""
    if x == 0:
        return (2,)
    if x in (1, 2):
        return (2, 3)
    if x in (20, 21, 22):
        return (0, 1)
    if x == CROSS_W - 1:
        return (1,)
    return (1, 2)


def cross():
    """The 24 x 4 pen strike-through, 2 px thick; the game repeats columns CROSS_REPEAT along the text."""
    im = new(CROSS_W, CROSS_H)
    for x in range(CROSS_W):
        for y in cross_rows(x):
            im.putpixel((x, y), rgba(INK))
    return im


# The power-up overlay's card frame (T-464): a bolted workshop steel plate with an amber frame. Kept apart
# from the Greenbull gift screen: no green, ribbon, sunburst or emblem, and the amber stays a deep
# orange-amber well away from Greenbull's yellow (rule 6).
CARD_W = CARD_H = 170
CARD_MARGIN = 12                  # the StyleBoxTexture's 9-slice margin; everything inside is flat steel
AMBER = (255, 172, 28)
AMBER_LIGHT = (255, 200, 104)     # highlight along the top and left
AMBER_SHADE = (196, 118, 20)      # shade along the bottom and right
STEEL = (46, 52, 64)              # the flat middle the game writes on
STEEL_LIGHT = (70, 78, 94)        # inner bevel, top and left
STEEL_SHADE = (30, 34, 44)        # inner bevel, bottom and right
HAZARD_DARK = (24, 24, 32)        # the hazard stripes' near-black
BOLT = (150, 156, 168)
BOLT_LIGHT = (196, 202, 212)
BOLT_SHADE = (96, 102, 116)
FRAME_IN = 9                      # the inner near-black outline's ring (amber is rings 1..8)
HAZARD_SPANS = [(14, 41), (128, 155)]   # x ranges of the hazard stripes on the top band, near each corner


def _ring(x, y, w, h):
    """How many pixels in from the nearest edge (x, y) lies, or -1 outside the stepped (radius 2) corner."""
    dx, dy = min(x, w - 1 - x), min(y, h - 1 - y)
    if dx + dy < 2:
        return -1
    return 0 if dx + dy == 2 else min(dx, dy)


def _bolt(im, x0, y0):
    """A 6 x 6 hex-ish bolt head with a slot, its top left at (x0, y0)."""
    px = im.load()
    rows = ["..XX..", ".XLLX.", "XLBBSX", "XBBBSX", ".XSSX.", "..XX.."]
    col = {"X": OUT, "L": rgba(BOLT_LIGHT), "B": rgba(BOLT), "S": rgba(BOLT_SHADE)}
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch != ".":
                px[x0 + i, y0 + j] = col[ch]
    px[x0 + 2, y0 + 3] = OUT          # the slot, a short diagonal
    px[x0 + 3, y0 + 2] = OUT


def card_frame():
    im = new(CARD_W, CARD_H)
    px = im.load()
    for y in range(CARD_H):
        for x in range(CARD_W):
            r = _ring(x, y, CARD_W, CARD_H)
            if r < 0:
                continue
            top_left = min(x, y) < min(CARD_W - 1 - x, CARD_H - 1 - y)
            if r == 0 or r == FRAME_IN:
                c = OUT
            elif r == 1:
                c = AMBER_LIGHT if top_left else AMBER_SHADE
            elif r < FRAME_IN:
                c = AMBER_SHADE if r == FRAME_IN - 1 and not top_left else AMBER
            elif r < CARD_MARGIN:
                c = STEEL_LIGHT if top_left else STEEL_SHADE
            else:
                c = STEEL
            px[x, y] = rgba(c)
    for x0, x1 in HAZARD_SPANS:       # diagonal stripes, 3 amber then 3 dark, on rows 2..7 of the top band
        for y in range(2, 8):
            for x in range(x0, x1 + 1):
                if (x + y) % 6 < 3:
                    px[x, y] = rgba(HAZARD_DARK)
        for y in range(2, 8):          # dark end caps so each strip reads as a plate
            px[x0 - 1, y] = OUT
            px[x1 + 1, y] = OUT
    for x0, y0 in [(2, 2), (CARD_W - 8, 2), (2, CARD_H - 8), (CARD_W - 8, CARD_H - 8)]:
        _bolt(im, x0, y0)
    return im


# Card frame v2 (style loop refine): a 2 px amber bevel, an inset lip step, bigger high-contrast slotted
# bolts and a rivet line around the frame, so the frame reads as a thick bolted plate (Visual style rule 2).
AMBER_BRIGHT = (255, 212, 136)    # the 2 px top/left bevel band
AMBER_DEEP = (166, 90, 18)        # the 2 px bottom/right bevel band, a deep orange-brown
BOLT2 = (118, 126, 140)
BOLT2_LIGHT = (226, 232, 240)
BOLT2_SHADE = (66, 72, 86)
RIVET_RING = 5                    # the rivet line runs along the middle of the amber band
RIVET_STEP = 12


def _bolt2(px, x0, y0):
    rows = [".XXXX.", "XHLBBX", "XLBBSX", "XKKKKX", "XBBSSX", ".XXXX."]
    col = {"X": OUT, "K": OUT, "H": rgba(BOLT2_LIGHT), "L": rgba(BOLT2_LIGHT),
           "B": rgba(BOLT2), "S": rgba(BOLT2_SHADE)}
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch != ".":
                px[x0 + i, y0 + j] = col[ch]
    px[x0 + 2, y0 + 1] = rgba(BOLT2)  # one highlight pixel only at the top left, the rest mid grey


def _rivet(px, x, y):
    px[x, y] = rgba(BOLT2_LIGHT)
    px[x + 1, y] = rgba(BOLT2)
    px[x, y + 1] = rgba(BOLT2)
    px[x + 1, y + 1] = OUT


def card_frame_v2():
    im = new(CARD_W, CARD_H)
    px = im.load()
    for y in range(CARD_H):
        for x in range(CARD_W):
            r = _ring(x, y, CARD_W, CARD_H)
            if r < 0:
                continue
            top_left = min(x, y) < min(CARD_W - 1 - x, CARD_H - 1 - y)
            if r == 0 or r == FRAME_IN:
                c = OUT
            elif r <= 2:
                c = AMBER_BRIGHT if top_left else AMBER_DEEP
            elif r == FRAME_IN - 1:          # the inset lip: shaded top/left, lit bottom/right
                c = AMBER_SHADE if top_left else AMBER_LIGHT
            elif r < FRAME_IN:
                c = AMBER
            elif r < CARD_MARGIN:
                c = STEEL_LIGHT if top_left else STEEL_SHADE
            else:
                c = STEEL
            px[x, y] = rgba(c)
    for x0, x1 in HAZARD_SPANS:       # stripes on rows 3..7, below the top bevel
        for y in range(3, 8):
            for x in range(x0, x1 + 1):
                px[x, y] = rgba(HAZARD_DARK if (x + y) % 6 < 3 else AMBER)
            px[x0 - 1, y] = OUT
            px[x1 + 1, y] = OUT
    lo, hi = 20, CARD_W - 22
    for t in range(lo, hi + 1, RIVET_STEP):
        if not any(a - 3 <= t <= b + 2 for a, b in HAZARD_SPANS):
            _rivet(px, t, RIVET_RING - 1)                   # top
        _rivet(px, t, CARD_H - 1 - RIVET_RING)              # bottom
        _rivet(px, RIVET_RING - 1, t)                       # left
        _rivet(px, CARD_W - 1 - RIVET_RING, t)              # right
    for x0, y0 in [(2, 2), (CARD_W - 8, 2), (2, CARD_H - 8), (CARD_W - 8, CARD_H - 8)]:
        _bolt2(px, x0, y0)
    return im


PIECES = {"page": page, "checkbox": checkbox, "tick": tick, "cross": cross, "card": card_frame,
          "card2": card_frame_v2}


def post(raw, size, max_colors=30):
    """A PixelLab raw made game-ready without scaling (the livestream HUD tool's post-process)."""
    import build_hud_livestream_art as live
    return live.post(raw, size, max_colors)


def save(im, out):
    out = Path(out)
    if out.exists():
        raise FileExistsError(f"{out} exists; this tool never overwrites a file")
    out.parent.mkdir(parents=True, exist_ok=True)
    im.convert("RGBA").save(out)
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in PIECES:
        p = sub.add_parser(name)
        p.add_argument("--out", required=True)
    p = sub.add_parser("post")
    p.add_argument("raw")
    p.add_argument("--out", required=True)
    p.add_argument("--size", required=True)
    p.add_argument("--max-colors", type=int, default=30)
    a = ap.parse_args(argv)
    if a.cmd in PIECES:
        print(save(PIECES[a.cmd](), a.out))
    elif a.cmd == "post":
        w, h = (int(v) for v in a.size.lower().split("x"))
        print(save(post(Image.open(a.raw), (w, h), a.max_colors), a.out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
