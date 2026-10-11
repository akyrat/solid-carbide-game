"""Build the MVP map's layout data and the fitted challenge patterns (task T-019).

Run from the repo root:

  python game/tools/build_mvp_map.py

It reads the board's sketches in docs/level-design/<pattern>/<arrow>.json (never
changes them) and writes:

  docs/level-design/<pattern>/<arrow>.fitted.json/.svg   the fitted version of each sketch
  game/data/level/mvp_map.json                          the whole map: ground, buildings,
                                                        pattern copies, boulders, challenges

Challenges are left out of the MVP (task T-097): the map in the game ignores the
challenges written here unless mvp_map.gd's CHALLENGES_ENABLED is true. They are still
written, unchanged, so challenges can come back without rebuilding anything.

All coordinates are in units (1 unit = the car's width), x to the right, y down.
The map's origin is its centre, as in Crash City Grid, so the map runs from -120 to 120
(240 by 240, task T-096: the first map's 80 by 80 layout, task T-019, three times bigger).
Running it twice gives identical files. Standard library only.

How a sketch is fitted (Level design, Decisions: keep the number of boulders, the
direction around each boulder and the overall path; size, spacing and tightness
may change):

- The sketch is moved so its boulders sit where the fitted version wants them,
  keeping the sketch's size and the spacing between its boulders.
- Each arrow point is then nudged, as little as possible, until the arrow's
  centre line keeps BOULDER_CLEARANCE from every boulder's centre and its
  3-unit corridor keeps BUILDING_MARGIN from every building of the place the
  pattern is made for (FIT_CONTEXTS).
"""

import json
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SKETCH_DIR = ROOT / "docs" / "level-design"
SKETCH_NAME = re.compile(r"^arrow-\d+\.json$")
MAP_OUT = ROOT / "game" / "data" / "level" / "mvp_map.json"

# ---- The map (Level design, Decisions) -------------------------------------------------

# Level design (2026-10-11, task T-096): 240 by 240, the first plan's 80 by 80 layout with
# everything three times bigger. 2 x 24 (perimeter road) + 4 x 30 (blocks) + 3 x 24 (roads) = 240.
MAP_SIZE = 240         # units, square
PERIMETER_ROAD = 24    # the road around the edge
BLOCK = 30             # building blocks are 30 by 30
ROAD = 24              # roads between blocks
BLOCKS_PER_SIDE = 4    # 4 by 4 grid of blocks
GRAVEL = 84            # the open gravel square in the centre: the middle 2 by 2 blocks
                       # and the road between them

CORRIDOR_WIDTH = 3.0   # the arrow is as wide as the car is long
BOULDER_DIAMETER = 3.0

# ---- Fitting choices (this agent's, listed in the task's result notes) --------------------

BOULDER_CLEARANCE = 2.0   # centre line to boulder centre: rock radius 1.5 + half the car's width 0.5
BUILDING_MARGIN = 0.25    # corridor edge to the nearest building
SAMPLES_PER_CURVE = 16    # centre line samples per quadratic piece

# Where each fitted pattern is made to fit, in pattern coordinates (pattern centre = 0, 0):
# "intersection": a 24 by 24 crossing of two 24-unit roads (buildings where |x| >= 12 and |y| >= 12);
# "road": a straight 24-unit road running along y (buildings where |x| >= 12).
# On 24-unit roads every sketch fits as drawn (task T-096), so the fitted versions are the
# sketches moved onto the pattern's centre, with no arrow point nudged.
FIT_CONTEXTS = {
    "single-boulder": "intersection",
    "two-boulders": "road",
}

# The boulders' places in each fitted pattern. Single Boulder: on the crossing's centre.
# Two Boulders: on the road's centre line, as far apart as in the sketch (7 units).
FITTED_BOULDERS = {
    "single-boulder": [(0.0, 0.0)],
    "two-boulders": [(0.0, -3.5), (0.0, 3.5)],
}

