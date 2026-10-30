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


# --- the strip ---

def binarize(a):
    return sample.binarize_alpha(a)


def shared_palette(frames, max_colors=MAX_COLORS):
    """Reduces the frames together to at most max_colors colours, so every facing uses the same palette."""
    stacked = np.concatenate(frames, axis=1)
    stacked = binarize(sample.reduce_colours(binarize(stacked), max_colors))
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
