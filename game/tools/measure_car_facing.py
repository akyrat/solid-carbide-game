#!/usr/bin/env python3
"""Measures where each frame of the car sheet is drawn pointing on screen (task T-583, fix A).

The frame remap (scripts/driving/car_facing.gd, data/car_facing.json frame_remap) draws each
heading with the frame whose drawing points closest on screen; it reads each frame's drawn angle
from the sheet's JSON, ``seen_nose_screen_angle_deg_approx`` (degrees, 0 = screen right,
clockwise). This script refreshes those angles after frames are redrawn (T-584: frames 19 to 23,
2 and 3), so the remap follows the new art with no code change.

How it measures: the long axis of the car's pixels with its drop shadow left out
(build_car_noshadow.py's rule; the same axis T-102 placed its frames by), turned into the nose's
direction by taking the end nearer the frame's ideal angle. The bare axis is biased by the
isometric drawing (the visible side and roof), so it is calibrated: for every frame NOT being
re-measured, the bias is its recorded angle minus its measured axis; a re-measured frame gets its
measured axis plus the bias interpolated (around the circle, by measured angle) from those
frames. Leave-one-out on the T-102 sheet, every frame against its recorded angle: mean error
3.2 degrees, worst 13 (frames 2, 7, 8 and 20; the recorded angles are themselves estimates).
When a redrawn frame reads wrong by eye, set it by hand with --set (recorded as by eye).

Usage, from the repo root:
    python game/tools/measure_car_facing.py                         # report only, writes nothing
    python game/tools/measure_car_facing.py --frames 19-23,2,3 --write
    python game/tools/measure_car_facing.py --set 22=300 --write     # an angle read by eye
Options: --sheet PNG and --json JSON (default the car sheet, game/art/car/car_iso.png/.json).
The JSON's other fields are kept; only the named frames' angle and its "seen_source" change.
The tilt and shadowless sheets share these columns, so they need nothing of their own.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_car_noshadow as ns  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
SHEET = GAME / "art" / "car" / "car_iso.png"
LAYOUT = GAME / "art" / "car" / "car_iso.json"
FIELD = "seen_nose_screen_angle_deg_approx"
SOURCE = "seen_source"


def wrap180(a: float) -> float:
    return (a + 180.0) % 360.0 - 180.0


def body_axis(rows) -> float:
    """Long-axis angle (0-180, clockwise from screen right) of the frame's pixels without its drop shadow."""
    gone = ns.shadow_pixels(rows, 0, len(rows[0]))
    pts = [(x, y) for y, r in enumerate(rows) for x, p in enumerate(r) if p[3] and (x, y) not in gone]
    if len(pts) < 2:
        return 0.0
    n = len(pts)
    mx = sum(p[0] for p in pts) / n
    my = sum(p[1] for p in pts) / n
    sxx = sum((p[0] - mx) ** 2 for p in pts) / n
    syy = sum((p[1] - my) ** 2 for p in pts) / n
    sxy = sum((p[0] - mx) * (p[1] - my) for p in pts) / n
    return (0.5 * math.degrees(math.atan2(2 * sxy, sxx - syy))) % 180.0


def nose_end(axis: float, ideal: float) -> float:
    """The axis direction (axis or axis + 180) nearer the ideal nose angle, 0-360."""
    a = axis % 360.0
    b = (axis + 180.0) % 360.0
    return a if abs(wrap180(a - ideal)) <= abs(wrap180(b - ideal)) else b


def frames_of(sheet_png: Path, layout: dict):
    _, _, rows = ns.read_png(sheet_png)
    fw, fh = int(layout["frame_width"]), int(layout["frame_height"])
    out = []
    for i in range(int(layout["frame_count"])):
        out.append([r[i * fw:(i + 1) * fw] for r in rows[:fh]])
    return out


def measured_axes(sheet_png: Path, layout: dict) -> list[float]:
    ideal = [float(f["nose_screen_angle_deg"]) for f in layout["frames"]]
    return [nose_end(body_axis(fr), ideal[i]) for i, fr in enumerate(frames_of(sheet_png, layout))]


