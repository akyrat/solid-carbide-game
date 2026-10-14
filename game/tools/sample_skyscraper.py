#!/usr/bin/env python3
"""Builds the sample skyscraper (T-064 round 2) from the three raw PixelLab pieces, for free.

  python game/tools/sample_skyscraper.py --raw art-archive/T-064/round2/raw --out-dir art-archive/T-064/round2

Writes cleaned pieces, the body, the pavement, a whole-block mock-up (one skyscraper, free variations),
that block next to the car at game scale, enlarged previews, and sample_record.json with the checks.
Nothing goes into the game.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_skyscrapers as bs  # noqa: E402
from build_buildings import car_frame  # noqa: E402

# Crops of the raw pieces (art px): the facade's tower, the shopfront's middle building (96 px = 3 units).
FACADE_CROP = (84, 20, 172, 250)
SHOP_CROP = (42, 16, 178, 112)
# Faint window ghosts in the facade are nearly the wall's own colour; lift them to readable greys (free fix).
LIFT = {(32, 31, 45): (68, 59, 81), (41, 39, 54): (85, 84, 96)}
WALL_BASE = {(24, 23, 36): (32, 31, 45)}

# One skyscraper, four free variations for the four slots (flip, neon colour, sign wall and height, facade start, rubble).
SLOT_VARIANTS = {
    (0, 0): dict(flip=False, sign_swap=False, sign_side="left", sign_up=5.0, facade_off=(0, 0), rubble=0),
    (1, 0): dict(flip=True, sign_swap=True, sign_side="right", sign_up=9.0, facade_off=(60, 40), rubble=6),
    (0, 1): dict(flip=False, sign_swap=True, sign_side="right", sign_up=3.0, facade_off=(120, 100), rubble=10),
    (1, 1): dict(flip=True, sign_swap=False, sign_side="left", sign_up=11.0, facade_off=(30, 150), rubble=4),
}

BG = (14, 12, 24)
ROAD = (26, 25, 38)


def load(raw, name, crop=None, alpha_cut=None):
    im = Image.open(Path(raw) / name).convert("RGBA")
    if crop:
        im = im.crop(crop)
    a = np.array(im)
    if alpha_cut is not None:
        a[..., 3] = np.where(a[..., 3] >= alpha_cut, 255, 0)
    return a


def clean_piece(arr, pal, extra=None):
    out = arr.copy()
    if extra:
        out = bs.replace_colors(out, extra)
    m = out[..., 3] == 255
    out[..., :3][m] = bs.snap(out[..., :3][m].reshape(-1, 1, 3), pal).reshape(-1, 3)
    return out


def block_mockup(bodies, pavements, car=True):
    """Canvas with the block's north corner at (ox, oy); bodies by painter order; road ring around the block."""
    ox, oy = 1100, 1000
    W, H = 2200, 2100
    canvas = Image.new("RGBA", (W, H), BG + (255,))
    from PIL import ImageDraw
    d = ImageDraw.Draw(canvas)
    d.polygon([(ox + p[0], oy + p[1]) for p in (bs.iso(-6, -6), bs.iso(36, -6), bs.iso(36, 36), bs.iso(-6, 36))], fill=ROAD + (255,))
    for (si, sj), pav in pavements.items():
        px, py = bs.iso(si * bs.SLOT, sj * bs.SLOT)
        canvas.alpha_composite(bs.to_img(pav), (int(ox + px - pav.shape[1] // 2), int(oy + py)))
    order = sorted(bodies, key=lambda k: (k[0] + k[1], k[0]))
    for (si, sj) in order:
        fx, fy = bs.iso(si * bs.SLOT + bs.MARGIN + bs.FOOT, sj * bs.SLOT + bs.MARGIN + bs.FOOT)
        body = bs.to_img(bodies[(si, sj)])
        canvas.alpha_composite(body, (int(ox + fx - bs.BODY_W // 2), int(oy + fy - bs.BODY_H)))
    car_at = None
    if car:
        cx, cy = bs.iso(14.0, 37.5)
        car_at = (ox + cx, oy + cy)
        canvas.alpha_composite(car_frame(6), (int(car_at[0] - 64), int(car_at[1] - 64)))
    return canvas, car_at


def game_scale(canvas, centre, zoom=11.6, win=(1152, 648)):
    """What the board's window shows at the camera size `zoom` (saved 11.6): screen px per art px is
    window height / (2 x zoom x 32). The view is cut around `centre` and resized with nearest neighbour."""
    s = win[1] / (2 * zoom * 32)
    vw, vh = win[0] / s, win[1] / s
    box = (int(centre[0] - vw / 2), int(centre[1] - vh / 2), int(centre[0] + vw / 2), int(centre[1] + vh / 2))
    return canvas.crop(box).resize(win, Image.NEAREST), s


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default="art-archive/T-064/round2/raw")
    ap.add_argument("--out-dir", default="art-archive/T-064/round2")
    a = ap.parse_args(argv)
    out = Path(a.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    pal = bs.load_palette()
    facade = clean_piece(load(a.raw, "sky01_facade.png", FACADE_CROP), pal, {**LIFT, **WALL_BASE})
    shop = clean_piece(load(a.raw, "sky01_shopfront.png", SHOP_CROP), pal)
    sign = clean_piece(load(a.raw, "sky01_sign.png", None, alpha_cut=128), pal)
    for name, arr in (("facade", facade), ("shopfront", shop), ("sign", sign)):
        bs.to_img(arr).save(out / f"sky01_{name}_clean.png")
        bs.side_by_side(bs.to_img(arr), 4 if name != "facade" else 3).save(out / f"sky01_{name}_preview.png")
    record = {"pieces": {n: bs.sprite_rules(x) for n, x in (("facade", facade), ("shopfront", shop), ("sign", sign))},
              "facade_seams": bs.seam_report(facade), "shop_seams": bs.seam_report(shop)}

    bodies = {k: bs.build_body(facade, shop, sign, pal, seed=i, **v) for i, (k, v) in enumerate(SLOT_VARIANTS.items())}
    body = bodies[(0, 0)]
    bs.to_img(body).save(out / "sky01_body.png")
    bs.side_by_side(bs.to_img(body), 1).save(out / "sky01_body_preview.png")
    zoomcrop = bs.to_img(body).crop((0, 600, 768, 960))
    bs.side_by_side(zoomcrop, 2).save(out / "sky01_body_base_closeup_2x.png")
    record["body"] = bs.sprite_rules(body)

    pavements = {}
    for (si, sj) in SLOT_VARIANTS:
        pavements[(si, sj)] = bs.pavement_slot(sj == 1, si == 1, pal, seed=10 + si * 2 + sj)
    bs.to_img(pavements[(1, 1)]).save(out / "pavement_slot_south_sample.png")
    bs.side_by_side(bs.to_img(pavements[(1, 1)]), 1).save(out / "pavement_slot_south_preview.png")
    record["pavement"] = bs.sprite_rules(pavements[(1, 1)])

    canvas, car_at = block_mockup(bodies, pavements, car=False)
    canvas.save(out / "block_mockup_one_skyscraper.png")
    canvas2, car_at = block_mockup(bodies, pavements, car=True)
    canvas2.save(out / "block_mockup_with_car.png")
    shot, s = game_scale(canvas2, (car_at[0] + 250, car_at[1] - 330), zoom=11.6)
    shot.save(out / "block_with_car_game_scale_zoom11.6.png")
    shot2, _ = game_scale(canvas2, (car_at[0] + 250, car_at[1] - 330), zoom=14.4)
    shot2.save(out / "block_with_car_game_scale_zoom14.4.png")
    record["game_scale_screen_px_per_art_px_at_11.6"] = round(s, 4)
    record["bodies_distinct"] = len({bodies[k].tobytes() for k in bodies})
    (out / "sample_record.json").write_text(json.dumps(record, indent=1))
    print(json.dumps(record, indent=1))


if __name__ == "__main__":
    main()
