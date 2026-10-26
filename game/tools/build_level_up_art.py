#!/usr/bin/env python3
"""Builds the level-up screen's art in Greenbull's colours (task T-303; first red and gold, T-140).

No PixelLab call: every piece is script-drawn, and the gift box is the approved T-140 PixelLab box recoloured
by script. Visual style, Decisions, "Greenbull's look": dark green leads, light green supports it, yellow is a
small accent. The emblem is Greenbull's approved bull's head (game/art/logo/greenbull_emblem_32.png, T-294/T-300),
stamped where the Redgull gull was. The old red and gold pieces are kept in art-archive/T-303/red_gold/.

Pieces (written to game/art/level_up/, each with a record JSON; shown at 2 screen pixels per art pixel,
except the sunburst, which T-141 scales as it likes). Same names and sizes as T-140's, so level_up_screen.gd
loads them unchanged:
  card_frame.png            180x150  9-slice card (margin 10): dark green and light green border, pale fill,
                                     four small yellow studs
  highlight_frame.png       192x162  hollow bright frame (pale and light green, one yellow line);
                                     the card sits at (6, 6) inside it
  header_ribbon.png         380x44   light green ribbon (the game letters the black title on it, x 76..304),
                                     dark green trim with one yellow line, dark green folded tails,
                                     a pale medallion with Greenbull's emblem at each end
  button_plate.png / button_plate_pressed.png   72x22  "Take it" plate, text added by the game
  sunburst.png              256x256  dark green rays in a circle, behind the cards
  gift_pack_emblem.png      128x128  T-140's PixelLab gift box (art-archive/T-140/gift_pack_raw.png, read, never
                                     changed) recoloured: dark green box, light green ribbon, yellow sparkles,
                                     with Greenbull's emblem on a pale disc on its front

Rules (Visual style, Content, "Rules"): hard pixel edges, selective dark outline, at most 30 colours per sprite,
alpha 0 or 255 only, transparent background where the piece needs one; no red. Byte-identical on every run.

  python game/tools/build_level_up_art.py build                 # writes the PNGs and records, then checks them
  python game/tools/build_level_up_art.py check                 # checks the written PNGs (exit 1 on a fail)
  python game/tools/build_level_up_art.py piece <name> <png>    # writes one piece to <png> (the style loop's step)
  python game/tools/build_level_up_art.py archive               # copies the pieces in game/art/level_up/ to
                                                                # art-archive/T-303/red_gold/ (never overwrites)
"""
from __future__ import annotations

import json
import math
import shutil
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_rules as rules  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
REPO = GAME.parent
OUT = GAME / "art" / "level_up"
RAW_BOX = REPO / "art-archive" / "T-140" / "gift_pack_raw.png"
EMBLEM_32 = GAME / "art" / "logo" / "greenbull_emblem_32.png"
OLD_ARCHIVE = REPO / "art-archive" / "T-303" / "red_gold"
MAX_COLORS = 30

# The outline is the emblem's own near-black green, so the logo sits in the art without a seam.
OUTLINE = (14, 22, 18)
DG_D = (6, 46, 26)          # the emblem's dark shade
DG = rules.GREENBULL_DARK_GREEN          # (12, 76, 44), the main colour
DG_L = (24, 110, 58)
MG = (52, 160, 72)
LG = rules.GREENBULL_LIGHT_GREEN         # (104, 220, 96)
LG_L = (170, 240, 140)
LG_P = (226, 252, 200)
YEL = rules.GREENBULL_YELLOW             # (247, 208, 52), the small accent
YEL_L = (255, 238, 150)
CREAM = (246, 250, 232)
CREAM_D = (214, 226, 196)

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
    ring = [OUTLINE, DG_L, DG, DG, DG_D, OUTLINE, LG_L, LG, OUTLINE, CREAM_D]
    rings(im, ring, [5, 3, 2, 1, 1])
    k = len(ring)
    for y in range(k, h - k):
        hline(im, k, w - 1 - k, y, CREAM)
    hline(im, k, w - 1 - k, k, CREAM_D)  # a soft shadow under the top border
    for cx, cy in ((12, 12), (w - 13, 12), (12, h - 13), (w - 13, h - 13)):  # small yellow studs
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                put(im, cx + dx, cy + dy, YEL_L if dx + dy < 0 else YEL)
    return im


def highlight_frame():
    im = new(192, 162)
    rings(im, [MG, OUTLINE, LG_P, LG, YEL, OUTLINE], [9, 6, 4, 3, 2, 1, 1], hollow=True)
    return im


def disc(im, cx, cy, r, fill, edge, shade):
    for y in range(cy - r - 1, cy + r + 2):
        for x in range(cx - r - 1, cx + r + 2):
            d = math.hypot(x - cx, y - cy)
            if d <= r + 1:
                c = edge if d > r else (shade if (x - cx) + (y - cy) > r * 0.9 else fill)
                put(im, x, y, c)


