"""Build the rain splash sheet (T-509): 4 frames of 12 x 8 in one row (48 x 8), RGBA.

Free script work, no PixelLab call. Every colour is sampled from the two PixelLab generations
art-archive/T-509/style-loop/raw/splash/v1-2_crown_raw.png and v1-2_ring_raw.png; the frame
shapes are placed pixel by pixel (the 32 x 32 drawings are far too large for 12 x 8 and are never
scaled). Every pixel is fully opaque or fully transparent.

    python game/tools/build_rain_splash.py <out.png> [--version 1|2|3|4]   (default 4)
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
    # v2 (style loop refine, free): a still darker, more desaturated blue for the fading ring's
    # far edge, so frame 4 fades in three tones (far 9, sides 8, near 7). Darkened from "8".
    "9": (70, 104, 134, 255),
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

# Version 2: frame 4's far edge in the darkest blue "9" (sides stay "8", near side "7").
FRAME4_V2 = [
    "............",
    "............",
    "............",
    "............",
    "....9..9....",
    ".8........8.",
    "..........8.",
    "...7..77....",
]


# Version 3: frame 1's tiny ring opened up around the dot (6 x 3: dark far edge, mid sides with a
# transparent gap either side of the dot, pale near side), so it reads as a dot inside a ring.
FRAME1_V3 = [
    "............",
    "............",
    "............",
    "............",
    "............",
    "....8888....",
    "...4.WC.4...",
    "....2112....",
]


# Version 4: frame 1 back to 8 pixels (a white-and-cyan dot in a tiny 4x3 ring, lighter than v3's
# 12); frame 4 keeps the darkest far edge "9" and gains two dim droplets "4" that have fallen on
# from frame 3's (2,2) and (9,3), so the fade has 4 tones.
FRAME4_V4 = [
    "............",
    "............",
    "............",
    "..4.........",
    "....9..9.4..",
    ".8........8.",
    "..........8.",
    "...7..77....",
]


def frames_for(version: int) -> list[list[str]]:
    if version == 1:
        return FRAMES_MAP
    if version == 2:
        return FRAMES_MAP[:3] + [FRAME4_V2]
    if version == 3:
        return [FRAME1_V3] + FRAMES_MAP[1:3] + [FRAME4_V2]
    return FRAMES_MAP[:3] + [FRAME4_V4]


def ascii_map(version: int = 4) -> str:
    """The sheet as text, one frame per block, for reviewers who cannot zoom in."""
    out = []
    for f, rows in enumerate(frames_for(version)):
        out.append(f"frame {f + 1}:")
        out += [f"  {r}" for r in rows]
    return "\n".join(out)


def build_sheet(version: int = 4) -> Image.Image:
    img = Image.new("RGBA", (FRAME_W * FRAMES, FRAME_H), (0, 0, 0, 0))
    for f, rows in enumerate(frames_for(version)):
        assert len(rows) == FRAME_H, f"frame {f + 1} has {len(rows)} rows"
        for y, row in enumerate(rows):
            assert len(row) == FRAME_W, f"frame {f + 1} row {y} is {len(row)} wide"
            for x, ch in enumerate(row):
                if ch != ".":
                    img.putpixel((f * FRAME_W + x, y), PALETTE[ch])
    return img


def main(argv: list[str]) -> int:
    version = 4
    if "--version" in argv:
        i = argv.index("--version")
        version = int(argv[i + 1])
        argv = argv[:i] + argv[i + 2:]
    if len(argv) != 1:
        print(__doc__)
        return 2
    out = Path(argv[0])
    if out.exists():
        print(f"refusing to overwrite {out}")
        return 1
    build_sheet(version).save(out)
    print(f"saved {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
