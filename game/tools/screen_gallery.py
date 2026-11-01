#!/usr/bin/env python3
"""The screen gallery (task T-479): one 1280 x 720 screenshot of every screen the player can meet.

  python game/tools/screen_gallery.py [--out screenshots/mvp-gallery] [--no-text]

Runs game/tools/screen_gallery.gd in a real Godot window (not headless; about a minute), then
checks the manifest.json it wrote against the PNGs on disk and prints the screens saved and any
not reached. Unless --no-text, it also writes the text inventory (text_inventory.py) next to them.
GODOT_BIN comes from the environment or .env at the repo root, like the other tools.
The output folder is git-ignored (/screenshots/) and outside game/, so Godot never imports it.
"""
import argparse
import json
import os
import re
import struct
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import text_inventory  # noqa: E402

SIZE = (1280, 720)
TIMEOUT_SECONDS = 600


def godot_bin():
    value = os.environ.get("GODOT_BIN", "")
    env = ROOT / ".env"
    if not value and env.exists():
        for line in env.read_text(encoding="utf-8").splitlines():
            m = re.match(r"\s*GODOT_BIN\s*=\s*(.*?)\s*$", line)
            if m:
                value = m.group(1).strip("\"'")
    return value


def png_size(path):
    """(width, height) from a PNG's header, or None when it is not a PNG."""
    with open(path, "rb") as f:
        head = f.read(24)
    if len(head) < 24 or head[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return struct.unpack(">II", head[16:24])


def check_manifest(out_dir):
    """Problems with a gallery folder: [] when the manifest lists real 1280 x 720 PNGs only."""
    out_dir = Path(out_dir)
    path = out_dir / "manifest.json"
    if not path.exists():
        return ["no manifest.json"]
    manifest = json.loads(path.read_text(encoding="utf-8"))
    problems, names = [], set()
    for s in manifest.get("screens", []):
        for key in ("name", "file", "how"):
            if not s.get(key):
                problems.append(f"{s.get('name', '?')}: missing {key}")
        if s.get("name") in names:
            problems.append(f"{s['name']}: listed twice")
        names.add(s.get("name"))
        png = out_dir / s.get("file", "")
        if not png.is_file():
            problems.append(f"{s.get('name')}: {s.get('file')} is not on disk")
        elif png_size(png) != SIZE:
            problems.append(f"{s.get('name')}: {s.get('file')} is {png_size(png)}, not {SIZE}")
    for n in manifest.get("not_reached", []):
        if not n.get("name") or not n.get("reason"):
            problems.append(f"not_reached entry without name and reason: {n}")
    return problems


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", default=str(ROOT / "screenshots" / "mvp-gallery"))
    ap.add_argument("--no-text", action="store_true", help="skip the text inventory")
    args = ap.parse_args(argv)
    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    for old in list(out.glob("*.png")) + [out / "manifest.json"]:
        old.unlink(missing_ok=True)
    binary = godot_bin()
    if not binary or not Path(binary).is_file():
        print("GODOT_BIN is not set or does not exist (set it in the environment or .env).", file=sys.stderr)
        return 2
    game = ROOT / "game"
    subprocess.run([binary, "--headless", "--path", str(game), "--import"], capture_output=True, timeout=TIMEOUT_SECONDS)
    cmd = [binary, "--path", str(game), "--resolution", f"{SIZE[0]}x{SIZE[1]}", "-s", "res://tools/screen_gallery.gd",
           "--", f"--out={out.as_posix()}"]
    result = subprocess.run(cmd, timeout=TIMEOUT_SECONDS)
    problems = check_manifest(out)
    manifest = out / "manifest.json"
    if manifest.exists():
        m = json.loads(manifest.read_text(encoding="utf-8"))
        print(f"{len(m['screens'])} screens saved in {out}")
        for n in m["not_reached"]:
            print(f"  not reached: {n['name']}: {n['reason']}")
    for p in problems:
        print("  problem:", p)
    if not args.no_text:
        text_inventory.write(text_inventory.build(game), out / "text_inventory.json")
        print(f"text inventory written to {out / 'text_inventory.json'} (+ .csv)")
    return 0 if result.returncode == 0 and not problems else 1


if __name__ == "__main__":
    sys.exit(main())
