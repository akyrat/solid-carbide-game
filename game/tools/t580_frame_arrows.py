#!/usr/bin/env python3
"""Task T-580 (investigation): a contact sheet of the 32 isometric car frames, each with two arrows
from the car's centre pixel: green = where the nose should point on screen for the frame's world
heading (the run's 2:1 projection, car_iso.json nose_screen_angle_deg), orange = where the drawing's
nose was measured to point (seen_nose_screen_angle_deg_approx, T-102). The gap between the two is
the art's own share of "the car points one way and moves another" while driving straight.

Usage (from the repo root):
    python game/tools/t580_frame_arrows.py [--out art-archive/T-580/screenshots/frames_vs_ideal_arrow.png]
Reads only game/art/car/car_iso.png and .json; writes only the output PNG.
"""
import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

GAME = Path(__file__).resolve().parents[1]
SHEET = GAME / "art" / "car" / "car_iso.png"
LAYOUT = GAME / "art" / "car" / "car_iso.json"

GREEN = (60, 230, 90, 255)
ORANGE = (255, 150, 30, 255)


def wrap180(a):
    return (a + 180.0) % 360.0 - 180.0


def arrow(draw, cx, cy, deg, length, colour, width=3):
    r = math.radians(deg)
    ex, ey = cx + math.cos(r) * length, cy + math.sin(r) * length
    draw.line([(cx, cy), (ex, ey)], fill=colour, width=width)
    for side in (150, -150):
        h = math.radians(deg + side)
        draw.line([(ex, ey), (ex + math.cos(h) * 12, ey + math.sin(h) * 12)], fill=colour, width=width)


def build(out, scale=2, cols=8, bg=(70, 72, 80, 255)):
    sheet = Image.open(SHEET).convert("RGBA")
    layout = json.loads(LAYOUT.read_text(encoding="utf-8"))
    fw, fh = int(layout["frame_width"]), int(layout["frame_height"])
    cxp, cyp = float(layout["center_px"]["x"]), float(layout["center_px"]["y"])
    frames = layout["frames"]
    rows = math.ceil(len(frames) / cols)
    cell_w, cell_h = fw * scale, fh * scale + 34
    img = Image.new("RGBA", (cols * cell_w, rows * cell_h), bg)
    draw = ImageDraw.Draw(img)
    gaps = []
    for f in frames:
        i = int(f["index"])
        fr = sheet.crop((i * fw, 0, (i + 1) * fw, fh)).resize((fw * scale, fh * scale), Image.NEAREST)
        ox, oy = (i % cols) * cell_w, (i // cols) * cell_h
        img.alpha_composite(fr, (ox, oy))
        cx, cy = ox + cxp * scale, oy + cyp * scale
        ideal = float(f["nose_screen_angle_deg"])
        seen = float(f["seen_nose_screen_angle_deg_approx"])
        arrow(draw, cx, cy, ideal, 105, GREEN)
        arrow(draw, cx, cy, seen, 80, ORANGE, 2)
        gap = wrap180(seen - ideal)
        gaps.append((i, float(f["heading_deg"]), ideal, seen, gap))
        colour = (255, 90, 90, 255) if abs(gap) >= 15 else (235, 235, 235, 255)
        draw.text((ox + 4, oy + fh * scale + 2), "f%d  world %.1f" % (i, float(f["heading_deg"])), fill=(235, 235, 235, 255))
        draw.text((ox + 4, oy + fh * scale + 16), "should %.0f  drawn %.0f  gap %+.0f" % (ideal % 360, seen % 360, gap), fill=colour)
    out = Path(out)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    return gaps


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", default=str(GAME.parent / "art-archive" / "T-580" / "screenshots" / "frames_vs_ideal_arrow.png"))
    args = ap.parse_args()
    for i, h, ideal, seen, gap in build(args.out):
        print("frame %2d world %6.2f should %6.1f drawn %6.1f gap %+6.1f" % (i, h, ideal, seen, gap))
    print("wrote", args.out)


if __name__ == "__main__":
    main()
