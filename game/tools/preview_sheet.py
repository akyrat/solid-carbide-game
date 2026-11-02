"""Enlarged nearest-neighbour preview of a sheet on a dark street and a pale roof colour (T-509, review only).

    python game/tools/preview_sheet.py <in.png> <out.png> [scale]
"""
import sys
from pathlib import Path

from PIL import Image

DARK = (38, 44, 58, 255)     # wet street, dark blue-grey
LIGHT = (176, 184, 196, 255)  # pale steel rooftop


def preview(src: Path, out: Path, scale: int = 12) -> None:
    im = Image.open(src).convert("RGBA")
    big = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    pad = scale
    canvas = Image.new("RGBA", (big.width + 2 * pad, 2 * big.height + 3 * pad), DARK)
    canvas.paste(Image.new("RGBA", (canvas.width, big.height + 2 * pad), LIGHT), (0, big.height + pad))
    canvas.alpha_composite(big, (pad, pad))
    canvas.alpha_composite(big, (pad, big.height + 2 * pad))
    canvas.save(out)


if __name__ == "__main__":
    preview(Path(sys.argv[1]), Path(sys.argv[2]), int(sys.argv[3]) if len(sys.argv) > 3 else 12)
