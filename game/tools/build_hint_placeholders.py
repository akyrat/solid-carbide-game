"""Draws the placeholder art of the hint pieces (task T-576; Level design, Decisions, "Hint pieces in the
level creator"). No PixelLab: T-577 drops the PixelLab art over these files at the same paths and sizes
(game/data/level/hints.json, game/docs/level/hint-pieces.md).

- game/art/hints/hint_<icon>.png, 64 x 64 px, transparent: each icon seen from above, pointing up the
  picture (the way the car drives over it). The engine lays it flat on the isometric ground and turns it
  to the piece's heading, so one picture serves all 8 directions. The curved arrow turns right and the
  circular arrow goes clockwise; the mirror (M) flips them.
- game/art/hints/hint_sign.png, 64 x 96 px, transparent: the standing sign, a board on a post, its post's
  foot at (32, 95); the engine puts the icon on its face (face_px, 8, 8, 48 x 48).

Usage, from the repo root:

    python game/tools/build_hint_placeholders.py           # writes the PNGs
    python game/tools/build_hint_placeholders.py --check   # exits 1 when a PNG is missing or not its size (the art in the game, placeholder or T-577's)

Needs Pillow.
"""
from __future__ import annotations

import io
import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

GAME = Path(__file__).resolve().parent.parent
DATA = GAME / "data" / "level" / "hints.json"

# The tutorial's keycap colours (scripts/menu/key_pad.gd), and road paint.
KEY_FACE = (0x33, 0x38, 0x4F, 255)
KEY_EDGE = (0x1F, 0x23, 0x36, 255)
KEY_INK = (0xF6, 0xC9, 0xDE, 255)
PAINT = (0xF2, 0xEF, 0xE6, 255)
OUTLINE = (0x1F, 0x23, 0x36, 255)
SIGN_FACE = (0x2A, 0x3A, 0x6A, 255)
SIGN_RIM = (0xE9, 0xE4, 0xD4, 255)
POST = (0x6B, 0x6F, 0x80, 255)
POST_DARK = (0x45, 0x48, 0x58, 255)

# 5 x 7 pixel letters.
LETTERS = {
    "W": ["10001", "10001", "10001", "10101", "10101", "11011", "10001"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
}


def res_path(res: str) -> Path:
    return GAME / res.replace("res://", "")


def keycap(letter: str) -> Image.Image:
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((6, 6, 57, 57), radius=8, fill=KEY_EDGE)
    d.rounded_rectangle((9, 8, 54, 50), radius=6, fill=KEY_FACE)
    rows = LETTERS[letter]
    px = 5
    x0 = 32 - (5 * px) // 2
    y0 = 29 - (7 * px) // 2
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch == "1":
                d.rectangle((x0 + i * px, y0 + j * px, x0 + i * px + px - 1, y0 + j * px + px - 1), fill=KEY_INK)
    return im


def _poly(d: ImageDraw.ImageDraw, pts, width: int) -> None:
    """A thick painted line along pts with a dark outline."""
    d.line(pts, fill=OUTLINE, width=width + 4, joint="curve")
    d.line(pts, fill=PAINT, width=width, joint="curve")


def _head(d: ImageDraw.ImageDraw, tip, angle: float, size: float) -> None:
    """An arrow head with its tip at `tip`, pointing at `angle` (radians, screen: 0 right, -pi/2 up)."""
    ax, ay = math.cos(angle), math.sin(angle)
    sx, sy = -ay, ax
    base = (tip[0] - ax * size, tip[1] - ay * size)
    pts = [tip, (base[0] + sx * size * 0.8, base[1] + sy * size * 0.8), (base[0] - sx * size * 0.8, base[1] - sy * size * 0.8)]
    grown = []
    cx = sum(p[0] for p in pts) / 3.0
    cy = sum(p[1] for p in pts) / 3.0
    for p in pts:
        grown.append((cx + (p[0] - cx) * 1.35, cy + (p[1] - cy) * 1.35))
    d.polygon(grown, fill=OUTLINE)
    d.polygon(pts, fill=PAINT)


def arrow_straight() -> Image.Image:
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    _poly(d, [(32, 58), (32, 24)], 8)
    _head(d, (32, 6), -math.pi / 2, 18)
    return im


def arrow_curved() -> Image.Image:
    """Goes up, then turns right."""
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    pts = [(20, 60), (20, 40)]
    cx, cy, r = 38, 40, 18
    for k in range(0, 91, 10):
        a = math.radians(180 + k)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    pts.append((44, 22))
    _poly(d, pts, 8)
    _head(d, (60, 22), 0.0, 16)
    return im


def arrow_circular() -> Image.Image:
    """A ring going round clockwise, its head at the top pointing right."""
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy, r = 32, 34, 20
    pts = []
    for k in range(0, 301, 10):
        a = math.radians(-90 + 40 + k)  # starts right of the top, clockwise
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    _poly(d, pts, 7)
    end = math.radians(-90 + 40 + 300)
    tip = (cx + r * math.cos(end) + 12 * math.cos(end + math.pi / 2), cy + r * math.sin(end) + 12 * math.sin(end + math.pi / 2))
    _head(d, tip, end + math.pi / 2, 14)
    return im


def sign() -> Image.Image:
    im = Image.new("RGBA", (64, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((29, 54, 34, 95), fill=POST_DARK)
    d.rectangle((30, 54, 33, 95), fill=POST)
    d.rounded_rectangle((2, 2, 61, 61), radius=5, fill=OUTLINE)
    d.rounded_rectangle((4, 4, 59, 59), radius=4, fill=SIGN_RIM)
    d.rectangle((7, 7, 56, 56), fill=SIGN_FACE)
    return im


DRAWINGS = {
    "gas": lambda: keycap("W"),
    "brake": lambda: keycap("S"),
    "arrow-straight": arrow_straight,
    "arrow-curved": arrow_curved,
    "arrow-circular": arrow_circular,
}


def build() -> dict:
    data = json.loads(DATA.read_text(encoding="utf-8"))
    out = {}
    for icon in data["icons"]:
        out[res_path(icon["texture"])] = DRAWINGS[icon["id"]]()
    out[res_path(data["sign"]["texture"])] = sign()
    return out


def _png(im: Image.Image) -> bytes:
    b = io.BytesIO()
    im.save(b, format="PNG")
    return b.getvalue()


def main(argv) -> int:
    images = build()
    if "--check" in argv:
        bad = []
        for path, im in images.items():
            if not path.is_file():
                bad.append("%s: missing" % path.name)
                continue
            have = Image.open(path).convert("RGBA")
            if have.size != im.size:
                bad.append("%s: %s px, wants %s" % (path.name, have.size, im.size))
        for b in bad:
            print(b)
        print("OK" if not bad else "%d problem(s)" % len(bad))
        return 1 if bad else 0
    for path, im in images.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(_png(im))
        print("wrote", path.relative_to(GAME.parent))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
