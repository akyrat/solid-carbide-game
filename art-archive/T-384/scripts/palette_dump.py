"""List an image's colours with pixel counts and bounding boxes (T-384, free inspection)."""
import sys
from collections import Counter

from PIL import Image

im = Image.open(sys.argv[1]).convert("RGBA")
w, h = im.size
px = im.load()
where = {}
for y in range(h):
    for x in range(w):
        where.setdefault(px[x, y], []).append((x, y))
for col, pts in sorted(where.items(), key=lambda kv: -len(kv[1])):
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    print(col, len(pts), "x", min(xs), max(xs), "y", min(ys), max(ys))
