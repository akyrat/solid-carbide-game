#!/usr/bin/env python3
"""Draws Bricks' impact wave (task T-325; no PixelLab call).

Weapons, Decisions, "Bricks" (board, 2026-10-28): each landing after a jump sends an
impact wave out around the car. The art (T-325's description): a ring on the ground with
dust and brick chips, in the City's colours (Visual style, Decisions, "City colours":
cool blue-grey, pale white and pale blue), never Greenbull's, in the pixel rules
(Visual style, Content, "Rules"): hard pixel edges, every pixel opaque or transparent,
a dark selective outline, at most 30 colours.

One one-row sheet of FRAMES stepped frames per damage radius the tiers use (read from
game/data/weapons.json), so the ring is drawn at its final size at every tier and is
never scaled: 32 art pixels per unit, shown at 0.5 in the run (rule 3). The ground
circle of radius r is drawn as the run's isometric ellipse (run.gd ISO_TRANSFORM,
doubled to art pixels). The timing matches bricks.gd's BricksWave: FRAME_SECONDS a
frame, the ring easing out from START_RADIUS to the radius in RING_SECONDS, then
thinning and crumbling away; dust puffs kicked up behind the ring grow, rise and
shrink; brick chips hop out and drop. Nothing fades: pixels appear or go.

Commands (from the repo root):
  python game/tools/build_bricks_wave.py build                  # every radius into game/art/weapons/
  python game/tools/build_bricks_wave.py build --radius 4 --out X.png   # one sheet (style loop versions)
  python game/tools/build_bricks_wave.py check                  # checks the committed sheets
  python game/tools/build_bricks_wave.py preview --png X.png --out Y.png  # enlarged, dark and light ground

Running build twice gives byte-identical files.
"""
from __future__ import annotations

import argparse
import json
import math
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_rules as rules  # noqa: E402
from remove_car_shadow import write_png  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
REPO = GAME.parent
OUT_DIR = GAME / "art" / "weapons"
WEAPONS_JSON = GAME / "data" / "weapons.json"

ART_PX = 32            # art pixels per unit (rule 3)
FRAMES = 12
FRAME_SECONDS = 0.05   # bricks.gd BricksWave.FRAME_SECONDS
RING_SECONDS = 0.35    # bricks.gd BricksWave.RING_SECONDS
START_RADIUS = 0.6     # bricks.gd BricksWave.START_RADIUS
MARGIN = 10            # art px round the ring
TOP = 44               # art px above the ring for rising dust and hopping chips

# The City's colours (steel and glass, cool blue-grey), dust greys, brick browns.
OUTLINE = (20, 24, 40)
RING_WHITE = (250, 252, 255)   # the glowing core (rule 5: the glow is bright pixels)
RING_GLOW = (204, 226, 248)    # pale blue, the halo's first step
RING_PALE = (176, 200, 228)
RING_MID = (126, 148, 182)
RING_GREY = (88, 104, 134)
RING_DARK = (58, 70, 98)
DUST_WHITE = (216, 222, 230)
DUST_LIGHT = (180, 188, 200)
DUST_MID = (140, 148, 164)
DUST_DARK = (102, 110, 128)
# Dull, dark brick browns (not orange or amber, so the chips never read as fire).
BRICK_TOP = (170, 122, 102)
BRICK_LIGHT = (140, 94, 78)
BRICK = (112, 70, 60)
BRICK_DARK = (78, 48, 46)
COLOURS = [OUTLINE, RING_WHITE, RING_GLOW, RING_PALE, RING_MID, RING_GREY, RING_DARK, DUST_WHITE,
           DUST_LIGHT, DUST_MID, DUST_DARK, BRICK_TOP, BRICK_LIGHT, BRICK, BRICK_DARK]
# One shade darker on the far half of the ring (the side away from the viewer); the
# white core stays white all round, so the glow reads on both halves.
FAR = {RING_GLOW: RING_PALE, RING_PALE: RING_MID, RING_MID: RING_GREY, RING_GREY: RING_DARK}

PUFFS = 14
CHIPS = 24
SEGMENTS = 30          # the ring breaks into this many pieces as it crumbles
# Per frame after the ring stops (index = frames since it reached the radius).
AFTER_WIDTH = [0.26, 0.23, 0.21, 0.19, 0.18]   # band width, units
AFTER_GAP = [0.0, 0.16, 0.32, 0.48, 0.62]      # share of each piece broken away
AFTER_HALO = [2, 2, 1, 0, 0]                   # halo steps still shown
HALO_1 = 0.13          # units: the first, denser halo step's width
HALO_2 = 0.24          # units: where the second, sparser step ends
SEED = 325


