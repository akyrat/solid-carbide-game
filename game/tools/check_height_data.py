"""Checks a ground-height data file (task T-193).

The format is game/README.md, "Elevation sample map", "Height data": a list of
platforms (axis-aligned rectangles with a height, optionally standing on
another platform with "on") and a list of ramps (a footprint next to the side
of the platform it climbs, rising from bottom_height at its foot to
top_height at that side). Units are the flat world's (x east, y south).

Usage, from the repo root:

    python game/tools/check_height_data.py <file.json>

Prints one line per problem and exits 1 when there is any, prints "OK" and
exits 0 otherwise. Standard library only.
"""
import json
import sys

SIDES = ("north", "east", "south", "west")
EPS = 1e-6


def _rect(item):
    x, y, w, h = (float(item[k]) for k in ("x", "y", "w", "h"))
    return (x, y, x + w, y + h)


def _overlap(a, b):
    """True when the rectangles share some area (touching sides don't count)."""
    return a[0] < b[2] - EPS and b[0] < a[2] - EPS and a[1] < b[3] - EPS and b[1] < a[3] - EPS


def _inside(inner, outer):
    return (inner[0] >= outer[0] - EPS and inner[1] >= outer[1] - EPS
            and inner[2] <= outer[2] + EPS and inner[3] <= outer[3] + EPS)


def _same(a, b):
    return abs(a - b) <= EPS


def _top_touches(side, ramp, area):
    """True when the ramp's top end lies on the area's side it climbs, within it."""
    if side in ("east", "west"):
        line_ok = _same(ramp[0], area[2]) if side == "east" else _same(ramp[2], area[0])
        return line_ok and ramp[1] >= area[1] - EPS and ramp[3] <= area[3] + EPS
    line_ok = _same(ramp[3], area[1]) if side == "north" else _same(ramp[1], area[3])
    return line_ok and ramp[0] >= area[0] - EPS and ramp[2] <= area[2] + EPS


def _ancestors(pid, on_of):
    """The platforms pid stands on, directly or through others (cycle-safe)."""
    seen = []
    cur = on_of.get(pid)
    while cur and cur not in seen:
        seen.append(cur)
        cur = on_of.get(cur)
    return seen


def check_data(data):
    """Returns a list of problems (strings); empty when the data is valid."""
    problems = []
    if not isinstance(data, dict):
        return ["the file is not a JSON object"]
    platforms = {}
    order = []
    on_of = {}
    for i, p in enumerate(data.get("platforms", [])):
        pid = str(p.get("id", "")) if isinstance(p, dict) else ""
        name = "platform %r" % pid if pid else "platform #%d" % i
        try:
            rect = _rect(p)
            height = float(p["height"])
        except (KeyError, TypeError, ValueError):
            problems.append("%s: needs numbers x, y, w, h and height" % name)
            continue
        if not pid:
            problems.append("%s: has no id" % name)
            continue
        if pid in platforms:
            problems.append("%s: the id is used twice" % name)
            continue
        if rect[2] - rect[0] <= 0 or rect[3] - rect[1] <= 0:
            problems.append("%s: w and h must be positive" % name)
        platforms[pid] = {"rect": rect, "height": height, "on": p.get("on")}
        order.append(pid)
        if p.get("on"):
            on_of[pid] = str(p["on"])

    # Stacking: "on" names an existing other area that contains the whole footprint.
    for pid in order:
        on = on_of.get(pid)
        if on is None:
            continue
        if on == pid:
            problems.append("platform %r: stands on itself" % pid)
        elif on not in platforms:
            problems.append("platform %r: stands on unknown area %r" % (pid, on))
        elif not _inside(platforms[pid]["rect"], platforms[on]["rect"]):
            problems.append("platform %r: stands on %r, which doesn't contain its whole footprint" % (pid, on))
        elif platforms[pid]["height"] <= platforms[on]["height"] + EPS:
            problems.append("platform %r: stands on %r but isn't higher than it" % (pid, on))
        if pid in _ancestors(pid, on_of):
            problems.append("platform %r: its 'on' chain loops back to itself" % pid)

    # Overlaps: allowed only when one stands on the other (directly or through others).
    for i, a in enumerate(order):
        for b in order[i + 1:]:
            if not _overlap(platforms[a]["rect"], platforms[b]["rect"]):
                continue
            if b in _ancestors(a, on_of) or a in _ancestors(b, on_of):
                continue
            problems.append("platforms %r and %r overlap, and neither is marked as standing on the other ('on')" % (a, b))

    ramp_ids = set()
    for i, r in enumerate(data.get("ramps", [])):
        rid = str(r.get("id", "")) if isinstance(r, dict) else ""
        name = "ramp %r" % rid if rid else "ramp #%d" % i
        try:
            rect = _rect(r)
            top = float(r["top_height"])
            bottom = float(r.get("bottom_height", 0.0))
        except (KeyError, TypeError, ValueError):
            problems.append("%s: needs numbers x, y, w, h and top_height" % name)
            continue
        if not rid:
            problems.append("%s: has no id" % name)
        elif rid in ramp_ids or rid in platforms:
            problems.append("%s: the id is used twice" % name)
        ramp_ids.add(rid)
        if rect[2] - rect[0] <= 0 or rect[3] - rect[1] <= 0:
            problems.append("%s: w and h must be positive" % name)
        side = r.get("side")
        if side not in SIDES:
            problems.append("%s: unknown side %r (north, east, south or west)" % (name, side))
        target = str(r.get("platform", ""))
        if target not in platforms:
            problems.append("%s: climbs to unknown area %r" % (name, target))
            continue
        area = platforms[target]
        if side in SIDES and not _top_touches(side, rect, area["rect"]):
            problems.append("%s: its top (the %s side of %r) doesn't touch area %r along that side"
                            % (name, side, target, target))
        if not _same(top, area["height"]):
            problems.append("%s: top_height %g doesn't match area %r's height %g"
                            % (name, top, target, area["height"]))
        # The ground at its foot: the street, or the highest area holding the whole footprint.
        foot_id, foot_h = None, 0.0
        for pid in order:
            if pid == target:
                continue
            if _inside(rect, platforms[pid]["rect"]) and platforms[pid]["height"] > foot_h:
                foot_id, foot_h = pid, platforms[pid]["height"]
        if not _same(bottom, foot_h):
            where = "area %r" % foot_id if foot_id else "the street"
            problems.append("%s: bottom_height %g doesn't match the ground at its foot (%s, %g)"
                            % (name, bottom, where, foot_h))
        # A ramp may stand on its foot area (and what that stands on), nothing else.
        allowed = set([foot_id] + _ancestors(foot_id, on_of)) if foot_id else set()
        for pid in order:
            if pid == target or pid in allowed:
                continue
            if _overlap(rect, platforms[pid]["rect"]):
                problems.append("%s: overlaps area %r without standing wholly on it" % (name, pid))
    return problems


def check_file(path):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError) as e:
        return ["can't read %s: %s" % (path, e)]
    return check_data(data)


def main(argv):
    if len(argv) != 2:
        print("usage: python game/tools/check_height_data.py <file.json>")
        return 2
    problems = check_file(argv[1])
    for p in problems:
        print(p)
    if not problems:
        print("OK")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
