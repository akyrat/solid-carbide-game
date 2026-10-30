#!/usr/bin/env python3
"""T-398: the level creator's sidewalk tiles (every curb piece) and meteor craters, as placeholders.

Free, no PixelLab: both are drawn by T-397's approved sample script (build_sidewalk_car_sample.py:
draw_sidewalk for the slabs, draw_crater for the crater), so they already fit the roads. T-399 swaps
the final art in by changing the files this script writes (and their json).

  python game/tools/build_street_pieces.py build   # writes the files below
  python game/tools/build_street_pieces.py check   # the committed files match a fresh build, and the rules
  T-399 (the style loop's versions and previews):
  python game/tools/build_street_pieces.py sheet --out <png>          # the sidewalk sheet, as build draws it
  python game/tools/build_street_pieces.py crater-strip --out <png>   # the crater looks in one row
  python game/tools/build_street_pieces.py preview-sidewalks --sheet <png> --out-dir <dir>   # on a crossroads
  python game/tools/build_street_pieces.py preview-craters --strip <png> --out-dir <dir>     # on each ground

Writes:
  game/art/ground/sidewalk_tiles.png   one 128 x 64 ground tile (2 x 2 units) per curb piece, 8 to a row
  game/art/ground/sidewalk_tiles.json  per tile: name (the catalogue id), edges, corners, region
  game/art/craters/crater_<n>.png      CRATER_LOOKS ground decals (the road tile's diamond)
  game/data/level/craters.json         per crater: id, label, footprint_units, texture

A sidewalk tile's curb pieces (scripts/level_creator/sidewalk_curbs.gd picks them, the same names):
  edges   the sides with a road next to them, of "nesw" (n = -y, the screen's upper right; e = +x,
          lower right; s = +y, lower left; w = -x, upper left): a straight curb along each.
  corners the inner corners, of ne, se, sw, nw: a road diagonally next to the tile while neither side
          of that corner has one (where two sidewalks meet round a road's corner).
  Two edges next to each other make an outer corner by themselves. The name: "sidewalk", then
  "-<edges>" when it has edges, then "-in_<corner>_<corner>" when it has inner corners
  ("sidewalk-es", "sidewalk-n-in_se_sw", "sidewalk-in_ne").

Rules (check): alpha 0 or 255, at most 30 colours a file, no old-brand red. Same input, same pixels.
Needs Pillow and numpy.
"""
from __future__ import annotations

import itertools
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_sidewalk_car_sample as sample  # noqa: E402

GAME = Path(__file__).resolve().parents[1]
SHEET_PNG = GAME / "art/ground/sidewalk_tiles.png"
SHEET_JSON = GAME / "art/ground/sidewalk_tiles.json"
CRATER_DIR = GAME / "art/craters"
CRATERS_JSON = GAME / "data/level/craters.json"

TILE_W, TILE_H = sample.TILE_W, sample.TILE_H
COLS = 8
EDGES = "nesw"
CORNERS = ["ne", "se", "sw", "nw"]
CURB_PX = 3            # the sample's lift of the surface, art px (under the 0.1-unit curb rule)
SEED = 397             # the sample's seed: the same slabs and cracks as the approved tile
# Crater looks (proposal: three, as the ticket's "a few"): the sample's crater drawn with other seeds and
# hole sizes. Footprint 2 x 2 units (one ground tile), as the approved sample.
# T-399 (style loop v2): each look is draw_crater's keywords: a round rim with radial cracks, a broken,
# uneven rim of many small slabs with cracks ringing the hole, and a wide round rim of few big slabs with
# branching cracks.
CRATER_LOOKS = [
    # (v4) look 1 a deep, narrower pit with few cracks; look 3 wide and shallow, the glow-heavy one
    dict(seed=397, r_hole=0.58, depth_px=10, n_slabs=9, rim_wobble=0.05, missing=0.15, cracks="radial",
         n_cracks=3),
    dict(seed=4011, r_hole=0.54, n_slabs=12, rim_wobble=0.08, missing=0.3, cracks="ringed", n_cracks=3),
    dict(seed=4012, r_hole=0.66, depth_px=7, n_slabs=7, rim_wobble=0.03, missing=0.05, cracks="branching",
         n_cracks=4),
]
CRATER_FOOT = [2.0, 2.0]
MAX_COLORS = 30
RED_MIN, RED_OVER, RED_MAX_OTHER = 150, 70, 100


def tile_name(edges: str, corners: list[str]) -> str:
    s = "sidewalk"
    if edges:
        s += "-" + edges
    if corners:
        s += "-in_" + "_".join(corners)
    return s


def variants() -> list[tuple[str, list[str]]]:
    """Every (edges, corners) a tile can have: any edges, and an inner corner only where neither of its
    sides has an edge. The plain tile first."""
    out = []
    for n in range(16):
        edges = "".join(EDGES[i] for i in range(4) if n & (1 << i))
        free = [c for c in CORNERS if c[0] not in edges and c[1] not in edges]
        for k in range(len(free) + 1):
            for combo in itertools.combinations(free, k):
                out.append((edges, list(combo)))
    return out


