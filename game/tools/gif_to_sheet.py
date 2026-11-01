"""Turns the tutorial clips' GIFs into frame sheets the game plays (task T-485).

Godot does not play GIFs. For each GIF this writes, next to it, `<name>_sheet.png` (every frame
side by side in a grid, RGBA, no resampling: 1 GIF pixel = 1 sheet pixel) and `<name>_sheet.json`
(frame size, columns, frame count and each frame's own duration in milliseconds, read from the
GIF, so the timing is the GIF's). ClipPlayer (game/scripts/menu/clip_player.gd) reads both.

Run from the repo root:  python game/tools/gif_to_sheet.py [gif ...]
With no arguments it converts every .gif in game/art/tutorial/clips/.
"""
import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageSequence

CLIPS = Path(__file__).resolve().parent.parent / "art" / "tutorial" / "clips"


def read_gif(path):
    """(frames as RGBA images, durations in ms)."""
    im = Image.open(path)
    frames, durations = [], []
    for f in ImageSequence.Iterator(im):
        frames.append(f.convert("RGBA"))
        durations.append(int(f.info.get("duration", 40)))
    return frames, durations


def build_sheet(frames):
    """(sheet image, columns): the frames in a near-square grid, row by row."""
    w, h = frames[0].size
    cols = max(1, math.ceil(math.sqrt(len(frames))))
    rows = math.ceil(len(frames) / cols)
    sheet = Image.new("RGBA", (cols * w, rows * h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, ((i % cols) * w, (i // cols) * h))
    return sheet, cols


def convert(gif_path):
    gif_path = Path(gif_path)
    frames, durations = read_gif(gif_path)
    sheet, cols = build_sheet(frames)
    out = gif_path.with_name(gif_path.stem + "_sheet.png")
    sheet.save(out, optimize=True)
    meta = {
        "clip": gif_path.stem,
        "task": "T-485",
        "source": gif_path.name,
        "frame_size": list(frames[0].size),
        "columns": cols,
        "frames": len(frames),
        "durations_ms": durations,
        "seconds": sum(durations) / 1000.0,
    }
    out.with_suffix(".json").write_text(json.dumps(meta, indent=2) + "\n")
    return out, meta


def main(argv):
    gifs = [Path(a) for a in argv] or sorted(CLIPS.glob("*.gif"))
    for g in gifs:
        out, meta = convert(g)
        print(f"{g.name}: {meta['frames']} frames, {meta['seconds']:.2f} s -> {out.name} "
              f"({out.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main(sys.argv[1:])
