"""Free check for T-584 frame 23: enlarged strips of a candidate next to live-sheet frames 21-25, plus pixel stats.

  python art-archive/T-584/tools_compare_frame23.py art-archive/T-584/style-loop/v1-2.png [tag]
Writes art-archive/T-584/screenshots/frame23_<tag>_compare_{dark,light}.png (nearest-neighbour x3).
"""
import sys
from pathlib import Path

from PIL import Image

F = 128
S = 3
REPO = Path(__file__).resolve().parents[2]


def stats(im):
    px = list(im.getdata())
    idx = [i for i, p in enumerate(px) if p[3] > 0]
    xs = [i % F for i in idx]
    ys = [i // F for i in idx]
    shadow = sum(1 for i in idx if px[i][3] < 255)
    return {"opaque_px": len(idx), "semi_transparent_px": shadow,
            "bbox": (min(xs), min(ys), max(xs), max(ys)), "colours": len(set(px))}


def main():
    cand = Path(sys.argv[1])
    tag = sys.argv[2] if len(sys.argv) > 2 else cand.stem
    sheet = Image.open(REPO / "game/art/car/car_iso.png").convert("RGBA")
    new = Image.open(cand).convert("RGBA")
    tiles = [("f21", sheet.crop((21 * F, 0, 22 * F, F))), ("f22", sheet.crop((22 * F, 0, 23 * F, F))),
             ("f23 old", sheet.crop((23 * F, 0, 24 * F, F))), ("f23 NEW", new),
             ("f24", sheet.crop((24 * F, 0, 25 * F, F))), ("f25", sheet.crop((25 * F, 0, 26 * F, F)))]
    out_dir = REPO / "art-archive/T-584/screenshots"
    out_dir.mkdir(parents=True, exist_ok=True)
    for bgname, bg in (("dark", (24, 24, 32, 255)), ("light", (220, 220, 220, 255))):
        out = Image.new("RGBA", (F * S * len(tiles), F * S), bg)
        for i, (_, t) in enumerate(tiles):
            big = t.resize((F * S, F * S), Image.NEAREST)
            out.paste(big, (i * F * S, 0), big)
        out.save(out_dir / f"frame23_{tag}_compare_{bgname}.png")
    print("candidate:", new.mode, new.size)
    for n, t in tiles:
        print(f"{n:8s}", stats(t))


if __name__ == "__main__":
    main()
