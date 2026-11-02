"""Inspect a 32x32 icon (colours, bbox, Greenbull colours) and write enlarged dark/light previews. T-503."""
import sys
from pathlib import Path
from PIL import Image

src = Path(sys.argv[1])
out = Path(sys.argv[2]) if len(sys.argv) > 2 else src.parent
im = Image.open(src).convert("RGBA")
px = [p for p in im.getdata() if p[3] > 0]
cols = {p[:3] for p in px}
print("size", im.size, "colours", len(cols), "bbox", im.getbbox(), "semi-transparent", sum(1 for p in px if p[3] < 255))
print("greenbull exact", [c for c in cols if c in ((104, 220, 96), (247, 208, 52))])
print("reddish", sorted(c for c in cols if c[0] > 150 and c[1] < 80 and c[2] < 80))
for bg, n in (((18, 16, 28), "dark"), ((235, 235, 235), "light")):
    b = Image.new("RGBA", im.size, bg + (255,))
    b.alpha_composite(im)
    b.resize((256, 256), Image.NEAREST).save(out / f"{src.stem}_prev_{n}.png")
