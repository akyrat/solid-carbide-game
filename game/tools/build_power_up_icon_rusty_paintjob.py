#!/usr/bin/env python3
"""Rusty Paintjob power-up icon (T-503): inspect versions and apply free script fixes.

Version 1 is a PixelLab pixflux call (art-archive/T-503/pixellab/rusty_paintjob_v1_raw.png).
Later versions are script fixes on top of it, so no paid call is spent.

Usage, from the repo root:

    python game/tools/build_power_up_icon_rusty_paintjob.py dump <png>
    python game/tools/build_power_up_icon_rusty_paintjob.py preview <png> <out dir>
    python game/tools/build_power_up_icon_rusty_paintjob.py fix <src png> <out png> --version 2

`fix` never overwrites an existing file.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

GREENBULL = {(104, 220, 96), (247, 208, 52)}
CHARS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"


def stats(im: Image.Image) -> dict:
    px = [p for p in im.getdata() if p[3] > 0]
    cols = {p[:3] for p in px}
    return {
        "size": im.size,
        "colours": len(cols),
        "bbox": im.getbbox(),
        "semi": sum(1 for p in px if p[3] < 255),
        "greenbull": sorted(c for c in cols if c in GREENBULL),
    }


def dump(im: Image.Image) -> str:
    pal: list[tuple] = []
    rows = []
    for y in range(im.height):
        row = ""
        for x in range(im.width):
            p = im.getpixel((x, y))
            if p[3] == 0:
                row += "."
                continue
            if p[:3] not in pal:
                pal.append(p[:3])
            row += CHARS[pal.index(p[:3])]
        rows.append(f"{y:2d} {row}")
    legend = [f"{CHARS[i]} = {c}" for i, c in enumerate(pal)]
    return "\n".join(rows + legend)


def preview(im: Image.Image, out_dir: Path, stem: str) -> list[Path]:
    out = []
    for bg, n in (((18, 16, 28), "dark"), ((235, 235, 235), "light")):
        b = Image.new("RGBA", im.size, bg + (255,))
        b.alpha_composite(im)
        p = out_dir / f"{stem}_prev_{n}.png"
        b.resize((256, 256), Image.NEAREST).save(p)
        out.append(p)
    return out


# ------------------------------------------------------- version 2 ----
# Version 2 keeps v1's silhouette (the can's outline shape) and repaints everything inside it.
# Style Evaluator on v1 (6/10, rules 2, 4, 5): rust was one orange block, weak top-left light,
# no visible puff or neon glints. Colours follow the matched set: outline, rust and neon glints
# are taken from rusty_overcoat.png (T-465); the metal is a cooler blue-grey.
OUTLINE = (33, 29, 50)
RIM = (232, 238, 248)
M_HI = (200, 208, 226)
M_LIGHT = (156, 166, 194)
M_MID = (114, 122, 152)
M_DARK = (80, 86, 118)
M_DEEP = (50, 52, 80)
R_LIGHT = (244, 162, 104)
R_MID = (197, 111, 72)
R_BASE = (177, 91, 57)
R_DARK = (145, 68, 40)
R_PIT = (122, 56, 30)
CYAN = (142, 246, 254)
CYAN_HALO = (96, 178, 204)
MAGENTA = (228, 90, 232)
MAGENTA_HALO = (128, 66, 138)
MIST = (206, 228, 242)
MIST_DIM = (124, 150, 178)

V1_ROWS_DROPPED = (19, 20)   # two repeated body rows, so the can is 30 px tall and sits at y 1..30

# Final coordinates (after the rows are dropped and the can moved down by 1).
NOZZLE_ROWS = range(1, 5)
CONE_ROWS = range(5, 12)
SEAM_ROW = 12
TOP_RIM_ROW = 13
BODY_ROWS = range(14, 27)
BOTTOM_RIM_ROW = 27
BASE_ROWS = range(28, 30)

RUST = {   # irregular patches: (x, y)
    "a": [(18, 19), (19, 19), (17, 20), (18, 20), (19, 20), (20, 20), (16, 21), (17, 21), (18, 21),
          (19, 21), (20, 21), (17, 22), (18, 22), (19, 22), (18, 23), (19, 23), (19, 24)],
    "b": [(13, 16), (14, 16), (12, 17), (13, 17), (14, 17), (15, 17), (13, 18), (14, 18)],
    "c": [(18, 14), (19, 14), (20, 14), (19, 15), (20, 15)],
    "d": [(13, 24), (12, 25), (13, 25), (14, 25), (13, 26), (14, 26), (15, 26), (16, 26)],
    "e": [(13, 22), (17, 10), (18, 10), (18, 9)],
}
PITS = [(18, 21), (13, 17), (13, 25), (19, 22)]
FLAKES = [(17, 19), (12, 16), (17, 14), (12, 24), (15, 21)]     # bright paint chips curling off the rust
OUTLINE_HIGHLIGHTS = [(10, 15), (10, 16), (10, 22), (12, 6), (11, 8)]   # lighter pixels breaking the outline
CYAN_GLINTS = [(12, 21)]
CYAN_SPARKS = [(14, 13), (19, 9)]
MAGENTA_GLINTS = [(20, 17)]
NOZZLE_TIP = (16, 2)
PUFF = {MIST: [(20, 1), (20, 2), (21, 2), (21, 3)],
        MIST_DIM: [(19, 2), (21, 1), (22, 2), (22, 3), (20, 3), (21, 4), (23, 1)]}


def silhouette(v1: Image.Image) -> Image.Image:
    """v1 without the dropped rows, moved down by 1 px."""
    out = Image.new("RGBA", v1.size, (0, 0, 0, 0))
    y_out = 1
    for y in range(v1.height):
        if y in V1_ROWS_DROPPED:
            continue
        if y_out < out.height:
            for x in range(v1.width):
                out.putpixel((x, y_out), v1.getpixel((x, y)))
        y_out += 1
    return out


def metal_tone(t: float, lift: int = 0) -> tuple:
    """Cylinder shading across the row, lit from the left; lift brightens by steps (the lit dome)."""
    tones = [M_DEEP, M_DARK, M_MID, M_LIGHT, M_HI]
    if t < 0.08:
        i = 2
    elif t < 0.15:
        i = 3
    elif t < 0.3:
        i = 4
    elif t < 0.48:
        i = 3
    elif t < 0.75:
        i = 2
    elif t < 0.95:
        i = 1
    else:
        i = 0
    return tones[min(4, i + lift)]


def rust_tone(base: tuple) -> tuple:
    return {M_HI: R_LIGHT, M_LIGHT: R_MID, M_MID: R_BASE, M_DARK: R_DARK, M_DEEP: R_PIT}.get(base, R_BASE)


def build_v2(v1: Image.Image) -> Image.Image:
    im = silhouette(v1.convert("RGBA"))
    w, h = im.size
    base_tone: dict[tuple, tuple] = {}
    for y in range(h):
        xs = [x for x in range(w) if im.getpixel((x, y))[3] > 0]
        if not xs:
            continue
        left, right = xs[0], xs[-1]
        for x in xs:
            if x in (left, right) or y in (1, 30):   # outline: row ends, the cap's top and the base
                im.putpixel((x, y), OUTLINE + (255,))
                continue
            t = (x - left - 1) / max(1, right - left - 2)
            if y in NOZZLE_ROWS:
                c = metal_tone(t, lift=1)
            elif y in CONE_ROWS:
                c = metal_tone(t, lift=1 if y < 9 else 0)
            elif y == SEAM_ROW:
                c = M_DEEP if 0.1 < t < 0.9 else M_DARK
            elif y in (TOP_RIM_ROW, BOTTOM_RIM_ROW):
                c = RIM if t < 0.3 else M_HI if t < 0.6 else M_LIGHT if t < 0.85 else M_MID
            elif y in BASE_ROWS:
                c = M_MID if t < 0.25 else M_DARK if t < 0.8 else M_DEEP
            else:
                c = metal_tone(t)
            base_tone[(x, y)] = c
            im.putpixel((x, y), c + (255,))
    for patch in RUST.values():
        for xy in patch:
            if xy in base_tone:
                im.putpixel(xy, rust_tone(base_tone[xy]) + (255,))
    for xy in PITS:
        im.putpixel(xy, R_PIT + (255,))
    for xy in FLAKES:
        im.putpixel(xy, M_HI + (255,))
    for xy in OUTLINE_HIGHLIGHTS:
        im.putpixel(xy, M_MID + (255,))
    for (x, y) in CYAN_GLINTS:
        for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            im.putpixel((x + d[0], y + d[1]), CYAN_HALO + (255,))
        im.putpixel((x, y), CYAN + (255,))
    for xy in CYAN_SPARKS:
        im.putpixel(xy, CYAN + (255,))
    for (x, y) in MAGENTA_GLINTS:
        for d in ((0, 1), (0, -1), (-1, 0)):
            im.putpixel((x + d[0], y + d[1]), MAGENTA_HALO + (255,))
        im.putpixel((x, y), MAGENTA + (255,))
    im.putpixel(NOZZLE_TIP, MAGENTA + (255,))
    for c, pts in PUFF.items():
        for xy in pts:
            if im.getpixel(xy)[3] == 0:
                im.putpixel(xy, c + (255,))
    return im


# ------------------------------------------------------- version 3 ----
# Style Evaluator on v2 (5/10, rules 2, 4, 5): read as a bottle or vial, too narrow, pale and pink,
# rust barely visible, heavy unbroken outline. Version 3 is drawn by hand as pixel rows (no PixelLab call):
# a 16 px wide can body, a distinct dark cap with a nozzle and a spray puff, a bright rim ring under the cap,
# darker blue-grey metal lit from the top-left, rust patches in three tones plus pits, flaking paint chips,
# lighter pixels breaking the top-left outline, and small stepped cyan and magenta glints.
V3_PALETTE = {
    "O": OUTLINE, "W": RIM,
    "H": (176, 190, 214), "L": (126, 140, 172), "M": (88, 100, 136), "D": (60, 68, 102), "E": (40, 42, 68),
    "N": (52, 48, 78), "n": (74, 72, 104), "k": (106, 108, 142),
    "r": R_LIGHT, "R": (186, 96, 58), "K": (140, 66, 38), "P": (100, 46, 26),
    "C": CYAN, "c": CYAN_HALO, "G": MAGENTA, "g": MAGENTA_HALO, "S": MIST, "s": MIST_DIM,
}
_BODY = "MLHHLLMMMDDDEE"   # x 9..22: cylinder shading, lit from the left
V3_TOP = [
    "......................s.........",
    "...................sSSs.........",
    "..............OOO.sSSSs.........",
    ".............OknNOSSSs..........",
    ".............OnNNO.ss...........",
    "...........nOOOOOOOOO...........",
    "..........nkknnnNNNGNO..........",
    "..........OknnnNNNNgNO..........",
    "..........OnnnNNNNNNNO..........",
    "........MHWCWHHHLLLMMDDO........"[:32],
    "........OLMMDDDDDDEEEEEO........",
]
V3_BODY_OVERLAY = [   # rows 11..27, columns x 8..23 ('-' keeps the body shading; the ends are the outline)
    "M---------------",
    "L----------HrR--",
    "M-----------RK--",
    "--Hr---------K--",
    "-HrrR-----------",
    "--rRKR-------g--",
    "---RR-K------G--",
    "---------Hr--g--",
    "---c----HrRR----",
    "--cCc---rRRKR---",
    "---c---HrRKPKR--",
    "--------rRKPKR--",
    "--------RKKR----",
    "---Hr-----K-----",
    "--HrRR----------",
    "--rRKR----------",
    "---RK-----------",
]
V3_BOTTOM = [
    "........OLWWHHHLLLMMDDEO........",
    ".........ODDDDEEEEEEEEO.........",
    "..........OOOOOOOOOOOO..........",
]


def v3_rows() -> list[str]:
    body = []
    for over in V3_BODY_OVERLAY:
        base = "O" + _BODY + "O"
        body.append("." * 8 + "".join(b if o == "-" else o for b, o in zip(base, over)) + "." * 8)
    rows = V3_TOP + body + V3_BOTTOM
    rows += ["." * 32] * (32 - len(rows))
    return rows


def build_v3() -> Image.Image:
    rows = v3_rows()
    assert len(rows) == 32 and all(len(r) == 32 for r in rows), [len(r) for r in rows]
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                im.putpixel((x, y), V3_PALETTE[ch] + (255,))
    return im


# ------------------------------------------------------- version 4 ----
# Style Evaluator on v3 (5/10, rules 2, 4): read as a jar, no clear nozzle or puff, rust like round gems,
# glints too faint, flat shading. Version 4 (no PixelLab call) is a spray-can silhouette: a domed shoulder
# narrowing to a smaller dark cap with a bright collar, a nozzle button and a stepped puff; a 2 px white
# highlight strip down the lit left of the body; ragged rust with drips and white paint flakes;
# brighter cyan and magenta glints with stepped halos.
V4_PALETTE = dict(V3_PALETTE, X=RIM)
_BODY4 = "MHXXHLMMMDDDEE"   # x 9..22, with the vertical highlight strip at x 11..12
V4_TOP = [
    "................................",
    ".....................sSSs.s.....",
    "....................sSSSs.......",
    "...............OOO.SSSs.........",
    "..............OkNNOSs...........",
    "............nOOOOOOO............",
    "...........nkknnNNGNO...........",
    "...........OkknnNNgNO...........",
    "...........OknnnNNNNO...........",
    "...........OWWHHLLMDO...........",
    "..........MHXHLLMMDDEO..........",
    ".........MHXXHLLMMDDEEO.........",
    "........OWCWHHHLLLMMDDEO........"[:32],
    "........OMDDDDDEEEEEEEEO........",
]
V4_BODY_OVERLAY = [   # rows 14..27, columns x 8..23
    "L----------rRK--",
    "M---------XrKPR-",
    "M-----c----rRK--",
    "-----cCc----R---",
    "------c---------",
    "---rRX-------g--",
    "--rRKR------gG--",
    "---RPKrR-----g--",
    "----R----XrR----",
    "--------rRKKR---",
    "-------rRKPKRR--",
    "--------RK-KR---",
    "---------K---K--",
    "---r-----K------",
]
V4_BOTTOM = [
    "........OLWWHHHLLLMMDDEO........",
    ".........ODDDDEEEEEEEEO.........",
    "..........OOOOOOOOOOOO..........",
]


def rows_from(top: list[str], overlay: list[str], bottom: list[str], body: str) -> list[str]:
    rows = list(top)
    for over in overlay:
        base = "O" + body + "O"
        rows.append("." * 8 + "".join(b if o == "-" else o for b, o in zip(base, over)) + "." * 8)
    rows += bottom
    return rows + ["." * 32] * (32 - len(rows))


def image_from(rows: list[str], palette: dict) -> Image.Image:
    assert len(rows) == 32 and all(len(r) == 32 for r in rows), [len(r) for r in rows]
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                im.putpixel((x, y), palette[ch] + (255,))
    return im


def v4_rows() -> list[str]:
    return rows_from(V4_TOP, V4_BODY_OVERLAY, V4_BOTTOM, _BODY4)


def build_v4() -> Image.Image:
    return image_from(v4_rows(), V4_PALETTE)


def main(argv: list[str]) -> int:
    if argv and argv[0] == "v4":
        out = Path(argv[1])
        if out.exists():
            print("refusing to overwrite", out)
            return 1
        v4 = build_v4()
        v4.save(out)
        print("wrote", out, stats(v4))
        return 0
    if argv and argv[0] == "v3":
        out = Path(argv[1])
        if out.exists():
            print("refusing to overwrite", out)
            return 1
        v3 = build_v3()
        v3.save(out)
        print("wrote", out, stats(v3))
        return 0
    if len(argv) < 2:
        print(__doc__)
        return 2
    cmd = argv[0]
    im = Image.open(argv[1]).convert("RGBA")
    if cmd == "dump":
        print(stats(im))
        print(dump(im))
        return 0
    if cmd == "preview":
        for p in preview(im, Path(argv[2]), Path(argv[1]).stem):
            print("wrote", p)
        print(stats(im))
        return 0
    if cmd == "v2":
        out = Path(argv[2])
        if out.exists():
            print("refusing to overwrite", out)
            return 1
        v2 = build_v2(im)
        v2.save(out)
        print("wrote", out, stats(v2))
        return 0
    print("unknown command", cmd)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
