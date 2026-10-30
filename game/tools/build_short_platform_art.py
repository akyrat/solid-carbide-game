#!/usr/bin/env python3
"""The short buildings' platform art (T-405; Level design, Decisions, "Short buildings become platforms").

  python game/tools/build_short_platform_art.py            # writes game/art/buildings/platforms/
  python game/tools/build_short_platform_art.py --check    # checks the files there are what it would write

The low-rise (T-129's 8 short bodies) and the creator's small and long buildings (T-257's 6 textures) become
platforms 3 units high. No PixelLab: every image here is cut from today's art by script, pixel for pixel
(only whole-pixel moves, never resampled).

For each source texture it writes four images of the same size and anchor, a box that fills the building's whole
footprint and stands 3 units high (96 art px of wall instead of 134 or 138):

- `<stem>.png`        the platform as it stands alone: roof with its parapet on every edge, the two front walls.
- `<stem>_clean.png`  the roof with no parapet on any edge (and no walls): drawn under everything else.
- `<stem>_ns.png`     the roof with only the north and south parapets (the west and east ones taken out).
- `<stem>_ew.png`     the roof with only the west and east parapets.

At run time (elevation_platform_drawing.gd, building mode) the roof is drawn from `_clean`, then each edge's
parapet only where nothing at the platform's height stands across that edge (from `_ns` or `_ew`, so a parapet
never shows a piece of the one across the corner), the full corner where both edges are open, and the front walls
only where open. Two platforms side by side (or one beside a 3-high rooftop) so join with no wall or edge between.

How the box is cut from the source:
- walls: a band of rows is taken out of each wall (the rows under the top lip), so the walls are 3 units high and
  keep their ground floor and their lip;
- the creator's buildings stand half a unit inside their footprint (a pavement round them): their box is widened
  to the whole footprint by repeating one unit in the middle of each side (the roof and each wall), and the
  pavement is left out;
- the parapets (half a unit wide, plus the outline) are taken out by reading the roof one unit further in;
- the rooftop props (tanks, AC units, signs...) are never cut: the art is built again without them from the
  PixelLab pieces in art-archive (T-129, T-257; the rebuild must equal today's file, checked), the box is cut from
  that, and the props' own pixels are put back whole on the lowered, widened roof.

The record `platforms.json` lists, per source texture path, the four images, their footprint and the anchor (the
art pixel on the footprint's front corner, the bottom centre for the low-rise). Same input, same pixels.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

REPO = Path(__file__).resolve().parents[2]
GAME = REPO / "game"
OUT_DIR = GAME / "art" / "buildings" / "platforms"
RECORD_NAME = "platforms.json"
SKYSCRAPERS = GAME / "art" / "buildings" / "skyscrapers.json"
CREATOR_BUILDINGS = GAME / "data" / "level" / "creator_buildings.json"

U = 32              # art px per unit across (16 px down per unit along x or y)
HEIGHT_UNITS = 3
WALL = HEIGHT_UNITS * U   # 96 rows of wall
KEEP_TOP = 3        # rows kept at the top of each wall (the lit lip and the dark line under it)
EDGE = 1.0          # units of roof replaced at an edge to take its parapet out (the parapet is 0.5 wide)
LIP = 0.15          # units outside a back edge where the lit lip line lies (kept or taken out with its parapet)
CREATOR_MARGIN = 0.5  # the creator's buildings stand this far inside their footprint
VARIANTS = {"": (False, False, True), "_clean": (True, True, False), "_ns": (True, False, False), "_ew": (False, True, False)}


def res_to_path(res: str) -> Path:
    return GAME / res.replace("res://", "")


# ---- The sources, built again with and without their rooftop props ------------------------------------------

def _t129_bodies(with_props: bool) -> list:
    """build_short_set.py build_all's steps: [(body, wall rows)] in body order."""
    import build_short_buildings as sb
    import build_short_set as bss
    import build_skyscrapers as bs
    raw = REPO / "art-archive" / "T-129" / "raw"
    pal = bs.load_palette()

    def ld(n):
        return bss.load(raw, n)

    props = {"tank": sb.clean_prop(ld("a_prop_tank"), pal), "ac": sb.clean_prop(ld("a_prop_ac"), pal, polygon=bss.KEEP_AC),
             "rubble": sb.clean_prop(ld("a_prop_rubble"), pal, polygon=bss.KEEP_RUBBLE, drop=bss.LILAC),
             "sign": sb.clean_prop(ld("b_prop_signboard"), pal), "antenna": sb.clean_prop(ld("b_prop_antenna"), pal),
             "dish": sb.clean_prop(ld("c_prop_dish"), pal, polygon=bss.KEEP_DISH)}
    out = []
    for d, (lk, rk) in bss.DESIGNS.items():
        fl, fr = bss.facade(raw, lk, pal), bss.facade(raw, rk, pal)
        placed = []
        for name in (bss.ROOF_LOADS[d] if with_props else []):
            base = name.rstrip("23")
            spr = props["rubble"] if (base == "rubble" and name.endswith("3")) else props[base]
            placed.append((spr[:, ::-1].copy() if name.endswith("2") else spr, bss.PLACES[name]))
        old = sb.build_body(fl, fr, pal, placed, seed=7 + ord(d), cracks=90 if d == "d" else 40)
        for look in (0, 1):
            arr = old if look == 0 else bs.recolor_pink_cyan(old)[:, ::-1].copy()
            out.append((sb.recolor_b(arr), fl.shape[0]))
    return out


