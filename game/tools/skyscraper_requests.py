#!/usr/bin/env python3
"""Request bodies for the three flat pieces of one skyscraper (T-064 round 2, approach A).

  python game/tools/skyscraper_requests.py 1 --out-dir art-archive/T-064/round2

Writes sky01_facade_request.json, sky01_shopfront_request.json, sky01_sign_request.json.
Only writes files; the paid calls are made by pixellab_client.py, one by one, by hand.
"""
import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_buildings import b64_png  # noqa: E402
from PIL import Image  # noqa: E402

PALETTE = Path(__file__).resolve().parents[2] / "art-archive" / "T-064" / "palette.png"
PALETTE_B = Path(__file__).resolve().parents[2] / "art-archive" / "T-064" / "round2" / "paletteB.png"
NEGATIVE = "text, letters, words, logo, red, ground, street, car, people, sky, fire"

# (facade material and window grid, sign colour) per skyscraper; the sample is tower 1.
TOWERS = {
    1: ("small square windows in a tight grid, dark navy concrete with thin horizontal ribs", "pink"),
}


def common(seed):
    return {
        "negative_description": NEGATIVE,
        "text_guidance_scale": 8,
        "shading": "detailed shading",
        "detail": "highly detailed",
        "view": "side",
        "isometric": False,
        "color_image": {"type": "base64", "base64": b64_png(Image.open(PALETTE).convert("RGBA"))},
        "seed": seed,
    }


def requests_for(n, seed_base=64064):
    grid, glow = TOWERS[n]
    facade = common(seed_base + 1)
    facade.update({
        "description": ("flat front view of a tall Tokyo-style skyscraper wall at night, repeating rows of " + grid +
                        ", a few windows lit pink or cyan, a few dark or cracked, light damage, filling the whole image, "
                        "no door, no ground, no sky, no sign, no letters"),
        "image_size": {"width": 256, "height": 256}, "direction": "south",
        "no_background": False, "outline": "lineless",
    })
    shop = common(seed_base + 2)
    shop.update({
        "description": ("flat front view of the ground floor of a Tokyo skyscraper at night, glass lobby entrance and "
                        "small shopfronts with awnings and shutters, dim pink and cyan neon glow, a little rubble, "
                        "light cracks, filling the whole image, no sky, no letters"),
        "image_size": {"width": 256, "height": 128}, "direction": "south",
        "no_background": False, "outline": "lineless",
    })
    sign = common(seed_base + 3)
    sign.update({
        "description": (f"tall vertical Japanese-style neon sign board, glowing {glow} abstract glyph shapes and stripes "
                        "on a dark panel, pixel glow, no letters, no words"),
        "image_size": {"width": 64, "height": 192}, "direction": "south",
        "no_background": True, "outline": "selective outline",
    })
    return {"facade": facade, "shopfront": shop, "sign": sign}


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("n", type=int)
    ap.add_argument("--out-dir", required=True)
    a = ap.parse_args(argv)
    out = Path(a.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    for name, body in (requests_b(a.n) if a.n > 1 else requests_for(a.n)).items():
        (out / f"sky{a.n:02d}_{name}_request.json").write_text(json.dumps(body, indent=1))
        print("wrote", out / f"sky{a.n:02d}_{name}_request.json", body["image_size"])



# ---- full set (towers 2 to 6), palette B (steel and glass), signs drawn by script ----
FACADES_B = {
    2: "tall narrow window columns separated by steel mullions",
    3: "wide horizontal ribbon windows with dark bands between the floors",
    4: "a regular grid of square glass windows with light concrete piers",
    5: "dense small windows in a regular grid, a few dark or cracked ones",
    6: "large glass curtain wall panels with thin frames, some panels lit",
}


def requests_b(n, seed_base=64100):
    """Two calls per tower (facade band, shopfront strip); the sign is drawn by script."""
    pal = {"type": "base64", "base64": b64_png(Image.open(PALETTE_B).convert("RGBA"))}
    common_b = {"negative_description": NEGATIVE, "text_guidance_scale": 8, "shading": "detailed shading",
                "detail": "highly detailed", "view": "side", "isometric": False, "color_image": pal,
                "direction": "south", "no_background": False, "outline": "lineless"}
    facade = dict(common_b, seed=seed_base + n * 2, image_size={"width": 256, "height": 256}, description=(
        "pixel art, flat seamless texture of a skyscraper wall seen straight on, fills the whole image edge to edge, "
        f"{FACADES_B[n]}, dark blue-grey steel and glass, pale white and pale blue lit windows, a few amber lit windows, "
        "night, no sky, no ground, no roof, no building outline, no sign, no letters"))
    shop = dict(common_b, seed=seed_base + n * 2 + 1, image_size={"width": 256, "height": 128}, description=(
        "pixel art, flat front view of the ground floor wall of one steel and glass skyscraper at night, lobby entrance and "
        "shop windows with small awnings, cool blue-grey walls, pale white and pale blue light, small amber lights, "
        "fills the whole image edge to edge, no street, no sky, no neighbouring buildings, no letters"))
    return {"facade": facade, "shopfront": shop}


if __name__ == "__main__":
    main()
