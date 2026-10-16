#!/usr/bin/env python3
"""Builds the level-up screen's red and gold art (task T-140; no PixelLab call for these pieces).

Pieces (written to game/art/level_up/, each with a record JSON; shown at 2 screen pixels per art pixel,
except the sunburst, which T-141 scales as it likes):
  card_frame.png            180x150  9-slice card (margin 10): gold and red border, cream fill
  highlight_frame.png       192x162  hollow bright-gold frame; the card sits at (6, 6) inside it
  header_ribbon.png         380x44   red ribbon, gold trim, a Redgull logo medallion at each end;
                                     the game letters the title between the medallions (x 76..304)
  button_plate.png / button_plate_pressed.png   72x22  "Take it" plate, text added by the game
  sunburst.png              256x256  red and gold rays in a circle, behind the cards
  gift_pack_emblem.png      128x128  the approved PixelLab gift box (art-archive/T-140/gift_pack_raw.png,
                                     left as it is) with the Redgull logo stamped on a cream disc by script

Rules (Visual style, Decisions): hard pixel edges, selective dark outline, at most 30 colours per sprite,
alpha 0 or 255 only, transparent background where the piece needs one. The logo is the approved one-colour
gull (game/art/logo/redgull_logo_32.png). Byte-identical on every run.

  python game/tools/build_level_up_art.py build   # writes the PNGs and records, then checks them
  python game/tools/build_level_up_art.py check   # checks the written PNGs (exit 1 on a fail)
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_sprite_rules as rules  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
REPO = GAME.parent
OUT = GAME / "art" / "level_up"
RAW_BOX = REPO / "art-archive" / "T-140" / "gift_pack_raw.png"
LOGO_32 = GAME / "art" / "logo" / "redgull_logo_32.png"
MAX_COLORS = 30

OUTLINE = (14, 6, 10)
GOLD_L = (255, 236, 150)
GOLD_Y = (255, 214, 64)
GOLD = (240, 180, 40)
GOLD_D = (176, 118, 24)
RED_L = (222, 44, 52)
RED = (176, 24, 36)
RED_D = (110, 14, 24)
CREAM = (255, 244, 214)
CREAM_D = (232, 214, 170)

FILES = ["card_frame", "highlight_frame", "header_ribbon", "button_plate", "button_plate_pressed",
         "sunburst", "gift_pack_emblem"]


def new(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def put(im, x, y, c):
    im.putpixel((x, y), tuple(c) + (255,))


def hline(im, x0, x1, y, c):
    for x in range(x0, x1 + 1):
        put(im, x, y, c)


def corner_cut(cuts, h, y):
    if y < len(cuts):
        return cuts[y]
    if h - 1 - y < len(cuts):
        return cuts[h - 1 - y]
    return 0


def rings(im, colors, cuts, hollow=False):
    """Concentric stepped-corner rings from the outside in; `cuts` is the corner cut per row.
    Solid rings fill their whole row; with hollow=True only the ring's own pixels are drawn."""
    w, h = im.size
    for k, c in enumerate(colors):
        for y in range(k, h - k):
            xs = max(corner_cut(cuts, h, y), k)
            if not hollow or y == k or y == h - 1 - k:
                hline(im, xs, w - 1 - xs, y, c)
            else:
                put(im, xs, y, c)
                put(im, w - 1 - xs, y, c)


def card_frame():
    w, h = 180, 150
    im = new(w, h)
    ring = [OUTLINE, GOLD_L, GOLD, GOLD, GOLD_D, OUTLINE, RED_L, RED, OUTLINE, CREAM_D]
    rings(im, ring, [5, 3, 2, 1, 1])
    k = len(ring)
    for y in range(k, h - k):
        hline(im, k, w - 1 - k, y, CREAM)
    hline(im, k, w - 1 - k, k, CREAM_D)  # a soft shadow under the top border
    for cx, cy in ((12, 12), (w - 13, 12), (12, h - 13), (w - 13, h - 13)):  # gold studs
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                put(im, cx + dx, cy + dy, GOLD_L if dx + dy < 0 else GOLD)
    return im


def highlight_frame():
    im = new(192, 162)
    rings(im, [GOLD_D, OUTLINE, GOLD_L, GOLD_Y, GOLD, OUTLINE], [9, 6, 4, 3, 2, 1, 1], hollow=True)
    return im


def disc(im, cx, cy, r, fill, edge, shade):
    for y in range(cy - r - 1, cy + r + 2):
        for x in range(cx - r - 1, cx + r + 2):
            d = math.hypot(x - cx, y - cy)
            if d <= r + 1:
                c = edge if d > r else (shade if (x - cx) + (y - cy) > r * 0.9 else fill)
                put(im, x, y, c)


def stamp_logo(im, cx, cy):
    logo = Image.open(LOGO_32).convert("RGBA")
    im.alpha_composite(logo, (cx - 16, cy - 16))