# --- radii and names -------------------------------------------------------------

def tier_radii(path=WEAPONS_JSON):
    """Every damage radius Bricks' tiers 1 to 8 reach (weapons.json `bricks`: the base
    radius times each `radius_multiplier` up to the tier), rounded to 0.01, ascending."""
    b = json.loads(Path(path).read_text(encoding="utf-8"))["bricks"]
    r, out = float(b["radius"]), set()
    out.add(round(r, 2))
    for t in sorted(b.get("tiers", []), key=lambda t: t["tier"]):
        if t.get("effect") == "radius_multiplier":
            r *= float(t["value"])
        out.add(round(r, 2))
    return sorted(out)


def sheet_name(radius):
    """bricks_wave_r4_0, bricks_wave_r7_8, ... (the game finds a sheet by this name)."""
    return "bricks_wave_r" + ("%.1f" % radius).replace(".", "_")


def frame_size(radius):
    hw = math.ceil(radius * math.sqrt(2) * ART_PX) + MARGIN
    hh = math.ceil(radius * math.sqrt(2) * ART_PX / 2) + MARGIN
    return 2 * hw, TOP + 2 * hh, (hw, TOP + hh)


# --- timing (bricks.gd BricksWave) ---------------------------------------------------

def ring_radius(f, radius):
    t = min(f * FRAME_SECONDS / RING_SECONDS, 1.0)
    e = 1.0 - (1.0 - t) * (1.0 - t)
    return START_RADIUS + (radius - START_RADIUS) * e


def ground_dist(x, y):
    """Ground distance (units) of art pixel offset (x, y) from the centre (inverse iso)."""
    a, b = x / ART_PX, y / (ART_PX / 2)
    return math.sqrt((a * a + b * b) / 2.0)


def iso(u, v):
    return (u - v) * ART_PX, (u + v) * ART_PX / 2


def _hash(x, y, f):
    return ((x * 73856093) ^ (y * 19349663) ^ (f * 83492791)) & 1023


# --- drawing -------------------------------------------------------------------------