def draw_tile(edges: str, corners: list[str]) -> np.ndarray:
    """One sidewalk tile with the curbs of `edges` and `corners` (the sample's colours). A front edge (e, s)
    shows the curb's top, its face and the gutter, as the approved sample; a back edge (n, w) shows its top
    and the gutter strip (its face looks away)."""
    img = sample.draw_sidewalk(CURB_PX, SEED, curb=False)
    ys, xs = np.mgrid[0:TILE_H, 0:TILE_W]
    u0, v0 = sample.ground_uv(xs, ys)
    u, v = sample.ground_uv(xs, ys, lift=CURB_PX)
    inside = (u0 >= 0) & (u0 < 2) & (v0 >= 0) & (v0 < 2)
    W, I = sample.CURB_WIDTH, sample.CURB_INSET
    edge = 2 - I
    _thin_texture(img, inside, u, v)

    # (v2) one road shape for the whole tile (the edges' strips and the inner corners' squares), so every curb
    # piece is cut from the same outline: straights, outer corners and inner corners mitre with no overshoot
    def road(a, b):
        r = np.zeros(a.shape, dtype=bool)
        if "n" in edges:
            r |= b < I
        if "w" in edges:
            r |= a < I
        if "e" in edges:
            r |= a >= edge
        if "s" in edges:
            r |= b >= edge
        for c in corners:
            r |= ((a >= edge) if "e" in c else (a < I)) & ((b >= edge) if "s" in c else (b < I))
        return r

    def near(a, b):
        r = np.zeros(a.shape, dtype=bool)
        for da in (-W, 0, W):
            for db in (-W, 0, W):
                r |= road(a + da, b + db)
        return r

    strip = inside & road(u0, v0)                           # road-dark ground up to the tile's edge
    face = inside & road(u, v) & ~strip                     # the raised surface ends: the face (front edges only)
    top = inside & ~strip & ~face & (near(u, v) | near(u0, v0))
    slab = inside & ~strip & ~face & ~top

    def nb(mask):
        """Pixels with a 4-neighbour in `mask` (inside the tile)."""
        m = np.zeros_like(mask)
        m[1:] |= mask[:-1]
        m[:-1] |= mask[1:]
        m[:, 1:] |= mask[:, :-1]
        m[:, :-1] |= mask[:, 1:]
        return m

    def up(mask, k=1):
        """Pixels `k` rows above a pixel of `mask` (the mask shifted up)."""
        m = np.zeros_like(mask)
        m[:-k] = mask[k:]
        return m

    def down(mask, k=1):
        """Pixels `k` rows below a pixel of `mask`."""
        m = np.zeros_like(mask)
        m[k:] = mask[:-k]
        return m

    # (v3) an irregular pattern on the ground (so it runs on across tiles with no seam) to break the lit edges
    cu, cv = np.floor(np.mod(u0, 2) * 32).astype(int), np.floor(np.mod(v0, 2) * 32).astype(int)
    hl = ((cu * 92837111) ^ (cv * 689287499) ^ 0x5bd1) & 0xFFFF
    hl = (hl * 2654435761 >> 7) & 0xFF

    curb = top | face
    img[top] = [*sample.CURB_TOP, 255]
    img[top & nb(slab)] = [*sample.PAV_EDGE, 255]           # the seam between the slabs and the curb stone
    img[face] = [*sample.CURB_FACE, 255]
    img[strip] = [*sample.GUTTER_STRIP, 255]
    # (v3) the face's two lower rows are shaded, so a front curb shows a clear mid-dark band under the lip
    img[face & (up(strip) | up(strip, 2)) & down(face)] = [*sample.CURB_FACE_LOW, 255]
    # (v3) a back curb (top straight against the road) shows a 2 px dark seam on its road side: the stone's
    # edge (shaded) next to the road, a face-grey row inside it
    back_edge = top & down(strip)
    img[top & down(strip, 2) & ~back_edge & ~nb(slab)] = [*sample.CURB_FACE, 255]
    img[back_edge] = [*sample.CURB_FACE_LOW, 255]
    # (v3) the near-black gutter line: one pixel per column, straight above or below the curb, so it is the same
    # 1 px 2:1 line on every tile and runs unbroken round outer and inner corners
    img[strip & (up(curb) | down(curb))] = [*sample.GUTTER, 255]
    # the lit lip: a curb-top pixel right above a face pixel, broken by irregular highlight pixels
    lip = top & up(face)
    img[lip] = [*sample.CURB_LIP, 255]
    img[lip & (hl % 3 == 0)] = [*sample.CURB_HIGHLIGHT, 255]
    # (v3) the back curbs' tops get the same broken lit edge on their middle, so all curbs carry highlights
    back_mid = top & ~nb(slab) & ~down(strip) & ~down(strip, 2) & ~lip & ~face
    img[back_mid & (hl % 5 == 0)] = [*sample.CURB_LIP, 255]
    img[back_mid & (hl % 11 == 0)] = [*sample.CURB_HIGHLIGHT, 255]
    return img


