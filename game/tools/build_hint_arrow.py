"""The hint pieces' arrow icons (task T-577; Level design, Decisions, "Hint pieces in the level creator").

The straight arrow (hint_arrow_straight.png) is a flat top-down road-marking arrow pointing straight up the
picture, 64 x 64 px, laid on the isometric ground by the engine like painted paint (game/docs/level/hint-pieces.md,
"The art"). Its colours are the keycaps' letter colours: blush #f6c9de with a lighter highlight on the top-left
edges, a darker shade #b77b98 on the lower-right edges and a near-black selective outline, broken by a few
highlight pixels where the light comes from (Visual style, Content, "Rules", rule 2). This script does the free
parts of the style loop around one PixelLab call per version, like build_hint_keycap.py does for the keycaps:

    python game/tools/build_hint_arrow.py init OUT.png
        Draws the script arrow: the init image PixelLab starts from, and a fallback on its own.
    python game/tools/build_hint_arrow.py request OUT.json --init INIT.png [--strength N] [--seed N]
        Writes the create-image-pixflux request body (64 x 64, no background, the init image in base64).
    python game/tools/build_hint_arrow.py finish RAW.png OUT.png [--snap] [--no-reduce]
        The free fixes on PixelLab's output: alpha snapped to 0 or 255, the canvas outside the arrow cleared,
        arrow pixels PixelLab lost filled from the script's own, the palette cut to at most 30 colours
        (reduce_palette.py), or with --snap every pixel mapped to the script's six colours. 8-bit RGBA PNG.
    python game/tools/build_hint_arrow.py polish IN.png OUT.png [--bold]
        The style loop's free fixes for rule 2 and rule 4 (T-577 v2) on a finished arrow: the outline snapped to
        exact near-black with longer highlight runs breaking it, a two-pixel rim light with a near-white edge on
        the upper-left, two-step shade bands on the lower-right, worn-paint specks, and a two-ring stepped glow
        halo outside the outline (rule 5). PixelLab's plain body pixels stay. --bold (v3) reads at native 64 px:
        a two-pixel near-black outline with no halo, longer near-white runs breaking it, three shade steps.
    python game/tools/build_hint_arrow.py preview IN.png OUT.png [--scale 6]
        An enlarged preview (nearest-neighbour) on a dark and a light background, for the board.

Nothing here calls PixelLab: the paid call is game/tools/pixellab_client.py, inside the style loop. Needs Pillow.
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from reduce_palette import preview_image, reduce_image  # noqa: E402

SIZE = 64

# The keycaps' letter colours (build_hint_keycap.py) and the shades drawn from them.
INK = (0x0D, 0x0D, 0x1B, 255)          # the selective outline, near black
BLUSH = (0xF6, 0xC9, 0xDE, 255)        # the body
BLUSH_LIGHT = (0xFF, 0xEA, 0xF3, 255)  # the highlight along the top-left edges
BLUSH_MID = (0xDE, 0xA8, 0xC4, 255)    # the shade's inner step
BLUSH_SHADE = (0xB7, 0x7B, 0x98, 255)  # the shade along the lower-right edges (key_pad.gd LIT_EDGE)
GLINT = (0xFF, 0xF7, 0xFB, 255)        # the brightest pixels, breaking the outline where the light hits
PALETTE = (INK, BLUSH, BLUSH_LIGHT, BLUSH_MID, BLUSH_SHADE, GLINT)

# The arrow's geometry, inclusive pixel coordinates: about 40 x 56 px, centred on the canvas.
HEAD_TOP = 4        # the tip's row
HEAD_ROWS = 20      # the head's height; its edges run at 45 degrees (2 px wider every row)
SHAFT_X0, SHAFT_X1 = 24, 39   # the shaft, 16 px wide, centred between columns 31 and 32
BOTTOM = 59         # the shaft's last row

# Outline pixels that become highlight pixels (rule 2): a run on the head's left edge and one on the shaft's left.
GLINT_ROWS = range(HEAD_TOP + 5, HEAD_TOP + 9)
SHAFT_GLINT_ROWS = range(HEAD_TOP + HEAD_ROWS + 2, HEAD_TOP + HEAD_ROWS + 8)


def arrow_cells() -> set[tuple[int, int]]:
    """Every pixel of the arrow's silhouette, outline included."""
    cells = set()
    for k in range(HEAD_ROWS):
        y = HEAD_TOP + k
        for x in range(31 - k, 33 + k):
            cells.add((x, y))
    for y in range(HEAD_TOP + HEAD_ROWS, BOTTOM + 1):
        for x in range(SHAFT_X0, SHAFT_X1 + 1):
            cells.add((x, y))
    return cells


