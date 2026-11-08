"""The hint pieces' curved turn arrow (task T-577; Level design, Decisions, "Hint pieces in the level creator").

The curved arrow (hint_arrow_curved.png) is a flat top-down road-marking arrow, 64 x 64 px, that starts at the
bottom centre going up and bends through a quarter circle to turn RIGHT, its head pointing right at the top right.
The engine mirrors it for a left turn (game/docs/level/hint-pieces.md, "The art"), so the picture is always a
right turn. It shares the straight arrow's look (build_hint_arrow.py): blush #f6c9de body, a lighter rim light on
the lit edges, stepped darker shade on the lower/right edges and the inner bend, a two-pixel near-black selective
outline broken by near-white highlight runs where the light comes from (Visual style, Content, "Rules", rule 2).
This script does the free parts of the style loop around one PixelLab call per version:

    python game/tools/build_hint_arrow_curved.py init OUT.png
        Draws the script arrow: the init image PixelLab starts from, and a fallback on its own.
    python game/tools/build_hint_arrow_curved.py request OUT.json --init INIT.png [--strength N] [--seed N]
        Writes the create-image-pixflux request body (64 x 64, no background, the init image in base64).
    python game/tools/build_hint_arrow_curved.py finish RAW.png OUT.png [--no-polish] [--no-reduce]
        The free fixes on PixelLab's output: alpha snapped to 0 or 255, the canvas outside the arrow cleared,
        arrow pixels PixelLab lost filled from the script's own, the palette cut to at most 30 colours
        (reduce_palette.py). By default the script's outline, glints and shading roles are repainted over
        PixelLab's body pixels (polish), so the outline is exactly near-black and the shading reads at 64 px.
    python game/tools/build_hint_arrow_curved.py polish IN.png OUT.png [--wide]
        Only the repaint of the roles, on an already finished arrow. --wide (T-577 v2, the style loop's rule 2
        fixes at native 64 px) is the bolder footprint: an 18 px shaft, a clearer bend of radii 5 and 22, a
        three-step rim light, three two-pixel shade steps and near-white runs three pixels wide on longer
        stretches of the shaft's left, the outer bend and the head's upper slope; the body's new pixels take
        PixelLab's blush. `init` and `finish` take --wide too. --rich (T-577 v3) is the wide pass with two more
        tones (a mid-tone #e9b8d1 and a cool plum deepest step #5e3d66 against the outline on the shade side,
        for the night mood), a near-white edge line along every lit edge, and longer, more numerous highlight
        runs breaking the outline on the bend's and the head's top and left edges. The `wide` argument of
        arrow_cells(), layers(), arrow(), polish() and finish() takes False, True or "rich".
    python game/tools/build_hint_arrow_curved.py preview IN.png OUT.png [--scale 6]
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
from reduce_palette import preview_image, reduce_image  # noqa: E402

SIZE = 64
BLUSH_MID2 = (0xE9, 0xB8, 0xD1, 255)   # the rich pass's extra mid-tone between the body and the mid shade
COOL_DEEP = (0x5E, 0x3D, 0x66, 255)    # the rich pass's cool plum deepest step against the outline (night, rule 4)
PALETTE = (INK, GLINT, BLUSH_LIGHT, BLUSH, BLUSH_MID2, BLUSH_MID, BLUSH_SHADE, BLUSH_DEEP, COOL_DEEP)

# The arrow's geometry. Pixel (x, y) is centred at (x + 0.5, y + 0.5) in the continuous coordinates below.
# v1: a 14 px shaft (columns 24..37) from the bottom centre, a quarter circle of radii 4 and 18 centred at
# (42, 31), an 18-column head pointing right with its tip at column 59 on rows 19 and 20: 36 x 58 px.
# `wide` (v2, the style loop's rule 2 fixes at native 64 px): an 18 px shaft (columns 20..37), a clearer bend of
# radii 5 and 22 centred at (42, 34), the same 18-column head, 36 px tall at its base: 40 x 57 px.
GEOM = {
    False: {"shaft": (24, 37), "centre": (42.0, 31.0), "radii": (4.0, 18.0), "head_cols": 18, "tip_rows": (19, 20),
            "shaft_glint_rows": range(36, 48), "arc_glint_degrees": [(-170.0, -122.0)],
            "head_glint_cols": range(45, 55), "light_steps": 2,
            "shade_steps": (("deep", 1), ("shade", 1), ("mid", 2)), "edge_line": False},
    True: {"shaft": (20, 37), "centre": (42.0, 34.0), "radii": (5.0, 22.0), "head_cols": 18, "tip_rows": (20, 21),
           "shaft_glint_rows": range(38, 51), "arc_glint_degrees": [(-168.0, -116.0)],
           "head_glint_cols": range(45, 56), "light_steps": 3,
           "shade_steps": (("deep", 2), ("shade", 2), ("mid", 2)), "edge_line": False},
    # "rich" (v3): the wide geometry with two more tones, a near-white edge line along every lit edge and
    # longer, more numerous highlight runs breaking the outline on the bend's and the head's top and left edges.
    "rich": {"shaft": (20, 37), "centre": (42.0, 34.0), "radii": (5.0, 22.0), "head_cols": 18, "tip_rows": (20, 21),
             "shaft_glint_rows": range(36, 53), "arc_glint_degrees": [(-174.0, -142.0), (-128.0, -96.0)],
             "head_glint_cols": range(44, 55), "light_steps": 3,
             "shade_steps": (("cool", 1), ("deep", 1), ("shade", 2), ("mid", 2), ("mid2", 2)), "edge_line": True},
}
SHAFT_X0, SHAFT_X1 = GEOM[False]["shaft"]
BOTTOM = 59                        # the shaft's last row
CENTRE = GEOM[False]["centre"]     # the bend's circle centre: the shaft runs below it, the arc above and left of it
R_IN, R_OUT = GEOM[False]["radii"]
HEAD_TIP_X = 59                    # the head's tip column, pointing right
HEAD_COLS = GEOM[False]["head_cols"]   # the head's length; its slopes run at 45 degrees (2 px taller every column)
HEAD_ROW0, HEAD_ROW1 = GEOM[False]["tip_rows"]   # the tip's two rows: the head's axis is the band's middle at the top
SHAFT_TOP = int(CENTRE[1])         # the first row of the straight shaft

LIGHT = (-0.5, -1.0)   # where the light comes from: above, a little to the left

# Outline pixels that become near-white highlight runs (rule 2): the shaft's left, the outer bend's upper-left
# and the head's upper slope.
SHAFT_GLINT_ROWS = GEOM[False]["shaft_glint_rows"]
ARC_GLINT_DEGREES = GEOM[False]["arc_glint_degrees"]   # atan2 angles from the centre; the upper-left quadrant is (-180, -90)
HEAD_GLINT_COLS = GEOM[False]["head_glint_cols"]


def nbrs8(p):
    x, y = p
    return [(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if (dx, dy) != (0, 0)]


def arrow_cells(wide: bool = False) -> set[tuple[int, int]]:
    """Every pixel of the arrow's silhouette, outline included."""
    g = GEOM[wide]
    cx, cy = g["centre"]
    r_in, r_out = g["radii"]
    x0, x1 = g["shaft"]
    row0, row1 = g["tip_rows"]
    cells = set()
    for y in range(int(cy), BOTTOM + 1):
        for x in range(x0, x1 + 1):
            cells.add((x, y))
    for y in range(0, int(cy)):
        for x in range(0, int(cx)):
            px_, py_ = x + 0.5, y + 0.5
            if r_in <= math.hypot(px_ - cx, py_ - cy) <= r_out:
                cells.add((x, y))
    for k in range(g["head_cols"]):
        x = HEAD_TIP_X - k
        for y in range(row0 - k, row1 + k + 1):
            cells.add((x, y))
    return cells


