#!/usr/bin/env python3
"""Builds a kaiju animation sheet (T-613) from PixelLab /animate-with-text-v3 frames. Free, never a PixelLab call.

Fixes only what a script can: every opaque colour moves to the nearest colour of the kaiju's still sheet for that
direction (game/art/kaiju/kaiju_<dir>.png, 30 colours at most), alpha becomes 0 or 255, optionally the frames are
shifted so the feet stay on the still sprite's ground point (--align), optionally the last frames are held still
(--hold). Output: one row of 224 x 224 frames, 8-bit RGBA.

PixelLab returns the frame it was given as image 0, so --first defaults to 1. Run from the repo root:
  python game/tools/build_kaiju_anim_sheet.py DIR RAW_DIR PREFIX OUT.png [--first 1] [--count 6] [--hold 0]
         [--align] [--pick RAWDIR:I,RAWDIR:I,...] [--preview-dir D --scale 3]
  python game/tools/build_kaiju_anim_sheet.py DIR --frame0 OUT.png      the still sprite's frame 0 (the request's first frame)
DIR is one of s, se, e, ne, n. --preview-dir writes the sheet enlarged (nearest) on a dark and a light background.
"""
import argparse
import sys
from pathlib import Path

from PIL import Image

FRAME = 224
DIRS = ("s", "se", "e", "ne", "n")
ROOT = Path(__file__).resolve().parents[2]
KAIJU = ROOT / "game" / "art" / "kaiju"
BGS = {"dark": (24, 26, 40), "light": (225, 225, 230)}


def still_sheet(direction, kaiju_dir=KAIJU):
    return Image.open(Path(kaiju_dir) / f"kaiju_{direction}.png").convert("RGBA")


def still_frame0(direction, kaiju_dir=KAIJU):
    return still_sheet(direction, kaiju_dir).crop((0, 0, FRAME, FRAME))


def palette_of(direction, kaiju_dir=KAIJU):
    """The opaque RGB colours of the kaiju's still sheet for this direction."""
    return sorted({p[:3] for p in still_sheet(direction, kaiju_dir).getdata() if p[3] > 0})


def quantized_palette(frames, n):
    """n colours of the frames' own opaque pixels (median cut), for art that has no still to match."""
    px = [p[:3] for f in frames for p in f.convert("RGBA").getdata() if p[3] >= 128]
    strip = Image.new("RGB", (len(px), 1))
    strip.putdata(px)
    q = strip.quantize(colors=n, method=Image.MEDIANCUT)
    pal = q.getpalette()[:3 * n]
    used = sorted({q.getpixel((i, 0)) for i in range(len(px))})
    return sorted({tuple(pal[3 * i:3 * i + 3]) for i in used})


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


def feet(frame, rows=12):
    """(bottom row, centre x of the lowest `rows` opaque rows) of a frame, or None when it is empty."""
    box = frame.getchannel("A").getbbox()
    if box is None:
        return None
    bottom = box[3] - 1
    xs = [x for y in range(max(box[1], bottom - rows + 1), bottom + 1) for x in range(frame.width)
          if frame.getpixel((x, y))[3]]
    return bottom, (min(xs) + max(xs)) / 2


def shift(frame, dx, dy):
    out = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    out.paste(frame, (dx, dy), frame)
    return out


def align_frames(frames, ref):
    """Shift every frame as one block so the median frame's feet sit where the still sprite's feet do.
    One shift for the whole animation: a walk's bob and sway stay, only a drift from the ground point goes."""
    refs = feet(ref)
    marks = [m for m in (feet(f) for f in frames) if m]
    if not refs or not marks:
        return frames
    bottoms = sorted(m[0] for m in marks)
    centres = sorted(m[1] for m in marks)
    dy = refs[0] - bottoms[len(bottoms) // 2]
    dx = round(refs[1] - centres[len(centres) // 2])
    return [shift(f, dx, dy) for f in frames]


def build_sheet(frames, palette, hold=0, ref=None):
    """frames: RGBA images of FRAME x FRAME. The last `hold` frames are replaced by copies of the frame before
    them, so the end pose is still. With `ref` (the still's frame 0) the block is aligned to its ground point."""
    for f in frames:
        if f.size != (FRAME, FRAME):
            raise ValueError(f"frame is {f.size}, expected {FRAME}x{FRAME}")
    frames = [snap_frame(f, palette) for f in frames]
    if ref is not None:
        frames = align_frames(frames, ref)
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
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("dir", choices=DIRS)
    ap.add_argument("raw_dir", nargs="?")
    ap.add_argument("prefix", nargs="?")
    ap.add_argument("out", nargs="?")
    ap.add_argument("--frame0", help="write the still sprite's frame 0 here and stop")
    ap.add_argument("--first", type=int, default=1)
    ap.add_argument("--count", type=int, default=6)
    ap.add_argument("--hold", type=int, default=0)
    ap.add_argument("--align", action="store_true")
    ap.add_argument("--quantize", type=int, default=0,
                    help="instead of the still's palette, cut the whole sheet to this many colours of its own (the explosion)")
    ap.add_argument("--pick", help="DIR:INDEX,DIR:INDEX,... frames joined from several raw folders (raw_dir unused)")
    ap.add_argument("--preview-dir")
    ap.add_argument("--scale", type=int, default=3)
    a = ap.parse_args(argv)
    if a.frame0:
        Path(a.frame0).parent.mkdir(parents=True, exist_ok=True)
        still_frame0(a.dir).save(a.frame0)
        print("wrote", a.frame0)
        return 0
    if not (a.out and a.prefix):
        ap.error("RAW_DIR PREFIX OUT are needed")
    out = Path(a.out)
    if out.exists():
        raise SystemExit(f"{out} exists: never overwrite a version")
    if a.pick:
        paths = [Path(s.rsplit(":", 1)[0]) / f"{a.prefix}_{s.rsplit(':', 1)[1]}.png" for s in a.pick.split(",")]
    else:
        paths = [Path(a.raw_dir) / f"{a.prefix}_{i}.png" for i in range(a.first, a.first + a.count)]
    imgs = [Image.open(p) for p in paths]
    if a.quantize:
        pal = quantized_palette(imgs, a.quantize)
    else:
        pal = palette_of(a.dir)
    sheet = build_sheet(imgs, pal, a.hold, still_frame0(a.dir) if a.align else None)
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
