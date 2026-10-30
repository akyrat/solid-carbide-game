#!/usr/bin/env python3
"""T-399: the level creator's parked and broken cars at their four facings, from PixelLab pictures.

Each car model needs two PixelLab pictures: one facing up the screen (top left or top right) and one facing
down it (bottom left or bottom right); the other two facings are their mirrors (free). The facings, as the
creator names them (props.json rotations): north = top right, east = bottom right, south = bottom left,
west = top left. A mirror swaps top right <-> top left and bottom right <-> bottom left.

  python game/tools/build_street_cars.py rotate-request --from <png> --out <json> [--from-direction north-east]
          [--to-direction south-west] [--colors <png>] [--seed N]
      Writes a PixelLab /rotate request body (the picture, and the forced palette from --colors, default the
      same picture, as base64) so the second picture is the same car seen from the other end. (T-399's first
      try turned the car the wrong way; the briefs use rotations-request instead.)
  python game/tools/build_street_cars.py rotations-request --from <png> --description "<the car>" --out <json>
      Writes a PixelLab /generate-8-rotations-v3 request body (2 generations): the same car in 8 directions
      from one picture, among them the one facing down the screen.
  python game/tools/build_street_cars.py repaint-front --in <png> --out <png> --nose bottom-left
      Free (the board, 2026-10-30): PixelLab paints a car's headlights red like its rear lights; this turns
      the red lamps on the nose's side of the car grey (unlit) and leaves the rear lamps red.
  python game/tools/build_street_cars.py wreck --in <png> --out <png> [--crush B] [--crack B] [--scorch B]
          [--rust B] [--flat B] [--no-dusty] [--seed N]
      Free: a broken car's damage on one cleaned picture (boxes x0,y0,x1,y1, repeatable): dusty beige-grey
      paint, a crushed panel, shattered glass, scorch marks, rust and grime, a flat tyre. Seeded.
  python game/tools/build_street_cars.py clean --raw <png> --out <png> [--mirror]
      T-397's free clean-up of one PixelLab car picture (background, alpha 0/255, specks, 30 colours).
  python game/tools/build_street_cars.py strip --out <png> (--top-right P | --top-left P)
          (--bottom-left P | --bottom-right P) [--max-colors 30]
      The car's four facings as one row of four 128 x 128 frames, in the order north, east, south, west
      (top right, bottom right, bottom left, top left): the two pictures and their mirrors, with one shared
      palette of at most 30 colours (so the facings match), alpha 0 or 255.
  python game/tools/build_street_cars.py preview --strip <png> --out-dir <folder>
      The four facings parked on the road and on the sidewalk next to T-397's curb, a boulder and a building,
      placed by the same anchor the game uses; dark and light background, 3x. Writes preview_side_by_side.png,
      preview_dark.png, preview_light.png, and footprints.png (the 2 x 3 footprint drawn under each car, to
      check the anchor).
  python game/tools/build_street_cars.py install --model parked_car_1 --strip <png>
      Cuts the strip into game/art/props/<model>_<rotation>_art.png (cropped) and points the model's textures
      in game/data/level/props.json at them, with their anchors. Nothing else in props.json changes.
  python game/tools/build_street_cars.py check
      Every car model's textures are its _art files, they match a fresh install from the kept strips
      (KEPT[model]), and they pass the rules (alpha 0/255, at most 30 colours, transparent corners).

Needs Pillow and numpy. Same input, same pixels.
"""
from __future__ import annotations

import argparse
import base64
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_sidewalk_car_sample as sample  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
GAME = REPO / "game"
PROPS_JSON = GAME / "data/level/props.json"
PROPS_DIR = GAME / "art/props"
FRAME = 128
ROTATIONS = ["north", "east", "south", "west"]          # top right, bottom right, bottom left, top left
MODELS = ["parked_car_1", "parked_car_2", "parked_car_3", "broken_car_1", "broken_car_2"]
# The kept four-facing strip of each model (the style loop's --out), which install reads.
KEPT = {m: REPO / "art-archive/T-399" / ("%s_facings.png" % m) for m in MODELS}
MAX_COLORS = 30
# The anchor: the pixel over the car's centre on the ground. The car stands about 1 x 2.6 units on the
# ground, so its ground outline is a diamond (1 + 2.6) * 16 art px high, whose lowest corner is about the
# sprite's lowest row: the centre is half that above it.
BASE_UP = 29


# --- PixelLab request ---

def b64_png(path) -> dict:
    return {"type": "base64", "base64": base64.b64encode(Path(path).read_bytes()).decode("ascii"), "format": "png"}


def rotate_request(from_png, colors_png=None, from_direction="north-east", to_direction="south-west", seed=None):
    req = {
        "image_size": {"width": FRAME, "height": FRAME},
        "from_image": b64_png(from_png),
        "color_image": b64_png(colors_png or from_png),
        "image_guidance_scale": 7.5,
        "from_view": "high top-down",
        "to_view": "high top-down",
        "from_direction": from_direction,
        "to_direction": to_direction,
        "direction_change": None,
        "view_change": None,
        "isometric": True,
    }
    if seed is not None:
        req["seed"] = int(seed)
    return req


def rotations_request(first_frame_png, description):
    """A PixelLab /generate-8-rotations-v3 request body: the same car in 8 directions from one picture
    (2 generations; T-101 made the player car's directions this way). One of the 8 faces down the screen."""
    return {"first_frame": b64_png(first_frame_png), "description": description, "no_background": True}


# --- the front lamps (the board, 2026-10-30: only the rear lights are red; the front ones are grey, off) ---

NOSE_DIRS = {"bottom-left": (-2.0, 1.0), "bottom-right": (2.0, 1.0), "top-left": (-2.0, -1.0), "top-right": (2.0, -1.0)}
LAMP_RED_OVER_G, LAMP_RED_OVER_B, LAMP_RED_MIN = 40, 20, 50


