"""Builds the T-140 review images (sample enlarged, and a rough mock-up). Free, no PixelLab."""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
R = Path(__file__).resolve().parent
ROOT = R.parents[1]
box = Image.open(R / "gift_pack_raw.png").convert("RGBA")
logo = Image.open(ROOT / "game/art/logo/redgull_logo_32.png").convert("RGBA")

# 1. enlarged on dark and light, side by side (x4)
big = box.resize((512, 512), Image.NEAREST)
sheet = Image.new("RGB", (1024, 512))
for i, bg in enumerate([(20, 16, 40), (225, 225, 225)]):
    t = Image.new("RGBA", (512, 512), bg + (255,)); t.alpha_composite(big); sheet.paste(t.convert("RGB"), (i * 512, 0))
sheet.save(R / "gift_pack_review_dark_light_x4.png")

# 2. rough mock-up, 1152x648. Pieces 1-5 are quick script stand-ins (not final).
W, H = 1152, 648
im = Image.new("RGBA", (W, H), (46, 46, 54, 255)); d = ImageDraw.Draw(im)
for x in range(0, W, 192): d.rectangle([x, 300, x + 90, 308], fill=(200, 200, 200, 255))  # road line
d.rectangle([0, 0, 260, H], fill=(70, 64, 58, 255)); d.rectangle([900, 0, W, H], fill=(70, 64, 58, 255))
d.rectangle([540, 330, 610, 360], fill=(30, 90, 50, 255))  # car stand-in
im = Image.alpha_composite(im, Image.new("RGBA", (W, H), (0, 0, 0, 153)))  # 60% dim
# burst
cx, cy = W // 2, 360
burst = Image.new("RGBA", (W, H), (0, 0, 0, 0)); bd = ImageDraw.Draw(burst)
for k in range(16):
    a0 = k * math.tau / 16; a1 = a0 + math.tau / 32
    bd.polygon([(cx, cy)] + [(cx + 700 * math.cos(a), cy + 700 * math.sin(a)) for a in (a0, a1)],
               fill=(150, 20, 30, 255) if k % 2 else (200, 140, 30, 255))
mask = burst.getchannel("A").point(lambda v: 90 if v else 0)  # mock-up only; real art has no alpha
im.paste(burst, (0, 0), mask)
d = ImageDraw.Draw(im)
font = lambda s: ImageFont.truetype(str(ROOT / "game/fonts/bangers/Bangers-Regular.ttf"), s)
def card(x, y, w, h, hl):
    if hl: d.rectangle([x - 12, y - 12, x + w + 12, y + h + 12], fill=(255, 224, 77), outline=(0, 0, 0), width=4)
    d.rectangle([x, y, x + w, y + h], fill=(255, 244, 214), outline=(0, 0, 0), width=4)
    d.rectangle([x + 6, y + 6, x + w - 6, y + h - 6], outline=(190, 150, 40), width=6)
    d.rectangle([x + 14, y + 14, x + w - 14, y + h - 14], outline=(150, 20, 30), width=3)
    d.rectangle([x + 90, y + h - 62, x + w - 90, y + h - 24], fill=(220, 170, 50), outline=(150, 20, 30), width=4)
    d.text((x + w // 2, y + h - 43), "TAKE IT", font=font(30), fill=(0, 0, 0), anchor="mm")
    d.text((x + w // 2, y + 50), "BONUS BULLETS" if not hl else "HOT TAKE EXHAUST", font=font(32), fill=(0, 0, 0), anchor="mm")
    d.text((x + w // 2, y + 120), "(description text here)", font=font(22), fill=(60, 30, 30), anchor="mm")
card(W // 2 - 400, 250, 360, 300, False); card(W // 2 + 40, 250, 360, 300, True)
# ribbon
d.polygon([(W//2-300,70),(W//2-250,70),(W//2-250,150),(W//2-300,150),(W//2-270,110)], fill=(110,14,24), outline=(0,0,0))
d.polygon([(W//2+300,70),(W//2+250,70),(W//2+250,150),(W//2+300,150),(W//2+270,110)], fill=(110,14,24), outline=(0,0,0))
d.rectangle([W//2-260, 60, W//2+260, 140], fill=(190, 30, 40), outline=(0, 0, 0), width=4)
d.rectangle([W//2-252, 68, W//2+252, 132], outline=(240, 190, 60), width=4)
d.text((W//2, 100), "REDGULL SENT A GIFT PACK!", font=font(40), fill=(255, 236, 160), anchor="mm")
im.alpha_composite(box, (W//2 - 420, 36))  # emblem at 1x (128 px), left of the ribbon
im.convert("RGB").save(R / "level_up_mockup_rough.png")
