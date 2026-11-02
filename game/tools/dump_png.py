"""Print a PNG's pixels as a character map plus its palette (free inspection helper, T-509)."""
import sys
from PIL import Image


def dump(path):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    pal = {}
    rows = []
    for y in range(h):
        row = ""
        for x in range(w):
            p = im.getpixel((x, y))
            if p[3] == 0:
                row += "."
                continue
            if p not in pal:
                pal[p] = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"[len(pal) % 62]
            row += pal[p]
        rows.append(row)
    return rows, pal


if __name__ == "__main__":
    for path in sys.argv[1:]:
        rows, pal = dump(path)
        print(path)
        print("\n".join(rows))
        for p, c in pal.items():
            print(c, p)
