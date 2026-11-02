"""Build the rain splash sheet (T-509): 4 frames of 12 x 8 in one row (48 x 8), RGBA.

Free script work, no PixelLab call. Every colour is sampled from the two PixelLab generations
art-archive/T-509/style-loop/raw/splash/v1-2_crown_raw.png and v1-2_ring_raw.png; the frame
shapes are placed pixel by pixel (the 32 x 32 drawings are far too large for 12 x 8 and are never
scaled). Every pixel is fully opaque or fully transparent.

    python game/tools/build_rain_splash.py <out.png>
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

FRAME_W, FRAME_H, FRAMES = 12, 8, 4

# Colours sampled from the PixelLab drawings (source file in the comment).
PALETTE = {
    "W": (252, 254, 252, 255),  # crown: droplet highlight, near white
    "C": (202, 251, 251, 255),  # crown: the hint of cyan at the impact
    "1": (228, 246, 255, 255),  # ring: palest blue-white
    "2": (202, 232, 255, 255),  # ring: pale blue-white
    "3": (143, 197, 232, 255),  # ring: light blue-grey
    "4": (114, 167, 204, 255),  # ring: mid blue-grey
    "7": (103, 154, 192, 255),  # ring: darker blue-grey
    "8": (92, 141, 176, 255),   # ring: darkest, desaturated far edge
}

# Rows top to bottom, 12 characters each, "." is transparent.
FRAMES_MAP = [
    [  # 1: impact, a bright dot with a tiny ring
        "............",
        "............",
        "............",
        "............",
        "............",
        ".....88.....",
        "....4WC4....",
        ".....22.....",
    ],
    [  # 2: crown, droplets thrown up and out around a flat ring
        "............",
        "......W.....",
        "..W......1..",
        "...2....2...",
        "...3....3...",
        "...878878...",
        "..4......4..",
        "...312213...",
    ],
    [  # 3: the ring at its widest (10 x 4), two droplets still falling
        "............",
        "............",
        "..1.........",
        ".........2..",
        "...888888...",
        ".77......77.",
        ".44......44.",
        "...321123...",
    ],
    [  # 4: the ring fading and broken, a few dark pixels left
        "............",
        "............",
        "............",
        "............",
        "....8..8....",
        ".8........8.",
        "..........8.",
        "...7..77....",
    ],
]


def build_sheet() -> Image.Image:
    img = Image.new("RGBA", (FRAME_W * FRAMES, FRAME_H), (0, 0, 0, 0))
    for f, rows in enumerate(FRAMES_MAP):
        assert len(rows) == FRAME_H, f"frame {f + 1} has {len(rows)} rows"
        for y, row in enumerate(rows):
            assert len(row) == FRAME_W, f"frame {f + 1} row {y} is {len(row)} wide"
            for x, ch in enumerate(row):
                if ch != ".":
                    img.putpixel((f * FRAME_W + x, y), PALETTE[ch])
    return img


def main(argv: list[str]) -> int:
    if len(argv) != 1:
        print(__doc__)
        return 2
    out = Path(argv[0])
    if out.exists():
        print(f"refusing to overwrite {out}")
        return 1
    build_sheet().save(out)
    print(f"saved {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