def _creator_bodies(with_props: bool) -> dict:
    """build_creator_buildings_art.py build_all's steps: texture path -> (image, wall rows)."""
    import build_creator_buildings as bcb
    import build_creator_buildings_art as bca
    import build_short_buildings as sb
    import build_skyscrapers as bs
    raw = REPO / "art-archive" / "T-257" / "raw"
    pal = bs.load_palette()
    plan = bca.texture_plan(bca.load_props(pal))
    out = {}
    for n, (p, t) in enumerate(bcb.textures(bcb.load())):
        stem = Path(t["texture"]).stem
        w, h = t["footprint_units"]
        size, _anchor = bcb.expected_anchor(w, h, p["height_units"])
        up = round(p["height_units"] * U)
        lf, rf, pr = plan[stem]
        fl = bca.clean(raw, lf, pal, round((w - 2 * CREATOR_MARGIN) * U))
        fr = bca.clean(raw, rf, pal, round((h - 2 * CREATOR_MARGIN) * U))
        body = sb.recolor_b(bca.build_body(size, w, h, up, fl, fr, pr if with_props else [], pal, seed=257 + n))
        img = bs.to_img(bca.draw_pavement(size, w, h, up, seed=2570 + n))
        img.alpha_composite(bs.to_img(body))
        out[t["texture"]] = (np.array(img), fl.shape[0])
    return out


def sources() -> list:
    """[(res path, footprint (A, B), source box (a, b), the box's front ground corner in art px, wall rows,
    the art as it is, the art without its rooftop props)]. The rebuilt art must equal the game's file."""
    out = []
    sky = json.loads(SKYSCRAPERS.read_text(encoding="utf-8"))
    full, bare = _t129_bodies(True), _t129_bodies(False)
    for k, res in enumerate(sky["short"]["bodies"]):
        art = np.array(Image.open(res_to_path(res)).convert("RGBA"))
        assert np.array_equal(art, full[k][0]), "rebuilt %s differs from the game's file" % res
        h, w = art.shape[:2]
        out.append((res, (12, 12), (12, 12), (w / 2.0, float(h)), full[k][1], art, bare[k][0]))
    data = json.loads(CREATOR_BUILDINGS.read_text(encoding="utf-8"))
    cfull, cbare = _creator_bodies(True), _creator_bodies(False)
    for p in data["pieces"]:
        for t in p["textures"]:
            res = t["texture"]
            art = np.array(Image.open(res_to_path(res)).convert("RGBA"))
            assert np.array_equal(art, cfull[res][0]), "rebuilt %s differs from the game's file" % res
            fw, fh = (int(v) for v in t["footprint_units"])
            ax, ay = (float(v) for v in t["anchor_art_px"])
            # The building's front ground corner is half a unit in from the footprint's: (-0.5, -0.5) on the ground.
            out.append((res, (fw, fh), (fw - 2 * CREATOR_MARGIN, fh - 2 * CREATOR_MARGIN),
                        (ax, ay - 2 * CREATOR_MARGIN * U / 2), cfull[res][1], art, cbare[res][0]))
    return out


