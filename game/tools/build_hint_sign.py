"""The hint pieces' roadside sign (task T-577; Level design, Decisions, "Hint pieces in the level creator").

hint_sign.png is a small standing sign, 64 x 96 px, seen in the game's 3/4 isometric view: a blank square board
on a metal post with a small base. The engine draws the hint icon on the board's face by script (fitted into
face_px, x 8..55 and y 8..55, game/data/level/hints.json) and stands the post's foot, pixel (32, 95), on the piece's
cell (game/docs/level/hint-pieces.md, "The art"). The board's look is the keycaps' (build_hint_keycap.py: face
#33384f) with a lighter steel frame; the post and base take the street lamp's cool steel (game/art/props). This
script does the free parts of the style loop around one PixelLab call per version:

    python game/tools/build_hint_sign.py init OUT.png
        Draws the script sign: the init image PixelLab starts from, and a fallback on its own.
    python game/tools/build_hint_sign.py request OUT.json --init INIT.png [--strength N] [--seed N]
        Writes the create-image-pixflux request body (64 x 96, no background, the init image in base64).
    python game/tools/build_hint_sign.py finish RAW.png OUT.png [--no-polish] [--keep-face] [--no-reduce]
        The free fixes on PixelLab's output: alpha snapped to 0 or 255, the canvas outside the sign cleared,
        pixels PixelLab lost refilled from the script, the board's face blanked again (PixelLab likes to draw
        on it; --keep-face leaves its paint), the script's outline, glint and frame roles repainted over
        PixelLab's render (--no-polish keeps its pixels), and the palette cut to at most 30 colours.
    python game/tools/build_hint_sign.py polish IN.png OUT.png --strong
        The style loop's free fixes for rule 2 (T-577 v2): longer glint runs breaking the outline on the board
        and the post, a shadow column on the right of the board, post and base, a two-step frame bevel with
        rivets, and a thicker post and base with six shading steps; PixelLab's post and base pixels stay.
        --slim (v3) is the pass that reads at native size: a slim, longer pole on a small flat base, a clearer
        lighter frame with long bright glint runs, a stepped slate face (still blank), three steps on the pole.
        --bold (v4) is the slim pass with highlights that read at thumbnail size: near-white runs two pixels
        wide breaking the outline on the frame, the pole and the base, five face bands, rivets and scuffs.
    python game/tools/build_hint_sign.py roles [--strong | --slim | --bold]
        Prints how many pixels each drawing role has, for the result notes.
    python game/tools/build_hint_sign.py preview IN.png OUT.png [--scale 6]
        An enlarged preview (nearest-neighbour) on a dark and a light background, for the board.

Nothing here calls PixelLab: the paid call is game/tools/pixellab_client.py, inside the style loop. Needs Pillow.
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from reduce_palette import preview_image, reduce_image  # noqa: E402

WIDTH, HEIGHT = 64, 96
SIZE = (WIDTH, HEIGHT)
FOOT = (32, 95)                       # anchor_px: the post's foot, bottom centre
FACE_PX = (8, 8, 55, 55)              # face_px as an inclusive box: the board, frame included

# The board: the keycaps' colours (build_hint_keycap.py) and a lighter steel frame round the face.
INK = (0x0D, 0x0D, 0x1B, 255)         # the selective outline, near black
FACE = (0x33, 0x38, 0x4F, 255)        # the blank face, RGB 51,56,79
FACE_LOW = (0x2C, 0x30, 0x45, 255)    # the frame's shadow on the face, top and left inside the frame
FRAME = (0x4E, 0x56, 0x78, 255)       # the frame, lighter than the face
FRAME_LIT = (0x6A, 0x72, 0x9C, 255)   # the frame's lit top and left
FRAME_DARK = (0x3C, 0x41, 0x5C, 255)  # the frame's bottom and right, in shade
GLINT = (0x8C, 0x94, 0xC0, 255)       # the highlight pixels that break the outline (rule 2)

# The post and base: the street lamp's cool steel (game/art/props/street_lamp_*_art.png).
STEEL = (0x44, 0x4F, 0x62, 255)
STEEL_LIT = (0x5D, 0x6A, 0x82, 255)
STEEL_DARK = (0x37, 0x45, 0x5D, 255)
STEEL_DEEP = (0x2D, 0x31, 0x57, 255)
AMBER = (0xEF, 0xAA, 0x52, 255)       # a small reflective band on the post (rule 7: small amber accents)
AMBER_DARK = (0xD0, 0x81, 0x50, 255)

# Boxes, inclusive pixel coordinates.
BOARD_OUTLINE = (7, 7, 56, 56)
FACE_INNER = (10, 10, 53, 53)         # the face inside the 2 px frame
BRACKET = (26, 57, 37, 60)            # the plate the post hangs from, under the board (outline included)
POST_X = (28, 35)                     # the post with its outline columns; steel on 29..34
POST_ROWS = (57, 89)                  # from under the board into the base plate
BAND_ROWS = (74, 77)                  # the reflective band
BASE_OUTLINE = (21, 86, 43, 95)       # the base plate's ellipse, its bottom at the foot
BASE_TOP = (23, 87, 41, 92)


def sign() -> Image.Image:
    """The script-drawn sign: board with frame and blank face, bracket, post, band, base plate."""
    im = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    px = im.load()

    # The base plate first, so the post is drawn over its top.
    d.ellipse(BASE_OUTLINE, fill=INK)
    d.ellipse((22, 87, 42, 94), fill=STEEL_DEEP)        # the plate's side
    d.ellipse(BASE_TOP, fill=STEEL_DARK)                # its top
    d.ellipse((24, 87, 38, 90), fill=STEEL)             # the lit part of the top, towards the light
    for p in ((25, 91), (39, 91)):                      # two bolts on the plate
        px[p] = STEEL_LIT

    # The post: outline columns, lit left, shade right.
    x0, x1 = POST_X
    y0, y1 = POST_ROWS
    d.rectangle((x0, y0, x1, y1), fill=INK)
    d.rectangle((x0 + 1, y0, x1 - 1, y1), fill=STEEL)
    d.rectangle((x0 + 1, y0, x0 + 1, y1), fill=STEEL_LIT)
    d.rectangle((x1 - 2, y0, x1 - 1, y1), fill=STEEL_DARK)
    d.rectangle((x1 - 1, y0, x1 - 1, y1), fill=STEEL_DEEP)
    # A joint ring and the collar at the foot.
    d.rectangle((x0 + 1, 68, x1 - 1, 68), fill=STEEL_DEEP)
    d.rectangle((x0 - 1, 84, x1 + 1, 88), fill=INK)
    d.rectangle((x0, 85, x1, 88), fill=STEEL_DARK)
    d.rectangle((x0, 85, x0, 88), fill=STEEL)
    d.rectangle((x1, 85, x1, 88), fill=STEEL_DEEP)
    # The reflective band, with its shade on the right.
    d.rectangle((x0 + 1, BAND_ROWS[0], x1 - 1, BAND_ROWS[1]), fill=AMBER)
    d.rectangle((x1 - 2, BAND_ROWS[0], x1 - 1, BAND_ROWS[1]), fill=AMBER_DARK)

    # The bracket under the board.
    d.rectangle(BRACKET, fill=INK)
    d.rectangle((BRACKET[0] + 1, BRACKET[1], BRACKET[2] - 1, BRACKET[3] - 1), fill=STEEL_DARK)
    d.rectangle((BRACKET[0] + 1, BRACKET[1], BRACKET[0] + 1, BRACKET[3] - 1), fill=STEEL)
    for p in ((29, 58), (34, 58)):                      # two bolts
        px[p] = STEEL_LIT

    # The board: outline, frame, face.
    d.rounded_rectangle(BOARD_OUTLINE, radius=2, fill=INK)
    d.rounded_rectangle(FACE_PX, radius=1, fill=FRAME)
    d.rectangle((8, 8, 55, 9), fill=FRAME_LIT)          # the frame's top
    d.rectangle((8, 8, 9, 55), fill=FRAME_LIT)          # and left, lit
    d.rectangle((8, 54, 55, 55), fill=FRAME_DARK)       # bottom
    d.rectangle((54, 8, 55, 55), fill=FRAME_DARK)       # and right, in shade
    px[8, 55] = FRAME
    px[55, 8] = FRAME
    px[8, 8] = GLINT                                    # the corner nearest the light
    d.rectangle(FACE_INNER, fill=FACE)
    d.rectangle((10, 10, 53, 10), fill=FACE_LOW)        # the frame's shadow on the face
    d.rectangle((10, 10, 10, 53), fill=FACE_LOW)
    # Highlight pixels that break the outline at the top-left, where the light comes from (rule 2).
    for p in ((11, 7), (12, 7), (13, 7), (14, 7), (7, 11), (7, 12), (7, 13), (7, 14), (36, 7), (37, 7)):
        px[p] = GLINT
    # A glint on the post's lit edge and the plate's rim too.
    for p in ((x0 + 1, 62), (x0 + 1, 63), (23, 89)):
        px[p] = GLINT
    return im


# The strong pass (T-577 v2, the Style Evaluator's rule 2 fixes): more steps and a shadow column.
FRAME_HI = (0x7C, 0x84, 0xAE, 255)    # the frame's outermost lit step
GLINT_BRIGHT = (0xB4, 0xBC, 0xE0, 255)  # the brightest glint, at the corner nearest the light
FACE_LIT = (0x3A, 0x3F, 0x5A, 255)    # the recessed face's lit inner edge, bottom and right
EDGE = (0x1F, 0x23, 0x36, 255)        # the board's thickness, right and bottom (the keycap's edge)
EDGE_DEEP = (0x16, 0x19, 0x28, 255)   # the shadow column on the post and base, against the outline
STRONG_BRACKET = (25, 59, 38, 62)
STRONG_POST_X = (27, 36)              # outline columns; steel on 28..35
STRONG_POST_ROWS = (63, 88)
STRONG_BAND_ROWS = (75, 78)
STRONG_BASE_OUTLINE = (18, 85, 46, 95)


def sign_strong() -> Image.Image:
    """The v2 sign: the v1 shapes with a thicker post and base, stepped shading across them, a shadow column
    on the right of the board, post and base, a bevelled frame with rivets, and longer glint runs breaking
    the outline on the board's top-left and the post's lit edge. The face stays blank slate."""
    im = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    px = im.load()

    # The base plate: outline, a two-row side with its right in deep shadow, a top lit towards the light.
    d.ellipse(STRONG_BASE_OUTLINE, fill=INK)
    d.ellipse((19, 86, 45, 94), fill=STEEL_DEEP)        # the side
    d.ellipse((19, 86, 45, 92), fill=STEEL_DARK)        # the top
    d.ellipse((20, 86, 37, 90), fill=STEEL)             # the lit part of the top
    for y in range(90, 95):                             # the shadow column on the plate's right side
        for x in range(39, 46):
            if px[x, y] == STEEL_DEEP:
                px[x, y] = EDGE_DEEP
    for p in ((21, 88), (22, 87), (23, 87)):            # rim light on the plate's lit edge
        px[p] = GLINT
    for p in ((24, 91), (40, 91)):                      # two bolts
        px[p] = STEEL_LIT

    # The post: outline, six steps across the steel from the lit edge to the shadow column.
    x0, x1 = STRONG_POST_X
    y0, y1 = STRONG_POST_ROWS
    d.rectangle((x0, y0, x1, y1), fill=INK)
    steps = (GLINT, STEEL_LIT, STEEL, STEEL, STEEL_DARK, STEEL_DARK, STEEL_DEEP, EDGE_DEEP)
    for i, c in enumerate(steps):
        d.rectangle((x0 + 1 + i, y0, x0 + 1 + i, y1), fill=c)
    d.rectangle((x0 + 1, 70, x1 - 1, 70), fill=STEEL_DEEP)   # a joint ring
    d.rectangle((x0 + 1, 71, x1 - 1, 71), fill=INK)
    d.rectangle((x0 + 1, STRONG_BAND_ROWS[0], x1 - 2, STRONG_BAND_ROWS[1]), fill=AMBER)   # the shadow column stays
    d.rectangle((x1 - 4, STRONG_BAND_ROWS[0], x1 - 2, STRONG_BAND_ROWS[1]), fill=AMBER_DARK)
    for y in range(66, 70):                             # glints breaking the post's outline
        px[x0, y] = GLINT
    for y in range(81, 84):
        px[x0, y] = GLINT
    for p in ((30, 73), (31, 82), (29, 86)):            # scuffs
        px[p] = STEEL_LIT
    # The collar at the foot.
    d.rectangle((25, 84, 38, 88), fill=INK)
    d.rectangle((26, 85, 37, 88), fill=STEEL_DARK)
    d.rectangle((26, 85, 26, 88), fill=STEEL_LIT)
    d.rectangle((36, 85, 36, 88), fill=STEEL_DEEP)
    d.rectangle((37, 85, 37, 88), fill=EDGE_DEEP)

    # The bracket under the board.
    b = STRONG_BRACKET
    d.rectangle(b, fill=INK)
    d.rectangle((b[0] + 1, b[1], b[2] - 1, b[3] - 1), fill=STEEL_DARK)
    d.rectangle((b[0] + 1, b[1], b[0] + 1, b[3] - 1), fill=STEEL_LIT)
    d.rectangle((b[2] - 2, b[1], b[2] - 1, b[3] - 1), fill=STEEL_DEEP)
    d.rectangle((b[2] - 1, b[1], b[2] - 1, b[3] - 1), fill=EDGE_DEEP)
    for p in ((28, 60), (35, 60)):                      # two rivets
        px[p] = GLINT

    # The board: its thickness on the right and bottom, then the outline, the bevelled frame, the face.
    d.rectangle((9, 9, 58, 58), fill=INK)               # the outline round the thickness
    d.rectangle((9, 9, 57, 57), fill=EDGE)              # the thickness, 1 px right and below
    d.rounded_rectangle(BOARD_OUTLINE, radius=2, fill=INK)
    d.rounded_rectangle(FACE_PX, radius=1, fill=FRAME)
    d.rectangle((8, 8, 55, 8), fill=FRAME_HI)           # the frame's top, two lit steps
    d.rectangle((8, 9, 54, 9), fill=FRAME_LIT)
    d.rectangle((8, 8, 8, 55), fill=FRAME_HI)           # and its left
    d.rectangle((9, 9, 9, 54), fill=FRAME_LIT)
    d.rectangle((9, 55, 55, 55), fill=FACE_LOW)         # the bottom, two shaded steps
    d.rectangle((10, 54, 55, 54), fill=FRAME_DARK)
    d.rectangle((55, 9, 55, 55), fill=FACE_LOW)         # and the right
    d.rectangle((54, 10, 54, 54), fill=FRAME_DARK)
    px[8, 55] = FRAME
    px[55, 8] = FRAME
    px[8, 8] = GLINT_BRIGHT                             # the corner nearest the light
    d.rectangle(FACE_INNER, fill=FACE)
    d.rectangle((10, 10, 53, 10), fill=FACE_LOW)        # the frame's shadow on the recessed face
    d.rectangle((10, 10, 10, 53), fill=FACE_LOW)
    d.rectangle((11, 53, 53, 53), fill=FACE_LIT)        # and its lit inner edge
    d.rectangle((53, 11, 53, 53), fill=FACE_LIT)
    for p in ((9, 9), (54, 9), (9, 54), (54, 54)):      # rivets at the frame's corners
        px[p] = GLINT if p == (9, 9) else STEEL_LIT
    # Glint runs breaking the outline on the board's top and left (rule 2).
    for x in list(range(10, 18)) + list(range(30, 34)) + list(range(44, 47)):
        px[x, 7] = GLINT
    for y in list(range(10, 18)) + list(range(30, 34)):
        px[7, y] = GLINT
    return im


# The slim pass (T-577 v3): a slim, longer pole on a flat base, a clearer lighter frame, a stepped face.
FACE_HI = (0x38, 0x3D, 0x57, 255)     # the face's lit upper-left band
FACE_DEEP = (0x2E, 0x33, 0x48, 255)   # its lower-right band, in shade
SLIM_BRACKET = (27, 59, 37, 60)
SLIM_POST_X = (29, 35)                # outline columns; steel on 30..34
SLIM_POST_ROWS = (61, 92)
SLIM_BAND_ROWS = (74, 76)
SLIM_BASE_OUTLINE = (22, 89, 42, 95)


def sign_slim() -> Image.Image:
    """The v3 sign: the board with a clearer lighter frame, longer and brighter glint runs breaking its outline
    and a stepped slate face (still blank); a slim pole, 5 px of steel on three shading steps plus a shadow
    column, running most of the way down to a small flat base plate, so it reads as a sign on a pole, not a
    bollard; three glint runs break the pole's outline. The thickness shadow of v2 stays."""
    im = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    px = im.load()

    # The flat base plate: outline, a one-row side with its right in deep shadow, a top lit on the left.
    d.ellipse(SLIM_BASE_OUTLINE, fill=INK)
    d.ellipse((23, 90, 41, 94), fill=STEEL_DEEP)        # the side
    d.ellipse((23, 90, 41, 93), fill=STEEL_DARK)        # the top
    d.ellipse((24, 90, 35, 92), fill=STEEL)             # the lit part of the top
    for y in range(92, 95):                             # the shadow column on the plate's right
        for x in range(36, 42):
            if px[x, y] == STEEL_DEEP:
                px[x, y] = EDGE_DEEP
    for p in ((24, 91), (25, 90)):                      # rim light on the plate's lit edge
        px[p] = GLINT
    for p in ((26, 93), (38, 93)):                      # two bolts
        px[p] = STEEL_LIT

    # The pole: outline, then three steps and a shadow column across 5 px of steel.
    x0, x1 = SLIM_POST_X
    y0, y1 = SLIM_POST_ROWS
    d.rectangle((x0, y0, x1, y1), fill=INK)
    for i, c in enumerate((STEEL_LIT, STEEL, STEEL, STEEL_DARK, EDGE_DEEP)):
        d.rectangle((x0 + 1 + i, y0, x0 + 1 + i, y1), fill=c)
    d.rectangle((x0 + 1, 68, x1 - 1, 68), fill=STEEL_DEEP)   # a joint ring
    d.rectangle((x0 + 1, SLIM_BAND_ROWS[0], x1 - 2, SLIM_BAND_ROWS[1]), fill=AMBER)
    d.rectangle((x1 - 3, SLIM_BAND_ROWS[0], x1 - 2, SLIM_BAND_ROWS[1]), fill=AMBER_DARK)
    for y in list(range(63, 67)) + list(range(79, 83)) + list(range(86, 88)):
        px[x0, y] = GLINT_BRIGHT                        # glints breaking the pole's outline
        px[x0 + 1, y] = GLINT
    for p in ((31, 71), (32, 84)):                      # scuffs
        px[p] = STEEL_LIT
    # A small collar at the foot.
    d.rectangle((28, 89, 36, 89), fill=INK)
    d.rectangle((28, 90, 28, 91), fill=STEEL_LIT)
    d.rectangle((36, 90, 36, 91), fill=EDGE_DEEP)
    px[28, 90] = GLINT

    # A shallow bracket under the board.
    b = SLIM_BRACKET
    d.rectangle(b, fill=INK)
    d.rectangle((b[0] + 1, b[1], b[2] - 1, b[1]), fill=STEEL_DARK)
    px[b[0] + 1, b[1]] = STEEL_LIT
    px[b[2] - 1, b[1]] = EDGE_DEEP
    for p in ((30, 59), (34, 59)):                      # two rivets
        px[p] = GLINT

    # The board: its thickness on the right and bottom, then the outline, the clearer frame, the stepped face.
    d.rectangle((9, 9, 58, 58), fill=INK)
    d.rectangle((9, 9, 57, 57), fill=EDGE)
    d.rounded_rectangle(BOARD_OUTLINE, radius=2, fill=INK)
    d.rounded_rectangle(FACE_PX, radius=1, fill=FRAME)
    d.rectangle((8, 8, 55, 8), fill=GLINT)              # the frame's top: two bright lit steps
    d.rectangle((8, 9, 54, 9), fill=FRAME_HI)
    d.rectangle((8, 8, 8, 55), fill=GLINT)              # and its left
    d.rectangle((9, 9, 9, 54), fill=FRAME_HI)
    d.rectangle((9, 55, 55, 55), fill=FRAME_DARK)       # the bottom: two steps, both lighter than the face
    d.rectangle((10, 54, 55, 54), fill=FRAME)
    d.rectangle((55, 9, 55, 55), fill=FRAME_DARK)       # and the right
    d.rectangle((54, 10, 54, 54), fill=FRAME)
    px[8, 55] = FRAME_LIT
    px[55, 8] = FRAME_LIT
    px[8, 8] = GLINT_BRIGHT
    # The face: blank slate in three stepped bands lit from the top-left (no icon, no marks).
    d.rectangle(FACE_INNER, fill=FACE)
    for y in range(FACE_INNER[1], FACE_INNER[3] + 1):
        for x in range(FACE_INNER[0], FACE_INNER[2] + 1):
            if x + y <= 44:
                px[x, y] = FACE_HI
            elif x + y >= 90:
                px[x, y] = FACE_DEEP
    d.rectangle((10, 10, 53, 10), fill=FACE_LOW)        # the frame's shadow on the recessed face
    d.rectangle((10, 10, 10, 53), fill=FACE_LOW)
    d.rectangle((11, 53, 53, 53), fill=FACE_LIT)        # and its lit inner edge
    d.rectangle((53, 11, 53, 53), fill=FACE_LIT)
    for p in ((9, 9), (54, 9), (9, 54), (54, 54)):      # rivets at the frame's corners
        px[p] = GLINT_BRIGHT if p == (9, 9) else STEEL_LIT
    # Long bright glint runs breaking the outline on the board's top and left (rule 2).
    for x in list(range(10, 20)) + list(range(28, 34)) + list(range(42, 46)):
        px[x, 7] = GLINT_BRIGHT
    for y in list(range(10, 20)) + list(range(28, 34)):
        px[7, y] = GLINT_BRIGHT
    for x in range(20, 24):
        px[x, 7] = GLINT
    for y in range(20, 24):
        px[7, y] = GLINT
    return im


