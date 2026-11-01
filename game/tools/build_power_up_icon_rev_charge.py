#!/usr/bin/env python3
"""The Rev Charge power-up icon, script-drawn (task T-465, style loop; 0 PixelLab generations).

Version 1 (PixelLab pixflux) read as one round blob (Style Evaluator 5/10, rules 2 and 5). Version 2 redrew it
by script (7/10: needle and burst too small, shading flat, outline mostly unbroken, halos not stepped, under
28 x 28). This draws version 3 (`--v2` redraws version 2's layout for the record):
- a wheel seen from the side: dark rubber tyre with tread, a steel rim lip and a dark face with five thin spokes
  and a hub; strong top-left light (a bright band on the top-left of the tyre and rim, deep shade bottom-right);
- an amber rev ring inside the tyre, brightest at the top-right where the needle points;
- a big amber needle (2 px wide, pale tip) swung up to the right, with a stepped amber glow round it;
- a burst behind the wheel on the left: two large flame tongues (pale core, orange, dark ember tip) and three
  long cyan speed streaks stepped from dark teal to near-white;
- a near-black 1 px outline, broken on the top-left by every other pixel being a lighter highlight;
- a 2-step halo outside the outline (a mid shade, then a darker, sparser ring): amber on the right, cyan
  bottom-left;
- about 28 x 28, centred.
32 x 32, transparent background, opaque or empty pixels only, a fixed palette (< 30 colours), no Greenbull colours.

  python game/tools/build_power_up_icon_rev_charge.py <out.png> [--v2]   (refuses to overwrite)
"""
from __future__ import annotations

import math
import os
import sys

from PIL import Image

SIZE = 32

V3 = dict(cx=17.5, cy=16.0, r_tyre=10.0, r_ring=7.8, r_rim=6.8, r_face=5.8, r_hub=1.6,
          needle_angle=-50.0, needle_len=7.0, streak_rows=((8, 3), (16, 2), (24, 3)),
          flame_rows=(12, 20), flame_len=6, halo_steps=2, light_hi=0.3, out_hi=0.45, needle_glow=True)
V4 = dict(cx=19.5, cy=16.0, tail_back=3.0, r_tyre=8.6, r_ring=6.7, r_rim=5.8, r_face=4.9, r_hub=1.4,
          needle_angle=-50.0, needle_len=6.0, streak_rows=(), flame_rows=(), flame_len=0,
          halo_steps=2, light_hi=0.3, out_hi=0.4, needle_glow=True, wheel_cyan_halo=False,
          tail=True, tail_tip=2.0, tail_lines=(-3, 3))
V2 = dict(cx=19.0, cy=16.0, r_tyre=9.5, r_ring=7.4, r_rim=6.5, r_face=5.5, r_hub=1.6,
          needle_angle=-50.0, needle_len=6.2, streak_rows=((10, 4), (16, 2), (22, 5)),
          flame_rows=(13, 19), flame_len=4, halo_steps=1, light_hi=0.45, out_hi=0.7, needle_glow=False,
          needle_steps=24, cyan_halo="v2", halo_inner=1.0, halo_adj8=True, tread_lit=True, no_ember=True,
          pal={"out_hi": (96, 112, 142), "tyre_hi": (74, 80, 104), "tyre": (40, 42, 58), "tyre_lo": (26, 26, 38),
               "tread": (56, 60, 80), "rim_hi": (206, 218, 234), "rim_lo": (82, 94, 120), "fl_core": (255, 200, 92),
               "halo_amber": (112, 56, 16), "halo_cyan": (18, 74, 98)})

LATEST = V4

P = {
    "out": (14, 12, 24),
    "out_hi": (110, 128, 160),
    "tyre_hi": (86, 94, 122),
    "tyre": (44, 46, 64),
    "tyre_lo": (24, 24, 36),
    "tread": (60, 64, 86),
    "ring_hi": (255, 196, 84),
    "ring": (236, 140, 34),
    "ring_lo": (168, 84, 20),
    "rim_hi": (214, 226, 240),
    "rim": (142, 158, 184),
    "rim_lo": (74, 86, 112),
    "face": (24, 28, 46),
    "spoke_hi": (150, 166, 192),
    "spoke": (100, 114, 142),
    "hub": (226, 234, 244),
    "needle": (255, 178, 52),
    "needle_tip": (255, 236, 176),
    "needle_glow": (138, 66, 16),
    "cy_hi": (214, 250, 255),
    "cy": (96, 226, 250),
    "cy_mid": (36, 160, 196),
    "cy_lo": (22, 88, 116),
    "fl_core": (255, 214, 120),
    "fl": (240, 118, 26),
    "fl_ember": (150, 58, 14),
    "halo_amber": (126, 62, 16),
    "halo_amber2": (72, 36, 14),
    "halo_cyan": (22, 96, 124),
    "halo_cyan2": (16, 56, 76),
}


