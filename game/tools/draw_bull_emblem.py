"""T-294 style loop, version 1 base shape: Greenbull's emblem, a bull's head, drawn by script (free).

Front-facing, symmetric bull's head at 128 x 128 on a transparent background, in Greenbull's exact colours
(Visual style, Content, "Rules", rule 6): dark green leads (the head), light green supports it (the horns and
the angry brow chevron), yellow is a small accent (the eyes and the nose ring). A near-black outline, 2 px,
so it reads on dark and light backgrounds and at 32 x 32. One extra darker green for the nostrils and muzzle line.
Every pixel is fully opaque or fully transparent (rule 1).

Usage: python draw_bull_v1.py <out.png> [--preview <preview.png>]
"""
from __future__ import annotations

import argparse
import math

from PIL import Image, ImageDraw

W = H = 128
CX = 64  # the axis of symmetry is between pixel 63 and 64

DARK = (12, 76, 44, 255)
LIGHT = (104, 220, 96, 255)
YELLOW = (247, 208, 52, 255)
DEEP = (6, 44, 26, 255)      # the one extra darker green (nostrils, muzzle line)
OUTLINE = (10, 16, 14, 255)  # near-black outline


def mirror_x(x: float) -> float:
    return 2 * CX - 1 - x


def mirror_poly(pts):
    return [(mirror_x(x), y) for x, y in pts]


def sym_polygon(d: ImageDraw.ImageDraw, pts, fill) -> None:
    d.polygon(pts, fill=fill)
    d.polygon(mirror_poly(pts), fill=fill)


def bezier(p0, p1, p2, t):
    a = (1 - t) ** 2
    b = 2 * (1 - t) * t
    c = t ** 2
    return (a * p0[0] + b * p1[0] + c * p2[0], a * p0[1] + b * p1[1] + c * p2[1])


def horn(d: ImageDraw.ImageDraw, fill, tip_fill, r0=10.0, r1=3.2, tip_from=0.88) -> None:
    """A thick horn sweeping out from the skull and curving up, as a chain of discs, both sides."""
    p0, p1, p2 = (46, 44), (6, 46), (13, 9)
    steps = 90
    for i in range(steps + 1):
        t = i / steps
        x, y = bezier(p0, p1, p2, t)
        r = r0 + (r1 - r0) * t
        col = tip_fill if t >= tip_from else fill
        for xx in (x, mirror_x(x)):
            d.ellipse([xx - r, y - r, xx + r, y + r], fill=col)


def head(d: ImageDraw.ImageDraw, fill) -> None:
    # Left half of the head, from the top of the skull down to the muzzle's middle; mirrored.
    skull = [
        (CX - 0.5, 34), (52, 35), (42, 39), (36, 46),   # crown
        (35, 56), (38, 68), (42, 80),                   # cheek, narrowing
        (42, 90), (38, 100), (39, 110), (45, 117),      # muzzle flares out, wide and square
        (55, 120), (CX - 0.5, 120),
    ]
    sym_polygon(d, skull, fill)
    # Ears: pointed, sticking out sideways below the horns.
    ear = [(37, 50), (18, 54), (14, 59), (22, 62), (37, 62)]
    sym_polygon(d, ear, fill)


def details(d: ImageDraw.ImageDraw) -> None:
    # Light-green brow chevron: an angry V across the forehead, meeting low between the eyes.
    brow = [(39, 49), (50, 52), (CX - 0.5, 60), (CX - 0.5, 67), (49, 59), (38, 56)]
    sym_polygon(d, brow, LIGHT)
    # Inner ear in light green.
    inner_ear = [(33, 55), (22, 57), (24, 59), (33, 59)]
    sym_polygon(d, inner_ear, LIGHT)
    # Eyes: slanted yellow slits under the brow, with a near-black frame.
    eye_frame = [(39, 58), (51, 63), (52, 69), (40, 64)]
    sym_polygon(d, eye_frame, OUTLINE)
    eye = [(41, 60), (50, 64), (50, 67), (42, 64)]
    sym_polygon(d, eye, YELLOW)
    # Forehead ridge in light green down the face's middle, a narrow stripe.
    d.rectangle([CX - 2, 70, CX + 1, 88], fill=LIGHT)
    # Muzzle line: a darker band across.
    sym_polygon(d, [(41, 93), (CX - 0.5, 91), (CX - 0.5, 94), (41, 96)], DEEP)
    # Nostrils: two near-black slanted ovals.
    sym_polygon(d, [(44, 101), (51, 100), (54, 105), (49, 109), (43, 107)], OUTLINE)
    # Nose ring in yellow: a thick ring hanging from the septum.
    ring_c, ring_y, ro, ri = CX - 0.5, 113, 9.5, 5.0
    d.ellipse([ring_c - ro, ring_y - ro, ring_c + ro, ring_y + ro], fill=OUTLINE)
    d.ellipse([ring_c - ro + 2, ring_y - ro + 2, ring_c + ro - 2, ring_y + ro - 2], fill=YELLOW)
    d.ellipse([ring_c - ri, ring_y - ri, ring_c + ri, ring_y + ri], fill=OUTLINE)
    d.ellipse([ring_c - ri + 2, ring_y - ri + 2, ring_c + ri - 2, ring_y + ri - 2], fill=DARK)
    # Keep only the lower half of the ring outside the nose: the top is hidden behind the septum.
    d.rectangle([CX - 11, 102, CX + 10, 109], fill=DARK)