# The bold pass (T-577 v4): the slim sign pushed to read at thumbnail size.
WHITE = (0xEE, 0xF0, 0xFA, 255)       # the near-white highlight that breaks the outline, 2 px wide
FACE_HI_2 = (0x41, 0x47, 0x6B, 255)   # the face's brightest band, nearest the light
FACE_DEEP_2 = (0x27, 0x2A, 0x3C, 255)  # its darkest band, furthest from it
BOLD_POST_RUNS = (range(62, 67), range(77, 83), range(86, 89))


def sign_bold() -> Image.Image:
    """The v4 sign: the slim sign with highlights that read at native size (near-white runs two pixels wide,
    on the outline and the pixel inside it, on the frame's top and left, the pole's lit edge and the base's
    rim), five stepped bands across the blank face, a two-column dark right side on the pole and the base's
    right in deep shadow, and rivets and scuffs along the frame."""
    im = sign_slim()
    px = im.load()
    # The face: five stepped bands lit from the top-left, still blank slate.
    for y in range(11, 53):
        for x in range(11, 53):
            s = x + y
            if s <= 34:
                px[x, y] = FACE_HI_2
            elif s <= 46:
                px[x, y] = FACE_HI
            elif s >= 98:
                px[x, y] = FACE_DEEP_2
            elif s >= 88:
                px[x, y] = FACE_DEEP
            else:
                px[x, y] = FACE
    # The frame: the glint runs on the outline become near-white and two pixels wide.
    for x in range(8, 56):
        if px[x, 7] == GLINT_BRIGHT:
            px[x, 7] = WHITE
            px[x, 8] = WHITE
    for y in range(8, 56):
        if px[7, y] == GLINT_BRIGHT:
            px[7, y] = WHITE
            px[8, y] = WHITE
    px[8, 8] = WHITE
    # Rivets along the frame (bright on the lit sides, steel on the shaded ones) and a few scuffs.
    for t in (14, 32, 50):
        px[t, 9] = WHITE
        px[9, t] = WHITE
        px[t, 54] = GLINT
        px[54, t] = GLINT
    for p in ((24, 8), (38, 9), (8, 40), (9, 46)):
        px[p] = FRAME_DARK
    for p in ((20, 55), (46, 54), (55, 20)):
        px[p] = STEEL_LIT
    # The pole: a two-column dark right side, and longer near-white runs two pixels wide on its lit edge.
    x0, x1 = SLIM_POST_X
    for y in range(SLIM_POST_ROWS[0], SLIM_POST_ROWS[1] + 1):
        if px[x1 - 2, y] == STEEL_DARK:
            px[x1 - 2, y] = STEEL_DEEP
    for run in BOLD_POST_RUNS:
        for y in run:
            px[x0, y] = WHITE
            px[x0 + 1, y] = GLINT_BRIGHT
    # The base: a near-white run breaking the plate's left rim, and its right side in deep shadow.
    for p in ((22, 92), (23, 91), (24, 90), (23, 92)):
        px[p] = WHITE
    px[25, 90] = GLINT_BRIGHT
    for y in range(90, 95):
        for x in range(37, 43):
            if px[x, y] in (STEEL_DARK, STEEL_DEEP):
                px[x, y] = EDGE_DEEP
    # The bracket's rivets, bright.
    for p in ((30, 59), (34, 59)):
        px[p] = WHITE
    return im


