"""The hint pieces' circular arrow (task T-577; Level design, Decisions, "Hint pieces in the level creator").

The circular arrow (hint_arrow_circular.png) is a flat top-down road-marking arrow, 64 x 64 px, bent into nearly
a full circle going CLOCKWISE on screen (steer round), with a clear gap at the top right and a triangular head at
the top pointing right into the gap. The engine mirrors it for anticlockwise (game/docs/level/hint-pieces.md,
"The art"), so the picture is always clockwise. It shares the straight and curved arrows' look
(build_hint_arrow.py, build_hint_arrow_curved.py, the curved arrow's kept "clean" pass): blush #f6c9de body, a
near-white edge line and a rim light on the lit edges, stepped darker shade with a cool plum deepest step on the
edges away from the light, a two-pixel near-black selective outline whose inner ring is never broken and whose
outer ring carries short near-white highlight runs where the light comes from (Visual style, Content, "Rules",
rule 2). This script does the free parts of the style loop around one PixelLab call per version:

    python game/tools/build_hint_arrow_circular.py init OUT.png
        Draws the script arrow: the init image PixelLab starts from, and a fallback on its own.
    python game/tools/build_hint_arrow_circular.py request OUT.json --init INIT.png [--strength N] [--seed N]
        Writes the create-image-pixflux request body (64 x 64, no background, the init image in base64).
    python game/tools/build_hint_arrow_circular.py finish RAW.png OUT.png [--no-polish] [--no-reduce]
        The free fixes on PixelLab's output: alpha snapped to 0 or 255, the canvas outside the arrow cleared,
        arrow pixels PixelLab lost filled from the script's own, the palette cut to at most 30 colours
        (reduce_palette.py). By default the script's outline, glints and shading roles are repainted over
        PixelLab's body pixels (polish), so the outline is exactly near-black and the shading reads at 64 px.
    python game/tools/build_hint_arrow_circular.py polish IN.png OUT.png [--bold]
        Only the repaint of the roles, on an already finished arrow. --bold (T-577 v2, the style loop's rule 2
        fixes at native 64 px) is the bolder pass: a 16 px stroke (the hole 22 px across), a three-step rim
        light, two-pixel deep and shade steps, and longer highlight runs that break both rings of the outline
        over their middle; the stroke's new pixels take PixelLab's blush. `init`, `finish` and `roles` take
        --bold too. --flat (T-577 v3) is the bold stroke with the straight arrow's flat two-tone look: no
        near-white edge line, a two-step rim light, one deep and two shade pixels of stepped shade with no cool
        or mid tones, and three short runs breaking both rings of the outline fully on the upper-left. --crisp
        (T-577 v4) is the flat look with a continuous outline broken only by two 5 px notches on the outer ring
        and the head's slope, a darker three-step shade ending in the cool plum, and a bigger head (14 columns,
        28 px tall at its base, its axis on the stroke's middle).
    python game/tools/build_hint_arrow_circular.py preview IN.png OUT.png [--scale 6]
        An enlarged preview (nearest-neighbour) on a dark and a light background, for the board.

Nothing here calls PixelLab: the paid call is game/tools/pixellab_client.py, inside the style loop. Needs Pillow.
"""
from __future__ import annotations

import argparse
import base64
import json
import math
import sys
from collections import deque
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_hint_arrow import (  # noqa: E402
    BLUSH, BLUSH_DEEP, BLUSH_LIGHT, BLUSH_MID, BLUSH_SHADE, GLINT, INK, _png_bytes, save_png,
)
from build_hint_arrow_curved import BLUSH_MID2, COOL_DEEP, nbrs8  # noqa: E402
from reduce_palette import preview_image, reduce_image  # noqa: E402

SIZE = 64
PALETTE = (INK, GLINT, BLUSH_LIGHT, BLUSH, BLUSH_MID2, BLUSH_MID, BLUSH_SHADE, BLUSH_DEEP, COOL_DEEP)