def _thin_texture(img, inside, u, v):
    """(v2) Thins the sample's speckle and breaks its cracks up a little, so they read less stamped. The
    choice hangs on the ground position, so the tiles still repeat every 2 units with no seam."""
    uw, vw = np.mod(u, 2), np.mod(v, 2)
    slab = (np.floor(uw).astype(int) + np.floor(vw).astype(int)) % 2
    base = np.where((slab == 0)[..., None], np.array([*sample.PAV_DARK, 255]),
                    np.array([*sample.PAV, 255])).astype(np.uint8)
    gu, gv = np.floor(uw * 16).astype(int), np.floor(vw * 16).astype(int)
    h = (gu * 2654435761 ^ gv * 40503 ^ 7919) & 0xFFFF
    rgb = img[..., :3]
    speck = inside & np.all(rgb == sample.PAV_LIGHT, axis=-1)
    crack = inside & np.all(rgb == sample.PAV_EDGE, axis=-1)
    drop = (speck & (h % 5 < 2)) | (crack & (h % 7 < 2))
    img[drop] = base[drop]


def build_sheet():
    vs = variants()
    rows = (len(vs) + COLS - 1) // COLS
    sheet = np.zeros((rows * TILE_H, COLS * TILE_W, 4), dtype=np.uint8)
    tiles = []
    for k, (edges, corners) in enumerate(vs):
        x, y = (k % COLS) * TILE_W, (k // COLS) * TILE_H
        sheet[y:y + TILE_H, x:x + TILE_W] = draw_tile(edges, corners)
        tiles.append({"name": tile_name(edges, corners), "edges": edges, "corners": corners,
                      "region": [x, y, TILE_W, TILE_H]})
    record = {
        "about": "T-398: the level creator's sidewalk tiles, one per curb piece (placeholders drawn by "
                 "game/tools/build_street_pieces.py from T-397's approved sample; T-399 swaps the art). "
                 "edges: the sides with a road next to them (n -y, e +x, s +y, w -x); corners: the inner "
                 "corners (a road diagonally next to it, neither side has one). Do not edit by hand.",
        "file": "res://art/ground/sidewalk_tiles.png", "tile_px": [TILE_W, TILE_H],
        "cell_units": 2, "tiles": tiles}
    return sheet, record


# T-399's crater: a copy of T-397's sample.draw_crater (which stays as it was, so the sample is reproducible),
# refined in the style loop. Same asphalt and boulder palette as the sample, plus a navy-purple far wall and a
# brighter slab top.
WALL_TOP, WALL_MID, WALL_LOW = (104, 96, 156), (80, 72, 132), (56, 50, 102)
WALL_GLINT = (132, 124, 184)
SLAB_LIGHT = (130, 128, 142)
SLAB_GLINT = (156, 154, 168)    # (v4) the lit top edge of the far slabs


def _nb4(m):
    """Pixels 4-adjacent to mask m (not in it)."""
    p = np.pad(m, 1)
    return (p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]) & ~m


def _line(p0, p1):
    (x0, y0), (x1, y1) = p0, p1
    n = max(abs(x1 - x0), abs(y1 - y0), 1)
    return [(int(round(x0 + (x1 - x0) * i / n)), int(round(y0 + (y1 - y0) * i / n))) for i in range(n + 1)]


