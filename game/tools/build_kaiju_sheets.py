#!/usr/bin/env python3
"""Builds the kaiju's walk sheets for the game (T-069) from the generated frames.

One PNG per drawn direction in game/art/kaiju/: kaiju_<dir>.png, 6 frames of
224 x 224 side by side (1344 x 224). The other three directions (south-west,
west, north-west) are mirrored in the game from south-east, east and north-east.
Frames come from art-archive/T-069/walk_<dir>/ (the first 6 of the 7 returned).
Each sheet gets one shared palette of at most 30 colours, by the free
reduce_palette.reduce_image (every colour already in the sheet; no new pixels).
Run from the repo root: python game/tools/build_kaiju_sheets.py
"""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import reduce_palette  # noqa: E402

FRAME = 224
FRAMES = 6
MAX_COLORS = 30
DIRECTIONS = ["s", "se", "e", "ne", "n"]
ROOT = Path(__file__).resolve().parents[2]


def build_sheet(frame_paths, max_colors=MAX_COLORS):
    """One row of frames, each FRAME x FRAME RGBA, with one shared palette."""
    sheet = Image.new("RGBA", (FRAME * len(frame_paths), FRAME), (0, 0, 0, 0))
    for i, p in enumerate(frame_paths):
        f = Image.open(p).convert("RGBA")
        if f.size != (FRAME, FRAME):
            raise ValueError(f"{p} is {f.size}, expected {FRAME}x{FRAME}")
        sheet.paste(f, (i * FRAME, 0))
    return reduce_palette.reduce_image(sheet, max_colors)


def main():
    out = ROOT / "game" / "art" / "kaiju"
    out.mkdir(parents=True, exist_ok=True)
    for d in DIRECTIONS:
        src = ROOT / "art-archive" / "T-069" / f"walk_{d}"
        paths = [src / f"kaiju_walk_{d}_{i}.png" for i in range(FRAMES)]
        build_sheet(paths).save(out / f"kaiju_{d}.png")
        print("wrote", out / f"kaiju_{d}.png")
    return 0


if __name__ == "__main__":
    sys.exit(main())
