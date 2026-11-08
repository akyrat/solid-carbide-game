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
    python game/tools/build_hint_arrow_curved.py polish IN.png OUT.png
        Only the repaint of the roles, on an already finished arrow.
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
PALETTE = (INK, GLINT, BLUSH_LIGHT, BLUSH, BLUSH_MID, BLUSH_SHADE, BLUSH_DEEP)

# The arrow's geometry. Pixel (x, y) is centred at (x + 0.5, y + 0.5) in the continuous coordinates below.
SHAFT_X0, SHAFT_X1 = 24, 37        # the shaft, 14 px wide, from the bottom centre
BOTTOM = 59                        # the shaft's last row
CENTRE = (42.0, 31.0)              # the bend's circle centre: the shaft runs below it, the arc above and left of it
R_IN, R_OUT = 4.0, 18.0            # the bend's inner and outer radius (the band is 14 px, like the shaft)
HEAD_TIP_X = 59                    # the head's tip column, pointing right
HEAD_COLS = 18                     # the head's length; its slopes run at 45 degrees (2 px taller every column)
HEAD_ROW0, HEAD_ROW1 = 19, 20      # the tip's two rows: the head's axis is the band's middle at the top
SHAFT_TOP = int(CENTRE[1])         # the first row of the straight shaft

LIGHT = (-0.5, -1.0)   # where the light comes from: above, a little to the left

# Outline pixels that become near-white highlight runs (rule 2): the shaft's left, the outer bend's upper-left
# and the head's upper slope.
SHAFT_GLINT_ROWS = range(36, 48)
ARC_GLINT_DEGREES = (-170.0, -122.0)   # atan2 angles from the centre, the upper-left quadrant is (-180, -90)
HEAD_GLINT_COLS = range(45, 55)


def nbrs8(p):
    x, y = p
    return [(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if (dx, dy) != (0, 0)]


def arrow_cells() -> set[tuple[int, int]]:
    """Every pixel of the arrow's silhouette, outline included."""
    cx, cy = CENTRE
    cells = set()
    for y in range(SHAFT_TOP, BOTTOM + 1):
        for x in range(SHAFT_X0, SHAFT_X1 + 1):
            cells.add((x, y))
    for y in range(0, SHAFT_TOP):
        for x in range(0, int(cx)):
            px_, py_ = x + 0.5, y + 0.5
            if R_IN <= math.hypot(px_ - cx, py_ - cy) <= R_OUT:
                cells.add((x, y))
    for k in range(HEAD_COLS):
        x = HEAD_TIP_X - k
        for y in range(HEAD_ROW0 - k, HEAD_ROW1 + k + 1):
            cells.add((x, y))
    return cells


def head_upper_slope(cells: set[tuple[int, int]]) -> set[tuple[int, int]]:
    """The head's pixels above its axis, in the columns of the head."""
    return {(x, y) for x, y in cells if x > int(CENTRE[0]) and y <= HEAD_ROW0}


def layers() -> dict[str, set[tuple[int, int]]]:
    """The arrow's pixels by colour role: a two-pixel outline with near-white glint runs breaking it, a near-white
    edge and a two-step rim light on the lit edges, three stepped shade steps on the edges away from the light,
    the plain body between."""
    cells = arrow_cells()
    outline1 = {p for p in cells if any(q not in cells for q in nbrs8(p))}
    inner = {p for p in cells - outline1 if any(q in outline1 for q in nbrs8(p))}
    outline = outline1 | inner
    body = cells - outline

    lit_edge, shade_edge, flat_edge = set(), set(), set()
    for p in body:
        around = [q for q in nbrs8(p) if q in outline]
        if not around:
            continue
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
    roles = {"edge": set(), "light": set(), "deep": set(), "shade": set(), "mid": set(), "body": set()}
    slope = head_upper_slope(cells)
    for p in body:
        dl, ds = d_lit.get(p, 99), d_shade.get(p, 99)
        if p in lit_edge:
            roles["edge" if p in slope else "light"].add(p)
        elif p in shade_edge:
            roles["deep"].add(p)
        elif dl == 1 and p not in flat_edge:
            roles["light"].add(p)
        elif ds == 1 or p in flat_edge:
            roles["shade"].add(p)
        elif ds in (2, 3):
            roles["mid"].add(p)
        else:
            roles["body"].add(p)

    cx, cy = CENTRE
    glint = {(x, y) for x, y in outline if x in (SHAFT_X0, SHAFT_X0 + 1) and y in SHAFT_GLINT_ROWS}
    for x, y in outline:
        if x < cx and y < cy:
            angle = math.degrees(math.atan2(y + 0.5 - cy, x + 0.5 - cx))
            if ARC_GLINT_DEGREES[0] <= angle <= ARC_GLINT_DEGREES[1]:
                glint.add((x, y))
    for x in HEAD_GLINT_COLS:
        k = HEAD_TIP_X - x
        top = HEAD_ROW0 - k
        glint.update({(x, y) for y in range(top, top + 4)} & outline)
    roles["outline"] = outline - glint
    roles["glint"] = glint
    return roles


COLOURS = {
    "outline": INK, "glint": GLINT, "edge": GLINT, "light": BLUSH_LIGHT, "mid": BLUSH_MID, "shade": BLUSH_SHADE,
    "deep": BLUSH_DEEP, "body": BLUSH,
}


def arrow() -> Image.Image:
    """The script-drawn curved arrow, straight from above."""
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = im.load()
    for role, cells in layers().items():
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


def polish(im: Image.Image) -> Image.Image:
    """Repaint every role but the plain body from layers(), so the outline is exactly near-black and the glints,
    rim light and shade steps are the script's; PixelLab's body pixels stay where they are opaque."""
    im = im.convert("RGBA")
    if im.size != (SIZE, SIZE):
        im = im.resize((SIZE, SIZE), Image.NEAREST)
    px = im.load()
    shape = arrow_cells()
    for y in range(SIZE):
        for x in range(SIZE):
            if (x, y) not in shape:
                px[x, y] = (0, 0, 0, 0)
    for role, cells in layers().items():
        for x, y in cells:
            if role == "body":
                if px[x, y][3] != 255:
                    px[x, y] = BLUSH
            else:
                px[x, y] = COLOURS[role]
    return im


def finish(raw: Image.Image, do_polish: bool = True, reduce: bool = True) -> Image.Image:
    """The free fixes on a PixelLab result, keeping its pixels wherever they can stay."""
    im = raw.convert("RGBA")
    if im.size != (SIZE, SIZE):
        im = im.resize((SIZE, SIZE), Image.NEAREST)
    shape = arrow()
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
        im = polish(im)
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
    args = p.parse_args(argv)

    if args.cmd == "init":
        save_png(arrow(), Path(args.out))
    elif args.cmd == "request":
        body = request(Path(args.init).read_bytes(), args.strength, args.seed)
        Path(args.out).parent.mkdir(parents=True, exist_ok=True)
        Path(args.out).write_text(json.dumps(body) + "\n", encoding="utf-8")
    elif args.cmd == "finish":
        with Image.open(args.raw) as raw:
            im = finish(raw, not args.no_polish, not args.no_reduce)
        save_png(im, Path(args.out))
    elif args.cmd == "polish":
        with Image.open(args.src) as src:
            im = reduce_image(polish(src), 30)
        save_png(im, Path(args.out))
    else:
        with Image.open(args.src) as src:
            save_png(preview_image(src, args.scale), Path(args.out))
    print("wrote", args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
