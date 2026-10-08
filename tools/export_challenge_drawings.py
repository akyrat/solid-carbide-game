"""Save the board's challenge drawings from Crash City Grid into the repo.

Crash City Grid (the map editor page, linked from docs/level-design.md) keeps each
challenge drawing as a JSON document. The Project Lead downloads those documents
into a folder, then runs:

  python tools/export_challenge_drawings.py <folder with the downloaded .json files>

For every drawing with kind "challenge" it writes, under docs/level-design/:

  <pattern folder>/<drawing>.json   the drawing's data (ground, boulders, arrow path)
  <pattern folder>/<drawing>.svg    a picture of it, with the 3-unit-wide corridor

Coordinates are in units from the sheet's centre, x to the right and y down
(1 unit = the car's width). Running it twice gives identical files.
"""

import json
import math
import re
import sys
from pathlib import Path

OUT_DIR = Path(__file__).resolve().parent.parent / "docs" / "level-design"
CORRIDOR_WIDTH = 3.0   # units: as wide as the car is long (Level design, Decisions)
PX = 20                # pixels per unit in the pictures

COLOURS = {"R": "#5b5f68", "G": "#c9b48a", "B": "#4b3a8f", ".": "#f8f9fb"}
BOULDER = "#b4552c"
ARROW = "#c2186b"


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-") or "untitled"


def winding(points):
    """'clockwise' or 'counter-clockwise' as seen on screen (y down), from the path's signed area."""
    area = 0.0
    for (x1, y1), (x2, y2) in zip(points, points[1:] + points[:1]):
        area += x1 * y2 - x2 * y1
    if abs(area) < 1e-9:
        return "none"
    return "clockwise" if area > 0 else "counter-clockwise"


def turn_around(points, bx, by):
    """Signed degrees the path sweeps around a point; positive is clockwise on screen (y down)."""
    total = 0.0
    angles = [math.atan2(y - by, x - bx) for x, y in points]
    for a1, a2 in zip(angles, angles[1:]):
        d = a2 - a1
        while d > math.pi:
            d -= 2 * math.pi
        while d < -math.pi:
            d += 2 * math.pi
        total += d
    return math.degrees(total)


def around_boulders(points, boulders):
    out = []
    for i, b in enumerate(boulders):
        deg = round(turn_around(points, b["x"], b["y"]))
        direction = "clockwise" if deg > 0 else "counter-clockwise" if deg < 0 else "none"
        out.append({"boulder": i, "degrees": abs(deg), "direction": direction})
    return out


def clean(doc):
    """The fields worth keeping in the repo, in a fixed order."""
    group = (doc.get("groups") or [{}])[0]
    arrows = group.get("arrows") or ([group["arrow"]] if group.get("arrow") else [])
    arrow = arrows[0] if arrows else []
    boulders = [{"x": o["x"], "y": o["y"], "diameter": o["d"]} for o in doc.get("obstacles", [])]
    return {
        "pattern": doc.get("folder", ""),
        "name": doc.get("name", ""),
        "units": "1 unit = the car's width; the car is 1 x 3 units",
        "origin": "x and y in units from the sheet's centre, x to the right, y down",
        "width": doc["width"],
        "height": doc["height"],
        "legend": {"R": "road", "G": "gravel", "B": "building", ".": "empty"},
        "rows": doc["rows"],
        "boulders": boulders,
        "arrow": {
            "points": arrow,
            "around_boulders": around_boulders(arrow, boulders) if len(arrow) >= 2 else [],
            "corridor_width": CORRIDOR_WIDTH,
        },
    }


