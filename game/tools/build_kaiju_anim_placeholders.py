#!/usr/bin/env python3
"""Builds the kaiju's placeholder windup and death frames (T-612). Free: no PixelLab.

The final frames come from the art task T-613 in the same format (game/docs/enemies/kaiju.md,
"The kaiju's animations"). Until then these are made from the first frame of each walk sheet
(game/art/kaiju/kaiju_<dir>.png, T-069) by plain pixel moves, nearest neighbour only, every
colour taken from the walk sheet (alpha aside):

- windup: WINDUP_FRAMES frames, the kaiju rearing up: stretched taller and a little narrower
  about its feet, rising to the peak and holding it.
- death: DEATH_FRAMES frames (quick tuning 1, the board 2026-11-09: longer and more dramatic):
  the kaiju buckling (squashed, as before), sinking to its knees (no fade any more: it stays to
  fall), then falling forward: leaning over while it flattens onto the ground, a heavy slump
  that overshoots a little and settles, lying on the ground in the last frame (turned about its
  feet, lifted so it rests on the ground line and slid so it stays inside the frame). The game then holds the last frame for
  the cracks and the explosion, which are drawn in code (kaiju_sprite.gd).

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
BUCKLE_FRAMES = 4
KNEEL_FRAMES = 4
# The fall, per frame: (lean forward in degrees, height squash, width stretch). A heavy slump
# forward that flattens it onto the ground, overshooting a little and settling: a side view turned
# a full 90 degrees reads as a nose-dive, so the placeholder lies down by flattening.
TOPPLE = [(4, 0.85, 1.10), (9, 0.79, 1.13), (15, 0.71, 1.16), (20, 0.61, 1.19),
          (24, 0.51, 1.22), (26, 0.43, 1.26), (25, 0.48, 1.24), (24, 0.46, 1.25)]
DEATH_FRAMES = BUCKLE_FRAMES + KNEEL_FRAMES + len(TOPPLE)
KNEEL_SINK = 0.22  # how far it sinks, as a share of the feet's height
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


def death_poses():
    """(sx, sy, sink, angle) per death frame: buckling, sinking to its knees, then toppling."""
    out = []
    for i in range(BUCKLE_FRAMES):
        t = (i + 1) / BUCKLE_FRAMES
        out.append((1.0 + 0.08 * t, 1.0 - 0.12 * t, 0, 0.0))
    for i in range(KNEEL_FRAMES):
        t = (i + 1) / KNEEL_FRAMES
        out.append((1.08, 0.88, round(FEET_Y * KNEEL_SINK * t), 0.0))
    for ang, sy, sx in TOPPLE:
        # The knees' sink eases out as it flattens, so it ends lying on the ground, not sunk in it.
        ease = max(0.0, min(1.0, (sy - 0.4) / 0.48))
        out.append((sx, sy, round(FEET_Y * KNEEL_SINK * ease), float(ang)))
    return out


def topple(img, angle):
    """`img` turned `angle` degrees clockwise about its feet, then lifted so its lowest pixel rests
    on the ground line (FEET_Y + 2) and slid sideways so its middle stays at FEET_X (it fits the
    frame). Nearest neighbour; nothing below the ground line."""
    if angle == 0.0:
        return img
    big = Image.new("RGBA", (FRAME * 3, FRAME * 3), (0, 0, 0, 0))
    big.paste(img, (FRAME, FRAME), img)
    turned = big.rotate(-angle, resample=Image.NEAREST, center=(FRAME + FEET_X, FRAME + FEET_Y))
    box = turned.getbbox()
    if box is None:
        return Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    lift = box[3] - (FRAME + FEET_Y + 2)
    lift = max(lift, 0)
    mid = (box[0] + box[2]) // 2
    shift = mid - (FRAME + FEET_X)
    left = FRAME + shift
    top = FRAME + lift
    return turned.crop((left, top, left + FRAME, top + FRAME))


def sheet(frames):
    out = Image.new("RGBA", (FRAME * len(frames), FRAME), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(f, (i * FRAME, 0))
    return out


def build(walk_sheet):
    """(windup sheet, death sheet) from one walk sheet."""
    base = first_frame(walk_sheet)
    windup = sheet([pose(base, sx, sy) for sx, sy in windup_poses()])
    death = sheet([topple(pose(base, sx, sy, sink), ang) for sx, sy, sink, ang in death_poses()])
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
