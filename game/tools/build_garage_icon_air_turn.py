#!/usr/bin/env python3
"""The air turn garage icon (task T-370; Garage design, Decisions, "Pixel art icons for the upgrades").

A car in the air under a curved spin arrow. Hand-placed pixel grid (no PixelLab, 0 generations), 16 x 16, a
1 pixel dark HUD outline round the shape, flat fills and one highlight, opaque or empty pixels only. One
dominant colour (blue) plus white and the outline; none of Greenbull's colours. Deterministic.

  python game/tools/build_garage_icon_air_turn.py build --out-dir game/art/garage [--force]
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
KEY = "air_turn"
PAL = {
    "W": (245, 245, 250), "G": (150, 160, 190),          # the spin arrow: white, shade
    "b": (70, 140, 255), "B": (40, 90, 200), "l": (170, 215, 255),   # car body, shade, window / shine
    "t": (80, 100, 170), "h": (200, 210, 240),             # tyres, hubs
}
GRID = [
    "....WWWWWW....",
    "..WWW....WWW..",
    ".WW........W..",
    "WW.........W..",
    "W..........W..",
    "W........WWWWW",
    "W.........WWW.",
    "W..........W..",
    "....bbbbb.....",
    "...bllbllb....",
    "...bbbbbbbb...",
    "..bbbbbbbbbb..",
    "..BttBBBBttB..",
    "..thht..thht..",
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
        "task": "T-370",
        "what": "The air turn garage icon: a car in the air under a curved spin arrow, a dark outline.",
        "made_by": "game/tools/build_garage_icon_air_turn.py (hand-placed pixel grid; no PixelLab call, "
                   "0 generations). Byte-identical every run.",
        "size": [SIZE, SIZE],
        "shown_at_scale": 3,
        "references": ["docs/visual-style.md (Content, Rules)", "docs/garage-design.md",
                       "game/tools/build_hud_reaction_icons.py (the comic outline)"],
        "prompt": None,
    }


def build(out_dir: Path, force=False) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    p = out_dir / f"{KEY}.png"
    if p.exists() and not force:
        raise SystemExit(f"{p} exists (use --force)")
    draw().save(p)
    p.with_suffix(".json").write_text(json.dumps(record(), indent=1) + "\n", encoding="utf-8")
    return p


def main(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("--out-dir", required=True)
    b.add_argument("--force", action="store_true")
    a = ap.parse_args(argv)
    print(build(Path(a.out_dir), a.force))


if __name__ == "__main__":
    main()