def lamp_red(a):
    """Opaque pixels that read as a red lamp (PixelLab's lamps are crimson to magenta-red)."""
    r, g, b = (a[..., i].astype(int) for i in range(3))
    return (a[..., 3] > 0) & (r >= LAMP_RED_MIN) & (r - g >= LAMP_RED_OVER_G) & (r - b >= LAMP_RED_OVER_B)


def unlit_grey(rgb):
    """A red lamp pixel's unlit headlight grey: the same light and dark steps, as cool pale grey glass."""
    r, g, b = (int(v) for v in rgb)
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    v = int(round(min(225.0, 70.0 + 1.3 * lum)))
    return (max(0, v - 6), v, min(255, v + 10))


def repaint_front(a, nose):
    """Turns the red lamps at the car's front end grey and leaves the rear lamps red. `nose` is the way the
    car's nose points on screen (bottom-left, bottom-right, top-left, top-right): the red pixels on that side
    of the car's middle are the headlights. Returns (new picture, number of pixels repainted)."""
    dx, dy = NOSE_DIRS[nose]
    out = a.copy()
    ys, xs = np.nonzero(a[..., 3] > 0)
    cx, cy = xs.mean(), ys.mean()
    red = lamp_red(a)
    yy, xx = np.mgrid[0:a.shape[0], 0:a.shape[1]]
    front = red & (((xx - cx) * dx + (yy - cy) * dy) > 0)
    for y, x in zip(*np.nonzero(front)):
        out[y, x, :3] = unlit_grey(a[y, x, :3])
    return out, int(front.sum())


# --- touch-up (T-399 style loop: free fixes on one cleaned picture, before the strip) ---

LUM = np.array([0.299, 0.587, 0.114])
OUTLINE = (22, 24, 34)            # near-black, cool: rule 2's dark outline
REAR_RED = [(92, 18, 26), (150, 30, 36), (196, 52, 52)]   # unlit tail lamp, dark to light


def _lum(a):
    return a[..., :3].astype(float) @ LUM


def dull_paint(a, lum_min=150.0, sat=0.35, dim=0.9, contrast=1.45, pivot=200.0):
    """Pale paint (lum >= lum_min) to a duller, greyer off-white, its light and dark steps pulled apart
    (contrast around pivot) so the body keeps a clear mid-tone. Other pixels stay."""
    out = a.copy()
    rgb = a[..., :3].astype(float)
    lum = rgb @ LUM
    m = (a[..., 3] > 0) & (lum >= lum_min)
    grey = lum[..., None]
    new = grey + (rgb - grey) * sat
    new = new * dim
    nl = new @ LUM
    new = new + ((pivot + (nl - pivot) * contrast) - nl)[..., None]
    new = new + np.array([-2.0, 0.0, 3.0])          # a touch cooler, toward the city's steel greys
    out[m, :3] = np.clip(np.round(new[m]), 0, 255).astype(np.uint8)
    return out, int(m.sum())


def dark_outline(a, lum_max=90.0, colour=OUTLINE):
    """Silhouette pixels (opaque, next to a transparent one) lighter than lum_max become the dark outline."""
    op = a[..., 3] > 0
    pad = np.pad(op, 1, constant_values=False)
    edge = op & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
    m = edge & (_lum(a) > lum_max)
    out = a.copy()
    out[m, :3] = colour
    return out, int(m.sum())


def _box(a, box):
    x0, y0, x1, y1 = box
    sub = np.zeros(a.shape[:2], bool)
    sub[y0:y1 + 1, x0:x1 + 1] = True
    return sub & (a[..., 3] > 0)


def paint_rear_lamps(a, boxes, lum_max=255.0):
    """Inside each box (x0, y0, x1, y1, inclusive; drawn tight round one lamp) the lamp pixels (lum <=
    lum_max, not the silhouette's outline) become tail-lamp red, in three steps by their lightness.
    Returns (picture, pixels painted)."""
    out = a.copy()
    lum = _lum(a)
    op = a[..., 3] > 0
    pad = np.pad(op, 1, constant_values=False)
    inner = op & pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:]
    n = 0
    for box in boxes:
        m = _box(a, box) & inner & (lum <= lum_max)
        if not m.any():
            continue
        lo, hi = lum[m].min(), lum[m].max()
        for y, x in zip(*np.nonzero(m)):
            t = 0.0 if hi == lo else (lum[y, x] - lo) / (hi - lo)
            out[y, x, :3] = REAR_RED[min(2, int(t * 3))]
        n += int(m.sum())
    return out, n


def flatten(a, boxes):
    """Each box's opaque pixels become their median colour (flattens a badge or scribble marks)."""
    out = a.copy()
    for box in boxes:
        m = _box(a, box)
        if m.any():
            out[m, :3] = np.median(a[m, :3], axis=0).round().astype(np.uint8)
    return out


def touch_up(a, rear_lamps=(), flat=(), dull=True, outline=True):
    n = {}
    if dull:
        a, n["dulled"] = dull_paint(a)
    if flat:
        a = flatten(a, flat)
    if rear_lamps:
        a, n["rear_lamp"] = paint_rear_lamps(a, rear_lamps)
    if outline:
        a, n["outlined"] = dark_outline(a)
    return a, n


# --- wreck (T-399 broken cars: free damage on one cleaned picture, before the strip) ---
# A broken car is a kaiju-attack wreck, light to medium damage (Visual style, Decisions, "City brief"):
# dusty faded paint, a crushed bonnet, cracked glass, scorch marks, rust and grime, a flat tyre. No fire,
# no smoke. Every mark is drawn from a seeded generator, so the same input gives the same pixels.

