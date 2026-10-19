"""Build the elevation sample map's layout file from the MVP map (task T-194).

Run from the repo root:

  python game/tools/build_elevation_sample_map.py            writes the layout and its picture
  python game/tools/build_elevation_sample_map.py --check    rebuilds in memory, says if the
                                                             committed layout differs (exit 1)

It reads game/data/level/mvp_map.json (never changes it) and writes:

  game/data/level/elevation_sample_map.json       the MVP layout keys mvp_map.gd reads, plus
                                                  `platforms` and `ramps` (height data, T-193)
  docs/level-design/elevation-sample-map.png      the layout, flat, top-down
  art-archive/T-194/screenshots/elevation-sample-map.png   a copy of the picture

Level design, Decisions, "Elevation sample map": three layers, the street (0), a first
floor (3) and a second floor (6), the raised areas building rooftops and the ramps
parking-garage ramps. Every size and position below is this agent's proposal for the
board's playtest.

What it does to the MVP layout:
- adds the rooftops (ROOFTOPS) and ramps (RAMPS);
- leaves out every MVP building under a rooftop's footprint;
- leaves out every boulder on a rooftop's or a ramp's footprint (or on the strip in front
  of a ramp's foot); a pattern copy left with no boulder is left out, and a challenge
  whose copy lost a boulder is left out (challenges are off in the MVP anyway);
- rebuilds ground_rows with the remaining buildings.
Then it runs the height-data validator (check_height_data.py) on the result.

Units are the map's: x east (right), y south (down), origin at the map's centre.
Standard library only. Running it twice gives identical files.
"""

import copy
import json
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_mvp_map as mvp  # noqa: E402
import check_height_data as checker  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
MVP_MAP = ROOT / "game" / "data" / "level" / "mvp_map.json"
OUT = ROOT / "game" / "data" / "level" / "elevation_sample_map.json"
PICTURE = ROOT / "docs" / "level-design" / "elevation-sample-map.png"
PICTURE_COPY = ROOT / "art-archive" / "T-194" / "screenshots" / "elevation-sample-map.png"

HEIGHTS = (0, 3, 6)

# ---- The layout (proposals for the board's playtest) ------------------------------------
#
# Two parking garages, the second the first turned half a turn around the map's centre:
#
#   North-west garage: a first-floor rooftop (3) over the top row's two west blocks and the
#   road between them (x -96..-12, y -96..-66, 84 by 30); a second-floor rooftop (6) on its
#   east block (x -42..-12, 30 by 30), whose north, east and south sides drop 6 straight to
#   the street. A 0-to-3 ramp climbs the first floor's south side from the road below it;
#   a 3-to-6 ramp on the first floor climbs the second floor's west side.
#   So: street -> ramp -> 3 -> ramp -> 6 -> off the east edge onto the road at x 0.
#
#   South-east garage: the same, mirrored through the centre.
#
# Ramps: 12 units long per 3 units of rise (the elevation test scene's slope, 1 in 4) and
# 10 units wide (the car is 1 by 3; roads are 24).

RAMP_LENGTH = 12
RAMP_WIDTH = 10
FOOT_APPROACH = 6    # the strip in front of a ramp's foot that must be clear to drive in

ROOFTOPS = [
    {"id": "roof-nw-3", "x": -96, "y": -96, "w": 84, "h": 30, "height": 3},
    {"id": "roof-nw-6", "x": -42, "y": -96, "w": 30, "h": 30, "height": 6, "on": "roof-nw-3"},
    {"id": "roof-se-3", "x": 12, "y": 66, "w": 84, "h": 30, "height": 3},
    {"id": "roof-se-6", "x": 12, "y": 66, "w": 30, "h": 30, "height": 6, "on": "roof-se-3"},
]

RAMPS = [
    # North-west: street up to the first floor, climbing north onto its south side,
    # from the road along x at y -54, centred on x -81 (the middle of the west block).
    {"id": "ramp-nw-0-3", "platform": "roof-nw-3", "side": "south",
     "x": -86, "y": -66, "w": RAMP_WIDTH, "h": RAMP_LENGTH, "bottom_height": 0, "top_height": 3},
    # North-west: first floor up to the second, climbing east onto its west side,
    # centred on y -81, standing on the first floor over the old road between the blocks.
    {"id": "ramp-nw-3-6", "platform": "roof-nw-6", "side": "west",
     "x": -54, "y": -86, "w": RAMP_LENGTH, "h": RAMP_WIDTH, "bottom_height": 3, "top_height": 6},
    # South-east: the same turned half a turn.
    {"id": "ramp-se-0-3", "platform": "roof-se-3", "side": "north",
     "x": 76, "y": 54, "w": RAMP_WIDTH, "h": RAMP_LENGTH, "bottom_height": 0, "top_height": 3},
    {"id": "ramp-se-3-6", "platform": "roof-se-6", "side": "east",
     "x": 42, "y": 76, "w": RAMP_LENGTH, "h": RAMP_WIDTH, "bottom_height": 3, "top_height": 6},
]


