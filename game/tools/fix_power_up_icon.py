"""Free script fixes for the T-465 icons (style loop, before any paid refine).

usage: python icon_fix.py <in.png> <out.png> [--colors 30] [--preview <prefix>]

- Clears near-black background pixels connected to the image border (flood fill),
  so the background is transparent.
- Quantizes opaque pixels to at most N colours (median cut, no dithering).
- Alpha is forced to 0 or 255. Writes 8-bit RGBA.
- --preview writes 8x nearest-neighbour previews on dark and light backgrounds.
"""
import argparse
from collections import deque

from PIL import Image


def clear_border_background(im, thresh=40):
    w, h = im.size
    px = im.load()
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
        if a == 0 or max(r, g, b) < thresh:
            if a:
                cleared += 1
            px[x, y] = (0, 0, 0, 0)
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q.append((x + dx, y + dy))
    return cleared


def quantize(im, n):
    alpha = im.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    rgb = im.convert("RGB").quantize(colors=n, method=Image.Quantize.MEDIANCUT,
                                     dither=Image.Dither.NONE).convert("RGB")
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            if px[x, y][3] == 0:
                px[x, y] = (0, 0, 0, 0)
    return out


def preview(im, prefix, scale=8):
    big = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    for bg, name in (((20, 20, 28, 255), "dark"), ((230, 230, 230, 255), "light")):
        b = Image.new("RGBA", big.size, bg)
        b.alpha_composite(big)
        b.save(f"{prefix}_{name}.png")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--colors", type=int, default=30)
    ap.add_argument("--preview")
    a = ap.parse_args()
    im = Image.open(a.src).convert("RGBA")
    cleared = clear_border_background(im)
    # quantize with fewer than the limit to leave room; count opaque colours after
    out = quantize(im, a.colors)
    cols = {p for p in out.getdata() if p[3] == 255}
    import os
    if os.path.exists(a.dst):
        raise SystemExit(f"{a.dst} exists: never overwrite an earlier version")
    os.makedirs(os.path.dirname(a.dst) or ".", exist_ok=True)
    out.save(a.dst)
    print(f"cleared {cleared} border pixels, {len(cols)} colours, bbox {out.getbbox()}")
    if a.preview:
        preview(out, a.preview)


if __name__ == "__main__":
    main()