BODY_ROLES = (STEEL, STEEL_LIT, STEEL_DARK, STEEL_DEEP)
V1_ROLES = (INK, GLINT, GLINT_BRIGHT, WHITE, FRAME, FRAME_LIT, FRAME_HI, FRAME_DARK, AMBER, AMBER_DARK, FACE,
            FACE_LOW, FACE_LIT, FACE_HI, FACE_HI_2, FACE_DEEP, FACE_DEEP_2, EDGE, EDGE_DEEP)
PASSES = {"strong": sign_strong, "slim": sign_slim, "bold": sign_bold}


def polish_pass(im: Image.Image, name: str) -> Image.Image:
    """A pass over a finished sign: the pass's sign (outline, glints, frame, face, band, thickness, shadow
    columns) replaces the source; where it has plain steel (the post's and base's body), PixelLab's own
    render stays if the source has an opaque pixel there that is not a script role."""
    src = im.convert("RGBA")
    spx = src.load()
    out = PASSES[name]()
    opx = out.load()
    for y in range(HEIGHT):
        for x in range(WIDTH):
            if opx[x, y] in BODY_ROLES and spx[x, y][3] == 255 and spx[x, y] not in V1_ROLES:
                opx[x, y] = spx[x, y]
    return out


def polish_strong(im: Image.Image) -> Image.Image:
    return polish_pass(im, "strong")


