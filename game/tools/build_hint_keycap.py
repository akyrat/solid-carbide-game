"""The hint pieces' keycap icons (task T-577; Level design, Decisions, "Hint pieces in the level creator").

The W (hint_gas.png) and S (hint_brake.png) keycaps are flat top-down pictures of a keyboard key, 64 x 64 px,
laid on the isometric ground by the engine like a road marking (game/docs/level/hint-pieces.md, "The art").
Their look is the tutorial's keycap (scripts/menu/key_pad.gd): face #33384f, edge #1f2336, letter in blush
#f6c9de. This script does the free parts of the style loop around one PixelLab call per version:

    python game/tools/build_hint_keycap.py init OUT.png [--letter W]
        Draws the script keycap: the init image PixelLab starts from, and a fallback on its own.
    python game/tools/build_hint_keycap.py request OUT.json --init INIT.png [--letter W] [--strength N] [--seed N]
        Writes the create-image-pixflux request body (64 x 64, no background, the init image in base64).
    python game/tools/build_hint_keycap.py finish RAW.png OUT.png [--letter W] [--keep-letter] [--no-reduce]
        The free fixes on PixelLab's output: alpha snapped to 0 or 255, the canvas outside the keycap cleared,
        a clean pixel letter redrawn in blush (PixelLab draws letters badly; --keep-letter leaves its own),
        and the palette cut to at most 30 colours (reduce_palette.py). Saved as an 8-bit RGBA PNG.
    python game/tools/build_hint_keycap.py polish IN.png OUT.png [--strong] [--letter S]
        The style loop's free fixes for rule 2 (T-577 v2): a two-step bevel on the face's top and left, a shade
        step on its bottom and right, and brighter highlight pixels breaking the outline at the top-left.
        --strong (v3) is the bolder pass that reads at 64 px, with a stepped blush glow round --letter (rule 5).
    python game/tools/build_hint_keycap.py preview IN.png OUT.png [--scale 6]
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

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from reduce_palette import preview_image, reduce_image  # noqa: E402

SIZE = 64

# The tutorial's keycap colours (scripts/menu/key_pad.gd) and the shades drawn from them.
INK = (0x0D, 0x0D, 0x1B, 255)          # the selective outline, near black
EDGE = (0x1F, 0x23, 0x36, 255)         # the key's side, bottom and right
EDGE_DEEP = (0x16, 0x19, 0x28, 255)    # the side's lowest band
FACE = (0x33, 0x38, 0x4F, 255)
FACE_LOW = (0x2C, 0x30, 0x45, 255)     # the face's lower band, in shade
FACE_RIM = (0x45, 0x4B, 0x6A, 255)     # the lit rim along the top and left of the face
FACE_GLINT = (0x6A, 0x72, 0x9C, 255)   # the highlight pixels that break the outline (rule 2)
HALO = (0x26, 0x2A, 0x3E, 255)         # a 1 px darker halo round the letter, so it reads
BLUSH = (0xF6, 0xC9, 0xDE, 255)
BLUSH_SHADE = (0xB7, 0x7B, 0x98, 255)  # the letter's lower edge (key_pad.gd LIT_EDGE)

# The keycap's boxes, inclusive pixel coordinates.
OUTLINE_BOX = (4, 4, 59, 59)
SIDE_BOX = (5, 5, 58, 58)
FACE_BOX = (5, 5, 55, 52)

# Bold pixel letters, drawn at 2 x 2 px per cell: 6 px strokes, the left half mirrored for the W.
LETTERS = {
    "W": [
        "111.............111",
        "111.............111",
        "111.............111",
        "111.............111",
        "111.............111",
        "111.............111",
        "111.....111.....111",
        "111.....111.....111",
        "111.....111.....111",
        ".111...11111...111.",
        ".111...11111...111.",
        ".111..111.111..111.",
        "..111.111.111.111..",
        "..111.111.111.111..",
        "..111111...111111..",
        "...11111...11111...",
        "...1111.....1111...",
    ],
    # The S keeps the W's 3-cell stroke everywhere (T-577: the first S thinned to 2 cells on the diagonal).
    "S": [
        "...1111111111111...",
        "..111111111111111..",
        ".1111..........111.",
        ".111...........111.",
        ".111...............",
        ".111...............",
        ".1111..............",
        "..11111111111......",
        "...11111111111111..",
        ".......1111111111..",
        "..............1111.",
        "...............111.",
        "...............111.",
        ".111...........111.",
        ".1111.........1111.",
        "..111111111111111..",
        "...1111111111111...",
    ],
}
CELL = 2


def letter_box(letter: str) -> tuple[int, int, int, int]:
    """Where the letter sits on the face (inclusive box), centred on the face."""
    rows = LETTERS[letter]
    w, h = len(rows[0]) * CELL, len(rows) * CELL
    cx = (FACE_BOX[0] + FACE_BOX[2] + 1) // 2
    cy = (FACE_BOX[1] + FACE_BOX[3] + 1) // 2
    x0, y0 = cx - w // 2, cy - h // 2
    return x0, y0, x0 + w - 1, y0 + h - 1


def letter_mask(letter: str) -> set[tuple[int, int]]:
    rows = LETTERS[letter]
    x0, y0, _, _ = letter_box(letter)
    cells = set()
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch == "1":
                for dy in range(CELL):
                    for dx in range(CELL):
                        cells.add((x0 + i * CELL + dx, y0 + j * CELL + dy))
    return cells


def draw_letter(im: Image.Image, letter: str, halo: bool = True) -> None:
    """The letter in blush with its lower edge in shade and, on the face, a 1 px darker halo."""
    px = im.load()
    cells = letter_mask(letter)
    if halo:
        for x, y in cells:
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    p = (x + dx, y + dy)
                    if p not in cells and 0 <= p[0] < im.width and 0 <= p[1] < im.height and px[p][3] == 255:
                        px[p] = HALO
    for x, y in cells:
        px[x, y] = BLUSH_SHADE if (x, y + 1) not in cells else BLUSH


def keycap(letter: str = "W") -> Image.Image:
    """The script-drawn keycap, straight from above: outline, side, face, rim light, letter."""
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle(OUTLINE_BOX, radius=9, fill=INK)
    d.rounded_rectangle(SIDE_BOX, radius=8, fill=EDGE)
    d.rectangle((8, 56, 55, 58), fill=EDGE_DEEP)
    d.rounded_rectangle(FACE_BOX, radius=7, fill=FACE)
    d.rectangle((FACE_BOX[0] + 1, 45, FACE_BOX[2] - 1, FACE_BOX[3]), fill=FACE_LOW)
    px = im.load()
    # The lit rim: the face's top row and left column.
    for x in range(9, 51):
        px[x, 6] = FACE_RIM
    for y in range(9, 44):
        px[6, y] = FACE_RIM
    for p in ((7, 8), (8, 7)):
        px[p] = FACE_RIM
    # Highlight pixels that break the outline, top-left where the light comes from (rule 2).
    for p in ((11, 5), (12, 5), (13, 5), (5, 11), (5, 12), (5, 13), (7, 7)):
        px[p] = FACE_GLINT
    draw_letter(im, letter)
    return im


def _png_bytes(im: Image.Image) -> bytes:
    b = io.BytesIO()
    im.convert("RGBA").save(b, format="PNG")
    return b.getvalue()


def save_png(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(_png_bytes(im))


def description(letter: str) -> str:
    return (
        f"one keyboard keycap seen straight from above, flat top-down view, a rounded square key filling the "
        f"canvas, dark slate blue-grey face, darker navy side visible as a thick band along the bottom and right "
        f"edge, near-black outline, a few lighter highlight pixels on the top-left rim, one big bold blocky pink "
        f"letter {letter} centred on the key face, clean 1-bit pixel letter with thick strokes, retro night arcade "
        f"look, crisp pixel art, no gradients, transparent background"
    )


NEGATIVE = "words, text, several keys, keyboard, hand, finger, drop shadow, blur, gradient, photo, 3d render, tilted"


def request(init_png: bytes, letter: str = "W", strength: int = 500, seed: int | None = None) -> dict:
    body = {
        "description": description(letter),
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


def inside_keycap(x: int, y: int) -> bool:
    """Whether a pixel lies inside the keycap's outline box (the rounded corners are judged by the drawing)."""
    return OUTLINE_BOX[0] <= x <= OUTLINE_BOX[2] and OUTLINE_BOX[1] <= y <= OUTLINE_BOX[3]


