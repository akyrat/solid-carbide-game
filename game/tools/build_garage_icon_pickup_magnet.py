#!/usr/bin/env python3
"""The pickup magnet's garage icon (task T-369; Garage design, Decisions, "Pixel art icons for the upgrades").

A horseshoe magnet, 16 x 16, hand-placed pixel grid (no PixelLab, 0 generations), drawn like the HUD reaction
icons (build_hud_reaction_icons.py): a 1 pixel dark HUD outline, flat fills, one highlight. One dominant colour
(blue) plus white pole tips and the outline colour; none of Greenbull's colours. Deterministic.

  python game/tools/build_garage_icon_pickup_magnet.py build --out-dir game/art/garage [--force]
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
KEY = "pickup_magnet"
PAL = {
    "b": (50, 120, 245), "B": (24, 66, 170), "h": (140, 190, 255),   # body, shade, highlight
    "W": (245, 245, 250), "G": (150, 160, 190),                       # pole tip, tip shade
}
GRID = [
    ".WWWW....WWWW.",
    ".WWWG....WWWG.",
    ".WWWG....WWWG.",
    ".GGGG....GGGG.",
    ".hbbB....hbbB.",
    ".hbbB....hbbB.",
    ".hbbB....hbbB.",
    ".hbbB....hbbB.",
    ".hbbB....hbbB.",
    ".hbbbb..bbbbB.",
    ".hbbbbbbbbbbB.",
    "..bbbbbbbbbB..",
    "...BBBBBBBB...",
]


def draw() -> Image.Image:
    im = hud.new(SIZE, SIZE)
    ox, oy = (SIZE - max(len(r) for r in GRID)) // 2, (SIZE - len(GRID)) // 2
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
        "task": "T-369",
        "what": "The pickup magnet's garage icon: a blue horseshoe magnet with white pole tips and a dark outline.",
        "made_by": "game/tools/build_garage_icon_pickup_magnet.py (hand-placed pixel grid; no PixelLab call, "
                   "0 generations). Byte-identical every run.",
        "size": [SIZE, SIZE],
        "shown_at_scale": 3,
        "references": ["docs/visual-style.md (Content, Rules)", "docs/garage-design.md",
                       "game/tools/build_hud_reaction_icons.py (the outline and palette approach)"],
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
    ap.add_argument("cmd", choices=["build"])
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args(argv)
    print(build(Path(a.out_dir), a.force))


if __name__ == "__main__":
    main()
