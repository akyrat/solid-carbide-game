#!/usr/bin/env python3
"""Builds the minion's walk sheets for the game (T-068) from the generated frames.

One PNG per drawn direction in game/art/minion/: minion_<dir>.png, 8 frames of
48 x 48 side by side (384 x 48). The other three directions (south-west, west,
north-west) are mirrored in the game from south-east, east and north-east.
Frames come from art-archive/T-068/walk_<dir>/ (east: walk_e_fixed/) after the
free fixes of fix_minion_frames.py. Run from the repo root:
python game/tools/build_minion_sheets.py
"""
import sys
from pathlib import Path

from PIL import Image

FRAME = 48
FRAMES = 8
ROOT = Path(__file__).resolve().parents[2]
SOURCES = {
    "s": ("walk_s_fixed", "minion_walk_s"),
    "se": ("walk_se_fixed", "minion_walk_se"),
    "e": ("walk_e_fixed", "minion_walk_low"),
    "ne": ("walk_ne_fixed", "minion_walk_ne"),
    "n": ("walk_n_fixed", "minion_walk_n"),
}


def build_sheet(frame_paths):
    """One row of FRAMES frames, each FRAME x FRAME RGBA."""
    sheet = Image.new("RGBA", (FRAME * len(frame_paths), FRAME), (0, 0, 0, 0))
    for i, p in enumerate(frame_paths):
        f = Image.open(p).convert("RGBA")
        if f.size != (FRAME, FRAME):
            raise ValueError(f"{p} is {f.size}, expected {FRAME}x{FRAME}")
        sheet.paste(f, (i * FRAME, 0))
    return sheet


def main():
    out = ROOT / "game" / "art" / "minion"
    out.mkdir(parents=True, exist_ok=True)
    for d, (folder, prefix) in SOURCES.items():
        src = ROOT / "art-archive" / "T-068" / folder
        paths = [src / f"{prefix}_{i}.png" for i in range(FRAMES)]
        build_sheet(paths).save(out / f"minion_{d}.png")
        print("wrote", out / f"minion_{d}.png")
    return 0


if __name__ == "__main__":
    sys.exit(main())