def header_ribbon():
    w, h = 380, 44
    im = new(w, h)
    for side in (0, 1):  # folded tails behind the body, with a V notch at the outer end
        for y in range(8, 44):
            for dx in range(36):
                x = dx if side == 0 else w - 1 - dx
                notch = max(0, 12 - abs(y - 26))
                if dx < notch or (y in (8, 43) and dx < 2):
                    continue
                edge = y in (8, 43) or dx == notch
                put(im, x, y, OUTLINE if edge else RED_D)
    body = [OUTLINE, GOLD_L, GOLD, OUTLINE] + [RED_L, RED_L] + [RED] * 16
    for i, c in enumerate(body):  # the upper half, mirrored for the lower half
        hline(im, 14, w - 15, 2 + i, c)
        hline(im, 14, w - 15, 41 - i, RED_D if 4 <= i < 8 else c)
    for y in range(2, 42):  # end caps
        put(im, 14, y, OUTLINE)
        put(im, w - 15, y, OUTLINE)
    for cx in (46, w - 47):  # a Redgull medallion at each end
        disc(im, cx, 22, 15, CREAM, OUTLINE, CREAM_D)
        stamp_logo(im, cx, 22)
    return im


def button(pressed):
    w, h = 72, 22
    im = new(w, h)
    ring = [OUTLINE, RED_D, RED_D] if pressed else [OUTLINE, RED_L, RED]
    rings(im, ring, [2, 1])
    k = len(ring)
    for y in range(k, h - k):
        if pressed:
            c = GOLD_D
        elif y == k:
            c = GOLD_L
        elif y >= h - k - 2:
            c = GOLD_D
        else:
            c = GOLD
        hline(im, k, w - 1 - k, y, c)
    return im


def sunburst():
    n = 256
    im = new(n, n)
    c = (n - 1) / 2
    cols = [RED_D, RED, RED_D, GOLD_D]
    for y in range(n):
        for x in range(n):
            d = math.hypot(x - c, y - c)
            if d <= n / 2 - 0.5:
                a = (math.atan2(y - c, x - c) + math.tau) % math.tau
                col = OUTLINE if d > n / 2 - 4 else cols[int(a / math.tau * 24) % 4]
                put(im, x, y, col)
    return im


def gift_pack_emblem():
    im = Image.open(RAW_BOX).convert("RGBA")
    disc(im, 63, 91, 13, CREAM, OUTLINE, CREAM_D)
    stamp_logo(im, 63, 91)
    return im


BUILDERS = {
    "card_frame": (card_frame, "The card: a 9-slice frame (margin 10 art pixels) in gold and red with a cream fill and four gold studs. Replaces T-052's white rounded card; shown 2x (360x300).", "none (the ribbon and the gift box carry the logo)"),
    "highlight_frame": (highlight_frame, "The highlighted card's frame: bright gold with a darker glow ring and black lines, hollow. The card sits 6 art pixels inside it (shown 2x). Replaces T-052's yellow ring.", "none"),
    "header_ribbon": (header_ribbon, "The banner: red ribbon with gold trim and folded tails, a cream medallion with the Redgull gull at each end; the game letters the title between x 76 and 304. Shown 2x (760 wide, as wide as the two cards and their gap).", "logo on both medallions"),
    "button_plate": (lambda: button(False), "The 'Take it' plate: gold with a red edge; the game letters the text. Shown 2x.", "none"),
    "button_plate_pressed": (lambda: button(True), "The 'Take it' plate pressed: darker gold, flat, dark red edge. Shown 2x.", "none"),
    "sunburst": (sunburst, "Backdrop: 24 rays in dark red, red and dark gold inside a circle with a black rim. Sits behind the cards over the dimmed run; T-141 may spin and scale it (4x covers the 1152x648 window).", "none"),
    "gift_pack_emblem": (gift_pack_emblem, "Gift pack emblem: the PixelLab gift box (art-archive/T-140/gift_pack_raw.png, unchanged) with the Redgull logo on a cream disc on its front. Shown 1x or 2x beside the ribbon.", "logo on the box front"),
}


def check_png(path):
    with open(path, "rb") as f:
        w, h, rows = rules.decode_png(f.read())
    px = [p for r in rows for p in r]
    semi = sum(1 for p in px if 0 < p[3] < 255)
    colors = {p[:3] for p in px if p[3] == 255}
    results = [("no semi-transparent pixels", semi == 0, "%d" % semi),
               ("%d colours or fewer" % MAX_COLORS, len(colors) <= MAX_COLORS, "%d colours" % len(colors)),
               ("has opaque pixels", any(p[3] == 255 for p in px), ""),
               ("transparent corners", all(r[3] == 0 for r in (rows[0][0], rows[0][-1], rows[-1][0], rows[-1][-1])), "")]
    return results, (w, h)


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (fn, what, logo) in BUILDERS.items():
        im = fn()
        im.save(OUT / (name + ".png"))
        made = ("game/tools/build_level_up_art.py (script, 0 PixelLab generations)" if name != "gift_pack_emblem"
                else "game/tools/build_level_up_art.py: art-archive/T-140/gift_pack_raw.png (PixelLab, 1 generation, T-140 sample) plus the logo by script")
        rec = {"task": "T-140", "what": what, "logo": logo, "made_by": made, "size": list(im.size), "prompt": None}
        (OUT / (name + ".json")).write_text(json.dumps(rec, indent=1) + "\n", encoding="utf-8")


def check():
    ok_all = True
    for name in FILES:
        res, size = check_png(OUT / (name + ".png"))
        ok = all(r[1] for r in res)
        ok_all &= ok
        print("%s  %s %s  %s" % ("PASS" if ok else "FAIL", name, size,
                                 "; ".join("%s %s" % (a, "ok" if k else "FAIL (%s)" % d) for a, k, d in res)))
    return 0 if ok_all else 1


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    if cmd == "build":
        build()
    sys.exit(check())
