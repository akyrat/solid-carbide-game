"""Crops a rectangle out of a screenshot and enlarges it (nearest-neighbour), to look at HUD pixels.

    python game/tools/crop_zoom.py <in.png> <out.png> <x> <y> <w> <h> [--scale 4]
"""
import sys

from PIL import Image


def crop_zoom(img, x, y, w, h, scale=4):
    return img.convert("RGBA").crop((x, y, x + w, y + h)).resize((w * scale, h * scale), Image.NEAREST)


def main(argv):
    args = list(argv)
    scale = 4
    if "--scale" in args:
        i = args.index("--scale")
        scale = int(args[i + 1])
        del args[i:i + 2]
    if len(args) != 6:
        print(__doc__)
        return 2
    src, out = args[0], args[1]
    x, y, w, h = (int(v) for v in args[2:6])
    crop_zoom(Image.open(src), x, y, w, h, scale).save(out)
    print(f"saved {w * scale}x{h * scale} to {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