CHALLENGE_SHARE = 0.30


def crossings():
    """Centre of each road crossing inside the perimeter road, along one axis (units)."""
    return [s + BLOCK + ROAD / 2 for s in block_ranges()[:-1]]


def road_lines():
    """The centre line of every road along one axis, the perimeter road's two sides included."""
    edge = MAP_SIZE / 2 - PERIMETER_ROAD / 2
    return [-edge] + crossings() + [edge]


def block_middles():
    """The middle of each block along one axis: the middle of each stretch of road between two
    crossings."""
    return [s + BLOCK / 2 for s in block_ranges()]


def in_gravel(x, y):
    g = GRAVEL / 2
    return abs(x) < g and abs(y) < g


def _num(v):
    return int(v) if v == int(v) else v


def make_copies():
    """The pattern copies on the map: (pattern, centre x, centre y, rotation in degrees clockwise),
    in reading order (top to bottom, then left to right).

    Task T-096 (240 by 240, 24-unit roads): a Single Boulder on the centre of every place where
    two road centre lines cross (the crossings, the perimeter road's T-junctions and its corners),
    and a Two Boulders on the middle of every stretch of road between them, turned to run along
    the road. No copy in the gravel. Neighbouring copies are 27 units apart. Turning by whole
    quarter turns keeps clockwise clockwise.
    """
    lines = road_lines()
    middles = block_middles()
    out = []
    for y in lines:
        for x in lines:
            out.append(("single-boulder", x, y, 0))
    for v in lines:
        for m in middles:
            out.append(("two-boulders", v, m, 0))    # along a road running along y
            out.append(("two-boulders", m, v, 90))   # along a road running along x
    out = [(p, _num(x), _num(y), d) for p, x, y, d in out if not in_gravel(x, y)]
    out.sort(key=lambda c: (c[2], c[1]))
    return out


def make_challenges(copies):
    """Which copies are challenges: (index into copies, arrow name). Fixed, the same every run.
    30% of the copies, spread evenly through the reading order (copy number (k + 0.5) n / count),
    so they are spread over the whole map. Single Boulder challenges take arrow 1 and arrow 2
    in turn."""
    n = len(copies)
    count = challenge_count(n)
    out = []
    single = 0
    for k in range(count):
        ci = int((k + 0.5) * n / count)
        if copies[ci][0] == "single-boulder":
            out.append((ci, "arrow-1" if single % 2 == 0 else "arrow-2"))
            single += 1
        else:
            out.append((ci, "arrow-1"))
    return out


def challenge_count(copies):
    """30% of the pattern copies, rounded half up to a whole number, at least 1."""
    return max(1, math.floor(copies * CHALLENGE_SHARE + 0.5))


# ---- Geometry ------------------------------------------------------------------------------

def smooth(points, steps=SAMPLES_PER_CURVE):
    """The arrow's centre line, drawn exactly as the sketches' pictures draw it: a quadratic
    curve through the midpoints between the points, each point acting as a control point,
    with straight ends to the first and last point."""
    pts = [tuple(map(float, p)) for p in points]
    if len(pts) < 3:
        return pts
    out = [pts[0]]
    cur = pts[0]
    for i in range(1, len(pts) - 1):
        c = pts[i]
        end = ((pts[i][0] + pts[i + 1][0]) / 2, (pts[i][1] + pts[i + 1][1]) / 2)
        for k in range(1, steps + 1):
            t = k / steps
            a, b, d = (1 - t) ** 2, 2 * (1 - t) * t, t * t
            out.append((a * cur[0] + b * c[0] + d * end[0], a * cur[1] + b * c[1] + d * end[1]))
        cur = end
    out.append(pts[-1])
    return out


def turn_around(points, bx, by):
    """Signed degrees the path sweeps around a point; positive is clockwise on screen (y down).
    Same measure as tools/export_challenge_drawings.py."""
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