# The ring's geometry. Pixel (x, y) is centred at (x + 0.5, y + 0.5) in the continuous coordinates below.
# Angles are atan2(dy, dx) in degrees with y down, so an increasing angle goes right, bottom, left, top:
# clockwise on screen. The ring is 54 px across (columns 5..58, rows 7..60), its stroke 13 px, centred a little
# below the middle so the head has room above it. The arc runs from the tail's flat cut at 0 degrees (the
# right, level with the centre) clockwise round to 270 degrees (the top), where the head starts: a 13-column
# 45-degree head pointing right, 26 px tall at its base (twice the stroke, like the curved arrow's), its tip on
# rows 13 and 14 at column 44, which leaves a clear 58-degree gap at the top right before the tail.
CENTRE = (32.0, 34.0)
R_IN, R_OUT = 14.0, 27.0
ARC_START = 0.0              # the tail's cut, in degrees: a flat, horizontal end
ARC_END = 270.0              # the head's base, in degrees (the vertical line x = 32 above the centre)
HEAD_TIP_X = 44              # the head's tip column, pointing right
HEAD_COLS = 13               # columns 32..44; the slopes run at 45 degrees (2 px taller every column)
HEAD_ROW0, HEAD_ROW1 = 13, 14   # the tip's two rows: the head's axis is the ring's mid radius at the top

LIGHT = (-0.5, -1.0)         # where the light comes from: above, a little to the left
LIGHT_STEPS = 2              # the edge line (or rim light) and one rim-light pixel inside it
SHADE_STEPS = (("cool", 1), ("deep", 1), ("shade", 1), ("mid", 1), ("mid2", 1))   # from the outline inwards
NORMAL_REACH = 2             # the outline pixels within this Chebyshev distance give a body pixel its normal

# Outline pixels of the outer ring that become near-white highlight runs (rule 2): two short runs on the ring's
# upper-left outer edge and one on the head's upper slope (the tip's outline stays dark).
ARC_GLINT_DEGREES = [(-172.0, -150.0), (-130.0, -108.0)]
HEAD_GLINT_COLS = range(36, 42)
EDGE_LINE_FROM_DEGREES = 10.0   # the outer edge line starts this far past the tail's cut, so the cut stays plain

# The passes. False is v1. "bold" (T-577 v2, the style loop's rule 2 fixes at native 64 px) is a 16 px stroke
# (the hole 22 px across), a three-step rim light, two-pixel deep and shade steps so the second shade step
# shows, and longer highlight runs that break both rings of the outline over their middle (the ends break the
# outer ring only, so the silhouette stays closed).
GEOM = {
    False: {"r_in": R_IN, "light_steps": LIGHT_STEPS, "hole_light_steps": LIGHT_STEPS, "shade_steps": SHADE_STEPS,
            "arc_glint_degrees": ARC_GLINT_DEGREES, "head_glint_cols": HEAD_GLINT_COLS, "head_run_rows": 3,
            "inner_ring_runs": 0.0, "taper": 0.0, "edge_line": True, "flat_role": "mid"},
    "bold": {"r_in": 11.0, "light_steps": 3, "hole_light_steps": 1,
             "shade_steps": (("cool", 1), ("deep", 2), ("shade", 2), ("mid", 1)),
             "arc_glint_degrees": [(-174.0, -152.0), (-130.0, -110.0)], "head_glint_cols": range(35, 42),
             "head_run_rows": 3, "inner_ring_runs": 0.4, "taper": 0.3, "edge_line": True, "flat_role": "mid"},
    # "flat" (T-577 v3): the bold stroke with the straight arrow's flat two-tone look: no near-white edge line
    # (the near-white is only in the runs, so the breaks read), a two-step rim light, a stepped shade of one
    # deep and two shade pixels with no cool or mid tones, and three short runs that break both rings of the
    # outline fully on the ring's upper-left outer edge.
    "flat": {"r_in": 11.0, "light_steps": 2, "hole_light_steps": 1,
             "shade_steps": (("deep", 1), ("shade", 2)),
             "arc_glint_degrees": [(-173.0, -163.0), (-147.0, -137.0), (-121.0, -111.0)],
             "head_glint_cols": range(36, 41), "head_run_rows": 3, "inner_ring_runs": 1.0, "taper": 0.3,
             "edge_line": False, "flat_role": "body"},   # the turn is plain paint: no mid tone
    # "crisp" (T-577 v4): the flat look with a continuous outline broken only by two 5 px notches on the outer
    # ring and the head's slope (the inner ring never breaks, the near-white never widens inward), a darker
    # three-step shade ending in the cool plum against the outline, and a bigger head: 14 columns, 28 px tall
    # at its base, its axis on the stroke's middle.
    "crisp": {"r_in": 11.0, "light_steps": 2, "hole_light_steps": 1,
              "shade_steps": (("cool", 1), ("deep", 1), ("shade", 1)),
              "arc_glint_degrees": [(-168.0, -158.0), (-128.0, -118.0)],
              "head_glint_cols": range(37, 43), "head_run_rows": 2, "inner_ring_runs": 0.0, "taper": 0.3,
              "edge_line": False, "flat_role": "body", "widen_runs": False, "head": (45, 14, 14, 15)},
}
HEAD_DEFAULT = (HEAD_TIP_X, HEAD_COLS, HEAD_ROW0, HEAD_ROW1)   # (tip column, columns, tip's first row, last row)


