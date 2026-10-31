"""Draws a review sheet of the four power-up icons, enlarged 8x on a dark and a light background.

  python game/tools/power_up_icon_sheet.py [out.png]
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
IDS = ["rev_charge", "jump", "bouncy_bumpers", "rusty_overcoat"]
SCALE = 8


def build_sheet(art_dir: Path) -> Image.Image:
    size = 32 * SCALE
    sheet = Image.new("RGBA", (size * len(IDS), size * 2), (0, 0, 0, 255))
    for row, bg in enumerate(((24, 26, 34, 255), (225, 225, 230, 255))):
        for col, name in enumerate(IDS):
            icon = Image.open(art_dir / f"{name}.png").convert("RGBA")
            icon = icon.resize((icon.width * SCALE, icon.height * SCALE), Image.NEAREST)
            tile = Image.new("RGBA", (size, size), bg)
            tile.alpha_composite(icon, ((size - icon.width) // 2, (size - icon.height) // 2))
            sheet.paste(tile, (col * size, row * size))
    return sheet


if __name__ == "__main__":
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "art-archive/T-465/screenshots/icons_sheet.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    build_sheet(ROOT / "game/art/power_ups").save(out)
    print(out)
