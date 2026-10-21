"""Checks a level file (task T-231).

A level is a map file in the elevation sample map's format
(game/data/level/elevation_sample_map.json). This runs check_height_data.py's check_data on it and
also checks that:

- every building, rooftop (platform), ramp and boulder (pattern_copies[].boulders, a centre and a
  diameter) lies inside the map's rect (map.rect);
- the edges of buildings, rooftops and ramps lie on even units (enemy_navigation.gd's CELL = 2);
- ground_rows has as many rows and columns as the map's size in tiles (1 tile = 1 unit).

Usage, from the repo root:

    python game/tools/check_level.py <file.json>

Prints one line per problem and exits 1 when there is any, prints "OK" and exits 0 otherwise.
Standard library only.
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_height_data  # noqa: E402

CELL = 2.0  # enemy_navigation.gd's CELL (units)
EPS = 1e-6


def _rect(item):
    x, y, w, h = (float(item[k]) for k in ("x", "y", "w", "h"))
    return (x, y, x + w, y + h)


def _inside(inner, outer):
    return (inner[0] >= outer[0] - EPS and inner[1] >= outer[1] - EPS
            and inner[2] <= outer[2] + EPS and inner[3] <= outer[3] + EPS)


def _on_cell(v):
    q = v / CELL
    return abs(q - round(q)) <= EPS


def _items(data, key):
    """(label, rect) of each well-formed rectangle in data[key]; bad ones are the height check's job
    for platforms and ramps, and reported here for buildings."""
    out = []
    problems = []
    for i, item in enumerate(data.get(key, []) or []):
        name = "%s %r" % (key[:-1], item.get("id")) if isinstance(item, dict) and item.get("id") else "%s #%d" % (key[:-1], i)
        try:
            out.append((name, _rect(item)))
        except (KeyError, TypeError, ValueError):
            if key == "buildings":
                problems.append("%s: needs numbers x, y, w, h" % name)
    return out, problems


def check_level(data):
    """Returns a list of problems (strings); empty when the level is valid."""
    problems = list(check_height_data.check_data(data))
    if not isinstance(data, dict):
        return problems

    map_rect = None
    m = data.get("map")
    try:
        map_rect = _rect(m["rect"])
    except (KeyError, TypeError, ValueError):
        problems.append("map: needs a rect with numbers x, y, w, h")

    kinds = {"buildings": "building", "platforms": "rooftop", "ramps": "ramp"}
    for key, kind in kinds.items():
        items, bad = _items(data, key)
        problems.extend(bad)
        for name, r in items:
            label = name.replace(key[:-1], kind, 1)
            if map_rect is not None and not _inside(r, map_rect):
                problems.append("%s: lies outside the map" % label)
            if not all(_on_cell(v) for v in r):
                problems.append("%s: an edge is on an odd unit (edges lie on multiples of %g)" % (label, CELL))

    if map_rect is not None:
        for copy in data.get("pattern_copies", []) or []:
            cid = copy.get("id", "?") if isinstance(copy, dict) else "?"
            for j, b in enumerate(copy.get("boulders", []) if isinstance(copy, dict) else []):
                try:
                    x, y, r = float(b["x"]), float(b["y"]), float(b["diameter"]) / 2.0
                except (KeyError, TypeError, ValueError):
                    problems.append("boulder #%d of copy %r: needs numbers x, y and diameter" % (j, cid))
                    continue
                if not _inside((x - r, y - r, x + r, y + r), map_rect):
                    problems.append("boulder #%d of copy %r: lies outside the map" % (j, cid))

    # ground_rows: one string per tile row, one letter per tile column.
    try:
        cols, rows = int(round(float(m["width"]))), int(round(float(m["height"])))
    except (KeyError, TypeError, ValueError):
        cols = rows = None
        problems.append("map: needs numbers width and height")
    gr = data.get("ground_rows")
    if not isinstance(gr, list):
        problems.append("ground_rows: missing (a list of text rows)")
    elif cols is not None:
        if len(gr) != rows:
            problems.append("ground_rows: has %d rows, the map is %d tiles high" % (len(gr), rows))
        for i, row in enumerate(gr):
            if not isinstance(row, str) or len(row) != cols:
                problems.append("ground_rows: row %d has %s columns, the map is %d tiles wide"
                                % (i, len(row) if isinstance(row, str) else "no", cols))
                break
    return problems


def check_file(path):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError) as e:
        return ["can't read %s: %s" % (path, e)]
    return check_level(data)


def main(argv):
    if len(argv) != 2:
        print("usage: python game/tools/check_level.py <file.json>")
        return 2
    problems = check_file(argv[1])
    for p in problems:
        print(p)
    if not problems:
        print("OK")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
