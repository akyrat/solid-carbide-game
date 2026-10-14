#!/usr/bin/env python3
"""Free assembly of a skyscraper from flat PixelLab pieces (T-064 round 2, approach A).

A flat facade band, a shopfront strip and a vertical sign (three PixelLab calls) become the
bottom of a very tall isometric tower; PixelLab never has to draw the 3D corner. Everything
here is exact pixel work at the game's density, 32 art px per unit (1 unit along x or y =
32 x 16 px, 1 unit up = 32 px), never resampled:

  shear        a flat wall becomes an iso wall: each column moves 1 px per 2 px across (2:1)
  mirror_tile  a flat piece is tiled to any size by mirroring, so the seams always match
  floor bands, a darker right wall (one palette step), an ordered-dither dissolve at the top
  (binary alpha, no roof), the palette (at most 30 colours), a pavement ring drawn by script.

The body is 768 x 960 px (24 units of wall at the two outer corners), anchored at its bottom
centre, which is the footprint's front corner. Run `sample_skyscraper.py` for the sample.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_buildings import REDGULL_RED, RED_MIN_DISTANCE, palette_from_image  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
PALETTE_PNG = REPO / "art-archive" / "T-064" / "palette.png"

UNIT_W, UNIT_H, UNIT_UP = 32, 16, 32
FOOT = 12                      # footprint, units
WALL_UNITS = 24                # wall height at the two outer corners (the one tunable constant)
WALL_W = FOOT * UNIT_W         # 384: one visible wall, flat width in art px
SLOPE_PX = FOOT * UNIT_H       # 192: how far a wall's base climbs along its length
FLAT_H = WALL_UNITS * UNIT_UP  # 768
BODY_W, BODY_H = 2 * WALL_W, FLAT_H + SLOPE_PX   # 768 x 960
FLOOR_UNITS = 2                # one floor = 2 units = 64 px
SHOP_UNITS = 3                 # the shopfront strip replaces the bottom 3 units
DISSOLVE_PX = 6 * UNIT_UP      # the top 6 units dissolve into the dark
SLOT, MARGIN = 15, 1.5         # slot units; pavement ring width


def iso(ux, uy, up=0.0):
    return ((ux - uy) * UNIT_W, (ux + uy) * UNIT_H - up * UNIT_UP)


# ------------------------------------------------------------ palette ----

def load_palette(path=PALETTE_PNG):
    return np.array(palette_from_image(path), dtype=np.int32)


def nearest_in(pal, c):
    return pal[int(np.argmin(((pal - np.array(c)) ** 2).sum(axis=1)))]


def snap(rgb, pal):
    """Maps an (h, w, 3) array to the nearest palette colours."""
    flat = rgb.reshape(-1, 3)
    cache = {}
    out = np.empty_like(flat)
    for i, c in enumerate(map(tuple, flat.tolist())):
        if c not in cache:
            cache[c] = nearest_in(pal, c)
        out[i] = cache[c]
    return out.reshape(rgb.shape).astype(np.uint8)


def darker_color(c, pal, factor=0.62):
    """One palette step darker: the palette colour nearest to factor x c that is not brighter than c."""
    ok = pal[pal.sum(axis=1) <= sum(c)]
    if not len(ok):
        ok = pal
    return ok[int(np.argmin(((ok - np.array(c) * factor) ** 2).sum(axis=1)))]


def darker(rgb, pal, factor=0.62):
    flat = rgb.reshape(-1, 3)
    cache = {}
    out = np.empty_like(flat)
    for i, c in enumerate(map(tuple, flat.tolist())):
        if c not in cache:
            cache[c] = darker_color(c, pal, factor)
        out[i] = cache[c]
    return out.reshape(rgb.shape).astype(np.uint8)


# ------------------------------------------------------ flat pieces ----

def replace_colors(arr, mapping):
    """Replaces exact colours of opaque pixels (a free fix, for example to lift faint window ghosts)."""
    out = arr.copy()
    for src, dst in mapping.items():
        m = (arr[..., :3] == np.array(src)).all(axis=-1) & (arr[..., 3] == 255)
        out[m, :3] = dst
    return out


def mirror_tile(arr, w, h, off=(0, 0)):
    """Tiles arr to w x h by mirroring in both directions, starting at offset off; edges always match."""
    ah, aw = arr.shape[:2]
    xs = (np.arange(w) + off[0]) % (2 * aw)
    xs = np.where(xs >= aw, 2 * aw - 1 - xs, xs)
    ys = (np.arange(h) + off[1]) % (2 * ah)
    ys = np.where(ys >= ah, 2 * ah - 1 - ys, ys)
    return arr[np.ix_(ys, xs)]


def seam_report(arr):
    """Mean colour difference across the wrap of the plain repeat; mirror tiling has none by construction."""
    a = arr[..., :3].astype(int)
    return {"plain_wrap_x": float(np.abs(a[:, 0] - a[:, -1]).sum(axis=-1).mean()),
            "plain_wrap_y": float(np.abs(a[0] - a[-1]).sum(axis=-1).mean()), "mirror": 0.0}


# --------------------------------------------------------------- shear ----

def shear_wall(flat, down):
    """Flat (h, w, 4) -> iso wall of h + w//2 + 1 rows. down=True: the base falls to the right (the
    left wall); down=False: it rises to the right (the right wall). 1 px per 2 px across, exactly."""
    h, w = flat.shape[:2]
    out = np.zeros((h + w // 2 + 1, w, 4), dtype=np.uint8)
    for x in range(w):
        dy = x // 2 if down else (w - 1 - x) // 2
        out[dy:dy + h, x] = flat[:, x]
    return out


# ---------------------------------------------------------------- body ----

def bayer(n=8):
    m = np.array([[0, 2], [3, 1]])
    while m.shape[0] < n:
        m = np.block([[4 * m, 4 * m + 2], [4 * m + 3, 4 * m + 1]])
    return (m + 0.5) / (n * n)


def dissolve_top(img, px=DISSOLVE_PX):
    """Ordered dither on the alpha: empty at the very top, solid px rows down (binary alpha, no roof)."""
    out = img.copy()
    h, w = out.shape[:2]
    thr = np.tile(bayer(8), (h // 8 + 1, w // 8 + 1))[:h, :w]
    keep = np.clip(np.arange(h)[:, None] / float(px), 0, 1) ** 1.3
    out[..., 3] = np.where((keep > thr) & (out[..., 3] == 255), 255, 0)
    return out


def base_y(x):
    """Canvas row of the wall's bottom edge at column x of the body (left wall falls, right wall rises)."""
    return FLAT_H + (x // 2 if x < WALL_W else (BODY_W - 1 - x) // 2)


def draw_floor_bands(body, pal):
    """A one-pixel line every floor along the wall's slope, one palette step darker than the wall."""
    for x in range(BODY_W):
        for f in range(1, FLAT_H // (FLOOR_UNITS * UNIT_UP) + 1):
            y = base_y(x) - f * FLOOR_UNITS * UNIT_UP
            if 0 <= y < BODY_H and body[y, x, 3] == 255:
                body[y, x, :3] = darker_color(tuple(body[y, x, :3].tolist()), pal, 0.7)


def draw_outline(body, pal):
    """Dark selective outline: the front corner line and the two outer edges."""
    dark = pal[int(np.argmin(pal.sum(axis=1)))]
    for x in (WALL_W - 1, WALL_W, 0, BODY_W - 1):
        m = body[:, x, 3] == 255
        body[m, x, :3] = dark


def place_sign(body, sign, pal, side, up_units):
    """The vertical sign sheared onto the wall like the facade, standing up_units above the base."""
    sh = shear_wall(sign, down=(side == "left"))
    x0 = 150 if side == "left" else WALL_W + 170
    for k in range(sh.shape[1]):
        x = x0 + k
        top = base_y(x) - int(up_units * UNIT_UP) - sign.shape[0]
        for yy in range(sh.shape[0]):
            if sh[yy, k, 3] == 255 and 0 <= top + yy < BODY_H:
                c = sh[yy, k, :3]
                if side == "right":
                    c = darker_color(tuple(c.tolist()), pal)
                body[top + yy, x, :3] = c
                body[top + yy, x, 3] = 255


def recolor_pink_cyan(arr):
    """Pink-led to cyan-led, a colour map between palette colours (never towards red)."""
    pairs = {(255, 64, 200): (0, 229, 255), (255, 200, 240): (190, 255, 255), (170, 36, 168): (0, 150, 214),
             (96, 20, 104): (20, 72, 140), (215, 180, 255): (190, 255, 255), (160, 90, 255): (0, 150, 214)}
    return replace_colors(arr, pairs)


def build_body(facade, shop, sign, pal, flip=False, sign_swap=False, sign_side="left", sign_up=5.0,
               facade_off=(0, 0), rubble=0, seed=0):
    """One skyscraper body, 768 x 960 RGBA. facade, shop and sign are (h, w, 4) uint8 arrays."""
    shop_h = SHOP_UNITS * UNIT_UP
    body = np.zeros((BODY_H, BODY_W, 4), dtype=np.uint8)
    for k in range(2):
        f = mirror_tile(facade, WALL_W, BODY_H, (facade_off[0] + 37 * k, facade_off[1] + 91 * k)).copy()
        f[BODY_H - shop_h:] = mirror_tile(shop, WALL_W, shop_h, (61 * k, 0))
        if k == 1:
            f[..., :3] = darker(f[..., :3], pal)
        for i in range(WALL_W):
            x = i + k * WALL_W
            b = base_y(x)
            body[:b, x] = f[BODY_H - b:, i]  # bottom-aligned on the sloped base, top at the canvas top
    sg = recolor_pink_cyan(sign) if sign_swap else sign
    place_sign(body, sg, pal, sign_side, sign_up)
    if rubble:  # a little rubble at the foot, from the palette's greys
        rng = np.random.default_rng(seed)
        greys = [pal[i] for i in range(len(pal)) if abs(int(pal[i][0]) - int(pal[i][2])) < 40 and 60 < pal[i].sum() < 400]
        for _ in range(rubble):
            x = int(rng.integers(8, BODY_W - 8))
            y = base_y(x) - int(rng.integers(0, 3))
            body[y:y + 2, x:x + int(rng.integers(1, 4)), :3] = greys[int(rng.integers(len(greys)))]
            body[y:y + 2, x:x + 3, 3] = 255
    draw_floor_bands(body, pal)
    draw_outline(body, pal)
    body = dissolve_top(body)
    if flip:
        body = body[:, ::-1].copy()
    return body


# ------------------------------------------------------------ pavement ----

def pavement_slot(kerb_sw, kerb_se, pal, seed=1):
    """A slot's ground: the 15 x 15 diamond (960 x 480 px, plus a 6 px kerb face), lighter and cooler than the
    asphalt, 1-unit slab lines, light cracks, a few rubble pixels, and a raised kerb face on the bottom edges
    that face a road (kerb_sw, kerb_se)."""
    rng = np.random.default_rng(seed)
    w, h = SLOT * UNIT_W * 2, SLOT * UNIT_H * 2 + 6
    img = np.zeros((h, w, 4), dtype=np.uint8)
    base, slab, hi = nearest_in(pal, (93, 92, 93)), nearest_in(pal, (85, 84, 96)), nearest_in(pal, (111, 96, 115))
    crack, kface = nearest_in(pal, (57, 55, 69)), nearest_in(pal, (41, 39, 54))
    cx = w // 2
    ys, xs = np.mgrid[0:h - 6, 0:w]
    u = (xs - cx) / 64.0 + ys / 32.0
    v = ys / 32.0 - (xs - cx) / 64.0
    inside = (u >= 0) & (u < SLOT) & (v >= 0) & (v < SLOT)
    img[:h - 6][inside] = np.array([*base, 255], dtype=np.uint8)
    line = inside & (((u % 1.0) < 0.04) | ((v % 1.0) < 0.04))
    img[:h - 6][line] = np.array([*slab, 255], dtype=np.uint8)
    pale = inside & ~line & (((u.astype(int) + v.astype(int)) % 2) == 0) & (rng.random(inside.shape) < 0.012)
    img[:h - 6][pale] = np.array([*hi, 255], dtype=np.uint8)
    for _ in range(50):  # light cracks: short diagonal runs
        x, y = int(rng.integers(40, w - 40)), int(rng.integers(30, h - 40))
        for _k in range(int(rng.integers(6, 18))):
            if img[y, x, 3] == 255:
                img[y, x, :3] = crack
            x += int(rng.integers(0, 3))
            y += int(rng.integers(0, 2))
            if not (0 <= x < w and 0 <= y < h - 6):
                break
    for _ in range(40):  # rubble
        x, y = int(rng.integers(40, w - 40)), int(rng.integers(30, h - 40))
        if img[y, x, 3] == 255:
            img[y, x, :3] = hi
    for x in range(w):
        solid = np.nonzero(img[:h - 6, x, 3])[0]
        if len(solid) and ((x < cx and kerb_sw) or (x >= cx and kerb_se)):
            yb = solid[-1]
            for d in range(1, 7):
                img[yb + d, x, :3] = hi if d == 1 else kface
                img[yb + d, x, 3] = 255
    return img


# -------------------------------------------------------------- checks ----

def red_ok(arr):
    for c in {tuple(p[:3]) for p in arr.reshape(-1, 4).tolist() if p[3] == 255}:
        if float(np.sqrt(sum(((a - b) / 255.0) ** 2 for a, b in zip(c, REDGULL_RED)))) <= RED_MIN_DISTANCE:
            return False
    return True


def sprite_rules(arr, max_colors=30):
    a = arr[..., 3]
    colors = {tuple(p[:3]) for p in arr.reshape(-1, 4).tolist() if p[3] == 255}
    return {"semi_transparent": int(((a > 0) & (a < 255)).sum()), "colors": len(colors),
            "colors_ok": len(colors) <= max_colors, "red_ok": red_ok(arr), "has_transparent": bool((a == 0).any())}


def to_img(arr):
    return Image.fromarray(np.asarray(arr, dtype=np.uint8), "RGBA")


def preview(img, scale, bg):
    big = img.resize((img.size[0] * scale, img.size[1] * scale), Image.NEAREST)
    out = Image.new("RGBA", big.size, bg + (255,))
    out.alpha_composite(big)
    return out


def side_by_side(img, scale, dark=(14, 12, 24), light=(225, 225, 230), gap=8):
    a, b = preview(img, scale, dark), preview(img, scale, light)
    out = Image.new("RGBA", (a.size[0] * 2 + gap, a.size[1]), (128, 128, 128, 255))
    out.paste(a, (0, 0))
    out.paste(b, (a.size[0] + gap, 0))
    return out