def finish(raw: Image.Image, letter: str = "W", redraw_letter: bool = True, reduce: bool = True) -> Image.Image:
    """The free fixes on a PixelLab result, keeping its pixels wherever they can stay."""
    im = raw.convert("RGBA")
    if im.size != (SIZE, SIZE):
        im = im.resize((SIZE, SIZE), Image.NEAREST)
    shape = keycap(letter)
    spx = shape.load()
    px = im.load()
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, a = px[x, y]
            if a < 128 or spx[x, y][3] == 0:
                px[x, y] = (0, 0, 0, 0)       # the canvas outside the keycap, and half pixels
            else:
                px[x, y] = (r, g, b, 255)
    # Pixels the shape has but PixelLab lost (cut-off corners) take the script's own pixel.
    for y in range(SIZE):
        for x in range(SIZE):
            if spx[x, y][3] == 255 and px[x, y][3] == 0:
                px[x, y] = spx[x, y]
    if redraw_letter:
        # Clear the letter's area to the face as the generated key paints it, then draw the clean letter.
        x0, y0, x1, y1 = letter_box(letter)
        face = _face_colour(im, letter)
        for y in range(y0 - 2, y1 + 3):
            for x in range(x0 - 2, x1 + 3):
                if 0 <= x < SIZE and 0 <= y < SIZE and px[x, y][3] == 255 and FACE_BOX[0] < x < FACE_BOX[2] and FACE_BOX[1] < y < FACE_BOX[3]:
                    px[x, y] = face
        draw_letter(im, letter)
    if reduce:
        im = reduce_image(im, 30)
    return im


