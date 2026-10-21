#!/usr/bin/env python3
"""Builds the final isometric car sheet from the PixelLab frames (task T-101).

Usage, from the repo root:  python game/tools/build_car_sheet.py

Reads the 16 source frames listed in SOURCES (the approved T-014 sprite for
frame 4, and the raw T-101 PixelLab generations, archived in
art-archive/T-101/frames/, for the others) and writes
game/art/car/car_iso.png (one row of 16 frames of 128 x 128) and
game/art/car/car_iso.json, in T-013's layout and JSON convention, so
scripts/driving/car_sprite.gd reads it like the placeholder sheet.

It adds no new pixels. Two steps only, both recorded in the JSON:

- **Palette:** every opaque pixel is replaced by the nearest colour (CIELAB
  distance) of the approved sprite's own palette (33 colours), so all frames
  share frame 4's colours and keep to Visual style's "about 30 colours".
  Transparent pixels stay transparent; there are no semi-transparent ones.
  The approved sprite itself is unchanged by this (its colours map to themselves).
- **Centring:** each frame is moved by whole pixels so the centre of its
  bounding box lands where the approved sprite's is (frame 4 does not move),
  so the car does not jump around its centre as it turns. A move never pushes
  an opaque pixel out of the frame.

Standard library only; the same inputs always give byte-identical files.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_sprite_rules as rules  # noqa: E402  (PNG decoding)
from remove_car_shadow import write_png  # noqa: E402  (PNG encoding)

REPO = Path(__file__).resolve().parents[2]
FRAME = 128
COUNT = 16
STEP = 22.5
REFERENCE = "game/art/car/car_sw_front.png"
REFERENCE_FRAME = 4
# T-102: this 16-frame sheet is now the input of build_car_sheet32.py, which
# writes the game's 32-frame game/art/car/car_iso.png.
OUT_PNG = "art-archive/T-102/car_iso_16_t101.png"
OUT_JSON = "art-archive/T-102/car_iso_16_t101.json"
# Sprite pixels per unit, fitted to the PixelLab art (T-101 result notes): the
# car comes out about 3 units long on average over the 16 directions.
PX_PER_UNIT = 32.0

# The raw PixelLab frames are archived (not game-ready on their own: 49 to 272
# colours); this script reads them from the archive.
_F = "art-archive/T-101/frames/"
# frame index -> (source PNG, how it was made, the nose angle on screen as seen
# by the Asset Generation Agent, in degrees clockwise from screen right; approximate)
SOURCES = {
    0: (_F + "car_rot8_v3_2.png", "/generate-8-rotations-v3 image 2 (south-east)", 25),
    1: (_F + "car_rot22_from_f00_south-east.png", "/rotate of frame 0 by 22", 70),
    2: (_F + "car_rot8_v3_1.png", "/generate-8-rotations-v3 image 1 (south)", 90),
    3: (_F + "car_rot22_from_f02_south.png", "/rotate of frame 2 by 22", 120),
    4: (REFERENCE, "T-014 /create-image-pixflux, approved by the board", 163),
    5: (_F + "car_rot22_from_f04_sw.png", "/rotate of frame 4 by 22", 170),
    6: (_F + "car_rot8_v3_7.png", "/generate-8-rotations-v3 image 7 (west)", 170),
    7: (_F + "car_rot22_from_f06_west.png", "/rotate of frame 6 by 22", 182),
    8: (_F + "car_rot8_v3_6.png", "/generate-8-rotations-v3 image 6 (north-west)", 200),
    9: (_F + "car_rot22_from_f08_north-west.png", "/rotate of frame 8 by 22", 218),
    10: (_F + "car_rot8_v3_5.png", "/generate-8-rotations-v3 image 5 (north)", 260),
    11: (_F + "car_rot22_from_f10_north.png", "/rotate of frame 10 by 22", 270),
    12: (_F + "car_rot8_v3_4.png", "/generate-8-rotations-v3 image 4 (north-east)", 320),
    13: (_F + "car_rot22_from_f12_north-east.png", "/rotate of frame 12 by 22", 343),
    14: (_F + "car_rot8_v3_3.png", "/generate-8-rotations-v3 image 3 (east)", 0),
    15: (_F + "car_rot22_from_f14_east.png", "/rotate of frame 14 by 22", 17),
}


# ---------------------------------------------------------------- colour ----

def _lin(v: int) -> float:
    c = v / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def to_lab(rgb) -> tuple[float, float, float]:
    """sRGB (0-255) to CIELAB (D65)."""
    r, g, b = (_lin(v) for v in rgb[:3])
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
    f = lambda t: t ** (1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0  # noqa: E731
    return 116.0 * f(y) - 16.0, 500.0 * (f(x) - f(y)), 200.0 * (f(y) - f(z))


def palette_of(rows) -> list[tuple[int, int, int]]:
    """The sorted distinct colours of the opaque pixels."""
    return sorted({p[:3] for r in rows for p in r if p[3] == 255})


def map_to_palette(rows, palette):
    """Each opaque pixel -> the nearest palette colour; transparent pixels unchanged."""
    labs = [to_lab(c) for c in palette]
    cache: dict = {}

    def nearest(rgb):
        if rgb not in cache:
            l = to_lab(rgb)
            cache[rgb] = min(range(len(palette)),
                             key=lambda i: (sum((a - b) ** 2 for a, b in zip(l, labs[i])), i))
        return palette[cache[rgb]]

    out = []
    for r in rows:
        out.append([(0, 0, 0, 0) if p[3] == 0 else nearest(p[:3]) + (p[3],) for p in r])
    return out


# --------------------------------------------------------------- centring ----

def bbox(rows):
    """(x0, y0, x1, y1) of the non-transparent pixels, x1 and y1 exclusive."""
    xs = [x for r in rows for x, p in enumerate(r) if p[3]]
    ys = [y for y, r in enumerate(rows) if any(p[3] for p in r)]
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def bbox_centre(rows) -> tuple[float, float]:
    x0, y0, x1, y1 = bbox(rows)
    return (x0 + x1) / 2.0, (y0 + y1) / 2.0


def centring_shift(rows, target) -> tuple[int, int]:
    """Whole-pixel move putting the bbox centre nearest to target, keeping every pixel in the frame."""
    x0, y0, x1, y1 = bbox(rows)
    cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
    h, w = len(rows), len(rows[0])
    dx = math.floor(target[0] - cx + 0.5)
    dy = math.floor(target[1] - cy + 0.5)
    dx = max(-x0, min(w - x1, dx))
    dy = max(-y0, min(h - y1, dy))
    return dx, dy


def shift(rows, dx: int, dy: int):
    h, w = len(rows), len(rows[0])
    out = [[(0, 0, 0, 0)] * w for _ in range(h)]
    for y, r in enumerate(rows):
        for x, p in enumerate(r):
            if p[3] and 0 <= x + dx < w and 0 <= y + dy < h:
                out[y + dy][x + dx] = p
    return out


# ------------------------------------------------------------------ sheet ----

def iso_screen_angle(heading_deg: float) -> float:
    """The nose's screen angle for a world heading in the game's 2:1 projection."""
    h = math.radians(heading_deg)
    x, y = math.cos(h), math.sin(h)
    return round(math.degrees(math.atan2((x + y) / 2.0, x - y)) % 360.0, 2)


def read_rows(path: Path):
    w, h, rows = rules.decode_png(path.read_bytes())
    if (w, h) != (FRAME, FRAME):
        raise ValueError(f"{path} is {w}x{h}, expected {FRAME}x{FRAME}")
    return rows


def build(repo: Path = REPO, sources=None):
    """Returns (sheet rows, layout JSON dict)."""
    sources = SOURCES if sources is None else sources
    ref_rows = read_rows(repo / REFERENCE)
    palette = palette_of(ref_rows)
    target = bbox_centre(ref_rows)
    sheet = [[] for _ in range(FRAME)]
    frames = []
    for i in range(COUNT):
        src, made, seen = sources[i]
        rows = read_rows(repo / src)
        before = len(palette_of(rows))
        mapped = map_to_palette(rows, palette)
        dx, dy = centring_shift(mapped, target)
        final = shift(mapped, dx, dy)
        for y in range(FRAME):
            sheet[y].extend(final[y])
        heading = i * STEP
        frames.append({
            "index": i,
            "heading_deg": heading,
            "nose_screen_angle_deg": iso_screen_angle(heading),
            "seen_nose_screen_angle_deg_approx": seen,
            "source": src,
            "made_by": made,
            "colours_before": before,
            "colours_after": len(palette_of(final)),
            "shift_px": {"x": dx, "y": dy},
        })
    layout = {
        "file": "car_iso.png",  # the name T-101's sheet had in the game (T-102 keeps it as a copy in the archive)
        "view": "iso",
        "placeholder": False,
        "columns": COUNT,
        "rows": 1,
        "frame_count": COUNT,
        "frame_width": FRAME,
        "frame_height": FRAME,
        "frame0_heading_deg": 0.0,
        "frame0_faces": "world heading 0 degrees, nose along world +x: drawn pointing down-right on screen (PixelLab south-east)",
        "step_deg": STEP,
        "order": "clockwise on screen: frame i shows world heading i * 22.5 degrees, Godot axes (y down), the same direction Godot's rotation grows",
        "frame_from_rotation": "posmod(roundi(rotation / deg_to_rad(22.5)), 16) for a car body whose nose is +x at rotation 0; the same formula as the placeholder sheets",
        "projection": "PixelLab's isometric view (high top-down), drawn by PixelLab; the game draws the world in 2:1 isometric, screen = (x - y, (x + y) / 2). PixelLab's diagonals are flatter than 2:1, so the nose's angle on screen is close to, not exactly, nose_screen_angle_deg (see seen_nose_screen_angle_deg_approx per frame)",
        "center_px": {"x": target[0], "y": target[1]},
        "center_note": "point in frame pixel coordinates (top-left of the frame = 0, 0) where the car's centre sits: the centre of the approved frame 4's bounding box; every other frame was moved by whole pixels to put its own bounding-box centre there",
        "px_per_unit": PX_PER_UNIT,
        "car_size_units": {"length": 3.0, "width": 1.0},
        "car_size_px": {"length": 3.0 * PX_PER_UNIT, "width": PX_PER_UNIT},
        "car_size_note": "px_per_unit is fitted to the PixelLab art so the car is drawn about 3 units long on average over the 16 directions (Drifting, Decisions); the drawing only, the physics body is a 1 by 1 unit square. To scale the sprite to the world: scale = world size of 1 unit / px_per_unit",
        "palette": ["#%02x%02x%02x" % c for c in palette],
        "frames": frames,
        "record": {
            "made_by": "PixelLab (T-101: one /generate-8-rotations-v3 call and eight /rotate calls; frame 4 is T-014's approved sprite), assembled by game/tools/build_car_sheet.py",
            "command": "python game/tools/build_car_sheet.py",
            "processing": "palette: each opaque pixel mapped to the nearest colour (CIELAB) of the approved sprite's palette; centring: whole-pixel moves; no other change and no new pixels",
            "pixellab_records": "each source frame has its PixelLab record JSON next to it; every call is in game/art/pixellab-generation-log.jsonl",
            "task": "T-101",
            "resources_consulted": [
                "docs/visual-style.md", "docs/extended-narrative.md", "docs/drifting.md",
                "tasks/T-101-car-sprites-remaining-directions.md", "tasks/T-014-car-sprites-16-directions.md",
                "tasks/T-013-placeholder-car-sprites.md", "game/art/placeholders/car/car_iso.json",
            ],
        },
    }
    return sheet, layout


def main(argv=None) -> int:
    sheet, layout = build()
    write_png(REPO / OUT_PNG, sheet)
    (REPO / OUT_JSON).write_text(json.dumps(layout, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"wrote {OUT_PNG} ({len(sheet[0])}x{len(sheet)}) and {OUT_JSON}")
    for f in layout["frames"]:
        print(f"  frame {f['index']:2d}: {f['colours_before']:3d} -> {f['colours_after']:2d} colours, "
              f"moved ({f['shift_px']['x']}, {f['shift_px']['y']}), {f['source']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