def draw_crater(seed=397, r_hole=0.58, depth_px=10, n_slabs=10, rim_wobble=0.05, missing=0.15,
                cracks="radial", n_cracks=5):
    """A meteor crater as a 128 x 64 ground decal (2 x 2 units, transparent round it). As T-397's sample, plus:
    a far inner wall in its own navy-purple tones, stepped from lit to dark, over a darker floor; brighter,
    two-tone lit slab tops; a dithered scorch band; glowing cracks with a two-step halo all along; and three
    crack layouts ("radial", "ringed" round the hole, "branching")."""
    s_ = sample
    W, H = TILE_W, TILE_H
    rng = np.random.default_rng(seed)
    ys, xs = np.mgrid[0:H, 0:W]
    u, v = s_.ground_uv(xs, ys)
    du, dv = u - 1, v - 1
    d, a = np.hypot(du, dv), np.arctan2(dv, du)
    s = du + dv
    r_in = r_hole + _wobble_safe(a, rng, rim_wobble)
    r_base = r_in + 0.12
    img = np.zeros((H, W, 4), dtype=np.uint8)
    put = lambda m, c: img.__setitem__(m, [*c, 255])  # noqa: E731
    noise = rng.random(d.shape)
    dith = (xs + ys) % 2 == 0

    # scorched ground: stepped bands, each step's edge dithered one band wide; never past the diamond's edge
    tongue = np.zeros_like(d)
    for _ in range(3):
        ta = rng.uniform(-np.pi, np.pi)
        tongue += 0.06 * np.exp(-((np.angle(np.exp(1j * (a - ta)))) / 0.2) ** 2)
    q = lambda r: np.round(r * 24) / 24  # noqa: E731
    r1 = np.minimum(r_base + 0.20 + s_._wobble(a, rng, 0.03, terms=5) + tongue, 0.97)
    r2 = r_base + 0.11 + s_._wobble(a, rng, 0.02) + tongue * 0.6
    r3 = r_base + 0.05 + s_._wobble(a, rng, 0.015)
    # (v3) one wide, clean checker band at the outer edge and one between the scorch steps; the steps inside
    # are solid, so the band no longer looks fuzzy
    r1s = np.minimum(np.round(r1 * 12) / 12, 0.97)
    # (v4) darker throughout (scorch, not road asphalt), so it shows on gravel and sidewalk too
    put((d < r1s) & dith, s_.SCORCH)
    put(d < r1s - 0.09, s_.SCORCH)
    put((d < q(r2)) & dith, s_.SCORCH_DEEP)
    put(d < q(r2) - 0.07, s_.SCORCH_DEEP)

    # the hole: the floor (seen depth_px lower) where it shows, else the far inner wall
    hole = d < r_in
    fu, fv = s_.ground_uv(xs, ys - depth_px)
    fd = np.hypot(fu - 1, fv - 1)
    fa = np.arctan2(fv - 1, fu - 1)
    floor = hole & (fd < r_hole - 0.12 + _wobble_safe(fa, np.random.default_rng(seed), rim_wobble))
    wall = hole & ~floor
    rows = np.zeros(wall.shape, int)
    for y in range(1, H):
        rows[y] = np.where(wall[y] & wall[y - 1], rows[y - 1] + 1, 0)
    # the far wall in its own navy-purple, lit at the top under the cut asphalt and stepping down to dark,
    # darker at its two ends (it curves away); the floor stays darker than any of it
    side = np.abs(du - dv) > 0.42 + r_hole * 0.2
    # (v3) brighter steps, the lowest (at the wall's foot) still clearly lighter than the floor, so they separate
    put(wall, WALL_LOW)
    put(wall & (rows <= 6) & ~side, WALL_MID)
    put(wall & (rows >= 2) & (rows <= 3), WALL_TOP)
    put(wall & (rows >= 2) & (rows <= 4) & ~side & (noise < 0.12), WALL_GLINT)    # stepped highlights
    put(wall & (rows >= 5) & (rows <= 7) & (noise < 0.07), s_.ROCK)               # meteor grit
    put(wall & (rows <= 1), s_.ASPH)
    put(wall & (rows == 0), s_.ASPH_LIT)
    put(floor, s_.FLOOR)

    # the glow on the floor: small solid stepped rings round the fragments
    k = r_hole / 0.52
    gd = np.hypot(fu - 1.04, fv - 1.04)

    def chunk(cx, cy, rx, ry, crng, glow_seam, area=None):
        dx, dy = xs - cx, ys - cy
        ang = np.arctan2(dy, dx)
        wob = s_._wobble(ang, crng, 0.18, terms=3)
        n = 0.45 * (np.abs(dx) / rx + np.abs(dy) / ry) + 0.55 * np.hypot(dx / rx, dy / ry)
        rock = n <= 1 + wob
        if area is not None:
            rock &= area
        put(_nb4(rock), s_.CRATER_OUTLINE)
        put(rock, s_.ROCK)
        above = np.zeros_like(rock)
        above[1:] = rock[:-1]
        put(rock & ~above, s_.ROCK_LIGHT)
        put(rock & (dx > rx * 0.3) & (dy > -ry * 0.2), s_.ROCK_DARK)
        below = np.zeros_like(rock)
        below[:-1] = rock[1:]
        put(rock & ~below, s_.ROCK_DARK)
        if glow_seam:
            seam = rock & (np.abs(dy - (dx * 0.5)) < 0.6) & (np.abs(dx) < rx - 1)
            put(_nb4(seam) & rock, s_.GLOW_HALO)
            put(seam, s_.GLOW)

    cx, cy = s_.to_px(1, 1)
    cy += depth_px
    for (ox, oy, rx, ry, g) in ((-6, -1, 4.2, 2.6, True), (4, 0, 3.6, 2.4, True), (0, 2, 2.6, 1.8, False)):
        chunk(cx + int(round(ox * k)), cy + oy, rx * k, ry, np.random.default_rng(seed + ox * 7 + oy), g,
              area=floor)
    # (v3) the floor's glow drawn round the fragments (on bare floor only), brighter, with a hot core
    bare = floor & np.all(img[..., :3] == s_.FLOOR, axis=-1)
    put(bare & (gd < 0.30 * k), s_.GLOW_DEEP)
    put(bare & (gd < 0.21 * k), s_.GLOW_HALO)
    put(bare & (gd < 0.13 * k), s_.GLOW_MID)
    put(bare & (gd < 0.07 * k), s_.GLOW)
    img[cy, cx - 1] = [*s_.GLOW_CORE, 255]
    img[cy, cx] = [*s_.GLOW_CORE, 255]
    img[cy + 1, cx + 1] = [*s_.GLOW_CORE, 255]

    # the rim: broken, lifted asphalt slabs, far to near; far slabs face the light (two bright greys and a
    # lighter lit edge), near slabs a step darker; each has a shaded lower row
    cuts = np.sort((np.arange(n_slabs) + rng.uniform(0.2, 0.8, n_slabs)) / n_slabs * 2 * np.pi - np.pi)
    slabs = []
    for i in range(n_slabs):
        a0, a1 = cuts[i], cuts[(i + 1) % n_slabs] + (2 * np.pi if i == n_slabs - 1 else 0)
        mid = (a0 + a1) / 2
        sm = np.cos(mid) + np.sin(mid)
        near = sm > 0.5
        # (v3) chunkier: wider plates, lifted further so each shows a dark underside
        lift = int(rng.choice([0, 1, 1])) if near else int(rng.choice([1, 2, 2, 3]))
        width = rng.uniform(0.06, 0.09) if near else rng.uniform(0.12, 0.22)
        tilt = rng.uniform(-0.03, 0.03) if near else rng.uniform(-0.08, 0.08)
        gap = rng.uniform(0.04, 0.15) * 10 / n_slabs
        miss = rng.random() < missing
        slabs.append((sm, a0, a1, lift, width, tilt, int(rng.integers(0, 2)), gap, miss))
    rim = np.zeros_like(hole)
    slab_rng = np.random.default_rng(seed + 1)
    for (sm, a0, a1, lift, width, tilt, tone, gap, miss) in sorted(slabs):
        if miss:
            continue
        # (v4) a brighter lit edge on both sides, and a second lit row under it on the far side
        if sm < 0.3:
            fills, edge, edge2, low = (s_.SLAB_HI, s_.SLAB_TOP), SLAB_GLINT, SLAB_LIGHT, s_.SLAB_MID
        else:
            fills, edge, edge2, low = (s_.SLAB_MID, s_.SLAB_TOP), SLAB_LIGHT, None, s_.ASPH_LIT
        lu, lv = s_.ground_uv(xs, ys, lift=lift)
        ld, la = np.hypot(lu - 1, lv - 1), np.arctan2(lv - 1, lu - 1)
        rel = np.mod(la - a0, 2 * np.pi)
        span = np.mod(a1 - a0, 2 * np.pi)
        lr_in = r_hole + _wobble_safe(la, np.random.default_rng(seed + 1), rim_wobble)
        r_out = lr_in + 0.02 + width + tilt * (rel / max(span, 1e-6) - 0.5) * 2
        top = (rel > gap) & (rel < span - gap * 0.7) & (ld >= lr_in - 0.03) & (ld < r_out)
        face = np.zeros_like(top)
        for j in range(1, lift + 1):
            sh = np.zeros_like(top)
            sh[j:] = top[:-j]
            face |= sh
        face &= ~top
        # (v3) the underside in two steps: dark face, near-black foot; the top in three: lit edge, fill, shaded
        # lower row; grit sparse, no scorch speckle on the top (it read as scribble)
        put(face, s_.SCORCH_DEEP)                            # (v4) a darker underside
        fb = np.zeros_like(face)
        fb[:-1] = face[1:]
        put(face & ~fb, s_.CRATER_OUTLINE)
        put(top, fills[tone])
        above = np.zeros_like(top)
        above[1:] = top[:-1]
        below = np.zeros_like(top)
        below[:-1] = top[1:]
        put(top & ~below & above, low)                       # the shaded lower row
        if edge2 is not None:
            above2 = np.zeros_like(top)
            above2[2:] = top[:-2]
            put(top & above & ~above2 & below, edge2)        # the second lit row
        put(top & ~above, edge)                              # the lit upper edge
        put(top & above & below & (noise < 0.03), low)       # grit
        rim |= top | face
    del slab_rng

    # the outline where the rim drops into the hole: near-black all round the lip, 2 px on the near side,
    # broken on the far side by lit chips
    open_hole = hole & ~rim
    lip = open_hole & _nb4(~open_hole)
    put(lip, s_.CRATER_OUTLINE)
    lip2 = open_hole & _nb4(lip) & ~lip & (s > 0.15)
    lip2[1:] &= lip[:-1]
    put(lip2, s_.CRATER_OUTLINE)
    put(lip & (s <= -0.35) & (xs % 4 == 1), SLAB_LIGHT)
    put(lip & (s > -0.35) & (s < 0.0) & (xs % 6 == 3), s_.SLAB_TOP)
    # (v4) the near rim's inner edge catches light: a lit lower lip over the near-black drop
    put(rim & _nb4(open_hole) & (s > 0.15) & ~_nb4(~(rim | open_hole)), SLAB_LIGHT)
    outer = ~hole & ~rim & _nb4(rim) & (d > r_in) & (s > 0.1)
    put(outer, s_.CRATER_OUTLINE)

    # asphalt rubble in the scorch
    rrng = np.random.default_rng(seed + 5)
    for _ in range(18):
        ra = rrng.uniform(-np.pi, np.pi)
        rr = r_hole + 0.15 + rrng.uniform(0.0, 0.14)
        x, y = s_.to_px(1 + rr * np.cos(ra), 1 + rr * np.sin(ra))
        w = int(rrng.integers(1, 4))
        if 0 <= y < H - 1 and 0 <= x and x + w < W and not rim[y, x:x + w].any() \
                and not hole[y:y + 2, x:x + w].any() and d[y, x] < 0.95:
            img[y, x:x + w] = [*rrng.choice([s_.SLAB_MID, s_.SLAB_HI, s_.SLAB_TOP]), 255]
            img[y + 1, x:x + w] = [*s_.CRATER_OUTLINE, 255]

    # meteor chunks thrown on the rim and the scorch
    crng = np.random.default_rng(seed + 9)
    for (dr, rx, ry, g) in ((0.07, 3.0, 1.9, True), (0.17, 2.4, 1.6, False)):
        ca = crng.uniform(-np.pi, np.pi)
        px, py = s_.to_px(1 + (r_hole + dr) * np.cos(ca), 1 + (r_hole + dr) * np.sin(ca))
        chunk(px, py, rx, ry, np.random.default_rng(seed + int(ca * 100) + 300), g)

    # glowing cracks running from inside the lip across the rim into the scorch: a bright core (2 px wide
    # near the lip), a halo of two stepped darker purples all along it, no blur
    paths = []

    def walk(ang, r, r_end, step_a=0.25, dr=0.04, da=0.0):
        pts = [s_.to_px(1 + r * np.cos(ang), 1 + r * np.sin(ang))]
        while r < r_end:
            ang += rng.uniform(-step_a, step_a) + da
            r += dr
            pts.append(s_.to_px(1 + r * np.cos(ang), 1 + r * np.sin(ang)))
        return pts, ang, r

    base_angles = np.linspace(-np.pi, np.pi, n_cracks, endpoint=False) + rng.uniform(0, 2 * np.pi / n_cracks)
    # (v4) shorter cracks that start down in the far wall (or at the near lip) and run out across the slabs;
    # the ringed look's arcs are short, so no loop reads as a wreath
    for ang0 in base_angles + rng.uniform(-0.3, 0.3, n_cracks):
        far = np.cos(ang0) + np.sin(ang0) < 0
        r0 = float(r_hole) - (0.16 if far else 0.04)
        if cracks == "radial":
            pts, _, _ = walk(ang0, r0, r_hole + 0.22 + rng.uniform(0, 0.08))
            paths.append(pts)
        elif cracks == "ringed":
            pts, ang, r = walk(ang0, r0, r_hole + 0.13)
            arc_dir = rng.choice([-1, 1])
            arc = [pts[-1]]
            for _ in range(int(rng.integers(3, 6))):
                ang += arc_dir * 0.09
                r += rng.uniform(-0.01, 0.015)
                arc.append(s_.to_px(1 + r * np.cos(ang), 1 + r * np.sin(ang)))
            paths.append(pts + arc[1:])
        else:   # branching
            pts, ang, r = walk(ang0, r0, r_hole + 0.14)
            paths.append(pts)
            for side_ in (-1, 1):
                br, _, _ = walk(ang, r, r + 0.10 + rng.uniform(0, 0.06), step_a=0.12, da=side_ * 0.12)
                paths.append(br)

    cores = []
    for pts in paths:
        path = []
        for p0, p1 in zip(pts, pts[1:]):
            for p in _line(p0, p1):
                if (not path or path[-1] != p) and 0 <= p[0] < W and 0 <= p[1] < H and not floor[p[1], p[0]] \
                        and d[p[1], p[0]] < 0.96:
                    path.append(p)
        cores.append(path)
    # (v4) thickness varies: every other crack has a 2 px core on its first 40%, the others are 1 px
    thick = [0.4 if j % 2 == 0 else 0.0 for j in range(len(cores))]
    core_all = np.zeros_like(hole)
    for j, path in enumerate(cores):
        n = len(path)
        for i, (x, y) in enumerate(path):
            core_all[y, x] = True
            if i < n * thick[j] and x + 1 < W and not floor[y, x + 1]:
                core_all[y, x + 1] = True
    # (v3) the halo's outer step 8-connected, so it is 1-2 px wide all round; hot white-pink pixels spaced
    # along each crack's bright part, as on the boulder
    halo1 = _nb4(core_all) & ~floor
    inner = core_all | halo1
    p = np.pad(inner, 1)
    near8 = np.zeros_like(inner)
    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            near8 |= p[1 + oy:1 + oy + H, 1 + ox:1 + ox + W]
    halo2 = near8 & ~inner & ~floor
    put(halo2, s_.GLOW_DEEP)
    put(halo1, s_.GLOW_HALO)
    for j, path in enumerate(cores):
        n = len(path)
        for i, (x, y) in enumerate(path):
            hot = i < 3 or (i < n * 0.6 and i % 5 == 0)
            c = s_.GLOW_CORE if hot else s_.GLOW if i < n * 0.7 else s_.GLOW_MID
            img[y, x] = [*c, 255]
            if i < n * thick[j] and x + 1 < W and not floor[y, x + 1]:
                img[y, x + 1] = [*(s_.GLOW if i < 3 else s_.GLOW_MID), 255]

    # inside the tile's diamond only
    u0, v0 = s_.ground_uv(xs, ys)
    img[~((u0 >= 0) & (u0 < 2) & (v0 >= 0) & (v0 < 2))] = 0
    return img


