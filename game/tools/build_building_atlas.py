#!/usr/bin/env python3
"""Free (no PixelLab call) step of task T-064: the 8 cleaned base towers become the
building atlas the map draws.

  python game/tools/build_building_atlas.py --raw-dir art-archive/T-064/raw \
      --palette art-archive/T-064/palette.png --clean-dir art-archive/T-064/clean \
      --atlas game/art/buildings/buildings_atlas.png --json game/art/buildings/buildings.json

For every base tower it makes the script versions: mirrored or not, pink-led or
cyan-led neon (a colour mapping only), and, for towers with a regular wall, taller
by repeating a band of whole floors (the band is chosen where the wall repeats
best and has the fewest neon pixels, so signs are repeated as little as possible).
All versions are packed into one atlas; the JSON gives each version's region,
its ground anchor (the tower's front-bottom corner), its on-screen hull and
height, as the map reads them (scripts/level/building_towers.gd).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_buildings as bb  # noqa: E402

EXTRA_HEIGHTS = (0, 3, 6)      # units added by repeating floors
MAX_HEIGHT_UNITS = 15.5        # no taller than the placeholder boxes the board has played with
# Towers whose walls are plain enough to stretch (set after looking at the cleaned towers:
# the stepped and spired roofs of 3 and 7 taper, so they keep their generated height).
STRETCHABLE = {1, 2, 4, 5, 6, 8}


def is_neon(c):
    return bb.hue_kind(c) is not None


def find_band(img, periods=range(14, 41)):
    """The best band of rows to repeat: returns (top, bottom, cost). The band is where the
    rows repeat themselves best (rows [y, y+P) against [y+P, y+2P)) and holds few neon pixels."""
    w, h = img.size
    px = img.load()
    lo, hi = int(h * 0.30), int(h * 0.78)
    rows = [[px[x, y] for x in range(w)] for y in range(h)]
    best = None
    for P in periods:
        for y in range(lo, hi - 2 * P, 2):
            tot, opaque, neon = 0, 0, 0
            for k in range(P):
                a, b = rows[y + k], rows[y + P + k]
                for x in range(w):
                    pa, pb = a[x], b[x]
                    if pa[3] or pb[3]:
                        opaque += 1
                        if pa != pb:
                            tot += 1
                    if pa[3] and is_neon(pa[:3]):
                        neon += 1
            if opaque < 40 * P:
                continue
            cost = tot / opaque + 2.0 * neon / opaque
            if best is None or cost < best[2]:
                best = (y, y + P, cost)
    return best


def hull(points):
    pts = sorted(set(points))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def opaque_hull(img):
    """Convex hull of the opaque pixels' corners (art pixels)."""
    px = img.load()
    w, h = img.size
    pts = []
    for y in range(h):
        xs = [x for x in range(w) if px[x, y][3]]
        if xs:
            pts += [(xs[0], y), (xs[0], y + 1), (xs[-1] + 1, y), (xs[-1] + 1, y + 1)]
    return hull(pts)


def versions_of(tower, n, swap, band=None):
    """All script versions of base tower n (1-based): a list of dicts with an 'image'."""
    out = []
    if band is None and n in STRETCHABLE:
        band = find_band(tower)
    for extra in EXTRA_HEIGHTS:
        img = tower
        if extra:
            if n not in STRETCHABLE or band is None:
                continue
            img = bb.stretch(img, band[0], band[1], int(round(extra * bb.UNIT_UP)))
        for sw in (False, True):
            im2 = bb.recolor(img, swap) if sw else img
            for mi in (False, True):
                im3 = bb.mirror(im2) if mi else im2
                ay, ax = bb.base_line(im3)
                top = im3.getbbox()[1]
                height = round((ay - top) / bb.UNIT_UP, 2)
                if height > MAX_HEIGHT_UNITS and extra:
                    continue
                out.append({
                    "id": "t%d_h%d_%s_%s" % (n, extra, "cyan" if sw else "pink", "m" if mi else "n"),
                    "tower": n, "extra_units": extra, "swap": sw, "mirror": mi,
                    "anchor": [round(ax), ay], "height_units": height,
                    "image": im3,
                })
    return out


