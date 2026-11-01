#!/usr/bin/env python3
"""Records the tutorial slides' four clips of the real car (task T-483).

Usage, from the repo root (needs a real window, not headless, and Pillow):

    python game/tools/record_tutorial_clips.py [--out DIR] [--only NAME ...] [--archive DIR] [--keep-frames]

Each clip is a fixture scene (game/tests/fixtures/tutorial_clip_<name>.tscn,
script tutorial_clip_demo.gd): the real car driven by scripted inputs on a plain
background, nothing else on screen. Godot's movie maker saves one PNG per
physics step (50 per second); every second one is kept (25 fps; every third, 16.7 fps, for the clips whose camera follows the car), cropped to
CLIP_SIZE around the screen centre (no scaling: pixels stay as drawn) and
written as a looping GIF with one shared palette, plus <name>.json saying how it
was made (the fixture's own trick, airtime and spin lines included).

Clips: drift (zoomed out, camera held), long_drift, alt_drift, ramp_jump.
Defaults: GIFs and records in game/art/tutorial/clips/, every take (the GIF as
recorded) copied to art-archive/T-483/takes/ with a number.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

CLIP_SIZE = (480, 320)
FPS = 50
KEEP_EVERY = 2          # 50 -> 25 frames per second
# The clips whose camera follows the car redraw the whole frame each time, so their GIFs are bigger:
# they keep every 3rd step (16.7 frames per second) to stay near the 1.5 MB aim.
CLIP_EVERY = {"long_drift": 3, "alt_drift": 3, "ramp_jump": 3}
MAX_BYTES = 1_500_000   # the board's aim for a slide
CLIPS = ["drift", "long_drift", "alt_drift", "ramp_jump"]
REPO = Path(__file__).resolve().parents[2]
GAME = REPO / "game"
FIXTURE = "res://tests/fixtures/tutorial_clip_%s.tscn"


def godot_bin() -> str:
    env = os.environ.get("GODOT_BIN")
    if env:
        return env
    envfile = REPO / ".env"
    if envfile.exists():
        for line in envfile.read_text().splitlines():
            m = re.match(r"\s*GODOT_BIN\s*=\s*(.*)", line)
            if m:
                return m.group(1).strip().strip("\"'")
    raise SystemExit("GODOT_BIN is not set (environment or .env)")


def crop_box(w: int, h: int, size=CLIP_SIZE) -> tuple[int, int, int, int]:
    x0 = (w - size[0]) // 2
    y0 = (h - size[1]) // 2
    return x0, y0, x0 + size[0], y0 + size[1]


def assemble(frames_dir: Path, out: Path, every: int = KEEP_EVERY, colors: int = 128) -> int:
    """Crops the movie's frames and writes a looping GIF with one shared palette. Returns the frame count."""
    from PIL import Image
    files = sorted(frames_dir.glob("f*.png"))[::every]
    if not files:
        raise FileNotFoundError(f"no frames in {frames_dir}")
    ims = []
    for f in files:
        im = Image.open(f).convert("RGB")
        ims.append(im.crop(crop_box(*im.size)))
    sample = ims[::max(1, len(ims) // 10)]
    strip = Image.new("RGB", (CLIP_SIZE[0], CLIP_SIZE[1] * len(sample)))
    for i, im in enumerate(sample):
        strip.paste(im, (0, i * CLIP_SIZE[1]))
    pal = strip.quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.NONE)
    q = [im.quantize(palette=pal, dither=Image.NONE) for im in ims]
    out.parent.mkdir(parents=True, exist_ok=True)
    q[0].save(out, save_all=True, append_images=q[1:], duration=int(1000 * every / FPS), loop=0, optimize=True)
    return len(q)


def record(name: str, out_dir: Path, archive: Path | None, keep_frames: bool = False) -> dict:
    tmp = Path(tempfile.mkdtemp(prefix=f"clip_{name}_"))
    try:
        cmd = [godot_bin(), "--path", str(GAME), "--write-movie", (tmp / "f.png").as_posix(),
               "--fixed-fps", str(FPS), FIXTURE % name]
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        log = [l.split("tutorial_clip_demo: ", 1)[1] for l in proc.stdout.splitlines() if "tutorial_clip_demo: " in l]
        gif = out_dir / f"{name}.gif"
        every = CLIP_EVERY.get(name, KEEP_EVERY)
        n = assemble(tmp, gif, every=every)
        size = gif.stat().st_size
        record_data = {
            "clip": name,
            "task": "T-483",
            "fixture": FIXTURE % name,
            "script": "game/tests/fixtures/tutorial_clip_demo.gd",
            "recorder": "game/tools/record_tutorial_clips.py",
            "size_px": list(CLIP_SIZE),
            "fps": round(FPS / every, 1),
            "frames": n,
            "seconds": round(n * every / FPS, 2),
            "bytes": size,
            "scale": "none (1 screen pixel = 1 GIF pixel, a crop of the 1152 x 648 window)",
            "tricks": [l for l in log if l.startswith("trick ")],
            "air": [l for l in log if l.startswith("airtime") or l.startswith("landed")],
            "how": "the real car (car.gd) and its art on the plain grid, driven by scripted inputs; Godot movie maker, every %dth physics step kept" % every + "",
        }
        (out_dir / f"{name}.json").write_text(json.dumps(record_data, indent=2) + "\n")
        if archive is not None:
            archive.mkdir(parents=True, exist_ok=True)
            k = len(list(archive.glob(f"{name}_take*.gif"))) + 1
            shutil.copyfile(gif, archive / f"{name}_take{k:02d}.gif")
        if keep_frames:
            print(f"frames kept in {tmp}")
            tmp = None
        return record_data
    finally:
        if tmp is not None:
            shutil.rmtree(tmp, ignore_errors=True)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(GAME / "art" / "tutorial" / "clips"))
    ap.add_argument("--archive", default=str(REPO / "art-archive" / "T-483" / "takes"))
    ap.add_argument("--no-archive", action="store_true")
    ap.add_argument("--only", nargs="*", choices=CLIPS)
    ap.add_argument("--keep-frames", action="store_true")
    a = ap.parse_args(argv)
    bad = 0
    for name in (a.only or CLIPS):
        d = record(name, Path(a.out), None if a.no_archive else Path(a.archive), a.keep_frames)
        flag = "" if d["bytes"] <= MAX_BYTES else "  (over 1.5 MB!)"
        print(f"{name}: {d['frames']} frames, {d['seconds']} s, {d['bytes']} bytes{flag}")
        bad += d["bytes"] > MAX_BYTES
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
