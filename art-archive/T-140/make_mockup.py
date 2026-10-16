"""T-140 mock-up: the full level-up art set over a dimmed run, as T-141 would show it (2 screen px per art px)."""
import textwrap
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
R = Path(__file__).resolve().parent
ROOT = R.parents[1]
A = ROOT / "game/art/level_up"
def load(n, s=1):
    im = Image.open(A / (n + ".png")).convert("RGBA")
    return im.resize((im.width * s, im.height * s), Image.NEAREST)
W, H = 1152, 648
run = Image.open(ROOT / "art-archive/T-052/screenshots/level_up_screen.png").convert("RGBA").resize((W, H))
# the run behind: dark road and car stand-in (the T-052 screenshot already has cards, so draw a plain run)
im = Image.new("RGBA", (W, H), (52, 52, 60, 255)); d = ImageDraw.Draw(im)
for x in range(0, W, 192): d.rectangle([x, 330, x + 90, 338], fill=(210, 210, 210, 255))
d.rectangle([0, 0, 250, H], fill=(78, 70, 62, 255)); d.rectangle([900, 0, W, H], fill=(78, 70, 62, 255))
d.rectangle([540, 340, 610, 372], fill=(30, 100, 60, 255))
im = Image.alpha_composite(im, Image.new("RGBA", (W, H), (0, 0, 0, 153)))  # the screen's 60% dim
burst = load("sunburst", 4)  # mock-up only: shown at 55% here; T-141 sets the real strength
a = burst.getchannel("A").point(lambda v: 140 if v else 0); burst.putalpha(a)
im.alpha_composite(burst, (W // 2 - 512, 380 - 512))
font = lambda s: ImageFont.truetype(str(ROOT / "game/fonts/bangers/Bangers-Regular.ttf"), s)
d = ImageDraw.Draw(im)
rib = load("header_ribbon", 2); rx = W // 2 - 380; im.alpha_composite(rib, (rx, 40))
d.text((W // 2, 84), "REDGULL SENT A GIFT PACK!", font=font(40), fill=(255, 244, 214), anchor="mm")
im.alpha_composite(load("gift_pack_emblem", 1), (rx - 112, 22))
card = load("card_frame", 2); hl = load("highlight_frame", 2); btn = load("button_plate", 2)
titles = [("BONUS BULLETS", "A faster trigger finger. More bullets, more likes."), ("HOT TAKE EXHAUST", "Your tailpipe breathes fire at whatever is behind you.")]
for i, (t, desc) in enumerate(titles):
    x = W // 2 - 380 + i * 400; y = 230
    if i == 1: im.alpha_composite(hl, (x - 12, y - 12))
    im.alpha_composite(card, (x, y))
    d = ImageDraw.Draw(im)
    d.text((x + 180, y + 52), t, font=font(36), fill=(0, 0, 0), anchor="mm")
    d.text((x + 180, y + 140), desc[:26] + "\n" + desc[26:], font=font(24), fill=(0, 0, 0), anchor="mm", align="center")
    im.alpha_composite(btn, (x + 108, y + 220))
    d.text((x + 180, y + 240), "TAKE IT", font=font(28), fill=(0, 0, 0), anchor="mm")
im.convert("RGB").save(R / "level_up_mockup_full_set.png")
