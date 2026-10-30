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
  python game/tools/build_sidewalk_car_sample.py crater --out <png> [--seed 397]
      Draws (free, no PixelLab) a meteor crater as a 128 x 64 ground decal (the road tile's diamond, transparent
      round the crater): a hole with its far inner wall showing, lifted broken asphalt round it, a dithered
      scorched band, glowing magenta cracks and meteor fragments on the floor (the boulders' own colours).
  python game/tools/build_sidewalk_car_sample.py preview --sidewalk <png> [--car <png>] [--crater <png>] --out-dir <folder>
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


# --- the meteor crater (added by the board, 2026-10-30): a flat ground decal the car drives over ---

# the road's asphalt (game/art/ground/road_tile.png) and the boulders' rock and glow (game/art/boulders/boulder_a.png)
ASPH, ASPH_DARK, ASPH_LIGHT, ASPH_LIT = (48, 46, 62), (41, 39, 54), (57, 55, 69), (73, 71, 85)
ASPH_HI, SCORCH, SCORCH_DEEP = (85, 84, 96), (30, 28, 40), (24, 23, 36)
EARTH, EARTH_DARK, FLOOR = (52, 50, 64), (38, 36, 50), (18, 16, 28)
EARTH_LIGHT, SLAB_HI = (74, 66, 88), (108, 106, 120)   # a lighter earth stratum; the lifted slabs' lit edges
WALL_LIT, SLAB_MID, SLAB_TOP = (92, 84, 104), (88, 87, 98), (98, 97, 108)   # lit wall stratum; grey slab tops
CRATER_OUTLINE = (15, 7, 22)
ROCK, ROCK_LIGHT, ROCK_DARK = (47, 47, 97), (57, 58, 107), (22, 4, 74)
GLOW_CORE, GLOW, GLOW_MID, GLOW_HALO, GLOW_DEEP = (251, 192, 247), (249, 22, 242), (173, 18, 177), (110, 2, 123), (64, 1, 94)


def _wobble(a, rng, amp, terms=4):
    """A smooth random wobble of an angle array (radians), amplitude about `amp`."""
    out = np.zeros_like(a)
    for k in range(1, terms + 1):
        out += np.sin(a * (k + 1) + rng.uniform(0, 2 * np.pi)) * amp / k
    return out


def to_px(u, v):
    """Ground point (units from the tile's top corner) to the tile's pixel."""
    return int(round(TILE_W / 2 + (u - v) * U - 0.5)), int(round((u + v) * U / 2 - 0.5))


def draw_crater(seed=397, depth_px=9, r_hole=0.52):
    """A meteor crater as a 128 x 64 ground decal (2 x 2 units, the road tiles' diamond; transparent round it):
    a hole whose far inner wall shows (the floor is drawn `depth_px` lower, so the near wall hides behind the
    rim), a ring of broken, lifted asphalt, a scorched band fading into the ground by dither, glowing cracks in
    the meteors' magenta running out over the ground, and meteor fragments glowing on the floor."""
    rng = np.random.default_rng(seed)
    ys, xs = np.mgrid[0:TILE_H, 0:TILE_W]
    u, v = ground_uv(xs, ys)
    du, dv = u - 1, v - 1
    d, a = np.hypot(du, dv), np.arctan2(dv, du)
    s = du + dv                                  # > 0 towards the viewer
    r_in = r_hole + _wobble(a, rng, 0.05)
    r_base = r_in + 0.12                         # where the slabs end and the scorch begins (smooth)
    img = np.zeros((TILE_H, TILE_W, 4), dtype=np.uint8)
    put = lambda m, c: img.__setitem__(m, [*c, 255])  # noqa: E731
    noise = rng.random(d.shape)

    def nb4(m):
        """Pixels 4-adjacent to mask m (not in it)."""
        p = np.pad(m, 1)
        return (p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]) & ~m

    # scorched ground: three solid stepped bands, darkest at the rim, with an uneven (not dithered) outer edge,
    # and a few solid scorch tongues reaching further out
    # (v4: narrower, so no soft dark skirt; each band's radius is quantised so its edge steps in hard runs)
    tongue = np.zeros_like(d)
    for _ in range(3):
        ta = rng.uniform(-np.pi, np.pi)
        tongue += 0.06 * np.exp(-((np.angle(np.exp(1j * (a - ta)))) / 0.2) ** 2)
    q = lambda r: np.round(r * 24) / 24  # noqa: E731
    put(d < q(r_base + 0.15 + _wobble(a, rng, 0.03, terms=5) + tongue), ASPH_DARK)
    put(d < q(r_base + 0.09 + _wobble(a, rng, 0.02) + tongue * 0.6), SCORCH)
    put(d < q(r_base + 0.04 + _wobble(a, rng, 0.015)), SCORCH_DEEP)

    # the hole: the floor (seen `depth_px` lower) where it shows, else the far inner wall
    hole = d < r_in
    fu, fv = ground_uv(xs, ys - depth_px)
    fd = np.hypot(fu - 1, fv - 1)
    fa = np.arctan2(fv - 1, fu - 1)
    floor = hole & (fd < r_hole - 0.12 + _wobble(fa, np.random.default_rng(seed), 0.05))
    wall = hole & ~floor
    rows = np.zeros(wall.shape, int)             # rows down from the wall's top edge
    for y in range(1, TILE_H):
        rows[y] = np.where(wall[y] & wall[y - 1], rows[y - 1] + 1, 0)
    # wall bands: the cut asphalt layer (lit), a dark seam, a lighter earth stratum, earth darkening downwards,
    # and the floor's glow reflected on the wall's foot
    # the far inner wall faces the viewer and the light: lit at the top, stepping down to dark at the floor
    # (v4) a pit, not a dome: only the cut asphalt at the top catches light; the earth below steps down into
    # shadow, darker towards both ends of the wall (it curves away), and the glow stays on the floor
    side = np.abs(du - dv) > 0.38                # the wall's two ends, turning away from the viewer
    put(wall, EARTH_DARK)
    put(wall & (rows <= 4) & ~side, EARTH)
    put(wall & (rows == 2) & ~side, EARTH_LIGHT)
    put(wall & (rows <= 1), ASPH)
    put(wall & (rows == 0), ASPH_LIT)
    put(wall & (rows >= 6), FLOOR)
    put(wall & (rows >= 2) & (rows <= 5) & (noise < 0.06), ROCK)            # meteor grit in the earth
    put(floor, FLOOR)

    # the glow, low on the floor only: small solid stepped rings round the fragments (no blur, no dither)
    gu, gv = ground_uv(xs, ys - depth_px)
    gd = np.hypot(gu - 1.04, gv - 1.04)
    put(floor & (gd < 0.27), GLOW_DEEP)
    put(floor & (gd < 0.18), GLOW_HALO)
    put(floor & (gd < 0.09), GLOW_MID)

    def chunk(cx, cy, rx, ry, crng, glow_seam, area=None):
        """An irregular, faceted rock chunk of the meteor (navy), outlined, lit on top, with a glowing seam."""
        dx, dy = xs - cx, ys - cy
        ang = np.arctan2(dy, dx)
        wob = _wobble(ang, crng, 0.18, terms=3)
        n = 0.45 * (np.abs(dx) / rx + np.abs(dy) / ry) + 0.55 * np.hypot(dx / rx, dy / ry)
        rock = n <= 1 + wob
        if area is not None:
            rock &= area
        ring = nb4(rock)
        put(ring, CRATER_OUTLINE)
        put(rock, ROCK)
        above = np.zeros_like(rock)
        above[1:] = rock[:-1]
        put(rock & ~above, ROCK_LIGHT)                                   # lit top facet
        put(rock & (dx > rx * 0.3) & (dy > -ry * 0.2), ROCK_DARK)        # shaded side
        below = np.zeros_like(rock)
        below[:-1] = rock[1:]
        put(rock & ~below, ROCK_DARK)
        if glow_seam:                                                    # a crack across it, glowing
            seam = rock & (np.abs(dy - (dx * 0.5)) < 0.6) & (np.abs(dx) < rx - 1)
            put(nb4(seam) & rock, GLOW_HALO)
            put(seam, GLOW)

    # meteor fragments on the floor: irregular navy chunks round the glowing middle
    cx, cy = to_px(1, 1)
    cy += depth_px
    for (ox, oy, rx, ry, g) in ((-6, -1, 4.2, 2.6, True), (4, 0, 3.6, 2.4, True), (0, 2, 2.6, 1.8, False)):
        chunk(cx + ox, cy + oy, rx, ry, np.random.default_rng(seed + ox * 7 + oy), g, area=floor)
    img[cy, cx - 1] = [*GLOW_CORE, 255]
    img[cy + 1, cx + 1] = [*GLOW_CORE, 255]

    # the rim: broken, angular asphalt slabs lifted at the hole's edge, drawn far to near; each slab has its own
    # lift (0-2 px), width and tone, a lit top edge, a dark front face, and a gap to its neighbours
    n_slabs = 10
    cuts = np.sort((np.arange(n_slabs) + rng.uniform(0.2, 0.8, n_slabs)) / n_slabs * 2 * np.pi - np.pi)
    slabs = []
    for k in range(n_slabs):
        a0, a1 = cuts[k], cuts[(k + 1) % n_slabs] + (2 * np.pi if k == n_slabs - 1 else 0)
        mid = (a0 + a1) / 2
        sm = np.cos(mid) + np.sin(mid)           # > 0 on the near side
        # (v4) varied, broken ring: far slabs vary from flat to lifted 2 px, wide or narrow, strongly tilted;
        # near slabs are thin and flat so the near rim stays low; some slabs are missing, leaving gaps
        near = sm > 0.5
        lift = 0 if near else int(rng.choice([0, 1, 1, 2]))
        width = rng.uniform(0.03, 0.06) if near else rng.uniform(0.06, 0.19)
        tilt = rng.uniform(-0.03, 0.03) if near else rng.uniform(-0.08, 0.08)
        gap = rng.uniform(0.04, 0.15)
        missing = rng.random() < 0.2
        slabs.append((sm, a0, a1, lift, width, tilt, int(rng.integers(0, 3)), gap, missing))
    rim = np.zeros_like(hole)
    for (_sm, a0, a1, lift, width, tilt, tone, gap, missing) in sorted(slabs):
        if missing:
            continue
        # grey broken asphalt: far slabs face the light (lighter), near slabs a step darker; two greys per side
        tones = (SLAB_TOP, SLAB_MID, ASPH_HI) if _sm < 0.3 else (ASPH_HI, ASPH_LIT, SLAB_MID)
        lu, lv = ground_uv(xs, ys, lift=lift)
        ld, la = np.hypot(lu - 1, lv - 1), np.arctan2(lv - 1, lu - 1)
        rel = np.mod(la - a0, 2 * np.pi)
        span = np.mod(a1 - a0, 2 * np.pi)
        lr_in = r_hole + _wobble(la, np.random.default_rng(seed + 1), 0.05)
        # straight-edged outer side: radius changes linearly across the slab (a tilted, broken plate)
        r_out = lr_in + 0.02 + width + tilt * (rel / max(span, 1e-6) - 0.5) * 2
        top = (rel > gap) & (rel < span - gap * 0.7) & (ld >= lr_in - 0.03) & (ld < r_out)
        face = np.zeros_like(top)
        for k in range(1, lift + 1):
            sh = np.zeros_like(top)
            sh[k:] = top[:-k]
            face |= sh
        face &= ~top
        put(face, ASPH_DARK)
        fb = np.zeros_like(face)
        fb[:-1] = face[1:]
        put(face & ~fb, CRATER_OUTLINE)          # the face's foot, where the slab sits on the ground
        put(top, tones[tone])
        above = np.zeros_like(top)
        above[1:] = top[:-1]
        put(top & ~above, SLAB_HI if lift else ASPH_HI)   # lit upper edge
        put(top & (noise < 0.06), ASPH_LIT)      # grit
        put(top & (ld < lr_in + 0.035), SCORCH)  # the scorched band on the slab's inner edge, between slab and pit
        put(top & (ld < lr_in + 0.035) & (noise < 0.3), SCORCH_DEEP)
        rim |= top | face

    # the outline: near-black where the rim drops into the hole, all round the lip; on the far side, under the
    # wall's lit cut edge, a 1-pixel dark line so the lip still separates
    # (v4) the whole hole's edge, slabs or gaps, gets the near-black line; on the near side it is 2 px, the drop
    # under the near rim; on the far slabs it is broken by lit chips
    open_hole = hole & ~rim
    lip = open_hole & nb4(~open_hole)
    put(lip, CRATER_OUTLINE)
    lip2 = open_hole & nb4(lip) & ~lip & (s > 0.15)
    lip2[1:] &= lip[:-1]                         # the second row only straight under the first
    put(lip2, CRATER_OUTLINE)
    put(lip & (s <= -0.35) & (xs % 5 == 1), SLAB_HI)
    put(lip & (s > -0.35) & (s < 0.0) & (xs % 7 == 3), ASPH_LIT)
    # the rim's outer edge on the near half, so the slabs stand off the scorched ground
    outer = ~hole & ~rim & nb4(rim) & (d > r_in) & (s > 0.1)
    put(outer, CRATER_OUTLINE)

    # (v4) asphalt rubble in the scorch round the rim: small grey chips, lit top, near-black foot
    rrng = np.random.default_rng(seed + 5)
    for _ in range(14):
        ra = rrng.uniform(-np.pi, np.pi)
        rr = r_hole + 0.13 + rrng.uniform(0.0, 0.12)
        x, y = to_px(1 + rr * np.cos(ra), 1 + rr * np.sin(ra))
        w = int(rrng.integers(1, 4))
        if 0 <= y < TILE_H - 1 and 0 <= x and x + w < TILE_W and not rim[y, x:x + w].any() and not hole[y:y + 2, x:x + w].any():
            img[y, x:x + w] = [*rrng.choice([SLAB_MID, ASPH_HI, SLAB_TOP]), 255]
            img[y + 1, x:x + w] = [*CRATER_OUTLINE, 255]

    # meteor chunks thrown on the rim and the scorched ground (the boulders' navy rock)
    for (cu, cv, rx, ry, g) in ((0.42, 0.95, 3.0, 1.9, True), (1.62, 1.25, 2.4, 1.6, False)):   # sparse
        px, py = to_px(cu, cv)
        chunk(px, py, rx, ry, np.random.default_rng(seed + int(cu * 100)), g)

    # glowing cracks: a few connected fissures running from inside the lip, across the rim, into the scorch;
    # a bright core with a stepped halo of darker purples (no blur)
    def line(p0, p1):
        (x0, y0), (x1, y1) = p0, p1
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        return [(int(round(x0 + (x1 - x0) * i / n)), int(round(y0 + (y1 - y0) * i / n))) for i in range(n + 1)]

    # (v4) short: each starts in the lip and stops just past the rim slabs, in the scorch
    for ang0, length in ((-2.6, 0.1), (2.35, 0.12), (0.15, 0.13), (-0.95, 0.08)):
        ang, r = ang0, float(r_hole) - 0.04
        pts = [to_px(1 + r * np.cos(ang), 1 + r * np.sin(ang))]
        while r < r_hole + 0.12 + length:
            ang += rng.uniform(-0.25, 0.25)
            r += 0.04
            pts.append(to_px(1 + r * np.cos(ang), 1 + r * np.sin(ang)))
        path = []
        for p0, p1 in zip(pts, pts[1:]):
            for p in line(p0, p1):
                if (not path or path[-1] != p) and 0 <= p[0] < TILE_W and 0 <= p[1] < TILE_H and not floor[p[1], p[0]]:
                    path.append(p)
        core = np.zeros_like(hole)
        for x, y in path:
            core[y, x] = True
        n = len(path)
        head = np.zeros_like(hole)
        for x, y in path[: max(3, int(n * 0.45))]:
            head[y, x] = True
        halo = nb4(core)
        put(nb4(core | halo) & nb4(head | nb4(head)) & ~halo & ~floor, GLOW_DEEP)   # second step, near the rim
        put(halo & ~floor, GLOW_HALO)
        for i, (x, y) in enumerate(path):
            img[y, x] = [*(GLOW_CORE if i < 2 else GLOW if i < n * 0.65 else GLOW_MID), 255]

    # keep it inside the tile's diamond
    u0, v0 = ground_uv(xs, ys)
    img[~((u0 >= 0) & (u0 < 2) & (v0 >= 0) & (v0 < 2))] = 0
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


