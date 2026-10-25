#!/usr/bin/env python3
"""Builds the elevation test scene's platform and ramp art (T-186).

PixelLab (T-186's three create-image-pixflux calls, in art-archive/T-186/) made
the surface textures; this script projects them exactly onto the isometric
faces of the platform and the ramp in game/data/level/elevation_test.json, at
32 art px per unit (drawn at scale 0.5 in the game's 16 px per unit world):

    screen x = (x - y) * 32,  screen y = (x + y) * 16 - height * 32

Faces: the top (platform: flat; ramp: the sloped plane), the east side and the
south side (the two the view shows; the ramp has only the south side, a
triangle). Textures tile by mirroring, so tile edges are seamless. A dark
outline is added on the silhouette and the top / side boundary, a lighter
edge on the top's rim, and the result is reduced to at most 30 colours with no
new semi-transparent pixels.

Usage (from the repo root):
    python game/tools/build_elevation_art.py build   # writes game/art/elevation/
    python game/tools/build_elevation_art.py check   # rules on the committed files
Standard library plus Pillow (as reduce_palette.py).
"""
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from style_rules import is_redgull_red  # noqa: E402  (Visual style rule 6)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW = os.path.join(ROOT, "art-archive", "T-186")
OUT = os.path.join(ROOT, "game", "art", "elevation")
DATA = os.path.join(ROOT, "game", "data", "level", "elevation_test.json")
PX = 32          # art px per unit
MAX_COLORS = 30
OUTLINE = (10, 12, 24)
WALL_ROWS = (16, 112)   # the wall texture rows used for 3 units of height (96 px)
SHADE = {"east": 0.86, "south": 0.66}
JOIN_EPS = 0.12  # units: the ramp's west edge meets the platform, no outline there


def mirror(i, n):
    i %= 2 * n
    return i if i < n else 2 * n - 1 - i


def load(name):
    return Image.open(os.path.join(RAW, name)).convert("RGB")


def desaturate(img, amount):
    """Free script fix: PixelLab's top is a bright cyan; pull it towards the
    cool blue-grey of concrete (amount 0..1 towards grey) and darken it a bit."""
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b = px[x, y]
            grey = 0.3 * r + 0.59 * g + 0.11 * b
            px[x, y] = tuple(int((c + (grey - c) * amount) * 0.82) for c in (r, g, b))
    return img


def corner_plane(piece, kind):
    """(h0, gx, gy): top height = h0 + gx * x + gy * y, in units."""
    if kind == "platform":
        return float(piece["height"]), 0.0, 0.0
    # east ramp: rises towards the platform at its west end
    x0, w = piece["x"], piece["w"]
    top, bottom = piece["top_height"], piece["bottom_height"]
    g = (bottom - top) / w
    return top - g * x0, g, 0.0


def vertices(rect, h0, gx, gy):
    x0, y0, x1, y1 = rect
    pts = []
    for x, y in ((x0, y0), (x1, y0), (x1, y1), (x0, y1)):
        h = h0 + gx * x + gy * y
        for hh in (h, 0.0):
            pts.append(((x - y) * PX, (x + y) * PX / 2 - hh * PX))
    return pts


def render(piece, kind, top_tex, wall_tex, top_swap):
    rect = (piece["x"], piece["y"], piece["x"] + piece["w"], piece["y"] + piece["h"])
    x0, y0, x1, y1 = rect
    h0, gx, gy = corner_plane(piece, kind)
    pts = vertices(rect, h0, gx, gy)
    minx = int(min(p[0] for p in pts))
    miny = int(min(p[1] for p in pts))
    maxx = int(max(p[0] for p in pts))
    maxy = int(max(p[1] for p in pts))
    w, h = maxx - minx, maxy - miny
    tw, th = top_tex.size
    ww, wh = wall_tex.size
    top_px, wall_px = top_tex.load(), wall_tex.load()
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out = img.load()
    face = [[None] * w for _ in range(h)]
    wx = [[0.0] * w for _ in range(h)]
    denom = 16 - 16 * gx - 16 * gy
    for py in range(h):
        sy = py + miny + 0.5
        for px in range(w):
            sx = px + minx + 0.5
            p = sx / PX
            q = (sy + 32 * h0 + 16 * p * (gx - gy)) / denom
            x, y = (q + p) / 2, (q - p) / 2
            if x0 <= x < x1 and y0 <= y < y1:
                u, v = (x, y) if not top_swap else (y, x)
                c = top_px[mirror(int(u * PX), tw), mirror(int(v * PX), th)]
                out[px, py] = c + (255,)
                face[py][px] = "top"
                wx[py][px] = x
                continue
            # east side: the plane x = x1, y along it
            y = x1 - p
            if kind == "platform" and y0 <= y < y1:
                top_h = h0 + gx * x1 + gy * y
                depth = (x1 + y) * PX / 2 - sy      # px above the base
                if 0 <= depth < top_h * PX:
                    row = WALL_ROWS[0] + int(top_h * PX - depth)
                    c = wall_px[mirror(int(y * PX), ww), min(max(row, 0), wh - 1)]
                    out[px, py] = tuple(int(k * SHADE["east"]) for k in c) + (255,)
                    face[py][px] = "east"
                    wx[py][px] = x1
                    continue
            # south side: the plane y = y1, x along it
            x = p + y1
            if x0 <= x < x1:
                top_h = h0 + gx * x + gy * y1
                depth = (x + y1) * PX / 2 - sy
                if 0 <= depth < top_h * PX:
                    row = WALL_ROWS[0] + int(top_h * PX - depth)
                    c = wall_px[mirror(int(x * PX), ww), min(max(row, 0), wh - 1)]
                    out[px, py] = tuple(int(k * SHADE["south"]) for k in c) + (255,)
                    face[py][px] = "south"
                    wx[py][px] = x
    outline(out, face, wx, w, h, x0 if kind == "ramp" else None)
    return img, (minx, miny), (x0, y0, x1, y1, h0, gx, gy)