def _light(dx: float, dy: float, d: float) -> float:
    """+1 facing the top-left light, -1 facing away."""
    return -(dx + dy) / (math.sqrt(2) * d) if d else 0.0


def _shade(l: float, cut: float, hi: str, mid: str, lo: str) -> str:
    return hi if l > cut else lo if l < -cut else mid


def _angle_off(a: float, b: float) -> float:
    return abs(((a - b + 180) % 360) - 180)


def _draw_tail(px: dict, v: dict) -> None:
    """Version 4's burst: a flame tail behind the wheel (left), widest at the wheel and licking to a point,
    stepped from a pale core through amber and orange to a dark ember edge, then a dark-teal halo; two cyan
    speed lines run through it and end in near-white heads at the wheel. It leaves a 1 px gap round the wheel
    for the wheel's outline."""
    cx, cy, r = v["cx"], v["cy"], v["r_tyre"]
    x_tip, x_w = v["tail_tip"], cx - r
    W = r + 0.3
    for y in range(SIZE):
        for x in range(SIZE):
            xc, yc = x + 0.5, y + 0.5
            if xc >= cx - v.get("tail_back", 0.0) or (x, y) in px:
                continue
            if math.hypot(xc - cx, yc - cy) <= r + 1.0:
                continue  # room for the wheel's outline
            if xc < x_tip:
                continue
            f = min(1.0, (xc - x_tip) / (x_w - x_tip))
            w = W * f ** 0.75 + (0.9 if x % 3 == 0 and f < 0.95 else 0.0)  # flame licks
            e = w - abs(yc - cy)
            if e > 3.6:
                k = "fl_core"
            elif e > 2.2:
                k = "ring_hi"
            elif e > 1.0:
                k = "fl"
            elif e > 0:
                k = "fl_ember"
            elif e > -1.0:
                k = "halo_cyan"
            else:
                continue
            px[(x, y)] = k
    # cyan speed lines through the flame, bright head at the wheel
    for off in v["tail_lines"]:
        y = int(cy + off)
        xs = sorted(x for (x, yy), k in px.items() if yy == y and x < cx - r and k in ("fl_core", "ring_hi", "fl"))
        n = len(xs)
        for i, x in enumerate(xs):
            g = i / max(n - 1, 1)
            px[(x, y)] = "cy_mid" if g < 0.35 else "cy" if g < 0.85 else "cy_hi"