DUST_TINT = np.array([1.06, 1.0, 0.88])           # faded dusty beige-grey
SCORCH = np.array([38.0, 34.0, 33.0])
RUST = [(112, 66, 40), (86, 50, 32), (138, 88, 52)]
CRACK_LIGHT = (176, 184, 192)
CRACK_DARK = (30, 32, 40)


def _inner(a):
    op = a[..., 3] > 0
    pad = np.pad(op, 1, constant_values=False)
    return op & pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:]


def _glass(a):
    r, g, b = (a[..., i].astype(int) for i in range(3))
    return (a[..., 3] > 0) & (b - r > 14) & (_lum(a) < 170)


def _body(a, lum_min=70.0):
    return _inner(a) & ~_glass(a) & (_lum(a) >= lum_min)


def dusty_paint(a, scale=0.74, lift=8.0, lum_min=95.0):
    """The body paint (not glass, lum >= lum_min) to faded dusty beige-grey: darker, warm grey."""
    out = a.copy()
    lum = _lum(a)
    m = (a[..., 3] > 0) & ~_glass(a) & (lum >= lum_min)
    new = (lum[..., None] * scale + lift) * DUST_TINT
    out[m, :3] = np.clip(np.round(new[m]), 0, 255).astype(np.uint8)
    return out, int(m.sum())


DARK_GREY_TINT = np.array([-2.0, 0.0, 4.0])       # a touch cool, toward the city's steel greys


def dark_grey_paint(a, scale=0.56, lift=10.0, sat=0.08, cap=138.0, glass_lum=50.0):
    """The whole car (not glass, not the red lamps) to dull dark grey: nearly no colour, darker, and its
    lightest step capped at `cap`, so pale highlights and white headlights come out dull, unlit grey.
    The light and dark steps keep their order, so the shading stays (T-399 broken car 2). Glass here is
    only the dark bluish panes (lum < glass_lum): a teal or blue body paint is not glass."""
    out = a.copy()
    rgb = a[..., :3].astype(float)
    lum = rgb @ LUM
    m = (a[..., 3] > 0) & ~(_glass(a) & (lum < glass_lum)) & ~lamp_red(a)
    grey = lum[..., None]
    new = grey + (rgb - grey) * sat
    nl = np.minimum(lum * scale + lift, cap)
    new = new + (nl - new @ LUM)[..., None] + DARK_GREY_TINT
    out[m, :3] = np.clip(np.round(new[m]), 0, 255).astype(np.uint8)
    return out, int(m.sum())


def _walk(rng, x, y, steps, dx, dy):
    pts = []
    for _ in range(steps):
        pts.append((int(round(x)), int(round(y))))
        x += dx + rng.uniform(-0.6, 0.6)
        y += dy + rng.uniform(-0.6, 0.6)
    return pts


def crack_glass(a, box, rng):
    """Shattered glass inside the box: cracks running out from an impact point, light with a dark edge,
    and a few loose shards. Only glass pixels change."""
    out = a.copy()
    gl = _glass(a) & _box(a, box)
    if not gl.any():
        return out, 0
    ys, xs = np.nonzero(gl)
    # The impact near the middle of the pane, so the web spreads over it (a spider-web crack).
    cx = int(round(xs.mean() + rng.uniform(-2, 2)))
    cy = int(round(ys.mean() + rng.uniform(-1, 1)))
    reach = max(xs.max() - xs.min(), ys.max() - ys.min())
    hit = np.zeros(gl.shape, bool)

    def put(px, py):
        if 0 <= py < a.shape[0] and 0 <= px < a.shape[1] and gl[py, px]:
            hit[py, px] = True

    for k in range(8):                                   # radial cracks, nearly straight
        ang = k * np.pi / 4 + rng.uniform(-0.25, 0.25)
        x, y = float(cx), float(cy)
        for _ in range(int(reach)):
            put(int(round(x)), int(round(y)))
            x += np.cos(ang) + rng.uniform(-0.25, 0.25)
            y += np.sin(ang) * 0.7 + rng.uniform(-0.25, 0.25)
    for r in (3.0, 6.5):                                 # the web's rings
        for t in np.linspace(0, 2 * np.pi, int(8 * r), endpoint=False):
            put(int(round(cx + r * np.cos(t))), int(round(cy + r * 0.7 * np.sin(t))))
    out[hit, :3] = CRACK_LIGHT
    for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):     # the hole at the impact
        if 0 <= cy + dy < a.shape[0] and 0 <= cx + dx < a.shape[1] and gl[cy + dy, cx + dx]:
            out[cy + dy, cx + dx, :3] = CRACK_DARK
    return out, int(hit.sum())


def crush(a, box, rng, creases=5):
    """A crushed, dented panel inside the box: jagged creases (a dark fold with a lit ridge above it)
    across the body pixels, and small dents."""
    out = a.copy()
    body = _body(a) & _box(a, box)
    if not body.any():
        return out, 0
    x0, y0, x1, y1 = box
    n = 0
    for c in range(creases):
        y = y0 + (c + 0.5) * (y1 - y0) / creases + rng.uniform(-2, 2)
        x = x0
        while x <= x1:
            yi = int(round(y))
            for py, f in ((yi, 0.42), (yi + 1, 0.62), (yi - 1, 1.12)):
                if 0 <= py < a.shape[0] and body[py, x]:
                    out[py, x, :3] = np.clip(a[py, x, :3] * f, 0, 255).astype(np.uint8)
                    n += 1
            y += rng.choice([-1, 0, 0, 1]) * 0.8 + 0.25
            x += 1
    ys, xs = np.nonzero(body)
    for y, x in zip(ys, xs):
        if rng.random() < 0.06:
            out[y, x, :3] = np.clip(a[y, x, :3] * 0.55, 0, 255).astype(np.uint8)
            n += 1
    return out, n


