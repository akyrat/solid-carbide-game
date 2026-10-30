#!/usr/bin/env python3
"""T-397's art sample: one sidewalk tile with its curb, one parked car facing, and the composed preview.

  python game/tools/build_sidewalk_car_sample.py sidewalk --out <png> [--curb-px 3] [--seed 397]
      Draws (free, no PixelLab) one 128 x 64 isometric ground tile (2 x 2 units, the road tiles' size) of
      sidewalk in the buildings' pavement colours (build_creator_buildings_art.py PAV*), with a raised curb
      along its south-east edge (world +x, the screen's lower-right edge), the side that meets the road.
      The whole surface is drawn as if lifted `curb_px` art px (under 0.1 unit), so the curb's front face
      shows between the surface and the tile's edge; slabs and speckle repeat every 2 units, so the tile
      joins its neighbours without a seam.
  python game/tools/build_sidewalk_car_sample.py car --raw <pixellab png> --out <png> [--mirror] [--max-colors 30]
      Cleans a PixelLab car picture (free): alpha 0 or 255, the flat border background removed, loose specks
      and detached blobs dropped, at most 30 colours, optionally mirrored (top left <-> top right).
  python game/tools/build_sidewalk_car_sample.py preview --sidewalk <png> --car <png> --out-dir <folder>
      The composed preview: a road along world y (the game's road tiles), the sidewalk beside it with its curb
      against the road, a creator small building on the sidewalk, a boulder on the road and the car parked at
      the curb; on a dark and a light background, enlarged 3x with nearest neighbour. Writes
      preview_dark.png, preview_light.png and preview_side_by_side.png.

Needs Pillow and numpy. Same input, same pixels.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
U = 32                      # art px per unit across
TILE_W, TILE_H = 128, 64    # one ground tile = 2 x 2 units

# The buildings' pavement (build_creator_buildings_art.py), so the sidewalk matches the pavement round them.
PAV, PAV_LIGHT, PAV_DARK, PAV_EDGE = (103, 121, 141), (119, 138, 158), (98, 116, 136), (58, 71, 87)
CURB_TOP = (146, 164, 183)       # the curb stone's top, clearly lighter than the slabs
CURB_LIP = (172, 187, 203)       # its lit front edge
CURB_HIGHLIGHT = (200, 211, 223) # highlight pixels breaking up the lit edge
CURB_FACE = (104, 118, 136)      # the face towards the road, darker than the top
CURB_FACE_LOW = (86, 99, 117)    # its lower, shaded row
GUTTER = (14, 14, 20)            # the near-black line where the curb meets the asphalt
GUTTER_STRIP = (40, 38, 52)      # the strip of road-dark ground between the gutter line and the tile's edge
JOINT = (88, 105, 124)           # slab joints
CURB_JOINT = (122, 138, 156)     # joints between the curb stones
CURB_WIDTH = 0.25                # units
CURB_INSET = 0.18               # units the curb's front edge sits in from the tile's edge


def ground_uv(px, py, lift=0.0):
    """Ground point (u along world x, v along world y, units, from the tile's top corner) under a pixel
    centre, for a surface lifted `lift` art px."""
    s = (px + 0.5 - TILE_W / 2) / U
    t = (py + 0.5 + lift) / (U / 2)
    return (s + t) / 2, (t - s) / 2


def draw_sidewalk(curb_px=3, seed=397, curb=True):
    """The sidewalk tile with its curb on the south-east edge, as an RGBA uint8 array (64 x 128).
    curb=False draws the same tile with no curb (an inner sidewalk tile, used in the preview)."""
    rng = np.random.default_rng(seed)
    ys, xs = np.mgrid[0:TILE_H, 0:TILE_W]
    u0, v0 = ground_uv(xs, ys)                 # the tile's footprint on the ground
    u, v = ground_uv(xs, ys, lift=curb_px)     # the raised surface seen at each pixel
    inside = (u0 >= 0) & (u0 < 2) & (v0 >= 0) & (v0 < 2)
    img = np.zeros((TILE_H, TILE_W, 4), dtype=np.uint8)

    # the surface: 1 x 1 unit slabs as a checker of two greys (as the buildings' pavement), repeating every 2 units
    uw, vw = np.mod(u, 2), np.mod(v, 2)
    slab = (np.floor(uw).astype(int) + np.floor(vw).astype(int)) % 2
    img[inside] = [*PAV, 255]
    img[inside & (slab == 0)] = [*PAV_DARK, 255]
    # slab joints: a thin darker line along each slab edge (the u and v integer lines)
    fu, fv = uw - np.floor(uw), vw - np.floor(vw)
    joint = inside & ((fu < 0.035) | (fv < 0.035))
    img[joint] = [*JOINT, 255]
    # speckle, placed on the ground grid so it repeats with the tile
    gu, gv = np.floor(uw * 16).astype(int), np.floor(vw * 16).astype(int)
    hashv = (gu * 73856093 ^ gv * 19349663 ^ seed) & 0xFFFF
    img[inside & ~joint & (hashv % 23 == 0)] = [*PAV_LIGHT, 255]

    # light cracks: short wandering pixel runs, kept away from the tile's edges
    for _ in range(3):
        x, y = int(rng.integers(30, 80)), int(rng.integers(14, 40))
        for _k in range(int(rng.integers(10, 16))):
            if inside[y, x] and 0.2 < u[y, x] < 2 - CURB_INSET - CURB_WIDTH - 0.15 and 0.15 < v[y, x] < 1.85:
                img[y, x] = [*PAV_EDGE, 255]
            x += int(rng.integers(0, 2)) + 1
            y += int(rng.integers(-1, 2))
            y = min(max(y, 0), TILE_H - 1)

    if not curb:
        return img
    # the curb: its front edge sits CURB_INSET in from the tile's edge, so the road tile drawn next to it (whose
    # edge pixels overlap this tile's) never covers the face or the gutter; the strip in front of the face is gutter
    edge = 2 - CURB_INSET
    top = inside & (u >= edge - CURB_WIDTH) & (u < edge)
    img[top] = [*CURB_TOP, 255]
    face = inside & (u >= edge) & (u0 < edge)
    img[face] = [*CURB_FACE, 255]
    strip = inside & (u0 >= edge)
    img[strip] = [*GUTTER_STRIP, 255]
    # the face's lowest row is shaded
    for x in range(TILE_W):
        col = np.nonzero(face[:, x])[0]
        if len(col) >= 2:
            img[col.max(), x] = [*CURB_FACE_LOW, 255]
    # the gutter line: the first pixel below the face in each column, where the curb meets the road
    for x in range(TILE_W):
        col = np.nonzero(strip[:, x])[0]
        if len(col):
            img[col.min(), x] = [*GUTTER, 255]
    # the joints run on across the curb top, a little darker, so the curb reads as stones
    img[top & (fv < 0.035)] = [*CURB_JOINT, 255]
    img[top & (u < edge - CURB_WIDTH + 0.045)] = [*PAV_EDGE, 255]   # the seam between the slabs and the curb stone
    # the lit edge right above the face, broken by brighter highlight pixels
    below = np.zeros_like(face)
    below[:-1] = face[1:]
    lip = top & below
    img[lip] = [*CURB_LIP, 255]
    img[lip & (xs % 5 == 1)] = [*CURB_HIGHLIGHT, 255]
    return img


def load_rgba(path):
    return np.array(Image.open(path).convert("RGBA"))


def binarize_alpha(a):
    out = a.copy()
    solid = out[..., 3] >= 128
    out[..., 3] = np.where(solid, 255, 0)
    out[~solid] = 0
    return out


def remove_flat_background(a, tol=6):
    """Flood fill from the border through pixels within `tol` of the border's most common colour."""
    h, w = a.shape[:2]
    if (a[..., 3] == 0).mean() > 0.2:
        return a
    border = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    vals, counts = np.unique(border[:, :3], axis=0, return_counts=True)
    bg = vals[counts.argmax()].astype(int)
    near = np.abs(a[..., :3].astype(int) - bg).max(axis=2) <= tol
    seen = np.zeros((h, w), bool)
    stack = [(y, x) for x in range(w) for y in (0, h - 1)] + [(y, x) for y in range(h) for x in (0, w - 1)]
    while stack:
        y, x = stack.pop()
        if 0 <= y < h and 0 <= x < w and not seen[y, x] and near[y, x]:
            seen[y, x] = True
            stack += [(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)]
    out = a.copy()
    out[seen] = 0
    return out


def drop_specks(a):
    """Peels pixels with 2 or fewer opaque 4-neighbours... repeatedly, then keeps only the largest blob."""
    out = a.copy()
    for _ in range(2):
        s = out[..., 3] == 255
        p = np.pad(s, 1)
        n = p[:-2, 1:-1].astype(int) + p[2:, 1:-1] + p[1:-1, :-2] + p[1:-1, 2:]
        loose = s & (n <= 1)
        out[loose] = 0
    s = out[..., 3] == 255
    lab = np.zeros(s.shape, int)
    cur = 0
    sizes = {}
    for y, x in zip(*np.nonzero(s)):
        if lab[y, x]:
            continue
        cur += 1
        stack, n = [(y, x)], 0
        while stack:
            cy, cx = stack.pop()
            if 0 <= cy < s.shape[0] and 0 <= cx < s.shape[1] and s[cy, cx] and not lab[cy, cx]:
                lab[cy, cx] = cur
                n += 1
                stack += [(cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)]
        sizes[cur] = n
    if sizes:
        keep = max(sizes, key=sizes.get)
        out[s & (lab != keep)] = 0
    return out


def reduce_colours(a, max_colors=30):
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import reduce_palette  # noqa: E402
    im = reduce_palette.reduce_image(Image.fromarray(a, "RGBA"), max_colors)
    return np.array(im.convert("RGBA"))


def clean_car(raw, mirror=False, max_colors=30):
    a = binarize_alpha(remove_flat_background(load_rgba(raw)))
    a = drop_specks(a)
    a = reduce_colours(a, max_colors)
    a = binarize_alpha(a)
    if mirror:
        a = a[:, ::-1].copy()
    return a


def colours(a):
    s = a[..., 3] == 255
    return {tuple(int(c) for c in p) for p in a[s][:, :3]}


# --- the composed preview ---

def ground_tile(name):
    import json
    atlas = json.loads((REPO / "game/art/ground/ground_atlas.json").read_text(encoding="utf-8"))
    entry = next(t for t in atlas["tiles"] if t["name"] == name)
    x, y = entry["atlas_xy"]
    return Image.open(REPO / "game/art/ground/ground_atlas.png").convert("RGBA").crop((x, y, x + TILE_W, y + TILE_H))


def screen(u, v, ox, oy):
    """World point (units) to canvas px: x = (u - v) * 32, y = (u + v) * 16."""
    return int(round(ox + (u - v) * U)), int(round(oy + (u + v) * U / 2))


def compose(sidewalk, car, bg):
    """Road along y at u in [4, 8), sidewalk at u in [0, 4) (curb tiles at u in [2, 4)), v in [0, 12)."""
    W, H = 860, 640
    ox, oy = 440, 210
    canvas = Image.new("RGBA", (W, H), (*bg, 255))
    side = Image.fromarray(sidewalk, "RGBA")
    plain = Image.fromarray(draw_sidewalk(curb=False), "RGBA")
    gravel = ground_tile("gravel0")
    road_r, road_l = ground_tile("y_line_r_a0"), ground_tile("y_line_l_a0")
    for j in range(6):
        for i, tile in enumerate([plain, side, road_r, road_l, gravel]):
            x, y = screen(2 * i, 2 * j, ox, oy)
            canvas.alpha_composite(tile, (x - TILE_W // 2, y))
    # the small creator building (6 x 6 units, with its own pavement) behind the sidewalk: footprint u in [-6, 0),
    # v in [0, 6), its front corner (anchor_art_px 192, 330) at (u, v) = (0, 6)
    bld = Image.open(REPO / "game/art/buildings/creator_final/small_0.png").convert("RGBA")
    fx, fy = screen(0, 6, ox, oy)
    canvas.alpha_composite(bld, (fx - 192, fy - 330))
    # the boulder on the road (centre at u = 6, v = 3), bbox bottom on the 3-unit circle's front edge
    bo = Image.open(REPO / "game/art/boulders/boulder_a.png").convert("RGBA")
    cx, cy = screen(6.0, 2.5, ox, oy)
    canvas.alpha_composite(bo, (cx - (32 + 131) // 2, cy + 24 - 120))
    # the parked car at the curb, its long axis along y, centre at u = 4.75, v = 8.5
    c = Image.fromarray(car, "RGBA")
    bbox = c.getbbox()
    if bbox is None:            # no car yet (the sidewalk's own preview)
        return canvas
    cx, cy = screen(4.75, 8.5, ox, oy)
    ccx, ccy = (bbox[0] + bbox[2]) // 2, (bbox[1] + bbox[3]) // 2
    canvas.alpha_composite(c, (cx - ccx, cy - ccy - 8))
    return canvas


def enlarge(im, k=3):
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def preview(sidewalk_png, car_png, out_dir):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    side = load_rgba(sidewalk_png)
    car = load_rgba(car_png) if car_png else np.zeros((8, 8, 4), np.uint8)
    dark = enlarge(compose(side, car, (20, 20, 30)))
    light = enlarge(compose(side, car, (225, 225, 230)))
    dark.save(out_dir / "preview_dark.png")
    light.save(out_dir / "preview_light.png")
    both = Image.new("RGBA", (dark.width * 2 + 24, dark.height), (128, 128, 128, 255))
    both.alpha_composite(dark, (0, 0))
    both.alpha_composite(light, (dark.width + 24, 0))
    both.save(out_dir / "preview_side_by_side.png")
    # a close-up of one curb tile's edge against the road (curb tile i = 1, j = 2), 8x, so the curb can be judged
    base = compose(side, car, (20, 20, 30))
    enlarge(base.crop((330, 296, 470, 386)), 8).save(out_dir / "preview_curb_zoom.png")
    # and the tile's own curb corner on its own, 10x, on the dark background
    tile = Image.new("RGBA", (72, 40), (20, 20, 30, 255))
    tile.alpha_composite(Image.fromarray(side, "RGBA").crop((56, 24, 128, 64)))
    enlarge(tile, 10).save(out_dir / "tile_curb_zoom.png")
    return out_dir / "preview_side_by_side.png"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("sidewalk")
    s.add_argument("--out", required=True)
    s.add_argument("--curb-px", type=int, default=3)
    s.add_argument("--seed", type=int, default=397)
    c = sub.add_parser("car")
    c.add_argument("--raw", required=True)
    c.add_argument("--out", required=True)
    c.add_argument("--mirror", action="store_true")
    c.add_argument("--max-colors", type=int, default=30)
    p = sub.add_parser("preview")
    p.add_argument("--sidewalk", required=True)
    p.add_argument("--car", help="the car PNG; left out, the preview has no car")
    p.add_argument("--out-dir", required=True)
    a = ap.parse_args(argv)
    if a.cmd == "sidewalk":
        img = draw_sidewalk(a.curb_px, a.seed)
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(img, "RGBA").save(a.out)
        print(f"{a.out}: {len(colours(img))} colours")
    elif a.cmd == "car":
        img = clean_car(a.raw, a.mirror, a.max_colors)
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(img, "RGBA").save(a.out)
        print(f"{a.out}: {len(colours(img))} colours, bbox {Image.fromarray(img).getbbox()}")
    else:
        print(preview(a.sidewalk, a.car, a.out_dir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