def head_of(g: dict) -> tuple[int, int, int, int]:
    return g.get("head", HEAD_DEFAULT)


def angle_from_start(x: float, y: float) -> float:
    """The clockwise angle in degrees from the tail's cut to the point, in [0, 360)."""
    a = math.degrees(math.atan2(y - CENTRE[1], x - CENTRE[0]))
    return (a - ARC_START) % 360.0


def arrow_cells(bold=False) -> set[tuple[int, int]]:
    """Every pixel of the arrow's silhouette, outline included."""
    r_in = GEOM[bold]["r_in"]
    cells = set()
    span = (ARC_END - ARC_START) % 360.0
    for y in range(SIZE):
        for x in range(SIZE):
            px_, py_ = x + 0.5, y + 0.5
            d = math.hypot(px_ - CENTRE[0], py_ - CENTRE[1])
            if r_in <= d <= R_OUT and angle_from_start(px_, py_) <= span:
                cells.add((x, y))
    tip_x, cols, row0, row1 = head_of(GEOM[bold])
    for k in range(cols):
        x = tip_x - k
        for y in range(row0 - k, row1 + k + 1):
            cells.add((x, y))
    return cells


LAST_DEPTHS: dict[str, dict[tuple[int, int], int]] = {}   # the last layers() call's ring depths, for `roles --depths`