def _wobble_safe(a, rng, amp):
    """sample._wobble, amplitude `amp` (0 gives a perfect circle, still drawing from rng in the same order)."""
    return sample._wobble(a, rng, amp)


def build_craters():
    out, images = [], {}
    for n, look in enumerate(CRATER_LOOKS, start=1):
        name = "crater_%d" % n
        images[name] = draw_crater(**look)
        out.append({"id": "crater-%d" % n, "label": "piece_meteor_crater",
                    "footprint_units": list(CRATER_FOOT), "texture": "res://art/craters/%s.png" % name})
    record = {
        "about": "T-398: the level creator's meteor craters (Level design, Decisions, \"Sidewalks and parked "
                 "cars in the level creator\", Meteor craters): ground decals the car drives over, no crash. "
                 "Placeholders drawn by game/tools/build_street_pieces.py from T-397's approved crater; T-399 "
                 "swaps the art by changing the textures here and the PNGs. The footprint is a square of "
                 "whole ground cells; the texture is its diamond (128 x 64 art px per 2 x 2 units, drawn at "
                 "draw_scale). Do not edit by hand.",
        "draw_scale": 0.5, "craters": out}
    return images, record


def dump(obj) -> str:
    return json.dumps(obj, indent=1) + "\n"


def build():
    sheet, record = build_sheet()
    SHEET_PNG.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(sheet, "RGBA").save(SHEET_PNG)
    SHEET_JSON.write_text(dump(record), encoding="utf-8", newline="\n")
    images, crec = build_craters()
    CRATER_DIR.mkdir(parents=True, exist_ok=True)
    for name, img in images.items():
        Image.fromarray(img, "RGBA").save(CRATER_DIR / (name + ".png"))
    CRATERS_JSON.write_text(dump(crec), encoding="utf-8", newline="\n")
    print("Wrote %d sidewalk tiles and %d craters" % (len(record["tiles"]), len(images)))


