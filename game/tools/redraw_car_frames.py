#!/usr/bin/env python3
"""Helper for T-584's redraw of the car sheet's frames 19-23, 2 and 3 (Visual style, Decisions, "Redrawn car frames").

  python game/tools/redraw_car_frames.py backup                     keep the old sheets in art-archive/T-584/old/ (once)
  python game/tools/redraw_car_frames.py call --frame K --source S --change D [--version N] [--notes ...]
        ONE paid PixelLab /rotate call (inside a style loop run only): frame S of the live sheet turned by D degrees
        (positive = clockwise on screen), raw saved in art-archive/T-584/raw/, then processed (see `process`).
  python game/tools/redraw_car_frames.py process RAW.png --frame K [--out PNG]
        free: the raw mapped to the car's 33-colour palette (nearest colour), centred by whole pixels like every
        other frame; prints the style-rule check and the measured screen angle against the target.
  python game/tools/redraw_car_frames.py install FRAME.png --frame K --made-by TEXT
        puts a processed frame into game/art/car/car_iso.png, records it in car_iso.json, rebuilds the shadowless sheet.
Targets (screen angle of the nose, degrees clockwise from screen right) are TARGETS below.
"""
from __future__ import annotations

import argparse
import base64
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
import build_car_sheet as cs  # noqa: E402
import measure_car_facing as mf  # noqa: E402

FRAME = 128
SHEET = REPO / "game/art/car/car_iso.png"
LAYOUT = REPO / "game/art/car/car_iso.json"
ARCHIVE = REPO / "art-archive/T-584"
# Where each redrawn frame should point on screen: the ideal, except that frames 2, 3 and 23 are nudged
# toward their neighbours' real angles (frame 1 is drawn at 47, frame 4 at 90, frame 24 at 320).
TARGETS = {19: 237, 20: 254, 21: 271, 22: 288, 23: 305, 2: 61, 3: 76}
COMPASS = {"south-east": 25, "south": 90, "south-west": 155, "west": 178, "north-west": 205, "north": 260,
           "north-east": 320, "east": 360}


def compass_for(angle: float) -> str:
    return min(COMPASS, key=lambda k: abs(mf.wrap180(COMPASS[k] - angle)))


def cut(sheet: Path, k: int):
    return [r[k * FRAME:(k + 1) * FRAME] for r in cs.rules.decode_png(sheet.read_bytes())[2]]


def save(rows, path: Path):
    from PIL import Image
    im = Image.new("RGBA", (len(rows[0]), len(rows)))
    im.putdata([p for r in rows for p in r])
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)


def b64(data: bytes) -> dict:
    return {"type": "base64", "base64": base64.b64encode(data).decode("ascii"), "format": "png"}


def process_rows(raw_rows):
    ref = cs.read_rows(REPO / cs.REFERENCE)
    mapped = cs.map_to_palette(raw_rows, cs.palette_of(ref))
    dx, dy = cs.centring_shift(mapped, cs.bbox_centre(ref))
    return cs.shift(mapped, dx, dy), (dx, dy)


def measure_rows(rows, k: int) -> float:
    """Screen angle of the nose of a candidate for slot k, calibrated on the frames that are not being redrawn."""
    layout = json.loads(LAYOUT.read_text(encoding="utf-8"))
    frames = mf.frames_of(SHEET, layout)
    frames[k] = rows
    ideal = [float(f["nose_screen_angle_deg"]) for f in layout["frames"]]
    axes = [mf.nose_end(mf.body_axis(fr), ideal[i]) for i, fr in enumerate(frames)]
    recorded = [float(f[mf.FIELD]) for f in layout["frames"]]
    trusted = [j for j in range(len(recorded)) if j not in TARGETS]
    return round(mf.calibrated(axes, recorded, trusted, k), 1)


def do_process(raw: Path, k: int, out: Path | None) -> Path:
    rows, shift = process_rows(cs.read_rows(raw))
    out = out or ARCHIVE / "candidates" / (raw.stem.replace("_raw", "") + ".png")
    save(rows, out)
    angle = measure_rows(rows, k)
    print(f"processed -> {out}\n  shift {shift}, colours {len(cs.palette_of(rows))}")
    print(f"  frame {k}: nose seen at {angle} degrees on screen, target {TARGETS[k]} "
          f"({mf.wrap180(angle - TARGETS[k]):+.1f} off)")
    r = subprocess.run([sys.executable, str(TOOLS / "style_rules.py"), "art", str(out), "--size", "128x128",
                        "--max-colors", "33", "--allow-red", "230,110,102"], cwd=REPO, capture_output=True, text=True)
    print("  style_rules:", "ok" if r.returncode == 0 else "FAILED " + r.stdout.strip()[:600])
    return out