def layers(bold=False) -> dict[str, set[tuple[int, int]]]:
    """The arrow's pixels by colour role: a two-pixel outline whose outer ring carries short near-white glint
    runs, a near-white edge line and a rim light on the lit edges, stepped shade with a cool deepest step on the
    edges away from the light, the plain body between. `bold` (v2) widens the stroke, the rim light and the
    shade steps so they show at native 64 px, and lets the runs break both rings over their middle."""
    g = GEOM[bold]
    cells = arrow_cells(bold)
    outline1 = {p for p in cells if any(q not in cells for q in nbrs8(p))}
    inner = {p for p in cells - outline1 if any(q in outline1 for q in nbrs8(p))}
    outline = outline1 | inner
    body = cells - outline

    r_in = g["r_in"]
    mid_radius = (r_in + R_OUT) / 2
    tip_x, head_cols, head_row0, head_row1 = head_of(g)
    head_x0 = tip_x - head_cols + 1
    span = (ARC_END - ARC_START) % 360.0
    shade_bands = []
    for role, n in g["shade_steps"]:
        shade_bands.extend([role] * n)
    roles = {"edge": set(), "light": set(), "cool": set(), "deep": set(), "shade": set(), "mid": set(),
             "mid2": set(), "body": set()}

    def polar(p):
        x, y = p[0] + 0.5 - CENTRE[0], p[1] + 0.5 - CENTRE[1]
        return math.hypot(x, y), math.atan2(y, x)

    def edge_line_ok(p) -> bool:
        # The near-white edge line runs along the ring's outer edge and the head only; the hole's rim and the
        # tail's cut get the plain rim light, so no near-white specks sit inside the ring.
        if not g["edge_line"]:
            return False
        x, y = p[0] + 0.5, p[1] + 0.5
        if p[0] >= head_x0 and p[1] <= head_row1 + head_cols:
            return True
        return (math.hypot(x - CENTRE[0], y - CENTRE[1]) > mid_radius
                and EDGE_LINE_FROM_DEGREES < angle_from_start(x, y) < span)

    def distances(seed: set[tuple[int, int]], through: set[tuple[int, int]]) -> dict[tuple[int, int], int]:
        dist = {p: 0 for p in seed}
        queue = deque(seed)
        while queue:
            p = queue.popleft()
            for q in nbrs8(p):
                if q in through and q not in dist:
                    dist[q] = dist[p] + 1
                    queue.append(q)
        return dist

    # The ring's shading is radial: each body pixel has a depth from the outer outline ring and one from the
    # hole's ring, and each ring is lit, shaded or flat at the pixel's own angle (the outward normal of the
    # outer ring is radial; the hole's rim faces the other way). The nearer ring decides, so the bands run
    # evenly round the ring with no spill where a shaded stretch begins. The tail's flat cut gets the plain
    # rim light on its first rows.
    ring = set()
    for p in cells:
        d, a = polar(p)
        if r_in <= d <= R_OUT and angle_from_start(p[0] + 0.5, p[1] + 0.5) <= span:
            ring.add(p)
    ring_body = ring & body
    outer_outline = {p for p in outline if polar(p)[0] > mid_radius}
    inner_outline = {p for p in outline if polar(p)[0] <= mid_radius}
    def nearest(seed: set[tuple[int, int]]) -> dict[tuple[int, int], int]:
        # The Euclidean distance to the nearest pixel of the ring's outline, in whole pixels: a walk along the
        # pixels (Chebyshev) would leak diagonally from the circle's stair-steps and undercount the depth.
        return {p: int(min(math.hypot(p[0] - q[0], p[1] - q[1]) for q in seed) + 1e-6) for p in ring_body}

    d_outer = nearest(outer_outline)
    d_inner = nearest(inner_outline)
    LAST_DEPTHS.clear()
    LAST_DEPTHS.update({"outer": d_outer, "inner": d_inner})

    taper = g["taper"]

    def visible_of(total: int, score: float) -> int:
        # With a taper, the rim light and the shade steps fade in over the first `taper` of the score past
        # the flat band, so a stretch's bands grow from the outline instead of starting along a radial seam.
        if not taper:
            return total
        return min(total, math.ceil(total * (abs(score) - 0.2) / taper))

    def side_role(score: float, depth: int, p, steps: int) -> str | None:
        if score > 0.2:
            if depth == 0:
                return "edge" if edge_line_ok(p) else "light"
            return "light" if depth < visible_of(steps, score) else None
        if score < -0.2:
            # The lighter steps appear first: the stack is shifted, never cut, so no lone dark pixel.
            index = depth + len(shade_bands) - visible_of(len(shade_bands), score)
            return shade_bands[index] if index < len(shade_bands) else None
        return g["flat_role"] if depth == 0 else None   # the turn between the lit and the shaded stretch

    for p in ring_body:
        d, a = polar(p)
        if p[0] + 0.5 > CENTRE[0] and p[1] + 0.5 - CENTRE[1] < 4.0:
            roles["light"].add(p)   # the tail's cut
            continue
        score_outer = math.cos(a) * LIGHT[0] + math.sin(a) * LIGHT[1]
        sides = [(d_outer.get(p, 99) - 1, score_outer, g["light_steps"]),
                 (d_inner.get(p, 99) - 1, -score_outer, g["hole_light_steps"])]
        sides.sort(key=lambda s: s[0])
        role = None
        for depth, score, steps in sides:
            role = side_role(score, depth, p, steps)
            if role:
                break
        roles[role or "body"].add(p)

    # The head (its pixels outside the ring) keeps the neighbour model: a body pixel next to the outline faces
    # the way the outline pixels around it lie, summed within NORMAL_REACH so a lone corner neighbour cannot
    # point it the wrong way; the rim light and the shade steps are counted from those edge pixels.
    head_body = body - ring_body
    lit_edge, shade_edge, flat_edge = set(), set(), set()
    reach = range(-NORMAL_REACH, NORMAL_REACH + 1)
    for p in head_body:
        if not any(q in outline for q in nbrs8(p)):
            continue
        around = [(p[0] + dx, p[1] + dy) for dx in reach for dy in reach if (p[0] + dx, p[1] + dy) in outline]
        nx = sum(q[0] - p[0] for q in around)
        ny = sum(q[1] - p[1] for q in around)
        norm = math.hypot(nx, ny) or 1.0
        score = (nx * LIGHT[0] + ny * LIGHT[1]) / norm
        if score > 0.2:
            lit_edge.add(p)
        elif score < -0.2:
            shade_edge.add(p)
        else:
            flat_edge.add(p)
    d_lit = distances(lit_edge, head_body)
    d_shade = distances(shade_edge, head_body)
    for p in head_body:
        dl, ds = d_lit.get(p, 99), d_shade.get(p, 99)
        if p in lit_edge:
            roles["edge" if edge_line_ok(p) else "light"].add(p)
        elif ds < 1:
            roles[shade_bands[0]].add(p)
        elif dl < g["light_steps"] and p not in flat_edge:
            roles["light"].add(p)
        elif p in flat_edge:
            roles[g["flat_role"]].add(p)
        elif ds < len(shade_bands):
            roles[shade_bands[ds]].add(p)
        else:
            roles["body"].add(p)

    glint = set()
    shrink = g["inner_ring_runs"]   # the inner ring breaks over this fraction of each run's middle (0: never)
    for x, y in outline:   # the runs sit on the outer edge only, never on the hole's outline
        if math.hypot(x + 0.5 - CENTRE[0], y + 0.5 - CENTRE[1]) > mid_radius and x < head_x0:
            angle = math.degrees(math.atan2(y + 0.5 - CENTRE[1], x + 0.5 - CENTRE[0]))
            for lo, hi in g["arc_glint_degrees"]:
                if (x, y) in outline1 and lo <= angle <= hi:
                    glint.add((x, y))
                elif (x, y) not in outline1 and shrink:
                    margin = (hi - lo) * (1 - shrink) / 2
                    if lo + margin <= angle <= hi - margin:
                        glint.add((x, y))
    for x in g["head_glint_cols"]:
        k = tip_x - x
        top = head_row0 - k
        glint.update({(x, y) for y in range(top, top + g["head_run_rows"])} & (outline if shrink else outline1))
    if g.get("widen_runs", True):
        # The runs are wider than the outline pixel: the lit pixel just inside a run is near-white too.
        lit_inside = {p for p in roles["light"] if any(q in glint for q in nbrs8(p))}
        roles["light"] -= lit_inside
        roles["edge"] |= lit_inside
    roles["outline"] = outline - glint
    roles["glint"] = glint
    return {role: cells for role, cells in roles.items() if cells or role in ("outline", "glint", "body")}


