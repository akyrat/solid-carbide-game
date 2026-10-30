"""T-399: enlarged contact sheet of PNGs side by side (dark background), for picking a rotation.

usage: python contact_sheet.py OUT.png SCALE IN1.png [IN2.png ...]
"""
import sys
from PIL import Image, ImageDraw

out, scale, paths = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
imgs = [Image.open(p).convert("RGBA") for p in paths]
w = max(i.width for i in imgs) * scale
h = max(i.height for i in imgs) * scale
sheet = Image.new("RGBA", (w * len(imgs), h + 14), (40, 40, 48, 255))
d = ImageDraw.Draw(sheet)
for n, im in enumerate(imgs):
    big = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    sheet.alpha_composite(big, (n * w, 14))
    d.text((n * w + 4, 1), str(n), fill=(255, 255, 255, 255))
sheet.save(out)
print("wrote", out)