def compose(sidewalk, car, bg, crater=None):
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
    # the meteor crater, a ground decal, on the road tile at u in [6, 8), v in [6, 8)
    if crater is not None:
        x, y = screen(6, 6, ox, oy)
        canvas.alpha_composite(Image.fromarray(crater, "RGBA"), (x - TILE_W // 2, y))
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


def preview(sidewalk_png, car_png, out_dir, crater_png=None):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    side = load_rgba(sidewalk_png)
    car = load_rgba(car_png) if car_png else np.zeros((8, 8, 4), np.uint8)
    crater = load_rgba(crater_png) if crater_png else None
    dark = enlarge(compose(side, car, (20, 20, 30), crater))
    light = enlarge(compose(side, car, (225, 225, 230), crater))
    dark.save(out_dir / "preview_dark.png")
    light.save(out_dir / "preview_light.png")
    both = Image.new("RGBA", (dark.width * 2 + 24, dark.height), (128, 128, 128, 255))
    both.alpha_composite(dark, (0, 0))
    both.alpha_composite(light, (dark.width + 24, 0))
    both.save(out_dir / "preview_side_by_side.png")
    # a close-up of one curb tile's edge against the road (curb tile i = 1, j = 2), 8x, so the curb can be judged
    base = compose(side, car, (20, 20, 30), crater)
    enlarge(base.crop((330, 296, 470, 386)), 8).save(out_dir / "preview_curb_zoom.png")
    # and the tile's own curb corner on its own, 10x, on the dark background
    tile = Image.new("RGBA", (72, 40), (20, 20, 30, 255))
    tile.alpha_composite(Image.fromarray(side, "RGBA").crop((56, 24, 128, 64)))
    enlarge(tile, 10).save(out_dir / "tile_curb_zoom.png")
    if crater is not None:   # the crater on the road and on the sidewalk, 6x, so it can be judged up close
        road = ground_tile("y_plain_a0")
        walk = Image.fromarray(draw_sidewalk(curb=False), "RGBA")
        cr = Image.fromarray(crater, "RGBA")
        strip = Image.new("RGBA", (TILE_W * 3 + 16, TILE_H), (20, 20, 30, 255))
        for n, ground in enumerate((road, walk, None)):
            if ground is not None:
                strip.alpha_composite(ground, (n * (TILE_W + 8), 0))
            strip.alpha_composite(cr, (n * (TILE_W + 8), 0))
        enlarge(strip, 6).save(out_dir / "crater_zoom.png")
    return out_dir / "preview_side_by_side.png"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("sidewalk")
    s.add_argument("--out", required=True)
    s.add_argument("--curb-px", type=int, default=3)
    s.add_argument("--seed", type=int, default=397)
    k = sub.add_parser("crater")
    k.add_argument("--out", required=True)
    k.add_argument("--seed", type=int, default=397)
    c = sub.add_parser("car")
    c.add_argument("--raw", required=True)
    c.add_argument("--out", required=True)
    c.add_argument("--mirror", action="store_true")
    c.add_argument("--max-colors", type=int, default=30)
    p = sub.add_parser("preview")
    p.add_argument("--sidewalk", required=True)
    p.add_argument("--crater", help="the crater PNG (optional)")
    p.add_argument("--car", help="the car PNG; left out, the preview has no car")
    p.add_argument("--out-dir", required=True)
    a = ap.parse_args(argv)
    if a.cmd == "sidewalk":
        img = draw_sidewalk(a.curb_px, a.seed)
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(img, "RGBA").save(a.out)
        print(f"{a.out}: {len(colours(img))} colours")
    elif a.cmd == "crater":
        img = draw_crater(a.seed)
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(img, "RGBA").save(a.out)
        print(f"{a.out}: {len(colours(img))} colours")
    elif a.cmd == "car":
        img = clean_car(a.raw, a.mirror, a.max_colors)
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(img, "RGBA").save(a.out)
        print(f"{a.out}: {len(colours(img))} colours, bbox {Image.fromarray(img).getbbox()}")
    else:
        print(preview(a.sidewalk, a.car, a.out_dir, a.crater))
    return 0


if __name__ == "__main__":
    sys.exit(main())
