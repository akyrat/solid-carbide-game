#!/usr/bin/env python3
"""Draws the gift pack drop's placeholder art (task T-144; no PixelLab call, 0 generations).

Two simple shapes so the board can play the gift pack drop before any art exists:
- the helicopter (side view, flying to the right): a steel-blue body with a pale window, a
  tail boom, a dark rotor on top and skids below;
- the package: a cardboard-tan box with a cyan ribbon and bow.
Both have a 1 pixel dark outline, a transparent background and no semi-transparent pixels.
No Redgull red and no other red (docs/working-with-the-board.md, "Placeholders never use
Redgull red"). The final art replaces them in tasks T-145 (helicopter) and T-146 (package):
see game/README.md, "The gift pack drop".

Commands (run from the repo root):
  python game/tools/build_gift_placeholders.py build    # game/art/gift_pack/*_placeholder.png
  python game/tools/build_gift_placeholders.py check    # checks the committed PNGs (exit 1 on a fail)

Running build twice gives byte-identical files.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_drift_mark as marks  # noqa: E402  (shared Redgull-red check)
import check_sprite_rules as rules  # noqa: E402
from remove_car_shadow import write_png  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
OUT_DIR = GAME / "art" / "gift_pack"
HELICOPTER_PNG = OUT_DIR / "helicopter_placeholder.png"
PACKAGE_PNG = OUT_DIR / "package_placeholder.png"

CLEAR = (0, 0, 0, 0)
OUTLINE = (14, 16, 26)
DARK = (44, 48, 62)       # rotor, skids, tail rotor
BODY = (86, 128, 170)     # steel blue
BODY_DARK = (60, 92, 128)
WINDOW = (170, 225, 240)
BOX = (205, 165, 95)      # cardboard tan
BOX_DARK = (176, 148, 90)
LID = (228, 194, 128)
RIBBON = (70, 200, 220)   # cyan

HELICOPTER_SIZE = (42, 20)
PACKAGE_SIZE = (16, 16)


def _canvas(size):
    w, h = size
    return [[CLEAR for _ in range(w)] for _ in range(h)]


def _rect(img, x0, y0, x1, y1, colour):
    """Fills x0..x1, y0..y1 (inclusive)."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            img[y][x] = colour + (255,)


def _outline(img):
    """A 1 pixel OUTLINE around every opaque pixel, on the transparent ones."""
    h, w = len(img), len(img[0])
    out = [list(r) for r in img]
    for y in range(h):
        for x in range(w):
            if img[y][x][3]:
                continue
            near = any(0 <= x + dx < w and 0 <= y + dy < h and img[y + dy][x + dx][3]
                       for dx in (-1, 0, 1) for dy in (-1, 0, 1))
            if near:
                out[y][x] = OUTLINE + (255,)
    return out


def helicopter_rows():
    img = _canvas(HELICOPTER_SIZE)
    _rect(img, 4, 1, 37, 1, DARK)        # main rotor
    _rect(img, 20, 2, 21, 3, DARK)       # rotor mast
    _rect(img, 13, 4, 32, 13, BODY)      # cabin
    _rect(img, 13, 11, 32, 13, BODY_DARK)  # belly shade
    _rect(img, 33, 6, 34, 11, BODY)      # nose
    _rect(img, 26, 6, 32, 9, WINDOW)     # window
    _rect(img, 2, 7, 12, 9, BODY_DARK)   # tail boom
    _rect(img, 1, 4, 2, 12, DARK)        # tail rotor
    _rect(img, 16, 14, 16, 15, DARK)     # struts
    _rect(img, 29, 14, 29, 15, DARK)
    _rect(img, 11, 16, 34, 16, DARK)     # skids
    return _outline(img)


def package_rows():
    img = _canvas(PACKAGE_SIZE)
    _rect(img, 2, 5, 13, 14, BOX)        # box
    _rect(img, 2, 12, 13, 14, BOX_DARK)  # shaded bottom
    _rect(img, 1, 4, 14, 6, LID)         # lid
    _rect(img, 7, 4, 8, 14, RIBBON)      # ribbon, down
    _rect(img, 1, 8, 14, 9, RIBBON)      # ribbon, across
    _rect(img, 4, 1, 6, 3, RIBBON)       # bow
    _rect(img, 9, 1, 11, 3, RIBBON)
    return _outline(img)


def check_rows(img, size):
    results = []
    results.append(("size %dx%d" % size, (len(img[0]), len(img)) == size, "%dx%d" % (len(img[0]), len(img))))
    alphas = {p[3] for r in img for p in r}
    results.append(("no semi-transparent pixels", alphas <= {0, 255}, str(sorted(alphas))))
    colours = {p[:3] for r in img for p in r if p[3]}
    results.append(("has opaque pixels", len(colours) > 0, str(len(colours))))
    results.append(("about 30 colours or fewer", len(colours) <= 30, str(len(colours))))
    reds = [c for c in colours if marks.is_redgull_red(c) or (c[0] > 128 and c[1] < 100 and c[2] < 100)]
    results.append(("no Redgull red, no red", not reds, str(reds)))
    edge = [p for p in img[0] + img[-1] + [r[0] for r in img] + [r[-1] for r in img]]
    results.append(("transparent or outline at the edge", all(p[3] == 0 or p[:3] == OUTLINE for p in edge), ""))
    return results


def check(paths=(HELICOPTER_PNG, PACKAGE_PNG)):
    out = []
    for path, size in zip(paths, (HELICOPTER_SIZE, PACKAGE_SIZE)):
        _, _, img = rules.decode_png(Path(path).read_bytes())
        out += [(Path(path).name + ": " + rule, ok, detail) for rule, ok, detail in check_rows(img, size)]
    return out


def build(out_dir=OUT_DIR):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    write_png(out_dir / HELICOPTER_PNG.name, helicopter_rows())
    write_png(out_dir / PACKAGE_PNG.name, package_rows())
    return out_dir


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("command", choices=["build", "check"])
    a = ap.parse_args(argv)
    if a.command == "check":
        res = check()
        for rule, ok, detail in res:
            print(("PASS " if ok else "FAIL ") + rule + ": " + detail)
        return 0 if all(r[1] for r in res) else 1
    print("wrote the gift pack placeholders in", build())
    return 0


if __name__ == "__main__":
    sys.exit(main())