def layers() -> dict[str, set[tuple[int, int]]]:
    """The arrow's pixels by colour role: outline, glint (outline pixels lit), light, mid, shade, body."""
    cells = arrow_cells()

    def nbrs8(p):
        x, y = p
        return [(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if (dx, dy) != (0, 0)]

    outline = {p for p in cells if any(q not in cells for q in nbrs8(p))}
    body = cells - outline
    # Lit edges face the top-left: a pixel under the outline is lit unless it also sits against the right edge.
    light = {(x, y) for x, y in body
             if (x - 1, y) in outline or ((x, y - 1) in outline and (x + 1, y) not in outline)}
    shade = {(x, y) for x, y in body if ((x + 1, y) in outline or (x, y + 1) in outline) and (x, y) not in light}
    mid = {(x, y) for x, y in body - light - shade if (x + 1, y) in shade or (x, y + 1) in shade}
    glint = set()
    for y in GLINT_ROWS:
        k = y - HEAD_TOP
        glint.update({(31 - k, y), (32 - k, y)} & outline)
    for y in SHAFT_GLINT_ROWS:
        glint.add((SHAFT_X0, y))
    glint &= outline
    return {
        "outline": outline - glint, "glint": glint, "light": light, "mid": mid, "shade": shade,
        "body": body - light - mid - shade,
    }


def arrow() -> Image.Image:
    """The script-drawn straight arrow, straight from above."""
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = im.load()
    colours = {
        "outline": INK, "glint": GLINT, "light": BLUSH_LIGHT, "mid": BLUSH_MID, "shade": BLUSH_SHADE, "body": BLUSH,
    }
    for role, cells in layers().items():
        for x, y in cells:
            px[x, y] = colours[role]
    # The shaft's lit edge: the brightest glint sits one pixel in from the outline run it breaks.
    for y in SHAFT_GLINT_ROWS:
        px[SHAFT_X0 + 1, y] = BLUSH_LIGHT
    return im


GLOW_1 = (0x7A, 0x42, 0x68, 255)   # the drawn glow's first ring outside the outline (rule 5, stepped)
GLOW_2 = (0x42, 0x28, 0x42, 255)   # its second ring, fading into the asphalt

# Worn-paint specks on the plain body, for a little retro road-marking detail (rule 2, rule 4).
WEAR = ((33, 14), (29, 18), (30, 18), (36, 20), (28, 34), (29, 34), (36, 30), (35, 41), (27, 40),
        (30, 47), (31, 47), (34, 52))
STRONG_GLINT_ROWS = range(HEAD_TOP + 3, HEAD_TOP + 11)
STRONG_SHAFT_GLINT_ROWS = range(HEAD_TOP + HEAD_ROWS + 2, HEAD_TOP + HEAD_ROWS + 12)


BLUSH_DEEP = (0x96, 0x58, 0x7A, 255)   # the bold pass's deepest shade step, right against the outline
BOLD_GLINT_ROWS = range(HEAD_TOP + 3, HEAD_TOP + 13)
BOLD_SHAFT_GLINT_ROWS = range(HEAD_TOP + HEAD_ROWS + 2, HEAD_TOP + HEAD_ROWS + 14)


def strong_layers(bold: bool = False) -> dict[str, set[tuple[int, int]]]:
    """The polished arrow's pixels by role (T-577 v2, the style loop's rule 2 fixes): the outline with longer
    glint runs breaking it, a two-pixel rim light with a near-white edge on the upper-left, two-step shade bands
    on the lower-right, and a two-ring glow halo outside the outline.

    `bold` (v3) is the pass that reads at native 64 px: a two-pixel exact near-black outline and no outer halo
    (at 64 px the halo read as a purple-tinted outline), longer near-white runs breaking the outline on the head's
    left slope and the shaft's left, and three stepped shade colours (deep, shade, mid) on the lower-right."""
    cells = arrow_cells()

    def nbrs8(p):
        x, y = p
        return [(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if (dx, dy) != (0, 0)]

    outline = {p for p in cells if any(q not in cells for q in nbrs8(p))}
    body = cells - outline
    if bold:
        inner = {p for p in body if any(q in outline for q in nbrs8(p))}
        outline |= inner
        body -= inner
    light1 = {(x, y) for x, y in body
              if (x - 1, y) in outline or ((x, y - 1) in outline and (x + 1, y) not in outline)}
    light2 = {(x, y) for x, y in body - light1
              if ((x - 1, y) in light1 or (x, y - 1) in light1) and (x + 1, y) not in outline}
    rest = body - light1 - light2
    steps = []
    frontier = outline
    for _ in range(4):
        step = {(x, y) for x, y in rest if (x + 1, y) in frontier or (x, y + 1) in frontier}
        rest -= step
        steps.append(step)
        frontier = step
    if bold:
        deep, shade, mid = steps[0], steps[1], steps[2] | steps[3]
    else:
        deep, shade, mid = set(), steps[0] | steps[1], steps[2] | steps[3]
    # The near-white edge: the first lit pixel along the head's left slope.
    edge = {(x, y) for x, y in light1 if y < HEAD_TOP + HEAD_ROWS and (x - 1, y) in outline}
    glint = set()
    for y in (BOLD_GLINT_ROWS if bold else STRONG_GLINT_ROWS):
        k = y - HEAD_TOP
        glint.update({(31 - k, y), (32 - k, y), (33 - k, y), (34 - k, y)} & outline)
    shaft_cols = (SHAFT_X0, SHAFT_X0 + 1) if bold else (SHAFT_X0,)
    shaft_glint = {(x, y) for y in (BOLD_SHAFT_GLINT_ROWS if bold else STRONG_SHAFT_GLINT_ROWS) for x in shaft_cols} & outline
    if bold:
        ring1, ring2 = set(), set()
    else:
        ring1 = {q for p in cells for q in nbrs8(p) if q not in cells and 0 <= q[0] < SIZE and 0 <= q[1] < SIZE}
        ring2 = {q for p in ring1 for q in nbrs8(p)
                 if q not in cells and q not in ring1 and 0 <= q[0] < SIZE and 0 <= q[1] < SIZE}
    wear = {p for p in WEAR if p in rest}
    return {
        "outline": outline - glint - shaft_glint, "glint": glint, "shaft_glint": shaft_glint,
        "edge": edge, "light": (light1 | light2) - edge, "mid": mid, "shade": shade, "deep": deep,
        "wear": wear, "body": rest - wear, "glow1": ring1, "glow2": ring2,
    }


STRONG_COLOURS = {
    "outline": INK, "glint": GLINT, "shaft_glint": BLUSH_LIGHT, "edge": GLINT, "light": BLUSH_LIGHT,
    "mid": BLUSH_MID, "shade": BLUSH_SHADE, "deep": BLUSH_DEEP, "wear": BLUSH_MID, "glow1": GLOW_1, "glow2": GLOW_2,
}


def polish(im: Image.Image, bold: bool = False) -> Image.Image:
    """The free fixes on a finished arrow (T-577 v2, `bold` v3): every role but the plain body is repainted from
    strong_layers(), so PixelLab's body pixels stay where they can and the outline is exactly near-black."""
    im = im.convert("RGBA")
    if im.size != (SIZE, SIZE):
        im = im.resize((SIZE, SIZE), Image.NEAREST)
    px = im.load()
    if bold:
        shape = arrow_cells()
        for y in range(SIZE):
            for x in range(SIZE):
                if (x, y) not in shape:
                    px[x, y] = (0, 0, 0, 0)   # no halo: anything outside the silhouette goes
    for role, cells in strong_layers(bold).items():
        if role == "body":
            for x, y in cells:
                if px[x, y][3] != 255:
                    px[x, y] = BLUSH
            continue
        for x, y in cells:
            px[x, y] = STRONG_COLOURS[role]
    return im


def _png_bytes(im: Image.Image) -> bytes:
    b = io.BytesIO()
    im.convert("RGBA").save(b, format="PNG")
    return b.getvalue()


def save_png(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(_png_bytes(im))


DESCRIPTION = (
    "one bold straight arrow road marking seen straight from above, flat top-down view, pointing straight up, "
    "a thick straight shaft and a wide triangular head, painted in pale pink, lighter highlight along the "
    "top-left edges, dusky darker pink shade along the lower-right edges, near-black outline, slightly worn "
    "paint texture, retro night arcade look, crisp pixel art, no gradients, transparent background"
)

NEGATIVE = (
    "text, letters, words, road, asphalt, background, keycap, button, box, frame, several arrows, curved, bent, "
    "drop shadow, blur, gradient, photo, 3d render, tilted, perspective"
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


def nearest(colour: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    """The script palette colour nearest to a pixel (RGB distance)."""
    r, g, b, _ = colour
    return min(PALETTE, key=lambda c: (c[0] - r) ** 2 + (c[1] - g) ** 2 + (c[2] - b) ** 2)


def finish(raw: Image.Image, snap: bool = False, reduce: bool = True) -> Image.Image:
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
            elif snap:
                px[x, y] = nearest((r, g, b, a))
            else:
                px[x, y] = (r, g, b, 255)
    # Pixels the shape has but PixelLab lost take the script's own pixel.
    for y in range(SIZE):
        for x in range(SIZE):
            if spx[x, y][3] == 255 and px[x, y][3] == 0:
                px[x, y] = spx[x, y]
    if reduce and not snap:
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
    f.add_argument("--snap", action="store_true", help="map every pixel to the script's six colours")
    f.add_argument("--no-reduce", action="store_true")
    q = sub.add_parser("polish", help="rule 2 fixes: stepped shade, rim light, glints breaking the outline, glow halo")
    q.add_argument("src")
    q.add_argument("out")
    q.add_argument("--bold", action="store_true", help="the pass that reads at native 64 px (T-577 v3)")
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
            im = finish(raw, args.snap, not args.no_reduce)
        save_png(im, Path(args.out))
    elif args.cmd == "polish":
        with Image.open(args.src) as src:
            im = reduce_image(polish(src, args.bold), 30)
        save_png(im, Path(args.out))
    else:
        with Image.open(args.src) as src:
            save_png(preview_image(src, args.scale), Path(args.out))
    print("wrote", args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
