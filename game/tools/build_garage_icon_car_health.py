#!/usr/bin/env python3
"""The garage's car health icon (task T-367; Garage design, Decisions, "Pixel art icons for the upgrades").

A 16 x 16 heart with a bold white plus, in the HUD reaction icons' comic look (T-352): a 1 pixel dark
outline, flat fills, one highlight. One dominant colour (red) plus white and the outline colour; none of
Greenbull's colours. Hand-placed grid, no PixelLab (0 generations), deterministic.

  python game/tools/build_garage_icon_car_health.py build [--out-dir game/art/garage] [--force]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hud_livestream_art as hud  # noqa: E402

SIZE = 16
KEY = "car_health"
PAL = {"r": (232, 40, 70), "R": (160, 16, 48), "w": (255, 190, 205), "W": (255, 255, 255)}
GRID = [
    "..rrrr..rrrr..",
    ".rwwrrrrrrrrrR",
    "rrwrrrWWrrrrrR",
    "rrrrrrWWrrrrrR",
    "rrrWWWWWWWWrrR",
    "rrrWWWWWWWWrRR",
    ".rrrrrWWrrrRR.",
    "..rrrrWWrrRR..",
    "...rrrrrrRR...",
    "....rrrrRR....",
    ".....rrRR.....",
    "......RR......",
]


def draw() -> "hud.Image.Image":
    im = hud.new(SIZE, SIZE)
    w = max(len(r) for r in GRID)
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
        "task": "T-367",
        "what": "The car health upgrade's garage icon: a heart with a plus (each level adds a heart).",
        "made_by": "game/tools/build_garage_icon_car_health.py (hand-placed pixel grid; no PixelLab call, "
                   "0 generations). Byte-identical every run.",
        "size": [SIZE, SIZE],
        "references": ["docs/visual-style.md (Content, Rules)", "docs/garage-design.md",
                       "game/art/hud/reaction_heart.png (the comic outline)"],
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
    b.add_argument("--out-dir", default="game/art/garage")
    b.add_argument("--force", action="store_true")
    a = ap.parse_args(argv)
    print(build(Path(a.out_dir), a.force))


if __name__ == "__main__":
    main()