def calibrated(measured: list[float], recorded: list[float], trusted: list[int], k: int) -> float:
    """Frame k's angle: its measured axis plus the bias (recorded - measured) of the trusted frames,
    interpolated around the circle by measured angle."""
    pts = sorted((measured[j] % 360.0, wrap180(recorded[j] - measured[j])) for j in trusted if j != k)
    if not pts:
        return measured[k] % 360.0
    m = measured[k] % 360.0
    below = [p for p in pts if p[0] <= m]
    above = [p for p in pts if p[0] > m]
    lo = below[-1] if below else (pts[-1][0] - 360.0, pts[-1][1])
    hi = above[0] if above else (pts[0][0] + 360.0, pts[0][1])
    t = (m - lo[0]) / (hi[0] - lo[0]) if hi[0] != lo[0] else 0.0
    return (m + lo[1] + t * (hi[1] - lo[1])) % 360.0


def parse_frames(text: str, count: int) -> list[int]:
    out: list[int] = []
    for part in filter(None, (p.strip() for p in text.split(","))):
        if "-" in part:
            a, b = part.split("-", 1)
            out.extend(range(int(a), int(b) + 1))
        else:
            out.append(int(part))
    for i in out:
        if not 0 <= i < count:
            raise SystemExit(f"frame {i} is not on the sheet (0 to {count - 1})")
    return sorted(set(out))


def measure(sheet_png: Path, layout: dict, frames: list[int]) -> dict[int, float]:
    """The new angle of each frame in `frames`, calibrated on every other frame."""
    measured = measured_axes(sheet_png, layout)
    recorded = [float(f[FIELD]) for f in layout["frames"]]
    trusted = [j for j in range(len(recorded)) if j not in frames]
    return {k: round(calibrated(measured, recorded, trusted, k), 1) for k in frames}


def leave_one_out(sheet_png: Path, layout: dict) -> list[float]:
    """Each frame measured with all the others as calibration, minus its recorded angle."""
    measured = measured_axes(sheet_png, layout)
    recorded = [float(f[FIELD]) for f in layout["frames"]]
    every = list(range(len(recorded)))
    return [wrap180(calibrated(measured, recorded, every, k) - recorded[k]) for k in every]


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--sheet", type=Path, default=SHEET)
    p.add_argument("--json", type=Path, default=LAYOUT)
    p.add_argument("--frames", default="", help="frames to re-measure, e.g. 19-23,2,3")
    p.add_argument("--set", action="append", default=[], metavar="FRAME=DEG", help="an angle read by eye")
    p.add_argument("--write", action="store_true", help="write the new angles into the JSON")
    args = p.parse_args(argv)
    layout = json.loads(args.json.read_text(encoding="utf-8"))
    count = int(layout["frame_count"])
    frames = parse_frames(args.frames, count)
    new = measure(args.sheet, layout, frames) if frames else {}
    by_eye = {}
    for s in args.set:
        k, v = s.split("=", 1)
        by_eye[parse_frames(k, count)[0]] = float(v) % 360.0
    if not frames and not by_eye:
        errs = leave_one_out(args.sheet, layout)
        print("frame | ideal | recorded | measured (calibrated on the others) | difference")
        for i, f in enumerate(layout["frames"]):
            print(f"{i:5d} | {float(f['nose_screen_angle_deg']):5.1f} | {float(f[FIELD]):8.1f} | "
                  f"{(float(f[FIELD]) + errs[i]) % 360.0:8.1f} | {errs[i]:+6.1f}")
        print(f"mean |difference| {sum(abs(e) for e in errs) / len(errs):.1f}, worst {max(abs(e) for e in errs):.1f}")
        return 0
    for k, v in sorted(new.items()):
        print(f"frame {k:2d}: recorded {float(layout['frames'][k][FIELD]):6.1f} -> measured {v:6.1f}")
    for k, v in sorted(by_eye.items()):
        print(f"frame {k:2d}: recorded {float(layout['frames'][k][FIELD]):6.1f} -> by eye {v:6.1f}")
    if args.write:
        for k, v in new.items():
            layout["frames"][k][FIELD] = v
            layout["frames"][k][SOURCE] = "measure_car_facing.py (T-583): calibrated body axis"
        for k, v in by_eye.items():
            layout["frames"][k][FIELD] = v
            layout["frames"][k][SOURCE] = "by eye (measure_car_facing.py --set)"
        args.json.write_text(json.dumps(layout, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {args.json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
