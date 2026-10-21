"""Scale the approved car frame 2x (nearest-neighbour) for the root README.

Usage: python tools/make_readme_car.py   (run from anywhere)
Source: game/art/car/car_sw_front.png (frame 8 of game/art/car/car_iso.png, 32 frames since T-102).
Output: docs/readme/car.png
"""
import os
import sys
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "game", "art", "car", "car_sw_front.png")
OUTPUT = os.path.join(ROOT, "docs", "readme", "car.png")
SCALE = 2


def scale_nearest(img, factor):
    return img.convert("RGBA").resize((img.width * factor, img.height * factor), Image.NEAREST)


def main():
    out = scale_nearest(Image.open(SOURCE), SCALE)
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    out.save(OUTPUT)
    print(f"Wrote {OUTPUT} {out.size}")


if __name__ == "__main__":
    sys.exit(main())