def polish_slim(im: Image.Image) -> Image.Image:
    return polish_pass(im, "slim")


def roles(strong: bool = False) -> dict[str, int]:
    """How many pixels each colour role has in the script sign."""
    names = {
        INK: "ink", FACE: "face", FACE_LOW: "face_low", FRAME: "frame", FRAME_LIT: "frame_lit",
        FRAME_DARK: "frame_dark", GLINT: "glint", STEEL: "steel", STEEL_LIT: "steel_lit",
        STEEL_DARK: "steel_dark", STEEL_DEEP: "steel_deep", AMBER: "amber", AMBER_DARK: "amber_dark",
        FRAME_HI: "frame_hi", GLINT_BRIGHT: "glint_bright", FACE_LIT: "face_lit", EDGE: "edge",
        EDGE_DEEP: "edge_deep", FACE_HI: "face_hi", FACE_DEEP: "face_deep", WHITE: "white",
        FACE_HI_2: "face_hi_2", FACE_DEEP_2: "face_deep_2",
    }
    counts: dict[str, int] = {}
    shape = PASSES[strong]() if isinstance(strong, str) else (sign_strong() if strong else sign())
    for p in shape.getdata():
        if p[3] == 255:
            counts[names.get(p, "other")] = counts.get(names.get(p, "other"), 0) + 1
    return counts


