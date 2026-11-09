#!/usr/bin/env python3
"""Tilts one 224 x 224 kaiju frame as a rigid block (T-613), to give PixelLab a first frame that is already falling.
Free, never a PixelLab call.

animate-with-text-v3 keeps the pose of the frame it is given, so a standing first frame never ends lying down.
This turns the frame clockwise by --angle degrees (nearest neighbour, so no new colours and alpha stays 0 or 255),
puts its lowest pixel back on the source frame's ground row and centres it sideways, moved only as far as needed
to stay inside the frame.

Run from the repo root:
  python game/tools/tilt_kaiju_frame.py IN.png OUT.png --angle 45 [--preview OUT_x3.png --scale 3]
Never overwrites OUT. Exits 1 when the tilted body does not fit in the frame.
"""
import argparse
import sys
from pathlib import Path

from PIL import Image

FRAME = 224
BG = (225, 225, 230, 255)


def tilt(frame, angle):
    """frame: RGBA FRAME x FRAME. Returns the frame turned clockwise by `angle` degrees, its lowest opaque row on
    the source's lowest opaque row, centred sideways. Raises ValueError when it no longer fits."""
    frame = frame.convert("RGBA")
    if frame.size != (FRAME, FRAME):
        raise ValueError(f"frame is {frame.size}, expected {FRAME}x{FRAME}")
    box = frame.getchannel("A").getbbox()
    if box is None:
        raise ValueError("frame is empty")
    ground = box[3]
    turned = frame.crop(box).rotate(-angle, resample=Image.NEAREST, expand=True)
    tbox = turned.getchannel("A").getbbox()
    turned = turned.crop(tbox)
    if turned.width > FRAME or turned.height > ground:
        raise ValueError(f"tilted body is {turned.size}, it does not fit above row {ground} of a {FRAME} px frame")
    out = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    out.paste(turned, ((FRAME - turned.width) // 2, ground - turned.height), turned)
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src")
    ap.add_argument("out")
    ap.add_argument("--angle", type=float, required=True, help="degrees clockwise")
    ap.add_argument("--preview")
    ap.add_argument("--scale", type=int, default=3)
    a = ap.parse_args(argv)
    out = Path(a.out)
    if out.exists():
        raise SystemExit(f"{out} exists: never overwrite a version")
    try:
        img = tilt(Image.open(a.src), a.angle)
    except ValueError as e:
        print(e)
        return 1
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print("wrote", out, img.getchannel("A").getbbox())
    if a.preview:
        bg = Image.new("RGBA", img.size, BG)
        bg.alpha_composite(img)
        bg.resize((FRAME * a.scale, FRAME * a.scale), Image.NEAREST).save(a.preview)
        print("wrote", a.preview)
    return 0


if __name__ == "__main__":
    sys.exit(main())
