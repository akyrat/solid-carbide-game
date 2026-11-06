#!/usr/bin/env python3
"""Builds a PixelLab /animate-with-text-v3 request JSON (T-532, moved from art-archive/T-532/build_req.py).

Usage, from the repo root:
    python game/tools/pixellab_animate_req.py --first-frame ref.png --out req.json --seed 1 \
        [--action "text" | --action-file action.txt] [--frames 8]

The request is then sent with game/tools/pixellab_client.py inside a style loop run.
It makes no network call and spends nothing.
"""
import argparse
import base64
import json
from pathlib import Path

DEFAULT_ACTION = (
    "death animation: the lizard is hit and jolts back with its head thrown up, then collapses sideways "
    "onto its belly and side, legs curling and going limp, tail dropping flat, jaw hanging slack, eye closing; "
    "it ends lying still on the ground as a motionless corpse, the last two frames identical and still. "
    "The feet stay in place, it does not slide or move away. No blood, no liquid, no splatter, no particles, no shadow"
)


def build(first_frame: Path, action: str, frames: int, seed: int) -> dict:
    b64 = base64.b64encode(Path(first_frame).read_bytes()).decode()
    return {
        "first_frame": {"type": "base64", "base64": b64, "format": "png"},
        "action": action,
        "frame_count": frames,
        "no_background": True,
        "seed": seed,
    }


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--first-frame", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--seed", type=int, default=1)
    p.add_argument("--frames", type=int, default=8)
    g = p.add_mutually_exclusive_group()
    g.add_argument("--action")
    g.add_argument("--action-file")
    a = p.parse_args(argv)
    action = a.action or (Path(a.action_file).read_text(encoding="utf-8").strip() if a.action_file else DEFAULT_ACTION)
    req = build(Path(a.first_frame), action, a.frames, a.seed)
    Path(a.out).write_text(json.dumps(req), encoding="utf-8")
    print(a.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