FACE_RIM_2 = (0x3C, 0x41, 0x5C, 255)   # the bevel's second step, between the rim and the face
GLINT_BRIGHT = (0x8C, 0x94, 0xC0, 255)  # the brightest glint, on the outline itself


RIM_BRIGHT = (0x5A, 0x62, 0x88, 255)   # the strong bevel's first step, brighter than FACE_RIM
GLOW_1 = (0x6E, 0x55, 0x78, 255)       # the blush glow's first ring round the letter (rule 5, stepped)
GLOW_2 = (0x4C, 0x45, 0x64, 255)       # its second ring, fading into the face


def polish(im: Image.Image, letter: str | None = None, strong: bool = False) -> Image.Image:
    """The free fixes the style loop asked for on the S keycap (rule 2): a stepped bevel along the face's top and
    left, a shade step along its bottom and right, and brighter highlight pixels that break the near-black outline
    at the top-left, where the light comes from. Letter pixels are never touched.

    T-577 v2 was the plain pass; `strong` (v3) reads at 64 px: a brighter three-step bevel, a two-pixel dark
    bottom/right edge, glints on the outline's corners too, and, with a `letter`, a two-ring blush glow round
    the glyph (rule 5, stepped, inside the sprite) in place of the dark halo."""
    im = im.convert("RGBA")
    px = im.load()
    x0, y0, x1, y1 = letter_box_any()
    cells = letter_mask(letter) if letter else set()

    def put(x: int, y: int, c: tuple[int, int, int, int]) -> None:
        if 0 <= x < SIZE and 0 <= y < SIZE and px[x, y][3] == 255 and not (x0 - 1 <= x <= x1 + 1 and y0 - 1 <= y <= y1 + 1):
            px[x, y] = c

    if strong:
        # The bevel: a bright rim on the face's first row and column, then two steps down to the face.
        for x in range(9, 51):
            put(x, 6, RIM_BRIGHT)
        for x in range(10, 49):
            put(x, 7, FACE_RIM)
        for x in range(11, 47):
            put(x, 8, FACE_RIM_2)
        for y in range(9, 44):
            put(6, y, RIM_BRIGHT)
        for y in range(10, 42):
            put(7, y, FACE_RIM)
        for y in range(11, 40):
            put(8, y, FACE_RIM_2)
        for p in ((7, 8), (8, 7)):
            put(*p, RIM_BRIGHT)
        put(8, 8, FACE_RIM)
        put(9, 9, FACE_RIM_2)
        # The dark edge: two pixels along the face's bottom and right, the outer one as dark as the side.
        for y in range(9, 53):
            put(FACE_BOX[2], y, EDGE)
            put(FACE_BOX[2] - 1, y, HALO)
        for x in range(9, FACE_BOX[2]):
            put(x, FACE_BOX[3], EDGE)
            put(x, FACE_BOX[3] - 1, HALO)
        # Highlights breaking the outline: a run on the top and left, and the rounded corners themselves.
        for x in range(9, 18):
            put(x, OUTLINE_BOX[1], GLINT_BRIGHT)
        for y in range(9, 18):
            put(OUTLINE_BOX[0], y, GLINT_BRIGHT)
        for p in ((5, 7), (6, 6), (7, 5), (6, 5), (5, 6)):
            put(*p, GLINT_BRIGHT)
        for p in ((10, 5), (11, 5), (12, 5), (13, 5), (14, 5), (15, 5), (5, 10), (5, 11), (5, 12), (5, 13), (5, 14), (5, 15), (7, 7)):
            put(*p, FACE_GLINT)
        for p in ((51, 4), (52, 4), (53, 4), (4, 51), (4, 52), (4, 53), (57, 7), (7, 57)):
            put(*p, FACE_GLINT)
    else:
        for x in range(9, 51):
            put(x, 6, FACE_RIM)
        for x in range(10, 49):
            put(x, 7, FACE_RIM_2)
        for y in range(9, 44):
            put(6, y, FACE_RIM)
        for y in range(10, 42):
            put(7, y, FACE_RIM_2)
        for p in ((7, 8), (8, 7)):
            put(*p, FACE_RIM)
        put(8, 8, FACE_RIM_2)
        for y in range(9, 52):
            put(FACE_BOX[2], y, HALO)
        for x in range(9, FACE_BOX[2]):
            put(x, FACE_BOX[3], HALO)
        for x in range(10, 16):
            put(x, OUTLINE_BOX[1], GLINT_BRIGHT)
        for y in range(10, 16):
            put(OUTLINE_BOX[0], y, GLINT_BRIGHT)
        for p in ((11, 5), (12, 5), (13, 5), (14, 5), (5, 11), (5, 12), (5, 13), (5, 14)):
            put(*p, FACE_GLINT)
        for p in ((6, 5), (5, 6), (7, 7)):
            put(*p, FACE_GLINT)

    if strong and cells:
        # The stepped blush glow round the letter: ring 1 touches the glyph, ring 2 is one pixel further out.
        ring1 = {(x + dx, y + dy) for x, y in cells for dx in (-1, 0, 1) for dy in (-1, 0, 1)} - cells
        ring2 = {(x + dx, y + dy) for x, y in ring1 for dx in (-1, 0, 1) for dy in (-1, 0, 1)} - cells - ring1
        for ring, colour in ((ring1, GLOW_1), (ring2, GLOW_2)):
            for x, y in ring:
                if FACE_BOX[0] < x < FACE_BOX[2] - 1 and FACE_BOX[1] < y < FACE_BOX[3] - 1 and px[x, y][3] == 255 and not _is_blush(px[x, y]):
                    px[x, y] = colour
    return im


