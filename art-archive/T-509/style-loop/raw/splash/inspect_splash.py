"""Print the opaque pixels of a raw PixelLab PNG as a character map with its palette (T-509, free)."""
import sys
from PIL import Image

for path in sys.argv[1:]:
    im = Image.open(path).convert("RGBA")
    bb = im.getbbox()
    print(path, im.size, bb)
    pal = {}
    for y in range(bb[1], bb[3]):
        row = ""
        for x in range(bb[0], bb[2]):
            p = im.getpixel((x, y))
            if p[3] < 128:
                row += "."
            else:
                if p not in pal:
                    pal[p] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"[len(pal) % 62]
                row += pal[p]
        print(row)
    alphas = sorted({im.getpixel((x, y))[3] for x in range(im.width) for y in range(im.height)})
    print("alphas:", alphas)
    for k, v in pal.items():
        print(v, k)
