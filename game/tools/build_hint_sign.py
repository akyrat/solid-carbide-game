"""The hint pieces' roadside sign (task T-577; Level design, Decisions, "Hint pieces in the level creator").

hint_sign.png is a small standing sign, 64 x 96 px, seen in the game's 3/4 isometric view: a blank square board
on a metal post with a small base. The engine draws the hint icon on the board's face by script (fitted into
face_px, x 8..55 and y 8..55, game/data/level/hints.json) and stands the post's foot, pixel (32, 95), on the piece's
cell (game/docs/level/hint-pieces.md, "The art"). The board's look is the keycaps' (build_hint_keycap.py: face
#33384f) with a lighter steel frame; the post and base take the street lamp's cool steel (game/art/props). This
script does the free parts of the style loop around one PixelLab call per version:

    python game/tools/build_hint_sign.py init OUT.png
        Draws the script sign: the init image PixelLab starts from, and a fallback on its own.
    python game/tools/build_hint_sign.py request OUT.json --init INIT.png [--strength N] [--seed N]
        Writes the create-image-pixflux request body (64 x 96, no background, the init image in base64).
    python game/tools/build_hint_sign.py finish RAW.png OUT.png [--no-polish] [--keep-face] [--no-reduce]
        The free fixes on PixelLab's output: alpha snapped to 0 or 255, the canvas outside the sign cleared,
        pixels PixelLab lost refilled from the script, the board's face blanked again (PixelLab likes to draw
        on it; --keep-face leaves its paint), the script's outline, glint and frame roles repainted over
        PixelLab's render (--no-polish keeps its pixels), and the palette cut to at most 30 colours.
    python game/tools/build_hint_sign.py roles
        Prints how many pixels each drawing role has, for the result notes.
    python game/tools/build_hint_sign.py preview IN.png OUT.png [--scale 6]
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

WIDTH, HEIGHT = 64, 96
SIZE = (WIDTH, HEIGHT)
FOOT = (32, 95)                       # anchor_px: the post's foot, bottom centre
FACE_PX = (8, 8, 55, 55)              # face_px as an inclusive box: the board, frame included

# The board: the keycaps' colours (build_hint_keycap.py) and a lighter steel frame round the face.
INK = (0x0D, 0x0D, 0x1B, 255)         # the selective outline, near black
FACE = (0x33, 0x38, 0x4F, 255)        # the blank face, RGB 51,56,79
FACE_LOW = (0x2C, 0x30, 0x45, 255)    # the frame's shadow on the face, top and left inside the frame
FRAME = (0x4E, 0x56, 0x78, 255)       # the frame, lighter than the face
FRAME_LIT = (0x6A, 0x72, 0x9C, 255)   # the frame's lit top and left
FRAME_DARK = (0x3C, 0x41, 0x5C, 255)  # the frame's bottom and right, in shade
GLINT = (0x8C, 0x94, 0xC0, 255)       # the highlight pixels that break the outline (rule 2)

# The post and base: the street lamp's cool steel (game/art/props/street_lamp_*_art.png).
STEEL = (0x44, 0x4F, 0x62, 255)
STEEL_LIT = (0x5D, 0x6A, 0x82, 255)
STEEL_DARK = (0x37, 0x45, 0x5D, 255)
STEEL_DEEP = (0x2D, 0x31, 0x57, 255)
AMBER = (0xEF, 0xAA, 0x52, 255)       # a small reflective band on the post (rule 7: small amber accents)
AMBER_DARK = (0xD0, 0x81, 0x50, 255)

# Boxes, inclusive pixel coordinates.
BOARD_OUTLINE = (7, 7, 56, 56)
FACE_INNER = (10, 10, 53, 53)         # the face inside the 2 px frame
BRACKET = (26, 57, 37, 60)            # the plate the post hangs from, under the board (outline included)
POST_X = (28, 35)                     # the post with its outline columns; steel on 29..34
POST_ROWS = (57, 89)                  # from under the board into the base plate
BAND_ROWS = (74, 77)                  # the reflective band
BASE_OUTLINE = (21, 86, 43, 95)       # the base plate's ellipse, its bottom at the foot
BASE_TOP = (23, 87, 41, 92)


def sign() -> Image.Image:
    """The script-drawn sign: board with frame and blank face, bracket, post, band, base plate."""
    im = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    px = im.load()

    # The base plate first, so the post is drawn over its top.
    d.ellipse(BASE_OUTLINE, fill=INK)
    d.ellipse((22, 87, 42, 94), fill=STEEL_DEEP)        # the plate's side
    d.ellipse(BASE_TOP, fill=STEEL_DARK)                # its top
    d.ellipse((24, 87, 38, 90), fill=STEEL)             # the lit part of the top, towards the light
    for p in ((25, 91), (39, 91)):                      # two bolts on the plate
        px[p] = STEEL_LIT

    # The post: outline columns, lit left, shade right.
    x0, x1 = POST_X
    y0, y1 = POST_ROWS
    d.rectangle((x0, y0, x1, y1), fill=INK)
    d.rectangle((x0 + 1, y0, x1 - 1, y1), fill=STEEL)
    d.rectangle((x0 + 1, y0, x0 + 1, y1), fill=STEEL_LIT)
    d.rectangle((x1 - 2, y0, x1 - 1, y1), fill=STEEL_DARK)
    d.rectangle((x1 - 1, y0, x1 - 1, y1), fill=STEEL_DEEP)
    # A joint ring and the collar at the foot.
    d.rectangle((x0 + 1, 68, x1 - 1, 68), fill=STEEL_DEEP)
    d.rectangle((x0 - 1, 84, x1 + 1, 88), fill=INK)
    d.rectangle((x0, 85, x1, 88), fill=STEEL_DARK)
    d.rectangle((x0, 85, x0, 88), fill=STEEL)
    d.rectangle((x1, 85, x1, 88), fill=STEEL_DEEP)
    # The reflective band, with its shade on the right.
    d.rectangle((x0 + 1, BAND_ROWS[0], x1 - 1, BAND_ROWS[1]), fill=AMBER)
    d.rectangle((x1 - 2, BAND_ROWS[0], x1 - 1, BAND_ROWS[1]), fill=AMBER_DARK)

    # The bracket under the board.
    d.rectangle(BRACKET, fill=INK)
    d.rectangle((BRACKET[0] + 1, BRACKET[1], BRACKET[2] - 1, BRACKET[3] - 1), fill=STEEL_DARK)
    d.rectangle((BRACKET[0] + 1, BRACKET[1], BRACKET[0] + 1, BRACKET[3] - 1), fill=STEEL)
    for p in ((29, 58), (34, 58)):                      # two bolts
        px[p] = STEEL_LIT

    # The board: outline, frame, face.
    d.rounded_rectangle(BOARD_OUTLINE, radius=2, fill=INK)
    d.rounded_rectangle(FACE_PX, radius=1, fill=FRAME)
    d.rectangle((8, 8, 55, 9), fill=FRAME_LIT)          # the frame's top
    d.rectangle((8, 8, 9, 55), fill=FRAME_LIT)          # and left, lit
    d.rectangle((8, 54, 55, 55), fill=FRAME_DARK)       # bottom
    d.rectangle((54, 8, 55, 55), fill=FRAME_DARK)       # and right, in shade
    px[8, 55] = FRAME
    px[55, 8] = FRAME
    px[8, 8] = GLINT                                    # the corner nearest the light
    d.rectangle(FACE_INNER, fill=FACE)
    d.rectangle((10, 10, 53, 10), fill=FACE_LOW)        # the frame's shadow on the face
    d.rectangle((10, 10, 10, 53), fill=FACE_LOW)
    # Highlight pixels that break the outline at the top-left, where the light comes from (rule 2).
    for p in ((11, 7), (12, 7), (13, 7), (14, 7), (7, 11), (7, 12), (7, 13), (7, 14), (36, 7), (37, 7)):
        px[p] = GLINT
    # A glint on the post's lit edge and the plate's rim too.
    for p in ((x0 + 1, 62), (x0 + 1, 63), (23, 89)):
        px[p] = GLINT
    return im


def roles() -> dict[str, int]:
    """How many pixels each colour role has in the script sign."""
    names = {
        INK: "ink", FACE: "face", FACE_LOW: "face_low", FRAME: "frame", FRAME_LIT: "frame_lit",
        FRAME_DARK: "frame_dark", GLINT: "glint", STEEL: "steel", STEEL_LIT: "steel_lit",
        STEEL_DARK: "steel_dark", STEEL_DEEP: "steel_deep", AMBER: "amber", AMBER_DARK: "amber_dark",
    }
    counts: dict[str, int] = {}
    for p in sign().getdata():
        if p[3] == 255:
            counts[names.get(p, "other")] = counts.get(names.get(p, "other"), 0) + 1
    return counts


def _png_bytes(im: Image.Image) -> bytes:
    b = io.BytesIO()
    im.convert("RGBA").save(b, format="PNG")
    return b.getvalue()


def save_png(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(_png_bytes(im))


DESCRIPTION = (
    "one small roadside sign post standing upright, seen in 3/4 isometric view from slightly above, a blank "
    "square sign board facing the camera with an empty plain dark slate blue-grey face and a thin lighter "
    "steel frame, nothing drawn on the board, the board mounted on a short thin grey steel pole with a small "
    "round metal base plate on the ground, a narrow amber reflective band on the pole, near-black outline, a "
    "few lighter highlight pixels on the top-left edges, night-time city street furniture, retro arcade look, "
    "crisp pixel art, no gradients, transparent background"
)

NEGATIVE = (
    "text, letters, words, symbol, icon, arrow, logo, picture on the board, drawing on the board, pattern on "
    "the board, several signs, two posts, road, ground, grass, background, drop shadow, blur, gradient, photo, "
    "3d render, green, yellow"
)


def request(init_png: bytes, strength: int = 500, seed: int | None = None) -> dict:
    body = {
        "description": DESCRIPTION,
        "negative_description": NEGATIVE,
        "image_size": {"width": WIDTH, "height": HEIGHT},
        "no_background": True,
        "text_guidance_scale": 8.0,
        "outline": "single color black outline",
        "shading": "detailed shading",
        "detail": "highly detailed",
        "view": "low top-down",
        "init_image": {"type": "base64", "base64": base64.b64encode(init_png).decode("ascii")},
        "init_image_strength": int(strength),
    }
    if seed is not None:
        body["seed"] = int(seed)
    return body


POLISH_ROLES = (INK, GLINT, FRAME_LIT, FRAME_DARK, FRAME, AMBER, AMBER_DARK)


def polish(im: Image.Image) -> Image.Image:
    """Repaints the script's outline, glints, frame and band over PixelLab's render, so the near-black
    outline is exact, the highlight pixels break it where the script put them and the frame reads as a
    frame; PixelLab's own pixels stay everywhere else (the post, the base, the face's texture if kept)."""
    out = im.convert("RGBA")
    px = out.load()
    spx = sign().load()
    for y in range(HEIGHT):
        for x in range(WIDTH):
            if spx[x, y] in POLISH_ROLES:
                px[x, y] = spx[x, y]
    return out


def blank_face(im: Image.Image) -> Image.Image:
    """The face inside the frame put back to the script's blank slate (the icon goes there)."""
    out = im.convert("RGBA")
    px = out.load()
    spx = sign().load()
    for y in range(FACE_INNER[1], FACE_INNER[3] + 1):
        for x in range(FACE_INNER[0], FACE_INNER[2] + 1):
            px[x, y] = spx[x, y]
    return out