def draw(v: dict = V3) -> Image.Image:
    cx, cy = v["cx"], v["cy"]
    px: dict[tuple[int, int], str] = {}
    for y in range(SIZE):
        for x in range(SIZE):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            d = math.hypot(dx, dy)
            if d > v["r_tyre"]:
                continue
            ang = math.degrees(math.atan2(dy, dx))
            l = _light(dx, dy, d)
            if d <= v["r_hub"]:
                px[(x, y)] = "hub"
            elif d <= v["r_face"]:
                spoke = min(_angle_off(ang, a) for a in (-90, -18, 54, 126, 198))
                px[(x, y)] = ("spoke_hi" if l > 0 else "spoke") if spoke < 10 else "face"
            elif d <= v["r_rim"]:
                px[(x, y)] = _shade(l, v["light_hi"], "rim_hi", "rim", "rim_lo")
            elif d <= v["r_ring"]:
                off = _angle_off(ang, v["needle_angle"])
                px[(x, y)] = "ring_hi" if off < 40 else "ring" if off < 110 else "ring_lo"
            else:
                tread = int((ang + 180) / 20) % 2 == 0 and d > v["r_tyre"] - 1.2
                if tread and -v["light_hi"] <= l <= (1.0 if v.get("tread_lit") else v["light_hi"]):
                    px[(x, y)] = "tread"
                else:
                    px[(x, y)] = _shade(l, v["light_hi"], "tyre_hi", "tyre", "tyre_lo")
    # needle
    na = math.radians(v["needle_angle"])
    needle: dict[tuple[int, int], str] = {}
    steps = v.get("needle_steps", 40)
    for i in range(steps + 1):
        t = i / steps * v["needle_len"]
        x, y = int(cx + t * math.cos(na)), int(cy + t * math.sin(na))
        if math.hypot(x + 0.5 - cx, y + 0.5 - cy) > v["r_hub"]:
            tip = t > v["needle_len"] - 1.6
            needle[(x, y)] = "needle_tip" if tip else "needle"
            if 2.0 < t and not tip:
                needle.setdefault((x - 1, y), "needle")
    for (x, y) in needle:
        for a, b in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            q = (x + a, y + b)
            if q not in needle and px.get(q) in ("spoke", "spoke_hi", "face"):
                px[q] = "needle_glow" if v["needle_glow"] else "face"
    px.update(needle)
    wheel = set(px)
    if v.get("tail"):
        _draw_tail(px, v)
    # speed streaks (left), ending at the wheel's outline
    for row, start in v["streak_rows"]:
        xs = [x for x in range(start, SIZE) if x < cx and (x + 1, row) not in wheel and (x + 2, row) not in wheel]
        n = len(xs)
        for i, x in enumerate(xs):
            f = i / max(n - 1, 1)
            px[(x, row)] = "cy_lo" if f < 0.25 else "cy_mid" if f < 0.55 else "cy" if f < 0.9 else "cy_hi"
    # flame tongues between the streaks, pointing left
    L = v["flame_len"]
    for row in v["flame_rows"]:
        edge = min(x for (x, y) in wheel if y == row) - 1
        for y, length in ((row - 1, L - 2), (row, L), (row + 1, L - 2)):
            for i in range(length):
                core = (y == row and i < L // 2) or (y != row and i < (L - 2) // 3)
                ember = i == length - 1 and length > 2 and not v.get("no_ember")
                px[(edge - i, y)] = "fl_core" if core else "fl_ember" if ember else "fl"
    shape = set(px)
    # outline, broken by highlight pixels on the top-left
    outline = set()
    for y in range(SIZE):
        for x in range(SIZE):
            if (x, y) in shape:
                continue
            if any((x + a, y + b) in shape for a in (-1, 0, 1) for b in (-1, 0, 1)):
                outline.add((x, y))
                dx, dy = x + 0.5 - cx, y + 0.5 - cy
                d = math.hypot(dx, dy)
                top_left = _light(dx, dy, d) > v["out_hi"] and d < v["r_tyre"] + 2
                px[(x, y)] = "out_hi" if top_left and (x + y) % 2 == 0 else "out"
    # stepped halo around the wheel (not the streaks): amber right, cyan bottom-left
    ring_prev = outline
    for step in range(v["halo_steps"]):
        new = set()
        for y in range(SIZE):
            for x in range(SIZE):
                if (x, y) in px:
                    continue
                dx, dy = x + 0.5 - cx, y + 0.5 - cy
                d = math.hypot(dx, dy)
                if not (v["r_tyre"] + v.get("halo_inner", 0.8) < d <= v["r_tyre"] + 2.6 + step):
                    continue
                nbrs = (((a, b) for a in (-1, 0, 1) for b in (-1, 0, 1)) if v.get("halo_adj8")
                        else ((1, 0), (-1, 0), (0, 1), (0, -1)))
                if not any((x + a, y + b) in ring_prev for a, b in nbrs):
                    continue
                if step and abs(dy) > v["r_tyre"] - 1:
                    continue  # the outer step is a shorter arc, not a full ring
                if dx > 2:
                    new.add((x, y)); px[(x, y)] = "halo_amber2" if step else "halo_amber"
                elif v.get("wheel_cyan_halo", True) and dx < -2 and (_light(dx, dy, d) < 0.7 if v.get("cyan_halo") == "v2" else dy > 2):
                    new.add((x, y)); px[(x, y)] = "halo_cyan2" if step else "halo_cyan"
        ring_prev = new
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    pal = {**P, **v.get("pal", {})}
    for (x, y), k in px.items():
        if 0 <= x < SIZE and 0 <= y < SIZE:
            im.putpixel((x, y), pal[k] + (255,))
    return im


def main(argv: list[str]) -> int:
    versions = {"--v2": V2, "--v3": V3, "--v4": V4}
    args = [a for a in argv if a not in versions]
    if len(args) != 1:
        print(__doc__)
        return 2
    out = args[0]
    if os.path.exists(out):
        print(f"{out} exists: never overwrite an earlier version")
        return 1
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    picked = [versions[a] for a in argv if a in versions]
    im = draw(picked[0] if picked else LATEST)
    im.save(out)
    cols = {p for p in im.getdata() if p[3]}
    print(f"saved {out}: {len(cols)} colours, bbox {im.getbbox()}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
