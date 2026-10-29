"""Enlarge a style-loop PNG on dark and light backgrounds for inspection: python preview.py in.png out.png"""
import sys
from PIL import Image

src = Image.open(sys.argv[1]).convert("RGBA")
s = 8
w, h = src.size
out = Image.new("RGBA", (w * s * 2 + s, h * s), (0, 0, 0, 255))
for i, bg in enumerate([(16, 14, 30, 255), (220, 220, 225, 255)]):
    panel = Image.new("RGBA", (w, h), bg)
    panel.alpha_composite(src)
    out.paste(panel.resize((w * s, h * s), Image.NEAREST), (i * (w * s + s), 0))
out.save(sys.argv[2])
print(src.mode, src.size, len(src.getcolors(99999)))
