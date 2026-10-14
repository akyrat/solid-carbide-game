#!/usr/bin/env python3
"""Request bodies for the sample short building, variant A (T-129): two flat facades and three rooftop props.

  python game/tools/short_building_requests.py --out-dir art-archive/T-129/requests

Only writes files; the paid calls are made one by one by pixellab_client.py.
"""
import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_buildings import b64_png  # noqa: E402
from PIL import Image  # noqa: E402

PALETTE = Path(__file__).resolve().parents[2] / "art-archive" / "T-064" / "palette.png"
NEGATIVE = "text, letters, words, logo, red, perspective, gradient, blur, sky, ground, street, car, people, fire"
PROP_NEGATIVE = NEGATIVE + ", base plate, platform, pedestal, shadow, building, wall"
SEED_BASE = 129000


def common(seed, negative):
    return {
        "negative_description": negative,
        "text_guidance_scale": 8,
        "shading": "detailed shading",
        "detail": "highly detailed",
        "color_image": {"type": "base64", "base64": b64_png(Image.open(PALETTE).convert("RGBA"))},
        "seed": seed,
    }


def requests_for_variant_a():
    out = {}
    for i, (name, side) in enumerate((("a_facade_left", "left"), ("a_facade_right", "right")), start=1):
        r = common(SEED_BASE + i, NEGATIVE)
        r.update({
            "description": (f"flat front view of the {side} wall of a five-floor Tokyo-style shop and office building at night, "
                            "dark navy concrete, rows of mostly dim windows, a few broken, light cracks, "
                            "a pink and cyan neon shop sign on the ground floor with abstract marks and no letters, "
                            "glow drawn in pixels, filling the whole image, no sky, no ground, retro pixel art"),
            "image_size": {"width": 384, "height": 160}, "view": "side", "isometric": False, "direction": "south",
            "no_background": False, "outline": "lineless",
        })
        out[name] = r
    props = {
        "a_prop_tank": "a rooftop water tank on short legs seen from above, rusty dark navy cylinder with a conical lid, pipes, low and wide, lying directly on the roof, pixel art",
        "a_prop_ac": "a group of three rooftop air-conditioning units with fans, grey-blue boxes with pipes and vents, low and wide, lying directly on the roof, pixel art",
        "a_prop_rubble": "a low heap of rubble and broken concrete slabs with bent rebar, low and wide, lying directly on the ground, pixel art",
    }
    for i, (name, d) in enumerate(props.items(), start=3):
        r = common(SEED_BASE + i, PROP_NEGATIVE)
        r.update({"description": d, "image_size": {"width": 96, "height": 96}, "view": "high top-down", "isometric": True,
                  "direction": "south", "no_background": True, "outline": "selective outline"})
        out[name] = r
    return out


# Full set (board's go 2026-10-14): variants B, C, D, six facades and three new props (nine calls).
VARIANTS = {
    "b": ("a six-floor Tokyo-style office building with a ribbon of narrow windows and small balconies", 160),
    "c": ("a six-floor Tokyo-style apartment block with balconies, air-conditioner boxes and drainpipes", 192),
    "d": ("a five-floor old Tokyo-style concrete shop house with roller shutters, awnings and a few boarded windows", 160),
}
NEW_PROPS = {
    "b_prop_signboard": "a blank dark rooftop billboard frame on steel legs with glowing neon strip lights along its edge, no letters, low and wide, lying directly on the roof, pixel art",
    "b_prop_antenna": "a rooftop radio antenna mast with crossbars and a small blinking light on a low square base box, thin and tall, no platform, pixel art",
    "c_prop_dish": "a rooftop ventilation unit with pipes and a satellite dish, grey-blue metal, low and wide, lying directly on the roof, pixel art",
}


def requests_full_set():
    out = {}
    seed = SEED_BASE + 10
    for v, (what, h) in VARIANTS.items():
        for side in ("left", "right"):
            seed += 1
            r = common(seed, NEGATIVE)
            r.update({
                "description": (f"flat front view of the {side} wall of {what} at night, dark navy concrete, rows of mostly dim windows, "
                                "a few broken, light cracks, a dim neon glow on the ground floor, glow drawn in pixels, "
                                "no signs, no letters, filling the whole image, no sky, no ground, retro pixel art"),
                "image_size": {"width": 384, "height": h}, "view": "side", "isometric": False, "direction": "south",
                "no_background": False, "outline": "lineless",
            })
            out[f"{v}_facade_{side}"] = r
    for name, d in NEW_PROPS.items():
        seed += 1
        r = common(seed, PROP_NEGATIVE)
        r.update({"description": d, "image_size": {"width": 96, "height": 96}, "view": "high top-down", "isometric": True,
                  "direction": "south", "no_background": True, "outline": "selective outline"})
        out[name] = r
    return out


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--full-set", action="store_true")
    a = ap.parse_args(argv)
    out = Path(a.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    reqs = requests_full_set() if a.full_set else requests_for_variant_a()
    for name, body in reqs.items():
        (out / f"{name}_request.json").write_text(json.dumps(body, indent=1))
        print("wrote", name, body["image_size"], "seed", body["seed"])


if __name__ == "__main__":
    main()
