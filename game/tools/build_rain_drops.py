"""T-509: build the rain's raindrop sheet (3 variants of 8 x 16 in one 24 x 16 row).

PixelLab's 32 x 32 draw (art-archive/T-509/style-loop/v1_raw.png) gave round, upright teardrops 3 to 4 px
wide, not slanted streaks, so the streaks are placed pixel by pixel here using only colours sampled from that
PixelLab image. Nothing is scaled. The drop falls down and to the left: its top (the fading tail) leans right,
its bottom (the bright head) is lower left, one pixel sideways every 3 rows (about 18 degrees).

    python game/tools/build_rain_drops.py --src art-archive/T-509/style-loop/v1_raw.png --out <png>
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

FRAME_W, FRAME_H, FRAMES = 8, 16, 3

# Colour keys -> the PixelLab pixel they are sampled from (x, y in v1_raw.png).
SAMPLES = {
    "D": (15, 13),  # near white-blue (242,245,249): the head
    "F": (16, 16),  # pale blue-white (210,231,245)
    "A": (23, 4),   # pale cyan-blue (168,227,240)
    "E": (8, 21),   # pale blue (169,208,240)
    "C": (14, 16),  # mid blue (160,199,236)
    "B": (21, 10),  # blue-grey (107,117,177)
    "G": (16, 15),  # darker blue-grey (98,105,165)
    "H": (24, 7),   # darkest tail (88,94,156)
}

# Each variant: list of (row, x, key); x is the frame column. Tail (dark) at the top, head (bright) at the bottom.
def _streak(top: int, x_top: int, keys: str, wide: str = "") -> list[tuple[int, int, str]]:
    """A 1-px streak from row `top` down, stepping one column left every 3 rows. `wide` gives, per row,
    a second key for the pixel just right of the streak ('.' for none)."""
    px = []
    for i, k in enumerate(keys):
        y = top + i
        x = x_top - i // 3
        px.append((y, x, k))
        if i < len(wide) and wide[i] != ".":
            px.append((y, x + 1, wide[i]))
    return px


VARIANTS = [
    # 1: thin streak, 12 rows, 1 px wide.
    _streak(2, 6, "HHGGBBCCEAFD"),
    # 2: thicker and longer, 14 rows, 2 px wide through the body.
    _streak(1, 6, "HGGBBCCEEAAFFD", "....HGGBBCC..."),
    # 3: short bright streak, 7 rows.
    _streak(5, 5, "BCEAFDD"),
]


def build(src: Path) -> Image.Image:
    raw = Image.open(src).convert("RGBA")
    pal = {k: raw.getpixel(xy) for k, xy in SAMPLES.items()}
    for k, c in pal.items():
        if c[3] != 255:
            raise ValueError(f"sample {k} at {SAMPLES[k]} is not opaque: {c}")
    sheet = Image.new("RGBA", (FRAME_W * FRAMES, FRAME_H), (0, 0, 0, 0))
    for f, pixels in enumerate(VARIANTS):
        for y, x, k in pixels:
            if not (0 <= x < FRAME_W and 0 <= y < FRAME_H):
                raise ValueError(f"variant {f + 1} pixel ({x},{y}) is outside the frame")
            sheet.putpixel((f * FRAME_W + x, y), pal[k])
    return sheet


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--src", required=True, help="PixelLab image the colours are sampled from")
    ap.add_argument("--out", required=True, help="output PNG (8-bit RGBA)")
    a = ap.parse_args(argv)
    out = Path(a.out)
    if out.exists():
        raise SystemExit(f"{out} exists; never overwrite a version")
    out.parent.mkdir(parents=True, exist_ok=True)
    build(Path(a.src)).save(out)
    print(f"saved {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
