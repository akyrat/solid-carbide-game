"""Enlarged (nearest-neighbour) preview of a PNG on a dark and a light background, stacked.

Also prints the count of each opaque colour (optionally only right of --from-x).

    python game/tools/art_preview.py <in.png> <out.png> [--scale 4] [--from-x 64]
"""
import sys
from collections import Counter

from PIL import Image

DARK_BG = (20, 20, 28, 255)
LIGHT_BG = (235, 235, 230, 255)


def preview(img, scale=4, gap=8):
    w, h = img.size
    big = img.convert("RGBA").resize((w * scale, h * scale), Image.NEAREST)
    out = Image.new("RGBA", (w * scale, 2 * h * scale + gap), (128, 128, 128, 255))
    out.paste(DARK_BG, (0, 0, w * scale, h * scale))
    out.paste(LIGHT_BG, (0, h * scale + gap, w * scale, 2 * h * scale + gap))
    out.alpha_composite(big, (0, 0))
    out.alpha_composite(big, (0, h * scale + gap))
    return out


def colour_counts(img, from_x=0):
    img = img.convert("RGBA")
    crop = img.crop((from_x, 0, img.width, img.height))
    return {c: n for c, n in Counter(crop.getdata()).items() if c[3] == 255}


def main(argv):
    args = list(argv[1:])
    opts = {"--scale": 4, "--from-x": 0}
    for k in list(opts):
        if k in args:
            i = args.index(k)
            opts[k] = int(args[i + 1])
            del args[i:i + 2]
    if len(args) != 2:
        print(__doc__)
        return 2
    img = Image.open(args[0])
    preview(img, opts["--scale"]).save(args[1])
    for c, n in sorted(colour_counts(img, opts["--from-x"]).items(), key=lambda t: -t[1]):
        print(c[:3], n)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
