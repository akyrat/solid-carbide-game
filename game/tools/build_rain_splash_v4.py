"""Rain splash sheet, style loop version 4 (T-509): a free script fix of version 3 (v3-4.png), no PixelLab call.

Change from version 3, following the evaluator's round 3 reason: frame 1 (the impact) is cut from 14 to 8
pixels, a near-white/cyan dot inside a tiny 4 x 3 ring (darkest far edge, mid sides, pale near side), so it
is clearly smaller than frame 2 and the splash grows 8 -> 19 -> 20 -> fades to 9. Frames 2 to 4 unchanged.

    python game/tools/build_rain_splash_v4.py build <out.png>
    python game/tools/build_rain_splash_v4.py facts <png>
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
import build_rain_splash_v2 as v2  # noqa: E402
import build_rain_splash_v3 as v3  # noqa: E402

FRAME_W, FRAME_H, FRAMES = v3.FRAME_W, v3.FRAME_H, v3.FRAMES
PALETTE = dict(v3.PALETTE)

FRAME1 = [  # 1: impact, a small bright dot with a tiny ring
    "............",
    "............",
    "............",
    "............",
    "............",
    ".....99.....",
    "....4WC4....",
    ".....22.....",
]
FRAMES_MAP = [FRAME1] + v3.FRAMES_MAP[1:]


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