COLOURS = {
    "outline": INK, "glint": GLINT, "edge": GLINT, "light": BLUSH_LIGHT, "mid2": BLUSH_MID2, "mid": BLUSH_MID,
    "shade": BLUSH_SHADE, "deep": BLUSH_DEEP, "cool": COOL_DEEP, "body": BLUSH,
}


ROLE_LETTERS = {
    "outline": "#", "glint": "*", "edge": "E", "light": "l", "mid2": "n", "mid": "m", "shade": "s", "deep": "d",
    "cool": "c", "body": ".",
}


def roles_map(bold=False) -> str:
    """The colour roles as an ASCII map, one letter per pixel (ROLE_LETTERS; a space is transparent)."""
    grid = [[" "] * SIZE for _ in range(SIZE)]
    for role, cells in layers(bold).items():
        for x, y in cells:
            grid[y][x] = ROLE_LETTERS[role]
    header = "    " + "".join(str(x % 10) for x in range(SIZE))
    return "\n".join([header] + [f"{y:3d} " + "".join(row) for y, row in enumerate(grid)])


def arrow(bold=False) -> Image.Image:
    """The script-drawn circular arrow, straight from above."""
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = im.load()
    for role, cells in layers(bold).items():
        for x, y in cells:
            px[x, y] = COLOURS[role]
    return im


