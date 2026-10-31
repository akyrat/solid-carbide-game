"""T-399 helper: enlarge a crop of a sheet on a light background (nearest neighbour), for checking curb pixels.

  python art-archive/T-399/zoom_crop.py <sheet.png> <out.png> x y w h [scale]
"""
import sys

from PIL import Image

im = Image.open(sys.argv[1]).convert("RGBA")
x, y, w, h = map(int, sys.argv[3:7])
k = int(sys.argv[7]) if len(sys.argv) > 7 else 6
bg = Image.new("RGBA", (w, h), (230, 230, 235, 255))
bg.alpha_composite(im.crop((x, y, x + w, y + h)))
bg.resize((w * k, h * k), Image.NEAREST).save(sys.argv[2])