def _is_blush(c: tuple[int, int, int, int]) -> bool:
    """Whether a generated pixel is part of the letter (blush or its shade), so the glow never paints over it."""
    r, g, b, _ = c
    return r > 150 and r > b > g


def letter_box_any() -> tuple[int, int, int, int]:
    """The union of every letter's box: the area polish never touches."""
    boxes = [letter_box(letter) for letter in LETTERS]
    return (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))


def _face_colour(im: Image.Image, letter: str) -> tuple[int, int, int, int]:
    """The most common opaque colour just outside the letter's box: the generated face."""
    px = im.load()
    x0, y0, x1, y1 = letter_box(letter)
    counts: dict[tuple[int, int, int, int], int] = {}
    for y in range(y0 - 4, y1 + 5):
        for x in range(x0 - 4, x1 + 5):
            if (x0 - 2 <= x <= x1 + 2 and y0 - 2 <= y <= y1 + 2) or not (0 <= x < SIZE and 0 <= y < SIZE):
                continue
            c = px[x, y]
            if c[3] == 255:
                counts[c] = counts.get(c, 0) + 1
    return max(counts, key=counts.get) if counts else FACE


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("init", help="draw the script keycap")
    a.add_argument("out")
    a.add_argument("--letter", default="W", choices=sorted(LETTERS))
    r = sub.add_parser("request", help="write the pixflux request body")
    r.add_argument("out")
    r.add_argument("--init", required=True)
    r.add_argument("--letter", default="W", choices=sorted(LETTERS))
    r.add_argument("--strength", type=int, default=500)
    r.add_argument("--seed", type=int)
    f = sub.add_parser("finish", help="free fixes on PixelLab's output")
    f.add_argument("raw")
    f.add_argument("out")
    f.add_argument("--letter", default="W", choices=sorted(LETTERS))
    f.add_argument("--keep-letter", action="store_true")
    f.add_argument("--no-reduce", action="store_true")
    q = sub.add_parser("polish", help="bevel, shade step and outline-breaking glints on a finished keycap")
    q.add_argument("src")
    q.add_argument("out")
    q.add_argument("--letter", choices=sorted(LETTERS), help="the glyph, for the blush glow (with --strong)")
    q.add_argument("--strong", action="store_true", help="the bolder pass that reads at 64 px (T-577 v3)")
    v = sub.add_parser("preview", help="enlarged preview on dark and light")
    v.add_argument("src")
    v.add_argument("out")
    v.add_argument("--scale", type=int, default=6)
    args = p.parse_args(argv)

    if args.cmd == "init":
        save_png(keycap(args.letter), Path(args.out))
    elif args.cmd == "request":
        body = request(Path(args.init).read_bytes(), args.letter, args.strength, args.seed)
        Path(args.out).parent.mkdir(parents=True, exist_ok=True)
        Path(args.out).write_text(json.dumps(body) + "\n", encoding="utf-8")
    elif args.cmd == "finish":
        with Image.open(args.raw) as raw:
            im = finish(raw, args.letter, not args.keep_letter, not args.no_reduce)
        save_png(im, Path(args.out))
    elif args.cmd == "polish":
        with Image.open(args.src) as src:
            im = reduce_image(polish(src, args.letter, args.strong), 30)
        save_png(im, Path(args.out))
    else:
        with Image.open(args.src) as src:
            save_png(preview_image(src, args.scale), Path(args.out))
    print("wrote", args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