def rect_distance(px, py, rect):
    """Distance from a point to a rectangle (x, y, w, h); 0 inside."""
    x, y, w, h = rect
    dx = max(x - px, 0.0, px - (x + w))
    dy = max(y - py, 0.0, py - (y + h))
    return math.hypot(dx, dy)


def context_buildings(context):
    """The buildings around a fitted pattern, as rectangles in pattern coordinates."""
    far = float(BLOCK)
    h = ROAD / 2
    if context == "intersection":
        return [(h, h, far, far), (-h - far, h, far, far),
                (h, -h - far, far, far), (-h - far, -h - far, far, far)]
    if context == "road":
        return [(h, -far, far, 2 * far), (-h - far, -far, far, 2 * far)]
    raise ValueError(context)


def _push_from_rect(p, rect, dist):
    """Moves p the least distance so it is at least dist away from rect."""
    x, y, w, h = rect
    px, py = p
    cx = min(max(px, x), x + w)
    cy = min(max(py, y), y + h)
    dx, dy = px - cx, py - cy
    d = math.hypot(dx, dy)
    if d >= dist:
        return p
    if d > 1e-12:
        return (cx + dx / d * dist, cy + dy / d * dist)
    # Inside: leave by the nearest side.
    options = [(px - x + dist, (x - dist, py)), (x + w - px + dist, (x + w + dist, py)),
               (py - y + dist, (px, y - dist)), (y + h - py + dist, (px, y + h + dist))]
    return min(options)[1]


def _push_from_point(p, c, dist):
    dx, dy = p[0] - c[0], p[1] - c[1]
    d = math.hypot(dx, dy)
    if d >= dist:
        return p
    if d < 1e-12:
        dx, dy, d = 1.0, 0.0, 1.0
    return (c[0] + dx / d * dist, c[1] + dy / d * dist)


def violations(centre_line, boulders, buildings):
    """How far the centre line breaks the fitting rules (0 = fits)."""
    worst = 0.0
    need = CORRIDOR_WIDTH / 2 + BUILDING_MARGIN
    for p in centre_line:
        for b in boulders:
            worst = max(worst, BOULDER_CLEARANCE - math.hypot(p[0] - b[0], p[1] - b[1]))
        for r in buildings:
            worst = max(worst, need - rect_distance(p[0], p[1], r))
    return worst


def fit_points(points, boulders, buildings):
    """Nudges the arrow points until the smoothed centre line fits (see the module notes)."""
    extra = 0.0
    while extra < 2.0:
        pts = [tuple(p) for p in points]
        need = CORRIDOR_WIDTH / 2 + BUILDING_MARGIN + extra
        for _ in range(200):
            moved = 0.0
            for i, p in enumerate(pts):
                q = p
                for b in boulders:
                    q = _push_from_point(q, b, BOULDER_CLEARANCE + extra)
                for r in buildings:
                    q = _push_from_rect(q, r, need)
                moved = max(moved, math.hypot(q[0] - p[0], q[1] - p[1]))
                pts[i] = q
            if moved < 1e-9:
                break
        pts = [(round(x, 3), round(y, 3)) for x, y in pts]
        if violations(smooth(pts), boulders, buildings) <= 1e-9:
            return pts
        extra += 0.05
    raise RuntimeError("could not fit the arrow")


