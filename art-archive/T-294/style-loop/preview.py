"""Preview: the emblem x4 on dark and light, plus 32 x 32 (x4) on both. Prints its colours.
Usage: python preview.py <in.png> <out.png>"""
import sys
from PIL import Image

im = Image.open(sys.argv[1]).convert("RGBA")
print(sorted(im.getcolors(99999), reverse=True)[:20])
big = im.resize((512, 512), Image.NEAREST)
small = im.resize((32, 32), Image.NEAREST).resize((128, 128), Image.NEAREST)
sheet = Image.new("RGBA", (512 * 2 + 16 + 128, 512), (0, 0, 0, 255))
for i, bg in enumerate([(24, 20, 44, 255), (228, 228, 222, 255)]):
    tile = Image.new("RGBA", (512, 512), bg)
    tile.alpha_composite(big)
    sheet.paste(tile, (i * 520, 0))
    t2 = Image.new("RGBA", (128, 128), bg)
    t2.alpha_composite(small)
    sheet.paste(t2, (1040, i * 140))
sheet.save(sys.argv[2])