def _png_bytes(im: Image.Image) -> bytes:
    b = io.BytesIO()
    im.convert("RGBA").save(b, format="PNG")
    return b.getvalue()


def save_png(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(_png_bytes(im))


DESCRIPTION = (
    "one small roadside sign post standing upright, seen in 3/4 isometric view from slightly above, a blank "
    "square sign board facing the camera with an empty plain dark slate blue-grey face and a thin lighter "
    "steel frame, nothing drawn on the board, the board mounted on a short thin grey steel pole with a small "
    "round metal base plate on the ground, a narrow amber reflective band on the pole, near-black outline, a "
    "few lighter highlight pixels on the top-left edges, night-time city street furniture, retro arcade look, "
    "crisp pixel art, no gradients, transparent background"
)

NEGATIVE = (
    "text, letters, words, symbol, icon, arrow, logo, picture on the board, drawing on the board, pattern on "
    "the board, several signs, two posts, road, ground, grass, background, drop shadow, blur, gradient, photo, "
    "3d render, green, yellow"
)


def request(init_png: bytes, strength: int = 500, seed: int | None = None) -> dict:
    body = {
        "description": DESCRIPTION,
        "negative_description": NEGATIVE,
        "image_size": {"width": WIDTH, "height": HEIGHT},
        "no_background": True,
        "text_guidance_scale": 8.0,
        "outline": "single color black outline",
        "shading": "detailed shading",
        "detail": "highly detailed",
        "view": "low top-down",
        "init_image": {"type": "base64", "base64": base64.b64encode(init_png).decode("ascii")},
        "init_image_strength": int(strength),
    }
    if seed is not None:
        body["seed"] = int(seed)
    return body


POLISH_ROLES = (INK, GLINT, FRAME_LIT, FRAME_DARK, FRAME, AMBER, AMBER_DARK)


def polish(im: Image.Image) -> Image.Image:
    """Repaints the script's outline, glints, frame and band over PixelLab's render, so the near-black
    outline is exact, the highlight pixels break it where the script put them and the frame reads as a
    frame; PixelLab's own pixels stay everywhere else (the post, the base, the face's texture if kept)."""
    out = im.convert("RGBA")
    px = out.load()
    spx = sign().load()
    for y in range(HEIGHT):
        for x in range(WIDTH):
            if spx[x, y] in POLISH_ROLES:
                px[x, y] = spx[x, y]
    return out


def blank_face(im: Image.Image) -> Image.Image:
    """The face inside the frame put back to the script's blank slate (the icon goes there)."""
    out = im.convert("RGBA")
    px = out.load()
    spx = sign().load()
    for y in range(FACE_INNER[1], FACE_INNER[3] + 1):
        for x in range(FACE_INNER[0], FACE_INNER[2] + 1):
            px[x, y] = spx[x, y]
    return out


def finish(raw: Image.Image, do_polish: bool = True, keep_face: bool = False, reduce: bool = True) -> Image.Image:
    """The free fixes on a PixelLab result, keeping its pixels wherever they can stay."""
    im = raw.convert("RGBA")
    if im.size != SIZE:
        im = im.resize(SIZE, Image.NEAREST)
    shape = sign()
    spx = shape.load()
    px = im.load()
    for y in range(HEIGHT):
        for x in range(WIDTH):
            r, g, b, a = px[x, y]
            if a < 128 or spx[x, y][3] == 0:
                px[x, y] = (0, 0, 0, 0)       # the canvas outside the sign, and half pixels
            else:
                px[x, y] = (r, g, b, 255)
    for y in range(HEIGHT):
        for x in range(WIDTH):
            if spx[x, y][3] == 255 and px[x, y][3] == 0:
                px[x, y] = spx[x, y]          # pixels the shape has but PixelLab lost
    if not keep_face:
        im = blank_face(im)
    if do_polish:
        im = polish(im)
    if reduce:
        im = reduce_image(im, 30)
    return im


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("init", help="draw the script sign")
    a.add_argument("out")
    r = sub.add_parser("request", help="write the pixflux request body")
    r.add_argument("out")
    r.add_argument("--init", required=True)
    r.add_argument("--strength", type=int, default=500)
    r.add_argument("--seed", type=int)
    f = sub.add_parser("finish", help="free fixes on PixelLab's output")
    f.add_argument("raw")
    f.add_argument("out")
    f.add_argument("--no-polish", action="store_true", help="keep PixelLab's outline, frame and band pixels")
    f.add_argument("--keep-face", action="store_true", help="keep PixelLab's paint on the face")
    f.add_argument("--no-reduce", action="store_true")
    q = sub.add_parser("polish", help="the strong rule 2 pass over a finished sign (T-577 v2)")
    q.add_argument("src")
    q.add_argument("out")
    q.add_argument("--strong", action="store_true", help="the v2 pass")
    q.add_argument("--slim", action="store_true", help="the v3 pass: a slim long pole, a clearer frame, a stepped face")
    q.add_argument("--bold", action="store_true", help="the v4 pass: slim, with highlights that read at native size")
    ro = sub.add_parser("roles", help="print the script sign's pixel counts per role")
    ro.add_argument("--strong", action="store_true")
    ro.add_argument("--slim", action="store_true")
    ro.add_argument("--bold", action="store_true")
    v = sub.add_parser("preview", help="enlarged preview on dark and light")
    v.add_argument("src")
    v.add_argument("out")
    v.add_argument("--scale", type=int, default=6)
    args = p.parse_args(argv)

    if args.cmd == "init":
        save_png(sign(), Path(args.out))
    elif args.cmd == "request":
        body = request(Path(args.init).read_bytes(), args.strength, args.seed)
        Path(args.out).parent.mkdir(parents=True, exist_ok=True)
        Path(args.out).write_text(json.dumps(body) + "\n", encoding="utf-8")
    elif args.cmd == "finish":
        with Image.open(args.raw) as raw:
            im = finish(raw, not args.no_polish, args.keep_face, not args.no_reduce)
        save_png(im, Path(args.out))
    elif args.cmd == "polish":
        if not (args.strong or args.slim or args.bold):
            p.error("polish needs --strong, --slim or --bold")
        with Image.open(args.src) as src:
            im = reduce_image(polish_pass(src, "bold" if args.bold else "slim" if args.slim else "strong"), 30)
        save_png(im, Path(args.out))
    elif args.cmd == "roles":
        for name, n in sorted(roles("bold" if args.bold else "slim" if args.slim else args.strong).items()):
            print(f"{name}: {n}")
        return 0
    else:
        with Image.open(args.src) as src:
            save_png(preview_image(src, args.scale), Path(args.out))
    print("wrote", args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