def outline(out, face, wx, w, h, join_x):
    """Dark outline on the silhouette and where a side meets another face; a
    lighter rim on the top face along its edges. Not where the ramp joins."""
    marks = []
    for py in range(h):
        for px in range(w):
            f = face[py][px]
            if f is None:
                continue
            on_join = join_x is not None and wx[py][px] < join_x + JOIN_EPS and f in ("top", "south")
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = px + dx, py + dy
                nf = face[ny][nx] if 0 <= nx < w and 0 <= ny < h else None
                if nf == f:
                    continue
                if on_join:
                    continue
                if nf is None:
                    marks.append((px, py, "dark"))
                elif f != "top" and nf == "top":
                    marks.append((px, py, "dark"))
                elif f == "top":
                    marks.append((px, py, "rim"))
                break
    for px, py, kind in marks:
        r, g, b, _ = out[px, py]
        if kind == "dark":
            out[px, py] = OUTLINE + (255,)
        else:
            out[px, py] = (min(255, int(r * 1.35) + 12), min(255, int(g * 1.35) + 12), min(255, int(b * 1.35) + 14), 255)


def reduce_colors(img, n=MAX_COLORS):
    alpha = img.split()[3]
    rgb = img.convert("RGB").quantize(colors=n, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGB")
    res = Image.merge("RGBA", rgb.split() + (alpha.point(lambda a: 255 if a > 127 else 0),))
    px = res.load()
    for y in range(res.height):
        for x in range(res.width):
            if px[x, y][3] == 0:
                px[x, y] = (0, 0, 0, 0)
    return res


def build():
    with open(DATA) as f:
        data = json.load(f)
    plat, ramp = data["platforms"][0], data["ramps"][0]
    top = desaturate(load("raw_platform_top.png"), 0.6)
    wall = load("raw_platform_wall.png")
    rtop = load("raw_ramp_top.png")
    os.makedirs(OUT, exist_ok=True)
    jobs = [("platform", plat, "platform", top, False), ("ramp", ramp, "ramp", rtop, True)]
    for name, piece, kind, tex, swap in jobs:
        img, origin, geo = render(piece, kind, tex, wall, swap)
        img = reduce_colors(img)
        img.save(os.path.join(OUT, name + ".png"))
        sources = ["raw_platform_top", "raw_platform_wall"] if kind == "platform" else ["raw_ramp_top", "raw_platform_wall"]
        rec = {
            "asset": name,
            "task": "T-186",
            "image": {"width": img.width, "height": img.height},
            "px_per_unit": PX,
            "drawn_at_scale": 0.5,
            "top_left_art_px": list(origin),
            "note": "top_left_art_px is where the image's top-left sits relative to the scene's drawn origin (art px, +y down); the game draws it at scale 0.5.",
            "piece_id": piece["id"],
            "source_json": "game/data/level/elevation_test.json",
            "pixellab": [{"record": "art-archive/T-186/%s.json" % s, "image": "art-archive/T-186/%s.png" % s,
                          "endpoint": "create-image-pixflux", "generations": 1} for s in sources],
            "script": "game/tools/build_elevation_art.py",
            "steps": "PixelLab textures projected onto the isometric faces by script (mirror tiling), outline and rim, reduced to at most %d colours." % MAX_COLORS,
        }
        with open(os.path.join(OUT, name + ".json"), "w") as f:
            json.dump(rec, f, indent=2)
            f.write("\n")
        print(name, img.size, origin)


def rules(path):
    """Returns a list of (rule, ok, detail) for a game image (any size)."""
    img = Image.open(path)
    img = img.convert("RGBA")
    px = list(img.getdata())
    w, h = img.size
    corners = [px[0], px[w - 1], px[(h - 1) * w], px[-1]]
    semi = sum(1 for p in px if 0 < p[3] < 255)
    colors = {p[:3] for p in px if p[3] == 255}
    reds = {c for c in colors if is_redgull_red(c)}
    red = sum(1 for p in px if p[3] == 255 and p[:3] in reds)
    return [
        ("transparent background (corners)", all(c[3] == 0 for c in corners), str(corners)),
        ("no semi-transparent pixels", semi == 0, "%d" % semi),
        ("%d colours or fewer" % MAX_COLORS, len(colors) <= MAX_COLORS, "%d" % len(colors)),
        ("no Redgull red", red == 0, "%d" % red),
    ]


def check():
    ok = True
    for name in ("platform", "ramp"):
        for rule, good, detail in rules(os.path.join(OUT, name + ".png")):
            print("%s  %s %s: %s" % ("PASS" if good else "FAIL", name, rule, detail))
            ok = ok and good
    return 0 if ok else 1


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    if cmd == "build":
        build()
    elif cmd == "check":
        sys.exit(check())
    else:
        sys.exit("usage: build_elevation_art.py build|check")