def rules(arr: np.ndarray) -> list[str]:
    problems = []
    a = arr[..., 3]
    if not np.all((a == 0) | (a == 255)):
        problems.append("alpha is not 0 or 255")
    colours = {tuple(int(v) for v in c[:3]) for c in arr[a == 255]}
    if len(colours) > MAX_COLORS:
        problems.append("%d colours (at most %d)" % (len(colours), MAX_COLORS))
    reds = [c for c in colours if c[0] >= RED_MIN and max(c[1], c[2]) <= RED_MAX_OTHER and c[0] - max(c[1], c[2]) >= RED_OVER]
    if reds:
        problems.append("%d old-brand red colours" % len(reds))
    return problems


def check() -> int:
    ok = True
    sheet, record = build_sheet()
    if not SHEET_PNG.exists() or not np.array_equal(np.array(Image.open(SHEET_PNG).convert("RGBA")), sheet):
        print("FAIL  %s differs from a fresh build" % SHEET_PNG.name)
        ok = False
    if not SHEET_JSON.exists() or SHEET_JSON.read_text(encoding="utf-8") != dump(record):
        print("FAIL  %s differs from a fresh build" % SHEET_JSON.name)
        ok = False
    for t in record["tiles"]:
        x, y, w, h = t["region"]
        for p in rules(sheet[y:y + h, x:x + w]):
            print("FAIL  %s: %s" % (t["name"], p))
            ok = False
    images, crec = build_craters()
    for name, img in images.items():
        png = CRATER_DIR / (name + ".png")
        if not png.exists() or not np.array_equal(np.array(Image.open(png).convert("RGBA")), img):
            print("FAIL  %s differs from a fresh build" % png.name)
            ok = False
        for p in rules(img):
            print("FAIL  %s: %s" % (name, p))
            ok = False
    if not CRATERS_JSON.exists() or CRATERS_JSON.read_text(encoding="utf-8") != dump(crec):
        print("FAIL  craters.json differs from a fresh build")
        ok = False
    print("OK" if ok else "FAILED")
    return 0 if ok else 1


