#!/usr/bin/env python3
"""The damage bonus garage icon (task T-368; Garage design, Decisions, "Pixel art icons for the upgrades").

A 16 x 16 comic burst (red) with a white up arrow: more damage. Hand-placed pixel grid, no PixelLab (0 generations),
same helpers and 1 pixel dark HUD outline as the reaction icons (build_hud_reaction_icons.py). One dominant colour
(red) plus white and the outline; none of Greenbull's colours. Deterministic.

  python game/tools/build_garage_icon_damage_bonus.py build --out-dir game/art/garage [--force]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hud_livestream_art as hud  # noqa: E402

SIZE = 16
NAME = "damage_bonus"
PAL = {"r": (232, 52, 52), "R": (150, 24, 36), "t": (255, 120, 100), "W": (255, 255, 255)}  # red, shade, highlight, white
GRID = [
    "......r......",
    "r.....r.....r",
    "rr...rrr...rr",
    ".rr.rrrrr.rR.",
    "..rrrrWrrrR..",
    "..trrWWWrrrR.",
    "rrtrWWWWWrRRr",
    "..rrrWWWrrrR.",
    ".rrrrWWWrrRR.",
    "rrrrrWWWrrRRr",
    ".rr.rrrrrRRR.",
    "rr...rrrRR.RR",
    "r.....rR....R",
]
# spiky outer ring, so the white arrow reads inside the red burst


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
        "task": "T-368",
        "what": "The damage bonus upgrade icon: a red comic burst with a white up arrow, dark outline.",
        "made_by": "game/tools/build_garage_icon_damage_bonus.py (hand-placed pixel grid; no PixelLab call, "
                   "0 generations). Byte-identical every run.",
        "size": [SIZE, SIZE],
        "references": ["docs/visual-style.md (Content, Rules)", "docs/garage-design.md",
                       "game/tools/build_hud_reaction_icons.py (outline and helpers)"],
        "prompt": None,
    }


def build(out_dir: Path, force=False) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    p = out_dir / f"{NAME}.png"
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