def draw_frame(f, radius, rnd_puffs, rnd_chips):
    w, h, (cx, cy) = frame_size(radius)
    px = [[None] * w for _ in range(h)]
    life = (f + 0.5) / FRAMES
    travelling = f * FRAME_SECONDS < RING_SECONDS - 1e-9
    after = 0 if travelling else f - round(RING_SECONDS / FRAME_SECONDS)   # frames since the ring stopped
    rr = ring_radius(f, radius)
    a_i = min(after, len(AFTER_WIDTH) - 1)
    bw = 0.34 if travelling else AFTER_WIDTH[a_i]
    core = 0.15 if travelling else 0.11          # the white leading edge, units (3 px at the ellipse's ends)
    gap = 0.0 if travelling else AFTER_GAP[a_i]
    halo_steps = 2 if travelling else AFTER_HALO[a_i]

    def piece(x, y):
        """(segment, place in it 0..1) of art pixel offset (x, y) round the ring."""
        a, b = x / ART_PX, y / (ART_PX / 2)
        th = math.atan2((b - a) / 2, (a + b) / 2) + math.pi
        t = th / math.tau * SEGMENTS
        seg = int(t) % SEGMENTS
        return seg, t - int(t)

    def broken(x, y):
        if gap <= 0:
            return False
        seg, p = piece(x, y)
        g = gap * (0.55 + 0.9 * (_hash(seg, 7, 1) / 1023.0))
        return p < min(g, 0.95)

    def band(r_out, width, inner_only_grey=False):
        hw = int(r_out * math.sqrt(2) * ART_PX) + 2
        hh = int(r_out * math.sqrt(2) * ART_PX / 2) + 2
        for y in range(max(0, cy - hh), min(h, cy + hh + 1)):
            for x in range(max(0, cx - hw), min(w, cx + hw + 1)):
                d = ground_dist(x - cx, y - cy)
                if not (r_out - width <= d <= r_out):
                    continue
                if broken(x - cx, y - cy):
                    continue
                s = (d - (r_out - width)) / width
                if inner_only_grey:
                    c = RING_GREY
                elif r_out - d <= core:
                    c = RING_WHITE
                elif s > 0.55:
                    c = RING_PALE if travelling else RING_GLOW
                elif s > 0.25:
                    c = RING_PALE
                else:
                    c = RING_MID
                if y < cy:
                    c = FAR.get(c, c)
                px[y][x] = c

    band(rr, bw)
    if travelling and rr > START_RADIUS + 0.5:
        band(rr * 0.7, 0.07, inner_only_grey=True)
    _outline(px)
    # A second navy pixel on the ring's outer edge, so the white core stands off any ground.
    add = []
    for y in range(max(1, cy - int(rr * 23) - 4), min(h - 1, cy + int(rr * 23) + 5)):
        for x in range(1, w - 1):
            if px[y][x] is None and OUTLINE in (px[y][x - 1], px[y][x + 1], px[y - 1][x], px[y + 1][x]):
                if ground_dist(x - cx, y - cy) > rr:
                    add.append((x, y))
    for x, y in add:
        px[y][x] = OUTLINE
    # The glow's halo: checker-dithered steps just outside and inside the ring, no blur
    # (rule 5). The first step is pale blue on a checker, the second a sparser darker blue.
    if halo_steps:
        limit = radius + (MARGIN - 1) / (math.sqrt(2) * ART_PX)   # the halo stays inside the frame
        hw = int((rr + HALO_2) * math.sqrt(2) * ART_PX) + 2
        hh = int((rr + HALO_2) * math.sqrt(2) * ART_PX / 2) + 2
        for y in range(max(0, cy - hh), min(h, cy + hh + 1)):
            for x in range(max(0, cx - hw), min(w, cx + hw + 1)):
                if px[y][x] is not None or broken(x - cx, y - cy):
                    continue
                d = ground_dist(x - cx, y - cy)
                if d > limit:
                    continue
                out_d = d - rr                 # outside the ring's leading edge
                in_d = (rr - bw) - d           # inside its trailing edge
                c = None
                # Darker blues than the white core, so core and halo read as two things.
                if 0 < out_d <= HALO_1 and (x + y) % 2 == 0:
                    c = RING_MID
                elif halo_steps > 1 and HALO_1 < out_d <= HALO_2 and x % 2 == 0 and y % 2 == 0:
                    c = RING_GREY
                elif 0 < in_d <= HALO_1 and (x + y) % 2 == 0:
                    c = RING_MID
                elif halo_steps > 1 and HALO_1 < in_d <= HALO_2 and x % 2 == 0 and y % 2 == 0:
                    c = RING_GREY
                if c is not None:
                    px[y][x] = FAR.get(c, c) if y < cy else c
    # Pieces of the ring falling away into the gaps as it crumbles.
    if gap > 0:
        for seg in range(SEGMENTS):
            if _hash(seg, 11, 3) < 200:
                continue
            th = (seg + 0.5 * gap) / SEGMENTS * math.tau - math.pi
            u, v = math.cos(th) * rr, math.sin(th) * rr
            gx, gy = iso(u, v)
            drop = 1 + after * 2
            _fragment(px, int(round(cx + gx)), int(round(cy + gy + drop)), False)
    # Dust and chips, far ones first so the near ones cover them.
    sprites = []
    for p in rnd_puffs:
        sprites.append(("puff", p))
    for c in rnd_chips:
        sprites.append(("chip", c))
    placed = []
    for kind, s in sprites:
        u, v = math.cos(s["a"]), math.sin(s["a"])
        if kind == "puff":
            d = s["frac"] * min(rr, radius)
            gx, gy = iso(u * d, v * d)
            grow = min(life / 0.3, 1.0) if life < 0.3 else max(0.0, 1.0 - (life - 0.3) / 0.7)
            r = s["size"] * grow
            if r < 1.5:
                continue
            placed.append((gy, kind, (cx + gx + s["dx"], cy + gy - life * s["rise"]), r, s))
        else:
            if life >= 0.86:
                continue
            l = life / 0.86
            d = s["frac"] * radius * l
            gx, gy = iso(u * d, v * d)
            hop = s["hop"] * 4.0 * l * (1.0 - l)
            placed.append((gy, kind, (cx + gx, cy + gy - hop), 0, s))
    placed.sort(key=lambda t: t[0])
    for _, kind, (x, y), r, s in placed:
        if kind == "puff":
            _puff(px, x, y, r, s)
        else:
            _chip(px, int(round(x)), int(round(y)), (s["spin"] + f) % 4, s["small"])
    return px