# --- T-399: versions and previews for the style loop ---

def crater_strip() -> np.ndarray:
    """The crater looks as one row of 128 x 64 frames, in CRATER_LOOKS order (the style loop's version)."""
    images, _ = build_craters()
    return np.concatenate([images["crater_%d" % n] for n in range(1, len(CRATER_LOOKS) + 1)], axis=1)


PREVIEW_ROADS = (5, 6)


def preview_map(size=12, roads=PREVIEW_ROADS):
    """A small map: a road along y at columns `roads` and one along x at rows `roads`, sidewalk two cells deep
    along both, gravel beyond. {(cx, cy): "road" | "sidewalk" | "gravel"}."""
    cells = {}
    for cx in range(size):
        for cy in range(size):
            if cx in roads or cy in roads:
                cells[(cx, cy)] = "road"
            elif min(abs(cx - r) for r in roads) <= 2 or min(abs(cy - r) for r in roads) <= 2:
                cells[(cx, cy)] = "sidewalk"
            else:
                cells[(cx, cy)] = "gravel"
    return cells


def curb_name(cells, cx, cy) -> str:
    """The tile a sidewalk cell gets, by the rule in the module docstring (sidewalk_curbs.gd's)."""
    def road(x, y):
        return cells.get((x, y)) == "road"
    near = {"n": road(cx, cy - 1), "e": road(cx + 1, cy), "s": road(cx, cy + 1), "w": road(cx - 1, cy)}
    edges = "".join(e for e in EDGES if near[e])
    diag = {"ne": (1, -1), "se": (1, 1), "sw": (-1, 1), "nw": (-1, -1)}
    corners = [c for c in CORNERS
               if not near[c[0]] and not near[c[1]] and road(cx + diag[c][0], cy + diag[c][1])]
    return tile_name(edges, corners)


