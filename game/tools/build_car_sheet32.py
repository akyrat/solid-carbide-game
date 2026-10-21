#!/usr/bin/env python3
"""Builds the 32-direction isometric car sheet (task T-102).

Usage, from the repo root:

    python game/tools/build_car_sheet32.py            # write the sheet and its JSON
    python game/tools/build_car_sheet32.py --measure  # only print where each raw landed

Inputs:
- T-101's 16-frame sheet, kept as art-archive/T-102/car_iso_16_t101.png (+ .json),
  built by game/tools/build_car_sheet.py. Its frame k becomes frame 2k here,
  copied pixel for pixel (byte-identical).
- The 16 raw PixelLab /rotate frames of T-102 (one from each T-101 frame, by
  +16 degrees), in art-archive/T-102/ (see generate_car_inbetweens.py).

Each raw is palette-mapped to the approved sprite's palette and centred by whole
pixels, as build_car_sheet.py does (no new pixels), then placed by where it
landed: its screen angle is measured on the car's body (the drop shadow left
out, with build_car_noshadow.py's rule) as the long axis of the body pixels,
and compared with the axis of the two T-101 frames around it. ``position`` is 0
at the frame it came from and 1 at the next one. The slot 2k + 1 takes the raw
whose position lies inside (k, k + 1) and nearest the middle; ASSIGN can
override that per slot (recorded in the JSON).

Outputs game/art/car/car_iso.png (one row of 32 frames of 128 x 128) and
car_iso.json in T-013's convention, with step_deg 11.25, so
scripts/driving/car_sprite.gd reads it without a code change.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_car_sheet as cs  # noqa: E402
import build_car_noshadow as ns  # noqa: E402
import check_sprite_rules as rules  # noqa: E402
import generate_car_inbetweens as gen  # noqa: E402
from remove_car_shadow import write_png  # noqa: E402

REPO = cs.REPO
FRAME = 128
OLD = 16
COUNT = 32
STEP = 360.0 / COUNT
SHEET16 = cs.OUT_PNG
SHEET16_JSON = cs.OUT_JSON
OUT_PNG = "game/art/car/car_iso.png"
OUT_JSON = "game/art/car/car_iso.json"
RAW_DIR = gen.OUT_DIR

# Slot overrides after looking at the frames: new frame index -> T-101 frame
# whose raw goes there. Empty unless a measurement is misleading.
ASSIGN: dict[int, int] = {}


def frame_of(rows, i: int):
    return [r[i * FRAME:(i + 1) * FRAME] for r in rows]


def body_axis(rows) -> float:
    """Long-axis angle (0-180, clockwise from screen right) of the car's pixels without its drop shadow."""
    gone = ns.shadow_pixels(rows, 0, len(rows[0]))
    pts = [(x, y) for y, r in enumerate(rows) for x, p in enumerate(r) if p[3] and (x, y) not in gone]
    n = len(pts)
    mx = sum(p[0] for p in pts) / n
    my = sum(p[1] for p in pts) / n
    sxx = sum((p[0] - mx) ** 2 for p in pts) / n
    syy = sum((p[1] - my) ** 2 for p in pts) / n
    sxy = sum((p[0] - mx) * (p[1] - my) for p in pts) / n
    return (0.5 * math.degrees(math.atan2(2 * sxy, sxx - syy))) % 180.0


def unwrap_axes(axes):
    """Axis angles (mod 180) of a full clockwise turn, made increasing: frame 0 to 15 then back to 0 adds 360."""
    out = [axes[0]]
    for a in axes[1:]:
        prev = out[-1]
        # each step turns clockwise by 0 to 180 degrees; up to 20 back is read as a small step back
        out.append(prev + ((a - prev + 20.0) % 180.0) - 20.0)
    return out


def position(axis_new: float, a0: float, a1: float) -> float:
    """Where an axis angle lies from a0 (0) to a1 (1), with a0 < a1 unwrapped; mod-180 aware."""
    span = a1 - a0
    mid = (a0 + a1) / 2.0
    v = axis_new + 180.0 * round((mid - axis_new) / 180.0)
    return (v - a0) / span if span else 0.0


def measure(repo: Path = REPO):
    _, _, sheet16 = rules.decode_png((repo / SHEET16).read_bytes())
    old = [frame_of(sheet16, k) for k in range(OLD)]
    axes = unwrap_axes([body_axis(f) for f in old])
    axes_next = axes[1:] + [axes[0] + 360.0]
    raws = {}
    for k in range(OLD):
        path = repo / RAW_DIR / (gen.raw_name(k) + ".png")
        rows = cs.read_rows(path)
        raws[k] = {"path": path, "rows": rows, "axis": body_axis(rows),
                   "position": position(body_axis(rows), axes[k], axes_next[k])}
    return old, axes, raws


def assign(raws) -> dict[int, int | None]:
    """Slot k (between T-101 frames k and k+1) -> the T-101 frame whose raw goes there, or None."""
    out = {}
    for k in range(OLD):
        if (2 * k + 1) in ASSIGN:
            out[k] = ASSIGN[2 * k + 1]
            continue
        best = None
        for j, r in raws.items():
            g = (j + r["position"]) % OLD
            d = (g - k) % OLD
            if 0.0 < d < 1.0 and (best is None or abs(d - 0.5) < best[0]):
                best = (abs(d - 0.5), j)
        out[k] = best[1] if best else None
    return out


