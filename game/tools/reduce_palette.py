"""Reduce a sprite's palette and make review previews, with no new pixels.

Usage (from the repo root):
  python game/tools/reduce_palette.py reduce IN.png OUT.png [--max-colors 30]
  python game/tools/reduce_palette.py preview IN.png OUT.png [--scale 4]

reduce: maps the opaque colours of IN onto at most --max-colors of its own
colours. It repeatedly takes the least-used colour and merges it into the
nearest remaining colour (RGB distance; ties broken by colour value), so every
output colour already exists in the input and the most-used colours are kept.
Alpha is left as it is. The result is the same every run.

preview: the sprite enlarged with nearest-neighbour, on a dark and a light
background side by side (for the board's review).
"""
import argparse

from PIL import Image

DARK_BG = (24, 20, 38, 255)
LIGHT_BG = (232, 232, 236, 255)


def reduce_mapping(counts, max_colors):
    """counts: {rgb: pixel count}. Returns {rgb: kept rgb}."""
    kept = dict(counts)
    mapping = {c: c for c in counts}
    while len(kept) > max_colors:
        victim = min(kept, key=lambda c: (kept[c], c))
        n = kept.pop(victim)
        target = min(kept, key=lambda c: (sum((a - b) ** 2 for a, b in zip(c, victim)), c))
        kept[target] += n
        for c, m in mapping.items():
            if m == victim:
                mapping[c] = target
    return mapping


def reduce_image(im, max_colors=30):
    im = im.convert("RGBA")
    px = list(im.getdata())
    counts = {}
    for r, g, b, a in px:
        if a > 0:
            counts[(r, g, b)] = counts.get((r, g, b), 0) + 1
    mapping = reduce_mapping(counts, max_colors)
    out = Image.new("RGBA", im.size)
    out.putdata([(mapping[(r, g, b)] + (a,)) if a > 0 else (r, g, b, a) for r, g, b, a in px])
    return out


def preview_image(im, scale=4):
    im = im.convert("RGBA")
    big = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    pad = 2 * scale
    out = Image.new("RGBA", (big.width * 2 + pad * 4, big.height + pad * 2))
    for i, bg in enumerate((DARK_BG, LIGHT_BG)):
        x = pad + i * (big.width + pad * 2)
        panel = Image.new("RGBA", (big.width + pad * 2, big.height + pad * 2), bg)
        out.paste(panel, (x - pad, 0))
        out.paste(big, (x, pad), big)
    return out


def main(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("reduce")
    r.add_argument("src")
    r.add_argument("dst")
    r.add_argument("--max-colors", type=int, default=30)
    p = sub.add_parser("preview")
    p.add_argument("src")
    p.add_argument("dst")
    p.add_argument("--scale", type=int, default=4)
    a = ap.parse_args(argv)
    src = Image.open(a.src)
    if a.cmd == "reduce":
        reduce_image(src, a.max_colors).save(a.dst)
    else:
        preview_image(src, a.scale).save(a.dst)
    print("saved", a.dst)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
