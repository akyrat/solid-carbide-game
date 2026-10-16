#!/usr/bin/env python3
"""Check a logo PNG (T-075): exactly one visible colour, a dark red, a transparent background
and no semi-transparent pixels. Usage: check_logo_one_colour.py <png>; exit 0 on pass."""
import sys
from PIL import Image


def check(im: Image.Image) -> list[str]:
    """Return a list of problems (empty = pass)."""
    im = im.convert("RGBA")
    px = list(im.getdata())
    problems = []
    if any(0 < p[3] < 255 for p in px):
        problems.append("semi-transparent pixels")
    visible = {p[:3] for p in px if p[3] == 255}
    if len(visible) != 1:
        problems.append(f"{len(visible)} visible colours (need 1)")
    else:
        r, g, b = next(iter(visible))
        if not (r > 100 and r > 2 * max(g, b) and r < 190):
            problems.append(f"colour {(r, g, b)} is not a dark red")
    if not any(p[3] == 0 for p in px):
        problems.append("no transparent pixels")
    if im.getpixel((0, 0))[3] != 0:
        problems.append("corner is not transparent")
    if not any(p[3] == 255 for p in px):
        problems.append("nothing visible")
    return problems


if __name__ == "__main__":
    probs = check(Image.open(sys.argv[1]))
    print("PASS" if not probs else "FAIL: " + "; ".join(probs))
    sys.exit(1 if probs else 0)
