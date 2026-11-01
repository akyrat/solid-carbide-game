#!/usr/bin/env python3
"""The shared button's plates (task T-447; HUD and menus, Decisions, "One button style across the game").

Five 9-slice plates (the focus one is a ring with an open middle, drawn over the current state), one per state (normal, hover, focus, pressed, disabled), 72 x 22 art pixels, drawn at 1x and
shown by the game at 2x (HUD style sheet, rule 1). They follow the sheet's rules: a 1 pixel near-black outline
(8, 8, 15), a stepped corner of radius 2 (rule 4), a steel bezel lit from the top left (rule 3), flat fills and
two or three steps of shading (rule 7), only alpha 0 or 255, no Greenbull colour. The slice margins are 3 art
pixels on every side (outline + two bevel rows), so a plate stretches to any button size.

  python game/tools/build_button_plates.py build [--out-dir game/art/ui] [--state NAME --out FILE]

Deterministic, no PixelLab (0 generations). `build` writes game/art/ui/button_plate_<state>.png and
game/art/ui/button_plates.json (the record). The style loop's tool calls it with `--state`/`--out` for one plate.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

W, H = 72, 22
SLICE = 3                       # art pixels on every side
STATES = ["normal", "hover", "focus", "pressed", "disabled"]
OUT = (8, 8, 15)
# Per state: hi = the lit top and left bevel row, mid = the second bevel row there, lo = the shaded bottom and
# right bevel row, edge = the shaded second row, face = the fill, shade = the face's last row (under the bevel),
# glint = the lighter top row (None for none).
PALETTE = {
    "normal":   dict(hi=(132, 143, 168), mid=(92, 102, 124), lo=(26, 29, 38), edge=(40, 44, 57),
                     face=(62, 69, 86), shade=(50, 56, 71), glint=(196, 206, 228)),
    "hover":    dict(hi=(172, 184, 210), mid=(118, 130, 156), lo=(30, 34, 45), edge=(50, 56, 72),
                     face=(84, 94, 118), shade=(70, 79, 101), glint=(235, 242, 255)),
    # The keyboard selection is a ring over whichever state the button is in: bright bezel, transparent inside.
    "focus":    dict(hi=(255, 255, 255), mid=(235, 242, 255), lo=(172, 184, 210), edge=(172, 184, 210),
                     face=None, shade=None, glint=(255, 255, 255)),
    "pressed":  dict(hi=(26, 29, 38), mid=(34, 38, 49), lo=(92, 102, 124), edge=(66, 73, 90),
                     face=(40, 44, 57), shade=(40, 44, 57), glint=None),
    "disabled": dict(hi=(48, 52, 62), mid=(37, 40, 49), lo=(21, 23, 30), edge=(26, 28, 36),
                     face=(30, 33, 41), shade=(30, 33, 41), glint=None),
}


def draw(state: str) -> Image.Image:
    p = PALETTE[state]
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    cut = {(0, 0), (1, 0), (0, 1), (W - 1, 0), (W - 2, 0), (W - 1, 1),
           (0, H - 1), (1, H - 1), (0, H - 2), (W - 1, H - 1), (W - 2, H - 1), (W - 1, H - 2)}
    corner_outline = {(1, 1), (W - 2, 1), (1, H - 2), (W - 2, H - 2)}
    for y in range(H):
        for x in range(W):
            if (x, y) in cut:
                continue
            d_left, d_right, d_top, d_bot = x, W - 1 - x, y, H - 1 - y
            if min(d_left, d_right, d_top, d_bot) == 0 or (x, y) in corner_outline:
                c = OUT
            elif d_top == 1 or d_left == 1:
                c = p["hi"]
            elif d_bot == 1 or d_right == 1:
                c = p["lo"]
            elif d_top == 2 or d_left == 2:
                c = p["mid"]
            elif d_bot == 2 or d_right == 2:
                c = p["edge"]
            elif d_bot == 3:
                c = p["shade"]
            else:
                c = p["face"]
            if c is None:
                continue                                  # the focus ring's open middle
            px[x, y] = c + (255,)
    if p["glint"]:                                        # the lit top row's glint, whole width so it stretches flat
        for x in range(2, W - 2):
            px[x, 1] = p["glint"] + (255,)
    return im


def record(files: dict) -> dict:
    return {
        "task": "T-447",
        "what": "The shared button's 9-slice plates, one per state: normal, hover, focus (keyboard selected), "
                "pressed, disabled. 72 x 22 art pixels, slice margins 3 on every side, shown at 2x.",
        "made_by": "game/tools/build_button_plates.py (drawn by script; no PixelLab call, 0 generations). "
                   "Byte-identical every run.",
        "size": [W, H],
        "slice": SLICE,
        "files": files,
        "references": ["docs/visual-style.md (Content, Rules; the HUD style sheet)", "docs/hud-and-menus.md",
                       "game/art/hud/clock_panel.png (the bezel)"],
        "prompt": None,
    }


def build(out_dir: Path) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    paths = []
    for s in STATES:
        f = out_dir / f"button_plate_{s}.png"
        draw(s).save(f)
        paths.append(f)
    (out_dir / "button_plates.json").write_text(
        json.dumps(record({s: f"button_plate_{s}.png" for s in STATES}), indent=1) + "\n", encoding="utf-8")
    return paths


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("cmd", choices=["build"])
    ap.add_argument("--out-dir", default="game/art/ui")
    ap.add_argument("--state", choices=STATES)
    ap.add_argument("--out")
    a = ap.parse_args(argv)
    if a.state:
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        draw(a.state).save(a.out)
        print(a.out)
    else:
        for f in build(Path(a.out_dir)):
            print(f)
    return 0


if __name__ == "__main__":
    sys.exit(main())
