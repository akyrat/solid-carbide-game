#!/usr/bin/env python3
"""Draws the drift marks' tyre texture (task T-118; no PixelLab call).

The board decided (Visual style, Decisions, "Drift marks", 2026-10-13) that the
drift mark texture is drawn by a script, within the pixel style: dark rubber
tyre marks with a visible tread pattern, readable on the MVP map's dark asphalt
and its dusty gravel, hard pixel edges, no semi-transparent pixels, a
transparent background, about 30 colours or fewer, the night palette and no
Redgull red.

Output: one small tile, LENGTH texels along the mark by WIDTH texels across it.
The drift marks scene (scenes/driving/drift_marks.tscn) draws it along each
Line2D in tile mode: the texture's x runs along the mark, its y across it. The
tile is one period of the tread, so it repeats along the mark without a seam.
The rows inside the mark are fully opaque (the mark never breaks up); only the
two edge rows (the tyre's ragged shoulders) have transparent pixels, which is
the texture's transparent background.

Commands (run from the repo root):
  python game/tools/build_drift_mark.py build   # writes the PNG, its record and the archive previews
  python game/tools/build_drift_mark.py check   # checks the committed PNG (exit 1 on a fail)
  python game/tools/build_drift_mark.py check --png OTHER.png

Running build twice gives byte-identical files.
"""
from __future__ import annotations

import argparse
import colorsys
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_sprite_rules as rules  # noqa: E402
from remove_car_shadow import write_png  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
REPO = GAME.parent
OUT_PNG = GAME / "art" / "effects" / "drift_mark.png"
OUT_JSON = GAME / "art" / "effects" / "drift_mark.json"
ARCHIVE = REPO / "art-archive" / "T-118"

MAX_COLORS = 30

# Redgull red, as the HUD heart draws it (scripts/hud/hud.gd, HEART_COLOR = Color(0.86, 0.1, 0.16)).
REDGULL_RED = (219, 26, 41)

# The MVP map's ground (game/art/ground/ground_atlas.png, the most common pixel
# of an asphalt and a gravel tile), for the previews and the readability check.
ASPHALT = (48, 46, 62)
GRAVEL = (99, 86, 107)

# The palette: dark rubber with a night (navy and violet) tint, darker than
# both grounds, so the mark reads as rubber laid on the ground.
PALETTE = {
    "K": (12, 10, 20),   # deep rubber: the tread blocks
    "G": (46, 43, 64),   # groove: scuffed rubber between the blocks, just darker than the asphalt
    "E": (27, 24, 40),   # shoulder: the tyre's ragged outer edge
}

# One period of the tread, WIDTH rows across the mark by LENGTH columns along
# it ('.' is transparent). A chevron of 2-texel grooves (pointing back along the mark)
# between two ragged shoulder rows. Row 0 and the last row are the shoulders.
TREAD = [
    ".EE..EE.",
    "KKKKGGKK",
    "KKKGGKKK",
    "KKGGKKKK",
    "KKGGKKKK",
    "KKKGGKKK",
    "KKKKGGKK",
    ".EE..EE.",
]

# The alternative looked at (not used in the game; written to art-archive/T-118/):
# the same chevron with transparent grooves, so the ground shows through the tread.
ALTERNATIVES = {
    "drift_mark_alt_open_grooves": [r.replace("G", ".") for r in TREAD],
}

WIDTH = len(TREAD)        # texels across the mark
LENGTH = len(TREAD[0])    # texels along the mark (one tread period)

T = (0, 0, 0, 0)


def draw(grid=TREAD):
    """The tile as rows of RGBA."""
    if any(len(r) != len(grid[0]) for r in grid):
        raise ValueError("ragged tread")
    return [[T if ch == "." else PALETTE[ch] + (255,) for ch in line] for line in grid]


def is_redgull_red(rgb, max_dist=128, hue_deg=25):
    """True for Redgull red or anything that reads as a red: within half the colour range of it
    (0.5 in 0..1 units, as the GUT tests), or a saturated red hue."""
    dist = sum((a - b) ** 2 for a, b in zip(rgb, REDGULL_RED)) ** 0.5
    if dist < max_dist:
        return True
    h, s, v = colorsys.rgb_to_hsv(*(c / 255.0 for c in rgb))
    hue = h * 360.0
    return min(hue, 360.0 - hue) < hue_deg and s > 0.4 and v > 0.25


