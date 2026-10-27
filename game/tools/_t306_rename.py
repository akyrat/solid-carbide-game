#!/usr/bin/env python3
"""HISTORY: the one-off script T-306 ran once to rename the old sponsor's name (Redgull) in
game code, tests, tools and game/README.md; kept as the record of that rename, not to be run again.
Usage: _t306_rename.py [--write] [--readme]   (without --write: dry run, prints what would change)"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WRITE = "--write" in sys.argv
OLD = "Redgull"
old = OLD.lower()
UP = OLD.upper()

HISTORY = {"make_logo_sizes.py", "draw_gull_silhouette.py", "flatten_logo.py",
           "check_logo_one_colour.py", "test_check_logo_one_colour.py"}

IDENT = [
    (f"check_{old}_logo", "check_old_logo"),
    (f"is_{old}_red", "reads_as_red"),
    (f"{UP}_REDS", "HEART_AND_OLD_LOGO_REDS"),
    (f"MIN_{UP}_DISTANCE", "MIN_OLD_LOGO_RED_DISTANCE"),
    (f"near_{old}(?!_)", "near_old_logo_red"),
    (f"_{old}_pixels", "_red_pixels"),
    (f"_far_from_{old}", "_far_from_heart_red"),
]
IDENT_PY = [(f"{UP}_RED", "OLD_LOGO_RED")]
IDENT_GD = [(f"{UP}_RED", "HEART_RED")]

PROSE_GD = [
    (f"the HUD heart's {OLD} red", "the HUD heart's red"),
    (f"{OLD}'s \\(0\\.86, 0\\.1, 0\\.16\\)", "the heart's red (0.86, 0.1, 0.16)"),
    (f"far from {OLD} red", "far from the heart's red"),
    (f"\\bno {OLD} red", "not the heart's red"),
    (f"\\bNo {OLD} red", "Not the heart's red"),
    (f"{OLD} red", "the heart's red"),
]
PROSE_PY = [
    (f"the sprite checks and {OLD} red, Visual style rules 1 and 6", "the sprite checks and the red check, Visual style rules 1 and 6"),
    (f"no {OLD} red \\(nor any red\\)", "no red"),
    (f"no {OLD} red, no red", "no red"),
    (f"no {OLD} red nor any red", "no red"),
    (f"{OLD} red", "red"),
]
RECORD_LINE = re.compile(r'"[a-z_]+":\s')


def test_name(line, gd):
    m = re.match(r"(\s*(?:def|func) )(test_\w+)", line)
    if not m or old not in m.group(2):
        return line
    name = m.group(2).replace(f"{old}_red", "heart_red" if gd else "red")
    return line.replace(m.group(2), name, 1)


README = [
    (f"`REDGULL_RED`, `HEART_COLOR`, `is_{old}_red`; unchanged, renamed in a later ticket",
     "`OLD_LOGO_RED`, `HEART_COLOR`, `reads_as_red`; renamed by T-306, values and checks unchanged"),
    (f"\"Godzilla\" or \"{OLD}\", the sponsor's old name,", "\"Godzilla\" or the sponsor's old name,"),
    (f"kept as the old {OLD} logo's one-colour check", "kept as the old logo's one-colour check"),
    (f"test_canister_art_is_not_{old}_red", "test_canister_art_is_not_old_logo_red"),
    (f"away from {OLD}'s red", "away from the old logo's red"),
    (f"near {OLD}'s red", "near the old logo's red"),
    (f"flat {OLD} red `Hud.HEART_COLOR`", "flat red `Hud.HEART_COLOR`, the likes heart's red,"),
    (f"\\(not {OLD} red; red outside {OLD} is only for the kaiju alert signs\\)", "(not the heart's red)"),
    (f"no {OLD} red nor any red", "no red"),
    (f"no {OLD} red or any red", "no red"),
    (f"\\bno {OLD} red", "clear of the heart's red"),
    (f"\\bNo {OLD} red", "Clear of the heart's red"),
    (f"{OLD} red", "the heart's red"),
]


def readme():
    p = ROOT / "game/README.md"
    lines = p.read_text(encoding="utf-8").split("\n")
    for i, line in enumerate(lines):
        if line.startswith(f"**{OLD} logo (T-075):**"):
            continue  # the old logo's history paragraph, edited by hand
        new = line
        for a, b in README[:4] + IDENT + IDENT_PY + README[4:]:
            new = re.sub(a, b, new)
        lines[i] = new
    if WRITE:
        p.write_bytes("\n".join(lines).encode("utf-8"))


def main():
    if "--readme" in sys.argv:
        return readme()
    files = subprocess.run(["git", "ls-files", "game/scripts", "game/tests", "game/tools"],
                           cwd=ROOT, capture_output=True, text=True).stdout.split()
    for rel in files:
        if not rel.endswith((".py", ".gd")) or rel.endswith("_t306_rename.py"):
            continue
        p = ROOT / rel
        text = p.read_text(encoding="utf-8")
        if old not in text.lower():
            continue
        gd = rel.endswith(".gd")
        out = []
        for line in text.split("\n"):
            new = line
            for a, b in IDENT + (IDENT_GD if gd else IDENT_PY):
                new = re.sub(a, b, new)
            new = test_name(new, gd)
            if Path(rel).name not in HISTORY and not RECORD_LINE.search(new):
                for a, b in (PROSE_GD if gd else PROSE_PY):
                    new = re.sub(a, b, new)
            if new != line:
                print(f"{rel}\n  - {line.strip()}\n  + {new.strip()}")
            out.append(new)
        if WRITE:
            p.write_bytes("\n".join(out).encode("utf-8"))


if __name__ == "__main__":
    main()
