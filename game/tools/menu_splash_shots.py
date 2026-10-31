"""Makes a bright test image for the splash slot: python game/tools/menu_splash_shots.py make|remove

`make` writes game/art/menu/splash.png (a stripy 320 x 180 picture) for a screenshot;
`remove` deletes it again. The real splash comes from a later Asset Generation ticket.
"""
import sys
from pathlib import Path

from PIL import Image

PATH = Path(__file__).resolve().parent.parent / "art" / "menu" / "splash.png"


def main() -> int:
    if sys.argv[1:] == ["make"]:
        PATH.parent.mkdir(parents=True, exist_ok=True)
        img = Image.new("RGB", (320, 180))
        px = img.load()
        for y in range(180):
            for x in range(320):
                band = ((x // 16) + (y // 16)) % 2
                px[x, y] = (230, 120 + y // 3, 40) if band else (60, 40 + x // 3, 160)
        img.save(PATH)
    elif sys.argv[1:] == ["remove"]:
        PATH.unlink(missing_ok=True)
        for f in PATH.parent.glob("splash.png.import"):
            f.unlink()
    else:
        print(__doc__)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