def seen_estimate(k: int, pos: float) -> float:
    """The nose angle on screen in T-101's 'seen' terms, interpolated between frames k and k+1."""
    a = cs.SOURCES[k][2]
    b = cs.SOURCES[(k + 1) % OLD][2]
    while b < a:
        b += 360
    return (a + pos * (b - a)) % 360.0


def build(repo: Path = REPO):
    old, axes, raws = measure(repo)
    slots = assign(raws)
    ref_rows = cs.read_rows(repo / cs.REFERENCE)
    palette = cs.palette_of(ref_rows)
    target = cs.bbox_centre(ref_rows)
    layout16 = json.loads((repo / SHEET16_JSON).read_text(encoding="utf-8"))
    sheet = [[] for _ in range(FRAME)]
    frames = []
    for i in range(COUNT):
        heading = i * STEP
        k = i // 2
        entry = {"index": i, "heading_deg": heading, "nose_screen_angle_deg": cs.iso_screen_angle(heading)}
        if i % 2 == 0:
            rows = old[k]
            f16 = layout16["frames"][k]
            entry.update({"t101_frame": k, "source": f16["source"], "made_by": f16["made_by"],
                          "seen_nose_screen_angle_deg_approx": f16["seen_nose_screen_angle_deg_approx"],
                          "colours_after": len(cs.palette_of(rows)), "shift_px": f16["shift_px"],
                          "note": "T-101's frame, copied unchanged"})
        else:
            j = slots[k]
            if j is None:
                raise ValueError(f"no raw landed between T-101 frames {k} and {k + 1}; set ASSIGN for frame {i}")
            r = raws[j]
            mapped = cs.map_to_palette(r["rows"], palette)
            dx, dy = cs.centring_shift(mapped, target)
            rows = cs.shift(mapped, dx, dy)
            pos = ((j + r["position"]) - k) % OLD
            if pos > OLD / 2:
                pos -= OLD
            entry.update({
                "source": str(r["path"].relative_to(repo)).replace("\\", "/"),
                "made_by": f"/rotate of T-101 frame {j} by {gen.DIRECTION_CHANGE} (T-102)",
                "rotated_from_t101_frame": j,
                "colours_before": len(cs.palette_of(r["rows"])), "colours_after": len(cs.palette_of(rows)),
                "shift_px": {"x": dx, "y": dy},
                "body_axis_deg": round(r["axis"], 1),
                "position_between_neighbours": round(pos, 2),
                "seen_nose_screen_angle_deg_approx": round(seen_estimate(k, pos)),
                "placed_by": "override (ASSIGN)" if i in ASSIGN else "measured position",
            })
        for y in range(FRAME):
            sheet[y].extend(rows[y])
        frames.append(entry)
    layout = dict(layout16)
    layout.update({
        "columns": COUNT, "frame_count": COUNT, "step_deg": STEP, "frames": frames,
        "order": "clockwise on screen: frame i shows world heading i * 11.25 degrees, Godot axes (y down), the same direction Godot's rotation grows",
        "frame_from_rotation": "posmod(roundi(rotation / deg_to_rad(11.25)), 32) for a car body whose nose is +x at rotation 0; the same formula as the placeholder sheets",
        "car_size_note": layout16["car_size_note"].replace("16 directions", "16 T-101 directions"),
        "record": {
            "made_by": "T-101's 16 frames (even frames, unchanged) and 16 PixelLab /rotate frames of T-102 (odd frames), assembled by game/tools/build_car_sheet32.py",
            "command": "python game/tools/build_car_sheet32.py",
            "processing": "odd frames: each opaque pixel mapped to the nearest colour (CIELAB) of the approved sprite's palette, whole-pixel centring, placed by measured heading; no new pixels",
            "t101_sheet": SHEET16,
            "pixellab_records": "each raw has its PixelLab record JSON next to it; every call is in game/art/pixellab-generation-log.jsonl",
            "task": "T-102",
            "resources_consulted": ["docs/visual-style.md", "docs/extended-narrative.md", "docs/drifting.md",
                                    "tasks/T-102-car-sprites-32-directions.md", "tasks/T-101-car-sprites-remaining-directions.md"],
        },
    })
    return sheet, layout, axes, raws, slots


def main(argv=None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--measure", action="store_true")
    args = p.parse_args(argv)
    if args.measure:
        old, axes, raws = measure()
        print("T-101 body axes:", [round(a, 1) for a in axes])
        slots = assign(raws)
        for k in range(OLD):
            r = raws[k]
            print(f"raw from T-101 frame {k:2d}: axis {r['axis']:6.1f}, position {r['position']:5.2f}")
        print("slots:", {2 * k + 1: v for k, v in slots.items()})
        return 0
    sheet, layout, _, _, _ = build()
    write_png(REPO / OUT_PNG, sheet)
    (REPO / OUT_JSON).write_text(json.dumps(layout, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"wrote {OUT_PNG} ({len(sheet[0])}x{len(sheet)}) and {OUT_JSON}")
    for f in layout["frames"]:
        if f["index"] % 2:
            print(f"  frame {f['index']:2d}: ideal {f['nose_screen_angle_deg']:6.1f}, seen ~{f['seen_nose_screen_angle_deg_approx']:3d}, "
                  f"position {f['position_between_neighbours']:5.2f}, from T-101 frame {f['rotated_from_t101_frame']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
