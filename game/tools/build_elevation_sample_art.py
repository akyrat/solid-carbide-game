#!/usr/bin/env python3
"""Builds the elevation sample map's rooftop and parking-garage ramp art (T-198).

PixelLab (T-198's eight create-image-pixflux calls, in art-archive/T-198/) made
the textures and the rooftop details; this script projects the textures onto
the isometric faces of every raised area and ramp in
game/data/level/elevation_sample_map.json, at 32 art px per unit (drawn at scale
0.5 in the game's 16 px per unit world):

    screen x = (x - y) * 32,  screen y = (x + y) * 16 - height * 32

One sprite and one record per area, named after its id (roof-nw-3.png, ...).

Faces: the top (a rooftop: flat; a ramp: the sloped plane), the east wall and
the south wall (the two the view shows). A rooftop's walls are the building
wall texture (lit windows); a ramp's sides are the rooftop concrete, darker.
A wall runs from the height the area stands on (the rooftop under a stacked
rooftop or a ramp on a rooftop) up to its top. A ramp has no wall at the end
where it joins its rooftop. Rooftop details on the tops: a low parapet along
the back (north and west) edges with gaps where a ramp joins, AC units, vents
and a small sign near the back edges (never near a ramp or a rooftop standing
on it), and light cracks. A dark outline is added on silhouettes and between
faces, a lighter rim on the top's edges, and every sprite is reduced to at most
30 colours with no semi-transparent pixels.

Usage (from the repo root):
    python game/tools/build_elevation_sample_art.py build   # writes game/art/elevation_sample/
    python game/tools/build_elevation_sample_art.py --check # rules on the committed files
Needs Pillow and numpy (as build_buildings.py and city_palettes.py).
"""
import json
import os
import random
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from style_rules import is_redgull_red  # noqa: E402  (Visual style rule 6)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW = os.path.join(ROOT, "art-archive", "T-198")
OUT = os.path.join(ROOT, "game", "art", "elevation_sample")
DATA = os.path.join(ROOT, "game", "data", "level", "elevation_sample_map.json")
PX = 32                # art px per unit
MAX_COLORS = 30
OUTLINE = (10, 12, 24)
SHADE = {"platform": {"east": 0.86, "south": 0.66}, "ramp": {"east": 0.72, "south": 0.54}}
JOIN_EPS = 0.12        # units: where a ramp joins its rooftop there is no outline
TOP_MARGIN = 80        # art px above the geometry kept for the parapet and the details
PARAPET_PX = 20        # the parapet's height in art px
WALL_ROW_OFFSET = 4
RAW_FILES = ["raw_roof_top", "raw_wall", "raw_ramp_top", "raw_ac_unit", "raw_vent",
             "raw_sign", "raw_parapet", "raw_cracks"]


# ---------------------------------------------------------------- textures ----

def mirror(i, n):
    """Mirror tiling: indices (int or array) fold back and forth over 0..n-1."""
    i = np.asarray(i) % (2 * n)
    return np.where(i < n, i, 2 * n - 1 - i)


def load_rgb(name):
    return np.array(Image.open(os.path.join(RAW, name + ".png")).convert("RGB"), dtype=np.float32)


def load_rgba(name):
    return np.array(Image.open(os.path.join(RAW, name + ".png")).convert("RGBA"))


def to_concrete(arr, amount, dark):
    """Free script fix: PixelLab's tops are saturated teal; pull them towards the
    cool blue-grey of City concrete (amount 0..1) and darken (dark ~ 0.8)."""
    lum = arr[..., 0] * 0.3 + arr[..., 1] * 0.59 + arr[..., 2] * 0.11
    target = np.stack([lum * 0.88, lum * 0.96, lum * 1.08], axis=-1)
    out = (arr + (target - arr) * amount) * dark
    return np.clip(out, 0, 255)


def sample(tex, u, v):
    h, w = tex.shape[:2]
    iu = mirror(np.floor(u).astype(np.int64), w)
    iv = mirror(np.floor(v).astype(np.int64), h)
    return tex[iv, iu]


