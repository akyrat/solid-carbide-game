"""Free script fix for the Rusty Overcoat power-up icon (T-465, style loop).

Starts from the PixelLab version 1 (art-archive/T-465/style-loop/v1-4.png) and
edits pixels only; no PixelLab call.

    python game/tools/fix_power_up_icon_rusty_overcoat.py --dump           # print v1's pixel map
    python game/tools/fix_power_up_icon_rusty_overcoat.py <out.png>         # write version 2
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
V1 = ROOT / "art-archive" / "T-465" / "style-loop" / "v1-4.png"


def load_v1():
    return Image.open(V1).convert("RGBA")


def dump(im):
    pal = {}
    keys = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    rows = []
    for y in range(im.height):
        line = ""
        for x in range(im.width):
            p = im.getpixel((x, y))
            if p[3] == 0:
                line += "."
                continue
            if p not in pal:
                pal[p] = keys[len(pal)]
            line += pal[p]
        rows.append(f"{y:2d} {line}")
    print("   " + "".join(str(x % 10) for x in range(im.width)))
    print("\n".join(rows))
    for p, k in pal.items():
        print(k, p[:3])


# Colours: v1's own, plus four neon halo steps (cyan and magenta, mid and dark).
OUTLINE = (33, 29, 50)
OUT_HI = (148, 141, 161)      # v1's lighter outline-break grey
STEEL_TIP = (250, 249, 248)   # v1's rivet white, used for spike tips
STEEL_LIT = (185, 179, 197)
STEEL_MID = (127, 122, 141)
STEEL_DARK = (74, 72, 97)
CYAN = (142, 246, 254)        # v1's cyan glint
CYAN_MID = (52, 164, 196)
CYAN_DARK = (26, 74, 98)
MAG = (228, 90, 232)          # v1's magenta glint
MAG_MID = (146, 52, 158)
MAG_DARK = (72, 30, 88)

# 1. Sharp steel spikes along the coat's edge: shoulders, outer pauldron points, hem.
SPIKES = {
    # left shoulder, pointing up and up-left (lit side)
    (8, 1): STEEL_TIP, (8, 2): STEEL_LIT, (9, 2): OUTLINE,
    (5, 3): STEEL_TIP, (6, 4): STEEL_LIT, (6, 3): OUTLINE,
    # right shoulder (shade side)
    (23, 1): STEEL_LIT, (23, 2): STEEL_MID, (22, 2): OUTLINE,
    (26, 3): STEEL_LIT, (25, 4): STEEL_MID, (25, 3): OUTLINE,
    # outer pauldron points, pointing sideways
    # (a dark wedge base above and below so they read as spikes, not stray pixels)
    (2, 11): STEEL_LIT, (1, 11): STEEL_TIP, (2, 10): OUTLINE, (2, 12): OUTLINE,
    (29, 11): STEEL_MID, (30, 11): STEEL_LIT, (29, 10): OUTLINE, (29, 12): OUTLINE,
    # hem points
    (9, 30): STEEL_LIT, (22, 30): STEEL_MID,
}

# 2. A clear raised collar with flared points and a cyan neon trim.
COLLAR = {
    (12, 1): OUTLINE, (12, 2): STEEL_LIT,
    (19, 1): OUTLINE, (19, 2): STEEL_MID,
    (14, 2): CYAN, (15, 2): CYAN, (16, 2): CYAN_MID, (17, 2): CYAN_MID,
    (13, 1): CYAN_DARK, (14, 1): CYAN_MID, (15, 1): CYAN_MID,
    (16, 1): CYAN_DARK, (17, 1): CYAN_DARK, (18, 1): CYAN_DARK,
}

# 3. Neon rivets with stepped halos (bright, mid, dark).
GLOW = {
    # chest rivets turned cyan, on dark steel
    (11, 7): CYAN, (10, 7): CYAN_MID, (12, 7): CYAN_MID, (11, 6): CYAN_DARK, (11, 8): CYAN_DARK,
    (20, 7): CYAN, (19, 7): CYAN_MID, (21, 7): CYAN_MID, (20, 6): CYAN_DARK, (20, 8): CYAN_DARK,
    # v1's cuff glints: add halos
    (4, 19): CYAN_MID, (6, 19): CYAN_MID, (5, 18): CYAN_MID, (4, 18): CYAN_DARK, (5, 20): CYAN_DARK,
    (25, 19): CYAN_MID, (27, 19): CYAN_MID, (26, 18): CYAN_MID, (27, 18): CYAN_DARK, (26, 20): CYAN_DARK,
    # v1's waist glints: add halos
    (12, 19): MAG_MID, (11, 18): MAG_MID, (10, 19): MAG_DARK, (11, 20): MAG_DARK,
    (19, 19): MAG_MID, (20, 18): MAG_MID, (21, 19): MAG_DARK, (20, 20): MAG_DARK,
    # pauldron rivets turned magenta, with a one-step halo
    (7, 6): MAG, (24, 6): MAG, (7, 5): MAG_MID, (24, 5): MAG_MID,
}

# 4. More lighter breaks in the near-black outline on the top-left edges.
OUTLINE_BREAKS = {
    (4, 9): OUT_HI, (4, 15): OUT_HI, (3, 17): OUT_HI, (4, 22): OUT_HI,
    (9, 24): OUT_HI, (8, 26): OUT_HI, (12, 3): OUT_HI,
}

EDITS = [SPIKES, COLLAR, GLOW, OUTLINE_BREAKS]

# ---- Version 3: make it read as an overcoat, not a robot torso ----
# v1's round orange chest emblem under a dark hood read as a robot's head.
# v3 replaces it with an open collar: two steel lapels folding down in a V over
# the dark lining, then a front seam down the coat with neon buttons.
RUST = (157, 78, 46)
RUST_DARK = (145, 68, 40)
RUST_LIT = (246, 169, 109)
STEEL = (116, 113, 134)
STEEL_SHADE = (96, 95, 118)
LINING = (29, 25, 46)

_ROWS = {
    # x:   12          13          14          15          16          17          18          19
    3: [None,      STEEL_LIT,  LINING,     LINING,     LINING,     LINING,     STEEL_MID,  None],
    4: [STEEL_LIT, STEEL_LIT,  STEEL_LIT,  LINING,     LINING,     STEEL_MID,  STEEL_MID,  STEEL_SHADE],
    5: [RUST_LIT,  STEEL_LIT,  STEEL_LIT,  STEEL_LIT,  STEEL_MID,  STEEL_MID,  STEEL_SHADE, RUST],
    6: [RUST,      RUST_LIT,   RUST_LIT,   STEEL_LIT,  OUTLINE,    STEEL_MID,  STEEL,      STEEL],
    7: [RUST,      RUST_LIT,   RUST,       STEEL,      OUTLINE,    STEEL,      RUST,       STEEL],
    8: [STEEL,     RUST,       RUST,       STEEL,      OUTLINE,    RUST,       RUST_DARK,  STEEL],
    9: [STEEL,     STEEL,      STEEL,      STEEL,      OUTLINE,    STEEL,      STEEL,      None],
    10: [STEEL_MID, STEEL,     STEEL,      STEEL,      OUTLINE,    STEEL,      STEEL_SHADE, None],
}
LAPELS = {(12 + i, y): c for y, row in _ROWS.items() for i, c in enumerate(row) if c is not None}

# Front seam: a dark line down the middle (x 16) with a lit plate edge to its left.
SEAM = {}
for _y in range(11, 26):
    SEAM[(16, _y)] = OUTLINE
    SEAM[(15, _y)] = STEEL_MID if _y % 4 else STEEL_LIT

# Neon buttons on the left panel, each with a stepped halo (bright, mid, dark).
BUTTONS = {}
for _y in (10, 15, 20):
    BUTTONS.update({(14, _y): CYAN, (13, _y): CYAN_MID, (15, _y): CYAN_MID,
                    (12, _y): CYAN_DARK, (14, _y + 1): CYAN_DARK})

# More lighter outline breaks on the top-left edges.
OUTLINE_BREAKS_V3 = {(3, 13): OUT_HI, (9, 21): OUT_HI, (4, 8): OUT_HI}

EDITS_V3 = [LAPELS, SEAM, BUTTONS, OUTLINE_BREAKS_V3]

# ---- Version 4: a more jagged, spiky edge and a fuller magenta halo ----
# Sideways spikes down both sleeves (rows 15 and 20), each a steel tip on a dark wedge.
SIDE_SPIKES = {
    (3, 15): STEEL_LIT, (2, 15): STEEL_TIP, (3, 14): OUTLINE, (3, 16): OUTLINE,
    (2, 20): STEEL_LIT, (1, 20): STEEL_TIP, (2, 19): OUTLINE, (2, 21): OUTLINE,
    (28, 15): STEEL_MID, (29, 15): STEEL_LIT, (28, 14): OUTLINE, (28, 16): OUTLINE,
    (29, 20): STEEL_MID, (30, 20): STEEL_LIT, (29, 19): OUTLINE, (29, 21): OUTLINE,
}
# Pauldron rivets: magenta core, mid magenta on three sides, a dark magenta step above.
MAG_HALO = {
    (6, 6): MAG_MID, (8, 6): MAG_MID, (7, 4): MAG_DARK,
    (23, 6): MAG_MID, (25, 6): MAG_MID, (24, 4): MAG_DARK,
}

EDITS_V4 = [SIDE_SPIKES, MAG_HALO]


def _apply(im, layers):
    for layer in layers:
        for (x, y), c in layer.items():
            im.putpixel((x, y), c + (255,))
    return im


def make_v2():
    return _apply(load_v1(), EDITS)


def make_v3():
    return _apply(make_v2(), EDITS_V3)


def make_v4():
    return _apply(make_v3(), EDITS_V4)


def main(argv):
    if argv and argv[0] == "--dump":
        dump(load_v1())
        return 0
    make = make_v4
    if argv and argv[0] in ("--v2", "--v3"):
        make, argv = {"--v2": make_v2, "--v3": make_v3}[argv[0]], argv[1:]
    if len(argv) != 1:
        raise SystemExit(__doc__)
    out = Path(argv[0])
    if out.exists():
        raise SystemExit(f"{out} exists; never overwrite a version")
    im = make()
    im.save(out)
    colours = {p for p in im.getdata() if p[3]}
    print(f"wrote {out}: bbox {im.getbbox()}, {len(colours)} colours")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
