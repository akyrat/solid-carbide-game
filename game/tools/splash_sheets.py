"""Makes the review pictures for the splash cover: python game/tools/splash_sheets.py <out dir> <v1.png> [<v2.png> ...]

Writes splash_enlarged.png (the first image at 4x, nearest neighbour) and
compositions.png (all the images in a 2-wide grid, each at 2x). Needs Pillow.
"""
import sys
from pathlib import Path

from PIL import Image


def sheets(out_dir, paths):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    first = Image.open(paths[0]).convert("RGB")
    first.resize((first.width * 4, first.height * 4), Image.NEAREST).save(out / "splash_enlarged.png")
    ims = [Image.open(p).convert("RGB") for p in paths]
    w, h = ims[0].width * 2, ims[0].height * 2
    rows = (len(ims) + 1) // 2
    sheet = Image.new("RGB", (w * 2, h * rows), (24, 24, 24))
    for i, im in enumerate(ims):
        sheet.paste(im.resize((w, h), Image.NEAREST), ((i % 2) * w, (i // 2) * h))
    sheet.save(out / "compositions.png")
    return [out / "splash_enlarged.png", out / "compositions.png"]


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    for p in sheets(sys.argv[1], sys.argv[2:]):
        print(p)
