"""Rain splash sheet, style loop version 3 (T-509): a free script fix of version 2 (v2-3_alt.png), no PixelLab call.

Changes from version 2, following the evaluator's round 2 reason:
- frame 1: the impact is clearer, 14 pixels instead of 8: a 6 x 3 ring around the bright dot and a
  2-pixel spurt rising from it;
- the ring's far edge in frames 1 to 3 uses a darker desaturated blue "9", darkened by script from the
  ring drawing's darkest sampled colour (92,141,176), so far is visibly darker than the sides;
- frame 2: the droplets are each separated from the ring and from each other by transparent pixels;
- frame 4: 9 pixels, the broken ring in three dark tones.
Frames keep the impact on the bottom row at x 5 and 6.

    python game/tools/build_rain_splash_v3.py build <out.png>
    python game/tools/build_rain_splash_v3.py facts <png>
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
import build_rain_splash_v2 as v2  # noqa: E402

FRAME_W, FRAME_H, FRAMES = v2.FRAME_W, v2.FRAME_H, v2.FRAMES

PALETTE = dict(v2.PALETTE)
PALETTE["9"] = (72, 110, 142, 255)  # far edge: (92,141,176) darkened by script, desaturated blue

FRAMES_MAP = [
    [  # 1: impact, a bright dot with a tiny ring and a short spurt
        "............",
        "............",
        "............",
        "............",
        ".....22.....",
        "....9999....",
        "...4.WC.4...",
        "....3223....",
    ],
    [  # 2: crown, 3 droplets thrown up and out around a flat ring
        "............",
        "......W.....",
        "..W.......1.",
        "............",
        "...2....2...",
        "...399993...",
        "..4......4..",
        "...312213...",
    ],
    [  # 3: widest, a round flat 10 x 4 ellipse, two droplets falling
        "............",
        "..1.........",
        "............",
        ".........2..",
        "....9999....",
        "..89....98..",
        ".4........4.",
        "..32111123..",
    ],
    [  # 4: fading, the broken ring in three dark tones
        "............",
        "............",
        "............",
        "............",
        "....9..9....",
        "..9......8..",
        ".8........8.",
        "...7.77.....",
    ],
]


def build_sheet() -> Image.Image:
    img = Image.new("RGBA", (FRAME_W * FRAMES, FRAME_H), (0, 0, 0, 0))
    for f, rows in enumerate(FRAMES_MAP):
        assert len(rows) == FRAME_H
        for y, row in enumerate(rows):
            assert len(row) == FRAME_W
            for x, ch in enumerate(row):
                if ch != ".":
                    img.putpixel((f * FRAME_W + x, y), PALETTE[ch])
    return img


def main(argv: list[str]) -> int:
    if len(argv) == 2 and argv[0] == "build":
        out = Path(argv[1])
        if out.exists():
            print(f"refusing to overwrite {out}")
            return 1
        build_sheet().save(out)
        print(f"saved {out}")
        return 0
    if len(argv) == 2 and argv[0] == "facts":
        print(json.dumps(v2.facts(Image.open(argv[1])), indent=1))
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