def scorch(a, box, rng):
    """A black scorch mark inside the box: an uneven blotch, darkest in the middle, ragged at the edge."""
    out = a.copy()
    m = _inner(a) & _box(a, box)
    x0, y0, x1, y1 = box
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    rx, ry = max(1.0, (x1 - x0) / 2), max(1.0, (y1 - y0) / 2)
    n = 0
    for y, x in zip(*np.nonzero(m)):
        d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
        t = 1.0 - d + rng.uniform(-0.35, 0.35)
        if t <= 0.05:
            continue
        k = 0.9 if t > 0.55 else 0.6 if t > 0.3 else 0.35
        out[y, x, :3] = np.round(a[y, x, :3] * (1 - k) + SCORCH * k).astype(np.uint8)
        n += 1
    return out, n


def rust(a, box, rng, density=0.07):
    """Rust and grime in a few distinct patches (small irregular clumps, dark rim, lighter middle) on the
    body inside the box, not an all-over speckle. `density` is roughly the share of the box they cover."""
    out = a.copy()
    m = _body(a, 40.0) & _box(a, box)
    if not m.any():
        return out, 0
    ys, xs = np.nonzero(m)
    clumps = max(1, int(round(len(xs) * density / 9)))
    hit = np.zeros(m.shape, bool)
    for _ in range(clumps):
        i = rng.integers(len(xs))
        cx, cy = xs[i], ys[i]
        r = rng.uniform(1.2, 2.4)
        for dy in range(-3, 4):
            for dx in range(-4, 5):
                d = (dx / (r * 1.4)) ** 2 + (dy / r) ** 2 + rng.uniform(-0.25, 0.25)
                y, x = cy + dy, cx + dx
                if d <= 1.0 and 0 <= y < m.shape[0] and 0 <= x < m.shape[1] and m[y, x]:
                    out[y, x, :3] = RUST[2] if d < 0.3 else RUST[0] if d < 0.7 else RUST[1]
                    hit[y, x] = True
    return out, int(hit.sum())


DENT_DARK, DENT_LIGHT = 0.5, 1.18


def dent(a, box, rng):
    """A big dent in the panel inside the box: a hollow, shaded dark on its upper-left side and lit on
    its lower-right rim, with a dark crumple line along its top edge and short folds running out of it."""
    out = a.copy()
    body = _body(a) & _box(a, box)
    if not body.any():
        return out, 0
    x0, y0, x1, y1 = box
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    rx, ry = max(2.0, (x1 - x0) / 2), max(2.0, (y1 - y0) / 2)
    hit = np.zeros(body.shape, bool)
    for y, x in zip(*np.nonzero(body)):
        u, v = (x - cx) / rx, (y - cy) / ry
        d = u * u + v * v
        if d > 1.0:
            continue
        s = u + v                                        # -: upper left (in shadow), +: lower right (lit)
        if d > 0.72 and s < -0.2:
            f = 0.32                                     # the crumpled top edge
        elif d > 0.6 and s > 0.3:
            f = DENT_LIGHT
        else:
            f = DENT_DARK + 0.35 * (s + 1.4) / 2.8
        out[y, x, :3] = np.clip(a[y, x, :3] * f, 0, 255).astype(np.uint8)
        hit[y, x] = True
    for k in range(5):                                   # folds out of the dent
        ang = np.pi * (0.9 + 0.3 * k) + rng.uniform(-0.2, 0.2)
        x, y = cx + rx * np.cos(ang), cy + ry * np.sin(ang)
        for _ in range(int(rng.integers(3, 6))):
            xi, yi = int(round(x)), int(round(y))
            if 0 <= yi < a.shape[0] and 0 <= xi < a.shape[1] and _body(a)[yi, xi]:
                out[yi, xi, :3] = np.clip(a[yi, xi, :3] * 0.45, 0, 255).astype(np.uint8)
                hit[yi, xi] = True
            x += np.cos(ang) + rng.uniform(-0.4, 0.4)
            y += np.sin(ang) * 0.6 + rng.uniform(-0.4, 0.4)
    return out, int(hit.sum())


def flat_tyre(a, box, sag=0.4):
    """A flat tyre inside the box (drawn round the wheel and a little of the wing above it): the box's
    contents are squashed down onto the tyre's lowest row, so the wheel comes out low and wide and the
    wing above sinks onto it, and its lowest three rows bulge out in the dark outline colour."""
    out = a.copy()
    m = _box(a, box)
    if not m.any():
        return out, 0
    x0, y0, x1, y1 = box
    ys, _ = np.nonzero(m)
    bottom = int(ys.max())
    k = int(round((bottom - y0 + 1) * sag))
    src0 = max(0, y0 - k)
    for x in range(x0, x1 + 1):
        if not (0 <= x < a.shape[1]):
            continue
        col = a[src0:bottom + 1, x].copy()
        for y in range(y0, bottom + 1):
            t = (y - y0) / max(1, bottom - y0)
            out[y, x] = col[int(round(t * (len(col) - 1)))]
    n = int(np.any(out != a, axis=2).sum())
    m = _box(out, box)
    for y, w in ((bottom, 3), (bottom - 1, 2), (bottom - 2, 1)):
        xs = np.nonzero(m[y])[0]
        if not len(xs):
            continue
        for x in list(range(xs.min() - w, xs.min())) + list(range(xs.max() + 1, xs.max() + 1 + w)):
            if 0 <= x < a.shape[1]:
                out[y, x] = (*OUTLINE, 255)
                n += 1
    return out, n


DRUM = [(70, 46, 34), (104, 64, 42)]             # a bare, rusty brake drum, dark and lit