def crack_mask(arr_rgba):
    """The crack decal's dark line pixels (PixelLab left a light grey background)."""
    rgb = arr_rgba[..., :3].astype(np.float32)
    lum = rgb[..., 0] * 0.3 + rgb[..., 1] * 0.59 + rgb[..., 2] * 0.11
    return (lum < 90) & (arr_rgba[..., 3] > 127)


def load_textures():
    return {
        "roof": to_concrete(load_rgb("raw_roof_top"), 0.7, 0.85),
        "wall": to_concrete(load_rgb("raw_wall"), 0.3, 1.0),
        "ramp": to_concrete(load_rgb("raw_ramp_top"), 0.7, 0.85),
        "ac": load_rgba("raw_ac_unit"),
        "vent": load_rgba("raw_vent"),
        "sign": load_rgba("raw_sign"),
        "parapet": np.array(Image.open(os.path.join(RAW, "raw_parapet.png")).convert("RGBA")
                            .resize((128, PARAPET_PX), Image.NEAREST)),
        "cracks": crack_mask(load_rgba("raw_cracks")),
    }


# ---------------------------------------------------------------- geometry ----

def piece_plane(piece, kind, platforms_by_id):
    """(h0, gx, gy, base): top height = h0 + gx * x + gy * y, in units; base is
    the height the area stands on (walls start there)."""
    if kind == "platform":
        base = 0.0
        if piece.get("on"):
            base = float(platforms_by_id[piece["on"]]["height"])
        return float(piece["height"]), 0.0, 0.0, base
    x0, y0, w, h = piece["x"], piece["y"], piece["w"], piece["h"]
    top, bottom = float(piece["top_height"]), float(piece["bottom_height"])
    side = piece["side"]
    if side == "east":     # the top is at the west end
        g = (bottom - top) / w
        return top - g * x0, g, 0.0, bottom
    if side == "west":     # the top is at the east end
        g = (top - bottom) / w
        return bottom - g * x0, g, 0.0, bottom
    if side == "south":    # the top is at the north end
        g = (bottom - top) / h
        return top - g * y0, 0.0, g, bottom
    g = (top - bottom) / h  # north: the top is at the south end
    return bottom - g * y0, 0.0, g, bottom


def join_of(piece):
    """For a ramp: ('x' or 'y', value, 'low' or 'high') where it joins its rooftop;
    the end the wall is left off, and the outline skipped."""
    side = piece["side"]
    if side == "east":
        return "x", piece["x"], "low"
    if side == "west":
        return "x", piece["x"] + piece["w"], "high"
    if side == "south":
        return "y", piece["y"], "low"
    return "y", piece["y"] + piece["h"], "high"


def bounds(piece, h0, gx, gy, base):
    x0, y0 = piece["x"], piece["y"]
    x1, y1 = x0 + piece["w"], y0 + piece["h"]
    xs, ys = [], []
    for x, y in ((x0, y0), (x1, y0), (x1, y1), (x0, y1)):
        for hh in (h0 + gx * x + gy * y, base, 0.0):
            xs.append((x - y) * PX)
            ys.append((x + y) * PX / 2 - hh * PX)
    return int(np.floor(min(xs))), int(np.floor(min(ys))) - TOP_MARGIN, int(np.ceil(max(xs))), int(np.ceil(max(ys)))


# ------------------------------------------------------------------ render ----

