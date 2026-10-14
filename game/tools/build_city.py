#!/usr/bin/env python3
"""The full set of skyscrapers in palette B, assembled for free (T-064, approach A).

Six towers: tower 1 from the sample pieces (recoloured to palette B), towers 2 to 6 from the full-set
PixelLab pieces (facade band + shopfront strip each); the six signs are drawn by script (no real glyphs).
Per tower two variants (flip, sign wall and height, facade bands, rubble) = 12 bodies, plus the 4 slot
pavements (the palette-B pavements already made by city_palettes.py). Writes into game/art/buildings and
a previews folder; nothing is deleted.

  python game/tools/build_city.py --raw art-archive/T-064/round2/raw --out-dir game/art/buildings
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_skyscrapers as bs  # noqa: E402
import city_palettes as cp  # noqa: E402
from build_buildings import car_frame, palette_from_image  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
PALETTE_B = REPO / "art-archive" / "T-064" / "round2" / "paletteB.png"
OLD_PALETTE = REPO / "art-archive" / "T-064" / "palette.png"

# Shopfront crops (x0, y0, x1, y1) in the raw 256 x 128 piece; 96 rows = 3 units. Texts PixelLab drew on
# the lobby signs are painted over (boxes in raw coordinates).
SHOP_CROPS = {
    2: (16, 16, 216, 112), 3: (12, 32, 244, 128), 4: (34, 32, 222, 128), 5: (30, 32, 236, 128), 6: (22, 32, 234, 128),
}
SHOP_ERASE = {3: [(112, 63, 142, 72)], 5: [(115, 75, 140, 83), (213, 75, 229, 83)]}
SIGN_ACCENT = {1: (255, 178, 60), 2: (170, 210, 240), 3: (255, 178, 60), 4: (240, 248, 255), 5: (170, 210, 240), 6: (255, 178, 60)}
VARIANTS = [
    dict(flip=False, sign_side="left", sign_up=5.0, rubble=0),
    dict(flip=True, sign_side="right", sign_up=9.0, rubble=6),
]
BG, ROAD = (14, 12, 24), (26, 25, 38)


def erase(arr, boxes):
    """Paints a box over with the colour just above it (hides a text the generator drew)."""
    for x0, y0, x1, y1 in boxes:
        for x in range(x0, x1):
            arr[y0:y1, x] = arr[y0 - 2, x]
    return arr


def load(raw, name, crop=None, alpha_cut=None):
    im = Image.open(Path(raw) / name).convert("RGBA")
    if crop:
        im = im.crop(crop)
    a = np.array(im)
    if alpha_cut is not None:
        a[..., 3] = np.where(a[..., 3] >= alpha_cut, 255, 0)
    return a


def clean(a, pal):
    o = a.copy()
    m = o[..., 3] == 255
    o[..., :3][m] = bs.snap(o[..., :3][m].reshape(-1, 1, 3), pal).reshape(-1, 3)
    return o


def pieces(raw, palb):
    out = {}
    old = bs.load_palette(OLD_PALETTE)
    # tower 1: the sample pieces (old palette) recoloured to B with the same ramp as city_palettes
    f1 = clean(load(raw, "sky01_facade.png", (84, 20, 172, 250)), old)
    f1 = bs.replace_colors(f1, {(24, 23, 36): (32, 31, 45), (32, 31, 45): (68, 59, 81), (41, 39, 54): (85, 84, 96)})
    s1 = clean(load(raw, "sky01_shopfront.png", (42, 16, 178, 112)), old)
    f1 = cp.recolor(f1, "B")
    s1 = cp.recolor(s1, "B")
    f1[..., :3] = bs.lift_dark(bs.snap(f1[..., :3], palb), palb)
    s1[..., :3] = bs.snap(s1[..., :3], palb)
    out[1] = {"facade": f1, "shop": s1}
    for n in range(2, 7):
        f = clean(load(raw, f"sky0{n}_facade.png"), palb)
        f[..., :3] = bs.lift_dark(f[..., :3], palb)
        c = SHOP_CROPS[n]
        sh = load(raw, f"sky0{n}_shopfront.png")[c[1]:c[3], c[0]:c[2]].copy()
        sh = erase(sh, [(x0 - c[0], y0 - c[1], x1 - c[0], y1 - c[1]) for x0, y0, x1, y1 in SHOP_ERASE.get(n, [])])
        out[n] = {"facade": f, "shop": clean(sh, palb)}
    return out


def block_canvas(bodies_by_slot, pavements):
    ox, oy, W, H = 1100, 1000, 2200, 2100
    canvas = Image.new("RGBA", (W, H), BG + (255,))
    d = ImageDraw.Draw(canvas)
    d.polygon([(ox + p[0], oy + p[1]) for p in (bs.iso(-6, -6), bs.iso(36, -6), bs.iso(36, 36), bs.iso(-6, 36))], fill=ROAD + (255,))
    for (si, sj), pav in pavements.items():
        px, py = bs.iso(si * bs.SLOT, sj * bs.SLOT)
        canvas.alpha_composite(Image.fromarray(pav, "RGBA"), (int(ox + px - pav.shape[1] // 2), int(oy + py)))
    for (si, sj) in sorted(bodies_by_slot, key=lambda k: (k[0] + k[1], k[0])):
        fx, fy = bs.iso(si * bs.SLOT + bs.MARGIN + bs.FOOT, sj * bs.SLOT + bs.MARGIN + bs.FOOT)
        canvas.alpha_composite(Image.fromarray(bodies_by_slot[(si, sj)], "RGBA"), (int(ox + fx - bs.BODY_W // 2), int(oy + fy - bs.BODY_H)))
    return canvas, (ox, oy)


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default="art-archive/T-064/round2/raw")
    ap.add_argument("--out-dir", default="game/art/buildings")
    ap.add_argument("--preview-dir", default="art-archive/T-064/round2/full")
    a = ap.parse_args(argv)
    out, prev = Path(a.out_dir), Path(a.preview_dir)
    prev.mkdir(parents=True, exist_ok=True)
    palb = np.array(palette_from_image(PALETTE_B), dtype=np.int32)
    pcs = pieces(a.raw, palb)
    bodies, report, arrs = [], {}, {}
    for n in range(1, 7):
        sign = bs.script_sign(n * 17, palb, accent=SIGN_ACCENT[n])
        bs.to_img(sign).save(prev / f"tower{n}_sign.png")
        for k, v in enumerate(VARIANTS):
            body = bs.build_body(pcs[n]["facade"], pcs[n]["shop"], sign, palb, facade_seed=n * 10 + k, seed=n * 3 + k, **v)
            fn = f"skyscraper_{n}_{k}.png"
            bs.to_img(body).save(out / fn)
            bodies.append(f"res://art/buildings/{fn}")
            arrs[(n, k)] = body
            report[fn] = bs.sprite_rules(body)
        bs.to_img(pcs[n]["facade"]).save(prev / f"tower{n}_facade_clean.png")
        bs.to_img(pcs[n]["shop"]).save(prev / f"tower{n}_shop_clean.png")
    pavs = {}
    for si, sj in ((0, 0), (1, 0), (0, 1), (1, 1)):
        pavs[(si, sj)] = np.array(Image.open(out / f"cityB_pavement_{si}{sj}.png").convert("RGBA"))
        report[f"cityB_pavement_{si}{sj}.png"] = bs.sprite_rules(pavs[(si, sj)])
    sheet = Image.new("RGBA", (6 * 392, 2 * 490), (14, 12, 24, 255))
    for (n, k), body in arrs.items():
        im = Image.fromarray(body, "RGBA").resize((384, 480), Image.NEAREST)
        sheet.alpha_composite(im, ((n - 1) * 392, k * 490))
    sheet.save(prev / "all_bodies_half_size.png")
    for n in range(1, 7):
        bs.side_by_side(bs.to_img(arrs[(n, 0)]).crop((0, 560, 768, 960)), 2).save(prev / f"tower{n}_base_2x.png")
    slots = {(0, 0): arrs[(1, 0)], (1, 0): arrs[(2, 1)], (0, 1): arrs[(3, 0)], (1, 1): arrs[(4, 1)]}
    canvas, (ox, oy) = block_canvas(slots, pavs)
    canvas.save(prev / "block_four_towers.png")
    cx, cy = bs.iso(14.0, 37.5)
    c2 = canvas.copy()
    c2.alpha_composite(car_frame(6), (int(ox + cx - 64), int(oy + cy - 64)))
    c2.save(prev / "block_with_car.png")
    json_path = out / "skyscrapers.json"
    d = json.loads(json_path.read_text())
    d["about"] = ("T-064 full set, palette B (steel and glass): 6 skyscrapers x 2 variants = 12 bodies (768 x 960 art px, "
                  "anchored at the bottom centre = the footprint front corner; body index = (tower - 1) * 2 + variant) and 4 "
                  "script-drawn slot pavements (index = si + 2 * sj). Made by game/tools/build_city.py from PixelLab pieces; "
                  "signs drawn by script.")
    d.pop("palettes", None)
    d["bodies"] = bodies
    d["texture"] = bodies[0]
    d["pavements"] = [f"res://art/buildings/cityB_pavement_{si}{sj}.png" for si, sj in ((0, 0), (1, 0), (0, 1), (1, 1))]
    d["towers"] = 6
    d["variants_per_tower"] = 2
    json_path.write_text(json.dumps(d, indent=1))
    (prev / "build_record.json").write_text(json.dumps(report, indent=1))
    bad = {k: v for k, v in report.items() if v["semi_transparent"] or not v["colors_ok"] or not v["red_ok"]}
    print("failing sprites:", bad or "none", "| max colours", max(v["colors"] for v in report.values()))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
