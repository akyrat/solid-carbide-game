"""Turns the tutorial clips' GIFs into frame sheets the game plays (task T-485).

Godot does not play GIFs. For each GIF this writes, next to it, `<name>_sheet.png` (every frame
in a grid, RGBA, no resampling: 1 GIF pixel = 1 sheet pixel; a clip that does not fit 4096 x 4096
continues on `<name>_sheet_1.png` and so on) and `<name>_sheet.json`
(frame size, columns, pages, frame count and each frame's own duration in milliseconds, read from the
GIF, so the timing is the GIF's). ClipPlayer (game/scripts/menu/clip_player.gd) reads both.

Run from the repo root:  python game/tools/gif_to_sheet.py [gif ...]
With no arguments it converts every .gif in game/art/tutorial/clips/.
"""
import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageSequence

MAX_SIDE = 4096  # WebGL (the itch.io Web build) cannot load a texture with a side over 4096
CLIPS = Path(__file__).resolve().parent.parent / "art" / "tutorial" / "clips"


def read_gif(path):
    """(frames as RGBA images, durations in ms)."""
    im = Image.open(path)
    frames, durations = [], []
    for f in ImageSequence.Iterator(im):
        frames.append(f.convert("RGBA"))
        durations.append(int(f.info.get("duration", 40)))
    return frames, durations


def build_sheets(frames, max_side=MAX_SIDE):
    """(pages, columns, rows per page): the frames in a grid, row by row, split into pages whose
    sides are at most `max_side` pixels (WebGL cannot load a bigger texture)."""
    w, h = frames[0].size
    cols = max(1, max_side // w)
    rows = max(1, max_side // h)
    per_page = cols * rows
    pages = []
    for first in range(0, len(frames), per_page):
        chunk = frames[first:first + per_page]
        page_rows = math.ceil(len(chunk) / cols)
        page = Image.new("RGBA", (min(cols, len(chunk)) * w, page_rows * h), (0, 0, 0, 0))
        for i, f in enumerate(chunk):
            page.paste(f, ((i % cols) * w, (i // cols) * h))
        pages.append(page)
    return pages, cols, rows


def page_name(stem, n):
    return f"{stem}_sheet.png" if n == 0 else f"{stem}_sheet_{n}.png"


def convert(gif_path):
    gif_path = Path(gif_path)
    frames, durations = read_gif(gif_path)
    pages, cols, rows = build_sheets(frames)
    for old in gif_path.parent.glob(gif_path.stem + "_sheet*.png"):
        old.unlink()
    names = []
    for n, page in enumerate(pages):
        name = page_name(gif_path.stem, n)
        page.save(gif_path.with_name(name), optimize=True)
        names.append(name)
    meta = {
        "clip": gif_path.stem,
        "task": "T-485",
        "source": gif_path.name,
        "frame_size": list(frames[0].size),
        "columns": cols,
        "rows_per_page": rows,
        "frames_per_page": cols * rows,
        "pages": names,
        "frames": len(frames),
        "durations_ms": durations,
        "seconds": sum(durations) / 1000.0,
    }
    gif_path.with_name(gif_path.stem + "_sheet.json").write_text(json.dumps(meta, indent=2) + "\n")
    return names, meta


def main(argv):
    gifs = [Path(a) for a in argv] or sorted(CLIPS.glob("*.gif"))
    for g in gifs:
        names, meta = convert(g)
        print(f"{g.name}: {meta['frames']} frames, {meta['seconds']:.2f} s -> {', '.join(names)}")


if __name__ == "__main__":
    main(sys.argv[1:])
