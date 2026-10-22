#!/usr/bin/env python3
"""Request bodies for the creator's small and long buildings (T-257): six flat facades, in the style of T-129's short buildings.

  python game/tools/creator_building_requests.py --out-dir art-archive/T-257/requests

Only writes files; the paid calls are made one by one by pixellab_client.py. Small: look 0 and look 1, a left and a
right wall each (160 px = 5 units, the 6-unit footprint less a half-unit pavement margin each side). Long: look 0 and
look 1, one long wall each (352 px = 11 units); the long building's short ends reuse the small building's walls.
"""
import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from short_building_requests import NEGATIVE, common  # noqa: E402

SEED_BASE = 257000
SMALL = {
    "0": "a four-floor Tokyo-style concrete shop house with roller shutters, awnings and a few boarded windows",
    "1": "a four-floor Tokyo-style apartment building with small balconies, air-conditioner boxes and drainpipes",
}
LONG = {
    "0": "a four-floor Tokyo-style office building with a long ribbon of narrow windows",
    "1": "a four-floor Tokyo-style apartment block with a row of small balconies and many windows",
}


def request(what, side, width, seed):
    r = common(seed, NEGATIVE)
    r.update({
        "description": (f"flat front view of the {side} wall of {what} at night, dark navy concrete, rows of mostly dim windows, "
                        "a few broken, light cracks, a dim neon glow on the ground floor, glow drawn in pixels, "
                        "no signs, no letters, filling the whole image, no sky, no ground, retro pixel art"),
        "image_size": {"width": width, "height": 144}, "view": "side", "isometric": False, "direction": "south",
        "no_background": False, "outline": "lineless",
    })
    return r


def all_requests():
    out, seed = {}, SEED_BASE
    for look, what in SMALL.items():
        for side in ("left", "right"):
            seed += 1
            out[f"small_{look}_facade_{side}"] = request(what, side, 160, seed)
    for look, what in LONG.items():
        seed += 1
        out[f"long_{look}_facade"] = request(what, "long", 352, seed)
    return out


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--out-dir", required=True)
    a = ap.parse_args(argv)
    out = Path(a.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    for name, body in all_requests().items():
        (out / f"{name}_request.json").write_text(json.dumps(body, indent=1))
        print("wrote", name, body["image_size"], "seed", body["seed"])


if __name__ == "__main__":
    main()