def fit_sketch(sketch, pattern):
    """The fitted version of one sketch, as a dict in the sketches' JSON format."""
    old = [(b["x"], b["y"]) for b in sketch["boulders"]]
    new = FITTED_BOULDERS[pattern]
    if len(old) != len(new):
        raise ValueError("the fitted pattern must keep the sketch's boulders")
    # Move the sketch so the centre of its boulders lands on the centre of the fitted ones.
    ox = sum(b[0] for b in old) / len(old) - sum(b[0] for b in new) / len(new)
    oy = sum(b[1] for b in old) / len(old) - sum(b[1] for b in new) / len(new)
    moved = [(x - ox, y - oy) for x, y in sketch["arrow"]["points"]]
    context = FIT_CONTEXTS[pattern]
    buildings = context_buildings(context)
    pts = fit_points(moved, new, buildings)
    boulders = [{"x": x, "y": y, "diameter": BOULDER_DIAMETER} for x, y in new]
    size = ROAD + 8   # the picture shows the road and the edge of the buildings around it
    rows = []
    for j in range(size):
        row = ""
        for i in range(size):
            cx, cy = i - size / 2 + 0.5, j - size / 2 + 0.5
            inside = any(rect_distance(cx, cy, r) == 0 for r in buildings)
            row += "B" if inside else "R"
        rows.append(row)
    arrow_pts = [[x, y] for x, y in pts]
    return {
        "pattern": sketch["pattern"],
        "name": sketch["name"] + " (fitted)",
        "sketch": sketch["name"],
        "fitted_for": {
            "intersection": "a crossing of two %d-unit roads, the pattern's centre on the crossing's centre" % ROAD,
            "road": "a straight %d-unit road running along y, the pattern's centre on the road's centre line" % ROAD,
        }[context],
        "units": sketch["units"],
        "origin": "x and y in units from the pattern's centre, x to the right, y down",
        "width": size,
        "height": size,
        "legend": sketch["legend"],
        "rows": rows,
        "boulders": boulders,
        "arrow": {
            "points": arrow_pts,
            "around_boulders": around_boulders(pts, boulders),
            "corridor_width": CORRIDOR_WIDTH,
        },
    }


def rotate(p, degrees):
    """Turns a point clockwise on screen (y down) by a whole number of quarter turns."""
    q = int(degrees) // 90 % 4
    x, y = p
    for _ in range(q):
        x, y = -y, x
    return (x, y)


def place(p, cx, cy, degrees):
    x, y = rotate(p, degrees)
    return (round(x + cx, 3), round(y + cy, 3))


# ---- The map -------------------------------------------------------------------------------

def block_ranges():
    """Start of each block along one axis, in map units from the centre."""
    half = MAP_SIZE / 2
    starts = []
    pos = -half + PERIMETER_ROAD
    for _ in range(BLOCKS_PER_SIDE):
        starts.append(pos)
        pos += BLOCK + ROAD
    return starts


def gravel_rect():
    return (-GRAVEL / 2, -GRAVEL / 2, GRAVEL, GRAVEL)


def blocks():
    g = gravel_rect()
    out = []
    for y in block_ranges():
        for x in block_ranges():
            r = (x, y, BLOCK, BLOCK)
            # Blocks inside the gravel square are left out.
            if x >= g[0] and y >= g[1] and x + BLOCK <= g[0] + g[2] and y + BLOCK <= g[1] + g[3]:
                continue
            out.append(r)
    return out


def ground_rows(buildings):
    """The whole ground, one letter per 1-unit cell, in the sketches' legend."""
    half = MAP_SIZE // 2
    g = gravel_rect()
    rows = []
    for j in range(MAP_SIZE):
        row = ""
        for i in range(MAP_SIZE):
            cx, cy = i - half + 0.5, j - half + 0.5
            if any(rect_distance(cx, cy, r) == 0 for r in buildings):
                row += "B"
            elif rect_distance(cx, cy, g) == 0:
                row += "G"
            else:
                row += "R"
        rows.append(row)
    return rows


def rect_dict(r):
    return {"x": r[0], "y": r[1], "w": r[2], "h": r[3]}