def stamp_emblem(im, cx, cy):
    logo = Image.open(EMBLEM_32).convert("RGBA")
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
                put(im, x, y, OUTLINE if edge else (DG if y < 26 else DG_D))
    # The body, row by row from the top and from the bottom: dark green trim (one yellow line on top),
    # then the light green field the game letters the black title on.
    upper = [OUTLINE, YEL, DG_L, DG, DG, OUTLINE, LG_P, LG_L] + [LG] * 14
    lower = [OUTLINE, DG_D, DG, DG, DG, OUTLINE, MG, MG] + [LG] * 14
    for i in range(len(upper)):
        hline(im, 14, w - 15, 2 + i, upper[i])
        hline(im, 14, w - 15, 41 - i, lower[i])
    for y in range(2, 42):  # end caps
        put(im, 14, y, OUTLINE)
        put(im, w - 15, y, OUTLINE)
    for cx in (46, w - 47):  # a Greenbull medallion at each end
        disc(im, cx, 22, 15, CREAM, OUTLINE, CREAM_D)
        disc_ring(im, cx, 22, 13, DG)
        stamp_emblem(im, cx, 22)
    return im


def disc_ring(im, cx, cy, r, c):
    """A one-pixel ring of radius r inside a medallion."""
    for y in range(cy - r - 1, cy + r + 2):
        for x in range(cx - r - 1, cx + r + 2):
            if r - 0.5 < math.hypot(x - cx, y - cy) <= r + 0.5:
                put(im, x, y, c)


def button(pressed):
    w, h = 72, 22
    im = new(w, h)
    ring = [OUTLINE, DG_D, DG_D] if pressed else [OUTLINE, DG_L, DG]
    rings(im, ring, [2, 1])
    k = len(ring)
    for y in range(k, h - k):
        if pressed:
            c = MG
        elif y == k:
            c = LG_P
        elif y >= h - k - 2:
            c = MG
        else:
            c = LG
        hline(im, k, w - 1 - k, y, c)
    return im


def sunburst():
    n = 256
    im = new(n, n)
    c = (n - 1) / 2
    cols = [DG_D, DG, DG_D, DG_L]
    for y in range(n):
        for x in range(n):
            d = math.hypot(x - c, y - c)
            if d <= n / 2 - 0.5:
                a = (math.atan2(y - c, x - c) + math.tau) % math.tau
                col = OUTLINE if d > n / 2 - 4 else cols[int(a / math.tau * 24) % 4]
                put(im, x, y, col)
    return im


# The T-140 box's 16 colours, recoloured. Red box -> dark greens; gold ribbon -> light greens;
# the black outline -> Greenbull's near-black green. Small gold specks on the box (the sparkles) go yellow.
BOX_MAP = {
    (230, 1, 2): (24, 112, 60), (221, 1, 1): (20, 100, 54), (145, 1, 2): DG, (136, 0, 2): (10, 68, 40),
    (124, 0, 1): (8, 58, 34), (70, 1, 0): DG_D, (255, 139, 99): (80, 180, 100),
    (10, 3, 1): (8, 16, 12), (21, 3, 1): OUTLINE,
    (188, 120, 3): (40, 138, 60), (231, 150, 6): (62, 172, 72), (243, 166, 3): (80, 196, 82),
    (254, 192, 6): LG, (251, 210, 11): (150, 234, 120), (250, 249, 120): (206, 248, 170),
    (253, 252, 211): (240, 255, 226),
}
GOLDS = {(188, 120, 3), (231, 150, 6), (243, 166, 3), (254, 192, 6), (251, 210, 11), (250, 249, 120),
         (253, 252, 211)}
SPARKLE_MAX = 16  # a gold patch this small or smaller is a sparkle on the box, not ribbon
SPARKLE_MAP = {(253, 252, 211): (255, 250, 214), (250, 249, 120): YEL_L, (188, 120, 3): (204, 172, 40)}


def gold_patches(im):
    """8-connected patches of the box's gold colours, as lists of (x, y)."""
    w, h = im.size
    px = im.load()
    seen, out = set(), []
    for y in range(h):
        for x in range(w):
            if (x, y) in seen or px[x, y][3] == 0 or px[x, y][:3] not in GOLDS:
                continue
            stack, patch = [(x, y)], []
            seen.add((x, y))
            while stack:
                p = stack.pop()
                patch.append(p)
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        q = (p[0] + dx, p[1] + dy)
                        if (0 <= q[0] < w and 0 <= q[1] < h and q not in seen and px[q][3] == 255
                                and px[q][:3] in GOLDS):
                            seen.add(q)
                            stack.append(q)
            out.append(patch)
    return out


def recolour_box(raw):
    im = raw.copy()
    px, src = im.load(), raw.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = src[x, y]
            if a == 255:
                px[x, y] = BOX_MAP.get((r, g, b), (r, g, b)) + (255,)
    for patch in gold_patches(raw):
        if len(patch) <= SPARKLE_MAX:
            for p in patch:
                px[p] = SPARKLE_MAP.get(src[p][:3], YEL) + (255,)
    return im


