"""Build a review image: frames side by side, enlarged with nearest-neighbour, on a background.

Usage: python review_sheet.py OUT.png --bg dark|light|R,G,B --scale N
           SRC.png[:FRAME:FRAMEW] [SRC.png[:FRAME:FRAMEW] ...]
A source without ':FRAME:FRAMEW' is used whole. Frames are never resized relative to each other.
"""
import argparse
from PIL import Image

BGS = {"dark": (24, 26, 40), "light": (225, 225, 230)}


def load_frame(spec):
    parts = spec.rsplit(":", 2)
    if len(parts) == 3 and parts[1].isdigit() and parts[2].isdigit():
        path, idx, w = parts[0], int(parts[1]), int(parts[2])
        im = Image.open(path).convert("RGBA")
        return im.crop((idx * w, 0, (idx + 1) * w, im.height))
    return Image.open(spec).convert("RGBA")


def build_sheet(specs, bg, scale, gap=8):
    frames = [load_frame(s) for s in specs]
    w = sum(f.width for f in frames) + gap * (len(frames) + 1)
    h = max(f.height for f in frames) + 2 * gap
    sheet = Image.new("RGBA", (w, h), tuple(bg) + (255,))
    x = gap
    for f in frames:
        sheet.alpha_composite(f, (x, h - gap - f.height))  # bottoms aligned
        x += f.width + gap
    return sheet.resize((w * scale, h * scale), Image.NEAREST)


def parse_bg(text):
    if text in BGS:
        return BGS[text]
    return tuple(int(v) for v in text.split(","))


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("sources", nargs="+")
    ap.add_argument("--bg", default="dark")
    ap.add_argument("--scale", type=int, default=4)
    a = ap.parse_args(argv)
    build_sheet(a.sources, parse_bg(a.bg), a.scale).save(a.out)


if __name__ == "__main__":
    main()