DESCRIPTION = (
    "one bold circular arrow road marking seen straight from above, flat top-down view, a thick ring-shaped "
    "arrow bent into nearly a full circle running clockwise, with an open gap at the top right and a wide "
    "triangular head at the top pointing right into the gap, painted in pale pink, lighter highlight along the "
    "upper and left edges, dusky darker pink shade along the lower and right edges, near-black outline, slightly "
    "worn paint texture, retro night arcade look, crisp pixel art, no gradients, transparent background"
)

NEGATIVE = (
    "text, letters, words, road, asphalt, background, keycap, button, box, frame, several arrows, two arrows, "
    "straight arrow, anticlockwise, counterclockwise, refresh icon, closed circle without a gap, drop shadow, "
    "blur, gradient, photo, 3d render, tilted, perspective"
)


def request(init_png: bytes, strength: int = 500, seed: int | None = None) -> dict:
    body = {
        "description": DESCRIPTION,
        "negative_description": NEGATIVE,
        "image_size": {"width": SIZE, "height": SIZE},
        "no_background": True,
        "text_guidance_scale": 8.0,
        "outline": "single color black outline",
        "shading": "detailed shading",
        "detail": "highly detailed",
        "view": "high top-down",
        "init_image": {"type": "base64", "base64": base64.b64encode(init_png).decode("ascii")},
        "init_image_strength": int(strength),
    }
    if seed is not None:
        body["seed"] = int(seed)
    return body


def polish(im: Image.Image, bold=False) -> Image.Image:
    """Repaint every role but the plain body from layers(), so the outline is exactly near-black and the glints,
    rim light and shade steps are the script's; PixelLab's body pixels stay where they are opaque and blush-like.
    Body pixels that are not (a wider stroke's new pixels, a stray dark pixel) take the most common body colour
    already there (PixelLab's blush)."""
    im = im.convert("RGBA")
    if im.size != (SIZE, SIZE):
        im = im.resize((SIZE, SIZE), Image.NEAREST)
    px = im.load()
    shape = arrow_cells(bold)
    for y in range(SIZE):
        for x in range(SIZE):
            if (x, y) not in shape:
                px[x, y] = (0, 0, 0, 0)
    roles = layers(bold)

    def blush_like(c) -> bool:
        # A plain body pixel of PixelLab's: opaque and within 24 of the spec blush (PixelLab's render sits within
        # about 5). Anything else inside the body (a stray dark or pale pixel) is repainted.
        return c[3] == 255 and sum((a - b) ** 2 for a, b in zip(c[:3], BLUSH[:3])) < 24 ** 2

    counts: dict[tuple[int, int, int, int], int] = {}
    for x, y in roles["body"]:
        if blush_like(px[x, y]):
            counts[px[x, y]] = counts.get(px[x, y], 0) + 1
    fill = max(counts, key=counts.get) if counts else BLUSH
    for role, cells in roles.items():
        for x, y in cells:
            if role == "body":
                if not blush_like(px[x, y]):
                    px[x, y] = fill
            else:
                px[x, y] = COLOURS[role]
    return im