def head_upper_slope(cells: set[tuple[int, int]], wide: bool = False) -> set[tuple[int, int]]:
    """The head's pixels above its axis, in the columns of the head."""
    g = GEOM[wide]
    return {(x, y) for x, y in cells if x > int(g["centre"][0]) and y <= g["tip_rows"][0]}


def layers(wide: bool = False) -> dict[str, set[tuple[int, int]]]:
    """The arrow's pixels by colour role: a two-pixel outline with near-white glint runs breaking it, a near-white
    edge and a stepped rim light on the lit edges, three stepped shade steps on the edges away from the light,
    the plain body between. `wide` (v2) widens every band so it shows at native 64 px: a three-step rim light,
    three two-pixel shade steps, and near-white runs three pixels wide (the outline's two and the lit pixel
    inside) on longer stretches."""
    g = GEOM[wide]
    cells = arrow_cells(wide)
    outline1 = {p for p in cells if any(q not in cells for q in nbrs8(p))}
    inner = {p for p in cells - outline1 if any(q in outline1 for q in nbrs8(p))}
    outline = outline1 | inner
    body = cells - outline

    cx, cy = g["centre"]
    inner_corner = g["radii"][0] + 4   # the inner bend and the corners either side of it are in shadow
    lit_edge, shade_edge, flat_edge = set(), set(), set()
    for p in body:
        around = [q for q in nbrs8(p) if q in outline]
        if not around:
            continue
        nx = sum(q[0] - p[0] for q in around)
        ny = sum(q[1] - p[1] for q in around)
        norm = math.hypot(nx, ny) or 1.0
        score = (nx * LIGHT[0] + ny * LIGHT[1]) / norm
        if math.hypot(p[0] + 0.5 - cx, p[1] + 0.5 - cy) < inner_corner:
            shade_edge.add(p)
        elif score > 0.2:
            lit_edge.add(p)
        elif score < -0.2:
            shade_edge.add(p)
        else:
            flat_edge.add(p)

    def distances(seed: set[tuple[int, int]]) -> dict[tuple[int, int], int]:
        dist = {p: 0 for p in seed}
        queue = deque(seed)
        while queue:
            p = queue.popleft()
            for q in ((p[0] + 1, p[1]), (p[0] - 1, p[1]), (p[0], p[1] + 1), (p[0], p[1] - 1)):
                if q in body and q not in dist:
                    dist[q] = dist[p] + 1
                    queue.append(q)
        return dist

    d_lit = distances(lit_edge)
    d_shade = distances(shade_edge)
    # The shade bands, from the outline inwards: (role, width) pairs; the first band is the darkest.
    shade_bands = []
    for role, n in g["shade_steps"]:
        shade_bands.extend([role] * n)
    roles = {"edge": set(), "light": set(), "cool": set(), "deep": set(), "shade": set(), "mid": set(),
             "mid2": set(), "body": set()}
    slope = head_upper_slope(cells, wide)
    for p in body:
        dl, ds = d_lit.get(p, 99), d_shade.get(p, 99)
        if p in lit_edge:
            roles["edge" if (g["edge_line"] or p in slope) else "light"].add(p)
        elif ds < 1:
            roles[shade_bands[0]].add(p)
        elif dl < g["light_steps"] and p not in flat_edge:
            roles["light"].add(p)
        elif p in flat_edge:
            roles["shade"].add(p)
        elif ds < len(shade_bands):
            roles[shade_bands[ds]].add(p)
        else:
            roles["body"].add(p)

    shaft_x0 = g["shaft"][0]
    row0 = g["tip_rows"][0]
    glint = {(x, y) for x, y in outline if x in (shaft_x0, shaft_x0 + 1) and y in g["shaft_glint_rows"]}
    mid_radius = sum(g["radii"]) / 2   # the runs sit on the outer bend only, never on the inner arc's outline
    for x, y in outline:
        if x < cx and y < cy and math.hypot(x + 0.5 - cx, y + 0.5 - cy) > mid_radius:
            angle = math.degrees(math.atan2(y + 0.5 - cy, x + 0.5 - cx))
            if any(lo <= angle <= hi for lo, hi in g["arc_glint_degrees"]):
                glint.add((x, y))
    for x in g["head_glint_cols"]:
        k = HEAD_TIP_X - x
        top = row0 - k
        glint.update({(x, y) for y in range(top, top + 4)} & outline)
    if wide:
        # The runs are three pixels wide: the lit pixel just inside a glint run is near-white too.
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


