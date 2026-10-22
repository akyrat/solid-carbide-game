#!/usr/bin/env python3
"""Free assembly of the creator's small and long buildings (T-257) from PixelLab facades, in the style of T-129's short buildings.

  python game/tools/build_creator_buildings_art.py --raw art-archive/T-257/raw --out-dir game/art/buildings/creator_final

For each texture of data/level/creator_buildings.json (footprint w x h units, image size and anchor as T-254's
placeholders): a pavement fills the whole footprint (palette B, a lighter kerb band round the edge, cracks), and a
building stands inside it with a half-unit of pavement left on every side. Its two walls are flat PixelLab facades
sheared exactly 2:1 (the right one one palette step darker), a script-drawn tar roof with a parapet and rooftop
props from T-129 (reused, free) on it, the city palette B applied. Same input, same pixels.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_creator_buildings as bcb  # noqa: E402
import build_short_buildings as sb  # noqa: E402
import build_skyscrapers as bs  # noqa: E402
from sample_short_building import KEEP_AC, KEEP_RUBBLE, LILAC  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
PROPS_RAW = REPO / "art-archive" / "T-129" / "raw"
U = 32          # art px per unit across
MARGIN = 0.5    # pavement left round the building, units
ROWS = 134      # facade rows kept
PAV, PAV_LIGHT, PAV_DARK, PAV_EDGE = (103, 121, 141), (119, 138, 158), (98, 116, 136), (58, 71, 87)


def load_props(pal):
    ld = lambda n: np.array(Image.open(PROPS_RAW / f"{n}.png").convert("RGBA"))  # noqa: E731
    return {"tank": sb.clean_prop(ld("a_prop_tank"), pal),
            "ac": sb.clean_prop(ld("a_prop_ac"), pal, polygon=KEEP_AC),
            "rubble": sb.clean_prop(ld("a_prop_rubble"), pal, polygon=KEEP_RUBBLE, drop=LILAC)}


def ground_uv(shape, w, h, up, lift=0):
    """For every pixel, the ground point (units from the footprint's back corner) a point `lift` px above it stands over."""
    ys, xs = np.mgrid[0:shape[0], 0:shape[1]]
    s = (xs + 0.5 - U * h) / U
    t = (ys + 0.5 + lift - up) / (U / 2)
    return (s + t) / 2, (t - s) / 2


def draw_pavement(size, w, h, up, seed):
    rng = np.random.default_rng(seed)
    X, Y = ground_uv((size[1], size[0]), w, h, up)
    inside = (X >= 0) & (X < w) & (Y >= 0) & (Y < h)
    img = np.zeros((size[1], size[0], 4), dtype=np.uint8)
    img[inside] = [*PAV, 255]
    img[inside & (((X.astype(int) + Y.astype(int)) % 2) == 0)] = [*PAV_DARK, 255]   # slab joints read as a checker of two greys
    band = 0.3
    kerb = inside & ((X < band) | (Y < band) | (X >= w - band) | (Y >= h - band))
    img[kerb] = [*PAV_LIGHT, 255]
    for _ in range(int(w * h)):                                                       # light cracks
        x, y = int(rng.integers(30, size[0] - 30)), int(rng.integers(up // 2, size[1] - 10))
        for _k in range(int(rng.integers(4, 12))):
            if 0 <= x < size[0] and 0 <= y < size[1] and inside[y, x] and not kerb[y, x]:
                img[y, x, :3] = PAV_EDGE
            x += int(rng.integers(0, 3))
            y += int(rng.integers(0, 2))
    solid = img[..., 3] == 255
    ring = solid & ~(np.roll(solid, 1, 0) & np.roll(solid, -1, 0) & np.roll(solid, 1, 1) & np.roll(solid, -1, 1))
    img[ring] = [*PAV_EDGE, 255]
    return img


def draw_roof(body, pal, w, h, up, h_px, seed):
    rng = np.random.default_rng(seed)
    tar, seam, lipl, lipd, dark, patch = (bs.nearest_in(pal, c) for c in
                                          ((48, 46, 62), (41, 39, 54), (111, 96, 115), (32, 31, 45), (24, 23, 36), (57, 55, 69)))
    X, Y = ground_uv(body.shape, w, h, up, lift=h_px)
    u, v = X - MARGIN, Y - MARGIN
    wu, hv = w - 2 * MARGIN, h - 2 * MARGIN
    inside = (u >= 0) & (u < wu) & (v >= 0) & (v < hv)
    roof = np.zeros_like(body)
    roof[inside] = [*tar, 255]
    roof[inside & (((u.astype(int) // 3 + v.astype(int) // 3) % 2) == 0)] = [*patch, 255]
    roof[inside & (((u % 3) < 0.06) | ((v % 3) < 0.06))] = [*seam, 255]
    edge = inside & ((u < 0.5) | (u >= wu - 0.5) | (v < 0.5) | (v >= hv - 0.5))
    roof[edge] = [*lipd, 255]
    roof[inside & ((u < 0.17) | (v < 0.17))] = [*lipl, 255]
    ys, xs = np.nonzero(inside)
    for _ in range(int(wu * hv * 0.35)):
        k = int(rng.integers(len(ys)))
        x, y = int(xs[k]), int(ys[k])
        for _k in range(int(rng.integers(5, 16))):
            if 0 <= y < roof.shape[0] and 0 <= x < roof.shape[1] and roof[y, x, 3] == 255 and not edge[y, x]:
                roof[y, x, :3] = dark
            x += int(rng.integers(0, 3))
            y += int(rng.integers(0, 2))
    solid = roof[..., 3] == 255
    ring = solid & ~(np.roll(solid, 1, 0) & np.roll(solid, -1, 0) & np.roll(solid, 1, 1) & np.roll(solid, -1, 1))
    roof[ring] = [*dark, 255]
    body[solid] = roof[solid]


def roof_px(w, h, up, h_px, u, v):
    X, Y = MARGIN + u, MARGIN + v
    return (U * h + (X - Y) * U, up + (X + Y) * U / 2 - h_px)


def build_body(size, w, h, up, facade_l, facade_r, props, pal, seed):
    """The building (old palette) on a transparent canvas of `size`; facades are (ROWS, width, 4)."""
    h_px = facade_l.shape[0]
    body = np.zeros((size[1], size[0], 4), dtype=np.uint8)
    draw_roof(body, pal, w, h, up, h_px, seed)
    right = facade_r.copy()
    right[..., :3] = bs.darker(right[..., :3], pal)
    dark, lipl = bs.nearest_in(pal, (24, 23, 36)), bs.nearest_in(pal, (111, 96, 115))
    wl, wr = facade_l.shape[1], facade_r.shape[1]
    assert wl == round((w - 2 * MARGIN) * U) and wr == round((h - 2 * MARGIN) * U), (wl, wr, w, h)
    x_left = round(2 * MARGIN * U)                      # the left wall's first column (the footprint's left corner is x = 0 + margin)
    x_right = round(U * w)                              # the front corner: the right wall's first column
    base_left = up + U / 2 * h                          # base of the left wall at its first column
    base_right = up + U / 2 * (w + h - 2 * MARGIN)
    for i in range(wl):
        base = int(base_left + i // 2)
        x, top = x_left + i, base - h_px
        body[top:top + h_px, x] = facade_l[:, i]
        body[top, x, :3] = lipl
        body[top + 1, x, :3] = dark
        body[base, x] = [*dark, 255]
    for j in range(wr):
        base = int(base_right - j // 2)
        x, top = x_right + j, base - h_px
        body[top:top + h_px, x] = right[:, j]
        body[top, x, :3] = lipl
        body[top + 1, x, :3] = dark
        body[base, x] = [*dark, 255]
    for x in (x_left, x_right - 1, x_right, x_right + wr - 1):   # the corner line and the two outer edges
        if x < x_right:
            base = int(base_left + (x - x_left) // 2)
        else:
            base = int(base_right - (x - x_right) // 2)
        body[base - h_px:base + 1, x, :3] = dark
    for sprite, (u, v) in sorted(props, key=lambda p: p[1][0] + p[1][1]):
        sb.put(body, sprite, sb.prop_anchor(sprite), roof_px(w, h, up, h_px, u, v))
    return body


def clean(raw, name, pal, width):
    arr = sb.clean_facade(np.array(Image.open(Path(raw) / f"{name}.png").convert("RGBA")), pal, ROWS)
    assert arr.shape[1] == width, (name, arr.shape)
    return arr


def flip(a):
    return a[:, ::-1].copy()


def texture_plan(props):
    """texture file stem -> (left facade, right facade, props on the roof [(sprite, (u, v)) in roof units])."""
    t, ac, rb = props["tank"], props["ac"], props["rubble"]
    return {
        "small_0": ("small_0_facade_left", "small_0_facade_right", [(t, (2.6, 2.4)), (ac, (1.5, 3.5))]),
        "small_1": ("small_1_facade_left", "small_1_facade_right", [(flip(ac), (1.6, 3.2)), (rb, (3.4, 1.6))]),
        "long_ew_0": ("long_0_facade", "small_0_facade_right", [(t, (2.0, 2.0)), (ac, (6.0, 3.0)), (flip(rb), (9.0, 1.8))]),
        "long_ns_0": ("small_0_facade_left", "long_0_facade", [(t, (1.5, 2.0)), (flip(ac), (3.0, 6.0)), (rb, (2.0, 9.0))]),
        "long_ew_1": ("long_1_facade", "small_1_facade_right", [(flip(ac), (2.0, 3.0)), (rb, (5.5, 1.8)), (flip(t), (9.0, 2.5))]),
        "long_ns_1": ("small_1_facade_left", "long_1_facade", [(rb, (3.0, 2.0)), (ac, (1.8, 5.5)), (t, (3.0, 9.0))]),
    }


def build_all(raw, out_dir):
    pal = bs.load_palette()
    props = load_props(pal)
    data = bcb.load()
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    plan = texture_plan(props)
    report = {}
    for p, t in bcb.textures(data):
        stem = Path(t["texture"]).stem
        w, h = t["footprint_units"]
        size, anchor = bcb.expected_anchor(w, h, p["height_units"])
        up = round(p["height_units"] * U)
        lf, rf, pr = plan[stem]
        fl = clean(raw, lf, pal, round((w - 2 * MARGIN) * U))
        fr = clean(raw, rf, pal, round((h - 2 * MARGIN) * U))
        body = sb.recolor_b(build_body(size, w, h, up, fl, fr, pr, pal, seed=257 + len(report)))
        img = bs.to_img(draw_pavement(size, w, h, up, seed=2570 + len(report)))
        img.alpha_composite(bs.to_img(body))
        img.save(out / f"{stem}.png")
        report[stem] = {**bs.sprite_rules(np.array(img)), "size": list(img.size), "anchor": list(anchor)}
    (out / "build_record.json").write_text(json.dumps(report, indent=1))
    return report


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default="art-archive/T-257/raw")
    ap.add_argument("--out-dir", default="game/art/buildings/creator_final")
    a = ap.parse_args(argv)
    print(json.dumps(build_all(a.raw, a.out_dir), indent=1))


if __name__ == "__main__":
    main()
