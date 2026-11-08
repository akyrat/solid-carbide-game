#!/usr/bin/env python3
"""Task T-583: puts two recordings of the facing fixture side by side, BEFORE (no fix) on the left
and AFTER (the recommended fixes) on the right, as one GIF plus stills.

    python game/tools/t583_before_after.py <before frames dir> <after frames dir> <out dir> <name> [step ...]

Frame n of each folder is physics step n + 1 (Godot --write-movie at 50 fps). The two runs are cut
to the shorter one. Writes <name>.gif and <name>_step<k>.png (default steps: 100 and the last).
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

CROP = (0, 0, 960, 600)


def frames(folder):
    return sorted(Path(folder).glob("*.png"))


def pair(a, b):
    with Image.open(a) as ia, Image.open(b) as ib:
        ia = ia.convert("RGB")
        ib = ib.convert("RGB")
        if ia.width >= CROP[2] and ia.height >= CROP[3]:
            ia = ia.crop(CROP)
            ib = ib.crop(CROP)
        out = Image.new("RGB", (ia.width * 2 + 8, ia.height), (240, 240, 240))
        out.paste(ia, (0, 0))
        out.paste(ib, (ia.width + 8, 0))
        d = ImageDraw.Draw(out)
        for x, text in ((10, "BEFORE (no fix)"), (ia.width + 18, "AFTER (fixes on)")):
            d.rectangle((x - 4, out.height - 30, x + 150, out.height - 6), fill=(0, 0, 0))
            d.text((x, out.height - 26), text, fill=(255, 255, 255))
        return out


def make(before, after, out, name, steps=None, every=2, scale=0.5):
    fa, fb = frames(before), frames(after)
    n = min(len(fa), len(fb))
    if n == 0:
        raise SystemExit("no frames")
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    written = []
    for k in steps or [100, n]:
        i = min(max(k - 1, 0), n - 1)
        dst = out / ("%s_step%03d.png" % (name, k))
        pair(fa[i], fb[i]).save(dst)
        written.append(dst)
    ims = []
    for i in range(0, n, every):
        im = pair(fa[i], fb[i])
        im = im.resize((int(im.width * scale), int(im.height * scale)), Image.LANCZOS)
        ims.append(im.quantize(colors=64, method=Image.MEDIANCUT, dither=Image.NONE))
    gif = out / ("%s.gif" % name)
    ims[0].save(gif, save_all=True, append_images=ims[1:], duration=int(1000 * every / 50), loop=0)
    written.append(gif)
    return written


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 1
    for p in make(argv[0], argv[1], argv[2], argv[3], [int(a) for a in argv[4:]] or None):
        print("wrote", p)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
