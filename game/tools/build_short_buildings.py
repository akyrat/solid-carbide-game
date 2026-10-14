#!/usr/bin/env python3
"""Free assembly of a short building whose roof shows (T-129), from PixelLab facades and rooftop props.

Same grid as the skyscrapers (build_skyscrapers.py): 32 art px per unit, a 12 x 12 unit footprint in a
15 x 15 slot, the body anchored at its bottom centre (the footprint's front corner). Two flat facades
(384 px wide, 12 units) are sheared exactly 2:1 (no resampling), the right wall one palette step darker.
The roof is drawn by script directly in isometric space (768 x 384 px diamond): tar, a parapet lip, panel
seams, cracks. Rooftop props (PixelLab, base plates removed by a keep-polygon) stand on it. The city
palette (B, steel and glass) is applied afterwards by city_palettes.recolor.

See sample_short_building.py for the sample's assembly, previews and checks.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_skyscrapers as bs  # noqa: E402
import city_palettes as cp  # noqa: E402

WALL_W = bs.WALL_W            # 384
BODY_W = bs.BODY_W            # 768
ROOF_H = 2 * bs.SLOPE_PX      # 384: the roof diamond's height
FACADE_ROWS = 134             # rows of the raw facade kept (its last rows are a street strip)


def body_height(h_px):
    return h_px + ROOF_H


def wall_top(x):
    """Canvas row where the wall starts at column x (the roof's front edge)."""
    return ROOF_H // 2 + (x // 2 if x < WALL_W else (BODY_W - 1 - x) // 2)


def roof_xy(u, v):
    """Roof point (u along x, v along y, in units from the back corner) -> body px."""
    return (WALL_W + (u - v) * bs.UNIT_W, (u + v) * bs.UNIT_H)


def clean_facade(arr, pal, rows=FACADE_ROWS):
    out = arr[:rows].copy()
    out[..., 3] = 255
    out[..., :3] = bs.snap(out[..., :3], pal)
    return out


def clean_prop(arr, pal, polygon=None, drop=None):
    """Binary alpha, optionally keeps only pixels inside `polygon` (cuts a base plate away) and not of colour
    `drop`; snaps to the palette and trims to the bounding box."""
    a = arr.copy()
    keep = a[..., 3] >= 128
    if polygon is not None:
        mask = Image.new("L", (a.shape[1], a.shape[0]), 0)
        ImageDraw.Draw(mask).polygon(polygon, fill=255)
        keep &= np.array(mask) == 255
    if drop is not None:
        keep &= ~(a[..., :3] == np.array(drop)).all(axis=-1)
    a[..., 3] = np.where(keep, 255, 0)
    a[~keep, :3] = 0
    a[..., :3][keep] = bs.snap(a[..., :3][keep].reshape(-1, 1, 3), pal).reshape(-1, 3)
    ys, xs = np.nonzero(keep)
    return a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def shop_sign(w, h, seed, pal):
    """A horizontal shop sign drawn by script from abstract strokes only (bars, blocks, rings, stairs, dots): no
    glyph of any alphabet. Drawn in the sheared walls' source palette (neon pink = the accent, which palette B
    turns into amber); a dark panel, a 2 px frame, cells of marks. Same idea as build_skyscrapers.script_sign."""
    rng = np.random.default_rng(seed)
    img = np.zeros((h, w, 4), dtype=np.uint8)
    dark, frame = bs.nearest_in(pal, (24, 23, 36)), bs.nearest_in(pal, (255, 64, 200))
    ink = [bs.nearest_in(pal, c) for c in ((255, 200, 240), (255, 255, 255), (255, 64, 200))]
    img[..., :3] = dark
    img[..., 3] = 255
    img[:2, :, :3] = frame
    img[-2:, :, :3] = frame
    img[:, :2, :3] = frame
    img[:, -2:, :3] = frame
    cells = max(3, w // 15)
    cw = (w - 8) // cells
    for c in range(cells):
        x0 = 4 + c * cw
        col = ink[int(rng.integers(len(ink)))]
        kind = int(rng.integers(5))
        y0, y1 = 9, h - 9
        if kind == 0:    # two bars
            img[y0:y0 + 4, x0 + 2:x0 + cw - 2, :3] = col
            img[y1 - 4:y1, x0 + 2:x0 + cw - 2 - int(rng.integers(0, 4)), :3] = col
        elif kind == 1:  # block
            img[y0 + 3:y1 - 3, x0 + 2:x0 + cw - 2, :3] = col
        elif kind == 2:  # ring
            img[y0:y1, x0 + 2:x0 + cw - 2, :3] = col
            img[y0 + 3:y1 - 3, x0 + 5:x0 + cw - 5, :3] = dark
        elif kind == 3:  # stairs
            for i in range(3):
                img[y1 - 5 - i * 6:y1 - i * 6, x0 + 2 + i * 3:x0 + cw - 2, :3] = col
        else:            # dots
            for i in range(2):
                img[y0 + 2 + i * 9:y0 + 7 + i * 9, x0 + 3:x0 + cw - 3, :3] = col
    return img


def paint_sign(facade, box, seed, pal):
    """Paints a scripted sign over the PixelLab sign text; box = (x0, y0, x1, y1) in the facade's px."""
    x0, y0, x1, y1 = box
    facade[y0:y1, x0:x1] = shop_sign(x1 - x0, y1 - y0, seed, pal)
    return facade


def draw_roof(body, pal, seed=1, cracks=40):
    """Tar roof diamond with a parapet lip, panel seams and cracks, in palette colours."""
    rng = np.random.default_rng(seed)
    tar, seam, lipl, lipd, dark = (bs.nearest_in(pal, c) for c in ((48, 46, 62), (41, 39, 54), (111, 96, 115), (32, 31, 45), (24, 23, 36)))
    patch = bs.nearest_in(pal, (57, 55, 69))
    ys, xs = np.mgrid[0:ROOF_H, 0:BODY_W]
    u = (xs - WALL_W) / 64.0 + ys / 32.0
    v = ys / 32.0 - (xs - WALL_W) / 64.0
    inside = (u >= 0) & (u < 12) & (v >= 0) & (v < 12)
    roof = np.zeros((ROOF_H, BODY_W, 4), dtype=np.uint8)
    roof[inside] = [*tar, 255]
    roof[inside & (((u.astype(int) // 3 + v.astype(int) // 3) % 2) == 0)] = [*patch, 255]   # alternate 3-unit panels
    roof[inside & (((u % 3) < 0.06) | ((v % 3) < 0.06))] = [*seam, 255]
    edge = inside & ((u < 0.5) | (u >= 11.5) | (v < 0.5) | (v >= 11.5))                       # the parapet, 0.5 unit wide
    roof[edge] = [*lipd, 255]
    roof[inside & ((u < 0.17) | (v < 0.17))] = [*lipl, 255]                                   # the back edges catch the light
    for _ in range(cracks):
        x, y = int(rng.integers(40, BODY_W - 40)), int(rng.integers(40, ROOF_H - 40))
        for _k in range(int(rng.integers(5, 16))):
            if roof[y, x, 3] == 255 and not edge[y, x]:
                roof[y, x, :3] = dark
            x += int(rng.integers(0, 3))
            y += int(rng.integers(0, 2))
            if not (0 <= x < BODY_W and 0 <= y < ROOF_H):
                break
    solid = roof[..., 3] == 255
    ring = solid & ~(np.roll(solid, 1, 0) & np.roll(solid, -1, 0) & np.roll(solid, 1, 1) & np.roll(solid, -1, 1))
    roof[ring] = [*dark, 255]
    body[:ROOF_H][solid] = roof[solid]


def put(body, sprite, anchor, at):
    """Pastes a sprite (binary alpha) so its anchor lands on body px `at`."""
    h, w = sprite.shape[:2]
    x0, y0 = int(at[0] - anchor[0]), int(at[1] - anchor[1])
    ys, xs = np.nonzero(sprite[..., 3] == 255)
    for yy, xx in zip(ys.tolist(), xs.tolist()):
        if 0 <= y0 + yy < body.shape[0] and 0 <= x0 + xx < body.shape[1]:
            body[y0 + yy, x0 + xx] = sprite[yy, xx]


def prop_anchor(sprite):
    """Bottom centre of the prop's opaque pixels, a little up (the middle of its footprint)."""
    ys, xs = np.nonzero(sprite[..., 3] == 255)
    return (int((xs.min() + xs.max()) // 2), int(ys.max()) - 6)


def build_body(facade_l, facade_r, pal, props, flip=False, seed=1, cracks=40):
    """One short building body, 768 x (facade rows + 384). props = [(sprite, (u, v))] standing on the roof."""
    h_px = facade_l.shape[0]
    assert facade_r.shape[0] == h_px and facade_l.shape[1] == facade_r.shape[1] == WALL_W
    body = np.zeros((body_height(h_px), BODY_W, 4), dtype=np.uint8)
    draw_roof(body, pal, seed, cracks)
    right_flat = facade_r.copy()
    right_flat[..., :3] = bs.darker(right_flat[..., :3], pal)
    dark = bs.nearest_in(pal, (24, 23, 36))
    lipl = bs.nearest_in(pal, (111, 96, 115))
    # a 2:1 shear moves each column of the flat wall down by its own offset (columns are never resampled)
    for k, flat in enumerate((facade_l, right_flat)):
        for i in range(WALL_W):
            x = i + k * WALL_W
            top = wall_top(x)
            body[top:top + h_px, x] = flat[:, i]
            body[top, x, :3] = lipl                      # the roof's front edge, lit
            body[top + 1, x, :3] = dark
            body[top + h_px, x] = [*dark, 255]          # the wall's bottom line
    for x in (WALL_W - 1, WALL_W, 0, BODY_W - 1):        # the corner line and the two outer edges
        top = wall_top(x)
        body[top:top + h_px, x, :3] = dark
    for sprite, (u, v) in sorted(props, key=lambda p: p[1][0] + p[1][1]):
        put(body, sprite, prop_anchor(sprite), roof_xy(u, v))
    if flip:
        body = body[:, ::-1].copy()
    return body


def recolor_b(arr):
    return cp.recolor(arr, "B")
