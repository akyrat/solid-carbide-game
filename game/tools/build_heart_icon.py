#!/usr/bin/env python3
"""Draws the HUD's likes heart (task T-086; no PixelLab call, 0 generations).

Board, 2026-10-14: a flat Redgull-red heart in the HUD's comic look: a thick dark outline like
the "LIKES" text's, a little chunky. A hand-placed pixel grid: 9 x 8 fill pixels plus a 1 pixel
outline all round = 11 x 10 art pixels. The HUD shows it at 2x (nearest), so one art pixel is
two screen pixels, about the height of the "LIKES" text with its outline. Two colours only:
Redgull red (the HUD's Hud.HEART_COLOR) and the HUD's dark text-outline colour
(Hud.OUTLINE_COLOR). Transparent background, no anti-aliasing, no semi-transparent pixels.

Commands (run from the repo root):
  python game/tools/build_heart_icon.py build    # game/art/hud/likes_heart.png + .json, previews in art-archive/T-086/
  python game/tools/build_heart_icon.py check    # checks the committed PNG (exit 1 on a fail)

Running build twice gives byte-identical files.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_drift_mark as marks  # noqa: E402  (shared Redgull-red check)
import check_sprite_rules as rules  # noqa: E402
from remove_car_shadow import write_png  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
REPO = GAME.parent
OUT_DIR = GAME / "art" / "hud"
PNG = OUT_DIR / "likes_heart.png"
ARCHIVE = REPO / "art-archive" / "T-086"

RED = (219, 26, 41)  # Hud.HEART_COLOR (0.86, 0.1, 0.16), Redgull red
OUTLINE = (8, 8, 15)  # Hud.OUTLINE_COLOR (0.03, 0.03, 0.06)
CLEAR = (0, 0, 0, 0)

# The fill, 9 wide and 8 tall. X is red.
FILL = [
    ".XXX.XXX.",
    "XXXXXXXXX",
    "XXXXXXXXX",
    "XXXXXXXXX",
    ".XXXXXXX.",
    "..XXXXX..",
    "...XXX...",
    "....X....",
]
SIZE = (len(FILL[0]) + 2, len(FILL) + 2)  # with the 1 pixel outline
SHOW_SCALE = 2  # screen pixels per art pixel in the HUD


def rows():
    """The icon as rows of (r, g, b, a)."""
    w, h = SIZE
    red = {(x + 1, y + 1) for y, line in enumerate(FILL) for x, c in enumerate(line) if c == "X"}
    out = []
    for y in range(h):
        row = []
        for x in range(w):
            if (x, y) in red:
                row.append(RED + (255,))
            elif any((x + dx, y + dy) in red for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                row.append(OUTLINE + (255,))
            else:
                row.append(CLEAR)
        out.append(row)
    return out


def check_rows(icon):
    results, _ = rules.check_rows(icon, size=SIZE[0], max_colors=3)
    results[0] = ("size %dx%d" % SIZE, (len(icon[0]), len(icon)) == SIZE, "%dx%d" % (len(icon[0]), len(icon)))
    colours = {p[:3] for r in icon for p in r if p[3]}
    results.append(("only Redgull red and the outline colour", colours == {RED, OUTLINE}, str(colours)))
    results.append(("the red is Redgull red", marks.is_redgull_red(RED), str(RED)))
    return results


def check(path=PNG):
    _, _, icon = rules.decode_png(Path(path).read_bytes())
    return check_rows(icon)


def enlarge(icon, k, bg=None):
    """Nearest-neighbour k x, optionally on a flat background colour."""
    out = []
    for r in icon:
        line = []
        for p in r:
            if p[3] == 0 and bg is not None:
                p = bg + (255,)
            line.extend([p] * k)
        out.extend([list(line) for _ in range(k)])
    return out


def previews(icon, archive=ARCHIVE):
    archive.mkdir(parents=True, exist_ok=True)
    dark, light = enlarge(icon, 16, (20, 20, 40)), enlarge(icon, 16, (235, 235, 240))
    gap = [[(128, 128, 128, 255)] * 8 for _ in dark]
    sheet = [a + g + b for a, g, b in zip(dark, gap, light)]
    write_png(archive / "heart_dark_light_x16.png", sheet)
    return archive


def build(out_dir=OUT_DIR, archive=ARCHIVE):
    icon = rows()
    out_dir.mkdir(parents=True, exist_ok=True)
    write_png(out_dir / "likes_heart.png", icon)
    record = {
        "task": "T-086",
        "what": "The HUD likes heart: flat Redgull red, thick dark outline like the LIKES text's, a little chunky.",
        "made_by": "game/tools/build_heart_icon.py (a hand-placed pixel grid; no PixelLab call, 0 generations, board 2026-10-14). Byte-identical every run.",
        "size": list(SIZE),
        "shown_at_scale": SHOW_SCALE,
        "palette": {"red": list(RED), "outline": list(OUTLINE)},
        "references": ["docs/visual-style.md (technical rules, Redgull red)", "docs/hud-and-menus.md", "game/scripts/hud/hud.gd (HEART_COLOR, OUTLINE_COLOR)"],
        "prompt": None,
    }
    (out_dir / "likes_heart.json").write_text(json.dumps(record, indent=1) + "\n", encoding="utf-8")
    previews(icon, archive)
    return out_dir


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("command", choices=["build", "check"])
    a = ap.parse_args(argv)
    if a.command == "check":
        res = check()
        for rule, ok, detail in res:
            print(("PASS " if ok else "FAIL ") + rule + ": " + detail)
        return 0 if all(r[1] for r in res) else 1
    print("wrote the heart in", build())
    return 0


if __name__ == "__main__":
    sys.exit(main())
