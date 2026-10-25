"""T-293: free fix for rule 6. Swaps the given exact colours for others, pixel for pixel
(no new pixels, alpha kept). Usage: python recolour_reds.py src dst R,G,B=R,G,B ..."""
import sys
from PIL import Image

src, dst, *pairs = sys.argv[1:]
mapping = {}
for p in pairs:
    a, b = p.split("=")
    mapping[tuple(int(x) for x in a.split(","))] = tuple(int(x) for x in b.split(","))
im = Image.open(src).convert("RGBA")
px = im.load()
n = 0
for y in range(im.height):
    for x in range(im.width):
        r, g, b, al = px[x, y]
        if al and (r, g, b) in mapping:
            px[x, y] = mapping[(r, g, b)] + (al,)
            n += 1
im.save(dst)
print(f"recoloured {n} pixels -> {dst}")
