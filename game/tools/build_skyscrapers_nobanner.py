#!/usr/bin/env python3
"""The 12 skyscraper bodies without their vertical sign (T-265), made for free, no PixelLab.

The "banner" a creator skyscraper shows in the middle of its face is the vertical neon sign that
`build_skyscrapers.py` `place_sign` paints into every body (T-064; `build_city.py`). It is baked into
`game/art/buildings/skyscraper_N_K.png`, not a separate sprite. This script runs the same build from the same
raw pieces with the sign left out (an empty sign image), and writes the copies to
`game/art/buildings/nobanner/skyscraper_N_K.png`. The originals are never touched.

  python game/tools/build_skyscrapers_nobanner.py            # write the copies
  python game/tools/build_skyscrapers_nobanner.py --check    # also rebuild the originals and compare

`bodies(raw, with_sign)` gives {(tower, variant): RGBA array}; `check()` returns the problems (an empty list
when the with-sign rebuild is identical to the art in the game).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_city as bc  # noqa: E402
import build_skyscrapers as bs  # noqa: E402
from build_buildings import palette_from_image  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
DEFAULT_RAW = REPO / "art-archive" / "T-064" / "round2" / "raw"
ART_DIR = REPO / "game" / "art" / "buildings"
OUT_DIR = ART_DIR / "nobanner"


def bodies(raw=DEFAULT_RAW, with_sign: bool = False) -> dict:
    palb = np.array(palette_from_image(bc.PALETTE_B), dtype=np.int32)
    pcs = bc.pieces(str(raw), palb)
    out = {}
    for n in range(1, 7):
        sign = bs.script_sign(n * 17, palb, accent=bc.SIGN_ACCENT[n])
        if not with_sign:
            sign = np.zeros_like(sign)  # alpha 0 everywhere: place_sign paints nothing
        for k, v in enumerate(bc.VARIANTS):
            out[(n, k)] = bs.build_body(pcs[n]["facade"], pcs[n]["shop"], sign, palb,
                                        facade_seed=n * 10 + k, seed=n * 3 + k, **v)
    return out


def write(out_dir=OUT_DIR, raw=DEFAULT_RAW) -> list:
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    names = []
    for (n, k), body in bodies(raw, False).items():
        name = f"skyscraper_{n}_{k}.png"
        bs.to_img(body).save(out_dir / name)
        names.append(name)
    return names


def check(raw=DEFAULT_RAW, art_dir=ART_DIR, out_dir=OUT_DIR) -> list:
    """Problems: the with-sign rebuild must equal the art in the game, and the copies must differ from it only
    where the sign was (and never in a pixel outside the sign's own area)."""
    problems = []
    with_sign = bodies(raw, True)
    without = bodies(raw, False)
    for (n, k), body in with_sign.items():
        name = f"skyscraper_{n}_{k}.png"
        orig = np.array(Image.open(Path(art_dir) / name).convert("RGBA"))
        if not np.array_equal(orig, body):
            problems.append(f"{name}: the rebuild with the sign is not the art in the game")
        if np.array_equal(body, without[(n, k)]):
            problems.append(f"{name}: leaving the sign out changed nothing")
        copy = Path(out_dir) / name
        if copy.exists() and not np.array_equal(np.array(Image.open(copy).convert("RGBA")), without[(n, k)]):
            problems.append(f"{name}: the written copy is not the sign-less rebuild")
    return problems


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default=str(DEFAULT_RAW))
    ap.add_argument("--out-dir", default=str(OUT_DIR))
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args(argv)
    names = write(a.out_dir, a.raw)
    print(f"wrote {len(names)} bodies without the sign to {a.out_dir}")
    if a.check:
        problems = check(a.raw, ART_DIR, a.out_dir)
        for p in problems:
            print(p)
        return 1 if problems else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