def missing_wheel(a, box):
    """The wheel inside the box is gone: its tyre and rim pixels (opaque, inside the box) become the dark,
    empty wheel arch (the outline colour, a step lighter toward the top), and a small rusty brake drum is
    left at the middle of where the hub was. Run after `flat_tyre` on the same corner so the car sits low
    and tilted there. Returns (picture, pixels changed)."""
    out = a.copy()
    m = _box(a, box)
    if not m.any():
        return out, 0
    ys, xs = np.nonzero(m)
    y0, y1 = ys.min(), ys.max()
    for y, x in zip(ys, xs):
        t = (y - y0) / max(1, y1 - y0)
        out[y, x, :3] = OUTLINE if t > 0.35 else tuple(int(c * 1.6) for c in OUTLINE)
    cx, cy = int(round(xs.mean())), int(round(ys.mean()))
    for dy in range(-2, 3):
        for dx in range(-1, 2):
            y, x = cy + dy, cx + dx
            if 0 <= y < m.shape[0] and 0 <= x < m.shape[1] and m[y, x] and abs(dy) + abs(dx) <= 2:
                out[y, x, :3] = DRUM[1] if dy < 0 else DRUM[0]
    return out, int(np.any(out != a, axis=2).sum())


def paste(a, src_box, dst, darken=1.0):
    """Copies the opaque pixels of src_box (a lump of rubble) so its top-left corner lands at dst (x, y),
    drawn over the car (rubble fallen on the roof). `darken` < 1 dims the copy. Returns (picture, pixels)."""
    out = a.copy()
    x0, y0, x1, y1 = src_box
    dx, dy = dst
    n = 0
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            ty, tx = dy + y - y0, dx + x - x0
            if a[y, x, 3] > 0 and 0 <= ty < a.shape[0] and 0 <= tx < a.shape[1]:
                out[ty, tx, :3] = np.clip(a[y, x, :3] * darken, 0, 255).astype(np.uint8)
                out[ty, tx, 3] = 255
                n += 1
    return out, n


def _purplish(a):
    """PixelLab's lilac rubble, its purple-black outline and the purple ground shadow (red at least green,
    blue above green). The teal or grey car body never is."""
    r, g, b = (a[..., i].astype(int) for i in range(3))
    return (a[..., 3] > 0) & (r >= g) & (b > g)


def clear_rubble(a, src, box, shadow=False):
    """Removes the loose rubble inside the box: the pixels that were purplish in `src` (the picture before
    any paint) become transparent, or the ground shadow's colour when `shadow` (a lump lying over the
    car's shadow). Returns (picture, pixels changed)."""
    out = a.copy()
    m = _box(src, box) & _purplish(src)
    if shadow:
        dark = _purplish(src) & (_lum(src) < 60)
        fill = np.median(src[dark, :3], axis=0).round().astype(np.uint8) if dark.any() else np.array(OUTLINE)
        out[m, :3] = fill
        out[m, 3] = 255
    else:
        out[m] = 0
    return out, int(m.sum())


def neutral_shadow(a, lum_max=60.0):
    """The dark purple pixels (ground shadow, purple-black panes) to a neutral dark blue-grey of the same
    lightness, so no boulder purple is left. Returns (picture, pixels changed)."""
    out = a.copy()
    lum = _lum(a)
    m = _purplish(a) & (lum < lum_max)
    l = lum[m][:, None]
    out[m, :3] = np.clip(np.round(l + np.array([-2.0, 0.0, 6.0])), 0, 255).astype(np.uint8)
    return out, int(m.sum())


PAINTS = ("dusty", "dark-grey", "none")


def wreck(a, crushes=(), cracks=(), scorches=(), rusts=(), flats=(), dusty=True, seed=0, dents=(), paint=None,
          missing=(), rubble=(), clears=(), neutral=False):
    """All the damage on one picture, in a fixed order. `paint` is dusty, dark-grey or none (default: dusty
    when `dusty`, else none). `clears` are (x0, y0, x1, y1[, 1]) boxes of loose rubble to remove at the end
    (1: fill with the shadow); `neutral` turns the purple shadow neutral last. Returns (picture, pixels
    changed per kind)."""
    rng = np.random.default_rng(seed)
    n = {}
    src = a
    paint = paint or ("dusty" if dusty else "none")
    if paint == "dusty":
        a, n["dusty"] = dusty_paint(a)
    elif paint == "dark-grey":
        a, n["dark-grey"] = dark_grey_paint(a)
    for kind, boxes, fn in (("crush", crushes, crush), ("dent", dents, dent), ("crack", cracks, crack_glass),
                            ("scorch", scorches, scorch), ("rust", rusts, rust)):
        for box in boxes:
            a, k = fn(a, box, rng)
            n[kind] = n.get(kind, 0) + k
    for box in flats:
        a, k = flat_tyre(a, box)
        n["flat"] = n.get("flat", 0) + k
    for box in missing:
        a, k = missing_wheel(a, box)
        n["missing"] = n.get("missing", 0) + k
    for spec in rubble:                                  # (x0, y0, x1, y1, dst_x, dst_y)
        a, k = paste(a, spec[:4], spec[4:6], darken=0.85)
        n["rubble"] = n.get("rubble", 0) + k
    for spec in clears:
        a, k = clear_rubble(a, src, spec[:4], shadow=len(spec) > 4 and bool(spec[4]))
        n["clear"] = n.get("clear", 0) + k
    if neutral:
        a, n["neutral"] = neutral_shadow(a)
    return a, n


def grid(a, scale=8, step=8):
    """An enlarged picture with a grid line every `step` px and its coordinate, to read box coordinates."""
    h, w = a.shape[:2]
    img = Image.new("RGBA", (w, h), (60, 60, 72, 255))
    img.alpha_composite(Image.fromarray(a, "RGBA"))
    big = img.resize((w * scale, h * scale), Image.NEAREST)
    d = ImageDraw.Draw(big)
    for v in range(0, max(w, h), step):
        d.line([(v * scale, 0), (v * scale, h * scale)], fill=(0, 255, 255, 110))
        d.line([(0, v * scale), (w * scale, v * scale)], fill=(0, 255, 255, 110))
        d.text((v * scale + 2, 2), str(v), fill=(255, 255, 0, 255))
        d.text((2, v * scale + 2), str(v), fill=(255, 255, 0, 255))
    return big


