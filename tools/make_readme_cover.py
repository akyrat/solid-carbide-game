"""Make the wide cover at the top of the root README from the main menu's splash art.

Usage: python tools/make_readme_cover.py   (run from anywhere)
Source: game/art/menu/splash.png (320 x 180, the board's own picture, T-445).
Output: docs/readme/cover.png (1280 x 480): a 320 x 120 band of the splash, scaled exactly 4x,
nearest-neighbour, no smoothing. No PixelLab call.
"""
import os
import sys
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "game", "art", "menu", "splash.png")
OUTPUT = os.path.join(ROOT, "docs", "readme", "cover.png")
SCALE = 4
BAND_TOP = 36  # first row of the splash kept in the cover
BAND_HEIGHT = 120


def make_cover(img, top=BAND_TOP, height=BAND_HEIGHT, factor=SCALE):
    band = img.convert("RGBA").crop((0, top, img.width, top + height))
    return band.resize((band.width * factor, band.height * factor), Image.NEAREST)


def main():
    out = make_cover(Image.open(SOURCE))
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    out.save(OUTPUT)
    print(f"Wrote {OUTPUT} {out.size}")


if __name__ == "__main__":
    sys.exit(main())
