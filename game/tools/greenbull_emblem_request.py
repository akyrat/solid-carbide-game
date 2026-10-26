#!/usr/bin/env python3
"""Write the pixflux request body for a Greenbull emblem version (T-294).
Usage: greenbull_emblem_request.py <init.png> <strength> <out.json>"""
import base64
import json
import sys

DESCRIPTION = (
    "bold sports brand logo emblem, aggressive bull head, front view, symmetric, angular shield-shaped face "
    "tapering to the muzzle, thick horns sweeping up and forward to sharp points, heavy furrowed brow, narrow "
    "glowing yellow eyes, flared nostrils, small yellow nose ring, lightning blaze down the face, dark green head, "
    "light green horns and facets, thick black outline, flat graphic vector-like pixel art icon"
)


def body(init_png: bytes, strength: int) -> dict:
    return {
        "description": DESCRIPTION,
        "negative_description": "circle, sun, two bulls, whole body, text, letters, red, cute, gradient",
        "image_size": {"width": 128, "height": 128},
        "no_background": True,
        "outline": "single color black outline",
        "shading": "flat shading",
        "detail": "low detail",
        "text_guidance_scale": 8,
        "init_image": {"type": "base64", "base64": base64.b64encode(init_png).decode()},
        "init_image_strength": strength,
    }


if __name__ == "__main__":
    with open(sys.argv[1], "rb") as f:
        data = f.read()
    with open(sys.argv[3], "w", encoding="utf-8") as f:
        json.dump(body(data, int(sys.argv[2])), f)