def _boxes(vals):
    return [tuple(int(v) for v in s.split(",")) for s in (vals or [])]


# --- the strip ---

def binarize(a):
    return sample.binarize_alpha(a)


def shared_palette(frames, max_colors=MAX_COLORS):
    """Reduces the frames together to at most max_colors colours, so every facing uses the same palette."""
    stacked = binarize(np.concatenate(frames, axis=1))
    # The red lamps are few pixels, so a plain reduction merges them into grey: keep their reds exact,
    # within the budget (T-399 parked car 3).
    red = lamp_red(stacked)
    reds = {tuple(c) for c in stacked[red, :3].tolist()} if red.any() else set()
    if reds and len(reds) < max_colors // 4:
        keep = stacked[red].copy()
        stacked = binarize(sample.reduce_colours(stacked, max_colors - len(reds)))
        stacked[red] = keep
    else:
        stacked = binarize(sample.reduce_colours(stacked, max_colors))
    w = frames[0].shape[1]
    return [stacked[:, i * w:(i + 1) * w].copy() for i in range(len(frames))]


def fit_frame(a):
    """The picture in a FRAME x FRAME frame (PixelLab gives 128 x 128 already; a smaller one is centred)."""
    h, w = a.shape[:2]
    if (h, w) == (FRAME, FRAME):
        return a
    if h > FRAME or w > FRAME:
        raise ValueError("picture larger than %d x %d: %dx%d" % (FRAME, FRAME, w, h))
    out = np.zeros((FRAME, FRAME, 4), np.uint8)
    y, x = (FRAME - h) // 2, (FRAME - w) // 2
    out[y:y + h, x:x + w] = a
    return out


def make_strip(top, top_is_right, bottom, bottom_is_left, max_colors=MAX_COLORS):
    """One row of four frames: north (top right), east (bottom right), south (bottom left), west (top left)."""
    top, bottom = binarize(fit_frame(top)), binarize(fit_frame(bottom))
    top, bottom = shared_palette([top, bottom], max_colors)
    tr = top if top_is_right else top[:, ::-1]
    bl = bottom if bottom_is_left else bottom[:, ::-1]
    frames = {"north": tr, "east": bl[:, ::-1], "south": bl, "west": tr[:, ::-1]}
    return np.concatenate([frames[r] for r in ROTATIONS], axis=1).copy()


def split_strip(strip):
    if strip.shape[0] != FRAME or strip.shape[1] != FRAME * 4:
        raise ValueError("a strip is %d x %d, got %d x %d" % (FRAME * 4, FRAME, strip.shape[1], strip.shape[0]))
    return {r: strip[:, i * FRAME:(i + 1) * FRAME].copy() for i, r in enumerate(ROTATIONS)}


# --- install ---

def crop(a):
    ys, xs = np.nonzero(a[..., 3] > 0)
    if len(ys) == 0:
        raise ValueError("an empty frame")
    return a[ys.min():ys.max() + 1, xs.min():xs.max() + 1].copy()