def pack(items, width=2048, pad=2):
    """Shelf packing. Returns (atlas image, items with 'region')."""
    items = sorted(items, key=lambda it: -it["image"].size[1])
    x = y = shelf = 0
    placed = []
    for it in items:
        w, h = it["image"].size
        if x + w + pad > width:
            x, y, shelf = 0, y + shelf + pad, 0
        placed.append((it, x, y))
        x += w + pad
        shelf = max(shelf, h)
    atlas = Image.new("RGBA", (width, y + shelf + pad), (0, 0, 0, 0))
    for it, px_, py in placed:
        atlas.alpha_composite(it["image"], (px_, py))
        it["region"] = [px_, py, it["image"].size[0], it["image"].size[1]]
    return atlas, items


def build(raw_dir, palette_png, clean_dir, atlas_png, json_path):
    pal = bb.palette_from_image(palette_png)
    swap = bb.neon_swap_map(pal)
    Path(clean_dir).mkdir(parents=True, exist_ok=True)
    items, towers = [], []
    for n in range(1, 9):
        tower = bb.clean(Path(raw_dir) / ("tower_%02d.png" % n), pal)
        tower.save(Path(clean_dir) / ("tower_%02d_clean.png" % n))
        vs = versions_of(tower, n, swap)
        towers.append({"tower": n, "size": list(tower.size), "stretchable": n in STRETCHABLE,
                       "versions": len(vs)})
        items += vs
    atlas, items = pack(items)
    Path(atlas_png).parent.mkdir(parents=True, exist_ok=True)
    atlas.save(atlas_png)
    variants = []
    for it in sorted(items, key=lambda i: i["id"]):
        x, y, w, h = it["region"]
        crop = atlas.crop((x, y, x + w, y + h))
        variants.append({
            "id": it["id"], "tower": it["tower"], "region": it["region"], "anchor": it["anchor"],
            "height_units": it["height_units"], "hull": [list(p) for p in opaque_hull(crop)],
        })
    data = {
        "about": "T-064 building art (game/tools/build_building_atlas.py): 8 PixelLab base towers and their free "
                 "script versions (mirrored, pink or cyan neon, taller). region: the version's box in the atlas "
                 "(art pixels); anchor: the tower's front-bottom corner in the version; hull: convex hull of its "
                 "opaque pixels' corners, relative to region; height_units: anchor to roof, in units "
                 "(32 art pixels each).",
        "texture": "res://" + Path(atlas_png).as_posix().split("game/", 1)[-1],
        "art_px_per_unit": bb.UNIT_UP,
        "towers": towers,
        "variants": variants,
    }
    Path(json_path).write_text(json.dumps(data, indent=1) + "\n", encoding="utf-8")
    return data, atlas


def check_atlas(atlas, variants):
    """Visual style's rules for every version (colours counted per version, not for the whole atlas)."""
    bad = []
    for v in variants:
        x, y, w, h = v["region"]
        rep = bb.sprite_report(atlas.crop((x, y, x + w, y + h)))
        if not rep["pass"]:
            bad.append((v["id"], rep))
    semi = sum(1 for p in atlas.getdata() if 0 < p[3] < 255)
    return bad, semi


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--raw-dir", required=True)
    ap.add_argument("--palette", required=True)
    ap.add_argument("--clean-dir", required=True)
    ap.add_argument("--atlas", required=True)
    ap.add_argument("--json", required=True)
    a = ap.parse_args(argv)
    data, atlas = build(a.raw_dir, a.palette, a.clean_dir, a.atlas, a.json)
    bad, semi = check_atlas(atlas, data["variants"])
    print(json.dumps({"atlas": list(atlas.size), "variants": len(data["variants"]),
                      "failing": [b[0] for b in bad], "semi_transparent_pixels": semi}))
    return 0 if not bad and semi == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