def compose_sidewalks(sheet: np.ndarray, record: dict, bg, cells=None) -> Image.Image:
    cells = cells or preview_map()
    size = max(c[0] for c in cells) + 1
    tiles = {t["name"]: t["region"] for t in record["tiles"]}
    W, H = size * 128 + 64, size * 64 + 64
    ox, oy = W // 2, 32
    canvas = Image.new("RGBA", (W, H), (*bg, 255))
    sheet_im = Image.fromarray(sheet, "RGBA")
    road_y, road_x = sample.ground_tile("y_plain_a0"), sample.ground_tile("x_plain_a0")
    gravel = sample.ground_tile("gravel0")
    for (cx, cy) in sorted(cells, key=lambda c: (c[0] + c[1], c[0])):
        kind = cells[(cx, cy)]
        if kind == "road":
            tile = road_y if cx in PREVIEW_ROADS else road_x
        elif kind == "gravel":
            tile = gravel
        else:
            x, y, w, h = tiles[curb_name(cells, cx, cy)]
            tile = sheet_im.crop((x, y, x + w, y + h))
        px, py = sample.screen(2 * cx, 2 * cy, ox, oy)
        canvas.alpha_composite(tile, (px - TILE_W // 2, py))
    return canvas


def preview_sidewalks(sheet_png, out_dir) -> Path:
    """The sheet's tiles on a crossroads (straights, outer and inner corners), dark and light, 2x, plus 6x
    close-ups of the crossing's four corners."""
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    sheet = sample.load_rgba(sheet_png)
    _, record = build_sheet()
    dark = compose_sidewalks(sheet, record, (20, 20, 30))
    light = compose_sidewalks(sheet, record, (225, 225, 230))
    both = Image.new("RGBA", (dark.width * 2 + 16, dark.height), (128, 128, 128, 255))
    both.alpha_composite(dark, (0, 0))
    both.alpha_composite(light, (dark.width + 16, 0))
    sample.enlarge(both, 2).save(out_dir / "preview_side_by_side.png")
    ox, oy = dark.width // 2, 32
    for name, (cx, cy) in {"corner_n": (4, 4), "corner_s": (7, 7), "corner_w": (4, 7), "corner_e": (7, 4)}.items():
        px, py = sample.screen(2 * cx + 1, 2 * cy + 1, ox, oy)
        sample.enlarge(dark.crop((px - 150, py - 75, px + 150, py + 75)), 6).save(out_dir / ("zoom_%s.png" % name))
    return out_dir / "preview_side_by_side.png"


def preview_craters(strip_png, out_dir) -> Path:
    """Each crater look on asphalt, on sidewalk and on gravel, next to a boulder; dark and light, 4x."""
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    strip = sample.load_rgba(strip_png)
    n = strip.shape[1] // TILE_W
    grounds = [sample.ground_tile("y_plain_a0"), Image.fromarray(sample.draw_sidewalk(curb=False), "RGBA"),
               sample.ground_tile("gravel0")]
    bo = Image.open(sample.REPO / "game/art/boulders/boulder_a.png").convert("RGBA")
    bo = bo.resize((bo.width // 2, bo.height // 2), Image.NEAREST)
    out = []
    for bg in ((20, 20, 30), (225, 225, 230)):
        im = Image.new("RGBA", (3 * (TILE_W + 8) + bo.width + 16, max(n * (TILE_H + 8) + 8, bo.height + 16)), (*bg, 255))
        for k in range(n):
            cr = Image.fromarray(strip[:, k * TILE_W:(k + 1) * TILE_W].copy(), "RGBA")
            for g, ground in enumerate(grounds):
                at = (g * (TILE_W + 8), 8 + k * (TILE_H + 8))
                im.alpha_composite(ground, at)
                im.alpha_composite(cr, at)
        im.alpha_composite(bo, (3 * (TILE_W + 8) + 8, 8))
        out.append(sample.enlarge(im, 4))
    both = Image.new("RGBA", (out[0].width * 2 + 24, out[0].height), (128, 128, 128, 255))
    both.alpha_composite(out[0], (0, 0))
    both.alpha_composite(out[1], (out[0].width + 24, 0))
    both.save(out_dir / "preview_side_by_side.png")
    return out_dir / "preview_side_by_side.png"


def _arg(argv, flag):
    return argv[argv.index(flag) + 1] if flag in argv and argv.index(flag) + 1 < len(argv) else None


def main(argv=None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    cmd = argv[0] if argv else "build"
    if cmd == "build":
        build()
        return 0
    if cmd == "check":
        return check()
    if cmd == "sheet" and _arg(argv, "--out"):
        sheet, _ = build_sheet()
        Image.fromarray(sheet, "RGBA").save(_arg(argv, "--out"))
        return 0
    if cmd == "crater-strip" and _arg(argv, "--out"):
        Image.fromarray(crater_strip(), "RGBA").save(_arg(argv, "--out"))
        return 0
    if cmd == "preview-sidewalks" and _arg(argv, "--sheet") and _arg(argv, "--out-dir"):
        print(preview_sidewalks(_arg(argv, "--sheet"), _arg(argv, "--out-dir")))
        return 0
    if cmd == "preview-craters" and _arg(argv, "--strip") and _arg(argv, "--out-dir"):
        print(preview_craters(_arg(argv, "--strip"), _arg(argv, "--out-dir")))
        return 0
    print("usage: build_street_pieces.py build | check | sheet --out PNG | crater-strip --out PNG"
          " | preview-sidewalks --sheet PNG --out-dir DIR | preview-craters --strip PNG --out-dir DIR")
    return 2


if __name__ == "__main__":
    sys.exit(main())
