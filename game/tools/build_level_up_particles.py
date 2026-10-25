#!/usr/bin/env python3
"""Draws the level-up effect's particle sprites (task T-074; no PixelLab call).

The board decided (2026-10-13) that the level-up particles are drawn by a
script, within Visual style, Decisions: the night neon palette (pink, cyan and
violet on the dark navy night), glow drawn into the pixels as a bright core with
stepped, darker halo pixels (no engine bloom), hard pixel edges, no
semi-transparent pixels, a transparent background, about 30 colours or fewer,
and no Redgull red.

Output: one row of FRAME x FRAME frames, one particle shape per frame. The
effect scene (scenes/run/level_up_burst.tscn) reads it as a flipbook
(CanvasItemMaterial particles animation, h_frames = number of frames) and gives
every particle one random frame, so the burst mixes the shapes.

Commands (run from the repo root):
  python game/tools/build_level_up_particles.py build   # writes the PNG and its record
  python game/tools/build_level_up_particles.py check   # checks the committed PNG (exit 1 on a fail)
  python game/tools/build_level_up_particles.py check --png OTHER.png

Running build twice gives byte-identical files.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_rules as rules  # noqa: E402
from style_rules import is_redgull_red  # noqa: E402  (Visual style rule 6)
from remove_car_shadow import write_png  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
OUT_PNG = GAME / "art" / "effects" / "level_up_particles.png"
OUT_JSON = GAME / "art" / "effects" / "level_up_particles.json"

FRAME = 11
MAX_COLORS = 30

# The palette: night neon (Visual style, Decisions, "Palette" and "Glow").
# Each neon colour has a light core shade, the neon itself, a mid shade and a
# dark halo shade, so the glow steps down towards the night instead of blurring.
PALETTE = {
    "W": (255, 255, 255),  # white-hot core
    # cyan
    "c": (190, 255, 255),
    "C": (0, 229, 255),
    "b": (0, 150, 214),
    "d": (20, 72, 140),
    # pink
    "p": (255, 200, 240),
    "P": (255, 64, 200),
    "m": (170, 36, 168),
    "n": (96, 20, 104),
    # violet
    "v": (215, 180, 255),
    "V": (160, 90, 255),
    "u": (100, 50, 190),
    "x": (52, 28, 112),
}

# The shapes, drawn on a FRAME x FRAME grid ('.' is transparent). Smaller
# shapes are centred in the frame by the drawing code.
SHAPES = [
    ("cyan four-point star", [
        ".....d.....",
        ".....b.....",
        ".....C.....",
        "....bCb....",
        "...bcWcb...",
        "dbCCWWWCCbd",
        "...bcWcb...",
        "....bCb....",
        ".....C.....",
        ".....b.....",
        ".....d.....",
    ]),
    ("pink four-point star", [
        ".....n.....",
        ".....m.....",
        ".....P.....",
        "....mPm....",
        "...mpWpm...",
        "nmPPWWWPPmn",
        "...mpWpm...",
        "....mPm....",
        ".....P.....",
        ".....m.....",
        ".....n.....",
    ]),
    ("pink diamond", [
        "....n....",
        "...nmn...",
        "..nmPmn..",
        ".nmPpPmn.",
        "nmPpWpPmn",
        ".nmPpPmn.",
        "..nmPmn..",
        "...nmn...",
        "....n....",
    ]),
    ("cyan diamond", [
        "....d....",
        "...dbd...",
        "..dbCbd..",
        ".dbCcCbd.",
        "dbCcWcCbd",
        ".dbCcCbd.",
        "..dbCbd..",
        "...dbd...",
        "....d....",
    ]),
    ("violet pixel cross", [
        "x...x...x",
        ".u..V..u.",
        "....v....",
        "....v....",
        "xVvvWvvVx",
        "....v....",
        "....v....",
        ".u..V..u.",
        "x...x...x",
    ]),
    ("small cyan spark", [
        "..d..",
        ".bCb.",
        "dCWCd",
        ".bCb.",
        "..d..",
    ]),
]

T = (0, 0, 0, 0)


def draw_shape(grid, size=FRAME):
    """One frame (rows of RGBA) with the shape centred in it."""
    h, w = len(grid), len(grid[0])
    if any(len(r) != w for r in grid):
        raise ValueError("ragged shape")
    if h > size or w > size or (size - h) % 2 or (size - w) % 2:
        raise ValueError("shape %dx%d cannot be centred in %d" % (w, h, size))
    oy, ox = (size - h) // 2, (size - w) // 2
    rows = [[T] * size for _ in range(size)]
    for y, line in enumerate(grid):
        for x, ch in enumerate(line):
            if ch != ".":
                rows[oy + y][ox + x] = PALETTE[ch] + (255,)
    return rows


def build_sheet(shapes=SHAPES, size=FRAME):
    """One row of frames: rows of RGBA, len(shapes) * size wide."""
    frames = [draw_shape(g, size) for _, g in shapes]
    return [sum((f[y] for f in frames), []) for y in range(size)]


def check_rows(rows, frames, size=FRAME, max_colors=MAX_COLORS):
    """Every rule for the sheet: list of (rule, ok, detail)."""
    out = []
    for i, fr in enumerate(rules.split_sheet(rows, frames)):
        results, info = rules.check_rows(fr, size, max_colors)
        for rule, ok, detail in results:
            out.append(("frame %d: %s" % (i, rule), ok, detail))
    px = [p for r in rows for p in r]
    colors = {p[:3] for p in px if p[3] == 255}
    out.append(("whole sheet: about %d colours or fewer" % max_colors, len(colors) <= max_colors, "%d colours" % len(colors)))
    semi = sum(1 for p in px if 0 < p[3] < 255)
    out.append(("whole sheet: no semi-transparent pixels", semi == 0, "%d semi-transparent" % semi))
    reds = sorted(c for c in colors if is_redgull_red(c))
    out.append(("no Redgull red (nor any red)", not reds, "reds: %s" % reds if reds else "none"))
    return out


def record():
    return {
        "file": OUT_PNG.name,
        "what": "The level-up effect's particle sprites (task T-074): one row of %d frames, %d x %d pixels each, one particle shape per frame. The effect scene gives each particle one random frame." % (len(SHAPES), FRAME, FRAME),
        "frames": [name for name, _ in SHAPES],
        "frame_size": [FRAME, FRAME],
        "made_by": "game/tools/build_level_up_particles.py (a script; no PixelLab call, board 2026-10-13). Byte-identical every run.",
        "palette": {k: list(v) for k, v in PALETTE.items()},
        "colors": len(PALETTE),
        "rules": "Visual style, Decisions: night neon palette, glow drawn into the pixels (bright core, stepped darker halo), no anti-aliasing, no semi-transparent pixels, transparent background, about 30 colours or fewer, no Redgull red. Check: python game/tools/build_level_up_particles.py check",
        "scale": "drawn at the car art's density (32 art pixels per unit): the scene draws the particles at scale 0.5, as the car (16 world pixels per unit)",
        "used_by": "game/scenes/run/level_up_burst.tscn",
        "status": "proposal for the board's review (T-074)",
    }


def build(png=OUT_PNG, js=OUT_JSON):
    png.parent.mkdir(parents=True, exist_ok=True)
    write_png(png, build_sheet())
    js.write_text(json.dumps(record(), indent=1) + "\n", encoding="utf-8", newline="\n")
    return png, js


def check_file(path, frames=len(SHAPES)):
    _, _, rows = rules.decode_png(Path(path).read_bytes())
    return check_rows(rows, frames)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("command", choices=["build", "check"])
    ap.add_argument("--png", default=str(OUT_PNG))
    a = ap.parse_args(argv)
    if a.command == "build":
        png, js = build()
        print("wrote", png, "and", js)
        a.png = str(png)
    results = check_file(a.png)
    for rule, ok, detail in results:
        print("%s  %s: %s" % ("PASS" if ok else "FAIL", rule, detail))
    ok = all(r[1] for r in results)
    print("ALL RULES PASS" if ok else "SOME RULES FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
