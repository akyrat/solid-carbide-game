"""Puts the bottom centre of the four combo heat screenshots (task T-131) one
under the other, enlarged 2x with nearest neighbour, in <dir>/combo_heat_steps.png.

Usage: python game/tools/combo_heat_strip.py <dir with combo_heat_*.png>
"""
import sys
from pathlib import Path

from PIL import Image

STEPS = ["base", "step1", "step2", "step3"]
SCALE = 2


def crop_bottom(img: Image.Image) -> Image.Image:
    """The bottom centre: the combo counter, the likes row and the likes bar."""
    w, h = img.size
    box_h = min(150, h)
    return img.crop((w // 4 - 16, h - box_h, w - w // 4 + 16, h))


def build(folder: Path) -> Path:
    parts = [crop_bottom(Image.open(folder / f"combo_heat_{s}.png").convert("RGB")) for s in STEPS]
    w = max(p.width for p in parts)
    gap = 6
    sheet = Image.new("RGB", (w, sum(p.height for p in parts) + gap * (len(parts) - 1)), (40, 40, 40))
    y = 0
    for p in parts:
        sheet.paste(p, (0, y))
        y += p.height + gap
    sheet = sheet.resize((sheet.width * SCALE, sheet.height * SCALE), Image.NEAREST)
    out = folder / "combo_heat_steps.png"
    sheet.save(out)
    return out


if __name__ == "__main__":
    print(build(Path(sys.argv[1] if len(sys.argv) > 1 else "screenshots")))