# ---- Cutting the box ------------------------------------------------------------------------------------------

def stretch(t, big, small):
    """Box coordinate t in [0, big] of the target -> the source's [0, small]: one unit repeated in the middle."""
    extra = big - small
    m = np.floor(big / 2.0)
    return np.where(t < m, t, t - extra)


def inward(t, size, on):
    """Takes the parapet out along one axis: the EDGE units at each end read the roof EDGE units further in."""
    if not on:
        return t
    return np.where(t < EDGE, t + EDGE, np.where(t > size - EDGE, t - EDGE, t))


def top_rows(box, corner, wall_rows) -> int:
    """Rows the source has above its roof's back corner (the props' tops)."""
    a, b = box
    return max(0, int(np.ceil(corner[1] - wall_rows - (a + b) * U / 2)))


def render(src: np.ndarray, footprint, box, corner, wall_rows: int, strip_x: bool, strip_y: bool, walls: bool) -> tuple:
    """The target image (and its anchor) from a source without props; strip_x / strip_y take out the parapets
    across x (the west and east edges) / across y (the north and south edges); walls False leaves the walls out."""
    A, B = footprint
    a, b = box
    cx, cy = corner
    width = int((A + B) * U)
    height = int((A + B) * U / 2) + WALL + top_rows(box, corner, wall_rows)
    ax, ay = A * U, height                                # the footprint's front corner
    ys, xs = np.mgrid[0:height, 0:width]
    u = xs + 0.5 - ax
    v = ys + 0.5 - ay
    out = np.zeros((height, width, 4), dtype=np.uint8)
    sh, sw = src.shape[:2]

    def sample(mask, sx, sy):
        ix = np.floor(sx).astype(int)
        iy = np.floor(sy).astype(int)
        ok = mask & (ix >= 0) & (ix < sw) & (iy >= 0) & (iy < sh)
        out[ok] = src[iy[ok], ix[ok]]

    # The roof plane, WALL rows up: box coordinates (X, Y) of every pixel.
    dX = (u / U + (v + WALL) / (U / 2)) / 2
    dY = ((v + WALL) / (U / 2) - u / U) / 2
    X, Y = A + dX, B + dY
    roof = (X >= 0) & (X < A) & (Y >= 0) & (Y < B)
    # Just outside the back edges: the lit lip line, kept with its parapet.
    lip = ~roof & ((((X < 0) & (X >= -LIP) & (Y >= 0) & (Y < B)) & (not strip_x))
                   | (((Y < 0) & (Y >= -LIP) & (X >= 0) & (X < A)) & (not strip_y)))
    xr = stretch(inward(np.clip(X, -LIP, A), A, strip_x), A, a)
    yr = stretch(inward(np.clip(Y, -LIP, B), B, strip_y), B, b)
    sample(roof | lip, cx + ((xr - a) - (yr - b)) * U, cy + ((xr - a) + (yr - b)) * U / 2 - wall_rows)

    if walls:
        def z_src(z):  # rows up the wall: the top KEEP_TOP rows stay at the top, the band under them goes
            return np.where(z < WALL - KEEP_TOP, z, z + (wall_rows - WALL))

        # South wall (y = B, left of the front corner): along x.
        dx = u / U
        z = dx * (U / 2) - v
        south = ~roof & (u < 0) & (dx >= -A) & (z >= 0) & (z < WALL)
        xw = stretch(A + dx, A, a)
        sample(south, cx + (xw - a) * U, cy + (xw - a) * U / 2 - z_src(z))
        # East wall (x = A, right of the front corner): along y.
        dy = -u / U
        z = dy * (U / 2) - v
        east = ~roof & (u >= 0) & (dy >= -B) & (z >= 0) & (z < WALL)
        yw = stretch(B + dy, B, b)
        sample(east, cx - (yw - b) * U, cy + (yw - b) * U / 2 - z_src(z))
    return out, (ax, ay)


