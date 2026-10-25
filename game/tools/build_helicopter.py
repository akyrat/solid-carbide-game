#!/usr/bin/env python3
"""Builds the Redgull helicopter sprite sheet from the approved PixelLab sample (task T-145).

No PixelLab call: every step is a script on the approved sample
(art-archive/T-145/helicopter_sample.png). It
- mirrors the sample (the sample's nose points down-left; the helicopter flies left to right),
- recolours the charcoal body to Redgull red (the logo's red, style_rules.REDGULL_RED, at the middle of the ramp),
- erases the four static rotor blades and draws them again, turned a step per frame (4 frames),
- stamps the approved Redgull logo (game/art/logo/) on a pale panel on the fuselage side and the tail fin.

    python game/tools/build_helicopter.py build   # writes game/art/gift_pack/helicopter_sheet.png and its record
    python game/tools/build_helicopter.py check
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from style_rules import REDGULL_RED  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SAMPLE = ROOT / "art-archive" / "T-145" / "helicopter_sample.png"
LOGO = ROOT / "game" / "art" / "logo" / "redgull_logo_32.png"
OUT_DIR = ROOT / "game" / "art" / "gift_pack"
SHEET = OUT_DIR / "helicopter_sheet.png"
FRAME_FILES = [OUT_DIR / f"helicopter_{i}.png" for i in range(4)]
RECORD = OUT_DIR / "helicopter_sheet.json"

W, H = 192, 160
FRAMES = 4
LOGO_RED = REDGULL_RED
# Red ramp, dark to light, around the logo's red.
RAMP = [(52, 6, 14), (86, 11, 20), (112, 14, 24), LOGO_RED, (166, 28, 36), (198, 52, 50), (232, 120, 104)]
PANEL = (226, 220, 224)
PANEL_SHADE = (176, 168, 178)
OUTLINE = (5, 4, 8)
STRIPE = (30, 25, 57)
BLADE = (54, 54, 82)
BLADE_LIGHT = (91, 93, 112)

# Hub and blade directions of the MIRRORED sample (found by eye on the sample).
HUB = (101, 60)
U = (49.0, -28.0)   # one blade axis on screen, in pixels
V = (47.0, 29.0)    # the other axis (the rotor disc is seen in perspective)
BLADE_ERASE_RADIUS = 4.0


def lum(p):
    return 0.3 * p[0] + 0.59 * p[1] + 0.11 * p[2]


def is_glass(p):
    return p[0] - p[1] >= 18 and p[2] > p[0]


def is_accent(p):
    return p[0] - p[1] >= 60 and p[2] < p[0]


def thick_mask(img: Image.Image, r: int = 2) -> set:
    """Opaque pixels that survive a morphological opening of radius r (the body, not blades or skids)."""
    px = img.load()
    w, h = img.size
    op = [[px[x, y][3] > 0 for x in range(w)] for y in range(h)]
    offs = [(dx, dy) for dx in range(-r, r + 1) for dy in range(-r, r + 1)]
    eroded = [[all(0 <= x + dx < w and 0 <= y + dy < h and op[y + dy][x + dx] for dx, dy in offs) for x in range(w)] for y in range(h)]
    out = set()
    for y in range(h):
        for x in range(w):
            if any(0 <= x + dx < w and 0 <= y + dy < h and eroded[y + dy][x + dx] for dx, dy in offs):
                out.add((x, y))
    return out


def dist_to_segment(p, a, b):
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((p[0] - ax) * dx + (p[1] - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(p[0] - (ax + t * dx), p[1] - (ay + t * dy))


def blade_ends():
    return [(HUB[0] + s * m * u, HUB[1] + s * m * v) for (u, v) in (U, V) for m, s in ((1.0, 1), (1.0, -1))]


def blade_point(theta: float, sign: int):
    c, s = math.cos(theta), math.sin(theta)
    return (HUB[0] + sign * (c * U[0] + s * V[0]), HUB[1] + sign * (c * U[1] + s * V[1]))


def base_body() -> Image.Image:
    src = Image.open(SAMPLE).convert("RGBA")
    img = src.transpose(Image.FLIP_LEFT_RIGHT)
    px = img.load()
    body = thick_mask(img, 2)
    # 1. erase the old blades: pixels near the four old blade lines (the cockpit glass stays)
    ends = [(HUB[0] + (e[0] - HUB[0]) * 1.1, HUB[1] + (e[1] - HUB[1]) * 1.1) for e in blade_ends_old()]
    erased = set()
    for y in range(H):
        for x in range(W):
            p = px[x, y]
            if p[3] == 0 or (is_glass(p) and (x, y) in body):
                continue
            if any(dist_to_segment((x, y), HUB, e) <= BLADE_ERASE_RADIUS for e in ends):
                erased.add((x, y))
    for x, y in erased:
        px[x, y] = (0, 0, 0, 0)
    # 2. close the holes the blades left in the body: pixels inside the closed silhouette take the nearest body colour
    keep = {(x, y) for y in range(H) for x in range(W) if px[x, y][3] > 0}
    closed = close_set(keep, 4)
    fill = [q for q in erased if q in closed and q not in keep]
    colours = {}
    for q in fill:
        best = None
        for r in range(1, 8):
            cands = [(q[0] + dx, q[1] + dy) for dx in range(-r, r + 1) for dy in range(-r, r + 1) if max(abs(dx), abs(dy)) == r and (q[0] + dx, q[1] + dy) in keep]
            if cands:
                best = min(cands, key=lambda c: (c[0] - q[0]) ** 2 + (c[1] - q[1]) ** 2)
                break
        if best:
            colours[q] = px[best]
    for q, c in colours.items():
        px[q] = c
    # 3. drop loose specks (parts of old blades left behind)
    drop_specks(img, 30)
    return img


def close_set(s: set, r: int) -> set:
    dil = set()
    offs = [(dx, dy) for dx in range(-r, r + 1) for dy in range(-r, r + 1) if dx * dx + dy * dy <= r * r + 1]
    for (x, y) in s:
        for dx, dy in offs:
            dil.add((x + dx, y + dy))
    out = set()
    for (x, y) in dil:
        if all((x + dx, y + dy) in dil for dx, dy in offs):
            out.add((x, y))
    return out


def drop_specks(img: Image.Image, min_size: int) -> None:
    px = img.load()
    seen = set()
    for y in range(H):
        for x in range(W):
            if px[x, y][3] == 0 or (x, y) in seen:
                continue
            comp, stack = [], [(x, y)]
            seen.add((x, y))
            while stack:
                cx, cy = stack.pop()
                comp.append((cx, cy))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        n = (cx + dx, cy + dy)
                        if 0 <= n[0] < W and 0 <= n[1] < H and n not in seen and px[n][3] > 0:
                            seen.add(n)
                            stack.append(n)
            if len(comp) < min_size:
                for c in comp:
                    px[c] = (0, 0, 0, 0)


def blade_ends_old():
    # tips of the sample's blades, mirrored, by eye
    return [(144, 33), (71, 23), (166, 81), (46, 89)]


def recolour(img: Image.Image) -> Image.Image:
    """Charcoal body to the red ramp; the glass, the outline, the skids and the tail rotor stay; the thin accent stripes turn dark."""
    out = img.copy()
    px = out.load()
    body = thick_mask(img, 2)
    for (x, y) in body:
        p = px[x, y]
        if p[3] == 0 or is_glass(p):
            continue
        if is_accent(p):
            px[x, y] = STRIPE + (255,)
            continue
        L = lum(p)
        if L < 20:
            continue
        i = max(0, min(len(RAMP) - 1, round((L - 25) / 150 * (len(RAMP) - 1))))
        px[x, y] = RAMP[i] + (255,)
    return out


def draw_blades(img: Image.Image, theta: float) -> Image.Image:
    out = img.copy()
    d = ImageDraw.Draw(out)
    hub = HUB
    for sign in (1, -1):
        for off in (0.0, math.pi / 2):
            a = blade_point(theta + off, sign)
            d.line([hub, a], fill=OUTLINE + (255,), width=4)
    for sign in (1, -1):
        for off in (0.0, math.pi / 2):
            a = blade_point(theta + off, sign)
            d.line([hub, a], fill=BLADE + (255,), width=2)
            d.point((round(a[0]), round(a[1])), fill=BLADE_LIGHT + (255,))
    d.ellipse([hub[0] - 3, hub[1] - 3, hub[0] + 3, hub[1] + 3], fill=BLADE + (255,), outline=OUTLINE + (255,))
    d.point((hub[0] - 1, hub[1] - 1), fill=BLADE_LIGHT + (255,))
    return out


def logo_mask(size: int) -> list:
    """The approved logo (the 64 px file) cut down to size x size, hard pixels (threshold, no blending)."""
    lg = Image.open(LOGO.parent / "redgull_logo_64.png").convert("RGBA")
    alpha = lg.split()[3].resize((size, size), Image.BOX)
    a = alpha.load()
    return [[a[x, y] >= 128 for x in range(size)] for y in range(size)]


def stamp(img: Image.Image, centre, size: int, shear: float) -> None:
    """A pale panel with the logo in Redgull red, sheared along the fuselage."""
    px = img.load()
    m = logo_mask(size)
    pad = 2
    n = size + 2 * pad
    for yy in range(n):
        for xx in range(n):
            x = centre[0] - n // 2 + xx
            y = centre[1] - n // 2 + yy + round(shear * (xx - n // 2))
            edge = xx in (0, n - 1) or yy in (0, n - 1)
            corner = (xx in (0, n - 1)) and (yy in (0, n - 1))
            if corner:
                continue
            if edge:
                px[x, y] = (52, 6, 14, 255)
                continue
            lx, ly = xx - pad, yy - pad
            inside = 0 <= lx < size and 0 <= ly < size and m[ly][lx]
            px[x, y] = LOGO_RED + (255,) if inside else PANEL + (255,)


def build_frames(logo_spots) -> list:
    base = recolour(base_body())
    for centre, size, shear in logo_spots:
        stamp(base, centre, size, shear)
    frames = [draw_blades(base, i * (math.pi / 2) / FRAMES) for i in range(FRAMES)]
    return merge_colours(frames, 30)


def merge_colours(frames, limit: int):
    """Merge the least used colours into their nearest neighbour until the sheet has `limit` colours (the logo red stays)."""
    from collections import Counter
    count = Counter()
    for f in frames:
        count.update(p[:3] for p in f.getdata() if p[3] == 255)
    protected = {LOGO_RED, PANEL, OUTLINE}
    while len(count) > limit:
        c = min((k for k in count if k not in protected), key=lambda k: count[k])
        near = min((k for k in count if k != c), key=lambda k: sum((a - b) ** 2 for a, b in zip(k, c)))
        count[near] += count.pop(c)
        for f in frames:
            px = f.load()
            for y in range(H):
                for x in range(W):
                    if px[x, y][:3] == c and px[x, y][3] == 255:
                        px[x, y] = near + (255,)
    return frames


LOGO_SPOTS = [((78, 90), 18, 0.5), ((35, 29), 12, 0.0)]


def sheet_of(frames) -> Image.Image:
    sheet = Image.new("RGBA", (W * FRAMES, H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * W, 0))
    return sheet


def frame_report(img: Image.Image) -> dict:
    px = list(img.getdata())
    return {
        "size": list(img.size),
        "transparent_corners": all(img.getpixel(c)[3] == 0 for c in ((0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1))),
        "semi_transparent_pixels": sum(1 for p in px if 0 < p[3] < 255),
        "colours": len({p[:3] for p in px if p[3] == 255}),
        "opaque_pixels": sum(1 for p in px if p[3] == 255),
    }


def build() -> dict:
    frames = build_frames(LOGO_SPOTS)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sheet = sheet_of(frames)
    sheet.save(SHEET)
    report = {
        "task": "T-145",
        "generator": "game/tools/build_helicopter.py build (free, no PixelLab call)",
        "source": "art-archive/T-145/helicopter_sample.png (the board-approved sample, 2026-10-16)",
        "frames": FRAMES,
        "frame_size": [W, H],
        "sheet": "helicopter_sheet.png: 4 frames side by side, the rotor turned a quarter of a blade gap per frame",
        "faces": "right (down-right in the isometric view), the way it flies",
        "logo_spots": [{"centre": list(c), "size": n, "shear": sh} for c, n, sh in LOGO_SPOTS],
        "frame_checks": [frame_report(f) for f in frames],
    }
    RECORD.write_text(json.dumps(report, indent=2) + chr(10))
    return report


def check() -> int:
    sheet = Image.open(SHEET).convert("RGBA")
    ok = sheet.size == (W * FRAMES, H)
    for i in range(FRAMES):
        r = frame_report(sheet.crop((i * W, 0, (i + 1) * W, H)))
        good = r["transparent_corners"] and r["semi_transparent_pixels"] == 0 and r["colours"] <= 30
        print(("PASS " if good else "FAIL "), i, r)
        ok = ok and good
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("command", choices=["build", "check"])
    a = ap.parse_args()
    if a.command == "build":
        r = build()
        print(json.dumps(r["frame_checks"]))
        return 0
    return check()


if __name__ == "__main__":
    sys.exit(main())
