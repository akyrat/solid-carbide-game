#!/usr/bin/env python3
"""Draws the drift smoke's puff sprite (task T-073; no PixelLab call).

The board decided (Visual style, Decisions, "Drift smoke", 2026-10-13) that the
smoke sprites are drawn by a script, within the pixel style: cool grey-violet
smoke (night palette, a faint cyan tint on the lit side from the city's neon),
softness made by stepped shapes and dithering instead of semi-transparent
pixels, a transparent background, about 30 colours or fewer, no Redgull red,
readable on the MVP map's dark asphalt and its dusty gravel.

Output: SIZE x SIZE texels, one lumpy puff (a union of circles), lit from the
top left: light core, mid, dark, then a deeper violet rim. Bands blend with a
checkerboard dither, and the outermost ring is chequered away so the outline is
ragged and soft. The drift smoke scene (scenes/driving/drift_smoke.tscn) draws
it at different sizes over the puff's life (the size curve), so one sprite is
the whole animation: it grows, then shrinks and pops out.

Commands (run from the repo root):
  python game/tools/build_drift_smoke.py build   # writes the PNG, its record and the archive preview
  python game/tools/build_drift_smoke.py check   # checks the committed PNG (exit 1 on a fail)
  python game/tools/build_drift_smoke.py check --png OTHER.png

Running build twice gives byte-identical files.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_drift_mark as marks  # noqa: E402  (the luma check, ground colours)
import style_rules as rules  # noqa: E402  (the sprite checks and Redgull red, Visual style rules 1 and 6)
from remove_car_shadow import write_png  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
REPO = GAME.parent
OUT_PNG = GAME / "art" / "effects" / "drift_smoke_puff.png"
OUT_JSON = GAME / "art" / "effects" / "drift_smoke_puff.json"
ARCHIVE = REPO / "art-archive" / "T-073"

SIZE = 24
MAX_COLORS = 30
ASPHALT = marks.ASPHALT
GRAVEL = marks.GRAVEL

# Palette, lightest to darkest: cool grey-violet, a faint cyan on the lit side.
PALETTE = {
    "H": (224, 232, 250),  # neon-tinted highlight (a few pixels, top left)
    "L": (198, 192, 226),  # light
    "M": (166, 158, 198),  # mid
    "D": (136, 128, 172),  # dark
    "R": (74, 68, 110),    # rim: the deep violet outline
}

# Circles (cx, cy, r) of the puff, in texels.
BLOBS = [(12.0, 12.0, 8.8), (7.2, 8.6, 4.6), (16.8, 8.2, 4.8), (7.0, 15.8, 4.4), (17.2, 16.0, 4.6), (12.0, 18.2, 4.8), (11.5, 5.6, 4.4)]

T = (0, 0, 0, 0)

# 2 x 2 ordered dither thresholds.
BAYER = [[0.0, 0.5], [0.75, 0.25]]


def inside_mask(size=SIZE, blobs=BLOBS):
    return [[any((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r for cx, cy, r in blobs)
             for x in range(size)] for y in range(size)]


def edge_distance(mask):
    """For each inside texel, the distance in texels to the nearest outside texel (about 1 on the edge)."""
    size = len(mask)
    outside = [(x, y) for y in range(size) for x in range(size) if not mask[y][x]]
    # texels past the sprite's border count as outside too
    outside += [(x, y) for x in (-1, size) for y in range(-1, size + 1)]
    outside += [(x, y) for y in (-1, size) for x in range(-1, size + 1)]
    dist = [[0.0] * size for _ in range(size)]
    for y in range(size):
        for x in range(size):
            if mask[y][x]:
                dist[y][x] = min(((x - ox) ** 2 + (y - oy) ** 2) ** 0.5 for ox, oy in outside)
    return dist


def build_rows(size=SIZE, blobs=BLOBS):
    """The sprite as rows of palette letters ('.' transparent)."""
    mask = inside_mask(size, blobs)
    dist = edge_distance(mask)
    out = []
    for y in range(size):
        line = ""
        for x in range(size):
            if not mask[y][x]:
                line += "."
                continue
            d = dist[y][x]
            if d < 1.5 and (x + y) % 2 == 0:
                line += "."  # chequered outer ring: a ragged, soft outline
                continue
            if d < 2.5:
                line += "R"
                continue
            # tone: deep inside = light, lit from the top left = light
            lx, ly = (size - 1 - x) / size, (size - 1 - y) / size
            v = 0.5 * min(d - 2.5, 5.0) / 5.0 + 0.5 * (lx + ly) / 2.0
            v += (BAYER[y % 2][x % 2] - 0.375) * 0.12  # dither across the band edges
            if v > 0.70:
                line += "H"
            elif v > 0.50:
                line += "L"
            elif v > 0.32:
                line += "M"
            else:
                line += "D"
        out.append(line)
    return out


GRID = build_rows()


def draw(grid=GRID):
    return [[T if ch == "." else PALETTE[ch] + (255,) for ch in line] for line in grid]


def check_rows(rows, max_colors=MAX_COLORS):
    """Every rule for the sprite: list of (rule, ok, detail)."""
    h, w = len(rows), len(rows[0])
    results, _ = rules.check_rows(rows, w, max_colors)
    out = [r for r in results if not r[0].startswith("frame size")]
    px = [p for r in rows for p in r]
    colors = {p[:3] for p in px if p[3] == 255}
    reds = sorted(c for c in colors if rules.is_redgull_red(c))
    out.append(("no Redgull red (nor any red)", not reds, "reds: %s" % reds if reds else "none"))
    cool = sorted(c for c in colors if c[2] < c[0] or c[2] < c[1])
    out.append(("cool: blue is the strongest channel of every colour", not cool, "not cool: %s" % cool if cool else "none"))
    opaque = sum(1 for p in px if p[3] == 255)
    out.append(("a real puff: between 35% and 80% of the texels are smoke", 0.35 * w * h <= opaque <= 0.8 * w * h, "%d of %d" % (opaque, w * h)))
    # Reads on both grounds: the body (every colour lighter than the rim) is lighter
    # than both by a clear gap (40 of 255 luma).
    rim = min(marks.luma(c) for c in colors) if colors else 0
    body = [c for c in colors if marks.luma(c) > rim + 1]
    gap = {}
    for name, g in (("asphalt", ASPHALT), ("gravel", GRAVEL)):
        gap[name] = min((marks.luma(c) - marks.luma(g) for c in body), default=-999)
    out.append(("body colours at least 40 luma lighter than the asphalt and the gravel",
                all(v >= 40 for v in gap.values()), ", ".join("%s +%.0f" % (k, v) for k, v in gap.items())))
    return out


def preview(sizes=(0.6, 1.0, 1.5, 2.0), scale=6):
    """The sprite over asphalt and over gravel at the sizes it passes through (nearest), enlarged."""
    tile = draw()
    rows_out = []
    cell_size = SIZE * 2 + 4
    for ground in (ASPHALT, GRAVEL):
        g = ground + (255,)
        cells = []
        for s in sizes:
            n = max(1, round(SIZE * s))
            cell = [[g] * cell_size for _ in range(cell_size)]
            off = (cell_size - n) // 2
            for y in range(n):
                for x in range(n):
                    p = tile[min(SIZE - 1, int(y / s))][min(SIZE - 1, int(x / s))]
                    if p[3]:
                        cell[off + y][off + x] = p
            cells.append(cell)
        for y in range(cell_size):
            rows_out.append(sum((c[y] for c in cells), []))
    big = []
    for r in rows_out:
        wide = [p for p in r for _ in range(scale)]
        big.extend([wide] * scale)
    return big


def record():
    return {
        "file": OUT_PNG.name,
        "task": "T-073",
        "what": "The drift smoke's puff: one %d x %d sprite, a lumpy cloud lit from the top left (neon-tinted highlight, light, mid, dark, deep violet rim), bands blended by a checkerboard dither, outer ring chequered away for a ragged soft edge. The smoke scene scales it over the puff's life, so it grows, then shrinks and pops out." % (SIZE, SIZE),
        "grid": GRID,
        "palette": {k: list(v) for k, v in PALETTE.items()},
        "colors": len(PALETTE),
        "made_by": "game/tools/build_drift_smoke.py (a script; no PixelLab call, board 2026-10-13). Byte-identical every run.",
        "rules": "Visual style, Decisions: night palette, no anti-aliasing, no semi-transparent pixels, transparent background, about 30 colours or fewer, no Redgull red; body lighter than both grounds. Check: python game/tools/build_drift_smoke.py check",
        "grounds": {"asphalt": list(ASPHALT), "gravel": list(GRAVEL)},
        "used_by": "game/scenes/driving/drift_smoke.tscn (puff_texture)",
        "archive": "art-archive/T-073/: the preview over asphalt and gravel at four sizes",
        "status": "proposal for the board's review (T-073, with T-121)",
    }


def build(png=OUT_PNG, js=OUT_JSON, archive=ARCHIVE):
    png.parent.mkdir(parents=True, exist_ok=True)
    write_png(png, draw())
    js.write_text(json.dumps(record(), indent=1) + "\n", encoding="utf-8", newline="\n")
    if archive is not None:
        archive.mkdir(parents=True, exist_ok=True)
        write_png(archive / "drift_smoke_preview.png", preview())
    return png, js


def check_file(path):
    _, _, rows = rules.decode_png(Path(path).read_bytes())
    return check_rows(rows)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("command", choices=["build", "check"])
    ap.add_argument("--png", default=str(OUT_PNG))
    a = ap.parse_args(argv)
    if a.command == "build":
        png, js = build()
        print("wrote", png, "and", js, "and the preview in", ARCHIVE)
        a.png = str(png)
    results = check_file(a.png)
    for rule, ok, detail in results:
        print("%s  %s: %s" % ("PASS" if ok else "FAIL", rule, detail))
    ok = all(r[1] for r in results)
    print("ALL RULES PASS" if ok else "SOME RULES FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