def do_backup():
    old = ARCHIVE / "old"
    if (old / "car_iso.png").exists():
        print("already backed up")
        return
    old.mkdir(parents=True, exist_ok=True)
    for name in ("car_iso.png", "car_iso.json", "car_iso_noshadow.png", "car_iso_noshadow.json", "car_iso_tilt.png"):
        (old / name).write_bytes((REPO / "game/art/car" / name).read_bytes())
    for k in TARGETS:
        save(cut(old / "car_iso.png", k), old / f"frame_{k:02d}.png")
    print("backed up to", old)


def do_call(a):
    layout = json.loads(LAYOUT.read_text(encoding="utf-8"))
    seen = float(layout["frames"][a.source][mf.FIELD])
    raw_dir = ARCHIVE / "raw"
    name = f"frame{a.frame:02d}_from{a.source:02d}_{a.change:+d}_v{a.version}_raw"
    src_path = raw_dir / f"{name}_input.png"
    save(cut(SHEET, a.source), src_path)
    direction = a.from_direction or compass_for(seen)
    colour = (REPO / cs.REFERENCE).read_bytes()
    body = {"image_size": {"width": FRAME, "height": FRAME}, "from_image": b64(src_path.read_bytes()),
            "color_image": b64(colour), "direction_change": a.change, "view_change": None,
            "from_view": "high top-down", "to_view": "high top-down", "from_direction": direction,
            "to_direction": None, "isometric": True, "image_guidance_scale": 7.5}
    req = raw_dir / f"{name}_request.json"
    req.write_text(json.dumps(body), encoding="utf-8")
    cmd = [sys.executable, str(TOOLS / "pixellab_client.py"), "generate", "--endpoint", "rotate",
           "--params-file", str(req), "--out-dir", str(raw_dir), "--name", name, "--task", "T-584",
           "--notes", f"T-584 redraw of frame {a.frame}: /rotate of live-sheet frame {a.source} (seen {seen}) by "
                      f"{a.change}, from_direction {direction}, target {TARGETS[a.frame]}. {a.notes}",
           "--consulted", "docs/visual-style.md", "--consulted", "docs/drifting.md",
           "--consulted", "art-archive/T-580/screenshots/frames_vs_ideal_arrow.png"]
    r = subprocess.run(cmd, cwd=REPO)
    if r.returncode != 0:
        raise SystemExit(r.returncode)
    do_process(raw_dir / f"{name}.png", a.frame, ARCHIVE / "candidates" / f"frame{a.frame:02d}_v{a.version}.png")


def do_install(path: Path, k: int, made_by: str):
    sheet_rows = cs.rules.decode_png(SHEET.read_bytes())[2]
    new = cs.read_rows(path)
    for y in range(FRAME):
        sheet_rows[y][k * FRAME:(k + 1) * FRAME] = new[y]
    layout = json.loads(LAYOUT.read_text(encoding="utf-8"))
    angle = measure_rows(new, k)          # measured before the sheet changes, against the other frames
    save(sheet_rows, SHEET)
    e = layout["frames"][k]
    e.update({"made_by": made_by, "source": str(path.resolve().relative_to(REPO)).replace("\\", "/"),
              mf.FIELD: angle, mf.SOURCE: "measure_car_facing.py (T-584): calibrated body axis",
              "redrawn_by": "T-584", "colours_after": len(cs.palette_of(new))})
    for stale in ("body_axis_deg", "position_between_neighbours", "placed_by", "rotated_from_t101_frame", "t101_frame",
                  "colours_before", "shift_px", "note"):
        e.pop(stale, None)
    LAYOUT.write_text(json.dumps(layout, indent=2) + "\n", encoding="utf-8")
    subprocess.run([sys.executable, str(TOOLS / "build_car_noshadow.py")], cwd=REPO, check=True)
    print(f"installed frame {k}, seen angle {angle}")


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("backup")
    c = sub.add_parser("call")
    c.add_argument("--frame", type=int, required=True, choices=sorted(TARGETS))
    c.add_argument("--source", type=int, required=True)
    c.add_argument("--change", type=int, required=True)
    c.add_argument("--version", type=int, default=1)
    c.add_argument("--from-direction", choices=sorted(COMPASS))
    c.add_argument("--notes", default="")
    pr = sub.add_parser("process")
    pr.add_argument("raw", type=Path)
    pr.add_argument("--frame", type=int, required=True, choices=sorted(TARGETS))
    pr.add_argument("--out", type=Path)
    i = sub.add_parser("install")
    i.add_argument("png", type=Path)
    i.add_argument("--frame", type=int, required=True, choices=sorted(TARGETS))
    i.add_argument("--made-by", required=True)
    a = p.parse_args(argv)
    if a.cmd == "backup":
        do_backup()
    elif a.cmd == "call":
        do_call(a)
    elif a.cmd == "process":
        do_process(a.raw, a.frame, a.out)
    else:
        do_install(a.png, a.frame, a.made_by)


if __name__ == "__main__":
    main()
