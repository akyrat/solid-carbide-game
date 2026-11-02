"""Build the rain's raindrop sheet (T-509): 3 drop variants, 8 x 16 each, in one 24 x 16 row.

Free script step of the style loop. PixelLab drew the source pixels
(art-archive/T-509/style-loop/raw/v1_raw.png, a vertical outlined teardrop, and
v1b_raw.png, three 45-degree streaks); neither had the brief's lean, so the
streaks are redrawn here pixel by pixel at the brief's lean (the top 1 pixel to
the right for every 3 rows down, about 18 degrees) in colours sampled from
those two generations. Nothing is scaled.

Usage: python game/tools/build_rain_drops.py <out.png>
"""
import sys

from PIL import Image

FRAME_W, FRAME_H, FRAMES = 8, 16, 3

# Colours sampled from PixelLab's two T-509 generations, head (light) to tail (dark).
HEAD = (249, 250, 254)   # v1_raw B: near white-blue
HEAD2 = (215, 235, 253)  # v1_raw E
CYAN = (182, 222, 254)   # v1_raw A: a hint of cyan
BODY = (112, 132, 204)   # v1_raw C: mid blue
BODY2 = (88, 125, 165)   # v1b_raw C: blue-grey
TAIL = (85, 119, 157)    # v1b_raw A: desaturated blue
TAIL2 = (54, 57, 72)     # v1_raw G: dark fade

THIN = [(0.10, HEAD), (0.22, HEAD2), (0.40, CYAN), (0.62, BODY2), (0.82, TAIL), (1.01, TAIL2)]
THICK = [(0.08, HEAD), (0.20, HEAD2), (0.38, CYAN), (0.60, BODY), (0.80, BODY2), (0.92, TAIL), (1.01, TAIL2)]
BRIGHT = [(0.25, HEAD), (0.50, HEAD2), (0.75, CYAN), (1.01, BODY)]
# The second (left) column of the thick drop is one shade darker than the first.
DARKER = {HEAD: HEAD2, HEAD2: CYAN, CYAN: BODY, BODY: BODY2, BODY2: TAIL, TAIL: TAIL2, TAIL2: TAIL2}

# (first row, last row, x of the head, palette, width in pixels)
def _lean(top: int, x_top: int, lean: int, keys: str, wide: str = "") -> list[tuple[int, int, str]]:
    """Like _streak, but spreads exactly `lean` columns of sideways shift evenly over the streak's rows."""
    n = len(keys)
    px = []
    for i, k in enumerate(keys):
        x = x_top - round(i * lean / max(n - 1, 1))
        px.append((top + i, x, k))
        if i < len(wide) and wide[i] != ".":
            px.append((top + i, x + 1, wide[i]))
    return px


# Version 2 (style loop round 1 reason): frames 1 and 2 are continuous streaks ~15 rows tall with 5 px of lean;
# the darkest tail colours (G, H) are dropped so the tail never vanishes on the dark streets (B is the darkest);
# frame 3 is a distinct short, bright, 2-px streak with no dark tail.
VARIANTS_V2 = [
    # 1: thin 1-px streak, 15 rows, 5 px lean.
    _lean(0, 6, 5, "BBBCCCEEEAAFFDD"),
    # 2: thicker and longer: 16 rows, 2 px wide below the tail tip (right column one shade darker).
    _lean(0, 6, 5, "BBCCEEEAAAFFFDDD", "..BBCCCEEEAAFF.."),
    # 3: short bright streak, 8 rows, 2-px bright core.
    _lean(4, 5, 3, "EAAFFDDD", ".EEAAFF."),
]

VARIANTS_BY_VERSION = {}

VARIANTS = [
    (1, 14, 6, THIN, 1),    # 1: thin streak
    (0, 15, 6, THICK, 2),   # 2: thicker, longer streak
    (3, 11, 5, BRIGHT, 1),  # 3: short bright streak
]


def colour_at(palette, t):
    for limit, colour in palette:
        if t < limit:
            return colour
    return palette[-1][1]


def draw_frame(top, bottom, head_x, palette, width):
    im = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    length = bottom - top
    for y in range(top, bottom + 1):
        t = (y - top) / length if length else 0.0
        x = head_x - (y - top + (1 if width == 2 else 0)) // 3
        colour = colour_at(palette, t)
        # The thick drop's head and tail rows stay 1 pixel wide (keeps the corners clear).
        if width == 2 and top < y < bottom:
            im.putpixel((x + 1, y), colour + (255,))
            im.putpixel((x, y), DARKER[colour] + (255,))
        else:
            im.putpixel((x, y), colour + (255,))
    return im


def build_sheet():
    sheet = Image.new("RGBA", (FRAME_W * FRAMES, FRAME_H), (0, 0, 0, 0))
    for i, variant in enumerate(VARIANTS):
        sheet.paste(draw_frame(*variant), (i * FRAME_W, 0))
    return sheet


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    build_sheet().save(sys.argv[1])
    print("wrote", sys.argv[1])


if __name__ == "__main__":
    main()
