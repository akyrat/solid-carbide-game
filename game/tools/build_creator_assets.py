"""Builds the level creator's catalogue of placeable assets (task T-232).

Reads the art data already in the game (no art is made or changed):
  art/buildings/skyscrapers.json  skyscrapers, short buildings, their pavements
  art/boulders/boulders.json      boulders and their mirrored looks
  art/ground/ground_atlas.json    ground and road tiles (one atlas), road_tile.png
  art/elevation_sample/*.json     rooftops and ramps (sizes from data/level/elevation_sample_map.json)
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
    # T-252: the road pieces (the atlas tiles marked "piece") come first among the roads.
    pieces = {t["name"] for t in atlas["tiles"] if t.get("piece")}
    out.sort(key=lambda e: 0 if e["textures"][0]["variant"] in pieces else 1)
    out.append({"id": "road-road_tile", "kind": "road", "footprint_units": [GROUND_CELL, GROUND_CELL],
                "views": ["iso"], "mirrors": [False],
                "textures": [{"view": "iso", "mirror": False, "variant": "road_tile",
                              "texture": "res://art/ground/" + road_tile["file"]}]})
    return out


def elevation_entries(sample_map):
    platforms = {p["id"]: p for p in sample_map["platforms"]}
    ramps = {r["id"]: r for r in sample_map["ramps"]}
    out = []
    for h in (3, 6):
        views, textures, size = [], [], None
        for view in ("nw", "se"):
            p = platforms["roof-%s-%d" % (view, h)]
            s = [float(p["w"]), float(p["h"])]
            if size is not None and s != size:
                raise SystemExit("rooftop %d: nw and se sizes differ" % h)
            size = s
            views.append(view)
            textures.append({"view": view, "mirror": False, "variant": p["id"],
                             "texture": "res://" + SAMPLE_DIR + p["id"] + ".png"})
        out.append({"id": "rooftop-%d" % h, "kind": "rooftop", "footprint_units": size, "height": h,
                    "views": views, "mirrors": [False], "textures": textures})
    for lo, hi in ((0, 3), (3, 6)):
        views, textures, size = [], [], None
        for view in ("nw", "se"):
            r = ramps["ramp-%s-%d-%d" % (view, lo, hi)]
            if float(r["bottom_height"]) != lo or float(r["top_height"]) != hi:
                raise SystemExit("ramp %s heights do not match its name" % r["id"])
            s = [float(r["w"]), float(r["h"])]
            if size is not None and s != size:
                raise SystemExit("ramp %d-%d: nw and se sizes differ" % (lo, hi))
            size = s
            views.append(view)
            textures.append({"view": view, "mirror": False, "variant": r["id"], "side": r["side"],
                             "texture": "res://" + SAMPLE_DIR + r["id"] + ".png"})
        out.append({"id": "ramp-%d-%d" % (lo, hi), "kind": "ramp", "footprint_units": size,
                    "heights": [lo, hi], "views": views, "mirrors": [False], "textures": textures})
    return out


def build():
    sky = load("art/buildings/skyscrapers.json")
    entries = []
    entries += ground_entries(load("art/ground/ground_atlas.json"), load("art/ground/road_tile.json"))
    entries += building_entries(sky)
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
