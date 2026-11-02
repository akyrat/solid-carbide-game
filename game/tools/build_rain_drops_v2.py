"""T-509 raindrop sheet, version 2 (style loop round 1 refine; free script fix, no PixelLab call).

Kept in its own file because build_rain_drops.py is being edited by another run.
Same colours as version 1 (sampled from PixelLab's T-509 generations, art-archive/T-509/style-loop/raw/),
but: the darkest tail colour (54, 57, 72) is dropped so no drop vanishes on the dark streets; frames 1 and 2
span the full 15 to 16 rows with exactly 5 px of lean (top to the right); frame 2 is 2 px wide only in its
body; frame 3 is short and the brightest (whites only, a 2-px white core). Nothing is scaled.

Usage: python game/tools/build_rain_drops_v2.py [--version 2|3|4] <out.png>   (default 2)
"""
import sys

from PIL import Image

FRAME_W, FRAME_H = 8, 16

HEAD = (249, 250, 254)   # near white-blue
HEAD2 = (215, 235, 253)
CYAN = (182, 222, 254)   # hint of cyan
BODY = (112, 132, 204)   # mid blue
BODY2 = (88, 125, 165)   # blue-grey
TAIL = (85, 119, 157)    # desaturated blue, darkest used
DARKER = {HEAD: HEAD2, HEAD2: CYAN, CYAN: BODY, BODY: BODY2, BODY2: TAIL, TAIL: TAIL}

# (first row, x of the head, lean in px, colours per row head to tail, rows (index) that are 2 px wide)
VARIANTS = [
    (0, 6, 5, [HEAD, HEAD, HEAD2, HEAD2, CYAN, CYAN, CYAN, BODY, BODY, BODY, BODY2, BODY2, BODY2, TAIL, TAIL], ()),
    (0, 6, 5, [HEAD, HEAD, HEAD, HEAD2, HEAD2, CYAN, CYAN, CYAN, BODY, BODY, BODY, BODY2, BODY2, BODY2, TAIL, TAIL],
     range(2, 13)),
    (4, 5, 2, [HEAD, HEAD, HEAD, HEAD, HEAD2, HEAD2, CYAN], (1, 2, 3)),
]

# Version 3 (style loop round 2 reason: tails too dim on the dark streets, variant 3 not distinct enough).
# The body and tail are lifted: the head colours stay PixelLab's; body and tail are PixelLab's blue-greys
# brightened by script (darkest luminance now about 130 instead of 114), still darker than the body so the
# drop fades. Variant 3 is shorter (6 rows), 2 px wide for 5 of them and only whites and cyan.
BODY_V3 = (140, 164, 214)
BODY2_V3 = (120, 145, 188)
TAIL_V3 = (108, 134, 172)
DARKER_V3 = {HEAD: HEAD2, HEAD2: CYAN, CYAN: BODY_V3, BODY_V3: BODY2_V3, BODY2_V3: TAIL_V3, TAIL_V3: TAIL_V3}
VARIANTS_V3 = [
    (0, 6, 5, [HEAD, HEAD, HEAD2, HEAD2, CYAN, CYAN, CYAN, BODY_V3, BODY_V3, BODY_V3,
               BODY2_V3, BODY2_V3, BODY2_V3, TAIL_V3, TAIL_V3], ()),
    (0, 6, 5, [HEAD, HEAD, HEAD, HEAD2, HEAD2, CYAN, CYAN, CYAN, BODY_V3, BODY_V3, BODY_V3,
               BODY2_V3, BODY2_V3, BODY2_V3, TAIL_V3, TAIL_V3], range(2, 13)),
    (5, 5, 2, [HEAD, HEAD, HEAD, HEAD, HEAD2, CYAN], (1, 2, 3, 4)),
]

# Version 4 (style loop round 3 reason: variant 2 could read blobby, variant 3 flat with 3 colours).
# Same colours as version 3. Variant 2 is 2 px wide only on rows 3 to 9 (7 rows, was 11), so it reads as a
# slim streak with a thicker upper body. Variant 3 gets a full 4-step ramp: near-white head, white-blue,
# cyan, and a mid blue tail pixel, 7 rows, 2 px wide on rows 1 to 3 only.
VARIANTS_V4 = [
    VARIANTS_V3[0],
    (0, 6, 5, [HEAD, HEAD, HEAD, HEAD2, HEAD2, CYAN, CYAN, CYAN, BODY_V3, BODY_V3, BODY_V3,
               BODY2_V3, BODY2_V3, BODY2_V3, TAIL_V3, TAIL_V3], range(3, 10)),
    (5, 5, 2, [HEAD, HEAD, HEAD, HEAD2, HEAD2, CYAN, BODY_V3], (1, 2, 3)),
]

VERSIONS = {2: (VARIANTS, DARKER), 3: (VARIANTS_V3, DARKER_V3), 4: (VARIANTS_V4, DARKER_V3)}


def draw_frame(top, x_top, lean, colours, wide, darker=DARKER):
    im = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    n = len(colours)
    for i, c in enumerate(colours):
        x = x_top - round(i * lean / (n - 1))
        im.putpixel((x, top + i), c + (255,))
        if i in wide:
            im.putpixel((x - 1, top + i), darker[c] + (255,))
    return im


def build_sheet(version=2):
    variants, darker = VERSIONS[version]
    sheet = Image.new("RGBA", (FRAME_W * len(variants), FRAME_H), (0, 0, 0, 0))
    for i, v in enumerate(variants):
        sheet.paste(draw_frame(*v, darker=darker), (i * FRAME_W, 0))
    return sheet


def main():
    args = sys.argv[1:]
    version = 2
    if len(args) == 3 and args[0] == "--version":
        version, args = int(args[1]), args[2:]
    if len(args) != 1 or version not in VERSIONS:
        print(__doc__)
        sys.exit(2)
    build_sheet(version).save(args[0])
    print("wrote", args[0], "version", version)


if __name__ == "__main__":
    main()