def build(sketch_dir=SKETCH_DIR):
    """Returns (fitted versions by (pattern, arrow), the map layout dict)."""
    fitted = {}
    for pattern in sorted(FIT_CONTEXTS):
        for f in sorted((Path(sketch_dir) / pattern).glob("arrow-*.json")):
            if not SKETCH_NAME.match(f.name):  # only the board's sketches, not .fitted/.driven files
                continue
            sketch = json.loads(f.read_text(encoding="utf-8"))
            fitted[(pattern, f.stem)] = fit_sketch(sketch, pattern)

    buildings = blocks()
    copy_list = make_copies()
    copies = []
    for i, (pattern, cx, cy, deg) in enumerate(copy_list):
        base = next(v for (p, _), v in sorted(fitted.items()) if p == pattern)
        copies.append({
            "id": "copy-%02d" % (i + 1),
            "pattern": pattern,
            "fitted_versions": ["docs/level-design/%s/%s.fitted.json" % (p, a)
                                for (p, a) in sorted(fitted) if p == pattern],
            "centre": [cx, cy],
            "rotation_degrees": deg,
            "boulders": [
                {"x": place((b["x"], b["y"]), cx, cy, deg)[0],
                 "y": place((b["x"], b["y"]), cx, cy, deg)[1],
                 "diameter": b["diameter"]}
                for b in base["boulders"]
            ],
            "challenge": None,
        })

    chosen = make_challenges(copy_list)
    if len(chosen) != challenge_count(len(copy_list)):
        raise ValueError("the challenges must be 30% of the copies")
    challenges = []
    for n, (ci, arrow) in enumerate(chosen):
        copy = copies[ci]
        fv = fitted[(copy["pattern"], arrow)]
        cx, cy = copy["centre"]
        deg = copy["rotation_degrees"]
        pts = [list(place(p, cx, cy, deg)) for p in fv["arrow"]["points"]]
        line = [[round(x, 3), round(y, 3)] for x, y in smooth(pts)]
        cid = "challenge-%d" % (n + 1)
        copy["challenge"] = cid
        challenges.append({
            "id": cid,
            "copy": copy["id"],
            "pattern": copy["pattern"],
            "arrow": arrow,
            "fitted": "docs/level-design/%s/%s.fitted.json" % (copy["pattern"], arrow),
            "corridor_width": CORRIDOR_WIDTH,
            "points": pts,
            "centre_line": line,
        })

    # The 3 challenge designs, unplaced (centred on the pattern's centre, rotation 0), for the
    # challenges created during a run by the kaiju's meteors (task T-035).
    designs = []
    for (pattern, arrow), fv in sorted(fitted.items()):
        pts = [[round(x, 3), round(y, 3)] for x, y in fv["arrow"]["points"]]
        designs.append({
            "id": "%s/%s" % (pattern, arrow),
            "pattern": pattern,
            "arrow": arrow,
            "fitted": "docs/level-design/%s/%s.fitted.json" % (pattern, arrow),
            "boulders": [{"x": b["x"], "y": b["y"], "diameter": b["diameter"]} for b in fv["boulders"]],
            "corridor_width": CORRIDOR_WIDTH,
            "points": pts,
            "centre_line": [[round(x, 3), round(y, 3)] for x, y in smooth(pts)],
        })

    half = MAP_SIZE / 2
    layout = {
        "name": "MVP map",
        "task": "T-019, T-094, T-096 (240 by 240, everything three times bigger)",
        "generated_by": "python game/tools/build_mvp_map.py",
        "units": "1 unit = the car's width; the car is drawn 1 x 3 units",
        "origin": "x and y in units from the map's centre, x to the right, y down; rectangles give their top-left corner",
        "px_per_unit": 16,
        "map": {"width": MAP_SIZE, "height": MAP_SIZE, "rect": rect_dict((-half, -half, MAP_SIZE, MAP_SIZE)),
                "edge": "hard stop"},
        "perimeter_road_width": PERIMETER_ROAD,
        "road_width": ROAD,
        "block_size": BLOCK,
        "gravel": rect_dict(gravel_rect()),
        "buildings": [rect_dict(r) for r in buildings],
        "legend": {"R": "road", "G": "gravel", "B": "building"},
        "ground_rows": ground_rows(buildings),
        "challenge_rule": {
            "share": CHALLENGE_SHARE,
            "rounding": "round half up, at least 1",
            "copies": len(copies),
            "challenges": len(challenges),
        },
        "pattern_copies": copies,
        "challenges": challenges,
        "centre_line": "each challenge's centre_line is its arrow points drawn as in the sketches' pictures: quadratic curves through the midpoints between points, straight ends",
        "challenge_designs_note": "the fitted challenge designs in units from the pattern's centre, rotation 0; the map places them during a run for the kaiju's meteor challenges (T-035)",
        "challenge_designs": designs,
    }
    return fitted, layout


