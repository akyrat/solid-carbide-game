"""Builds the car's drawn outline for the rail snap (task T-566; Drifting, Content, "The rail snap
on the drawing (task T-566)").

A grind starts when the car's drawing, as the player sees it, crosses a rail's drawing. The game
measures the car's drawing from this file instead of reading the sprite sheets' pixels at run time:
for every frame of the sheets the car is drawn from in the air (the shadowless sheet, and the three
rows of the tilt sheet), each pixel row's leftmost and rightmost opaque pixel (alpha >= 128).

    python game/tools/build_car_outline.py          write game/art/car/car_iso_outline.json
    python game/tools/build_car_outline.py --check  exit 1 when the file is out of date

Run it again whenever car_iso_noshadow.png or car_iso_tilt.png changes (the GUT test
test_rail_snap_drawing.gd checks a few frames against the PNGs).
"""
import json
import sys
from pathlib import Path

from PIL import Image

GAME = Path(__file__).resolve().parent.parent
CAR = GAME / "art" / "car"
OUT = CAR / "car_iso_outline.json"
ALPHA_MIN = 128

# key in the outline -> (sheet, row of the sheet)
SOURCES = {
    "air": ("car_iso_noshadow", 0),
    "tilt1": ("car_iso_tilt", 0),
    "tilt2": ("car_iso_tilt", 1),
    "tilt3": ("car_iso_tilt", 2),
}


def frame_spans(img, x0, y0, w, h):
    """[row, left, right, row, left, right, ...] for the opaque pixels of one frame."""
    px = img.load()
    out = []
    for y in range(h):
        left = right = -1
        for x in range(w):
            if px[x0 + x, y0 + y][3] >= ALPHA_MIN:
                if left < 0:
                    left = x
                right = x
        if left >= 0:
            out += [y, left, right]
    return out


def build():
    layout = json.loads((CAR / "car_iso_noshadow.json").read_text(encoding="utf-8"))
    w, h = int(layout["frame_width"]), int(layout["frame_height"])
    cols = int(layout.get("columns", layout["frame_count"]))
    sheets = {}
    for key, (name, row) in SOURCES.items():
        img = Image.open(CAR / (name + ".png")).convert("RGBA")
        sheets[key] = [frame_spans(img, c * w, row * h, w, h) for c in range(cols)]
    return {
        "_comment": "T-566: the car's drawn outline, per frame: each pixel row's leftmost and rightmost "
                    "opaque pixel, as [row, left, right, ...] in frame pixels. Built by "
                    "game/tools/build_car_outline.py from the sheets named in sources; read by "
                    "scripts/driving/car_outline.gd for the rail snap (Drifting, Content).",
        "sources": {k: {"sheet": v[0] + ".png", "row": v[1]} for k, v in SOURCES.items()},
        "frame_width": w,
        "frame_height": h,
        "frame_count": cols,
        "center_px": layout["center_px"],
        "px_per_unit": layout["px_per_unit"],
        "frame0_heading_deg": layout.get("frame0_heading_deg", 0.0),
        "alpha_min": ALPHA_MIN,
        "sheets": sheets,
    }


def dump(data):
    # One frame per line keeps the file readable and its diffs small.
    lines = ["{"]
    keys = [k for k in data if k != "sheets"]
    for k in keys:
        lines.append("  %s: %s," % (json.dumps(k), json.dumps(data[k])))
    lines.append('  "sheets": {')
    names = list(data["sheets"])
    for i, name in enumerate(names):
        lines.append("    %s: [" % json.dumps(name))
        frames = data["sheets"][name]
        for j, f in enumerate(frames):
            lines.append("      " + json.dumps(f, separators=(",", ":")) + ("," if j < len(frames) - 1 else ""))
        lines.append("    ]" + ("," if i < len(names) - 1 else ""))
    lines.append("  }")
    lines.append("}")
    return "\n".join(lines) + "\n"


def main(argv):
    text = dump(build())
    if "--check" in argv:
        same = OUT.exists() and OUT.read_text(encoding="utf-8") == text
        print("up to date" if same else "out of date: run python game/tools/build_car_outline.py")
        return 0 if same else 1
    OUT.write_text(text, encoding="utf-8", newline="\n")
    print("wrote", OUT)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