# ---- Geometry -----------------------------------------------------------------------------

def rect_of(d):
    """(x0, y0, x1, y1) of a rectangle dict with x, y, w, h."""
    return (float(d["x"]), float(d["y"]), float(d["x"]) + float(d["w"]), float(d["y"]) + float(d["h"]))


def rects_overlap(a, b):
    """True when the rectangles share some area (touching sides don't count)."""
    e = 1e-6
    return a[0] < b[2] - e and b[0] < a[2] - e and a[1] < b[3] - e and b[1] < a[3] - e


def circle_overlaps_rect(cx, cy, r, rect):
    """True when the circle and the rectangle share some area (touching doesn't count)."""
    nx = min(max(cx, rect[0]), rect[2])
    ny = min(max(cy, rect[1]), rect[3])
    return (cx - nx) ** 2 + (cy - ny) ** 2 < r * r - 1e-9


def rect_inside(inner, outer):
    e = 1e-6
    return (inner[0] >= outer[0] - e and inner[1] >= outer[1] - e
            and inner[2] <= outer[2] + e and inner[3] <= outer[3] + e)


def climb_direction(side):
    """Unit vector from a ramp's foot to its top, for the side of the area it climbs."""
    return {"north": (0, 1), "south": (0, -1), "east": (-1, 0), "west": (1, 0)}[side]


def foot_strip(ramp, depth=FOOT_APPROACH):
    """The strip in front of the ramp's foot (the end away from its area), `depth` deep and
    as wide as the ramp: where the car drives onto it."""
    x0, y0, x1, y1 = rect_of(ramp)
    side = ramp["side"]
    if side == "north":    # ramp north of its area, rises southward, foot at its north end
        return (x0, y0 - depth, x1, y0)
    if side == "south":    # rises northward, foot at its south end
        return (x0, y1, x1, y1 + depth)
    if side == "east":     # rises westward, foot at its east end
        return (x1, y0, x1 + depth, y1)
    return (x0 - depth, y0, x0, y1)   # west: rises eastward, foot at its west end


def ground_under(rect, platforms, exclude=None):
    """(id, height) of the highest platform holding the whole rectangle; (None, 0) for the street."""
    best = (None, 0.0)
    for p in platforms:
        if p["id"] == exclude:
            continue
        if rect_inside(rect, rect_of(p)) and float(p["height"]) > best[1]:
            best = (p["id"], float(p["height"]))
    return best


def reachable_areas(platforms, ramps):
    """The areas the car can reach from the street by driving up ramps (a graph walk:
    each ramp is an edge from the ground at its foot to the area it climbs to)."""
    edges = {}
    for r in ramps:
        below, _ = ground_under(rect_of(r), platforms, exclude=r["platform"])
        edges.setdefault(below or "street", []).append(r["platform"])
    seen = {"street"}
    todo = ["street"]
    while todo:
        cur = todo.pop()
        for nxt in edges.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                todo.append(nxt)
    return seen


def blocked_footprints(platforms, ramps):
    """Everything no boulder may overlap: every rooftop, every ramp and the strip in front
    of every ramp's foot."""
    return ([rect_of(p) for p in platforms] + [rect_of(r) for r in ramps]
            + [foot_strip(r) for r in ramps])


# ---- Build --------------------------------------------------------------------------------

