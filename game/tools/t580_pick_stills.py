#!/usr/bin/env python3
"""Task T-580: turns one case's recorded frames (Godot --write-movie, frame n = physics step n + 1)
into <case>.gif and a few stills <case>_step<k>.png in the output folder.

    python game/tools/t580_pick_stills.py <frames dir> <out dir> <case> [step ...]

With no steps given, the case's own moments are used (STILLS): the step W takes over after the
turn, then 0.5 s and 1 s later (straight cases: the last step).
"""
import sys
from pathlib import Path

from PIL import Image

# Step where the last phase (W straight) starts, per case (facing_travel_probe.gd cases()).
W_START = {
    "coast_then_throttle": 88,
    "coast_long_then_throttle": 153,
    "drift_turn_onto_diagonal": 88,
    "turn_onto_screen_up_right": 93,
    "coast_turn_onto_screen_up_right": 93,
}


def stills_for(case):
    if case in W_START:
        k = W_START[case]
        return [k, k + 25, k + 50]
    return [100]


def frame_files(folder):
    return sorted(p for p in Path(folder).glob("*.png"))


def make(folder, out, case, steps=None, gif_every=2, gif_scale=0.6, gif_crop=(0, 0, 960, 560)):
    files = frame_files(folder)
    if not files:
        raise SystemExit("no frames in %s" % folder)
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    written = []
    for k in steps or stills_for(case):
        i = min(max(k - 1, 0), len(files) - 1)
        dst = out / ("%s_step%03d.png" % (case, k))
        with Image.open(files[i]) as im:
            im.convert("RGB").save(dst)
        written.append(dst)
    ims = []
    for f in files[::gif_every]:
        with Image.open(f) as im:
            im = im.convert("RGB")
            if gif_crop and im.width >= gif_crop[2] and im.height >= gif_crop[3]:
                im = im.crop(gif_crop)
            im = im.resize((int(im.width * gif_scale), int(im.height * gif_scale)), Image.LANCZOS)
            ims.append(im.quantize(colors=48, method=Image.MEDIANCUT, dither=Image.NONE))
    gif = out / ("%s.gif" % case)
    ims[0].save(gif, save_all=True, append_images=ims[1:], duration=int(1000 * gif_every / 50), loop=0)
    written.append(gif)
    return written


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 1
    steps = [int(a) for a in argv[3:]] or None
    for p in make(argv[0], argv[1], argv[2], steps):
        print("wrote", p)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
