#!/usr/bin/env python3
"""Builds a minion death sheet (T-532) from PixelLab /animate-with-text-v3 frames.

Free script fixes only, never a PixelLab call: every opaque colour is moved to the
nearest colour of the minion's walk sheets (game/art/minion/minion_<dir>.png), alpha
is made 0 or 255, and optionally the last frame is repeated (--hold) so the corpse
pose is held still. Output: one row of FRAME x FRAME frames, 8-bit RGBA.

PixelLab returns the first frame it was given as image 0, so --first defaults to 1.
Run from the repo root:
  python game/tools/build_minion_death_sheet.py RAW_DIR PREFIX OUT.png
         [--first 1] [--count 8] [--hold 0] [--pick DIR:I,DIR:I,...] [--preview-dir DIR --scale 6]
--preview-dir writes OUT's stem + _x<scale>_dark.png and _light.png (enlarged, nearest).
"""
import argparse
import sys
from pathlib import Path

from PIL import Image

FRAME = 48
ROOT = Path(__file__).resolve().parents[2]
MINION = ROOT / "game" / "art" / "minion"
BGS = {"dark": (24, 26, 40), "light": (225, 225, 230)}


def walk_palette(minion_dir=MINION):
    """The opaque RGB colours of the minion's walk sheets."""
    pal = set()
    for d in ("s", "se", "e", "ne", "n"):
        im = Image.open(Path(minion_dir) / f"minion_{d}.png").convert("RGBA")
        pal |= {p[:3] for p in im.getdata() if p[3] > 0}
    return sorted(pal)


def snap_frame(img, palette):
    """Alpha to 0/255 (cut at 128) and each opaque colour to its nearest palette colour."""
    img = img.convert("RGBA")
    cache = {}
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    src, dst = img.load(), out.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = src[x, y]
            if a < 128:
                continue
            c = (r, g, b)
            if c not in cache:
                cache[c] = min(palette, key=lambda p: sum((p[i] - c[i]) ** 2 for i in range(3)))
            dst[x, y] = (*cache[c], 255)
    return out


def build_sheet(frames, palette, hold=0):
    """frames: RGBA images of FRAME x FRAME. The last `hold` frames are replaced by copies
    of the frame before them, so the end pose is still."""
    frames = [snap_frame(f, palette) for f in frames]
    for f in frames:
        if f.size != (FRAME, FRAME):
            raise ValueError(f"frame is {f.size}, expected {FRAME}x{FRAME}")
    if hold:
        if hold >= len(frames):
            raise ValueError("--hold must be smaller than the frame count")
        keep = frames[len(frames) - hold - 1]
        frames = frames[:len(frames) - hold] + [keep.copy() for _ in range(hold)]
    sheet = Image.new("RGBA", (FRAME * len(frames), FRAME), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * FRAME, 0))
    return sheet


def preview(sheet, bg, scale):
    im = Image.new("RGBA", sheet.size, BGS[bg] + (255,))
    im.alpha_composite(sheet)
    return im.resize((sheet.width * scale, sheet.height * scale), Image.NEAREST)


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("raw_dir")
    ap.add_argument("prefix")
    ap.add_argument("out")
    ap.add_argument("--first", type=int, default=1)
    ap.add_argument("--count", type=int, default=8)
    ap.add_argument("--hold", type=int, default=0)
    ap.add_argument("--pick", help="DIR:INDEX,DIR:INDEX,... frames joined from several raw folders (raw_dir unused)")
    ap.add_argument("--preview-dir")
    ap.add_argument("--scale", type=int, default=6)
    a = ap.parse_args(argv)
    out = Path(a.out)
    if out.exists():
        raise SystemExit(f"{out} exists: never overwrite a version")
    if a.pick:
        # explicit frames, any raw folder: DIR:INDEX[,DIR:INDEX...]; the prefix applies to all
        paths = [Path(s.rsplit(":", 1)[0]) / f"{a.prefix}_{s.rsplit(':', 1)[1]}.png" for s in a.pick.split(",")]
    else:
        paths = [Path(a.raw_dir) / f"{a.prefix}_{i}.png" for i in range(a.first, a.first + a.count)]
    sheet = build_sheet([Image.open(p) for p in paths], walk_palette(), a.hold)
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    colours = {p[:3] for p in sheet.getdata() if p[3]}
    print(f"wrote {out} ({sheet.width}x{sheet.height}, {len(colours)} colours)")
    if a.preview_dir:
        pd = Path(a.preview_dir)
        pd.mkdir(parents=True, exist_ok=True)
        for bg in BGS:
            p = pd / f"{out.stem}_x{a.scale}_{bg}.png"
            preview(sheet, bg, a.scale).save(p)
            print("wrote", p)
    return 0


if __name__ == "__main__":
    sys.exit(main())