def build(mvp_layout):
    """The sample map's layout, from the MVP map's layout (which is not changed)."""
    layout = copy.deepcopy(mvp_layout)
    platforms = [dict(p) for p in ROOFTOPS]
    ramps = [dict(r) for r in RAMPS]
    roofs = [rect_of(p) for p in platforms]
    no_boulder = blocked_footprints(platforms, ramps)

    kept_buildings = [b for b in layout["buildings"]
                      if not any(rects_overlap(rect_of(b), r) for r in roofs)]
    dropped_buildings = len(layout["buildings"]) - len(kept_buildings)

    copies = []
    dropped_boulders = 0
    damaged = set()
    for c in layout["pattern_copies"]:
        keep = [b for b in c["boulders"]
                if not any(circle_overlaps_rect(b["x"], b["y"], b["diameter"] / 2, r) for r in no_boulder)]
        if len(keep) != len(c["boulders"]):
            dropped_boulders += len(c["boulders"]) - len(keep)
            damaged.add(c["id"])
            c["boulders"] = keep
            c["challenge"] = None
        if keep:
            copies.append(c)
    challenges = [ch for ch in layout["challenges"] if ch["copy"] not in damaged]

    half = mvp.MAP_SIZE // 2
    if layout["map"]["width"] != mvp.MAP_SIZE or -layout["map"]["rect"]["x"] != half:
        raise ValueError("the MVP map's size changed; update build_mvp_map.MAP_SIZE")
    building_rects = [(b["x"], b["y"], b["w"], b["h"]) for b in kept_buildings]

    layout["name"] = "Elevation sample map"
    layout["task"] = "T-194 (from the MVP map, T-096, with rooftops at heights 3 and 6 and parking-garage ramps)"
    layout["generated_by"] = "python game/tools/build_elevation_sample_map.py"
    layout["based_on"] = "game/data/level/mvp_map.json"
    layout["elevation_note"] = (
        "Height data (platforms, ramps) in the format of game/README.md, 'Elevation sample map', "
        "'Height data'; checked with game/tools/check_height_data.py. Every rooftop and ramp is a "
        "proposal for the board's playtest. Left out from the MVP map: %d buildings under rooftops, "
        "%d boulders on rooftops, ramps or in front of a ramp's foot, %d pattern copies left with no "
        "boulder and %d challenges whose copy lost a boulder." % (
            dropped_buildings, dropped_boulders,
            len(layout["pattern_copies"]) - len(copies),
            len(layout["challenges"]) - len(challenges)))
    layout["buildings"] = kept_buildings
    layout["ground_rows"] = mvp.ground_rows(building_rects)
    layout["pattern_copies"] = copies
    layout["challenges"] = challenges
    layout["challenge_rule"] = dict(layout["challenge_rule"], copies=len(copies), challenges=len(challenges))
    layout["platforms"] = platforms
    layout["ramps"] = ramps
    return layout


def load_mvp(path=MVP_MAP):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def render_text(layout):
    return mvp.dumps_compact(layout) + "\n"


# ---- Picture (a PNG written with the standard library) -------------------------------------

PX = 3                    # picture pixels per unit
MARGIN = 4                # units of frame around the map
C_FRAME = (24, 26, 34)
C_STREET = (91, 95, 104)       # the MVP flat view's road grey
C_GRAVEL = (201, 180, 138)     # the MVP flat view's gravel
C_BUILDING = (75, 58, 143)     # the MVP flat view's building purple
C_H3 = (84, 156, 196)          # first floor: light blue
C_H6 = (236, 178, 66)          # second floor: amber
C_BOULDER = (180, 85, 44)      # the boulder orange of the flat view's rim
C_ARROW = (255, 255, 255)
C_EDGE = (20, 20, 24)


def _lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def _height_colour(h):
    if h >= 6:
        return C_H6
    if h >= 3:
        return C_H3
    return C_STREET