def blocked_intervals(piece, kind, others, ramps, edge):
    """Intervals (units, along the edge) where no parapet stands: where a higher
    rooftop stands on the edge and where a ramp meets it. edge: 'north' or 'west'."""
    out = []
    x0, y0 = piece["x"], piece["y"]
    for o in others:
        if o["id"] == piece["id"] or float(o["height"]) <= float(piece["height"]):
            continue
        if edge == "north" and o["y"] <= y0 < o["y"] + o["h"]:
            out.append((o["x"], o["x"] + o["w"]))
        if edge == "west" and o["x"] <= x0 < o["x"] + o["w"]:
            out.append((o["y"], o["y"] + o["h"]))
    for r in ramps:
        if edge == "north" and r["y"] - 0.5 <= y0 <= r["y"] + r["h"] + 0.5:
            out.append((r["x"] - 0.5, r["x"] + r["w"] + 0.5))
        if edge == "west" and r["x"] - 0.5 <= x0 <= r["x"] + r["w"] + 0.5:
            out.append((r["y"] - 0.5, r["y"] + r["h"] + 0.5))
    return out


def in_any(t, intervals):
    m = np.zeros(np.shape(t), dtype=bool)
    for a, b in intervals:
        m |= (t >= a) & (t < b)
    return m


def detail_spots(piece, others, ramps):
    """Deterministic spots (flat units) for details along the back edges: lists
    of (kind, x, y). Away from every ramp and every higher rooftop (3 units)."""
    rng = random.Random(piece["id"])
    x0, y0 = piece["x"], piece["y"]
    x1, y1 = x0 + piece["w"], y0 + piece["h"]
    keep_out = [(r["x"] - 3, r["y"] - 3, r["x"] + r["w"] + 3, r["y"] + r["h"] + 3) for r in ramps]
    keep_out += [(o["x"] - 3, o["y"] - 3, o["x"] + o["w"] + 3, o["y"] + o["h"] + 3)
                 for o in others if o["id"] != piece["id"] and float(o["height"]) > float(piece["height"])]
    cands = []
    for i in range(int(piece["w"] // 4)):
        cands.append((x0 + 2 + i * 4 + rng.uniform(-0.5, 0.5), y0 + rng.uniform(1.8, 3.0)))
    for i in range(int(piece["h"] // 4)):
        cands.append((x0 + rng.uniform(1.8, 3.0), y0 + 2 + i * 4 + rng.uniform(-0.5, 0.5)))
    cands = [c for c in cands if x0 + 1 < c[0] < x1 - 1 and y0 + 1 < c[1] < y1 - 1
             and not any(a <= c[0] <= c2 and b <= c[1] <= d for a, b, c2, d in keep_out)]
    rng.shuffle(cands)
    area = piece["w"] * piece["h"]
    plan = ["sign"] * (1 if area >= 900 else 0) + ["ac"] * max(1, round(area / 600)) + ["vent"] * max(1, round(area / 600))
    spots = []
    for kind in plan:
        for c in list(cands):
            if all(abs(c[0] - s[1]) + abs(c[1] - s[2]) >= 5 for s in spots):
                spots.append((kind, c[0], c[1]))
                cands.remove(c)
                break
    return spots


def crack_spots(piece, others, ramps):
    rng = random.Random(piece["id"] + "-cracks")
    x0, y0 = piece["x"], piece["y"]
    x1, y1 = x0 + piece["w"], y0 + piece["h"]
    out = []
    for _ in range(int(piece["w"] * piece["h"] / 120)):
        x, y = rng.uniform(x0 + 1, x1 - 1), rng.uniform(y0 + 1, y1 - 1)
        if any(o["id"] != piece["id"] and float(o["height"]) > float(piece["height"])
               and o["x"] - 1 <= x <= o["x"] + o["w"] + 1 and o["y"] - 1 <= y <= o["y"] + o["h"] + 1 for o in others):
            continue
        if any(r["x"] - 1 <= x <= r["x"] + r["w"] + 1 and r["y"] - 1 <= y <= r["y"] + r["h"] + 1 for r in ramps):
            continue
        out.append((x, y))
    return out


def render(piece, kind, tex, platforms, ramps, platforms_by_id):
    """Returns (RGBA uint8 array, (minx, miny) art px of its top-left, face map)."""
    x0, y0 = piece["x"], piece["y"]
    x1, y1 = x0 + piece["w"], y0 + piece["h"]
    h0, gx, gy, base = piece_plane(piece, kind, platforms_by_id)
    minx, miny, maxx, maxy = bounds(piece, h0, gx, gy, base)
    w, h = maxx - minx, maxy - miny
    out = np.zeros((h, w, 4), dtype=np.uint8)
    face = np.zeros((h, w), dtype=np.uint8)   # 0 none, 1 top, 2 east, 3 south
    along = np.zeros((h, w), dtype=np.float32)  # the coordinate across the join axis
    join = join_of(piece) if kind == "ramp" else None
    shade = SHADE[kind]
    side_tex = tex["wall"] if kind == "platform" else tex["roof"]

    sy = (np.arange(h, dtype=np.float32) + miny + 0.5)[:, None]
    sx = (np.arange(w, dtype=np.float32) + minx + 0.5)[None, :]
    p = sx / PX
    denom = 16 - 16 * gx - 16 * gy
    q = (sy + 32 * h0 + 16 * p * (gx - gy)) / denom
    X = (q + p) / 2
    Y = (q - p) / 2

    # Top face.
    top = (X >= x0) & (X < x1) & (Y >= y0) & (Y < y1)
    ys, xs = np.nonzero(top)
    tx, ty = X[ys, xs], Y[ys, xs]
    if kind == "platform":
        col = sample(tex["roof"], tx * PX, ty * PX)
        cracks = np.zeros(len(tx), dtype=bool)
        cm = tex["cracks"]
        ch, cw = cm.shape
        for cx, cy in crack_spots(piece, platforms, ramps):
            u = (tx - cx) * PX + cw / 2
            v = (ty - cy) * PX + ch / 2
            inside = (u >= 0) & (u < cw) & (v >= 0) & (v < ch)
            hit = np.zeros(len(tx), dtype=bool)
            hit[inside] = cm[v[inside].astype(int), u[inside].astype(int)]
            cracks |= hit
        col = np.where(cracks[:, None], col * 0.55, col)
    else:
        swap = piece["side"] in ("east", "west")   # the lane lines run along the ramp
        u, v = (ty, tx) if swap else (tx, ty)
        col = sample(tex["ramp"], u * PX, v * PX)
    out[ys, xs, :3] = np.clip(col, 0, 255).astype(np.uint8)
    out[ys, xs, 3] = 255
    face[ys, xs] = 1
    along[ys, xs] = tx if (join and join[0] == "x") else ty

    # East wall: the plane x = x1 (left off where a ramp joins at its high east end).
    ye = x1 - p
    top_e = h0 + gx * x1 + gy * ye
    depth_e = (x1 + ye) * PX / 2 - sy
    east = (face == 0) & (ye >= y0) & (ye < y1) & (depth_e >= base * PX) & (depth_e < top_e * PX)
    if join and join[0] == "x" and join[2] == "high":
        east &= False
    ys, xs = np.nonzero(east)
    below = np.broadcast_to(top_e * PX - depth_e, (h, w))[ys, xs]
    yy = np.broadcast_to(ye, (h, w))[ys, xs]
    col = sample(side_tex, yy * PX, below + WALL_ROW_OFFSET) * shade["east"]
    col = np.where((below < 2)[:, None], np.minimum(col * 1.25 + 10, 255), col)
    out[ys, xs, :3] = np.clip(col, 0, 255).astype(np.uint8)
    out[ys, xs, 3] = 255
    face[ys, xs] = 2
    along[ys, xs] = yy

    # South wall: the plane y = y1 (left off where a ramp joins at its high south end).
    xsouth = p + y1
    top_s = h0 + gx * xsouth + gy * y1
    depth_s = (xsouth + y1) * PX / 2 - sy
    south = (face == 0) & (xsouth >= x0) & (xsouth < x1) & (depth_s >= base * PX) & (depth_s < top_s * PX)
    if join and join[0] == "y" and join[2] == "high":
        south &= False
    ys, xs = np.nonzero(south)
    below = np.broadcast_to(top_s * PX - depth_s, (h, w))[ys, xs]
    xx = np.broadcast_to(xsouth, (h, w))[ys, xs]
    col = sample(side_tex, xx * PX, below + WALL_ROW_OFFSET) * shade["south"]
    col = np.where((below < 2)[:, None], np.minimum(col * 1.25 + 10, 255), col)
    out[ys, xs, :3] = np.clip(col, 0, 255).astype(np.uint8)
    out[ys, xs, 3] = 255
    face[ys, xs] = 3
    along[ys, xs] = xx if (join and join[0] == "x") else y1

    outline(out, face, along, join)

    if kind == "platform":
        add_parapet(out, tex["parapet"], piece, platforms, ramps, minx, miny, h0)
        add_details(out, tex, piece, platforms, ramps, minx, miny, h0)
    return out, (minx, miny), face


def outline(out, face, along, join):
    """Dark outline on the silhouette and where a wall meets another face; a
    lighter rim on the top face along its edges. Not where a ramp joins."""
    h, w = face.shape
    pad = np.pad(face, 1)
    marks_dark = np.zeros((h, w), dtype=bool)
    marks_rim = np.zeros((h, w), dtype=bool)
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nf = pad[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
        diff = (nf != face) & (face != 0)
        marks_dark |= diff & ((nf == 0) | ((face != 1) & (nf == 1)))
        marks_rim |= diff & (face == 1) & (nf != 0)
    if join is not None:
        axis, value, end = join
        near = along < value + JOIN_EPS if end == "low" else along > value - JOIN_EPS
        skip = near & (face != 0)
        if axis == "y":
            skip = near & ((face == 1) | (face == 2))
        else:
            skip = near & ((face == 1) | (face == 3))
        marks_dark &= ~skip
        marks_rim &= ~skip
    rgb = out[..., :3].astype(np.int32)
    lighter = np.stack([np.minimum(255, (rgb[..., 0] * 1.35 + 12).astype(np.int32)),
                        np.minimum(255, (rgb[..., 1] * 1.35 + 12).astype(np.int32)),
                        np.minimum(255, (rgb[..., 2] * 1.35 + 14).astype(np.int32))], axis=-1)
    rim = marks_rim & ~marks_dark
    out[..., :3] = np.where(rim[..., None], lighter, rgb).astype(np.uint8)
    out[marks_dark, :3] = OUTLINE


def paste(out, spr, left, top):
    """Pastes an RGBA sprite (alpha 0 or 255 after a threshold) at (left, top)."""
    h, w = spr.shape[:2]
    H, W = out.shape[:2]
    x_a, y_a = max(0, left), max(0, top)
    x_b, y_b = min(W, left + w), min(H, top + h)
    if x_a >= x_b or y_a >= y_b:
        return
    part = spr[y_a - top:y_b - top, x_a - left:x_b - left]
    m = part[..., 3] > 127
    dst = out[y_a:y_b, x_a:x_b]
    dst[m] = np.concatenate([part[m][:, :3], np.full((int(m.sum()), 1), 255, dtype=np.uint8)], axis=1)


def add_parapet(out, parapet, piece, platforms, ramps, minx, miny, height):
    """A low wall along the north and west edges, standing on the top, with its
    inner face towards the view; gaps where a ramp joins or a higher rooftop stands."""
    x0, y0 = piece["x"], piece["y"]
    x1, y1 = x0 + piece["w"], y0 + piece["h"]
    h, w = out.shape[:2]
    sy = (np.arange(h, dtype=np.float32) + miny + 0.5)[:, None]
    sx = (np.arange(w, dtype=np.float32) + minx + 0.5)[None, :]
    p = sx / PX
    ph = parapet.shape[0]
    # North edge: the plane y = y0, x along it, facing south.
    xn = p + y0
    base_sy = (xn + y0) * PX / 2 - height * PX
    d = base_sy - sy
    m = (xn >= x0) & (xn < x1) & (d >= 0) & (d < ph)
    m &= ~in_any(xn, blocked_intervals(piece, "platform", platforms, ramps, "north"))
    ys, xs = np.nonzero(m)
    spr = parapet[(ph - 1 - np.broadcast_to(d, (h, w))[ys, xs]).astype(int),
                  mirror((np.broadcast_to(xn, (h, w))[ys, xs] * PX).astype(int), 128)]
    keep = spr[:, 3] > 127
    out[ys[keep], xs[keep]] = spr[keep]
    # West edge: the plane x = x0, y along it, facing east.
    yw = x0 - p
    base_sy = (x0 + yw) * PX / 2 - height * PX
    d = base_sy - sy
    m = (yw >= y0) & (yw < y1) & (d >= 0) & (d < ph)
    m &= ~in_any(yw, blocked_intervals(piece, "platform", platforms, ramps, "west"))
    ys, xs = np.nonzero(m)
    spr = parapet[(ph - 1 - np.broadcast_to(d, (h, w))[ys, xs]).astype(int),
                  mirror((np.broadcast_to(yw, (h, w))[ys, xs] * PX).astype(int), 128)]
    spr = spr.copy()
    spr[:, :3] = (spr[:, :3] * 0.8).astype(np.uint8)   # the west run faces east: a little darker
    keep = spr[:, 3] > 127
    out[ys[keep], xs[keep]] = spr[keep]


def add_details(out, tex, piece, platforms, ramps, minx, miny, height):
    """AC units, vents and a sign, back to front, their feet on the top."""
    spots = detail_spots(piece, platforms, ramps)
    spots.sort(key=lambda s: s[1] + s[2])
    for kind, x, y in spots:
        spr = tex[kind]
        ys, xs = np.nonzero(spr[..., 3] > 127)
        foot_x = int((xs.min() + xs.max()) / 2)
        foot_y = int(ys.max()) - 3          # the object's base sits a few px above its lowest pixel
        sx = int((x - y) * PX) - minx
        sy = int((x + y) * PX / 2 - height * PX) - miny
        paste(out, spr, sx - foot_x, sy - foot_y)


def reduce_colors(arr, n=MAX_COLORS):
    """Cut to at most n colours (median cut, no dither); alpha stays 0 or 255."""
    alpha = arr[..., 3] > 127
    img = Image.fromarray(arr[..., :3], "RGB")
    # Quantise only the opaque pixels' colours: put the transparent ones on a copy of a used colour.
    rgb = arr[..., :3].copy()
    if alpha.any():
        rgb[~alpha] = rgb[alpha][0]
    img = Image.fromarray(rgb, "RGB").quantize(colors=n, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGB")
    res = np.array(img)
    res = np.concatenate([res, np.where(alpha, 255, 0).astype(np.uint8)[..., None]], axis=-1)
    res[~alpha] = (0, 0, 0, 0)
    return res


def crop(arr, origin):
    a = arr[..., 3] > 0
    ys, xs = np.nonzero(a)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    return arr[y0:y1, x0:x1], (origin[0] + int(x0), origin[1] + int(y0))


# ------------------------------------------------------------------- build ----

def load_data(path=DATA):
    with open(path) as f:
        data = json.load(f)
    return data["platforms"], data["ramps"]


def pieces(platforms, ramps):
    return [("platform", p) for p in platforms] + [("ramp", r) for r in ramps]


def build(out_dir=OUT):
    platforms, ramps = load_data()
    by_id = {p["id"]: p for p in platforms}
    tex = load_textures()
    os.makedirs(out_dir, exist_ok=True)
    for kind, piece in pieces(platforms, ramps):
        arr, origin, _ = render(piece, kind, tex, platforms, ramps, by_id)
        arr, origin = crop(reduce_colors(arr), origin)
        name = piece["id"]
        Image.fromarray(arr, "RGBA").save(os.path.join(out_dir, name + ".png"))
        sources = ["raw_roof_top", "raw_wall", "raw_ac_unit", "raw_vent", "raw_sign", "raw_parapet", "raw_cracks"] \
            if kind == "platform" else ["raw_ramp_top", "raw_roof_top"]
        rec = {
            "asset": name,
            "task": "T-198",
            "kind": kind,
            "piece_id": piece["id"],
            "image": {"width": int(arr.shape[1]), "height": int(arr.shape[0])},
            "px_per_unit": PX,
            "drawn_at_scale": 0.5,
            "top_left_art_px": [int(origin[0]), int(origin[1])],
            "note": "top_left_art_px is where the image's top-left sits relative to the scene's drawn origin (art px, +y down); the game draws it at scale 0.5.",
            "source_json": "game/data/level/elevation_sample_map.json",
            "pixellab": [{"record": "art-archive/T-198/%s.json" % s, "image": "art-archive/T-198/%s.png" % s,
                          "endpoint": "create-image-pixflux", "generations": 1} for s in sources],
            "script": "game/tools/build_elevation_sample_art.py",
            "steps": "PixelLab textures projected onto the isometric faces by script (mirror tiling), parapet, details and cracks on rooftops, outline and rim, reduced to at most %d colours." % MAX_COLORS,
        }
        with open(os.path.join(out_dir, name + ".json"), "w") as f:
            json.dump(rec, f, indent=2)
            f.write("\n")
        print(name, (arr.shape[1], arr.shape[0]), origin)


# ------------------------------------------------------------------- check ----

def rules(path):
    """Returns a list of (rule, ok, detail) for a game image (any size)."""
    img = Image.open(path).convert("RGBA")
    a = np.array(img)
    h, w = a.shape[:2]
    corners = [a[0, 0], a[0, w - 1], a[h - 1, 0], a[h - 1, w - 1]]
    semi = int(((a[..., 3] > 0) & (a[..., 3] < 255)).sum())
    opaque = a[a[..., 3] == 255][:, :3]
    counts = {}
    for c in map(tuple, opaque.tolist()):
        counts[c] = counts.get(c, 0) + 1
    colors = len(counts)
    red = sum(n for c, n in counts.items() if is_redgull_red(c))
    return [
        ("transparent background (corners)", all(c[3] == 0 for c in corners), str([tuple(c) for c in corners])),
        ("no semi-transparent pixels", semi == 0, "%d" % semi),
        ("%d colours or fewer" % MAX_COLORS, colors <= MAX_COLORS, "%d" % colors),
        ("no Redgull red", red == 0, "%d" % red),
    ]


def check(out_dir=OUT, data_path=DATA):
    platforms, ramps = load_data(data_path)
    ok = True
    for _, piece in pieces(platforms, ramps):
        name = piece["id"]
        png, rec_path = os.path.join(out_dir, name + ".png"), os.path.join(out_dir, name + ".json")
        if not os.path.exists(png) or not os.path.exists(rec_path):
            print("FAIL  %s: sprite or record missing" % name)
            ok = False
            continue
        with open(rec_path) as f:
            rec = json.load(f)
        with Image.open(png) as im:
            size = im.size
        rec_ok = rec.get("px_per_unit") == PX and rec.get("drawn_at_scale") == 0.5 \
            and rec.get("image") == {"width": size[0], "height": size[1]} and len(rec.get("top_left_art_px", [])) == 2
        print("%s  %s record (32 art px per unit, scale 0.5, size matches)" % ("PASS" if rec_ok else "FAIL", name))
        ok = ok and rec_ok
        for rule, good, detail in rules(png):
            print("%s  %s %s: %s" % ("PASS" if good else "FAIL", name, rule, detail))
            ok = ok and good
    return 0 if ok else 1


def main(argv):
    cmd = argv[1] if len(argv) > 1 else "build"
    if cmd in ("build", "--build"):
        build()
        return 0
    if cmd in ("check", "--check"):
        return check()
    sys.exit("usage: build_elevation_sample_art.py build|--check")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