def luma(rgb):
    r, g, b = rgb
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def check_rows(rows, max_colors=MAX_COLORS):
    """Every rule for the tile: list of (rule, ok, detail)."""
    h, w = len(rows), len(rows[0])
    out = [("tile at least 2 long and 3 across", w >= 2 and h >= 3, "%d along x %d across" % (w, h))]
    results, _ = rules.check_rows(rows, w, max_colors)
    out += [r for r in results if not r[0].startswith("frame size")]
    px = [p for r in rows for p in r]
    colors = {p[:3] for p in px if p[3] == 255}
    reds = sorted(c for c in colors if is_redgull_red(c))
    out.append(("no Redgull red (nor any red)", not reds, "reds: %s" % reds if reds else "none"))
    # Tiles cleanly along the mark: every row inside the mark is opaque the whole
    # length, so the tile join never opens a gap; the shoulders' gaps stay short
    # across the join too.
    gaps = [y for y in range(1, h - 1) if any(p[3] == 0 for p in rows[y])]
    out.append(("rows inside the mark fully opaque (no gap at the tile join)", not gaps, "gaps in rows %s" % gaps if gaps else "none"))
    longest = max(_longest_wrapped_gap(rows[0]), _longest_wrapped_gap(rows[-1]))
    out.append(("shoulder gaps at most 2 texels, also across the join", longest <= 2, "longest %d" % longest))
    # Dark rubber: every colour darker than both grounds.
    darkest_ground = min(luma(ASPHALT), luma(GRAVEL))
    light = sorted(c for c in colors if luma(c) >= darkest_ground)
    out.append(("every colour darker than the asphalt and the gravel", not light, "too light: %s" % light if light else "none"))
    return out


def _longest_wrapped_gap(row):
    """Longest run of transparent texels in a row, counting the run that wraps from the end to the start."""
    doubled = list(row) + list(row)
    best = run = 0
    for p in doubled:
        run = run + 1 if p[3] == 0 else 0
        best = max(best, run)
    return min(best, len(row))


def preview(grid=TREAD, tiles=6, scale=8):
    """A strip of the tile repeated along the mark, over asphalt and over gravel, enlarged (nearest)."""
    tile = draw(grid)
    h = len(tile)
    strip = [sum((list(r) for _ in range(tiles)), []) for r in tile]
    w = len(strip[0])
    pad = 2
    out = []
    for ground in (ASPHALT, GRAVEL):
        g = ground + (255,)
        block = [[g] * (w + 2 * pad) for _ in range(h + 2 * pad)]
        for y, r in enumerate(strip):
            for x, p in enumerate(r):
                if p[3]:
                    block[pad + y][pad + x] = p
        out.extend(block)
    big = []
    for r in out:
        wide = [p for p in r for _ in range(scale)]
        big.extend([wide] * scale)
    return big


def record():
    return {
        "file": OUT_PNG.name,
        "task": "T-118",
        "what": "The drift marks' tyre texture: one tile, %d texels along the mark by %d across, one period of a chevron tread between two ragged shoulders. Drawn along each drift mark (Line2D, tile mode), repeated along its length." % (LENGTH, WIDTH),
        "tread": TREAD,
        "palette": {k: list(v) for k, v in PALETTE.items()},
        "colors": len(PALETTE),
        "made_by": "game/tools/build_drift_mark.py (a script; no PixelLab call, board 2026-10-13). Byte-identical every run.",
        "rules": "Visual style, Decisions: night palette, no anti-aliasing, no semi-transparent pixels, transparent background (the shoulder rows' gaps), about 30 colours or fewer, no Redgull red; every colour darker than the asphalt and the gravel; rows inside the mark opaque so it tiles without a gap. Check: python game/tools/build_drift_mark.py check",
        "scale": "width_units 0.25 in the scene: the %d texels across are 4 flat world pixels, 32 texels per unit, the car and ground art's density; one tile is 0.25 units long" % WIDTH,
        "grounds": {"asphalt": list(ASPHALT), "gravel": list(GRAVEL)},
        "used_by": "game/scenes/driving/drift_marks.tscn (mark_texture)",
        "archive": "art-archive/T-118/: previews over asphalt and gravel, and the alternative with transparent grooves (not used)",
        "status": "proposal for the board's review (T-118)",
    }


def build(png=OUT_PNG, js=OUT_JSON, archive=ARCHIVE):
    png.parent.mkdir(parents=True, exist_ok=True)
    write_png(png, draw())
    js.write_text(json.dumps(record(), indent=1) + "\n", encoding="utf-8", newline="\n")
    if archive is not None:
        archive.mkdir(parents=True, exist_ok=True)
        write_png(archive / "drift_mark_preview.png", preview())
        for name, grid in ALTERNATIVES.items():
            write_png(archive / (name + ".png"), draw(grid))
            write_png(archive / (name + "_preview.png"), preview(grid))
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
        print("wrote", png, "and", js, "and the previews in", ARCHIVE)
        a.png = str(png)
    results = check_file(a.png)
    for rule, ok, detail in results:
        print("%s  %s: %s" % ("PASS" if ok else "FAIL", rule, detail))
    ok = all(r[1] for r in results)
    print("ALL RULES PASS" if ok else "SOME RULES FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
