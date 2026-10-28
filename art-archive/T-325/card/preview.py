"""Enlarged preview (x8, nearest) on dark and light backgrounds, and a speck count."""
import sys
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGBA")
w, h = im.size
px = im.load()
specks = []
for y in range(h):
    for x in range(w):
        if px[x, y][3] == 0:
            continue
        n = sum(1 for dx in (-1, 0, 1) for dy in (-1, 0, 1)
                if (dx or dy) and 0 <= x + dx < w and 0 <= y + dy < h and px[x + dx, y + dy][3] > 0)
        if n == 0:
            specks.append((x, y))
print("isolated specks:", specks)
big = im.resize((w * 8, h * 8), Image.NEAREST)
sheet = Image.new("RGBA", (w * 16 + 24, h * 8 + 16), (255, 255, 255, 255))
sheet.paste((24, 24, 32, 255), (0, 0, w * 8 + 16, h * 8 + 16))
sheet.paste((230, 230, 230, 255), (w * 8 + 8, 0, w * 16 + 24, h * 8 + 16))
sheet.alpha_composite(big, (8, 8))
sheet.alpha_composite(big, (w * 8 + 16, 8))
sheet.save(out)