def gift_pack_emblem():
    im = recolour_box(Image.open(RAW_BOX).convert("RGBA"))
    disc(im, 63, 91, 13, CREAM, OUTLINE, CREAM_D)
    stamp_emblem(im, 63, 91)
    return im


BUILDERS = {
    "card_frame": (card_frame, "The card: a 9-slice frame (margin 10 art pixels): a dark green outer band and a light green inner band, a pale fill and four small yellow studs. Shown 2x.", "none (the ribbon and the gift box carry the emblem)"),
    "highlight_frame": (highlight_frame, "The highlighted card's frame, hollow: pale and light green with one yellow line, a mid-green glow ring and dark lines. The card sits 6 art pixels inside it (shown 2x).", "none"),
    "header_ribbon": (header_ribbon, "The banner: light green ribbon (the game letters the black title between x 76 and 304) with dark green trim, one yellow line on top, dark green folded tails, and a pale medallion with Greenbull's emblem at each end. Shown 2x (760 wide).", "Greenbull emblem (32 px) on both medallions"),
    "button_plate": (lambda: button(False), "The 'Take it' plate: light green with a dark green edge; the game letters the text. Shown 2x.", "none"),
    "button_plate_pressed": (lambda: button(True), "The 'Take it' plate pressed: mid green, flat, darkest green edge. Shown 2x.", "none"),
    "sunburst": (sunburst, "Backdrop: 24 rays in Greenbull's dark greens inside a circle with a dark rim. Sits behind the cards over the dimmed run; T-141 spins and scales it.", "none"),
    "gift_pack_emblem": (gift_pack_emblem, "Gift pack emblem: T-140's PixelLab gift box (art-archive/T-140/gift_pack_raw.png, unchanged) recoloured by script to a dark green box, light green ribbon and yellow sparkles, with Greenbull's emblem on a pale disc on its front. Shown beside the ribbon.", "Greenbull emblem (32 px) on the box front"),
}


def made_by(name):
    if name == "gift_pack_emblem":
        return ("game/tools/build_level_up_art.py: art-archive/T-140/gift_pack_raw.png (PixelLab, 1 generation, "
                "T-140 sample) recoloured by script, plus the emblem by script (0 new generations)")
    return "game/tools/build_level_up_art.py (script, 0 PixelLab generations)"


def record(name, im):
    what, logo = BUILDERS[name][1], BUILDERS[name][2]
    return {"task": "T-303", "earlier": "T-140 (red and gold, kept in art-archive/T-303/red_gold/)",
            "what": what, "logo": logo, "made_by": made_by(name), "size": list(im.size),
            "emblem": "game/art/logo/greenbull_emblem_32.png" if "emblem" in logo.lower() else None,
            "prompt": None}


def check_png(path):
    with open(path, "rb") as f:
        w, h, rows = rules.decode_png(f.read())
    px = [p for r in rows for p in r]
    semi = sum(1 for p in px if 0 < p[3] < 255)
    colors = {p[:3] for p in px if p[3] == 255}
    reds = sorted(c for c in colors if rules.is_redgull_red(c))
    results = [("no semi-transparent pixels", semi == 0, "%d" % semi),
               ("%d colours or fewer" % MAX_COLORS, len(colors) <= MAX_COLORS, "%d colours" % len(colors)),
               ("has opaque pixels", any(p[3] == 255 for p in px), ""),
               ("transparent corners", all(r[3] == 0 for r in (rows[0][0], rows[0][-1], rows[-1][0], rows[-1][-1])), ""),
               ("no Redgull red", not reds, "%s" % [list(c) for c in reds[:5]])]
    return results, (w, h)


def write_piece(name, path):
    im = BUILDERS[name][0]()
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)
    return im


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    for name in BUILDERS:
        im = write_piece(name, OUT / (name + ".png"))
        (OUT / (name + ".json")).write_text(json.dumps(record(name, im), indent=1) + "\n", encoding="utf-8")


def archive_old(src=None, dst=None):
    """Copies each piece's PNG and JSON to the archive, never overwriting one already there."""
    src, dst = Path(src or OUT), Path(dst or OLD_ARCHIVE)
    dst.mkdir(parents=True, exist_ok=True)
    copied = []
    for name in FILES:
        for ext in (".png", ".json"):
            if (src / (name + ext)).exists() and not (dst / (name + ext)).exists():
                shutil.copyfile(src / (name + ext), dst / (name + ext))
                copied.append(name + ext)
    return copied


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
    if cmd == "piece":
        write_piece(sys.argv[2], sys.argv[3])
        res, size = check_png(sys.argv[3])
        print("%s %s: %s" % (sys.argv[2], size, "; ".join("%s %s" % (a, "ok" if k else "FAIL") for a, k, _ in res)))
        sys.exit(0 if all(r[1] for r in res) else 1)
    if cmd == "archive":
        print("archived: %s" % (archive_old() or "nothing new"))
        sys.exit(0)
    if cmd == "build":
        build()
    sys.exit(check())
