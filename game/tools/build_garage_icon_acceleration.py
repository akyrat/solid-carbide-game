#!/usr/bin/env python3
"""The acceleration upgrade's garage icon (task T-366; Garage design, Decisions, "Pixel art icons for the upgrades").

A speedometer dial (blue, the dominant colour) with a white needle swung up to the right and speed lines
trailing behind it. 16 x 16, hand-placed pixel grid, 1 pixel dark HUD outline drawn round the shape like the
reaction icons (T-352), flat fills, one highlight, opaque or empty pixels only, no Greenbull colours.
No PixelLab (0 generations). Deterministic.

  python game/tools/build_garage_icon_acceleration.py build --out game/art/garage/acceleration.png [--force]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hud_livestream_art as hud  # noqa: E402

SIZE = 16
PAL = {
    "c": (40, 130, 235),    # dial blue (dominant)
    "C": (20, 80, 180),     # dial shade
    "l": (130, 200, 255),   # highlight
    "W": (245, 245, 250),   # needle, ticks, speed lines
    "k": (20, 40, 90),      # dial face (deep blue)
}
GRID = [
    "....cccccc....",
    "..cllcccccCC..",
    ".cckkkkkkkkcCC",
    "cckkkkWWkkkkcC",
    "ckkWkkkkkkWkkC",
    "ckkkkkkkkWkkkC",
    "ckWkkkkkWkkWkC",
    "ckkkkkkWWkkkkC",
    "cWkkkkWWkkkkWC",
    "ckkkkkWWkkkkCC",
    ".cckkkkkkkkcCC",
    "..ccccccccCC..",
    "....CCCCCC....",
]


def draw() -> Image.Image:
    w = max(len(r) for r in GRID)
    im = hud.new(SIZE, SIZE)
    ox, oy = (SIZE - w) // 2, (SIZE - len(GRID)) // 2
    for y, row in enumerate(GRID):
        for x, ch in enumerate(row):
            if ch != ".":
                hud.put(im, ox + x, oy + y, PAL[ch])
    shape = {(x, y) for y in range(SIZE) for x in range(SIZE) if hud.opaque(im, x, y)}
    for y in range(SIZE):
        for x in range(SIZE):
            if (x, y) not in shape and any((x + dx, y + dy) in shape for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                hud.put(im, x, y, hud.OUT)
    return im


def record() -> dict:
    return {
        "task": "T-366",
        "what": "The acceleration upgrade's garage icon: a speedometer dial with the needle swung up to the right.",
        "made_by": "game/tools/build_garage_icon_acceleration.py (hand-placed pixel grid; no PixelLab call, 0 generations). "
                   "Byte-identical every run.",
        "size": [SIZE, SIZE],
        "shown_at_scale": 3,
        "references": ["docs/visual-style.md (Content, Rules)", "docs/garage-design.md",
                       "game/tools/build_hud_reaction_icons.py (the outline and palette approach)"],
        "prompt": None,
    }


def build(out: Path, force=False) -> Path:
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.exists() and not force:
        raise SystemExit(f"{out} exists (use --force)")
    draw().save(out)
    out.with_suffix(".json").write_text(json.dumps(record(), indent=1) + "\n", encoding="utf-8")
    return out


def main(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("--out", default="game/art/garage/acceleration.png")
    b.add_argument("--force", action="store_true")
    a = ap.parse_args(argv)
    print(build(Path(a.out), a.force))


if __name__ == "__main__":
    main()