def draw(layout):
    """Returns (width, height, rows of RGB tuples)."""
    size = layout["map"]["width"] + 2 * MARGIN
    w = h = size * PX
    origin = -layout["map"]["width"] / 2 - MARGIN
    img = [[C_FRAME] * w for _ in range(h)]

    def to_px(x, y):
        return (int(round((x - origin) * PX)), int(round((y - origin) * PX)))

    def fill_rect(rect, colour):
        x0, y0 = to_px(rect[0], rect[1])
        x1, y1 = to_px(rect[2], rect[3])
        for j in range(max(0, y0), min(h, y1)):
            row = img[j]
            for i in range(max(0, x0), min(w, x1)):
                row[i] = colour

    def outline_rect(rect, colour):
        x0, y0 = to_px(rect[0], rect[1])
        x1, y1 = to_px(rect[2], rect[3])
        for i in range(x0, x1):
            img[y0][i] = colour
            img[y1 - 1][i] = colour
        for j in range(y0, y1):
            img[j][x0] = colour
            img[j][x1 - 1] = colour

    fill_rect(rect_of(layout["map"]["rect"]), C_STREET)
    fill_rect(rect_of(layout["gravel"]), C_GRAVEL)
    for b in layout["buildings"]:
        fill_rect(rect_of(b), C_BUILDING)
    for p in sorted(layout["platforms"], key=lambda p: p["height"]):
        fill_rect(rect_of(p), _height_colour(p["height"]))
        outline_rect(rect_of(p), C_EDGE)

    for r in layout["ramps"]:
        x0, y0, x1, y1 = rect_of(r)
        dx, dy = climb_direction(r["side"])
        lo, hi = _height_colour(r["bottom_height"]), _height_colour(r["top_height"])
        px0, py0 = to_px(x0, y0)
        px1, py1 = to_px(x1, y1)
        for j in range(py0, py1):
            for i in range(px0, px1):
                # 0 at the foot, 1 at the top.
                if dx:
                    t = (i - px0 + 0.5) / (px1 - px0)
                    t = t if dx > 0 else 1 - t
                else:
                    t = (j - py0 + 0.5) / (py1 - py0)
                    t = t if dy > 0 else 1 - t
                img[j][i] = _lerp(lo, hi, t)
        outline_rect((x0, y0, x1, y1), C_EDGE)
        # An arrowhead pointing uphill, from the foot towards the top.
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        length = abs((x1 - x0) * dx + (y1 - y0) * dy)
        width = abs((x1 - x0) * dy + (y1 - y0) * dx)
        tip = (cx + dx * length * 0.35, cy + dy * length * 0.35)
        base = (cx - dx * length * 0.35, cy - dy * length * 0.35)
        half = width * 0.3
        a = (base[0] + dy * half, base[1] + dx * half)
        b = (base[0] - dy * half, base[1] - dx * half)
        _fill_triangle(img, [to_px(*tip), to_px(*a), to_px(*b)], C_ARROW)

    for c in layout["pattern_copies"]:
        for bo in c["boulders"]:
            cx, cy = to_px(bo["x"], bo["y"])
            rad = bo["diameter"] / 2 * PX
            for j in range(int(cy - rad) - 1, int(cy + rad) + 2):
                for i in range(int(cx - rad) - 1, int(cx + rad) + 2):
                    if (i + 0.5 - cx) ** 2 + (j + 0.5 - cy) ** 2 <= rad * rad:
                        img[j][i] = C_BOULDER
    return w, h, img


def _fill_triangle(img, pts, colour):
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]

    def side(p, q, x, y):
        return (q[0] - p[0]) * (y - p[1]) - (q[1] - p[1]) * (x - p[0])

    for j in range(min(ys), max(ys) + 1):
        for i in range(min(xs), max(xs) + 1):
            x, y = i + 0.5, j + 0.5
            s = [side(pts[k], pts[(k + 1) % 3], x, y) for k in range(3)]
            if all(v >= 0 for v in s) or all(v <= 0 for v in s):
                img[j][i] = colour


def png_bytes(w, h, img):
    raw = b"".join(b"\x00" + bytes(c for px in row for c in px) for row in img)

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


# ---- Main ---------------------------------------------------------------------------------

def check_committed(out=OUT, mvp_path=MVP_MAP):
    """Returns a list of problems: the committed file differs from a rebuild, or the
    validator rejects it."""
    layout = build(load_mvp(mvp_path))
    problems = ["height data: " + p for p in checker.check_data(layout)]
    out = Path(out)
    if not out.exists():
        problems.append("%s is missing; run the script without --check" % out)
    elif out.read_text(encoding="utf-8") != render_text(layout):
        problems.append("%s differs from a rebuild; run the script without --check" % out)
    return problems


def write(out=OUT, mvp_path=MVP_MAP, pictures=(PICTURE, PICTURE_COPY)):
    layout = build(load_mvp(mvp_path))
    problems = checker.check_data(layout)
    if problems:
        raise ValueError("the height data is not valid: " + "; ".join(problems))
    out = Path(out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(render_text(layout), encoding="utf-8", newline="\n")
    data = png_bytes(*draw(layout))
    for p in pictures:
        p = Path(p)
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data)
    return layout


def main(argv):
    if argv == ["--check"]:
        problems = check_committed()
        for p in problems:
            print(p)
        if not problems:
            print("OK: %s matches a rebuild, and the height data is valid" % OUT.relative_to(ROOT))
        return 1 if problems else 0
    if argv:
        print(__doc__)
        return 2
    layout = write()
    print(layout["elevation_note"])
    print("wrote %s, %s and %s" % (OUT.relative_to(ROOT), PICTURE.relative_to(ROOT), PICTURE_COPY.relative_to(ROOT)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
