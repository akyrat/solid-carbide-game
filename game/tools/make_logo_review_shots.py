#!/usr/bin/env python3
"""T-300: draw the four Greenbull logo files enlarged (nearest-neighbour) on a dark and a light
background into art-archive/T-300/screenshots/. Usage: make_logo_review_shots.py [repo root]"""
import sys
from pathlib import Path

from PIL import Image

NAMES = ["greenbull_emblem_128.png", "greenbull_emblem_64.png", "greenbull_emblem_32.png", "greenbull_wordmark.png"]


def sheet(root, bg, scale=3, pad=16):
    imgs = [Image.open(Path(root) / "game" / "art" / "logo" / n).convert("RGBA") for n in NAMES]
    imgs = [i.resize((i.width * scale, i.height * scale), Image.NEAREST) for i in imgs]
    w = sum(i.width for i in imgs) + pad * (len(imgs) + 1)
    h = max(i.height for i in imgs) + pad * 2
    out = Image.new("RGBA", (w, h), bg)
    x = pad
    for i in imgs:
        out.alpha_composite(i, (x, (h - i.height) // 2))
        x += i.width + pad
    return out


def main(root="."):
    d = Path(root) / "art-archive" / "T-300" / "screenshots"
    d.mkdir(parents=True, exist_ok=True)
    sheet(root, (16, 14, 34, 255)).save(d / "logo_files_dark.png")
    sheet(root, (222, 222, 226, 255)).save(d / "logo_files_light.png")


if __name__ == "__main__":
    main(*(sys.argv[1:2]))