def props_offset(anchor, footprint, box, corner, wall_rows) -> tuple:
    """How far (art px) the props move: centred on the widened roof and down with the lowered roof."""
    A, B = footprint
    a, b = box
    ox = anchor[0] - corner[0] - ((A - a) / 2 - (B - b) / 2) * U
    oy = anchor[1] - corner[1] - ((A - a) / 2 + (B - b) / 2) * U / 2 - WALL + wall_rows
    return int(round(ox)), int(round(oy))


def paste_props(img: np.ndarray, anchor, art: np.ndarray, bare: np.ndarray, footprint, box, corner, wall_rows) -> int:
    """Puts the rooftop props (the art's pixels the art without props lacks) back whole; returns how many pixels."""
    mask = (art != bare).any(-1) & (art[..., 3] > 0)
    ox, oy = props_offset(anchor, footprint, box, corner, wall_rows)
    ys, xs = np.nonzero(mask)
    tx, ty = xs + ox, ys + oy
    ok = (tx >= 0) & (tx < img.shape[1]) & (ty >= 0) & (ty < img.shape[0])
    img[ty[ok], tx[ok]] = art[ys[ok], xs[ok]]
    return int(ok.sum())


def build(out_dir: Path = OUT_DIR) -> dict:
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    record = {"about": "T-405: the short buildings as platforms 3 units high, cut by game/tools/build_short_platform_art.py "
                       "from their art (no PixelLab). Per source texture: the four images (full: standing alone; clean: "
                       "the roof with no parapet; ns: only the north and south parapets; ew: only the west and east ones), "
                       "the footprint in units and the anchor (the art pixel on the footprint's front corner).",
              "height_units": HEIGHT_UNITS, "edge_units": EDGE, "lip_units": LIP, "art_px_per_unit": U, "textures": {}}
    for res, footprint, box, corner, wall_rows, art, bare in sources():
        stem = Path(res).stem
        files = {}
        anchor = None
        for suffix, (sx, sy, walls) in VARIANTS.items():
            img, anchor = render(bare, footprint, box, corner, wall_rows, sx, sy, walls)
            paste_props(img, anchor, art, bare, footprint, box, corner, wall_rows)
            Image.fromarray(img, "RGBA").save(out_dir / f"{stem}{suffix}.png")
            files[suffix.lstrip("_") or "full"] = f"res://art/buildings/platforms/{stem}{suffix}.png"
        record["textures"][res] = {**files, "footprint_units": list(footprint), "anchor_art_px": list(anchor)}
    (out_dir / RECORD_NAME).write_text(json.dumps(record, indent=1) + "\n", encoding="utf-8")
    return record


def check(out_dir: Path = OUT_DIR) -> list:
    """Problems: files missing or different from what build() writes now."""
    import tempfile
    problems = []
    with tempfile.TemporaryDirectory() as tmp:
        build(Path(tmp))
        for f in sorted(Path(tmp).iterdir()):
            mine = Path(out_dir) / f.name
            if not mine.exists():
                problems.append(f"missing: {mine}")
            elif f.suffix == ".png":
                if not np.array_equal(np.array(Image.open(f)), np.array(Image.open(mine).convert("RGBA"))):
                    problems.append(f"differs: {mine}")
            elif f.read_text(encoding="utf-8") != mine.read_text(encoding="utf-8"):
                problems.append(f"differs: {mine}")
    return problems


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out-dir", default=str(OUT_DIR))
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args(argv)
    if a.check:
        problems = check(Path(a.out_dir))
        for p in problems:
            print(p)
        print("OK" if not problems else "%d problems" % len(problems))
        return 1 if problems else 0
    rec = build(Path(a.out_dir))
    print("wrote %d textures x %d images to %s" % (len(rec["textures"]), len(VARIANTS), a.out_dir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