def anchor_for(a):
    h, w = a.shape[:2]
    ys = np.nonzero((a[..., 3] > 0).any(axis=1))[0]
    return [(w - 1) // 2, max(0, int(ys.max()) - BASE_UP)]


def sprite_name(model, rotation):
    return "%s_%s_art" % (model, rotation)


def prop_id(model):
    return "prop-" + model.replace("_", "-")


def installed(strip):
    """{rotation: (cropped sprite, anchor)} for a strip."""
    out = {}
    for r, f in split_strip(strip).items():
        c = crop(f)
        out[r] = (c, anchor_for(c))
    return out


def install(model, strip_png, props_json=PROPS_JSON, out_dir=PROPS_DIR):
    if model not in MODELS:
        raise ValueError("unknown model %s (one of %s)" % (model, ", ".join(MODELS)))
    strip = sample.load_rgba(strip_png)
    data = json.loads(Path(props_json).read_text(encoding="utf-8"))
    prop = next(p for p in data["props"] if p["id"] == prop_id(model))
    textures = {}
    Path(out_dir).mkdir(parents=True, exist_ok=True)
    for r, (img, anc) in installed(strip).items():
        fn = sprite_name(model, r)
        Image.fromarray(img, "RGBA").save(Path(out_dir) / (fn + ".png"))
        textures[r] = {"texture": "res://art/props/%s.png" % fn, "anchor_px": anc}
    prop["textures"] = textures
    Path(props_json).write_text(json.dumps(data, indent=1) + "\n", encoding="utf-8", newline="\n")
    return textures


# --- rules and check ---

def rules(a):
    problems = []
    al = a[..., 3]
    if not np.all((al == 0) | (al == 255)):
        problems.append("alpha is not 0 or 255")
    n = len({tuple(int(v) for v in c[:3]) for c in a[al == 255]})
    if n > MAX_COLORS:
        problems.append("%d colours (at most %d)" % (n, MAX_COLORS))
    if al[0, 0] or al[0, -1] or al[-1, 0] or al[-1, -1]:
        problems.append("a corner is not transparent")
    return problems


def check(props_json=PROPS_JSON, kept=None) -> int:
    kept = kept or KEPT
    data = json.loads(Path(props_json).read_text(encoding="utf-8"))
    ok = True
    for model in MODELS:
        prop = next(p for p in data["props"] if p["id"] == prop_id(model))
        fresh = installed(sample.load_rgba(kept[model])) if Path(kept[model]).is_file() else None
        if fresh is None:
            print("FAIL  %s: no kept strip at %s" % (model, kept[model]))
            ok = False
        for r in ROTATIONS:
            t = prop["textures"][r]
            if t["texture"] != "res://art/props/%s.png" % sprite_name(model, r):
                print("FAIL  %s %s: not the final art (%s)" % (model, r, t["texture"]))
                ok = False
                continue
            png = GAME / t["texture"].replace("res://", "")
            if not png.is_file():
                print("FAIL  %s %s: missing" % (model, r))
                ok = False
                continue
            a = sample.load_rgba(png)
            for p in rules(a):
                print("FAIL  %s %s: %s" % (model, r, p))
                ok = False
            if fresh is not None:
                img, anc = fresh[r]
                if not np.array_equal(a, img) or list(t["anchor_px"]) != anc:
                    print("FAIL  %s %s: differs from a fresh install" % (model, r))
                    ok = False
    print("OK" if ok else "FAILED")
    return 0 if ok else 1


# --- the preview ---

def ground_poly(cu, cv, wu, wv, ox, oy):
    """Screen polygon of a wu x wv ground rectangle centred on (cu, cv)."""
    pts = [(cu - wu / 2, cv - wv / 2), (cu + wu / 2, cv - wv / 2), (cu + wu / 2, cv + wv / 2), (cu - wu / 2, cv + wv / 2)]
    return [sample.screen(u, v, ox, oy) for u, v in pts]


def compose(strip, bg, footprints=False):
    """Road along y at u in [4, 8) with T-397's curbed sidewalk at u in [0, 4), gravel beyond; the four facings
    at the curb and on the road, each placed by its anchor at a footprint centre, at the game's art scale."""
    W, H = 900, 640
    ox, oy = 420, 150
    canvas = Image.new("RGBA", (W, H), (*bg, 255))
    side = Image.fromarray(sample.draw_sidewalk(), "RGBA")
    plain = Image.fromarray(sample.draw_sidewalk(curb=False), "RGBA")
    gravel = sample.ground_tile("gravel0")
    road_r, road_l = sample.ground_tile("y_line_r_a0"), sample.ground_tile("y_line_l_a0")
    for j in range(7):
        for i, tile in enumerate([plain, side, road_r, road_l, gravel, gravel]):
            x, y = sample.screen(2 * i, 2 * j, ox, oy)
            canvas.alpha_composite(tile, (x - sample.TILE_W // 2, y))
    bld = Image.open(REPO / "game/art/buildings/creator_final/small_0.png").convert("RGBA")
    fx, fy = sample.screen(0, 6, ox, oy)
    canvas.alpha_composite(bld, (fx - 192, fy - 330))
    bo = Image.open(REPO / "game/art/boulders/boulder_a.png").convert("RGBA")
    cx, cy = sample.screen(10.0, 2.5, ox, oy)
    canvas.alpha_composite(bo, (cx - (32 + 131) // 2, cy + 24 - 120))
    # (rotation, footprint centre u, v); north and south lie along y (3 long), east and west along x
    spots = [("north", 5.0, 3.5), ("south", 5.0, 8.0), ("east", 9.5, 7.0), ("west", 9.5, 10.5)]
    sprites = installed(strip)
    if footprints:
        d = ImageDraw.Draw(canvas)
        for r, cu, cv in spots:
            wu, wv = (2, 3) if r in ("north", "south") else (3, 2)
            d.polygon(ground_poly(cu, cv, wu, wv, ox, oy), outline=(255, 210, 60, 255))
    for r, cu, cv in sorted(spots, key=lambda s: s[1] + s[2]):
        img, (ax, ay) = sprites[r]
        x, y = sample.screen(cu, cv, ox, oy)
        canvas.alpha_composite(Image.fromarray(img, "RGBA"), (x - ax, y - ay))
    if footprints:
        d = ImageDraw.Draw(canvas)
        for r, cu, cv in spots:
            x, y = sample.screen(cu, cv, ox, oy)
            d.rectangle((x - 1, y - 1, x + 1, y + 1), fill=(255, 210, 60, 255))
    return canvas


def preview(strip_png, out_dir):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    strip = sample.load_rgba(strip_png)
    dark = sample.enlarge(compose(strip, (20, 20, 30)))
    light = sample.enlarge(compose(strip, (225, 225, 230)))
    dark.save(out_dir / "preview_dark.png")
    light.save(out_dir / "preview_light.png")
    both = Image.new("RGBA", (dark.width * 2 + 24, dark.height), (128, 128, 128, 255))
    both.alpha_composite(dark, (0, 0))
    both.alpha_composite(light, (dark.width + 24, 0))
    both.save(out_dir / "preview_side_by_side.png")
    sample.enlarge(compose(strip, (20, 20, 30), footprints=True), 2).save(out_dir / "footprints.png")
    big = Image.new("RGBA", (strip.shape[1], strip.shape[0]), (20, 20, 30, 255))
    big.alpha_composite(Image.fromarray(strip, "RGBA"))
    sample.enlarge(big, 4).save(out_dir / "strip_4x.png")
    return out_dir / "preview_side_by_side.png"


# --- command line ---

def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("rotate-request")
    r.add_argument("--from", dest="src", required=True)
    r.add_argument("--out", required=True)
    r.add_argument("--from-direction", default="north-east")
    r.add_argument("--to-direction", default="south-west")
    r.add_argument("--colors")
    r.add_argument("--seed", type=int)
    r8 = sub.add_parser("rotations-request")
    r8.add_argument("--from", dest="src", required=True)
    r8.add_argument("--description", required=True)
    r8.add_argument("--out", required=True)
    fr = sub.add_parser("repaint-front")
    fr.add_argument("--in", dest="src", required=True)
    fr.add_argument("--out", required=True)
    fr.add_argument("--nose", required=True, choices=sorted(NOSE_DIRS))
    tu = sub.add_parser("touch-up")
    tu.add_argument("--in", dest="src", required=True)
    tu.add_argument("--out", required=True)
    tu.add_argument("--rear-lamp", action="append", help="x0,y0,x1,y1 box around one rear lamp")
    tu.add_argument("--flatten", action="append", help="x0,y0,x1,y1 box to flatten to one colour")
    tu.add_argument("--no-dull", action="store_true")
    tu.add_argument("--no-outline", action="store_true")
    wr = sub.add_parser("wreck")
    wr.add_argument("--in", dest="src", required=True)
    wr.add_argument("--out", required=True)
    for flag in ("crush", "dent", "crack", "scorch", "rust", "flat"):
        wr.add_argument("--" + flag, action="append", help="x0,y0,x1,y1 box (repeatable)")
    wr.add_argument("--missing", action="append", help="x0,y0,x1,y1 box tight round a wheel to remove")
    wr.add_argument("--rubble", action="append", help="x0,y0,x1,y1,dst_x,dst_y: copy a rubble lump onto the car")
    wr.add_argument("--clear", action="append", help="x0,y0,x1,y1[,1]: remove loose rubble (1: leave shadow)")
    wr.add_argument("--neutral-shadow", action="store_true", help="purple shadow and panes to neutral")
    wr.add_argument("--no-dusty", action="store_true")
    wr.add_argument("--paint", choices=PAINTS, help="body paint first (default dusty; --no-dusty = none)")
    wr.add_argument("--seed", type=int, default=0)
    gr = sub.add_parser("grid")
    gr.add_argument("--in", dest="src", required=True)
    gr.add_argument("--out", required=True)
    c = sub.add_parser("clean")
    c.add_argument("--raw", required=True)
    c.add_argument("--out", required=True)
    c.add_argument("--mirror", action="store_true")
    s = sub.add_parser("strip")
    s.add_argument("--out", required=True)
    g = s.add_mutually_exclusive_group(required=True)
    g.add_argument("--top-right")
    g.add_argument("--top-left")
    g2 = s.add_mutually_exclusive_group(required=True)
    g2.add_argument("--bottom-left")
    g2.add_argument("--bottom-right")
    s.add_argument("--max-colors", type=int, default=MAX_COLORS)
    p = sub.add_parser("preview")
    p.add_argument("--strip", required=True)
    p.add_argument("--out-dir", required=True)
    i = sub.add_parser("install")
    i.add_argument("--model", required=True, choices=MODELS)
    i.add_argument("--strip")
    sub.add_parser("check")
    a = ap.parse_args(argv)

    if a.cmd == "rotate-request":
        req = rotate_request(a.src, a.colors, a.from_direction, a.to_direction, a.seed)
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Path(a.out).write_text(json.dumps(req, indent=1) + "\n", encoding="utf-8")
        print("Wrote %s (/rotate %s -> %s)" % (a.out, a.from_direction, a.to_direction))
    elif a.cmd == "rotations-request":
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Path(a.out).write_text(json.dumps(rotations_request(a.src, a.description), indent=1) + "\n", encoding="utf-8")
        print("Wrote %s (/generate-8-rotations-v3)" % a.out)
    elif a.cmd == "repaint-front":
        out, n = repaint_front(sample.load_rgba(a.src), a.nose)
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(out, "RGBA").save(a.out)
        print("Wrote %s (%d front lamp pixels made grey, nose %s)" % (a.out, n, a.nose))
    elif a.cmd == "touch-up":
        out, n = touch_up(sample.load_rgba(a.src), _boxes(a.rear_lamp), _boxes(a.flatten),
                          dull=not a.no_dull, outline=not a.no_outline)
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(out, "RGBA").save(a.out)
        print("Wrote %s (%s)" % (a.out, ", ".join("%s %d px" % kv for kv in n.items())))
    elif a.cmd == "wreck":
        out, n = wreck(sample.load_rgba(a.src), _boxes(a.crush), _boxes(a.crack), _boxes(a.scorch),
                       _boxes(a.rust), _boxes(a.flat), dusty=not a.no_dusty, seed=a.seed,
                       dents=_boxes(a.dent), paint=a.paint, missing=_boxes(a.missing),
                       rubble=_boxes(a.rubble), clears=_boxes(a.clear), neutral=a.neutral_shadow)
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(out, "RGBA").save(a.out)
        print("Wrote %s (%s)" % (a.out, ", ".join("%s %d px" % kv for kv in n.items())))
    elif a.cmd == "grid":
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        grid(sample.load_rgba(a.src)).save(a.out)
        print("Wrote %s" % a.out)
    elif a.cmd == "clean":
        out = sample.clean_car(a.raw, mirror=a.mirror)
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(out, "RGBA").save(a.out)
        print("Wrote %s (%d colours)" % (a.out, len(sample.colours(out))))
    elif a.cmd == "strip":
        top = sample.load_rgba(a.top_right or a.top_left)
        bottom = sample.load_rgba(a.bottom_left or a.bottom_right)
        out = make_strip(top, bool(a.top_right), bottom, bool(a.bottom_left), a.max_colors)
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(out, "RGBA").save(a.out)
        print("Wrote %s (%d colours; frames north, east, south, west)" % (a.out, len(sample.colours(out))))
    elif a.cmd == "preview":
        print("Wrote %s" % preview(a.strip, a.out_dir))
    elif a.cmd == "install":
        t = install(a.model, a.strip or KEPT[a.model])
        print("Installed %s: %s" % (a.model, ", ".join("%s %s" % (r, v["anchor_px"]) for r, v in t.items())))
    elif a.cmd == "check":
        return check()
    return 0


if __name__ == "__main__":
    sys.exit(main())