def finish(raw: Image.Image, do_polish: bool = True, keep_face: bool = False, reduce: bool = True) -> Image.Image:
    """The free fixes on a PixelLab result, keeping its pixels wherever they can stay."""
    im = raw.convert("RGBA")
    if im.size != SIZE:
        im = im.resize(SIZE, Image.NEAREST)
    shape = sign()
    spx = shape.load()
    px = im.load()
    for y in range(HEIGHT):
        for x in range(WIDTH):
            r, g, b, a = px[x, y]
            if a < 128 or spx[x, y][3] == 0:
                px[x, y] = (0, 0, 0, 0)       # the canvas outside the sign, and half pixels
            else:
                px[x, y] = (r, g, b, 255)
    for y in range(HEIGHT):
        for x in range(WIDTH):
            if spx[x, y][3] == 255 and px[x, y][3] == 0:
                px[x, y] = spx[x, y]          # pixels the shape has but PixelLab lost
    if not keep_face:
        im = blank_face(im)
    if do_polish:
        im = polish(im)
    if reduce:
        im = reduce_image(im, 30)
    return im


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("init", help="draw the script sign")
    a.add_argument("out")
    r = sub.add_parser("request", help="write the pixflux request body")
    r.add_argument("out")
    r.add_argument("--init", required=True)
    r.add_argument("--strength", type=int, default=500)
    r.add_argument("--seed", type=int)
    f = sub.add_parser("finish", help="free fixes on PixelLab's output")
    f.add_argument("raw")
    f.add_argument("out")
    f.add_argument("--no-polish", action="store_true", help="keep PixelLab's outline, frame and band pixels")
    f.add_argument("--keep-face", action="store_true", help="keep PixelLab's paint on the face")
    f.add_argument("--no-reduce", action="store_true")
    sub.add_parser("roles", help="print the script sign's pixel counts per role")
    v = sub.add_parser("preview", help="enlarged preview on dark and light")
    v.add_argument("src")
    v.add_argument("out")
    v.add_argument("--scale", type=int, default=6)
    args = p.parse_args(argv)

    if args.cmd == "init":
        save_png(sign(), Path(args.out))
    elif args.cmd == "request":
        body = request(Path(args.init).read_bytes(), args.strength, args.seed)
        Path(args.out).parent.mkdir(parents=True, exist_ok=True)
        Path(args.out).write_text(json.dumps(body) + "\n", encoding="utf-8")
    elif args.cmd == "finish":
        with Image.open(args.raw) as raw:
            im = finish(raw, not args.no_polish, args.keep_face, not args.no_reduce)
        save_png(im, Path(args.out))
    elif args.cmd == "roles":
        for name, n in sorted(roles().items()):
            print(f"{name}: {n}")
        return 0
    else:
        with Image.open(args.src) as src:
            save_png(preview_image(src, args.scale), Path(args.out))
    print("wrote", args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
