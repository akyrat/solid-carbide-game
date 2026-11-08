"""T-584: enlarged comparison strips of a frame-3 candidate against its neighbours (free, no PixelLab).

  python art-archive/T-584/tools_compare_frame03.py art-archive/T-584/style-loop/v1.png
Writes <candidate>_compare_dark.png and _compare_light.png next to the candidate (3x nearest-neighbour).
"""
import sys
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[2]
F, S = 128, 3


def main(cand: Path):
    sheet = Image.open(REPO / "game/art/car/car_iso.png").convert("RGBA")
    new = Image.open(cand).convert("RGBA")
    print("candidate:", cand, new.mode, new.size, "colours:", len(set(new.getdata())))
    frame = lambda k: sheet.crop((k * F, 0, (k + 1) * F, F))
    tiles = [("f1", frame(1)), ("f2", frame(2)), ("f3 old", frame(3)), ("f3 NEW", new), ("f4", frame(4)), ("f5", frame(5))]
    for bgname, bg in (("dark", (24, 24, 32, 255)), ("light", (220, 220, 220, 255))):
        out = Image.new("RGBA", (F * S * len(tiles), F * S), bg)
        for i, (_, t) in enumerate(tiles):
            big = t.resize((F * S, F * S), Image.NEAREST)
            out.paste(big, (i * F * S, 0), big)
        path = cand.with_name(cand.stem + f"_compare_{bgname}.png")
        out.save(path)
        print("wrote", path)


if __name__ == "__main__":
    main(Path(sys.argv[1]))
