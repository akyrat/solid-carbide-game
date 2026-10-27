#!/usr/bin/env python3
"""A side-by-side sheet of the level-up pieces, old (left) and new (right), on a dark and a light band (T-303).

Nearest-neighbour enlarged, for the review pictures; it reads the PNGs and writes one sheet.

  python game/tools/level_up_art_preview.py <old folder> <new folder> <out.png> [scale]
"""
import sys
from pathlib import Path

from PIL import Image

FILES = ["header_ribbon", "gift_pack_emblem", "card_frame", "highlight_frame", "button_plate",
         "button_plate_pressed", "sunburst"]
DARK, LIGHT = (24, 22, 40, 255), (222, 222, 222, 255)
PAD = 8


def sheet(old_dir, new_dir, scale=2):
    pieces = []
    for name in FILES:
        pair = [Image.open(Path(d) / (name + ".png")).convert("RGBA") for d in (old_dir, new_dir)]
        pieces.append([p.resize((p.width * scale, p.height * scale), Image.NEAREST) for p in pair])
    col_w = max(p[0].width for p in pieces) + 2 * PAD
    row_h = [max(p[0].height, p[1].height) + 2 * PAD for p in pieces]
    out = Image.new("RGBA", (col_w * 4, sum(row_h)), DARK)
    y = 0
    for (old, new), h in zip(pieces, row_h):
        for i, (img, bg) in enumerate([(old, DARK), (new, DARK), (old, LIGHT), (new, LIGHT)]):
            cell = Image.new("RGBA", (col_w, h), bg)
            cell.alpha_composite(img, (PAD, PAD))
            out.alpha_composite(cell, (i * col_w, y))
        y += h
    return out


if __name__ == "__main__":
    scale = int(sys.argv[4]) if len(sys.argv) > 4 else 2
    Path(sys.argv[3]).parent.mkdir(parents=True, exist_ok=True)
    sheet(sys.argv[1], sys.argv[2], scale).save(sys.argv[3])
    print(sys.argv[3])
