#!/usr/bin/env python3
"""Runs T-102's PixelLab /rotate calls for the 32-direction car (one per T-101 frame).

Usage, from the repo root:

    python game/tools/generate_car_inbetweens.py --plan      # print the calls, no call made
    python game/tools/generate_car_inbetweens.py --run       # make the missing calls

For each of the 16 frames of the T-101 sheet (game/art/car/car_iso.png, read
from git's T-101 version when the sheet already has 32 frames) it asks
/rotate for the same car turned by DIRECTION_CHANGE (clockwise on screen), to
be the in-between after it. A raw that already exists is never requested
again, so a rerun cannot pay twice; the first failed call stops the run (the
client itself never retries). Every call goes through pixellab_client.py, which
writes the record JSON and the log line.
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
TOOLS = Path(__file__).resolve().parent
OUT_DIR = "art-archive/T-102"
DIRECTION_CHANGE = 16
FRAME = 128
SHEET16 = "art-archive/T-102/car_iso_16_t101.png"  # T-101's sheet, kept for the build
REFERENCE = "game/art/car/car_sw_front.png"

# from_direction per T-101 frame: even frames their own compass direction; odd
# frames the compass direction nearest to the angle they are seen at (T-101).
FROM_DIRECTION = {
    0: "south-east", 1: "south", 2: "south", 3: "south", 4: "south-west", 5: "south-west",
    6: "west", 7: "west", 8: "north-west", 9: "north-west", 10: "north", 11: "north",
    12: "north-east", 13: "east", 14: "east", 15: "south-east",
}
# The approved second sample is the in-between after T-101 frame 2.
DONE = {2: "car_rot16_from_f02_south_raw"}

CONSULTED = [
    "docs/visual-style.md", "docs/extended-narrative.md",
    "tasks/T-102-car-sprites-32-directions.md", "tasks/T-101-car-sprites-remaining-directions.md",
    "art-archive/T-102/sample2_frame05_measure.json", "https://api.pixellab.ai/v2/openapi.json",
]


def raw_name(k: int) -> str:
    return DONE.get(k) or f"car_rot16_from_f{k:02d}_{FROM_DIRECTION[k]}_raw"


def png_b64(data: bytes) -> dict:
    return {"type": "base64", "base64": base64.b64encode(data).decode("ascii"), "format": "png"}


def frame_png(sheet_path: Path, k: int) -> bytes:
    from PIL import Image
    im = Image.open(sheet_path).convert("RGBA").crop((k * FRAME, 0, (k + 1) * FRAME, FRAME))
    buf = io.BytesIO()
    im.save(buf, format="PNG")
    return buf.getvalue()


def request(k: int, from_png: bytes, colour_png: bytes) -> dict:
    return {
        "image_size": {"width": FRAME, "height": FRAME},
        "from_image": png_b64(from_png),
        "color_image": png_b64(colour_png),
        "direction_change": DIRECTION_CHANGE,
        "view_change": None,
        "from_view": "high top-down",
        "to_view": "high top-down",
        "from_direction": FROM_DIRECTION[k],
        "to_direction": None,
        "isometric": True,
        "image_guidance_scale": 7.5,
    }


def pending(repo: Path = REPO) -> list[int]:
    return [k for k in range(16) if not (repo / OUT_DIR / (raw_name(k) + ".png")).is_file()]


def main(argv=None) -> int:
    p = argparse.ArgumentParser()
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--plan", action="store_true")
    g.add_argument("--run", action="store_true")
    p.add_argument("--req-dir", default=str(REPO / OUT_DIR / "requests"))
    args = p.parse_args(argv)
    todo = pending()
    for k in todo:
        print(f"T-101 frame {k:2d} -> /rotate +{DIRECTION_CHANGE}, from {FROM_DIRECTION[k]}, "
              f"for new frame {2 * k + 1}: {raw_name(k)}.png")
    print(f"{len(todo)} call(s), expected {len(todo)} generation(s)")
    if args.plan or not todo:
        return 0
    sheet = REPO / SHEET16
    colour = (REPO / REFERENCE).read_bytes()
    req_dir = Path(args.req_dir)
    req_dir.mkdir(parents=True, exist_ok=True)
    for k in todo:
        src = frame_png(sheet, k)
        (REPO / OUT_DIR / f"from_image_t101_frame{k:02d}.png").write_bytes(src)
        req_path = req_dir / f"{raw_name(k)}.json"
        req_path.write_text(json.dumps(request(k, src, colour)), encoding="utf-8")
        cmd = [sys.executable, str(TOOLS / "pixellab_client.py"), "generate", "--endpoint", "rotate",
               "--params-file", str(req_path), "--out-dir", OUT_DIR, "--name", raw_name(k), "--task", "T-102",
               "--notes", f"T-102 full set: /rotate of T-101 frame {k} (from_image art-archive/T-102/"
                          f"from_image_t101_frame{k:02d}.png) by direction_change {DIRECTION_CHANGE}, "
                          f"from_direction {FROM_DIRECTION[k]}, for new 32-direction frame {2 * k + 1}; "
                          f"color_image = {REFERENCE}"]
        for c in CONSULTED:
            cmd += ["--consulted", c]
        r = subprocess.run(cmd, cwd=REPO)
        if r.returncode != 0:
            print(f"call for T-101 frame {k} failed (exit {r.returncode}); stopping")
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