def finish(raw: Image.Image, do_polish: bool = True, reduce: bool = True, bold=False) -> Image.Image:
    """The free fixes on a PixelLab result, keeping its pixels wherever they can stay."""
    im = raw.convert("RGBA")
    if im.size != (SIZE, SIZE):
        im = im.resize((SIZE, SIZE), Image.NEAREST)
    shape = arrow(bold)
    spx = shape.load()
    px = im.load()
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, a = px[x, y]
            if a < 128 or spx[x, y][3] == 0:
                px[x, y] = (0, 0, 0, 0)       # the canvas outside the arrow, and half pixels
            else:
                px[x, y] = (r, g, b, 255)
    for y in range(SIZE):
        for x in range(SIZE):
            if spx[x, y][3] == 255 and px[x, y][3] == 0:
                px[x, y] = spx[x, y]          # pixels the shape has but PixelLab lost
    if do_polish:
        im = polish(im, bold)
    if reduce:
        im = reduce_image(im, 30)
    return im


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("init", help="draw the script arrow")
    a.add_argument("out")
    r = sub.add_parser("request", help="write the pixflux request body")
    r.add_argument("out")
    r.add_argument("--init", required=True)
    r.add_argument("--strength", type=int, default=500)
    r.add_argument("--seed", type=int)
    f = sub.add_parser("finish", help="free fixes on PixelLab's output")
    f.add_argument("raw")
    f.add_argument("out")
    f.add_argument("--no-polish", action="store_true", help="keep PixelLab's outline and shading pixels")
    f.add_argument("--no-reduce", action="store_true")
    q = sub.add_parser("polish", help="repaint the outline, glints and shading roles from the script")
    q.add_argument("src")
    q.add_argument("out")
    v = sub.add_parser("preview", help="enlarged preview on dark and light")
    v.add_argument("src")
    v.add_argument("out")
    v.add_argument("--scale", type=int, default=6)
    m = sub.add_parser("roles", help="print the colour roles as an ASCII map (one letter per pixel)")
    m.add_argument("--depths", type=int, metavar="ROW", help="also print the ring depths along this row")
    for sp in (a, f, q, m):
        sp.add_argument("--bold", action="store_true",
                        help="the v2 pass: a 16 px stroke, wider rim light and shade steps, runs breaking both rings")
        sp.add_argument("--flat", action="store_true",
                        help="the v3 pass: the bold stroke with a flat two-tone shade, no edge line, full-depth runs")
        sp.add_argument("--crisp", action="store_true",
                        help="the v4 pass: flat, with a continuous outline, two 5 px notches, a darker shade and a bigger head")
    args = p.parse_args(argv)
    bold = False
    for name in ("bold", "flat", "crisp"):
        if getattr(args, name, False):
            bold = name

    if args.cmd == "init":
        save_png(arrow(bold), Path(args.out))
    elif args.cmd == "roles":
        print(roles_map(bold))
        if args.depths is not None:
            for name in ("outer", "inner"):
                print(name, [(x, LAST_DEPTHS[name].get((x, args.depths))) for x in range(SIZE)
                             if (x, args.depths) in LAST_DEPTHS[name]])
        return 0
    elif args.cmd == "request":
        body = request(Path(args.init).read_bytes(), args.strength, args.seed)
        Path(args.out).parent.mkdir(parents=True, exist_ok=True)
        Path(args.out).write_text(json.dumps(body) + "\n", encoding="utf-8")
    elif args.cmd == "finish":
        with Image.open(args.raw) as raw:
            im = finish(raw, not args.no_polish, not args.no_reduce, bold)
        save_png(im, Path(args.out))
    elif args.cmd == "polish":
        with Image.open(args.src) as src:
            im = reduce_image(polish(src, bold), 30)
        save_png(im, Path(args.out))
    else:
        with Image.open(args.src) as src:
            save_png(preview_image(src, args.scale), Path(args.out))
    print("wrote", args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
