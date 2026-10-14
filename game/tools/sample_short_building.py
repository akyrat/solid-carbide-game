#!/usr/bin/env python3
"""Builds the sample short building (T-129, variant A) from the five raw PixelLab pieces, for free.

  python game/tools/sample_short_building.py --raw art-archive/T-129/raw --out-dir art-archive/T-129/sample

Writes the cleaned pieces, the body in the old palette and in palette B, previews on a dark and a light
background, mock-ups (next to the car at game scale, next to a T-064 skyscraper) and sample_record.json.
With --game-dir it also writes the body into the game's art folder (short_body_0.png).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_short_buildings as sb  # noqa: E402
import build_skyscrapers as bs  # noqa: E402
from build_buildings import car_frame  # noqa: E402
from sample_skyscraper import game_scale  # noqa: E402

KEEP_AC = [(16, 36), (36, 27), (52, 12), (68, 12), (82, 24), (82, 48), (72, 52), (60, 54), (46, 63), (44, 70), (35, 74), (16, 62)]
KEEP_RUBBLE = [(40, 26), (52, 19), (62, 20), (67, 29), (85, 37), (88, 43), (80, 52), (66, 58), (50, 59), (38, 52), (29, 42), (32, 33)]
LILAC = (215, 180, 255)
# Prop places on the 12 x 12 roof (units from the back corner).
PLACES = {"tank": (3.5, 4.0), "ac": (8.0, 3.5), "rubble": (5.5, 8.5),
          "ac2": (3.0, 8.5), "rubble2": (9.5, 8.0), "tank2": (9.0, 9.5)}
BG, ROAD = (14, 12, 24), (26, 25, 38)


def load(raw, name):
    return np.array(Image.open(Path(raw) / f"{name}.png").convert("RGBA"))


def block_canvas(slots, pavements, car=True):
    """slots: {(si, sj): (body RGBA array)}; every body anchored at its bottom centre on its footprint's front corner."""
    ox, oy = 1100, 1100
    canvas = Image.new("RGBA", (2200, 2300), BG + (255,))
    d = ImageDraw.Draw(canvas)
    d.polygon([(ox + p[0], oy + p[1]) for p in (bs.iso(-6, -6), bs.iso(36, -6), bs.iso(36, 36), bs.iso(-6, 36))], fill=ROAD + (255,))
    for (si, sj), pav in pavements.items():
        px, py = bs.iso(si * bs.SLOT, sj * bs.SLOT)
        canvas.alpha_composite(bs.to_img(pav), (int(ox + px - pav.shape[1] // 2), int(oy + py)))
    for (si, sj) in sorted(slots, key=lambda k: (k[0] + k[1], k[0])):
        fx, fy = bs.iso(si * bs.SLOT + bs.MARGIN + bs.FOOT, sj * bs.SLOT + bs.MARGIN + bs.FOOT)
        body = slots[(si, sj)]
        canvas.alpha_composite(bs.to_img(body), (int(ox + fx - body.shape[1] // 2), int(oy + fy - body.shape[0])))
    car_at = None
    if car:
        cx, cy = bs.iso(14.0, 37.5)
        car_at = (ox + cx, oy + cy)
        canvas.alpha_composite(car_frame(6), (int(car_at[0] - 64), int(car_at[1] - 64)))
    return canvas, car_at


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default="art-archive/T-129/raw")
    ap.add_argument("--out-dir", default="art-archive/T-129/sample")
    ap.add_argument("--game-dir", default=None)
    ap.add_argument("--b-art", default="game/art/buildings")
    a = ap.parse_args(argv)
    out = Path(a.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    pal = bs.load_palette()
    fl = sb.clean_facade(load(a.raw, "a_facade_left"), pal)
    fr = sb.clean_facade(load(a.raw, "a_facade_right"), pal)
    tank = sb.clean_prop(load(a.raw, "a_prop_tank"), pal)
    ac = sb.clean_prop(load(a.raw, "a_prop_ac"), pal, polygon=KEEP_AC)
    rub = sb.clean_prop(load(a.raw, "a_prop_rubble"), pal, polygon=KEEP_RUBBLE, drop=LILAC)
    for n, arr in (("facade_left", fl), ("facade_right", fr), ("prop_tank", tank), ("prop_ac", ac), ("prop_rubble", rub)):
        bs.to_img(arr).save(out / f"a_{n}_clean.png")
    flip = lambda x: x[:, ::-1].copy()  # noqa: E731
    props = [(tank, PLACES["tank"]), (ac, PLACES["ac"]), (rub, PLACES["rubble"]),
             (flip(ac), PLACES["ac2"]), (flip(rub), PLACES["rubble2"]), (flip(tank), PLACES["tank2"])]
    body_old = sb.build_body(fl, fr, pal, props, seed=7)
    body = sb.recolor_b(body_old)
    bs.to_img(body_old).save(out / "short_a_body_oldpalette.png")
    bs.to_img(body).save(out / "short_a_body_B.png")
    bs.side_by_side(bs.to_img(body), 1).save(out / "short_a_body_B_preview_1x.png")
    bs.side_by_side(bs.to_img(body), 2).save(out / "short_a_body_B_preview_2x.png")
    record = {"body": bs.sprite_rules(body), "size": list(body.shape[1::-1]), "height_px": int(fl.shape[0]),
              "height_units": round(fl.shape[0] / 32, 2), "pieces": {n: bs.sprite_rules(x) for n, x in
                                                                     (("facade_left", fl), ("facade_right", fr), ("tank", tank), ("ac", ac), ("rubble", rub))}}
    if a.game_dir:
        bs.to_img(body).save(Path(a.game_dir) / "short_body_0.png")
    b = Path(a.b_art)
    pavs = {(si, sj): np.array(Image.open(b / f"cityB_pavement_{si}{sj}.png").convert("RGBA")) for si, sj in ((0, 0), (1, 0), (0, 1), (1, 1))}
    sky = [np.array(Image.open(b / f"cityB_body_{i}.png").convert("RGBA")) for i in range(4)]
    # the board's sample block: short in the front slot, skyscrapers behind (the car on the road in front)
    canvas, car_at = block_canvas({(0, 0): sky[0], (1, 0): sky[1], (0, 1): sky[2], (1, 1): body}, pavs)
    canvas.save(out / "block_short_in_front_slot.png")
    for z in (11.6,):
        shot, _ = game_scale(canvas, (car_at[0] + 330, car_at[1] - 160), zoom=z)
        shot.save(out / f"block_short_with_car_game_scale_zoom{z}.png")
    # one short building next to one skyscraper (two slots of the same block row)
    c2, _ = block_canvas({(0, 1): sky[2], (1, 1): body}, {k: pavs[k] for k in ((0, 1), (1, 1))}, car=False)
    fx, fy = bs.iso(15 + bs.MARGIN + bs.FOOT, 15 + bs.MARGIN + bs.FOOT)
    c2.crop((1100 - 1100 + 200, 1100 + 400, 2000, 2100)).save(out / "short_next_to_skyscraper.png")
    # the car at game scale beside the short building alone
    c3, car3 = block_canvas({(1, 1): body}, {(1, 1): pavs[(1, 1)]})
    shot3, s = game_scale(c3, (car3[0] + 120, car3[1] - 120), zoom=11.6)
    shot3.save(out / "short_building_with_car_game_scale.png")
    record["screen_px_per_art_px"] = round(s, 4)
    (out / "sample_record.json").write_text(json.dumps(record, indent=1))
    print(json.dumps(record, indent=1))


if __name__ == "__main__":
    main()
