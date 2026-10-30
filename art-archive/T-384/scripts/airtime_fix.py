"""Free script fixes for the airtime illustration (T-384).

Usage: python airtime_fix.py <in.png> <out.png> [--preview <preview.png>] [--max-colors N]

- Clears the background: flood-fills from the edges every pixel whose colour
  matches an edge-connected background colour (the colours found at the corners).
- Snaps alpha to 0/255.
- Reduces to at most N colours (default 30) by merging the closest pairs
  of the least-used colours.
- Writes an 8-bit RGBA PNG and optionally an 8x nearest-neighbour preview
  on dark and light backgrounds.
"""
import sys
from collections import Counter, deque

from PIL import Image


def clear_background(im):
    w, h = im.size
    px = im.load()
    bg = set()
    for x, y in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        r, g, b, a = px[x, y]
        if a:
            bg.add((r, g, b))
    if not bg:
        return 0
    seen = set()
    q = deque()
    for x in range(w):
        q.append((x, 0)); q.append((x, h - 1))
    for y in range(h):
        q.append((0, y)); q.append((w - 1, y))
    cleared = 0
    while q:
        x, y = q.popleft()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        seen.add((x, y))
        r, g, b, a = px[x, y]
        if a == 0 or (r, g, b) in bg:
            if a:
                px[x, y] = (0, 0, 0, 0)
                cleared += 1
            q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return cleared


def snap_alpha(im):
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)


def reduce_colours(im, n):
    px = im.load()
    w, h = im.size
    while True:
        counts = Counter(px[x, y][:3] for y in range(h) for x in range(w) if px[x, y][3])
        if len(counts) <= n:
            return len(counts)
        cols = list(counts)
        rare = min(cols, key=lambda c: counts[c])
        target = min((c for c in cols if c != rare),
                     key=lambda c: sum((a - b) ** 2 for a, b in zip(c, rare)))
        for y in range(h):
            for x in range(w):
                if px[x, y][3] and px[x, y][:3] == rare:
                    px[x, y] = target + (255,)


def preview(im, path, scale=8):
    w, h = im.size
    big = im.resize((w * scale, h * scale), Image.NEAREST)
    out = Image.new("RGBA", (w * scale * 2 + scale, h * scale), (0, 0, 0, 0))
    out.paste(Image.new("RGBA", big.size, (24, 20, 40, 255)), (0, 0))
    out.paste(Image.new("RGBA", big.size, (225, 225, 230, 255)), (w * scale + scale, 0))
    out.alpha_composite(big, (0, 0))
    out.alpha_composite(big, (w * scale + scale, 0))
    out.save(path)


def main(argv):
    src, dst = argv[0], argv[1]
    max_colors = 30
    prev = None
    if "--max-colors" in argv:
        max_colors = int(argv[argv.index("--max-colors") + 1])
    if "--preview" in argv:
        prev = argv[argv.index("--preview") + 1]
    im = Image.open(src).convert("RGBA")
    cleared = clear_background(im)
    snap_alpha(im)
    ncol = reduce_colours(im, max_colors)
    im.save(dst)
    if prev:
        preview(im, prev)
    print(f"cleared {cleared} background px, {ncol} colours -> {dst}")


if __name__ == "__main__":
    main(sys.argv[1:])
