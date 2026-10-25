#!/usr/bin/env python3
"""Cruise boost motion lines (task T-009), free script steps around the PixelLab calls.

    python game/tools/build_boost_lines.py first-frame   # the script-drawn first frame for call 2
    python game/tools/build_boost_lines.py build         # raw PixelLab frames -> game sheet + record
    python game/tools/build_boost_lines.py check         # rules check on the game sheet

The lines are drawn pointing right: the car is to the right of the frame (it moves
right), the lines trail behind it on the left. `build` cleans the PixelLab frames
(no semi-transparent pixels, snapped to the frame-0 palette, never Redgull red) and
turns each frame to DIRECTIONS screen angles by nearest-neighbour rotation (no new
colours), one row per direction, so the game picks the row closest to the car's
heading on screen and never rotates pixel art itself.
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from style_rules import RED_MIN_DISTANCE, red_distance  # noqa: E402  (Visual style rule 6)

REPO = Path(__file__).resolve().parents[2]
ARCHIVE = REPO / "art-archive" / "T-009"
RAW_DIR = ARCHIVE / "call2"
FIRST_FRAME = ARCHIVE / "first_frame_script.png"
OUT_DIR = REPO / "game" / "art" / "effects"
SHEET = OUT_DIR / "boost_lines.png"
RECORD = OUT_DIR / "boost_lines.json"

SIZE = 64            # PixelLab frame size (square)
CELL = 80            # sheet cell: room for the 64 px frame turned to any angle
DIRECTIONS = 16      # screen angles, 22.5 degrees apart, row 0 = pointing right (east on screen)
ALPHA_CUT = 128      # alpha below this -> transparent, else opaque

# Pale cyans and whites (also call 1's color_image), darkest last.
PALETTE = [(248, 252, 255), (200, 240, 252), (140, 216, 240), (80, 168, 216), (48, 104, 160)]
OUTLINE = (24, 40, 80)


def draw_first_frame() -> Image.Image:
    """Three thin horizontal lines, bright at the right (the car), tapering left."""
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    # (y, x_start, x_end): the right ends are near the right edge.
    lines = [(24, 18, 58), (32, 8, 60), (40, 22, 56)]
    for y, x0, x1 in lines:
        n = x1 - x0
        for i, x in enumerate(range(x0, x1 + 1)):
            k = i / n  # 0 at the tail (left), 1 at the head (right)
            col = PALETTE[0] if k > 0.75 else PALETTE[1] if k > 0.5 else PALETTE[2] if k > 0.25 else PALETTE[3]
            im.putpixel((x, y), col + (255,))
            if k > 0.5:  # thicker near the head
                im.putpixel((x, y + 1), PALETTE[2 if k > 0.75 else 3] + (255,))
        # Selective dark outline at the head end and below the line.
        im.putpixel((x1 + 1, y), OUTLINE + (255,))
        for x in range(x0 + (x1 - x0) // 2, x1 + 1):
            if im.getpixel((x, y + 2))[3] == 0:
                im.putpixel((x, y + 2), OUTLINE + (255,))
    return im


def clean(im: Image.Image, palette: list[tuple[int, int, int]]) -> Image.Image:
    """Hard alpha, every colour snapped to the nearest palette colour."""
    im = im.convert("RGBA")
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = im.getpixel((x, y))
            if a < ALPHA_CUT:
                continue
            best = min(palette, key=lambda p: (p[0] - r) ** 2 + (p[1] - g) ** 2 + (p[2] - b) ** 2)
            out.putpixel((x, y), best + (255,))
    return out


def frame_palette(frames: list[Image.Image], cap: int = 30) -> list[tuple[int, int, int]]:
    """Up to `cap` most-used opaque colours over all frames, never near Redgull red."""
    counts: dict[tuple[int, int, int], int] = {}
    for f in frames:
        for r, g, b, a in f.convert("RGBA").getdata():
            if a >= ALPHA_CUT:
                counts[(r, g, b)] = counts.get((r, g, b), 0) + 1
    ranked = [c for c, _ in sorted(counts.items(), key=lambda kv: -kv[1]) if red_distance(c) > RED_MIN_DISTANCE]
    return ranked[:cap] or PALETTE


def rotate_nearest(im: Image.Image, degrees_cw: float) -> Image.Image:
    """Turn a frame clockwise on screen by nearest-neighbour sampling into a CELL x CELL cell."""
    out = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    a = math.radians(degrees_cw)
    ca, sa = math.cos(a), math.sin(a)
    cx_in, cy_in = im.width / 2.0, im.height / 2.0
    cx_out = cy_out = CELL / 2.0
    src = im.load()
    for y in range(CELL):
        for x in range(CELL):
            dx, dy = x + 0.5 - cx_out, y + 0.5 - cy_out
            # inverse rotation (screen y points down, so clockwise is +angle)
            sx = ca * dx + sa * dy + cx_in
            sy = -sa * dx + ca * dy + cy_in
            ix, iy = math.floor(sx), math.floor(sy)
            if 0 <= ix < im.width and 0 <= iy < im.height:
                p = src[ix, iy]
                if p[3]:
                    out.putpixel((x, y), p)
    return out


def raw_frames() -> list[Path]:
    files = sorted(RAW_DIR.glob("boost_lines_anim_*.png"), key=lambda p: int(p.stem.split("_")[3]))
    return files


def build(frame_ids: list[int] | None = None) -> dict:
    files = raw_frames()
    if not files:
        raise SystemExit(f"No raw frames in {RAW_DIR}")
    raws = [Image.open(f).convert("RGBA") for f in files]
    ids = list(range(len(raws))) if frame_ids is None else frame_ids
    pal = frame_palette([raws[i] for i in ids])
    frames = [clean(raws[i], pal) for i in ids]
    # The animation must end on its own: an empty cell after the last frame is not
    # needed, the game simply stops after the last column.
    sheet = Image.new("RGBA", (CELL * len(frames), CELL * DIRECTIONS), (0, 0, 0, 0))
    for d in range(DIRECTIONS):
        for i, f in enumerate(frames):
            sheet.alpha_composite(rotate_nearest(f, d * 360.0 / DIRECTIONS), (i * CELL, d * CELL))
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sheet.save(SHEET)
    record = {
        "task": "T-009",
        "generator": "game/tools/build_boost_lines.py build (free, no PixelLab call)",
        "sources": [str(files[i].relative_to(REPO)).replace("\\", "/") for i in ids],
        "pixellab_records": [str(files[i].with_suffix(".json").relative_to(REPO)).replace("\\", "/") for i in ids],
        "frame_size": CELL,
        "frames": len(frames),
        "directions": DIRECTIONS,
        "layout": "one row per screen direction, row 0 points right (lines trail to the left), "
                  "each next row turned 360/directions degrees clockwise on screen; one column per frame",
        "art_density": "drawn at scale 0.5 in the run (32 texels per unit, like the car)",
        "check": check_sheet(sheet, len(frames)),
    }
    RECORD.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    return record


def check_sheet(sheet: Image.Image, frame_count: int) -> dict:
    colors = set()
    semi = 0
    for r, g, b, a in sheet.getdata():
        if 0 < a < 255:
            semi += 1
        if a:
            colors.add((r, g, b))
    closest = min((red_distance(c) for c in colors), default=9.0)
    opaque_per_frame = []
    for i in range(frame_count):
        cell = sheet.crop((i * CELL, 0, (i + 1) * CELL, CELL))
        opaque_per_frame.append(sum(1 for p in cell.getdata() if p[3]))
    result = {
        "size": list(sheet.size),
        "semi_transparent_pixels": semi,
        "colors": len(colors),
        "closest_to_redgull_red": round(closest, 3),
        "opaque_pixels_per_frame_row0": opaque_per_frame,
    }
    result["pass"] = semi == 0 and len(colors) <= 30 and closest > RED_MIN_DISTANCE and all(opaque_per_frame)
    return result


def main(argv: list[str]) -> int:
    cmd = argv[1] if len(argv) > 1 else ""
    if cmd == "first-frame":
        draw_first_frame().save(FIRST_FRAME)
        print(FIRST_FRAME)
    elif cmd == "build":
        ids = [int(x) for x in argv[2].split(",")] if len(argv) > 2 else None
        print(json.dumps(build(ids)["check"], indent=2))
    elif cmd == "check":
        rec = json.loads(RECORD.read_text(encoding="utf-8"))
        res = check_sheet(Image.open(SHEET).convert("RGBA"), rec["frames"])
        print(json.dumps(res, indent=2))
        return 0 if res["pass"] else 1
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
