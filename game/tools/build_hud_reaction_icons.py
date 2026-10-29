#!/usr/bin/env python3
"""The reaction icons (task T-352; HUD and menus, Decisions, "The HUD looks like a livestream").

Six small icons for the livestream bursts and floaters (game/scripts/hud/reactions.gd): heart, thumbs up,
fire, clapping hands, star, smiling face. Hand-placed pixel grids (no PixelLab, 0 generations), each 16 x 16
with a 1 pixel dark HUD outline drawn round the shape, hard edges, opaque or empty pixels only, none of
Greenbull's light green or yellow (rule 6). Shown at 2x. Deterministic.

  python game/tools/build_hud_reaction_icons.py build --out-dir game/art/hud [--force]
  python game/tools/build_hud_reaction_icons.py contact --out SHEET.png
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hud_livestream_art as hud  # noqa: E402

SIZE = 16
NAMES = ["heart", "thumbs_up", "fire", "clapping", "star", "smile"]
# T-356: the six bad reactions when the combo breaks (placeholders drawn by script, like the good ones).
BAD_NAMES = ["cry_laugh", "thumbs_down", "peek", "broken_heart", "skull", "scream"]
PAL = {
    "r": (232, 40, 70), "R": (160, 16, 48), "w": (255, 190, 205),            # heart: red, shade, shine
    "p": (255, 176, 120), "P": (214, 120, 70), "v": (150, 110, 240),          # skin, skin shade, cuff
    "o": (255, 98, 20), "a": (255, 160, 30), "h": (255, 236, 190),            # fire: orange, amber, hot
    "s": (255, 150, 40), "S": (200, 90, 20), "l": (255, 205, 130),            # star / face body, shade, light
    "k": (60, 30, 40), "m": (255, 120, 170),                                  # features, pink
    "b": (90, 170, 255), "W": (240, 240, 245), "G": (140, 140, 160), "d": (120, 20, 50),  # tear, white, grey, mouth
}
GRIDS = {
    "heart": [
        "..rrrr...rrrr..",
        ".rrwwrr.rrrrrr.",
        "rrwwrrrrrrrrrrR",
        "rrwrrrrrrrrrrrR",
        "rrrrrrrrrrrrrrR",
        "rrrrrrrrrrrrrRR",
        ".rrrrrrrrrrrRR.",
        "..rrrrrrrrrRR..",
        "...rrrrrrrRR...",
        "....rrrrrRR....",
        ".....rrrRR.....",
        "......rRR......",
        ".......R.......",
    ],
    "thumbs_up": [
        "........pp.....",
        ".......pppp....",
        ".......pppp....",
        ".......pppp....",
        ".......ppppp...",
        "vvv..pppppppppP",
        "vvv..pppppppppP",
        "vvv..ppppPPPPpP",
        "vvv..pppppppppP",
        "vvv..ppppPPPPpP",
        "vvv..pppppppppP",
        "vvv...ppppppPP.",
        "......PPPPPPP..",
    ],
    "fire": [
        ".......o.......",
        ".......oo......",
        "......ooo..o...",
        "......oooo.oo..",
        ".....ooaaooo...",
        "....oooaaaooo..",
        "....ooaaaaaoo..",
        "...oooaahhaaoo.",
        "...ooaahhhhaoo.",
        "...ooaahhhhaoo.",
        "...ooaaahhaaoo.",
        "....oooaaaaoo..",
        ".....oooooooo..",
        "......oooooo...",
    ],
    "clapping": [
        "......hh......",
        "..h...hh...h..",
        "...h..pp..h...",
        "......lp......",
        ".....lppp.....",
        "....llpppp....",
        "...lppppppp...".replace("ppppppp","pppppp"),
        "..lppp..pppp..",
        ".lpppp....pppp",
        ".lpppP..Ppppp.",
        ".pppPP..PPppp.",
        ".vvvv....vvvv.",
        ".vvvv....vvvv.",
    ],
    "star": [
        ".......s.......",
        ".......s.......",
        "......sls......",
        "......sls......",
        "ssssssslsssssss",
        ".sllllllllllls.",
        "..sllllllllls..",
        "...slllllllsS..",
        "...sllllllsSS..",
        "..sllllsllllsS.",
        "..sllssSsssllS.",
        ".sllsSS.SSsllS.",
        ".ssSS.....SSSS.",
    ],
    "smile": [
        "....ssssssss...",
        "..ssllllsssssS.",
        ".sllllsssssssSS",
        ".sllssssssssssS",
        "ssllsskksskksSS",
        "sssssskksskksSS",
        "sssssskksskksSS",
        "ssssssssssssssS",
        "sskssssssssksSS",
        ".sskkssssskksSS",
        ".ssskkkkkkksssS",
        "..sssssssssSSS.",
        "....SSSSSSSS...",
    ],
}

GRIDS["cry_laugh"] = [
    "....ssssssss...",
    "..sssssssssssS.",
    ".ssskssssskssSS",
    ".sssskssskssSSS",
    ".ssskssssskssSS",
    "bssssssssssssSS",
    "bbsskkkkkkksssS",
    "bbsdddddddddssS",
    ".bsdWWWWWWWdssS",
    "..sdddddddddsS.",
    "...ssdddddssS..",
    "....SSSSSSSS...",
]
GRIDS["thumbs_down"] = GRIDS["thumbs_up"][::-1]
GRIDS["peek"] = [
    "....ssssssss...",
    "..sssssssssssS.",
    ".sssssssssssssS",
    ".ssWWsssssWWssS",
    ".ssWkssssskWssS",
    ".ppppppsppppppP",
    ".ppppppsppppppP",
    ".pppPPPsPPPpppP",
    ".ppppppsppppppP",
    "..PPPPPsPPPPPP.",
    "....SSSSSSSS...",
]
GRIDS["broken_heart"] = [
    "..rrrr...rrrr..",
    ".rrwwrr.rrrrrr.",
    "rrwwrrr.rrrrrrR",
    "rrwrrr.rrrrrrrR",
    "rrrrrrr.rrrrrrR",
    "rrrrrr.rrrrrrRR",
    ".rrrrrr.rrrrRR.",
    "..rrrr.rrrrrRR.",
    "...rrrr.rrrRR..",
    "....rrr.rrRR...",
    ".....rr.rRR....",
    "......r.RR.....",
    ".......R.......",
]
GRIDS["skull"] = [
    "....WWWWWWW....",
    "..WWWWWWWWWWW..",
    ".WWWWWWWWWWWWG.",
    ".WWWWWWWWWWWWG.",
    ".WWkkkWWWkkkWG.",
    ".WkkkkkWkkkkkG.",
    ".WkkkkkWkkkkkG.",
    ".WWkkkWWWkkkWG.",
    "..WWWWWkWWWWG..",
    "...WWWWWWWWG...",
    "...WkWkWkWkWG..",
    "...WWWWWWWWG...",
]
GRIDS["scream"] = [
    "....ssssssss...",
    "..sssssssssssS.",
    ".sssssssssssssS",
    ".sWWWsssssWWWsS",
    ".sWkWsssssWkWsS",
    ".sWWWsssssWWWsS",
    "ssssssssssssssS",
    "ssssskkkkksssSS",
    ".sssskdddkssssS",
    ".sssskdddkssssS",
    "..ssskkkkksssS.",
    "....SSSSSSSS...",
]


def draw(name: str) -> Image.Image:
    rows = GRIDS[name]
    w = max(len(r) for r in rows)
    im = hud.new(SIZE, SIZE)
    ox, oy = (SIZE - w) // 2, (SIZE - len(rows)) // 2
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                hud.put(im, ox + x, oy + y, PAL[ch])
    shape = {(x, y) for y in range(SIZE) for x in range(SIZE) if hud.opaque(im, x, y)}
    for y in range(SIZE):
        for x in range(SIZE):
            if (x, y) not in shape and any((x + dx, y + dy) in shape for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                hud.put(im, x, y, hud.OUT)
    return im


def record(name: str) -> dict:
    return {
        "task": "T-356" if name in BAD_NAMES else "T-352",
        "what": f"The {name.replace('_', ' ')} reaction icon: a small comic HUD pixel icon with a dark outline.",
        "made_by": "game/tools/build_hud_reaction_icons.py (hand-placed pixel grid; no PixelLab call, 0 generations). "
                   "Byte-identical every run.",
        "size": [SIZE, SIZE],
        "shown_at_scale": 2,
        "references": ["docs/visual-style.md (Content, Rules)", "docs/hud-and-menus.md",
                       "game/art/hud/likes_heart.png (the HUD outline)"],
        "prompt": None,
    }


def build(out_dir: Path, force=False, names=None) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    paths = []
    for n in names or NAMES + BAD_NAMES:
        p = out_dir / f"reaction_{n}.png"
        if p.exists() and not force:
            raise SystemExit(f"{p} exists (use --force)")
        draw(n).save(p)
        p.with_suffix(".json").write_text(json.dumps(record(n), indent=1) + "\n", encoding="utf-8")
        paths.append(p)
    return paths


def main(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("--out-dir", required=True)
    b.add_argument("--force", action="store_true")
    c = sub.add_parser("contact")
    c.add_argument("--out", required=True)
    c.add_argument("--dir", default="game/art/hud")
    a = ap.parse_args(argv)
    if a.cmd == "build":
        for p in build(Path(a.out_dir), a.force):
            print(p)
    else:
        hud.contact([Path(a.dir) / f"reaction_{n}.png" for n in NAMES + BAD_NAMES], scale=8).save(a.out)
        print(a.out)


if __name__ == "__main__":
    main()