# ---- Pictures of the fitted versions ---------------------------------------------------------

PX = 20
COLOURS = {"R": "#5b5f68", "G": "#c9b48a", "B": "#4b3a8f", ".": "#f8f9fb"}
BOULDER = "#b4552c"
ARROW = "#c2186b"


def svg(data):
    """Same look as the sketches' pictures (tools/export_challenge_drawings.py)."""
    w, h = data["width"], data["height"]
    cx, cy = w / 2, h / 2
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w * PX}" height="{h * PX}" viewBox="0 0 {w * PX} {h * PX}">']
    for y, row in enumerate(data["rows"]):
        x = 0
        while x < w:
            run = x
            while run < w and row[run] == row[x]:
                run += 1
            out.append(f'<rect x="{x * PX}" y="{y * PX}" width="{(run - x) * PX}" height="{PX}" fill="{COLOURS.get(row[x], COLOURS["."])}"/>')
            x = run
    for b in data["boulders"]:
        out.append(f'<circle cx="{(b["x"] + cx) * PX:.1f}" cy="{(b["y"] + cy) * PX:.1f}" r="{b["diameter"] / 2 * PX:.1f}" fill="{BOULDER}" stroke="#1b1d26"/>')
    pts = data["arrow"]["points"]
    line = smooth(pts)
    d = "M" + " L".join(f"{(x + cx) * PX:.1f},{(y + cy) * PX:.1f}" for x, y in line)
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


def dumps_compact(data):
    """JSON with one point (a pair of numbers) per line, so the file stays readable."""
    text = json.dumps(data, indent=1)
    return re.sub(r"\[\s*(-?[\d.e+-]+),\s*(-?[\d.e+-]+)\s*\]", r"[\1, \2]", text)


def write(sketch_dir=SKETCH_DIR, map_out=MAP_OUT):
    fitted, layout = build(sketch_dir)
    written = []
    for (pattern, arrow), data in sorted(fitted.items()):
        base = Path(sketch_dir) / pattern / (arrow + ".fitted")
        Path(str(base) + ".json").write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8", newline="\n")
        Path(str(base) + ".svg").write_text(svg(data), encoding="utf-8", newline="\n")
        written.append(Path(str(base) + ".json"))
    map_out = Path(map_out)
    map_out.parent.mkdir(parents=True, exist_ok=True)
    map_out.write_text(dumps_compact(layout) + "\n", encoding="utf-8", newline="\n")
    written.append(map_out)
    return written, fitted, layout


if __name__ == "__main__":
    if len(sys.argv) != 1:
        print(__doc__)
        sys.exit(2)
    files, fitted, layout = write()
    for (pattern, arrow), data in sorted(fitted.items()):
        turns = ", ".join(f'boulder {t["boulder"] + 1}: {t["direction"]} {t["degrees"]} deg'
                          for t in data["arrow"]["around_boulders"])
        print(f"{pattern}/{arrow}.fitted  ({turns})")
    print(f"{layout['challenge_rule']['copies']} pattern copies, {layout['challenge_rule']['challenges']} challenges")
    print(f"wrote {MAP_OUT.relative_to(ROOT)}")