def _outline(px, colour=OUTLINE):
    h, w = len(px), len(px[0])
    add = []
    for y in range(h):
        row = px[y]
        for x in range(w):
            if row[x] is None:
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if 0 <= nx < w and 0 <= ny < h and px[ny][nx] not in (None, colour):
                        add.append((x, y))
                        break
    for x, y in add:
        px[y][x] = colour


def _puff(px, x, y, r, s):
    """A dust cloud: five lumps with ragged, stepped edges (each lump's radius jumps
    from one angle step to the next), five shade steps lit from the top left, a navy
    outline broken by light dust on the lit side, and loose specks round it."""
    h, w = len(px), len(px[0])
    seed = int(s["a"] * 1000) & 1023
    # A wide, low cloud of uneven lumps (wider than tall, so it reads as kicked-up dust,
    # not a ball): small wisps out to the sides and on top.
    lumps = [(0.0, 0.0, r * 0.8), (-r * 0.85, r * 0.25, r * 0.55), (r * 0.9, r * 0.2, r * 0.6),
             (-r * 1.45, r * 0.45, r * 0.32), (r * 1.5, r * 0.4, r * 0.3),
             (-r * 0.45, -r * 0.45, r * 0.5), (r * 0.5, -r * 0.4, r * 0.45)]
    cells = {}
    for li, (lx, ly, lr) in enumerate(lumps):
        for yy in range(int(y + ly - lr) - 2, int(y + ly + lr) + 3):
            for xx in range(int(x + lx - lr * 1.3) - 2, int(x + lx + lr * 1.3) + 3):
                dx, dy = (xx + 0.5 - (x + lx)) / 1.3, yy + 0.5 - (y + ly)
                step = int((math.atan2(dy, dx) + math.pi) / math.tau * 7) % 7
                rag = 0.55 + 0.6 * (_hash(step, li, seed) / 1023.0)   # stepped, ragged edge
                if dx * dx + dy * dy <= (lr * rag) ** 2:
                    cells[(xx, yy)] = True
    for (xx, yy) in cells:
        k = (0.6 * (xx + 0.5 - x) / 1.3 + 1.4 * (yy + 0.5 - y)) / r
        if k < -0.75:
            cells[(xx, yy)] = DUST_WHITE
        elif k < -0.25:
            cells[(xx, yy)] = DUST_LIGHT
        elif k < 0.1:
            cells[(xx, yy)] = DUST_MID
        elif k < 0.3:
            # dithered step into the underside's shadow
            cells[(xx, yy)] = DUST_DARK if (xx + yy) % 2 else DUST_MID
        elif k < 0.55:
            cells[(xx, yy)] = DUST_DARK
        elif k < 0.75:
            cells[(xx, yy)] = RING_DARK if (xx + yy) % 2 else DUST_DARK
        else:
            cells[(xx, yy)] = RING_DARK
    # One bright highlight pixel pair on each billow's lit top-left.
    for lx, ly, lr in lumps[:3] + lumps[5:]:
        hx, hy = int(x + lx - lr * 0.45), int(y + ly - lr * 0.45)
        for p in ((hx, hy), (hx + 1, hy)):
            if p in cells:
                cells[p] = RING_WHITE
    edge = set()
    for (xx, yy) in cells:
        for nx, ny in ((xx - 1, yy), (xx + 1, yy), (xx, yy - 1), (xx, yy + 1)):
            if (nx, ny) not in cells:
                edge.add((nx, ny))
    for (xx, yy) in edge:
        if 0 <= xx < w and 0 <= yy < h:
            # Selective outline: the lit top-left edge breaks it with light dust pixels.
            lit = (xx - x) + (yy - y) < -r * 0.5
            px[yy][xx] = (DUST_LIGHT if (xx + yy) % 2 == 0 else DUST_WHITE) if lit else OUTLINE
    for (xx, yy), c in cells.items():
        if 0 <= xx < w and 0 <= yy < h:
            px[yy][xx] = c
    # Loose specks of dust round the cloud (2 x 1 and single pixels).
    for i in range(5):
        a = (_hash(i, seed, 5) / 1023.0) * math.tau
        dd = r * (1.25 + 0.4 * (_hash(i, seed, 9) / 1023.0))
        sx, sy = int(round(x + math.cos(a) * dd)), int(round(y + math.sin(a) * dd * 0.8))
        for ox in ((0, 1) if i % 2 == 0 else (0,)):
            if 0 <= sx + ox < w and 0 <= sy < h and px[sy][sx + ox] is None:
                px[sy][sx + ox] = DUST_LIGHT if i % 3 else DUST_MID


