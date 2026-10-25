#!/usr/bin/env python3
"""Draws T-072's art: the coin and the enemy hit, enemy death and car damage effects.

The board agreed (2026-10-14) that none of these use more PixelLab calls. The coin is
redrawn by hand from the one PixelLab sample's palette (art-archive/T-072/sample/), and the
three effects are drawn by script, within Visual style, Decisions: night neon palette
(white-hot cores, cyan and pink sparks), glow as stepped halo pixels, hard pixel edges,
no semi-transparent pixels, a transparent background, about 30 colours or fewer, and no
Redgull red. Effects pop and shrink away; they never fade.

Outputs in game/art/effects/ (one-row sheets of frames):
  coin.png         10 x 12, one still
  enemy_hit.png    4 frames of 16 x 16
  enemy_death.png  6 frames of 32 x 32
  car_damage.png   4 frames of 48 x 48
each with a .json record. Review images go to art-archive/T-072/.

Commands (run from the repo root):
  python game/tools/build_hit_coin_damage_effects.py build
  python game/tools/build_hit_coin_damage_effects.py check
Running build twice gives byte-identical files.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_rules as rules  # noqa: E402
from style_rules import is_redgull_red  # noqa: E402  (Visual style rule 6)
from remove_car_shadow import write_png  # noqa: E402

GAME = Path(__file__).resolve().parent.parent
REPO = GAME.parent
OUT_DIR = GAME / "art" / "effects"
ARCHIVE = REPO / "art-archive" / "T-072"
# The board dropped the hit, death and car damage effects after playing them (2026-10-15): only
# the coin goes to the game; the other sheets are kept, not deleted, in the archive.
UNUSED = ARCHIVE / "unused_effects"
GAME_SHEETS = ("coin",)
CLEAR = (0, 0, 0, 0)
OUTLINE = (13, 18, 31)

P = {
    "W": (255, 255, 255), "c": (190, 255, 255), "C": (0, 229, 255), "b": (0, 150, 214), "d": (20, 72, 140),
    "p": (255, 200, 240), "P": (255, 64, 200), "m": (170, 36, 168), "n": (96, 20, 104),
    "y": (255, 235, 130),
    # the minion's light green, for its death puff
    "g": (140, 205, 115), "G": (96, 160, 80), "h": (178, 230, 140), "k": (60, 105, 60),
    # coin (palette taken from the PixelLab sample)
    "A": (206, 158, 38), "F": (255, 204, 64), "S": (255, 247, 191), "E": (104, 90, 48),
}

COIN = [  # 8 x 10 fill; the outline is added round it: 10 x 12
    "..AAAA..",
    ".ASSFFAE",
    "ASSFFFFE",
    "ASFFFFFE",
    "AFFFFFFE",
    "AFFFFFFE",
    "AFFFFFAE",
    "AFFFFAAE",
    ".AFFAAE.",
    "..EEEE..",
]

DIRS8 = [(math.cos(a * math.pi / 4), math.sin(a * math.pi / 4)) for a in range(8)]


class Canvas:
    def __init__(self, n):
        self.n = n
        self.px = {}

    def _set(self, x, y, rgb):
        if 0 <= x < self.n and 0 <= y < self.n:
            self.px[(x, y)] = rgb

    def dot(self, x, y, c):
        self._set(int(round(x)), int(round(y)), P[c])

    def disc(self, cx, cy, r, c):
        for y in range(self.n):
            for x in range(self.n):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + 0.25:
                    self.px[(x, y)] = P[c]

    def ring(self, cx, cy, r0, r1, c):
        for y in range(self.n):
            for x in range(self.n):
                if r0 * r0 <= (x - cx) ** 2 + (y - cy) ** 2 <= r1 * r1:
                    self.px[(x, y)] = P[c]

    def ray(self, cx, cy, d, r0, r1, colours):
        """Pixels along direction d from r0 to r1; colours from the inside out."""
        steps = max(int(r1 - r0), 0)
        for i in range(steps + 1):
            c = colours[min(i * len(colours) // (steps + 1), len(colours) - 1)]
            self.dot(cx + d[0] * (r0 + i), cy + d[1] * (r0 + i), c)

    def outline(self, only):
        """A dark pixel round the pixels whose colour is in `only`."""
        want = {P[c] for c in only}
        mine = [k for k, v in self.px.items() if v in want]
        for (x, y) in mine:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                k = (x + dx, y + dy)
                if k not in self.px:
                    self._set(k[0], k[1], OUTLINE)

    def rows(self):
        return [[self.px[(x, y)] + (255,) if (x, y) in self.px else CLEAR for x in range(self.n)]
                for y in range(self.n)]


def hit_frames():
    n, c = 16, 7.5
    out = []
    f = Canvas(n)
    f.disc(c, c, 3.4, "C"); f.disc(c, c, 2.2, "c"); f.disc(c, c, 1.2, "W")
    out.append(f)
    f = Canvas(n)
    for i, d in enumerate(DIRS8):
        f.ray(c, c, d, 2, 6 if i % 2 == 0 else 4, "cCP" if i % 2 == 0 else "CP")
    f.disc(c, c, 1.5, "W")
    out.append(f)
    f = Canvas(n)
    for i, d in enumerate(DIRS8):
        r = 6.5 if i % 2 == 0 else 5
        f.dot(c + d[0] * r, c + d[1] * r, "P" if i % 2 else "C")
        f.dot(c + d[0] * (r - 1.5), c + d[1] * (r - 1.5), "c" if i % 2 == 0 else "p")
    f.dot(c, c, "W")
    out.append(f)
    f = Canvas(n)
    for i, d in enumerate(DIRS8):
        r = 7 if i % 2 == 0 else 6
        f.dot(c + d[0] * r, c + d[1] * r, "d" if i % 2 == 0 else "n")
    out.append(f)
    return out


def death_frames():
    n, c = 32, 15.5
    out = []
    f = Canvas(n)
    f.disc(c, c, 6.5, "g"); f.disc(c, c, 5, "h"); f.disc(c, c, 3.2, "W")
    f.outline("gh")
    out.append(f)
    for r_out, blob, spark_r, core in ((6, 3.6, 9, True), (9, 3.0, 12, False), (11, 2.2, 13.5, False)):
        f = Canvas(n)
        for i in range(6):
            a = i * math.pi / 3 + 0.3
            bx, by = c + math.cos(a) * r_out, c + math.sin(a) * r_out * 0.8
            f.disc(bx, by, blob, "g")
            f.disc(bx - 0.6, by - 0.6, blob * 0.55, "h")
        if core:
            f.disc(c, c, 3, "G"); f.disc(c, c, 1.6, "W")
        f.outline("gh")
        for i, d in enumerate(DIRS8):
            f.dot(c + d[0] * spark_r, c + d[1] * spark_r * 0.85, "C" if i % 2 == 0 else "P")
            if blob > 2.5:
                f.dot(c + d[0] * (spark_r - 1.5), c + d[1] * (spark_r - 1.5) * 0.85, "c" if i % 2 == 0 else "p")
        out.append(f)
    f = Canvas(n)
    for i in range(10):
        a = i * 2 * math.pi / 10 + 0.2
        r = 12.5 if i % 2 else 14
        x, y = c + math.cos(a) * r, c + math.sin(a) * r * 0.85
        f.dot(x, y, "G"); f.dot(x + 1, y, "G")
    for i, d in enumerate(DIRS8):
        f.dot(c + d[0] * 15, c + d[1] * 13, "d" if i % 2 == 0 else "n")
    out.append(f)
    f = Canvas(n)
    for i in range(8):
        a = i * math.pi / 4 + 0.5
        f.dot(c + math.cos(a) * 14.5, c + math.sin(a) * 12.5, "k")
    out.append(f)
    return out


def damage_frames():
    n, c = 48, 23.5
    out = []
    f = Canvas(n)
    f.ring(c, c, 8, 10, "d"); f.disc(c, c, 8, "C"); f.disc(c, c, 5.5, "c"); f.disc(c, c, 3, "W")
    for d in DIRS8[::2]:
        f.ray(c, c, d, 9, 13, "CPd")
    out.append(f)
    f = Canvas(n)
    for i, d in enumerate(DIRS8):
        long = i % 2 == 0
        f.ray(c, c, d, 3, 17 if long else 11, "WcCbP" if long else "cCP")
    f.disc(c, c, 2.5, "W")
    for i in range(6):
        a = i * math.pi / 3 + 0.4
        f.dot(c + math.cos(a) * 19, c + math.sin(a) * 19, "y")
    out.append(f)
    f = Canvas(n)
    for i, d in enumerate(DIRS8):
        r = 19 if i % 2 == 0 else 14
        f.ray(c, c, d, r - 3, r, "cCP")
    for i in range(8):
        a = i * math.pi / 4 + 0.4
        f.dot(c + math.cos(a) * 21, c + math.sin(a) * 21, "y")
        f.dot(c + math.cos(a + 0.5) * 11, c + math.sin(a + 0.5) * 11, "p")
    f.disc(c, c, 1.5, "W")
    out.append(f)
    f = Canvas(n)
    for i in range(12):
        a = i * math.pi / 6 + 0.1
        r = 22 if i % 2 else 20
        f.dot(c + math.cos(a) * r, c + math.sin(a) * r, "d" if i % 3 else "n")
    out.append(f)
    return out


def coin_rows():
    fill = {(x + 1, y + 1): P[ch] for y, line in enumerate(COIN) for x, ch in enumerate(line) if ch != "."}
    w, h = len(COIN[0]) + 2, len(COIN) + 2
    out = []
    for y in range(h):
        row = []
        for x in range(w):
            if (x, y) in fill:
                row.append(fill[(x, y)] + (255,))
            elif any((x + dx, y + dy) in fill for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                row.append(OUTLINE + (255,))
            else:
                row.append(CLEAR)
        out.append(row)
    return out


def sheet(frames):
    rows = [f.rows() for f in frames]
    return [sum((fr[y] for fr in rows), []) for y in range(len(rows[0]))]


SETS = {
    "coin": (1, (10, 12)),
    "enemy_hit": (4, (16, 16)),
    "enemy_death": (6, (32, 32)),
    "car_damage": (4, (48, 48)),
}


def sheets():
    return {
        "coin": coin_rows(),
        "enemy_hit": sheet(hit_frames()),
        "enemy_death": sheet(death_frames()),
        "car_damage": sheet(damage_frames()),
    }


def check_sheet_rows(name, rows):
    """Every frame of a sheet: the sprite rules and no Redgull red. Returns (rule, ok, detail) tuples."""
    frames, (fw, fh) = SETS[name]
    out = []
    for i in range(frames):
        fr = [r[i * fw:(i + 1) * fw] for r in rows]
        res, _ = rules.check_rows(fr, size=fw, max_colors=30)
        res[0] = ("frame size %dx%d" % (fw, fh), (len(fr[0]), len(fr)) == (fw, fh), "%dx%d" % (len(fr[0]), len(fr)))
        red = [p[:3] for r in fr for p in r if p[3] and is_redgull_red(p[:3])]
        res.append(("no Redgull red", not red, str(red[:2])))
        out += [("%s frame %d: %s" % (name, i, a), b, c) for a, b, c in res]
    return out


def enlarge(rows, k, bg):
    out = []
    for r in rows:
        line = []
        for p in r:
            if p[3] == 0:
                p = bg + (255,)
            line.extend([p] * k)
        out.extend([list(line) for _ in range(k)])
    return out


def previews(all_sheets, archive=ARCHIVE):
    archive.mkdir(parents=True, exist_ok=True)
    scales = {"coin": 16, "enemy_hit": 10, "enemy_death": 6, "car_damage": 4}
    for name, rows in all_sheets.items():
        k = scales[name]
        dark, light = enlarge(rows, k, (20, 20, 40)), enlarge(rows, k, (235, 235, 240))
        gap = [[(128, 128, 128, 255)] * 8 for _ in dark]
        write_png(archive / f"{name}_dark_light_x{k}.png", [a + g + b for a, g, b in zip(dark, gap, light)])


def build(out_dir=OUT_DIR, archive=ARCHIVE):
    out_dir.mkdir(parents=True, exist_ok=True)
    unused = archive / "unused_effects"
    unused.mkdir(parents=True, exist_ok=True)
    all_sheets = sheets()
    notes = {
        "coin": "Hand-drawn 8 x 10 fill plus a dark outline, in the PixelLab sample's gold palette. The sample (art-archive/T-072/sample/coin_sample.png) was too big, tilted, unoutlined and had grey stray pixels.",
        "enemy_hit": "White-hot flash, then cyan and pink sparks flying out, then specks. 4 frames.",
        "enemy_death": "The minion's light green puff with a white core, breaking into pieces and specks, with cyan and pink sparks. 6 frames.",
        "car_damage": "White and cyan flash, cyan and pink spark rays with yellow debris, then specks. No red. 4 frames.",
    }
    for name, rows in all_sheets.items():
        dest = out_dir if name in GAME_SHEETS else unused
        write_png(dest / f"{name}.png", rows)
        frames, (fw, fh) = SETS[name]
        rec = {
            "task": "T-072", "what": notes[name],
            "made_by": "game/tools/build_hit_coin_damage_effects.py (drawn by script, no PixelLab call; board 2026-10-14). Byte-identical every run.",
            "frames": frames, "frame_size": [fw, fh], "prompt": None,
            "references": ["docs/visual-style.md (technical rules, palette, glow, Effects)", "game/scripts/enemies/coin_sprite.gd (placeholder)"],
        }
        (dest / f"{name}.json").write_text(json.dumps(rec, indent=1) + "\n", encoding="utf-8")
    previews(all_sheets, archive)
    return out_dir


def check(out_dir=OUT_DIR, archive=ARCHIVE):
    res = []
    for name in SETS:
        src = Path(out_dir) if name in GAME_SHEETS else Path(archive) / "unused_effects"
        _, _, rows = rules.decode_png((src / f"{name}.png").read_bytes())
        res += check_sheet_rows(name, rows)
    return res


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("command", choices=["build", "check"])
    a = ap.parse_args(argv)
    if a.command == "check":
        res = check()
        for rule, ok, detail in res:
            print(("PASS " if ok else "FAIL ") + rule + ": " + detail)
        return 0 if all(r[1] for r in res) else 1
    print("wrote", build())
    return 0


if __name__ == "__main__":
    sys.exit(main())
