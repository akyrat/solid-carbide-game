#!/usr/bin/env python3
"""T-613 hand fix (board, 2026-11-09), free, no PixelLab: draws the far leg back into frame 5 of the kaiju's walk east.

Walk east version 3 (art-archive/T-613/kaiju_walk_e_v3a.png) loses the far (dark, in shadow) leg in its 5th frame
(index 4): frames 1 to 4 and 6 show it as a near-black silhouette with two cyan claws beside the planted leg, frame 5 shows
nothing. The far foot is taken from frame 4's own pixels (box FOOT_BOX: the silhouette and claws right of the knee),
moved half the way to where frame 6 has it (SHIFT_X) and drawn behind frame 5's own pixels, so the colours are the
still's palette, the outline is the sheet's own, and the near leg and the ground point are not touched.
Run from the repo root: python game/tools/fix_kaiju_walk_e_frame5.py [IN.png OUT.png]
"""
import sys
from pathlib import Path

from PIL import Image

FRAME = 224
SRC_FRAME = 3          # frame 4 (0-based), the neighbour the foot is taken from
TARGET_FRAME = 4       # frame 5
FOOT_BOX = (155, 150, 170, 173)   # x0, y0, x1, y1 (x1, y1 excluded) inside the frame
SHIFT_X = -1
SHIFT_Y = 0


def fix(sheet, src=SRC_FRAME, target=TARGET_FRAME, box=FOOT_BOX, dx=SHIFT_X, dy=SHIFT_Y):
    sheet = sheet.convert("RGBA")
    src_f = sheet.crop((src * FRAME, 0, (src + 1) * FRAME, FRAME))
    tgt = sheet.crop((target * FRAME, 0, (target + 1) * FRAME, FRAME))
    foot = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    foot.paste(src_f.crop(box), (box[0] + dx, box[1] + dy))
    out = foot                                  # behind: the target's own pixels go on top
    out.alpha_composite(tgt)
    res = sheet.copy()
    res.paste(out, (target * FRAME, 0))
    return res


def main(argv):
    root = Path(__file__).resolve().parents[2] / "art-archive" / "T-613"
    src = Path(argv[0]) if argv else root / "kaiju_walk_e_v3a.png"
    dst = Path(argv[1]) if len(argv) > 1 else root / "kaiju_walk_e_v5_handfix.png"
    if dst.exists():
        raise SystemExit(f"{dst} exists: never overwrite a version")
    fix(Image.open(src)).save(dst)
    print("wrote", dst)


if __name__ == "__main__":
    main(sys.argv[1:])
