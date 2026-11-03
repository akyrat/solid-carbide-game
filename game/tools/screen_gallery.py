#!/usr/bin/env python3
"""The screen gallery (task T-479): one 1280 x 720 screenshot of every screen the player can meet.

  python game/tools/screen_gallery.py [--out screenshots/mvp-gallery] [--no-text]
  python game/tools/screen_gallery.py --sizes --out art-archive/T-493   (the scaling scan, T-493)
  python game/tools/screen_gallery.py --text-layout --out screenshots/text-editor   (the text layout capture, T-524)

Runs game/tools/screen_gallery.gd in a real Godot window (not headless; about a minute), then
checks the manifest.json it wrote against the PNGs on disk and prints the screens saved and any
not reached. Unless --no-text, it also writes the text inventory (text_inventory.py) next to them.
GODOT_BIN comes from the environment or .env at the repo root, like the other tools.
--text-layout (task T-524, text_layout.py and text_layout.gd) saves, for every screen and extra state, `<screen>.png` and
`<screen>_blank.png` (the same frame with every text node's text invisible, nothing moved), and text_layout.json: one row per
text node with its rect, font, size, colours, outline, alignment, wrap and its text inventory match, the templates
(components that show many texts), the fonts copied into fonts/, what is not capturable and the coverage of the text
inventory. Docs: game/docs/hud-and-menus/hud.md, "The text layout capture".
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
import scaling_report  # noqa: E402
import text_layout  # noqa: E402
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


def check_manifest(out_dir, size=SIZE):
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
        elif png_size(png) != tuple(size):
            problems.append(f"{s.get('name')}: {s.get('file')} is {png_size(png)}, not {tuple(size)}")
    for n in manifest.get("not_reached", []):
        if not n.get("name") or not n.get("reason"):
            problems.append(f"not_reached entry without name and reason: {n}")
    return problems


def run_gallery(binary, game, out, size):
    """One Godot run with the root window resized to size (any monitor)."""
    cmd = [binary, "--path", str(game), "--resolution", f"{size[0]}x{size[1]}", "-s", "res://tools/screen_gallery.gd",
           "--", f"--out={out.as_posix()}", f"--size={size[0]}x{size[1]}"]
    return subprocess.run(cmd, timeout=TIMEOUT_SECONDS).returncode


def scan_sizes(binary, game, out):
    """--sizes: the gallery at each of scaling_report.SIZES, then the report and a contact sheet per screen."""
    import time
    from PIL import Image
    t0 = time.time()
    manifests, bad = {}, 0
    for size in scaling_report.SIZES:
        sub = out / f"{size[0]}x{size[1]}"
        sub.mkdir(parents=True, exist_ok=True)
        for old in list(sub.glob("*.png")) + [sub / "manifest.json"]:
            old.unlink(missing_ok=True)
        bad += run_gallery(binary, game, sub, size) != 0
        mf = sub / "manifest.json"
        got = tuple(json.loads(mf.read_text(encoding="utf-8")).get("actual_window", size)) if mf.exists() else size
        for p in check_manifest(sub, got):
            print(f"  problem at {size[0]}x{size[1]}:", p)
            bad += 1
        if (sub / "manifest.json").exists():
            manifests[size] = json.loads((sub / "manifest.json").read_text(encoding="utf-8"))
    report = scaling_report.build_report(manifests)
    sheets = out / "contact_sheets"
    sheets.mkdir(exist_ok=True)
    for name in report["order"]:
        ims, labels = [], []
        for size, m in manifests.items():
            hit = next((s for s in m["screens"] if s["name"] == name), None)
            if hit:
                ims.append(Image.open(out / f"{size[0]}x{size[1]}" / hit["file"]))
                labels.append(f"{size[0]}x{size[1]}")
        if ims:
            scaling_report.contact_sheet(ims, labels, sheets / f"{name}.png")
    secs = time.time() - t0
    actual = {f"{s[0]}x{s[1]}": m.get("actual_window") for s, m in manifests.items()}
    note = f"Captured by resizing the root window to each size (actual windows: {actual}). Scan took {secs:.0f} s."
    scaling_report.save_json(report, out / "scaling_report.json")
    scaling_report.write_markdown(report, out / "scaling_report.md", note)
    flagged = [n for n in report["order"] if report["screens"][n]["flagged"]]
    print(note)
    print(f"{len(flagged)} of {len(report['order'])} screens shrink: {', '.join(flagged)}")
    print(f"report: {out / 'scaling_report.md'}")
    return 0 if not bad else 1


def build_text_layout(out, game):
    """Godot's raw capture to text_layout.json (text_layout.py); prints the counts and coverage; returns problems."""
    raw_path = out / "text_layout_nodes.json"
    if not raw_path.exists():
        return ["Godot wrote no text_layout_nodes.json"]
    raw = json.loads(raw_path.read_text(encoding="utf-8"))
    inventory = text_inventory.build(game)
    result = text_layout.build(raw, inventory, game, out)
    (out / "text_layout.json").write_text(json.dumps(result, indent=2, ensure_ascii=False) + chr(10), encoding="utf-8")
    raw_path.unlink()
    print(text_layout.summary(result))
    problems = text_layout.check_layout(out)
    pct = result["coverage"]["text_files"]["percent"]
    if pct < text_layout.COVERAGE_MIN:
        problems.append(f"text_files coverage {pct}% is under {text_layout.COVERAGE_MIN}%")
    return problems


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", default=str(ROOT / "screenshots" / "mvp-gallery"))
    ap.add_argument("--sizes", action="store_true", help="the scaling scan: capture at 5 sizes, write scaling_report.md/.json and contact sheets into --out")
    ap.add_argument("--text-layout", action="store_true", help="the text layout capture: a _blank.png per screen and text_layout.json (T-524)")
    ap.add_argument("--no-text", action="store_true", help="skip the text inventory")
    args = ap.parse_args(argv)
    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    for old in list(out.glob("*.png")) + [out / "manifest.json"]:
        old.unlink(missing_ok=True)
    if args.text_layout:
        for old in [out / "text_layout.json", out / "text_layout_nodes.json"]:
            old.unlink(missing_ok=True)
    binary = godot_bin()
    if not binary or not Path(binary).is_file():
        print("GODOT_BIN is not set or does not exist (set it in the environment or .env).", file=sys.stderr)
        return 2
    game = ROOT / "game"
    subprocess.run([binary, "--headless", "--path", str(game), "--import"], capture_output=True, timeout=TIMEOUT_SECONDS)
    if args.sizes:
        return scan_sizes(binary, game, out)
    extra = ["--text-layout"] if args.text_layout else []
    result = subprocess.run([binary, "--path", str(game), "--resolution", f"{SIZE[0]}x{SIZE[1]}", "-s", "res://tools/screen_gallery.gd",
                             "--", f"--out={out.as_posix()}"] + extra, timeout=TIMEOUT_SECONDS)
    problems = check_manifest(out)
    manifest = out / "manifest.json"
    if manifest.exists():
        m = json.loads(manifest.read_text(encoding="utf-8"))
        print(f"{len(m['screens'])} screens saved in {out}")
        for n in m["not_reached"]:
            print(f"  not reached: {n['name']}: {n['reason']}")
    for p in problems:
        print("  problem:", p)
    if args.text_layout:
        problems += build_text_layout(out, game)
    if not args.no_text:
        text_inventory.write(text_inventory.build(game), out / "text_inventory.json")
        print(f"text inventory written to {out / 'text_inventory.json'} (+ .csv)")
    return 0 if result.returncode == 0 and not problems else 1


if __name__ == "__main__":
    sys.exit(main())
