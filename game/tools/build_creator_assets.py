"""Builds the level creator's catalogue of placeable assets (task T-232).

Reads the art data already in the game (no art is made or changed):
  art/buildings/skyscrapers.json  skyscrapers, short buildings, their pavements
  art/boulders/boulders.json      boulders and their mirrored looks
  art/ground/ground_atlas.json    ground and road tiles (one atlas), road_tile.png
  art/creator_pieces/             rooftops and ramps of any size (T-251; default sizes from data/level/elevation_sample_map.json)
and writes data/level/creator_assets.json, one entry per placeable asset:
  id, kind (ground, road, building, boulder, rooftop, ramp), footprint_units [w, h],
  views, mirrors (false = the art as made, true = a mirrored look the art has),
  textures [{view, mirror, variant, texture, ...}], and for rooftops "height",
  for ramps "heights" [bottom, top].
The textures are exactly the ones the run draws: mvp_map.gd (ground atlas, boulder
variants, building_towers.gd bodies / short bodies / pavements) and
elevation_platform_drawing.gd (art_dir + the area's id + ".png").

Run from the repo root: python game/tools/build_creator_assets.py
Running it twice gives the same file (no timestamps, sorted keys per entry order fixed).
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)
OUT = os.path.join(GAME, "data", "level", "creator_assets.json")

BOULDER_DIAMETER = 3.0  # units, mvp_map.gd DEFAULT_BOULDER_DIAMETER and the map's boulders
GROUND_CELL = 2.0  # units, one atlas tile (mvp_ground.json cell_units)
SAMPLE_DIR = "art/elevation_sample/"


def load(rel):
    with open(os.path.join(GAME, rel), encoding="utf-8") as f:
        return json.load(f)


def res_exists(res_path):
    return os.path.isfile(os.path.join(GAME, res_path.replace("res://", "")))


def building_entries(sky):
    entries = []
    foot = float(sky["foot_units"])
    for t in range(1, int(sky["towers"]) + 1):
        textures = []
        for v in range(int(sky["variants_per_tower"])):
            textures.append({"view": "iso", "mirror": False, "variant": str(v),
                             "texture": sky["bodies"][(t - 1) * int(sky["variants_per_tower"]) + v]})
        entries.append({"id": "skyscraper-%d" % t, "kind": "building", "footprint_units": [foot, foot],
                        "height_units": float(sky["height_units"]), "views": ["iso"], "mirrors": [False],
                        "textures": textures})
    short = sky["short"]
    for d in range(int(short["designs"])):
        textures = []
        for look in (0, 1):
            # build_short_set.py: body index = design * 2 + look; look 1 is the mirrored, recoloured body.
            textures.append({"view": "iso", "mirror": look == 1, "variant": str(look),
                             "texture": short["bodies"][d * 2 + look]})
        entries.append({"id": "short-%d" % d, "kind": "building", "footprint_units": [foot, foot],
                        "height_units": float(short["height_units"]), "views": ["iso"], "mirrors": [False, True],
                        "textures": textures})
    return entries


def piece_building_entries(pieces):
    """T-254: the small and long buildings, from data/level/creator_buildings.json (their art per view and
    mirror, each texture with its own footprint and anchor). The entry's footprint is its first texture's."""
    out = []
    for p in pieces["pieces"]:
        textures = [dict(t) for t in p["textures"]]
        first = textures[0]["footprint_units"]
        out.append({"id": p["id"], "kind": "building", "footprint_units": [float(first[0]), float(first[1])],
                    "height_units": float(p["height_units"]), "views": list(p["views"]),
                    "mirrors": list(p["mirrors"]), "textures": textures})
    return out


def boulder_entries(boulders):
    by_base = {}
    for v in boulders["variants"]:
        vid = v["id"]
        mirror = vid.endswith("_mirror")
        base = vid[:-7] if mirror else vid
        by_base.setdefault(base, []).append({"view": "iso", "mirror": mirror, "variant": vid,
                                             "texture": v["texture"]})
    out = []
    for base in sorted(by_base):
        textures = sorted(by_base[base], key=lambda t: t["mirror"])
        out.append({"id": "boulder-" + base, "kind": "boulder",
                    "footprint_units": [BOULDER_DIAMETER, BOULDER_DIAMETER], "views": ["iso"],
                    "mirrors": sorted({t["mirror"] for t in textures}), "textures": textures})
    return out


def ground_entries(atlas, road_tile):
    out = []
    path = "res://art/ground/" + atlas["file"]
    tw, th = 128, 64
    for t in atlas["tiles"]:
        name = t["name"]
        kind = "ground" if name.startswith("gravel") else "road"
        out.append({"id": "%s-%s" % (kind, name), "kind": kind,
                    "footprint_units": [GROUND_CELL, GROUND_CELL], "views": ["iso"], "mirrors": [False],
                    "atlas_index": t["index"],
                    "textures": [{"view": "iso", "mirror": False, "variant": name, "texture": path,
                                  "region": [t["atlas_xy"][0], t["atlas_xy"][1], tw, th]}]})
    out.append({"id": "road-road_tile", "kind": "road", "footprint_units": [GROUND_CELL, GROUND_CELL],
                "views": ["iso"], "mirrors": [False],
                "textures": [{"view": "iso", "mirror": False, "variant": "road_tile",
                              "texture": "res://art/ground/" + road_tile["file"]}]})
    return out


PIECE_DIR = "art/creator_pieces/"
PIECE_STYLE = "res://" + PIECE_DIR + "piece_style.tres"
# T-251 (proposals for the board's playtest): a rooftop is dragged to any even size from
# MIN_ROOFTOP; a click without a drag places the sample map's size (84 x 30 at 3, 30 x 30 at 6).
# A ramp climbs north, east, south or west; its width along the rooftop's side is dragged (from
# MIN_RAMP_WIDTH, default RAMP_WIDTH, the sample map's 10) and its length is fixed: 12 units per
# 3 of rise (the sample map's slope), so 24 for a ramp 0 to 6.
MIN_ROOFTOP = [4.0, 4.0]
MIN_RAMP_WIDTH = 4.0
RAMP_WIDTH = 10.0
RAMP_LENGTH_PER_3 = 12.0
# The direction a ramp climbs (its view) -> the side of the rooftop it climbs (the height data's
# "side"): climbing north, it goes up the rooftop's south side.
RAMP_DIRECTIONS = [("north", "south"), ("east", "west"), ("south", "north"), ("west", "east")]


def piece_icon(entry_id):
    return "res://" + PIECE_DIR + "icon_" + entry_id.replace("-", "_") + ".png"


def elevation_entries(sample_map):
    """T-251: rooftops of any size at 3 and 6, ramps 0 to 3, 3 to 6 and 0 to 6 climbing in four
    directions, drawn in the engine from the piece style's textures (no art piece; T-232's fixed
    pieces of the sample map's art are gone from the catalogue, the map still draws them). Their
    texture is the panel's icon (build_creator_piece_art.py); "style" names what they are drawn
    with. A ramp's footprint is the one climbing north or south (width x length)."""
    platforms = {p["id"]: p for p in sample_map["platforms"]}
    out = []
    for h in (3, 6):
        p = platforms["roof-nw-%d" % h]
        eid = "rooftop-%d" % h
        out.append({"id": eid, "kind": "rooftop", "footprint_units": [float(p["w"]), float(p["h"])],
                    "height": h, "resizable": True, "min_size_units": list(MIN_ROOFTOP),
                    "style": PIECE_STYLE, "views": ["iso"], "mirrors": [False],
                    "textures": [{"view": "iso", "mirror": False, "variant": "", "texture": piece_icon(eid)}]})
    for lo, hi in ((0, 3), (3, 6), (0, 6)):
        eid = "ramp-%d-%d" % (lo, hi)
        length = RAMP_LENGTH_PER_3 * (hi - lo) / 3.0
        out.append({"id": eid, "kind": "ramp", "footprint_units": [RAMP_WIDTH, length],
                    "heights": [lo, hi], "resizable": True, "length_units": length,
                    "width_units": RAMP_WIDTH, "min_width_units": MIN_RAMP_WIDTH, "style": PIECE_STYLE,
                    "views": [d for d, _ in RAMP_DIRECTIONS], "mirrors": [False],
                    "textures": [{"view": d, "mirror": False, "variant": "", "side": s,
                                  "texture": piece_icon(eid)} for d, s in RAMP_DIRECTIONS]})
    return out


def build():
    sky = load("art/buildings/skyscrapers.json")
    entries = []
    entries += ground_entries(load("art/ground/ground_atlas.json"), load("art/ground/road_tile.json"))
    entries += building_entries(sky)
    entries += piece_building_entries(load("data/level/creator_buildings.json"))
    entries += boulder_entries(load("art/boulders/boulders.json"))
    entries += elevation_entries(load("data/level/elevation_sample_map.json"))
    return {
        "about": "T-232: every placeable asset already in the game, built by game/tools/build_creator_assets.py "
                 "from the art data. Do not edit by hand; rebuild with the script.",
        "building_pavements": list(sky["pavements"]),
        "entries": entries,
    }


def textures_of(catalogue):
    out = set(catalogue.get("building_pavements", []))
    for e in catalogue["entries"]:
        for t in e["textures"]:
            out.add(t["texture"])
    return out


def main():
    cat = build()
    missing = sorted(t for t in textures_of(cat) if not res_exists(t))
    if missing:
        print("Missing textures:", *missing, sep="\n  ")
        return 1
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(cat, f, indent=1)
        f.write("\n")
    print("Wrote %s: %d entries" % (os.path.relpath(OUT, os.path.dirname(GAME)), len(cat["entries"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
