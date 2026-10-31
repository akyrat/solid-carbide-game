"""T-433: free script mock-up used as pixflux's init image (layout + the real car), and the request JSON."""
import base64, io, json, random, sys
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
W, H = 320, 180
FRAME = int(sys.argv[1]) if len(sys.argv) > 1 else 2

sheet = Image.open(ROOT / "game/art/car/car_iso.png").convert("RGBA")
car = sheet.crop((FRAME * 128, 0, FRAME * 128 + 128, 128))
car = car.crop(car.getbbox())

img = Image.new("RGBA", (W, H), (14, 16, 34, 255))
d = ImageDraw.Draw(img)
# night sky gradient, stepped
for y in range(0, 110):
    t = y / 110
    c = (int(14 + 20 * t), int(16 + 14 * t), int(34 + 30 * t), 255)
    d.line([(0, y), (W, y)], fill=c)
# skyline: steel/glass towers, darker toward the middle
rnd = random.Random(433)
x = 0
while x < W:
    w = rnd.randint(14, 30)
    h = rnd.randint(50, 110)
    mid = abs((x + w / 2) - W / 2) < 60
    body = (30, 36, 52) if mid else (52, 62, 84)
    d.rectangle([x, 120 - h, x + w, 125], fill=body)
    for wy in range(120 - h + 4, 122, 6):
        for wx in range(x + 3, x + w - 2, 5):
            r = rnd.random()
            if r < (0.15 if mid else 0.4):
                col = rnd.choice([(200, 214, 230), (150, 190, 230), (210, 150, 70)])
                d.rectangle([wx, wy, wx + 1, wy + 2], fill=col)
    x += w + rnd.randint(0, 4)
# street
d.rectangle([0, 124, W, H], fill=(24, 26, 38))
# kaiju silhouette on the right third
d.ellipse([228, 40, 300, 150], fill=(20, 24, 30))
d.ellipse([250, 20, 282, 52], fill=(20, 24, 30))
d.polygon([(232, 140), (210, 170), (250, 150)], fill=(20, 24, 30))
# meteors with magenta/purple glow
for mx, my in [(60, 18), (200, 30), (300, 70)]:
    d.ellipse([mx - 6, my - 6, mx + 6, my + 6], fill=(120, 40, 140))
    d.ellipse([mx - 3, my - 3, mx + 3, my + 3], fill=(40, 30, 60))
    d.line([(mx + 4, my - 4), (mx + 30, my - 26)], fill=(90, 50, 150), width=2)
# drift arc trails: pink and cyan
for i in range(0, 140):
    t = i / 140
    px = int(40 + 160 * t)
    py = int(150 + 18 * (1 - (2 * t - 1) ** 2))
    d.point((px, py), fill=(255, 60, 170))
    d.point((px, py + 3), fill=(60, 230, 240))
# smoke
for sx in range(110, 200, 9):
    d.ellipse([sx, 140, sx + 12, 152], fill=(120, 124, 140))
# the real car, left third
img.alpha_composite(car, (40, 112))
img.save(OUT / f"init_frame{FRAME}.png")

buf = io.BytesIO(); img.convert("RGBA").save(buf, "PNG")
b64 = base64.b64encode(buf.getvalue()).decode()
prompt = (
    "cinematic night street in downtown Tokyo, retro pixel art, dark green 1967 Mustang fastback with two white "
    "racing stripes drifting in a wide arc on the left, pink and cyan neon drift trails and grey tyre smoke behind it, "
    "a giant dark reptilian kaiju monster standing among steel and glass skyscrapers on the right, "
    "alien meteors of dark rock with glowing magenta and purple cracks falling from a navy sky, "
    "cool blue-grey buildings with pale white and pale blue lit windows, small amber lights, "
    "calm dark empty sky in the middle, no text, no letters"
)
req = {
    "description": prompt,
    "image_size": {"width": W, "height": H},
    "text_guidance_scale": 8,
    "outline": "selective outline",
    "shading": "detailed shading",
    "detail": "highly detailed",
    "init_image": {"type": "base64", "base64": b64},
    "init_image_strength": 300,
}
(OUT / f"req_v1_frame{FRAME}.json").write_text(json.dumps(req), encoding="utf-8")
print("ok", car.size)
