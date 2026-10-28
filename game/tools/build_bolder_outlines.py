#!/usr/bin/env python3
"""Bolder outlines for the enemies' sprite sheets (T-340, free script, no PixelLab).

Every transparent pixel next to an opaque one (inside the same frame) becomes the sheet's own outline colour,
so the dark outline grows one pixel outward. The outline colour is the most common colour among the sheet's
opaque pixels that touch transparency, so no new colour is added. Sizes do not change (the art keeps at least
one clear pixel inside each frame); a sprite just grows by one pixel on every side.

The originals are copied once to art-archive/T-340/originals/ and always read from there, so a rerun gives the
same result. Run from the repo root:
  python game/tools/build_bolder_outlines.py build [--reach 1] [--rim R,G,B]   write game/art from the originals
  python game/tools/build_bolder_outlines.py check                             pixel rules for every sheet
  python game/tools/build_bolder_outlines.py strip SET OUT.png                 one row of all the set's sheets (the style loop's unit)
  python game/tools/build_bolder_outlines.py apply SET STRIP.png               write a kept strip back to the sheets
SET is minion_walk, minion_fall or kaiju. --rim lightens nothing by itself: it paints the pixel ring just
outside the outline in that colour (a possible fix if the dark outline is lost against a dark street).
"""
import shutil
import sys
from collections import Counter
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "game" / "art"
ORIG = ROOT / "art-archive" / "T-340" / "originals"
DIRS = ("s", "se", "e", "ne", "n")
SETS = {
    "minion_walk": ("minion", [f"minion_{d}.png" for d in DIRS], 48, 8),
    "minion_fall": ("minion", [f"minion_fall_{d}.png" for d in DIRS], 48, 8),
    "kaiju": ("kaiju", [f"kaiju_{d}.png" for d in DIRS], 224, 6),
}
NEIGHBOURS = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if (dx, dy) != (0, 0)]


def outline_colour(img):
    """Most common colour of the opaque pixels that touch a transparent pixel (or the image edge)."""
    px, (w, h) = img.load(), img.size
    c = Counter()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] != 255:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < w and 0 <= ny < h) or px[nx, ny][3] == 0:
                    c[px[x, y][:3]] += 1
                    break
    return c.most_common(1)[0][0]


def grow(frame, colour, reach=1):
    """Frame (RGBA) with a `reach`-pixel ring of `colour` around the opaque pixels, inside the frame."""
    w, h = frame.size
    out = frame.copy()
    cur = frame
    for _ in range(reach):
        src, dst = cur.load(), cur.copy()
        dpx = dst.load()
        for y in range(h):
            for x in range(w):
                if src[x, y][3] == 255:
                    continue
                for dx, dy in NEIGHBOURS:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] == 255:
                        dpx[x, y] = (*colour, 255)
                        break
        cur = dst
    return cur


def bolder_sheet(sheet, fsize, nframes, reach=1, rim_colour=None):
    sheet = sheet.convert("RGBA")
    colour = outline_colour(sheet)
    out = Image.new("RGBA", sheet.size, (0, 0, 0, 0))
    for i in range(nframes):
        f = sheet.crop((i * fsize, 0, (i + 1) * fsize, fsize))
        if f.getchannel("A").getbbox() is None:
            continue
        g = grow(f, colour, reach)
        if rim_colour:
            g = grow(g, rim_colour, 1)
        out.paste(g, (i * fsize, 0))
    return out


def ensure_originals():
    for folder, names, _, _ in SETS.values():
        for n in names:
            dst = ORIG / folder / n
            if not dst.exists():
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ART / folder / n, dst)


def build(reach=1, rim_colour=None):
    ensure_originals()
    for folder, names, fsize, nframes in SETS.values():
        for n in names:
            img = bolder_sheet(Image.open(ORIG / folder / n), fsize, nframes, reach, rim_colour)
            img.save(ART / folder / n)
            print("wrote", ART / folder / n)


def check():
    sys.path.insert(0, str(Path(__file__).parent))
    import style_rules
    bad = 0
    for folder, names, fsize, nframes in SETS.values():
        for n in names:
            _, _, rows = style_rules.decode_png((ART / folder / n).read_bytes())
            res = style_rules.art_checks(rows, (fsize, fsize), nframes, False, [], 49 if "fall" in n else 36)
            fails = [c for c in res if not c["ok"]]
            bad += len(fails)
            print(n, "ok" if not fails else fails)
    return 1 if bad else 0


def strip(set_name, out):
    folder, names, fsize, nframes = SETS[set_name]
    row = Image.new("RGBA", (fsize * nframes * len(names), fsize), (0, 0, 0, 0))
    for i, n in enumerate(names):
        row.paste(Image.open(ART / folder / n).convert("RGBA"), (i * fsize * nframes, 0))
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    row.save(out)


def apply(set_name, strip_png):
    folder, names, fsize, nframes = SETS[set_name]
    row = Image.open(strip_png).convert("RGBA")
    for i, n in enumerate(names):
        w = fsize * nframes
        row.crop((i * w, 0, (i + 1) * w, fsize)).save(ART / folder / n)


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    cmd, rest = argv[0], argv[1:]
    if cmd == "build":
        reach, rim_colour = 1, None
        if "--reach" in rest:
            reach = int(rest[rest.index("--reach") + 1])
        if "--rim" in rest:
            rim_colour = tuple(int(v) for v in rest[rest.index("--rim") + 1].split(","))
        build(reach, rim_colour)
        return check()
    if cmd == "check":
        return check()
    if cmd == "strip":
        strip(rest[0], rest[1])
        return 0
    if cmd == "apply":
        apply(rest[0], rest[1])
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
