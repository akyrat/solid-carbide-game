"""Short buildings become platforms (task T-405): the Python mirror of game/scripts/level/short_platforms.gd.

The low-rise ("short-N"), the small ("building-small") and the long ("building-long") buildings of a level are
platforms at HEIGHT (3 units); only the skyscrapers stay solid buildings. The level file is unchanged: such a
building stays an entry of "buildings", and platforms_of(data) gives the platforms it makes, in the height data's
format ({id, x, y, w, h, height}) plus "short": True. A whole block of four (an entry with no "asset", the game's
own map) in a layout with "platforms" makes a platform of each of its short slots (building_towers.gd make_plan,
mirrored here). check_height_data.py adds them to the file's rooftops, so ramps may climb to them and rooftops may
stand on them. Standard library only.
"""
import json
import math
from pathlib import Path

HEIGHT = 3.0
GAME = Path(__file__).resolve().parents[1]
BUILDING_ART = GAME / "art" / "buildings" / "skyscrapers.json"
_ART = {}


def is_platform_asset(asset):
    asset = str(asset or "")
    return asset.startswith("short-") or asset in ("building-small", "building-long")


def is_platform_entry(entry):
    return isinstance(entry, dict) and is_platform_asset(entry.get("asset", ""))


def num(v):
    """A number as the ids write it: "12" for 12.0, "13.5" for 13.5 (short_platforms.gd num)."""
    v = float(v)
    return str(int(round(v))) if abs(v - round(v)) < 1e-9 else repr(v)


def id_of(entry):
    return "building@%s,%s" % (num(entry["x"]), num(entry["y"]))


def building_art():
    if not _ART:
        try:
            _ART.update(json.loads(BUILDING_ART.read_text(encoding="utf-8")))
        except (OSError, ValueError):
            pass
    return _ART


# ---- building_towers.gd make_plan's short slots, mirrored ----------------------------------------------------

M32 = 0xFFFFFFFF


def hash_of(block_x, block_y):
    h = ((block_x * 73856093) ^ (block_y * 83492791)) & M32
    h = (h * 0x2C1B3C6D) & M32
    h ^= h >> 12
    h = (h * 0x297A2D39) & M32
    h ^= h >> 15
    return h


def short_slots(block_x, block_y):
    """[(si, sj)] of a block's short buildings (building_towers.gd short_slots)."""
    h = hash_of(block_x + 7919, block_y + 104729)
    out = []
    if h % 100 < 50:
        out.append((1, 1))
    if (h >> 8) % 100 < 40:
        out.append((1, 0) if (h >> 16) % 2 == 0 else (0, 1))
    return out


def _round(v):
    """GDScript's roundi: halves away from zero."""
    return int(math.floor(abs(v) + 0.5)) * (1 if v >= 0 else -1)


def block_slots(x, y):
    """[{si, sj, short, rect (x0, y0, x1, y1) of the tower, slot (x0, y0, x1, y1)}] of a whole block at (x, y)."""
    art = building_art()
    if not art:
        return []
    slot, foot, margin = float(art["slot_units"]), float(art["foot_units"]), float(art["margin_units"])
    shorts = short_slots(_round(x), _round(y))
    out = []
    for sj in range(2):
        for si in range(2):
            ox, oy = x + si * slot, y + sj * slot
            out.append({"si": si, "sj": sj, "short": (si, sj) in shorts,
                        "rect": (ox + margin, oy + margin, ox + margin + foot, oy + margin + foot),
                        "slot": (ox, oy, ox + slot, oy + slot)})
    return out


def is_block(entry):
    """A whole block of four: no asset, 2 x 2 slots of the building art's slot size (30 x 30)."""
    art = building_art()
    if entry.get("asset") or not art:
        return False
    side = 2.0 * float(art["slot_units"])
    try:
        return abs(float(entry["w"]) - side) < 1e-6 and abs(float(entry["h"]) - side) < 1e-6
    except (KeyError, TypeError, ValueError):
        return False


def applies_to_blocks(data):
    return isinstance(data, dict) and "platforms" in data


def platforms_of(data):
    """The platforms the level's short buildings make: [{id, x, y, w, h, height, short: True, building: index}]."""
    out = []
    if not isinstance(data, dict):
        return out
    blocks = applies_to_blocks(data)
    for i, b in enumerate(data.get("buildings", []) or []):
        if not isinstance(b, dict):
            continue
        try:
            x, y, w, h = (float(b[k]) for k in ("x", "y", "w", "h"))
        except (KeyError, TypeError, ValueError):
            continue
        if is_platform_entry(b):
            out.append({"id": id_of(b), "x": x, "y": y, "w": w, "h": h, "height": HEIGHT, "short": True, "building": i})
        elif blocks and is_block(b):
            for s in block_slots(x, y):
                if s["short"]:
                    r = s["rect"]
                    out.append({"id": "%s/%d,%d" % (id_of(b).replace("building@", "block@"), s["si"], s["sj"]),
                                "x": r[0], "y": r[1], "w": r[2] - r[0], "h": r[3] - r[1], "height": HEIGHT,
                                "short": True, "building": i})
    return out
