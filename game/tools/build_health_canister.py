#!/usr/bin/env python3
"""Builds the health drop's final art from T-221's PixelLab sample (free script, no PixelLab).

Usage, from the repo root:  python game/tools/build_health_canister.py [--width 14]

Three fixes on the board-approved raw sample (art-archive/T-221/canister_raw.png):
1. the blobby white mark is painted over with the body red and redrawn as a clean
   plus-shaped cross;
2. the darkest red (close to Redgull's red, style_rules.REDGULL_RED) is moved to a lighter,
   warmer red, so no colour is within MIN_REDGULL_DISTANCE of Redgull's red;
3. the sprite is cut to its bounding box and scaled down to about a coin's size by
   taking, for each output pixel, the most common colour of the source block
   (nearest-neighbour style: no new colours, no semi-transparent pixels).
Writes game/art/effects/health_canister.png (+ .json record).
"""
import argparse
import json
import sys
from collections import Counter
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from style_rules import REDGULL_RED, rgb_distance  # noqa: E402  (Visual style rule 6)

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "art-archive" / "T-221" / "canister_raw.png"
OUT = ROOT / "game" / "art" / "effects" / "health_canister.png"
MIN_REDGULL_DISTANCE = 45.0  # 0..255 RGB distance every colour keeps from the logo's red
WHITE = (253, 248, 245)
OUTLINE = (23, 14, 14)
OUTLINE_WEIGHT = 2.2
DARK_RED_FROM = (143, 37, 30)
DARK_RED_TO = (170, 56, 40)
BODY_RED = (192, 67, 62)


def is_whiteish(p):
    return p[3] == 255 and min(p[:3]) > 140 and max(p[:3]) - min(p[:3]) < 40


def clean(raw):
    """Fix 1 and 2 on the full-size sample; returns (image, cross centre)."""
    im = raw.convert("RGBA")
    w, h = im.size
    px = im.load()
    whites = [(x, y) for y in range(h) for x in range(w) if is_whiteish(px[x, y]) and px[x, y][:3] == WHITE]
    cx = round(sum(x for x, _ in whites) / len(whites))
    cy = round(sum(y for _, y in whites) / len(whites))
    for x, y in whites:
        px[x, y] = BODY_RED + (255,)
    for y in range(h):
        for x in range(w):
            if px[x, y][:3] == DARK_RED_FROM and px[x, y][3] == 255:
                px[x, y] = DARK_RED_TO + (255,)
    return im, (cx, cy)


def downscale(im, out_w):
    """Most-common-colour block scaling of the opaque bounding box; transparent wins ties."""
    box = im.getbbox()
    im = im.crop(box)
    w, h = im.size
    out_h = max(1, round(h * out_w / w))
    out = Image.new("RGBA", (out_w, out_h), (0, 0, 0, 0))
    src = im.load()
    for oy in range(out_h):
        for ox in range(out_w):
            x0, x1 = ox * w // out_w, max(ox * w // out_w + 1, (ox + 1) * w // out_w)
            y0, y1 = oy * h // out_h, max(oy * h // out_h + 1, (oy + 1) * h // out_h)
            cnt = Counter(src[x, y] for y in range(y0, y1) for x in range(x0, x1))
            opaque = {p: n for p, n in cnt.items() if p[3] == 255}
            if sum(opaque.values()) * 2 > sum(cnt.values()):
                # The thin outline would vanish under a plain majority, so it counts double.
                score = {p: n * (OUTLINE_WEIGHT if p[:3] == OUTLINE else 1.0) for p, n in opaque.items()}
                out.putpixel((ox, oy), max(score, key=score.get))
    return out, box


def draw_cross(im, centre):
    """Fix 1: a plus of five white pixels (three by three, no corners) at the centre."""
    cx, cy = centre
    for dx, dy in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)):
        im.putpixel((cx + dx, cy + dy), WHITE + (255,))
    return im


def build(raw, out_w):
    cleaned, (cx, cy) = clean(raw)
    small, box = downscale(cleaned, out_w)
    scale = out_w / (box[2] - box[0])
    centre = (round((cx - box[0]) * scale), round((cy - box[1]) * scale))
    return draw_cross(small, centre)


def opaque_colours(im):
    return {p[:3] for p in im.convert("RGBA").getdata() if p[3] == 255}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--width", type=int, default=14)
    args = ap.parse_args()
    out = build(Image.open(RAW), args.width)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.save(OUT)
    cols = opaque_colours(out)
    record = {
        "file": OUT.name, "task": "T-221", "source": "art-archive/T-221/canister_raw.png",
        "generator": "game/tools/build_health_canister.py", "image": {"width": out.width, "height": out.height},
        "colours": sorted("#%02x%02x%02x" % c for c in cols),
        "min_distance_to_redgull_red": round(min(rgb_distance(c, REDGULL_RED) for c in cols), 1),
        "notes": "Free script on the board-approved raw sample: white mark redrawn as a plus, darkest red moved away from Redgull's red, scaled down by block majority. No PixelLab.",
    }
    OUT.with_suffix(".json").write_text(json.dumps(record, indent=2) + "\n")
    print(out.size, len(cols), "colours; min distance to Redgull red", record["min_distance_to_redgull_red"])


if __name__ == "__main__":
    main()
