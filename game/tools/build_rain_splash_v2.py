"""Rain splash sheet, style loop version 2 (T-509): a free script fix of version 1, no PixelLab call.

Separate file because build_rain_splash.py was being edited by another session in this worktree.
Same palette as version 1 (all sampled from raw/splash/v1-2_crown_raw.png and v1-2_ring_raw.png).
Changes from version 1, following the evaluator's round 1 reason:
- frame 3: the 10 x 4 ring is a rounder flat ellipse (no 2 x 2 blocks at the sides), shaded far
  (darkest) to near (brightest);
- frame 4: the broken ring fades in three dark tones instead of two;
- `facts` prints, per frame, the numbers the evaluator could not check by eye.

    python game/tools/build_rain_splash_v2.py build <out.png>
    python game/tools/build_rain_splash_v2.py facts <png>
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

FRAME_W, FRAME_H, FRAMES = 12, 8, 4

PALETTE = {
    "W": (252, 254, 252, 255),  # crown: near white
    "C": (202, 251, 251, 255),  # crown: hint of cyan
    "1": (228, 246, 255, 255),  # ring: palest blue-white
    "2": (202, 232, 255, 255),  # ring: pale blue-white
    "3": (143, 197, 232, 255),  # ring: light blue-grey
    "4": (114, 167, 204, 255),  # ring: mid blue-grey
    "7": (103, 154, 192, 255),  # ring: darker blue-grey
    "8": (92, 141, 176, 255),   # ring: darkest, desaturated far edge
}

FRAMES_MAP = [
    [  # 1: impact (unchanged)
        "............",
        "............",
        "............",
        "............",
        "............",
        ".....88.....",
        "....4WC4....",
        ".....22.....",
    ],
    [  # 2: crown (unchanged)
        "............",
        "......W.....",
        "..W......1..",
        "...2....2...",
        "...3....3...",
        "...878878...",
        "..4......4..",
        "...312213...",
    ],
    [  # 3: widest, a round flat 10 x 4 ellipse, two droplets falling
        "............",
        "............",
        "..1.........",
        ".........2..",
        "....8888....",
        "..78....87..",
        ".4........4.",
        "..32111123..",
    ],
    [  # 4: fading, broken ring in three dark tones
        "............",
        "............",
        "............",
        "............",
        "....8..8....",
        "..8......8..",
        ".7..........",
        "...7.44.....",
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


def facts(img: Image.Image) -> dict:
    img = img.convert("RGBA")
    out = {"size": list(img.size), "frames": []}
    union = set()
    for f in range(img.width // FRAME_W):
        px = [(x, y, img.getpixel((f * FRAME_W + x, y))) for y in range(FRAME_H) for x in range(FRAME_W)]
        op = [(x, y, p) for x, y, p in px if p[3] == 255]
        union |= {p for _, _, p in op}
        ring = [(x, y) for x, y, _ in op if y >= 4]
        bottom = sorted(x for x, y, _ in op if y == FRAME_H - 1)
        ring_w = max(x for x, _ in ring) - min(x for x, _ in ring) + 1 if ring else 0
        ring_h = max(y for _, y in ring) - min(y for _, y in ring) + 1 if ring else 0
        out["frames"].append({
            "frame": f + 1,
            "opaque": len(op),
            "colours": len({p for _, _, p in op}),
            "semi_transparent": sum(1 for *_, p in px if 0 < p[3] < 255),
            "corners_clear": all(img.getpixel((f * FRAME_W + x, y))[3] == 0
                                 for x, y in ((0, 0), (FRAME_W - 1, 0), (0, FRAME_H - 1), (FRAME_W - 1, FRAME_H - 1))),
            "bottom_row_x": bottom,
            "bottom_centre_x5_or_6": 5 in bottom or 6 in bottom,
            "bottom_row_symmetric_about_5.5": bottom == sorted(11 - x for x in bottom),
            "ring_box_rows_4_to_7": f"{ring_w}x{ring_h}",
            "pixels_above_ring": sum(1 for _, y, _ in op if y < 4),
        })
    out["colours_in_sheet"] = len(union)
    return out


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
        print(json.dumps(facts(Image.open(argv[1])), indent=1))
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