def path_d(points, cx, cy):
    P = [((x + cx) * PX, (y + cy) * PX) for x, y in points]
    d = f"M{P[0][0]:.1f},{P[0][1]:.1f}"
    if len(P) == 2:
        return d + f" L{P[1][0]:.1f},{P[1][1]:.1f}"
    for i in range(1, len(P) - 1):
        mx, my = (P[i][0] + P[i + 1][0]) / 2, (P[i][1] + P[i + 1][1]) / 2
        d += f" Q{P[i][0]:.1f},{P[i][1]:.1f} {mx:.1f},{my:.1f}"
    return d + f" L{P[-1][0]:.1f},{P[-1][1]:.1f}"


def svg(data):
    w, h = data["width"], data["height"]
    cx, cy = w / 2, h / 2
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w * PX}" height="{h * PX}" viewBox="0 0 {w * PX} {h * PX}">']
    for y, row in enumerate(data["rows"]):
        x = 0
        while x < w:  # merge runs of the same cell type into one rectangle
            run = x
            while run < w and row[run] == row[x]:
                run += 1
            out.append(f'<rect x="{x * PX}" y="{y * PX}" width="{(run - x) * PX}" height="{PX}" fill="{COLOURS.get(row[x], COLOURS["."])}"/>')
            x = run
    for b in data["boulders"]:
        out.append(f'<circle cx="{(b["x"] + cx) * PX:.1f}" cy="{(b["y"] + cy) * PX:.1f}" r="{b["diameter"] / 2 * PX:.1f}" fill="{BOULDER}" stroke="#1b1d26"/>')
    pts = data["arrow"]["points"]
    if len(pts) >= 2:
        d = path_d(pts, cx, cy)
        out.append(f'<path d="{d}" fill="none" stroke="{ARROW}" stroke-opacity="0.25" stroke-width="{CORRIDOR_WIDTH * PX}" stroke-linecap="round" stroke-linejoin="round"/>')
        out.append(f'<path d="{d}" fill="none" stroke="{ARROW}" stroke-width="{0.35 * PX:.1f}" stroke-linecap="round" stroke-linejoin="round"/>')
        (ax, ay), (bx, by) = pts[-2], pts[-1]
        ang = math.atan2(by - ay, bx - ax)
        tip = ((bx + cx) * PX, (by + cy) * PX)
        hl = 1.6 * PX
        left = (tip[0] - hl * math.cos(ang - 0.45), tip[1] - hl * math.sin(ang - 0.45))
        right = (tip[0] - hl * math.cos(ang + 0.45), tip[1] - hl * math.sin(ang + 0.45))
        out.append(f'<polygon points="{tip[0]:.1f},{tip[1]:.1f} {left[0]:.1f},{left[1]:.1f} {right[0]:.1f},{right[1]:.1f}" fill="{ARROW}"/>')
        sx, sy = (pts[0][0] + cx) * PX, (pts[0][1] + cy) * PX
        out.append(f'<circle cx="{sx:.1f}" cy="{sy:.1f}" r="{0.4 * PX:.1f}" fill="#ffffff" stroke="{ARROW}" stroke-width="2"/>')
    out.append("</svg>")
    return "\n".join(out) + "\n"


def export(src_dir, out_dir=OUT_DIR):
    written = []
    for f in sorted(Path(src_dir).glob("*.json")):
        doc = json.loads(f.read_text(encoding="utf-8"))
        if doc.get("kind") != "challenge":
            continue
        data = clean(doc)
        folder = Path(out_dir) / slug(data["pattern"])
        folder.mkdir(parents=True, exist_ok=True)
        base = folder / slug(data["name"].split(" - ")[-1])
        base.with_suffix(".json").write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8", newline="\n")
        base.with_suffix(".svg").write_text(svg(data), encoding="utf-8", newline="\n")
        turns = ", ".join(f'boulder {t["boulder"] + 1}: {t["direction"]} {t["degrees"]} deg' for t in data["arrow"]["around_boulders"])
        written.append((base, turns))
    return written


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    for base, turns in export(sys.argv[1]):
        print(f"{base.relative_to(OUT_DIR.parent.parent)}.json/.svg  ({turns})")
