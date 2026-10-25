#!/usr/bin/env python3
"""Builds the review pictures for one new in-between car frame (task T-102, sample).

Usage, from the repo root:

    python game/tools/build_car_inbetween_sample.py RAW_PNG LEFT_FRAME OUT_PREFIX

RAW_PNG is the raw PixelLab frame (128 x 128). LEFT_FRAME is the index (0-15)
in game/art/car/car_iso.png of the approved frame before it; the frame after
it is LEFT_FRAME + 1. It writes, with no new pixels (the same two steps as
build_car_sheet.py: palette mapping to the approved sprite's palette, and
whole-pixel centring):

- OUT_PREFIX + "_processed.png": the new frame as it would go in the sheet;
- OUT_PREFIX + "_dark.png" and "_light.png": the left neighbour, the new frame
  and the right neighbour side by side, enlarged 4x (nearest neighbour), on a
  dark and a light background;
- OUT_PREFIX + "_measure.json": colours before and after, the move, and the
  body's long-axis angle on screen for the three frames (a rough heading
  check: the axis has no nose, so it is given from 0 to 180 degrees).

Standard library only.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_car_sheet as cs  # noqa: E402
import style_rules as rules  # noqa: E402
from remove_car_shadow import write_png  # noqa: E402

DARK = (24, 22, 34, 255)
LIGHT = (226, 226, 232, 255)
SCALE = 4
GAP = 8


def sheet_frame(sheet_rows, index: int, size: int = cs.FRAME):
    return [r[index * size:(index + 1) * size] for r in sheet_rows]


def axis_angle(rows) -> float:
    """Long-axis angle (0-180, degrees clockwise from screen right) of the opaque pixels."""
    pts = [(x, y) for y, r in enumerate(rows) for x, p in enumerate(r) if p[3]]
    n = len(pts)
    mx = sum(p[0] for p in pts) / n
    my = sum(p[1] for p in pts) / n
    sxx = sum((p[0] - mx) ** 2 for p in pts) / n
    syy = sum((p[1] - my) ** 2 for p in pts) / n
    sxy = sum((p[0] - mx) * (p[1] - my) for p in pts) / n
    return round((0.5 * math.degrees(math.atan2(2 * sxy, sxx - syy))) % 180.0, 1)


def compose(frames, bg, scale: int = SCALE, gap: int = GAP):
    """Frames side by side over a flat background, enlarged by an integer factor."""
    h = len(frames[0])
    w = sum(len(f[0]) for f in frames) + gap * (len(frames) + 1)
    canvas = [[bg] * w for _ in range(h + 2 * gap)]
    x0 = gap
    for f in frames:
        for y, r in enumerate(f):
            for x, p in enumerate(r):
                if p[3]:
                    canvas[y + gap][x0 + x] = p[:3] + (255,)
        x0 += len(f[0]) + gap
    out = []
    for r in canvas:
        big = [p for p in r for _ in range(scale)]
        out.extend([list(big) for _ in range(scale)])
    return out


def build(raw_path: Path, left: int, repo: Path = cs.REPO):
    ref_rows = cs.read_rows(repo / cs.REFERENCE)
    palette = cs.palette_of(ref_rows)
    target = cs.bbox_centre(ref_rows)
    raw = cs.read_rows(raw_path)
    mapped = cs.map_to_palette(raw, palette)
    dx, dy = cs.centring_shift(mapped, target)
    final = cs.shift(mapped, dx, dy)
    w, h, sheet = rules.decode_png((repo / cs.OUT_PNG).read_bytes())
    count = w // cs.FRAME
    a = sheet_frame(sheet, left % count)
    b = sheet_frame(sheet, (left + 1) % count)
    measure = {
        "raw": str(raw_path),
        "left_frame": left % count,
        "right_frame": (left + 1) % count,
        "colours_before": len(cs.palette_of(raw)),
        "colours_after": len(cs.palette_of(final)),
        "shift_px": {"x": dx, "y": dy},
        "axis_angle_deg": {"left": axis_angle(a), "new": axis_angle(final), "right": axis_angle(b)},
        "axis_note": "long axis of all opaque pixels (car and its shadow), degrees clockwise from screen right, 0-180",
    }
    return final, compose([a, final, b], DARK), compose([a, final, b], LIGHT), measure


def main(argv=None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) != 3:
        print(__doc__)
        return 2
    raw, left, prefix = Path(argv[0]), int(argv[1]), argv[2]
    final, dark, light, measure = build(raw, left)
    write_png(Path(prefix + "_processed.png"), final)
    write_png(Path(prefix + "_dark.png"), dark)
    write_png(Path(prefix + "_light.png"), light)
    Path(prefix + "_measure.json").write_text(json.dumps(measure, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(measure, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