def outline(img: Image.Image, width: int = 2) -> Image.Image:
    """Add a near-black outline `width` px wide around every opaque pixel (4- then 8-neighbour steps)."""
    px = img.load()
    out = img.copy()
    opx = out.load()
    mask = {(x, y) for y in range(H) for x in range(W) if px[x, y][3] == 255}
    ring = set(mask)
    for step in range(width):
        grown = set()
        nbrs = [(1, 0), (-1, 0), (0, 1), (0, -1)] + ([(1, 1), (1, -1), (-1, 1), (-1, -1)] if step else [])
        for x, y in ring:
            for dx, dy in nbrs:
                q = (x + dx, y + dy)
                if 0 <= q[0] < W and 0 <= q[1] < H and q not in ring:
                    grown.add(q)
        for q in grown:
            opx[q] = OUTLINE
        ring |= grown
    return out


PALETTE = [DARK, LIGHT, YELLOW, DEEP, OUTLINE]


def nearest(rgb) -> tuple:
    return min(PALETTE, key=lambda c: sum((a - b) ** 2 for a, b in zip(rgb, c[:3])))


def remap(src: Image.Image, alpha_cut: int = 128) -> Image.Image:
    """Every pixel with alpha >= alpha_cut becomes the nearest palette colour; the rest fully transparent."""
    src = src.convert("RGBA")
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    sp, op = src.load(), out.load()
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, al = sp[x, y]
            if al >= alpha_cut:
                op[x, y] = nearest((r, g, b))
    return out


def colour_counts(img: Image.Image) -> dict:
    """Opaque pixels per colour."""
    counts: dict = {}
    for p in img.convert("RGBA").getdata():
        if p[3] == 255:
            counts[p] = counts.get(p, 0) + 1
    return counts


def draw() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    horn(d, LIGHT, YELLOW)
    head(d, DARK)
    details(d)
    img = outline(img, 2)
    # Hard alpha: every pixel fully opaque or fully transparent.
    px = img.load()
    for y in range(H):
        for x in range(W):
            if 0 < px[x, y][3] < 255:
                px[x, y] = px[x, y][:3] + (255,)
    return img


PROMPT = (
    "brand logo emblem, bull head, front view, symmetric, thick curved horns, angry slanted eyes, "
    "nose ring, bold flat shapes, dark green head, light green horns, black outline, flat vector-like pixel art icon"
)


def pixflux_request(img: Image.Image, strength: int, description: str = PROMPT) -> dict:
    """The body for PixelLab's /create-image-pixflux with this image as init_image."""
    import base64
    import io
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return {
        "description": description,
        "image_size": {"width": W, "height": H},
        "no_background": True,
        "outline": "single color black outline",
        "shading": "flat shading",
        "detail": "low detail",
        "text_guidance_scale": 8,
        "init_image": {"type": "base64", "base64": base64.b64encode(buf.getvalue()).decode("ascii")},
        "init_image_strength": strength,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--preview")
    ap.add_argument("--request", help="also write a pixflux request body (JSON) using this image as init_image")
    ap.add_argument("--strength", type=int, default=200)
    ap.add_argument("--remap", help="instead of drawing, remap this PNG (e.g. PixelLab's output) to the palette")
    a = ap.parse_args()
    img = remap(Image.open(a.remap)) if a.remap else draw()
    img.save(a.out)
    for rgba, n in sorted(colour_counts(img).items(), key=lambda kv: -kv[1]):
        print(f"RGB {rgba[0]},{rgba[1]},{rgba[2]}: {n} px")
    if a.request:
        import json
        with open(a.request, "w", encoding="utf-8") as fh:
            json.dump(pixflux_request(img, a.strength), fh)
    if a.preview:
        big = img.resize((W * 4, H * 4), Image.NEAREST)
        small = img.resize((32, 32), Image.BOX).resize((128, 128), Image.NEAREST)
        sheet = Image.new("RGBA", (W * 4 * 2 + 128 * 2 + 40, W * 4), (0, 0, 0, 255))
        dark = Image.new("RGBA", (W * 4, H * 4), (24, 20, 40, 255))
        light = Image.new("RGBA", (W * 4, H * 4), (230, 230, 225, 255))
        dark.alpha_composite(big)
        light.alpha_composite(big)
        sheet.paste(dark, (0, 0))
        sheet.paste(light, (W * 4 + 10, 0))
        s_d = Image.new("RGBA", (128, 128), (24, 20, 40, 255)); s_d.alpha_composite(small)
        s_l = Image.new("RGBA", (128, 128), (230, 230, 225, 255)); s_l.alpha_composite(small)
        sheet.paste(s_d, (W * 8 + 20, 0))
        sheet.paste(s_l, (W * 8 + 20, 140))
        sheet.save(a.preview)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
