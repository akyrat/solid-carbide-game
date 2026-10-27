#!/usr/bin/env python3
"""One-off (T-312): moves the old logo files to art-archive/T-075/ and T-306's one-off rename
script to art-archive/T-306/, then moves itself to art-archive/T-312/. Nothing is deleted;
existing destinations are never overwritten. Run once: python game/tools/_t312_move.py"""
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from style_rules import OLD_BRAND  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
MOVES = []
for n in (128, 64, 32):
    for ext in (".png", ".png.import"):
        name = f"{OLD_BRAND.lower()}_logo_{n}{ext}"
        MOVES.append((ROOT / "game/art/logo" / name, ROOT / "art-archive/T-075" / name))
MOVES.append((ROOT / "game/tools/_t306_rename.py", ROOT / "art-archive/T-306/_t306_rename.py"))
MOVES.append((Path(__file__).resolve(), ROOT / "art-archive/T-312/_t312_move.py"))

for src, dst in MOVES:
    if not src.exists():
        print("missing, skipped:", src.relative_to(ROOT))
        continue
    if dst.exists():
        print("already there, skipped:", dst.relative_to(ROOT))
        continue
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(src), str(dst))
    print("moved", src.relative_to(ROOT).as_posix(), "->", dst.relative_to(ROOT).as_posix())
