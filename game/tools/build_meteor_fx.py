#!/usr/bin/env python3
"""Draws the kaiju meteor attack's comet tail and impact animation (task T-070).

Two animations, in three versions (the game's setting `data/meteor_fx.json`
picks one; see game/README.md, "Meteor effects"):

  pixel      sprite sheets drawn here by script (no PixelLab).
  pixellab   sprite sheets animated by PixelLab (/animate-with-text-v3) from
             first frames drawn here; this script writes those first frames and
             turns the raw frames PixelLab returned into the game's sheets
             (cut background, at most 30 colours, no semi-transparent pixels).
  particles  no sprites: drawn live by scripts/enemies/meteor_fx.gd.

Sheets (in game/art/effects/): meteor_tail_<version>.png, 6 or 8 frames in one
row; meteor_impact_<version>.png, 8 frames in one row. Every cell is 128 x 128
art pixels, drawn at 0.75. The tail's head is at the cell's bottom centre and it
streams up, leaning like the falling meteor's path (a little to the right). The
impact is centred on (64, 76), the ground ellipse is 2:1.
Palette: the boulders' navy and violet with a magenta glow, a white-hot core,
grey-violet dust. Never red.

Commands (from the repo root):
  python game/tools/build_meteor_fx.py build            # the "pixel" sheets, records, previews
  python game/tools/build_meteor_fx.py first-frames     # the PixelLab first frames (art-archive/T-070/pixellab/)
  python game/tools/build_meteor_fx.py from-pixellab    # the "pixellab" sheets from the raw frames
  python game/tools/build_meteor_fx.py check            # the sprite rules on every sheet
Running build twice gives byte-identical files.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_sprite_rules as rules  # noqa: E402
from remove_car_shadow import write_png  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
REPO = GAME.parent
OUT = GAME / "art" / "effects"
ARCHIVE = REPO / "art-archive" / "T-070"
PL = ARCHIVE / "pixellab"

CELL = 128
MAX_COLORS = 30
TAIL_FRAMES = 6
IMPACT_FRAMES = 8
HEAD = (64, 118)          # the tail's head, in the cell
LEAN = 20.0 / 220.0       # pixels to the right per pixel up (the meteor's path)
CENTER = (64, 76)         # the impact's ground point

P = {
    "W": (255, 244, 255),   # white-hot
    "K": (255, 190, 245),   # pale pink
    "P": (240, 104, 236),   # magenta
    "V": (156, 70, 214),    # violet
    "D": (92, 46, 150),     # deep violet
    "N": (46, 30, 88),      # navy
    "O": (13, 10, 26),      # outline
    "g": (176, 168, 198),   # dust light
    "m": (128, 118, 164),   # dust mid
    "d": (86, 78, 124),     # dust dark
    "s": (96, 80, 110),     # rock
}
T = (0, 0, 0, 0)


def hash01(*a) -> float:
    h = 2166136261
    for v in a:
        h = ((h ^ (int(v) & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
        h = (h ^ (h >> 13)) & 0xFFFFFFFF
    return (h % 10007) / 10007.0


class Canvas:
    def __init__(self):
        self.px = {}

    def put(self, x, y, key):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < CELL and 0 <= y < CELL:
            self.px[(x, y)] = key

    def rows(self):
        return [[(*P[self.px[(x, y)]], 255) if (x, y) in self.px else T for x in range(CELL)] for y in range(CELL)]

    def clear_dither(self, x, y):
        return (x + y) % 2 == 0


def tail_frame(f: int) -> Canvas:
    """A tapered comet tail streaming up from HEAD; flickers over the 6 frames."""
    c = Canvas()
    length = 104.0
    for y in range(CELL):
        s = (HEAD[1] - y) / length          # 0 at the head, 1 at the tip
        if s < -0.05 or s > 1.0:
            continue
        s = max(s, 0.0)
        cx = HEAD[0] + (HEAD[1] - y) * LEAN
        wob = math.sin(s * 9.0 - f * 2 * math.pi / TAIL_FRAMES * 1.0) * (0.8 + 2.2 * s)
        half = 17.0 * (1.0 - s) ** 0.85 + 0.6
        # the tip breaks up into licking tongues: the tail ends at a ragged length
        tip_cut = 0.78 + 0.22 * hash01(f, y // 3, 7)
        if s > tip_cut:
            continue
        for x in range(CELL):
            dx = x - cx - wob
            a = abs(dx)
            if a > half + 1:
                continue
            n = hash01(f, x, y)
            edge = half + (n - 0.5) * 3.0
            if a > edge:
                continue
            r = a / max(edge, 0.001)
            along = s
            # zones: white core, pink, magenta, violet, deep violet, with dither at the borders
            zone = r * 1.0 + along * 0.55
            ck = c.clear_dither(x, y)
            if zone < 0.16:
                key = "W"
            elif zone < 0.30:
                key = "K" if (zone > 0.24 or ck) else "W"
            elif zone < 0.52:
                key = "P" if (zone > 0.46 or ck) else "K"
            elif zone < 0.76:
                key = "V" if (zone > 0.70 or ck) else "P"
            elif zone < 1.0:
                key = "D" if (zone > 0.94 or ck) else "V"
            else:
                key = "N"
            c.put(x, y, key)
    # sparks shed behind the head, each frame at other places, flying up
    for i in range(7):
        s = hash01(i, 3) * 0.9 + 0.1
        s = (s + f * 0.045 * (1 + hash01(i, 9))) % 1.0
        y = HEAD[1] - s * 110.0
        x = HEAD[0] + (HEAD[1] - y) * LEAN + (hash01(i, 5) - 0.5) * 36.0 * (0.4 + s)
        key = "K" if s < 0.45 else ("P" if s < 0.75 else "V")
        size = 2 if s < 0.6 else 1
        for dx in range(size):
            for dy in range(size):
                c.put(x + dx, y + dy, key)
    return c


def ellipse_ring(c, cx, cy, rx, thick, keys, f, seed, gaps=0.0):
    """A ring on the ground: ellipse 2:1, `thick` pixels thick, ragged."""
    ry = rx / 2.0
    for y in range(CELL):
        for x in range(CELL):
            d = math.hypot((x - cx) / rx, (y - cy) / ry)
            ang = math.atan2((y - cy) * 2.0, x - cx)
            tt = thick / rx
            if abs(d - 1.0) <= tt * (0.7 + 0.6 * hash01(f, int(ang * 6), seed)):
                if hash01(x, y, f, seed) < gaps:
                    continue
                k = keys[0] if d > 1.0 - tt * 0.2 else (keys[1] if d > 1.0 - tt * 0.7 else keys[2])
                c.put(x, y, k)


def fill_ellipse(c, cx, cy, rx, key, dither=False, ry=None):
    ry = ry if ry is not None else rx / 2.0
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                if dither and (x + y) % 2:
                    continue
                c.put(x, y, key)


def puff(c, cx, cy, r, f, seed, fade):
    """A grey-violet dust puff: lumpy disc lit from the upper left, chequered away as `fade` grows."""
    for y in range(int(cy - r) - 1, int(cy + r) + 2):
        for x in range(int(cx - r) - 1, int(cx + r) + 2):
            d = math.hypot(x - cx, (y - cy) * 1.15)
            if d > r * (0.85 + 0.3 * hash01(x // 2, y // 2, seed)):
                continue
            if fade > 0.0 and hash01(x, y, f, seed) < fade:
                continue
            lit = (x - cx) * -0.5 + (y - cy) * -0.8
            key = "g" if lit > r * 0.35 else ("m" if lit > -r * 0.35 else "d")
            c.put(x, y, key)


def shard(c, x, y, size, seed):
    k = "s" if hash01(seed, 1) < 0.5 else "N"
    for dx in range(-1, size + 1):
        for dy in range(-1, size + 1):
            edge = dx in (-1, size) or dy in (-1, size)
            c.put(x + dx, y + dy, "O" if edge else k)
    c.put(x, y, "P")  # a glowing crack pixel


def impact_frame(f: int) -> Canvas:
    c = Canvas()
    cx, cy = CENTER
    n = IMPACT_FRAMES
    t = f / (n - 1)
    # the glow pool on the ground, shrinking and chequered away
    if f >= 1:
        rx = 24 + 38 * min(t * 1.4, 1.0)
        pool = "V" if f < 4 else "D"
        fill_ellipse(c, cx, cy, rx, pool, dither=(f >= 3))
        if f < 4:
            fill_ellipse(c, cx, cy, rx * 0.6, "P", dither=(f >= 2))
    # dust puffs ring out and rise, from frame 3
    if f >= 3:
        for i in range(9):
            a = math.tau * i / 9 + hash01(i, 2) * 0.5
            dist = 30 + 26 * min((f - 2) / 5.0, 1.0) + hash01(i, 4) * 8
            px = cx + math.cos(a) * dist
            py = cy + math.sin(a) * dist * 0.5 - (f - 2) * 3.0
            r = 7 + (f - 2) * 1.6 + hash01(i, 6) * 4
            puff(c, px, py, r, f, i, fade=max(0.0, (f - 4) * 0.22))
    # shockwave ring
    if f >= 1:
        rx = 18 + 46 * min(t * 1.25, 1.0)
        thick = max(1.5, 7.0 - f * 0.8)
        keys = ("W", "K", "P") if f < 4 else (("P", "V", "V") if f < 6 else ("V", "D", "D"))
        ellipse_ring(c, cx, cy, rx, thick, keys, f, 11, gaps=0.06 * f)
    # the flash: white-hot ellipse and a vertical spike in the first frames
    if f <= 2:
        s = [1.0, 0.8, 0.45][f]
        fill_ellipse(c, cx, cy, 26 * s + 6, "K", ry=13 * s + 3)
        fill_ellipse(c, cx, cy, 17 * s + 3, "W", ry=8 * s + 2)
        for yy in range(int(34 * (1.0 if f == 0 else 0.6))):
            half = max(0, int((4 - yy * 0.14) * s + 0.5))
            for dx in range(-half, half + 1):
                c.put(cx + dx, cy - 4 - yy, "W" if abs(dx) <= half // 2 else "K")
    # rock shards: ballistic
    if f >= 1:
        for i in range(10):
            a = math.tau * i / 10 + hash01(i, 8)
            vx = math.cos(a) * (9 + 7 * hash01(i, 12))
            vy = -(14 + 12 * hash01(i, 13))
            tt = f - 0.5
            px = cx + vx * tt
            py = cy + vy * tt + 3.2 * tt * tt + math.sin(a) * 5
            if py > cy + 18:
                continue
            shard(c, px, py, 2 if hash01(i, 14) < 0.6 else 3, i)
    # glints: tiny sparks
    if f >= 1:
        for i in range(12):
            a = math.tau * hash01(i, 21)
            dist = (10 + 60 * hash01(i, 22)) * min(1.0, t * 1.6)
            if f > 5 and hash01(i, 23) < 0.6:
                continue
            c.put(cx + math.cos(a) * dist, cy + math.sin(a) * dist * 0.5 - 8 * t, "K" if i % 2 else "W")
    return c


def sheet(frames):
    h = CELL
    rows = [[] for _ in range(h)]
    for fr in frames:
        r = fr.rows() if isinstance(fr, Canvas) else fr
        for y in range(h):
            rows[y].extend(r[y])
    return rows


def png_path(kind, version):
    return OUT / f"meteor_{kind}_{version}.png"


def record(kind, version, frames, extra):
    d = {
        "file": png_path(kind, version).name,
        "what": f"The meteor attack's {'comet tail (loops while the meteor falls)' if kind == 'tail' else 'impact animation (plays once on landing)'}, version {version} (task T-070).",
        "frames": frames,
        "frame_size": [CELL, CELL],
        "drawn_scale": 0.75,
        "anchor": list(HEAD) if kind == "tail" else list(CENTER),
        "palette": {k: list(v) for k, v in P.items()},
    }
    d.update(extra)
    (OUT / f"meteor_{kind}_{version}.json").write_text(json.dumps(d, indent=1) + "\n", encoding="utf-8")


def preview(path, sheets):
    """Enlarged previews over a dark and a light ground (nearest neighbour)."""
    for name, bg in (("dark", (14, 12, 28)), ("light", (214, 210, 224))):
        parts = []
        for rows in sheets:
            h, w = len(rows), len(rows[0])
            out = [[bg if rows[y][x][3] == 0 else rows[y][x][:3] for x in range(w)] for y in range(h)]
            parts.append(out)
        big = []
        for out in parts:
            for row in out:
                r2 = []
                for p in row:
                    r2.extend([(*p, 255)] * 2)
                big.extend([r2, list(r2)])
        write_png(str(path).replace(".png", f"_{name}.png"), big)


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    ARCHIVE.mkdir(parents=True, exist_ok=True)
    tail = sheet([tail_frame(f) for f in range(TAIL_FRAMES)])
    imp = sheet([impact_frame(f) for f in range(IMPACT_FRAMES)])
    write_png(png_path("tail", "pixel"), tail)
    write_png(png_path("impact", "pixel"), imp)
    made = "game/tools/build_meteor_fx.py build (a script; no PixelLab call). Byte-identical every run."
    record("tail", "pixel", TAIL_FRAMES, {"made_by": made})
    record("impact", "pixel", IMPACT_FRAMES, {"made_by": made})
    preview(ARCHIVE / "preview_pixel_tail.png", [tail])
    preview(ARCHIVE / "preview_pixel_impact.png", [imp])
    print("wrote the pixel sheets")


def first_frames():
    PL.mkdir(parents=True, exist_ok=True)
    write_png(PL / "tail_first_frame.png", tail_frame(0).rows())
    write_png(PL / "impact_first_frame.png", impact_frame(1).rows())
    print("wrote the PixelLab first frames in", PL)


def from_pixellab():
    """Raw frames in art-archive/T-070/pixellab/<kind>_raw/*.png -> the game's sheets."""
    from PIL import Image
    for kind, want in (("tail", 8), ("impact", IMPACT_FRAMES)):
        files = sorted((PL / f"{kind}_raw").glob("*.png"), key=lambda p: int(p.stem.rsplit("_", 1)[-1]))
        if len(files) < want:
            print(f"{kind}: only {len(files)} raw frames, need {want}; skipped")
            continue
        ims = [Image.open(f).convert("RGBA").resize((CELL, CELL), Image.NEAREST) for f in files[:want]]
        # no semi-transparent pixels: opaque above half, else gone
        for im in ims:
            px = im.load()
            for y in range(CELL):
                for x in range(CELL):
                    r, g, b, a = px[x, y]
                    px[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
        big = Image.new("RGBA", (CELL * want, CELL), (0, 0, 0, 0))
        for i, im in enumerate(ims):
            big.paste(im, (i * CELL, 0))
        # at most 30 colours over the whole sheet (median cut on the opaque pixels), red-shifted colours kept as they are
        op = Image.new("RGB", big.size)
        op.paste(big.convert("RGB"))
        q = op.quantize(colors=MAX_COLORS - 1, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGB")
        out = Image.new("RGBA", big.size, (0, 0, 0, 0))
        bp, qp, outp = big.load(), q.load(), out.load()
        for y in range(big.size[1]):
            for x in range(big.size[0]):
                if bp[x, y][3]:
                    outp[x, y] = (*qp[x, y], 255)
        rows = [[outp[x, y] for x in range(big.size[0])] for y in range(big.size[1])]
        write_png(png_path(kind, "pixellab"), rows)
        record(kind, "pixellab", want, {
            "made_by": f"PixelLab /animate-with-text-v3 from a script-drawn first frame (art-archive/T-070/pixellab/), cut to {CELL} x {CELL}, "
                       f"background and semi-transparent pixels removed, at most {MAX_COLORS} colours, by game/tools/build_meteor_fx.py from-pixellab",
        })
        preview(ARCHIVE / f"preview_pixellab_{kind}.png", [rows])
        print("wrote", png_path(kind, "pixellab").name)


def check(argv_paths=None):
    ok = True
    for kind, n in (("tail", TAIL_FRAMES), ("impact", IMPACT_FRAMES)):
        for version in ("pixel", "pixellab"):
            p = png_path(kind, version)
            if not p.exists():
                continue
            rec = json.loads(p.with_suffix(".json").read_text(encoding="utf-8"))
            res = rules.check_sheet(str(p), rec["frames"], size=CELL, max_colors=MAX_COLORS)
            bad = [(i, r) for i, (rs, _info) in enumerate(res) for r in rs if not r[1]]
            red = _redgull_pixels(p)
            print(p.name, "OK" if not bad and not red else (bad, "redgull-red pixels: %d" % red))
            if bad or red:
                ok = False
    return 0 if ok else 1


def _redgull_pixels(path):
    _, _, rows = rules.decode_png(Path(path).read_bytes())
    n = 0
    for r in rows:
        for (R, G, B, A) in r:
            if A and R > 150 and G < 90 and B < 90:
                n += 1
    return n


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["build", "first-frames", "from-pixellab", "check"])
    a = ap.parse_args(argv)
    if a.cmd == "build":
        build()
    elif a.cmd == "first-frames":
        first_frames()
    elif a.cmd == "from-pixellab":
        from_pixellab()
    else:
        return check()
    return 0


if __name__ == "__main__":
    sys.exit(main())
