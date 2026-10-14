#!/usr/bin/env python3
"""Builds the comic-style trick popup art (task T-084; no PixelLab call).

A popup is one baked image: a jagged comic burst sized to fit its text, with
the text lettered in Bangers (game/fonts/bangers/, SIL OFL 1.1) rendered with
anti-aliasing off, so the letters have hard pixel edges. One popup pixel is
meant to be shown as 2 art pixels (task T-084 plan, point 4).

Look (T-084 plan, point 5; Visual style, Decisions: night neon palette, glow in
the pixels, hard edges, no semi-transparent pixels, no Redgull red):
- trick name: hot pink, a white-hot top row and a darker pink bottom row;
- amount ("+0.25"): cyan, with a light top row and a darker bottom row;
- both: a navy outline and a deep purple drop shadow down-right;
- burst: dark navy fill, a stepped cyan edge (bright cyan outside, darker cyan
  inside) and a black outline.

This round only builds the free sample for the board (no game code uses it yet):
  python game/tools/build_trick_popup.py sample   # writes art-archive/T-084/ files
  python game/tools/build_trick_popup.py check    # checks the written sample (exit 1 on a fail)

Needs Pillow (to rasterise the TrueType font). Running sample twice gives
byte-identical files.
"""
from __future__ import annotations

import argparse
import json
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_sprite_rules as rules  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
ROOT = GAME.parent
FONT_PATH = GAME / "fonts" / "bangers" / "Bangers-Regular.ttf"
ARCHIVE = ROOT / "art-archive" / "T-084"
SAMPLE_PNG = ARCHIVE / "trick_popup_sample.png"
SAMPLE_JSON = ARCHIVE / "trick_popup_sample.json"

MAX_COLORS = 30
# Redgull red, as the HUD heart draws it (scripts/hud/hud.gd, HEART_COLOR = Color(0.86, 0.1, 0.16)).
REDGULL_RED = (219, 26, 41)
MIN_RED_DISTANCE = 0.5  # 0..1 RGB distance every colour keeps from the heart red

PALETTE = {
    # burst
    "burst_outline": (6, 4, 14),
    "burst_edge": (0, 229, 255),
    "burst_edge_dark": (0, 120, 190),
    "burst_fill": (20, 16, 52),
    # lettering
    "text_outline": (14, 18, 58),
    "text_shadow": (58, 18, 92),
    "name_top": (255, 236, 250),
    "name": (255, 64, 200),
    "name_bottom": (150, 30, 170),
    "amount_top": (210, 255, 255),
    "amount": (0, 229, 255),
    "amount_bottom": (0, 140, 200),
}

# Per size: font pixel size, text outline and shadow thickness, burst spikes.
STYLES = {
    "normal": {"font_px": 35, "outline": 2, "shadow": 2, "spike": (10, 16), "spacing": 26, "flat": 1.0},
    "small": {"font_px": 20, "outline": 1, "shadow": 1, "spike": (5, 9), "spacing": 22, "flat": 0.8},
}
SUPERELLIPSE_N = 4.0  # how boxy the burst's base shape is (2 = oval)
EDGE = 3  # burst outline + bright edge + dark edge, in pixels
SEED = 84
BASE_SAMPLES = 1440  # points on the burst's base curve before the spikes go on

# Preview: popups enlarged this many times, on these two backgrounds.
PREVIEW_SCALE = 4
PREVIEW_BG = {"dark": (12, 10, 30), "light": (226, 228, 236)}
PREVIEW_PAD = 16


def split_text(text):
    """('FULL 360!', '+0.25') from 'FULL 360! +0.25'; amount is '' when there is none."""
    i = text.rfind(" +")
    if i < 0:
        return text, ""
    return text[:i], text[i + 1:]


def _mask(size, text, font, origin):
    img = Image.new("L", size, 0)
    d = ImageDraw.Draw(img)
    d.fontmode = "1"  # no anti-aliasing: every pixel is on or off
    d.text(origin, text, font=font, fill=255)
    return [[img.getpixel((x, y)) > 0 for x in range(size[0])] for y in range(size[1])]