def arrow(wide: bool = False) -> Image.Image:
    """The script-drawn curved arrow, straight from above."""
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = im.load()
    for role, cells in layers(wide).items():
        for x, y in cells:
            px[x, y] = COLOURS[role]
    return im


DESCRIPTION = (
    "one bold curved turn arrow road marking seen straight from above, flat top-down view, a thick shaft rising "
    "from the bottom centre that bends smoothly through a quarter circle to the right and ends in a wide "
    "triangular head pointing right at the top right, painted in pale pink, lighter highlight along the upper and "
    "left edges, dusky darker pink shade along the lower and right edges and the inside of the bend, near-black "
    "outline, slightly worn paint texture, retro night arcade look, crisp pixel art, no gradients, transparent "
    "background"
)

NEGATIVE = (
    "text, letters, words, road, asphalt, background, keycap, button, box, frame, several arrows, straight arrow, "
    "left turn, u-turn, circle, drop shadow, blur, gradient, photo, 3d render, tilted, perspective"
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


def polish(im: Image.Image, wide: bool = False) -> Image.Image:
    """Repaint every role but the plain body from layers(), so the outline is exactly near-black and the glints,
    rim light and shade steps are the script's; PixelLab's body pixels stay where they are opaque. With `wide`
    the bolder v2 footprint: body pixels the old silhouette did not have take the most common body colour already
    there (PixelLab's blush), so the body stays one even paint."""
    im = im.convert("RGBA")
    if im.size != (SIZE, SIZE):
        im = im.resize((SIZE, SIZE), Image.NEAREST)
    px = im.load()
    shape = arrow_cells(wide)
    for y in range(SIZE):
        for x in range(SIZE):
            if (x, y) not in shape:
                px[x, y] = (0, 0, 0, 0)
    roles = layers(wide)

    def blush_like(c) -> bool:
        # A plain body pixel of PixelLab's: opaque and within 24 of the spec blush (PixelLab's render sits within
        # about 5). Anything else inside the body (an outline, rim-light or shade pixel of a smaller base, a
        # stray dark pixel) is repainted.
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


def finish(raw: Image.Image, do_polish: bool = True, reduce: bool = True, wide: bool = False) -> Image.Image:
    """The free fixes on a PixelLab result, keeping its pixels wherever they can stay."""
    im = raw.convert("RGBA")
    if im.size != (SIZE, SIZE):
        im = im.resize((SIZE, SIZE), Image.NEAREST)
    shape = arrow(wide)
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
        im = polish(im, wide)
    if reduce:
        im = reduce_image(im, 30)
    return im


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("init", help="draw the script arrow")
    a.add_argument("out")
    a.add_argument("--wide", action="store_true", help="the bolder v2 footprint with wider shading bands")
    a.add_argument("--rich", action="store_true", help="the v3 pass: wide, with more tones, an edge line and more glint runs")
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
    f.add_argument("--wide", action="store_true", help="the bolder v2 footprint with wider shading bands")
    f.add_argument("--rich", action="store_true", help="the v3 pass: wide, with more tones, an edge line and more glint runs")
    q = sub.add_parser("polish", help="repaint the outline, glints and shading roles from the script")
    q.add_argument("src")
    q.add_argument("out")
    q.add_argument("--wide", action="store_true", help="the bolder v2 footprint with wider shading bands (T-577 v2)")
    q.add_argument("--rich", action="store_true", help="the v3 pass: wide, with more tones, an edge line and more glint runs")
    v = sub.add_parser("preview", help="enlarged preview on dark and light")
    v.add_argument("src")
    v.add_argument("out")
    v.add_argument("--scale", type=int, default=6)
    args = p.parse_args(argv)
    if getattr(args, "rich", False):
        args.wide = "rich"

    if args.cmd == "init":
        save_png(arrow(args.wide), Path(args.out))
    elif args.cmd == "request":
        body = request(Path(args.init).read_bytes(), args.strength, args.seed)
        Path(args.out).parent.mkdir(parents=True, exist_ok=True)
        Path(args.out).write_text(json.dumps(body) + "\n", encoding="utf-8")
    elif args.cmd == "finish":
        with Image.open(args.raw) as raw:
            im = finish(raw, not args.no_polish, not args.no_reduce, args.wide)
        save_png(im, Path(args.out))
    elif args.cmd == "polish":
        with Image.open(args.src) as src:
            im = reduce_image(polish(src, args.wide), 30)
        save_png(im, Path(args.out))
    else:
        with Image.open(args.src) as src:
            save_png(preview_image(src, args.scale), Path(args.out))
    print("wrote", args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
