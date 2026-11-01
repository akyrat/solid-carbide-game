#!/usr/bin/env python3
"""Rev Charge's charging and boost frames (task T-466), drawn by a free script (no PixelLab).

    python game/tools/build_rev_charge.py base    # the unturned frames -> the style loop's sheet
    python game/tools/build_rev_charge.py build   # base sheet -> game sheet (16 directions) + record
    python game/tools/build_rev_charge.py check   # rules check on the game sheet

The base sheet is one row of FRAMES 64 x 64 frames, drawn pointing right (the car is at the
right, the effect trails to the left, like the cruise boost's lines, build_boost_lines.py):
  frames 0-3   charging, a heat glow at the car's rear growing with the charge (25/50/75/100 %);
  frames 4-5   fully charged, two frames that the game alternates for the pulse;
  frames 6-10  the boost: speed lines streaming back, shorter and thinner as the boost runs down.
Every pixel is opaque or empty, glow is stepped halos (a dithered band, then solid bands) and
never a blur (Visual style, rules 1, 2 and 5). `build` turns each frame to 16 screen angles by
nearest-neighbour rotation (no new colours), one row per direction, as the cruise boost does.
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_boost_lines as bl  # noqa: E402  (rotate_nearest, CELL, DIRECTIONS)
from style_rules import OLD_BRAND, RED_MIN_DISTANCE, red_distance  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "game" / "art" / "driving" / "rev_charge"
BASE = OUT_DIR / "rev_charge_base.png"
SHEET = OUT_DIR / "rev_charge.png"
RECORD = OUT_DIR / "rev_charge.json"

SIZE = 64
CELL = bl.CELL
DIRECTIONS = bl.DIRECTIONS
CHARGE_FRAMES = 4      # 25, 50, 75, 100 %
PULSE_FRAMES = 2       # full charge, alternating
BOOST_FRAMES = 5
FRAMES = CHARGE_FRAMES + PULSE_FRAMES + BOOST_FRAMES
# Where the effect is anchored in the unturned frame, in texels right of the cell's centre.
CHARGE_ANCHOR = (10, 0)   # the glow's centre
BOOST_ANCHOR = (26, 0)    # the lines' leading ends

OUTLINE = (20, 10, 10)       # almost black, the glow's selective outline
# Heat, dark -> hot. Every step keeps over 25 from Greenbull's yellow (rule 6).
HEAT = [(96, 30, 14), (160, 48, 16), (210, 82, 18), (240, 118, 24), (255, 154, 40),
        (255, 196, 100), (255, 230, 168), (255, 248, 230)]
WHITE = (255, 255, 255)      # the hot core (full charge only) and the speed lines' tips
LINES = [(244, 248, 255), (196, 210, 236), (148, 166, 206), (100, 116, 164)]  # light -> dark
LINE_OUTLINE = (14, 14, 26)  # almost black, the speed lines' outline


def put(im: Image.Image, x: int, y: int, col: tuple[int, int, int]) -> None:
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), col + (255,))


def _glow_dist(x: int, y: int, cx: int, cy: int, r: float, frac: float) -> float:
    """Distance in radius units (1 = the glow's edge): round at the front, drawn out to the
    left into a flame tongue that narrows to a point."""
    dx, dy = x - cx, (y - cy) * 1.15
    if dx >= 0:
        return math.hypot(dx, dy) / r
    # The glow itself is near-round, only slightly drawn back; the flame is drawn separately.
    return math.hypot(dx / 1.25, dy) / r


def _flame(im: Image.Image, cx: int, cy: int, r: float, frac: float) -> None:
    """A small flickering flame licking back (left) from the glow, no outline: two forked
    tongues of stepped heat, hot at the root, ember at the tips."""
    root = cx - round(r * 1.1)
    length = round(6 + 10 * frac)
    for k in range(length):
        t = k / length                                    # 0 at the root, 1 at the tip
        half = max(0, round((r * 0.35) * (1.0 - t)))
        wob = round(math.sin(k * 0.9) * 1.2 * t)           # a flicker in the tongue
        # five shade steps along the tongue (hot root -> ember tip), its edges one step darker
        step = 6 - min(4, int(t * 5))
        for dy in range(-half, half + 1):
            y = cy + dy + wob
            x = root - k
            col = HEAT[step - 1] if half and abs(dy) == half else HEAT[step]
            if t > 0.75 and (x + y) % 2:
                continue                                   # dithered tip
            put(im, x, y, col)
        if t > 0.4 and k % 3 == 0:                         # a stray ember above the tongue
            put(im, root - k - 1, cy - half - 2 + wob, HEAT[1])


def glow_frame(frac: float, pulse: int = -1) -> Image.Image:
    """A stepped heat glow at the rear (anchor), drawn out into a flame trailing left. The
    charging frames step from ember red to pale yellow; the full-charge pulse frames are a
    little bigger and add a white-hot core."""
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2 + CHARGE_ANCHOR[0], SIZE // 2
    charged = pulse >= 0
    r = 4 + 9 * frac + (1 if charged else 0) + (1.5 if pulse == 1 else 0)
    # Stepped halos: a few wide bands from a bright centre out to dark ember, each step blended
    # by a 2-pixel checker dither, then an outer halo of dithered ember fading to sparse pixels.
    # (edge in radius units, colour), outermost first; hotter steps appear as the charge builds.
    bands = [(1.00, HEAT[2]), (0.72, HEAT[4])]
    if frac >= 0.5:
        bands.append((0.46, HEAT[5]))
    else:
        bands.append((0.40, HEAT[4]))
    if charged:
        bands.append((0.32 if pulse == 0 else 0.36, HEAT[6]))
        bands.append((0.21 if pulse == 0 else 0.25, HEAT[7]))
        bands.append((0.11 if pulse == 0 else 0.14, WHITE))
    elif frac >= 0.75:
        bands.append((0.24, HEAT[6]))
    dz = 1.0 / r                                  # one pixel, in radius units
    for y in range(SIZE):
        for x in range(SIZE):
            d = _glow_dist(x, y, cx, cy, r, frac)
            col = None
            chk = (x + y) % 2 == 0
            if d <= 1.0:
                for edge, c in bands:
                    if d <= edge:
                        col = c
                # a 2-pixel checker at each step, so each halo ring reads as stepped and dithered
                for (_, c_out), (e_in, c_in) in zip(bands, bands[1:]):
                    if e_in < d <= e_in + 2 * dz and col == c_out and chk:
                        col = c_in
            elif d <= 1.0 + dz:
                col = HEAT[1] if chk else HEAT[0]  # the dithered outer halo
            elif d <= 1.0 + 2 * dz:
                col = HEAT[0]                      # a solid ember rim, so the edge is clean
            if col is not None:
                put(im, x, y, col)
    # An almost-black outline on the outer silhouette, solid below and behind; on the hot upper
    # front it is left open with a few light pixels catching the heat.
    snap = im.copy()
    for y in range(SIZE):
        for x in range(SIZE):
            if snap.getpixel((x, y))[3]:
                continue
            if not any(0 <= x + ox < SIZE and 0 <= y + oy < SIZE and snap.getpixel((x + ox, y + oy))[3]
                       for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                continue
            if y < cy + r * 0.2 and x > cx - r * 0.4:
                if (x + 2 * y) % 4 == 0:
                    put(im, x, y, HEAT[5])          # highlight pixels breaking the outline
            else:
                put(im, x, y, OUTLINE)
    _flame(im, cx, cy, r, frac)                   # over the halo's trailing side, no outline
    # Sparks over the glow: a light pixel with a dark one under it.
    for k in range(3 if charged else 2):
        a = math.radians(215 + k * 50 + (25 if pulse == 1 else 0))
        sx, sy = round(cx + math.cos(a) * (r + 4)), round(cy + math.sin(a) * (r + 4))
        put(im, sx, sy, HEAT[6] if charged else HEAT[5])
        put(im, sx, sy + 1, OUTLINE)
    return im


def lines_frame(i: int) -> Image.Image:
    """Speed lines streaming back from the car: a bright core with shaded edges at the head
    (right), thinning and darkening to a broken tail, with a dark cap and a dark underside."""
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    fade = 1.0 - i / BOOST_FRAMES                      # 1 at the start, fades as the boost runs down
    head = SIZE // 2 + BOOST_ANCHOR[0]
    # (y offset, length, start shift, thickness at full boost), five lines.
    spec = [(-13, 26, 5, 2), (-7, 38, 1, 3), (0, 48, 0, 4), (7, 34, 2, 3), (13, 24, 6, 2)]
    for dy, length, shift, th0 in spec:
        n = max(6, round(length * (0.45 + 0.55 * fade)))
        th = max(1, round(th0 * (0.35 + 0.65 * fade)))
        x1 = head - shift - 4 * i
        yc = SIZE // 2 + dy
        for k in range(n):
            x = x1 - k
            t = k / n  # 0 at the head, 1 at the tail
            if t > 0.88 and k % 2:
                continue  # a broken tail
            w = th if t < 0.4 else max(1, th - 1) if t < 0.75 else 1
            top = yc - (th - 1) // 2          # top-aligned: the line thins from below, cleanly
            for j in range(w):
                edge = w > 2 and (j == 0 or j == w - 1) or (w == 2 and j == 1)
                if j == 0 and w > 1 and t < 0.5:
                    col = WHITE if t < 0.25 else LINES[0]   # a highlight along the top
                elif t < 0.3:
                    col = LINES[1] if edge else LINES[0]
                elif t < 0.6:
                    col = LINES[2] if edge else LINES[1]
                elif t < 0.82:
                    col = LINES[2]
                else:
                    col = LINES[3]
                put(im, x, top + j, col)
            if t < 0.4 and th > 1:
                put(im, x, top + w, LINE_OUTLINE)    # selective dark underside, one clean run
        top = yc - (th - 1) // 2
        for j in range(th):
            put(im, x1 + 1, top + j, LINE_OUTLINE)   # the dark cap at the head
        put(im, x1, top + (th - 1) // 2, WHITE)      # a bright tip
    return im


def base_frames() -> list[Image.Image]:
    frames = [glow_frame((i + 1) / CHARGE_FRAMES) for i in range(CHARGE_FRAMES)]
    frames += [glow_frame(1.0, pulse=p) for p in range(PULSE_FRAMES)]
    frames += [lines_frame(i) for i in range(BOOST_FRAMES)]
    return frames


def build_base() -> Path:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGBA", (SIZE * FRAMES, SIZE), (0, 0, 0, 0))
    for i, f in enumerate(base_frames()):
        sheet.alpha_composite(f, (i * SIZE, 0))
    sheet.save(BASE)
    return BASE


def check_sheet(sheet: Image.Image) -> dict:
    colors, semi = set(), 0
    for r, g, b, a in sheet.getdata():
        if 0 < a < 255:
            semi += 1
        if a:
            colors.add((r, g, b))
    closest = min((red_distance(c) for c in colors), default=9.0)
    res = {
        "size": list(sheet.size),
        "semi_transparent_pixels": semi,
        "colors": len(colors),
        "closest_to_" + OLD_BRAND.lower() + "_red": round(closest, 3),
    }
    res["pass"] = semi == 0 and len(colors) <= 30
    return res


def build() -> dict:
    base = Image.open(BASE).convert("RGBA")
    frames = [base.crop((i * SIZE, 0, (i + 1) * SIZE, SIZE)) for i in range(FRAMES)]
    sheet = Image.new("RGBA", (CELL * FRAMES, CELL * DIRECTIONS), (0, 0, 0, 0))
    for d in range(DIRECTIONS):
        for i, f in enumerate(frames):
            sheet.alpha_composite(bl.rotate_nearest(f, d * 360.0 / DIRECTIONS), (i * CELL, d * CELL))
    sheet.save(SHEET)
    record = {
        "task": "T-466",
        "generator": "game/tools/build_rev_charge.py (free script, no PixelLab call)",
        "frame_size": CELL,
        "directions": DIRECTIONS,
        "charge_frames": CHARGE_FRAMES,
        "pulse_frames": PULSE_FRAMES,
        "boost_frames": BOOST_FRAMES,
        "frames": FRAMES,
        "charge_anchor_texels": list(CHARGE_ANCHOR),
        "boost_anchor_texels": list(BOOST_ANCHOR),
        "layout": "one row per screen direction, row 0 points right (the effect trails to the left), "
                  "each next row turned 360/directions degrees clockwise on screen; columns: "
                  "charge 25/50/75/100 %, two full-charge pulse frames, then the boost's frames",
        "art_density": "drawn at scale 0.5 in the run (32 texels per unit, like the car)",
        "check": check_sheet(sheet),
    }
    RECORD.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    return record


def preview() -> list[Path]:
    """Enlarged (x6) pictures of the frames on a dark and a light ground, and of the 16 turns."""
    shots = REPO / "art-archive" / "T-466" / "screenshots"
    shots.mkdir(parents=True, exist_ok=True)
    base = Image.open(BASE).convert("RGBA")
    out = []
    strip = Image.new("RGB", (base.width, base.height * 2), (0, 0, 0))
    for k, bg in enumerate([(18, 20, 34), (200, 204, 214)]):
        panel = Image.new("RGBA", base.size, bg + (255,))
        panel.alpha_composite(base)
        strip.paste(panel.convert("RGB"), (0, k * base.height))
    p = shots / "frames_dark_light.png"
    strip.resize((strip.width * 2, strip.height * 2), Image.NEAREST).save(p)
    out.append(p)
    sheet = Image.open(SHEET).convert("RGBA")
    cols = [3, 5, 8]  # a charge frame, the full pulse, a boost frame
    turns = Image.new("RGBA", (CELL * DIRECTIONS // 2 * len(cols), CELL * 2), (18, 20, 34, 255))
    for ci, col in enumerate(cols):
        for d in range(0, DIRECTIONS, 2):
            cell = sheet.crop((col * CELL, d * CELL, (col + 1) * CELL, (d + 1) * CELL))
            turns.alpha_composite(cell, ((ci * 8 + d // 2) * CELL, 0))
    p = shots / "turns.png"
    turns.crop((0, 0, turns.width, CELL)).resize((turns.width, CELL), Image.NEAREST).save(p)
    out.append(p)
    return out


def main(argv: list[str]) -> int:
    cmd = argv[1] if len(argv) > 1 else ""
    if cmd == "preview":
        for p in preview():
            print(p)
    elif cmd == "base":
        print(build_base())
    elif cmd == "build":
        print(json.dumps(build()["check"], indent=2))
    elif cmd == "check":
        res = check_sheet(Image.open(SHEET).convert("RGBA"))
        print(json.dumps(res, indent=2))
        return 0 if res["pass"] else 1
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
