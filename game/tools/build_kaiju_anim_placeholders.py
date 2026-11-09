#!/usr/bin/env python3
"""Builds the kaiju's placeholder windup and death frames (T-612). Free: no PixelLab.

The final frames come from the art task T-613 in the same format (game/docs/enemies/kaiju.md,
"The kaiju's animations"). Until then these are made from the first frame of each walk sheet
(game/art/kaiju/kaiju_<dir>.png, T-069) by plain pixel moves, nearest neighbour only, every
colour taken from the walk sheet (alpha aside):

- windup: WINDUP_FRAMES frames, the kaiju rearing up: stretched taller and a little narrower
  about its feet, rising to the peak and holding it.
- death: DEATH_FRAMES frames, the kaiju buckling (squashed), then sinking into the ground
  while it fades out; the last frame is empty.

One PNG per animation and drawn direction in game/art/placeholders/kaiju/:
kaiju_windup_<dir>.png and kaiju_death_<dir>.png, frames of FRAME x FRAME side by side, feet at
(FEET_X, FEET_Y) in every frame, as the walk sheets. The game reads the paths and counts from
game/data/enemies.json, "kaiju_animations".
Run from the repo root: python game/tools/build_kaiju_anim_placeholders.py
"""
from pathlib import Path

from PIL import Image

FRAME = 224
FEET_X = 112
FEET_Y = 203
DIRECTIONS = ["s", "se", "e", "ne", "n"]
WINDUP_FRAMES = 6
DEATH_FRAMES = 12
ROOT = Path(__file__).resolve().parents[2]


def first_frame(sheet):
    """The first FRAME x FRAME frame of a walk sheet, RGBA."""
    return sheet.convert("RGBA").crop((0, 0, FRAME, FRAME))


def pose(img, sx=1.0, sy=1.0, sink=0, alpha=1.0):
    """`img` scaled by (sx, sy) about its feet, moved `sink` pixels down with everything below
    the feet's line cut off, and its alpha multiplied by `alpha`. Nearest neighbour only."""
    w = max(1, round(FRAME * sx))
    h = max(1, round(FRAME * sy))
    scaled = img.resize((w, h), Image.NEAREST)
    out = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    out.paste(scaled, (round(FEET_X - FEET_X * sx), round(FEET_Y + sink - FEET_Y * sy)), scaled)
    if sink > 0:
        # Sinking into the ground: nothing shows below the line the feet stood on.
        cut = Image.new("RGBA", (FRAME, FRAME - FEET_Y - 2), (0, 0, 0, 0))
        out.paste(cut, (0, FEET_Y + 2))
    if alpha < 1.0:
        a = out.getchannel("A").point(lambda v: int(round(v * max(alpha, 0.0))))
        out.putalpha(a)
    return out


def windup_poses(n=WINDUP_FRAMES):
    """(sx, sy) per windup frame: up to the peak (1.12 tall, 0.94 wide) by the last but one, held."""
    out = []
    for i in range(n):
        t = min(1.0, i / max(1, n - 2))
        out.append((1.0 - 0.06 * t, 1.0 + 0.12 * t))
    return out


def death_poses(n=DEATH_FRAMES):
    """(sx, sy, sink, alpha) per death frame: a third buckling, then sinking and fading out."""
    buckle = max(1, n // 3)
    out = []
    for i in range(n):
        if i < buckle:
            t = (i + 1) / buckle
            out.append((1.0 + 0.08 * t, 1.0 - 0.12 * t, 0, 1.0))
        else:
            t = (i - buckle + 1) / (n - buckle)
            out.append((1.08, 0.88, round(FEET_Y * 0.9 * t), 1.0 - t))
    return out


def sheet(frames):
    out = Image.new("RGBA", (FRAME * len(frames), FRAME), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(f, (i * FRAME, 0))
    return out


def build(walk_sheet):
    """(windup sheet, death sheet) from one walk sheet."""
    base = first_frame(walk_sheet)
    windup = sheet([pose(base, sx, sy) for sx, sy in windup_poses()])
    death = sheet([pose(base, sx, sy, sink, a) for sx, sy, sink, a in death_poses()])
    return windup, death


def main():
    src = ROOT / "game" / "art" / "kaiju"
    out = ROOT / "game" / "art" / "placeholders" / "kaiju"
    out.mkdir(parents=True, exist_ok=True)
    for d in DIRECTIONS:
        windup, death = build(Image.open(src / f"kaiju_{d}.png"))
        windup.save(out / f"kaiju_windup_{d}.png")
        death.save(out / f"kaiju_death_{d}.png")
        print(f"{d}: windup {windup.size}, death {death.size}")


if __name__ == "__main__":
    main()