FRAGMENT = [".WWG", "WWGP", "GPPM", ".MM."]
FRAGMENT_SMALL = ["WG", "PM"]
FRAGMENT_COLOURS = {"W": RING_WHITE, "G": RING_GLOW, "P": RING_PALE, "M": RING_MID}


def _fragment(px, x, y, small):
    """A piece of the ring falling away as it crumbles, outlined in navy."""
    _stamp(px, x, y, FRAGMENT_SMALL if small else FRAGMENT, FRAGMENT_COLOURS)


def _stamp(px, x, y, shape, colours):
    h, w = len(px), len(px[0])
    sh, sw = len(shape), len(shape[0])
    x0, y0 = x - sw // 2, y - sh // 2
    cells = {(x0 + i, y0 + j): colours[ch] for j, row in enumerate(shape)
             for i, ch in enumerate(row) if ch != "."}
    for (xx, yy) in list(cells):
        for nx, ny in ((xx - 1, yy), (xx + 1, yy), (xx, yy - 1), (xx, yy + 1)):
            if (nx, ny) not in cells and 0 <= nx < w and 0 <= ny < h:
                px[ny][nx] = OUTLINE
    for (xx, yy), c in cells.items():
        if 0 <= xx < w and 0 <= yy < h:
            px[yy][xx] = c


# Brick chips: T is the lit top face, L the front face, B the side, D the shadow edge.
# H is the one bright highlight pixel on the top face's lit corner.
CHIP_SHAPES = [
    ["...HTTTT", "..TTTTTL", ".TTTTTLB", "LLLLLLBD", "BBBBBBBD", "DDDDDDD."],   # flat
    ["...HT...", "..TTTL..", ".TTTLBB.", "TTLLBBBD", ".LLBBBD.", "..BBDD..", "...D...."],   # turned
    ["HTTL", "TTLB", "LLBB", "LLBD", "LLBD", "LBBD", "BBDD", "DD.."],   # on end
    ["HTTTT...", "LTTTTTT.", "BLLTTTTL", ".BBLLLBD", "..BBBBBD", "...DDDD."],   # turned the other way
]
CHIP_SMALL = [
    [".HTT", "TTLB", "LLBD", "BBD."],
    ["HTT.", "LTTB", "LLBD", ".BD."],
    ["HT", "TL", "LB", "BD"],
    ["HTTL", "LLBD", "BBD."],
]
CHIP_COLOURS = {"H": RING_WHITE, "T": BRICK_TOP, "L": BRICK_LIGHT, "B": BRICK, "D": BRICK_DARK}


def _chip(px, x, y, phase, small=False):
    """A tumbling brick chip: one of four turns, lit top face, outlined in the dark navy."""
    _stamp(px, x, y, (CHIP_SMALL if small else CHIP_SHAPES)[phase], CHIP_COLOURS)


def scatter():
    """The puffs and chips (the same pattern at every radius, scaled with it)."""
    rnd = random.Random(SEED)
    puffs = []
    for i in range(PUFFS):
        puffs.append({"a": math.tau * (i + rnd.uniform(-0.3, 0.3)) / PUFFS, "frac": rnd.uniform(0.55, 0.95),
                      "size": rnd.uniform(8.0, 12.0), "rise": rnd.uniform(14.0, 26.0), "dx": rnd.uniform(-2, 2)})
    chips = []
    for i in range(CHIPS):
        chips.append({"a": math.tau * (i + rnd.uniform(-0.4, 0.4)) / CHIPS, "frac": rnd.uniform(0.3, 0.85),
                      "hop": rnd.uniform(16.0, 36.0), "spin": rnd.randrange(4), "small": i % 3 == 2})
    return puffs, chips


