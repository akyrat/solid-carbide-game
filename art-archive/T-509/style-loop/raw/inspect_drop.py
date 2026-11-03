"""Print a PNG's alpha mask and colours (T-509 helper). Usage: python inspect_drop.py <png>"""
import sys
from PIL import Image

im = Image.open(sys.argv[1]).convert("RGBA")
w, h = im.size
px = im.load()
for y in range(h):
    print("".join("#" if px[x, y][3] >= 128 else ("+" if px[x, y][3] > 0 else ".") for x in range(w)))
print("bbox", im.getbbox())
cols = {}
for y in range(h):
    for x in range(w):
        if px[x, y][3] > 0:
            cols[px[x, y]] = cols.get(px[x, y], 0) + 1
print(len(cols), "colours")
for c, n in sorted(cols.items(), key=lambda t: -t[1])[:30]:
    print(c, n)
