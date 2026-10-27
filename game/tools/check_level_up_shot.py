#!/usr/bin/env python3
"""Level-up screen check (T-309): a screenshot of the open screen, checked by script.

  python game/tools/check_level_up_shot.py <png> [--game-dir game]

Prints JSON with
  red     every pixel style_rules.is_old_brand_red flags (count, and the first positions),
  art     the colour counts of the screenshot's pixels whose colour is exactly one of the opaque
          colours of art/level_up/header_ribbon.png, card_frame.png, highlight_frame.png and
          gift_pack_emblem.png, leaving out the cream fills (CREAM, CREAM_D of
          build_level_up_art.py) and the text ink,
  leader  the most common of those colours, and whether it is Greenbull's dark green.
Exit code 0 only when there is no red pixel and dark green leads.
"""
import argparse
import json
import os
import sys
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import style_rules  # noqa: E402

ART_FILES = ("header_ribbon.png", "card_frame.png", "highlight_frame.png", "gift_pack_emblem.png")
# build_level_up_art.py: CREAM and CREAM_D; the text is drawn in the ink colour below.
CREAM = (246, 250, 232)
CREAM_D = (214, 226, 196)
TEXT_INK = (0, 0, 0)  # level_up_screen.gd INK
LEFT_OUT = {CREAM, CREAM_D, TEXT_INK}
MAX_POSITIONS = 20


def read_rows(path):
    """Rows of (r, g, b, a). Pillow reads it: Godot's screenshots are 8-bit RGB."""
    from PIL import Image
    with Image.open(path) as im:
        im = im.convert("RGBA")
        w, h = im.size
        px = list(im.getdata())
    return [px[y * w:(y + 1) * w] for y in range(h)]


def art_colours(game_dir):
    """The opaque colours of the four art files, without the cream fills and the text ink."""
    colours = set()
    for name in ART_FILES:
        for row in read_rows(os.path.join(game_dir, "art", "level_up", name)):
            colours.update(p[:3] for p in row if p[3] == 255)
    return colours - LEFT_OUT


def check(rows, art):
    red, counts = [], Counter()
    for y, row in enumerate(rows):
        for x, p in enumerate(row):
            rgb = tuple(p[:3])
            if style_rules.is_old_brand_red(rgb):
                red.append((x, y, rgb))
            if rgb in art:
                counts[rgb] += 1
    top = counts.most_common(1)[0][0] if counts else None
    dark = style_rules.GREENBULL_DARK_GREEN
    return {
        "red_pixels": len(red),
        "red_positions": [{"x": x, "y": y, "rgb": list(c)} for x, y, c in red[:MAX_POSITIONS]],
        "art_colour_counts": [{"rgb": list(c), "count": n} for c, n in counts.most_common(12)],
        "most_common_art_colour": list(top) if top else None,
        "most_common_is_dark_green": top == dark,
        "ok": not red and top == dark,
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("png")
    ap.add_argument("--game-dir", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    a = ap.parse_args(argv)
    rep = check(read_rows(a.png), art_colours(a.game_dir))
    print(json.dumps(rep, indent=1))
    return 0 if rep["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
