"""T-509 style loop version 3 of the raindrop sheet (3 variants, 8 x 16 each, one 24 x 16 row).

Free script fix of v2 (round 2 reason): the thin streak is brighter, every streak has 5 px (frames 1-2) or 3 px
(frame 3) of lean with the top to the right, the near-black tail colour (54,57,72) that vanished on the dark
streets is gone, and the short bright streak gets a darker tail so it is not a flat dash. Colours are the ones
PixelLab drew for T-509 (style-loop/raw/v1_raw.png, v1b_raw.png); nothing is scaled. Head (near white) at the
top, as in v2.

    python game/tools/build_rain_drops_v3.py <out.png>
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

FRAME_W, FRAME_H = 8, 16

PALETTE = {
    "F": (249, 250, 254),  # near white-blue head
    "G": (215, 235, 253),  # pale blue-white
    "A": (182, 222, 254),  # pale blue, a hint of cyan
    "B": (112, 132, 204),  # mid blue
    "C": (88, 125, 165),   # blue-grey
    "E": (85, 119, 157),   # desaturated blue tail (darkest)
}

FRAMES = [
    # 1: thin streak, 15 rows, 5 px lean, mostly light.
    [
        "......F.",
        "......F.",
        ".....G..",
        ".....G..",
        ".....A..",
        "....A...",
        "....A...",
        "....A...",
        "...B....",
        "...B....",
        "...B....",
        "..C.....",
        "..C.....",
        ".E......",
        ".E......",
        "........",
    ],
    # 2: thicker and longer, 16 rows, 2 px body, 5 px lean (v2's shape without the near-black tail).
    [
        "......F.",
        "......GF",
        ".....AG.",
        ".....BA.",
        ".....BA.",
        "....BA..",
        "....CB..",
        "....CB..",
        "...CB...",
        "...EC...",
        "...EC...",
        "..EC....",
        "..EE....",
        "..E.....",
        ".E......",
        ".E......",
    ],
    # 3: short bright streak, 10 rows, 3 px lean, bright head to a darker tail.
    [
        "........",
        "........",
        "........",
        ".....F..",
        ".....F..",
        "....G...",
        "....G...",
        "....A...",
        "...A....",
        "...B....",
        "...B....",
        "..C.....",
        "........",
        "........",
        "........",
        "........",
    ],
]


def build_sheet() -> Image.Image:
    sheet = Image.new("RGBA", (FRAME_W * len(FRAMES), FRAME_H), (0, 0, 0, 0))
    for f, rows in enumerate(FRAMES):
        if len(rows) != FRAME_H or any(len(r) != FRAME_W for r in rows):
            raise ValueError(f"frame {f + 1} is not {FRAME_W}x{FRAME_H}")
        for y, row in enumerate(rows):
            for x, k in enumerate(row):
                if k != ".":
                    sheet.putpixel((f * FRAME_W + x, y), PALETTE[k] + (255,))
    return sheet


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) != 1:
        print(__doc__)
        return 2
    out = Path(argv[0])
    if out.exists():
        print(f"{out} exists; never overwrite a version")
        return 1
    build_sheet().save(out)
    print("wrote", out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