def _dilate(m, r):
    """Square dilation by r pixels (a chunky comic outline)."""
    h, w = len(m), len(m[0])
    out = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if m[y][x]:
                for yy in range(max(0, y - r), min(h, y + r + 1)):
                    row = out[yy]
                    for xx in range(max(0, x - r), min(w, x + r + 1)):
                        row[xx] = True
    return out


def _erode_cross(m):
    """Keeps pixels whose 4 neighbours are all set (a one-pixel ring comes off)."""
    h, w = len(m), len(m[0])
    out = [[False] * w for _ in range(h)]
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            out[y][x] = m[y][x] and m[y - 1][x] and m[y + 1][x] and m[y][x - 1] and m[y][x + 1]
    return out


def _dilate_cross(m):
    h, w = len(m), len(m[0])
    out = [row[:] for row in m]
    for y in range(h):
        for x in range(w):
            if m[y][x]:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if 0 <= x + dx < w and 0 <= y + dy < h:
                        out[y + dy][x + dx] = True
    return out


def letter_text(text, size="normal"):
    """The lettering alone: (rows of colour names or None, (w, h)), cropped tight."""
    st = STYLES[size]
    font = ImageFont.truetype(str(FONT_PATH), st["font_px"])
    name, amount = split_text(text)
    pad = st["outline"] + st["shadow"] + 2
    left, top, right, bottom = font.getbbox(text)
    w = right - left + 2 * pad
    h = bottom - top + 2 * pad
    origin = (pad - left, pad - top)
    full = _mask((w, h), text, font, origin)
    name_m = _mask((w, h), name, font, origin)
    outline = _dilate(full, st["outline"])
    s = st["shadow"]
    rows = [[None] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if y - s >= 0 and x - s >= 0 and outline[y - s][x - s]:
                rows[y][x] = "text_shadow"
    for y in range(h):
        for x in range(w):
            if outline[y][x]:
                rows[y][x] = "text_outline"
    for y in range(h):
        for x in range(w):
            if not full[y][x]:
                continue
            base = "name" if name_m[y][x] else "amount"
            above = y > 0 and full[y - 1][x]
            below = y < h - 1 and full[y + 1][x]
            if not above:
                rows[y][x] = base + "_top"
            elif not below:
                rows[y][x] = base + "_bottom"
            else:
                rows[y][x] = base
    return _crop(rows)


def _crop(rows):
    ys = [y for y, r in enumerate(rows) if any(r)]
    xs = [x for x in range(len(rows[0])) if any(r[x] for r in rows)]
    rows = [r[xs[0]:xs[-1] + 1] for r in rows[ys[0]:ys[-1] + 1]]
    return rows, (len(rows[0]), len(rows))


def burst_polygon(text_w, text_h, size="normal", seed=SEED):
    """The burst's jagged outline around a text box centred on (0, 0)."""
    st = STYLES[size]
    k = 2 ** (1 / SUPERELLIPSE_N)  # a box of half-size (w, h) fits in a superellipse of (k w, k h)
    a = (text_w / 2) * k + EDGE + 1
    b = (text_h / 2) * k * st["flat"] + EDGE + 1
    b = max(b, text_h / 2 + EDGE + 1)
    # Sample the base curve densely, then place the points evenly by arc length,
    # so long flat sides get as many spikes as the rounded ends.
    e = 2 / SUPERELLIPSE_N
    base = []
    for j in range(BASE_SAMPLES):
        t = 2 * math.pi * j / BASE_SAMPLES
        c, s = math.cos(t), math.sin(t)
        base.append((a * math.copysign(abs(c) ** e, c), b * math.copysign(abs(s) ** e, s)))
    cum = [0.0]
    for j in range(1, BASE_SAMPLES + 1):
        p0, p1 = base[j - 1], base[j % BASE_SAMPLES]
        cum.append(cum[-1] + math.hypot(p1[0] - p0[0], p1[1] - p0[1]))
    perimeter = cum[-1]
    spikes = max(8, int(round(perimeter / st["spacing"])))
    rnd = random.Random("%s|%d|%d|%s" % (seed, text_w, text_h, size))
    lo, hi = st["spike"]
    pts = []
    j = 0
    for i in range(2 * spikes):
        target = perimeter * (i + rnd.uniform(-0.15, 0.15)) / (2 * spikes) % perimeter
        while not cum[j] <= target < cum[j + 1]:
            j = (j + 1) % BASE_SAMPLES
        bx, by = base[j]
        if i % 2 == 0:
            # Spike direction: half the outward normal, half straight out from the centre.
            p0, p1 = base[j - 1], base[(j + 1) % BASE_SAMPLES]
            nx, ny = p1[1] - p0[1], -(p1[0] - p0[0])
            nl = math.hypot(nx, ny) or 1.0
            rl = math.hypot(bx, by) or 1.0
            dx, dy = nx / nl + bx / rl, ny / nl + by / rl
            dl = math.hypot(dx, dy) or 1.0
            out = rnd.uniform(lo, hi)
            pts.append((bx + dx / dl * out, by + dy / dl * out))
        else:
            pts.append((bx, by))
    return pts


def _inside(poly, x, y):
    inside = False
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        if (y1 > y) != (y2 > y):
            if x < x1 + (y - y1) * (x2 - x1) / (y2 - y1):
                inside = not inside
    return inside


def build_popup(text, size="normal"):
    """One popup as rows of RGBA tuples (transparent background)."""
    letters, (tw, th) = letter_text(text, size)
    poly = burst_polygon(tw, th, size)
    max_x = max(abs(p[0]) for p in poly)
    max_y = max(abs(p[1]) for p in poly)
    w = 2 * int(math.ceil(max_x)) + 5  # + outline + a transparent border
    h = 2 * int(math.ceil(max_y)) + 5
    cx, cy = w / 2, h / 2
    fill = [[_inside(poly, x + 0.5 - cx, y + 0.5 - cy) for x in range(w)] for y in range(h)]
    outer = _dilate_cross(fill)
    e1 = _erode_cross(fill)
    e2 = _erode_cross(e1)
    names = [[None] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if e2[y][x]:
                names[y][x] = "burst_fill"
            elif e1[y][x]:
                names[y][x] = "burst_edge_dark"
            elif fill[y][x]:
                names[y][x] = "burst_edge"
            elif outer[y][x]:
                names[y][x] = "burst_outline"
    ox = (w - tw) // 2
    oy = (h - th) // 2
    for y in range(th):
        for x in range(tw):
            if letters[y][x]:
                names[oy + y][ox + x] = letters[y][x]
    return [[(PALETTE[n] + (255,)) if n else (0, 0, 0, 0) for n in row] for row in names], (ox, oy, tw, th), e2


def red_distance(c):
    return math.sqrt(sum(((a - b) / 255.0) ** 2 for a, b in zip(c, REDGULL_RED)))


def check_popup(rows, max_colors=MAX_COLORS):
    """Visual style's rules for one popup: list of (rule, ok, detail)."""
    h, w = len(rows), len(rows[0])
    results = [r for r in rules.check_rows(rows, size=w, max_colors=max_colors)[0] if not r[0].startswith("frame size")]
    border = rows[0] + rows[-1] + [r[0] for r in rows] + [r[-1] for r in rows]
    results.append(("transparent border", all(p[3] == 0 for p in border), ""))
    colours = {p[:3] for r in rows for p in r if p[3] == 255}
    near = [c for c in colours if red_distance(c) <= MIN_RED_DISTANCE]
    results.append(("no Redgull red", not near, str(near)))
    return results


def scale_nearest(rows, k):
    out = []
    for r in rows:
        big = [p for p in r for _ in range(k)]
        out.extend([list(big) for _ in range(k)])
    return out


SAMPLE = [("FULL 360! +0.25", "normal"), ("LONG DRIFT! +0.05", "small")]


def build_sample():
    """The board's preview: both popups enlarged, on a dark and a light panel side by side."""
    pops = [scale_nearest(build_popup(t, s)[0], PREVIEW_SCALE) for t, s in SAMPLE]
    pad = PREVIEW_PAD
    panel_w = sum(len(p[0]) for p in pops) + pad * (len(pops) + 1)
    panel_h = max(len(p) for p in pops) + 2 * pad
    rows = []
    for y in range(panel_h):
        row = []
        for bg in PREVIEW_BG.values():
            line = [bg + (255,)] * panel_w
            x = pad
            for p in pops:
                py = y - (panel_h - len(p)) // 2
                if 0 <= py < len(p):
                    for i, px in enumerate(p[py]):
                        if px[3] == 255:
                            line[x + i] = px
                x += len(p[0]) + pad
            row.extend(line)
        rows.append(row)
    return rows


def write_rows(rows, path):
    h, w = len(rows), len(rows[0])
    img = Image.new("RGBA", (w, h))
    img.putdata([p for r in rows for p in r])
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=False)


def sample_record():
    popups = []
    for t, s in SAMPLE:
        rows, (ox, oy, tw, th), _ = build_popup(t, s)
        popups.append({"text": t, "size": s, "font_px": STYLES[s]["font_px"],
                       "popup_px": [len(rows[0]), len(rows)], "text_box": [ox, oy, tw, th],
                       "file": "trick_popup_%s.png" % s})
    return {
        "what": "Free sample of the trick popups' comic look (task T-084), for the board's review. Not used in the game yet.",
        "made_by": "game/tools/build_trick_popup.py sample (a script; no PixelLab call). Byte-identical every run.",
        "font": "Bangers Regular 2.100 (game/fonts/bangers/, SIL OFL 1.1), rendered without anti-aliasing",
        "preview": "trick_popup_sample.png: the popups enlarged %dx (nearest neighbour), on a dark and a light background side by side" % PREVIEW_SCALE,
        "popups": popups,
        "palette": {k: list(v) for k, v in PALETTE.items()},
        "preview_backgrounds": {k: list(v) for k, v in PREVIEW_BG.items()},
    }


def cmd_sample():
    ARCHIVE.mkdir(parents=True, exist_ok=True)
    for t, s in SAMPLE:
        write_rows(build_popup(t, s)[0], ARCHIVE / ("trick_popup_%s.png" % s))
    write_rows(build_sample(), SAMPLE_PNG)
    SAMPLE_JSON.write_text(json.dumps(sample_record(), indent=1) + "\n", encoding="utf-8")
    print("wrote", SAMPLE_PNG)
    return 0


def cmd_check():
    ok = True
    for t, s in SAMPLE:
        path = ARCHIVE / ("trick_popup_%s.png" % s)
        with open(path, "rb") as f:
            _, _, rows = rules.decode_png(f.read())
        for rule, good, detail in check_popup(rows):
            print("%s %s: %s %s" % ("PASS" if good else "FAIL", path.name, rule, detail))
            ok = ok and good
    with open(SAMPLE_PNG, "rb") as f:
        _, _, rows = rules.decode_png(f.read())
    semi = sum(1 for r in rows for p in r if 0 < p[3] < 255)
    colours = {p[:3] for r in rows for p in r}
    near = [c for c in colours if red_distance(c) <= MIN_RED_DISTANCE]
    print("%s preview: no semi-transparent pixels (%d)" % ("PASS" if semi == 0 else "FAIL", semi))
    print("%s preview: no Redgull red %s" % ("PASS" if not near else "FAIL", near))
    print("     preview: %d colours in all, %dx%d" % (len(colours), len(rows[0]), len(rows)))
    ok = ok and semi == 0 and not near
    return 0 if ok else 1


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("command", choices=["sample", "check"])
    a = p.parse_args(argv)
    return cmd_sample() if a.command == "sample" else cmd_check()


if __name__ == "__main__":
    sys.exit(main())
