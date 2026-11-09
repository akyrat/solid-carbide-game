#!/usr/bin/env python3
"""Fits the kept death east frames (T-613) to the game's frame format. Free, no PixelLab.

Reads art-archive/T-613/final/kaiju_death_e.png (12 frames), moves the lying frames (from LYING_FROM) down so the body rests
on the ground line (the placeholders rest at y 205 in the frame, the feet at 203), repeats the last frame to fill 16 frames
(the data's count: the fall then plays 12 drawn frames and holds the lying one for the last 0.5 s), and writes
game/art/kaiju/kaiju_death_e.png. Run from the repo root: python game/tools/fit_kaiju_death_e.py [IN OUT]
"""
import sys
from pathlib import Path

from PIL import Image

FRAME = 224
TOTAL = 16
LYING_FROM = 5        # index of the first frame lying on the ground
GROUND_END_Y = 205    # the lying body's lowest row + 1 should land here


def fit(sheet, lying_from=LYING_FROM, total=TOTAL, ground=GROUND_END_Y):
    sheet = sheet.convert("RGBA")
    n = sheet.width // FRAME
    frames = [sheet.crop((i * FRAME, 0, (i + 1) * FRAME, FRAME)) for i in range(n)]
    box = frames[-1].getchannel("A").getbbox()
    dy = ground - box[3]
    out = []
    for i, f in enumerate(frames):
        if i >= lying_from and dy:
            g = Image.new("RGBA", f.size, (0, 0, 0, 0))
            g.paste(f, (0, dy), f)
            f = g
        out.append(f)
    while len(out) < total:
        out.append(out[-1].copy())
    res = Image.new("RGBA", (FRAME * total, FRAME), (0, 0, 0, 0))
    for i, f in enumerate(out[:total]):
        res.paste(f, (i * FRAME, 0))
    return res


def main(argv):
    root = Path(__file__).resolve().parents[2]
    src = Path(argv[0]) if argv else root / "art-archive" / "T-613" / "final" / "kaiju_death_e.png"
    dst = Path(argv[1]) if len(argv) > 1 else root / "game" / "art" / "kaiju" / "kaiju_death_e.png"
    fit(Image.open(src)).save(dst)
    print("wrote", dst)


if __name__ == "__main__":
    main(sys.argv[1:])
