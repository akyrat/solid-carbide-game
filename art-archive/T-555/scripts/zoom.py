"""Enlarge a PNG (nearest neighbour) on a grey background, for looking at it."""
import sys
from PIL import Image

src, out, k = sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 4
im = Image.open(src).convert("RGBA")
bg = Image.new("RGBA", im.size, (90, 90, 90, 255))
bg.alpha_composite(im)
bg.resize((im.width * k, im.height * k), Image.NEAREST).save(out)
print(out)
