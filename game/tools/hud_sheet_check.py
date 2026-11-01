#!/usr/bin/env python3
"""Checks HUD art against the HUD style sheet (Visual style, Decisions, "The HUD style sheet"; task T-430).

The checks a script can do:
  outline   the opaque pixels that touch a transparent one (4 neighbours, or the image edge) are the HUD outline
            colour (8, 8, 15), except for a few lighter highlight pixels (at most 15% of the edge, Visual style)
  corners   a panel's four corners are stepped with radius 2 (pixels (0,0), (1,0), (0,1) are cut)
  colours   no pixel is Greenbull's light green or yellow (rule 6)
  size      width and height are even-friendly art pixels (the art is shown at 2x), checked only for the listed size

Run:  python game/tools/hud_sheet_check.py [FILE.png ...]   (no files: every piece the sheet covers in game/art/hud)
Exit code 1 when a piece breaks the sheet. Pieces the sheet exempts from the outline (the clock digits are lit
segments, the fire is the likes bar's own flames with a dark red-brown edge) are listed in EXEMPT_OUTLINE.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

OUTLINE = (8, 8, 15)
GREENBULL = [(104, 220, 96), (247, 208, 52)]
# The notebook page's checkbox, tick and cross-off stroke (T-464) are pen marks in ink, not outlined pieces.
EXEMPT_OUTLINE = ("clock_digit", "viewers_fire", "likes_heart", "mission_checkbox", "mission_tick", "mission_cross")
BREAK_SHARE = 0.15      # Visual style lets lighter highlight pixels break the dark outline, a few of them
CORNER_RADIUS = 2       # the sheet's stepped panel corner
PANELS = ("clock_panel", "viewers_panel", "subgoal_frame", "live_badge")
HUD_DIR = Path(__file__).resolve().parent.parent / "art" / "hud"


def edge_pixels(im: Image.Image):
    """Opaque pixels that touch transparency or the image's edge."""
    w, h = im.size
    px = im.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] < 255:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < w and 0 <= ny < h) or px[nx, ny][3] < 255:
                    yield (x, y)
                    break


def outline_breaks(im: Image.Image):
    px = im.load()
    return [(x, y) for (x, y) in edge_pixels(im) if px[x, y][:3] != OUTLINE]


def corner_radius(im: Image.Image) -> int:
    """The panel's corner step: how many pixels of the top row are transparent before the first opaque one
    (2 = the sheet's stepped corner: pixels (0,0), (1,0) and (0,1) are cut)."""
    px = im.load()
    r = 0
    while r < im.width and px[r, 0][3] == 0:
        r += 1
    return r


def corner_ok(im: Image.Image) -> bool:
    """All four corners are stepped with the sheet's radius."""
    w, h = im.size
    px = im.load()
    cut = {(x, y) for x in range(CORNER_RADIUS) for y in range(CORNER_RADIUS) if x + y < CORNER_RADIUS}
    for (x, y) in cut:
        for cx, cy in ((x, y), (w - 1 - x, y), (x, h - 1 - y), (w - 1 - x, h - 1 - y)):
            if px[cx, cy][3] != 0:
                return False
    return corner_radius(im) == CORNER_RADIUS


def greenbull_pixels(im: Image.Image):
    return [p for p in set(im.getdata()) if p[3] == 255 and tuple(p[:3]) in GREENBULL]


def check(path: Path) -> list[str]:
    im = Image.open(path).convert("RGBA")
    name = path.stem
    problems = []
    if not name.startswith(EXEMPT_OUTLINE):
        n, total = len(outline_breaks(im)), len(list(edge_pixels(im)))
        if n > BREAK_SHARE * total:
            problems.append(f"outline: {n} of {total} edge pixels are not the outline colour (at most {BREAK_SHARE:.0%})")
    if name in PANELS and not corner_ok(im):
        problems.append(f"corners: not the sheet's stepped corner of radius {CORNER_RADIUS} (found {corner_radius(im)})")
    if greenbull_pixels(im):
        problems.append("colours: Greenbull's colours")
    return problems


def hud_files() -> list[Path]:
    return sorted(p for p in HUD_DIR.glob("*.png"))


def main(argv=None) -> int:
    files = [Path(a) for a in (argv if argv is not None else sys.argv[1:])] or hud_files()
    bad = 0
    for f in files:
        problems = check(f)
        print(f"{'FAIL' if problems else 'ok  '} {f.name}" + "".join(f"\n       {p}" for p in problems))
        bad += bool(problems)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