def build_sheet(radius):
    """The sheet's rows (RGBA tuples) and its record."""
    w, h, centre = frame_size(radius)
    puffs, chips = scatter()
    frames = [draw_frame(f, radius, puffs, chips) for f in range(FRAMES)]
    clear = (0, 0, 0, 0)
    rows = []
    for y in range(h):
        row = []
        for fr in frames:
            row.extend(clear if c is None else c + (255,) for c in fr[y])
        rows.append(row)
    record = {
        "file": sheet_name(radius) + ".png",
        "task": "T-325",
        "generator": "game/tools/build_bricks_wave.py (script-drawn, no PixelLab)",
        "radius_units": radius,
        "frames": FRAMES,
        "frame_width": w,
        "frame_height": h,
        "centre": list(centre),
        "frame_seconds": FRAME_SECONDS,
        "ring_seconds": RING_SECONDS,
        "start_radius_units": START_RADIUS,
        "art_px_per_unit": ART_PX,
        "draw_scale": 0.5,
        "resources_consulted": ["docs/visual-style.md", "docs/weapons.md", "docs/extended-narrative.md",
                                "game/scripts/weapons/bricks.gd"],
    }
    return rows, record


def write_sheet(radius, out_png):
    rows, record = build_sheet(radius)
    out_png = Path(out_png)
    out_png.parent.mkdir(parents=True, exist_ok=True)
    write_png(out_png, rows)
    out_png.with_suffix(".json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    return rows, record


def check_rows(rows, record):
    """Rule checks on one sheet: [(name, ok, detail)]."""
    out = []
    w, h = record["frame_width"] * record["frames"], record["frame_height"]
    out.append(("sheet size", len(rows) == h and len(rows[0]) == w, "%dx%d" % (len(rows[0]), len(rows))))
    alphas = {p[3] for r in rows for p in r}
    out.append(("opaque or transparent", alphas <= {0, 255}, str(sorted(alphas))))
    cols = {p[:3] for r in rows for p in r if p[3] == 255}
    out.append(("at most 30 colours", len(cols) <= 30, "%d colours" % len(cols)))
    gb = [c for c in cols if rules.greenbull_colour(c)]
    out.append(("none of Greenbull's colours", not gb, str(gb)))
    corners = [rows[0][0][3], rows[-1][-1][3]]
    out.append(("transparent background", corners == [0, 0], str(corners)))
    return out


def preview(png, out, scale=2, frames=None):
    """The sheet enlarged (nearest neighbour), on the asphalt's dark grey above and a light grey below.
    frames: (first, last) to show only those frames (a close-up)."""
    from PIL import Image
    im = Image.open(png).convert("RGBA")
    if frames:
        fw = im.size[0] // FRAMES
        im = im.crop((frames[0] * fw, 0, (frames[1] + 1) * fw, im.size[1]))
    w, h = im.size
    canvas = Image.new("RGBA", (w, h * 2), (40, 42, 52, 255))
    canvas.paste((206, 210, 218, 255), (0, h, w, h * 2))
    canvas.alpha_composite(im, (0, 0))
    canvas.alpha_composite(im, (0, h))
    canvas = canvas.resize((w * scale, h * 2 * scale), Image.NEAREST)
    canvas.convert("RGB").save(out)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("--radius", type=float)
    b.add_argument("--out")
    sub.add_parser("check")
    p = sub.add_parser("preview")
    p.add_argument("--png", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--scale", type=int, default=2)
    p.add_argument("--frames", help="first-last frame to show, e.g. 3-5 (a close-up)")
    a = ap.parse_args(argv)
    if a.cmd == "build":
        if a.radius is not None or a.out:
            if a.radius is None or not a.out:
                ap.error("--radius and --out go together")
            write_sheet(a.radius, a.out)
            print("wrote", a.out)
            return 0
        for r in tier_radii():
            path = OUT_DIR / (sheet_name(r) + ".png")
            write_sheet(r, path)
            print("wrote", path.relative_to(REPO).as_posix())
        return 0
    if a.cmd == "preview":
        fr = tuple(int(v) for v in a.frames.split("-")) if a.frames else None
        preview(a.png, a.out, a.scale, fr)
        return 0
    bad = 0
    for r in tier_radii():
        path = OUT_DIR / (sheet_name(r) + ".png")
        if not path.is_file():
            print("missing", path)
            bad += 1
            continue
        _, _, rows = rules.decode_png(path.read_bytes())
        record = json.loads(path.with_suffix(".json").read_text(encoding="utf-8"))
        for name, ok, detail in check_rows(rows, record):
            print("%s %s: %s (%s)" % ("ok  " if ok else "FAIL", path.name, name, detail))
            bad += 0 if ok else 1
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
