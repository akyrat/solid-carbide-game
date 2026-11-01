"""Builds the level creator's catalogue of placeable assets (task T-232).

Reads the art data already in the game (no art is made or changed):
  art/buildings/skyscrapers.json  skyscrapers, short buildings, their pavements
  art/boulders/boulders.json      boulders and their mirrored looks
  art/ground/ground_atlas.json    ground and road tiles (one atlas), road_tile.png
  data/level/props.json           props (T-253: footprints, rotations, sprites)
  art/creator_pieces/             rooftops and ramps of any size (T-251; default sizes from data/level/elevation_sample_map.json)
and writes data/level/creator_assets.json, one entry per placeable asset:
  id, kind (ground, road, building, boulder, rooftop, ramp), footprint_units [w, h],
  views, mirrors (false = the art as made, true = a mirrored look the art has),
  textures [{view, mirror, variant, texture, ...}], and for rooftops "height",
  for ramps "heights" [bottom, top].
Since T-262 it also writes "groups" and "families": the side panel's one button per kind of piece,
each family listing its members (family_entries; see "Families" below).
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


def platform_art(entries, record):
    """T-405: the short buildings (short-N, building-small, building-long) are platforms 3 units high: each of
    their textures shows its platform art (game/art/buildings/platforms/, build_short_platform_art.py) with its
    own anchor, so the panel's button and the editor's preview show what is placed. A texture without platform
    art is left as it is."""
    textures = record.get("textures", {}) if record else {}
    for e in entries:
        eid = e["id"]
        if not (eid.startswith("short-") or eid in ("building-small", "building-long")):
            continue
        e["height_units"] = float(record.get("height_units", 3)) if record else e["height_units"]
        for t in e["textures"]:
            art = textures.get(t["texture"])
            if art:
                t["texture"] = art["full"]
                t["footprint_units"] = list(art["footprint_units"])
                t["anchor_art_px"] = list(art["anchor_art_px"])
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
        e = {"id": "%s-%s" % (kind, name), "kind": kind,
             "footprint_units": [GROUND_CELL, GROUND_CELL], "views": ["iso"], "mirrors": [False],
             "atlas_index": t["index"],
             "textures": [{"view": "iso", "mirror": False, "variant": name, "texture": path,
                           "region": [t["atlas_xy"][0], t["atlas_xy"][1], tw, th]}]}
        if t.get("piece"):
            e["part"] = True  # one tile of a road piece: placed only through the piece, not in the panel
        out.append(e)
    # T-252: the road pieces (2 x 2 tiles each, one entry per rotation) come first among the roads.
    pieces = []
    for p in atlas.get("pieces", []):
        parts = [{"dx": c * GROUND_CELL, "dy": r * GROUND_CELL, "tile": "road-" + p["tiles"][r][c]}
                 for r in range(2) for c in range(2)]
        w, h = p["sheet_size"]
        pieces.append({"id": "road-" + p["name"], "kind": "road", "footprint_units": [2 * GROUND_CELL] * 2,
                       "views": ["iso"], "mirrors": [False], "arms": p["arms"], "parts": parts,
                       "textures": [{"view": "iso", "mirror": False, "variant": p["name"],
                                     "texture": "res://art/ground/" + p["sheet"],
                                     "region": [p["sheet_xy"][0], p["sheet_xy"][1], w, h]}]})
    out = pieces + out
    out.append({"id": "road-road_tile", "kind": "road", "footprint_units": [GROUND_CELL, GROUND_CELL],
                "views": ["iso"], "mirrors": [False],
                "textures": [{"view": "iso", "mirror": False, "variant": "road_tile",
                              "texture": "res://art/ground/" + road_tile["file"]}]})
    return out


def sidewalk_entries(sheet):
    """T-398: one ground entry per sidewalk curb piece (art/ground/sidewalk_tiles.json, built by
    build_street_pieces.py). Not in the ground atlas: the run draws each from the sheet's region (a ground
    layout's "extra", LevelGround). "sidewalk" names its curbs: {edges, corners}."""
    out = []
    for t in sheet["tiles"]:
        out.append({"id": t["name"], "kind": "ground", "footprint_units": [GROUND_CELL, GROUND_CELL],
                    "views": ["iso"], "mirrors": [False],
                    "sidewalk": {"edges": t["edges"], "corners": list(t["corners"])},
                    **({} if t["name"] == "sidewalk" else {"part": True}),
                    "textures": [{"view": "iso", "mirror": False, "variant": t["name"], "texture": sheet["file"],
                                  "region": list(t["region"])}]})
    return out


def crater_entries(craters):
    """T-398: the meteor craters (data/level/craters.json): ground decals placed on the street, kind
    "crater"; the car drives over them."""
    return [{"id": c["id"], "kind": "crater", "footprint_units": [float(v) for v in c["footprint_units"]],
             "label": c["label"], "views": ["iso"], "mirrors": [False],
             "textures": [{"view": "iso", "mirror": False, "variant": "", "texture": c["texture"]}]}
            for c in craters["craters"]]


# T-441 (Level design, Decisions, "Kaiju alert signs are level creator pieces"): the kaiju alert signs
# with T-130's art (art/banners/, build_kaiju_banners.py), in both designs. The standing sign stands on a
# 2 x 2 cell (its post on the middle), mirrored with M; the banner hangs on a skyscraper's south (+y) or
# east (+x) wall (its views, turned with R), its bottom at one of BANNER_HEIGHTS (units above the ground,
# stepped with H; T-130's banners hung at 3). Proposals for the board's playtest. Geometry and drawing:
# scripts/level/kaiju_signs.gd.
ALERT_DESIGNS = [("head", "triangle"), ("body", "circle")]
ALERT_SIGN_CELL = 2.0
BANNER_WALLS = ["south", "east"]
BANNER_HEIGHTS = [3, 6, 9, 12, 15]
BANNER_ART_DIR = "res://art/banners/"


def alert_entries():
    """T-441: one entry per kind and design, kind "alert" ("alert": sign or banner, "design")."""
    out = []
    for design, shape in ALERT_DESIGNS:
        tex = "%skaiju_%s_%s_sign.png" % (BANNER_ART_DIR, design, shape)
        out.append({"id": "alert-sign-" + design, "kind": "alert", "alert": "sign", "design": design,
                    "label": "piece_alert_sign", "footprint_units": [ALERT_SIGN_CELL, ALERT_SIGN_CELL],
                    "views": ["iso"], "mirrors": [False, True],
                    "textures": [{"view": "iso", "mirror": m, "variant": "", "texture": tex} for m in (False, True)]})
    for design, shape in ALERT_DESIGNS:
        tex = "%skaiju_%s_%s_building_wall.png" % (BANNER_ART_DIR, design, shape)
        out.append({"id": "alert-banner-" + design, "kind": "alert", "alert": "banner", "design": design,
                    "label": "piece_alert_banner", "footprint_units": [3.0, 1.0],
                    "heights_units": list(BANNER_HEIGHTS), "views": list(BANNER_WALLS), "mirrors": [False],
                    # One pose per wall and height (the variant names the height), so each is one member.
                    "textures": [{"view": w, "mirror": False, "variant": str(h), "texture": tex}
                                 for w in BANNER_WALLS for h in BANNER_HEIGHTS]})
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
# T-400 (Level design, Decisions, "A small jump ramp"; proposals for the board's playtest): a small
# jump ramp one tile (4 units, a third of a 12-unit ramp) long, rising 2 units from what it stands
# on: the street (0 to 2) or a rooftop at 3 (3 to 5) or 6 (6 to 8). It climbs to no rooftop
# ("jump": its tall end is open, the car flies off it), in the same four directions and widths.
SMALL_RAMPS = [(0, 2), (3, 5), (6, 8)]
SMALL_RAMP_LENGTH = 4.0


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
    for lo, hi in SMALL_RAMPS:
        eid = "ramp-%d-%d" % (lo, hi)
        out.append({"id": eid, "kind": "ramp", "footprint_units": [RAMP_WIDTH, SMALL_RAMP_LENGTH],
                    "heights": [lo, hi], "jump": True, "resizable": True, "length_units": SMALL_RAMP_LENGTH,
                    "width_units": RAMP_WIDTH, "min_width_units": MIN_RAMP_WIDTH, "style": PIECE_STYLE,
                    "views": [d for d, _ in RAMP_DIRECTIONS], "mirrors": [False],
                    "textures": [{"view": d, "mirror": False, "variant": "", "side": s,
                                  "texture": piece_icon(eid)} for d, s in RAMP_DIRECTIONS]})
    return out


def prop_entries(props):
    """T-253: the props of data/level/props.json (footprint, rotations and their sprites live there:
    T-256 swaps the art in that file). One entry each, kind "prop", the four rotations as its views; a
    view's texture is that rotation's sprite. footprint_units is the one facing north (east and west
    swap its two numbers)."""
    out = []
    for p in props["props"]:
        out.append({"id": p["id"], "kind": "prop", "footprint_units": [float(v) for v in p["footprint_units"]],
                    "height_units": float(p["height_units"]), "label": p["label"],
                    "views": list(props["rotations"]), "mirrors": [False],
                    "textures": [{"view": r, "mirror": False, "variant": "", "texture": p["textures"][r]["texture"]}
                                 for r in props["rotations"]]})
    return out


# ---- Families (T-262) ----------------------------------------------------------------------------
# The side panel shows one button per family (a kind of piece), in six groups from the ground up
# (Level design, Decisions, "Level creator rework"). A family lists its members: each is one way to
# place a catalogue entry (an asset in one of its views and mirrors, and for a skyscraper one of its
# two bodies), tagged with the family's look, turn, mirror and height, which the creator steps with
# the keys V, R, M and H (editor.gd KEY_ACTIONS; creator_families.gd). A member places exactly what
# the old panel's button placed, so saved levels are unchanged. New art adds members (looks) here,
# not buttons. This is the one place that says which entry belongs where.
GROUPS = ["roads", "ground", "levels", "buildings", "obstacles", "decoration"]

# The road families are brushes (T-263; scripts/level_creator/road_brush.gd): Road, Centre line and
# Cracked road paint whole two-tile-wide roads along a drag ("brush": "paint"), and the brush
# picks every tile itself (straights, corners, T-junctions, crossroads, dead ends); Zebra crossing
# is clicked across a painted road ("brush": "zebra") and takes that road's asphalt. A look is an
# asphalt (ground_atlas.json names end in one of these; the member's "asphalt"); a0m is a0
# mirrored left-right, so it is a0's mirror (M). Proposals: the visibly cracked PixelLab asphalts
# (g4, g5, g7) are Cracked road; the plainer ones (a0, g6, g9) are Road and Centre line. A member's
# asset is that asphalt's straight tile along y, the button's and the strip's picture. The single
# road tiles are no longer in the panel (they stay in the catalogue, so earlier levels draw).
ROAD_PLAIN_LOOKS = ["a0", "g6", "g9"]
ROAD_LINE_LOOKS = ["a0", "g6", "g9"]
ROAD_CRACKED_LOOKS = ["g4", "g5", "g7"]
# Family id -> (text key, the straight tile kind its pictures show, its asphalt looks).
ROAD_BRUSHES = [
    ("road", "piece_road", "plain", ROAD_PLAIN_LOOKS),
    ("centre-line", "piece_centre_line", "line_r", ROAD_LINE_LOOKS),
    ("cracked-road", "piece_cracked_road", "plain", ROAD_CRACKED_LOOKS),
]
# Family id -> (group, text key, the catalogue ids in look order) for the families whose members
# are an entry's own views and mirrors.
SIMPLE_FAMILIES = [
    ("gravel", "ground", "piece_gravel", ["ground-gravel0", "ground-gravel1", "ground-gravel2"]),
    ("building-small", "buildings", "piece_building_small", ["building-small"]),
    ("building-long", "buildings", "piece_building_long", ["building-long"]),
    ("lowrise", "buildings", "piece_building_lowrise", ["short-0", "short-1", "short-2", "short-3"]),
    ("boulder", "obstacles", "piece_boulder", ["boulder-a", "boulder-b"]),
    ("barrier", "obstacles", "piece_barrier", ["prop-barrier"]),
    ("cones", "obstacles", "piece_cones", ["prop-cones"]),
    ("crates", "obstacles", "piece_crates", ["prop-crates"]),
    # T-398: the parked and broken cars, each model a look (V), the four facings its turns (R).
    ("parked-car", "obstacles", "piece_parked_car", ["prop-parked-car-1", "prop-parked-car-2", "prop-parked-car-3"]),
    ("broken-car", "obstacles", "piece_broken_car", ["prop-broken-car-1", "prop-broken-car-2"]),
    ("meteor-crater", "ground", "piece_meteor_crater", ["crater-1", "crater-2", "crater-3"]),
    ("street-lamp", "decoration", "piece_street_lamp", ["prop-street-lamp"]),
    ("ac-unit", "decoration", "piece_ac_unit", ["prop-ac-unit"]),
    ("water-tank", "decoration", "piece_water_tank", ["prop-water-tank"]),
    ("roof-vent", "decoration", "piece_roof_vent", ["prop-roof-vent"]),
    ("roof-sign", "decoration", "piece_roof_sign", ["prop-roof-sign"]),
    # T-441: the standing kaiju alert sign, its two designs the looks (V), its mirror M.
    ("alert-sign", "decoration", "piece_alert_sign", ["alert-sign-head", "alert-sign-body"]),
]
# T-398: the families whose looks strip counts models ("Model {n} of {count}", model_counter, T-396)
# and whose turns the top bar names as facings (facing_*, T-396).
MODEL_FAMILIES = ["parked-car", "broken-car", "meteor-crater"]
FACING_FAMILIES = ["parked-car", "broken-car"]
# Families stepped by height (H): the entry for each height, in order.
HEIGHT_FAMILIES = [
    ("platform", "levels", "piece_platform", [("3", "rooftop-3"), ("6", "rooftop-6")]),
    ("ramp", "levels", "piece_ramp", [("0-3", "ramp-0-3"), ("3-6", "ramp-3-6"), ("0-6", "ramp-0-6"),
                                         ("0-2", "ramp-0-2"), ("3-5", "ramp-3-5"), ("6-8", "ramp-6-8")]),
]
# The panel's order: by group, buildings smallest to tallest.
FAMILY_ORDER = ["road", "centre-line", "zebra-crossing", "cracked-road", "gravel", "sidewalk", "meteor-crater",
                "platform", "ramp", "building-small", "building-long", "lowrise", "skyscraper", "boulder", "barrier",
                "cones", "crates", "parked-car", "broken-car", "street-lamp", "ac-unit", "water-tank", "roof-vent", "roof-sign",
                "alert-sign", "alert-banner"]
# T-441: the alert families' looks strip names each design (creator_texts.json, T-440); the banner's strip
# also shows the hints for its wall (R) and height (H).
ALERT_LOOK_LABELS = ["alert_design_head", "alert_design_body"]
ALERT_BANNER_HINTS = ["banner_wall_hint", "banner_height_hint"]
# Pavement (piece_pavement) is left out: the only pavement art is the 30-unit block pavements drawn
# under buildings (cityB_pavement_*.png, 960 x 486 px), not a 2 x 2 unit ground tile.


def member(asset, view, mirror, look, turn, height="", variant="", flip=None):
    """asset, view, mirror, variant: what is placed (the old panel's pose). look, turn, flip, height:
    where it sits in its family (the keys V, R, M, H step them); flip is the asset's mirror unless
    the mirrored look is an entry of its own (a road tile's a0m)."""
    return {"asset": asset, "view": view, "mirror": mirror, "variant": variant,
            "look": look, "turn": turn, "flip": mirror if flip is None else flip, "height": height}


def entry_members(e, look, height=""):
    """One member per (view, mirror) the entry's art has: turn = the view's place in its views."""
    out = []
    for ti, view in enumerate(e["views"]):
        for mirror in e["mirrors"]:
            if any(t["view"] == view and t["mirror"] == mirror for t in e["textures"]):
                out.append(member(e["id"], view, mirror, look, ti, height))
    return out


def summarise(fid, group, label, members):
    def values(key):
        seen = []
        for m in members:
            if m[key] not in seen:
                seen.append(m[key])
        return seen
    return {"id": fid, "group": group, "label": label, "looks": len(values("look")),
            "turns": len(values("turn")), "mirrors": values("flip"),
            "heights": [h for h in values("height") if h != ""], "members": members}


def brush_members(by_id, tile_kind, asphalts):
    """A road brush's looks: one per asphalt (its straight tile along y as the picture), and a0's
    mirror a0m. Each member names its asphalt."""
    out = []
    for look, a in enumerate(asphalts):
        for flip, suffix in ((False, a), (True, a + "m")):
            aid = "road-y_%s_%s" % (tile_kind, suffix)
            if aid in by_id:
                m = member(aid, "iso", False, look, 0, flip=flip)
                m["asphalt"] = suffix
                out.append(m)
    return out


def brush_family(fid, label, brush, members):
    f = summarise(fid, "roads", label, members)
    f["brush"] = brush
    return f


def family_entries(entries):
    by_id = {e["id"]: e for e in entries}
    fams = []
    for fid, label, tile_kind, asphalts in ROAD_BRUSHES:
        fams.append(brush_family(fid, label, "paint", brush_members(by_id, tile_kind, asphalts)))
    zebra = member("road-y_zebra_a0", "iso", False, 0, 0)
    fams.append(brush_family("zebra-crossing", "piece_zebra_crossing", "zebra", [zebra]))
    for fid, group, label, pairs in HEIGHT_FAMILIES:
        ms = []
        for height, aid in pairs:
            ms += entry_members(by_id[aid], 0, height)
        fams.append(summarise(fid, group, label, ms))
    # Skyscrapers: each tower's two bodies are two looks (building_towers.gd single_of: look = body).
    ms = []
    look = 0
    for e in entries:
        if e["kind"] == "building" and e["id"].startswith("skyscraper-"):
            for t in e["textures"]:
                ms.append(member(e["id"], t["view"], t["mirror"], look, 0, variant=t["variant"]))
                look += 1
    fams.append(summarise("skyscraper", "buildings", "piece_building_skyscraper", ms))
    for fid, group, label, ids in SIMPLE_FAMILIES:
        ms = []
        for look, aid in enumerate(ids):
            ms += entry_members(by_id[aid], look)
        fams.append(summarise(fid, group, label, ms))
    # T-398: the sidewalk is a brush ("sidewalk", scripts/level_creator/sidewalk_brush.gd): painted cell by
    # cell, its curbs picked by the editor. Its picture is the plain tile.
    if "sidewalk" in by_id:
        sw = summarise("sidewalk", "ground", "piece_sidewalk", [member("sidewalk", "iso", False, 0, 0)])
        sw["brush"] = "sidewalk"
        fams.append(sw)
    # T-441: the alert banner: each design a look (V), each wall a turn (R), each height a height (H).
    ms = []
    for look, (design, _shape) in enumerate(ALERT_DESIGNS):
        e = by_id.get("alert-banner-" + design)
        if e is None:
            continue
        for turn, wall in enumerate(e["views"]):
            for h in e["heights_units"]:
                ms.append(member(e["id"], wall, False, look, turn, height=str(h), variant=str(h)))
    if ms:
        fams.append(summarise("alert-banner", "decoration", "piece_alert_banner", ms))
    for f in fams:
        if f["id"] in ("alert-sign", "alert-banner"):
            f["look_labels"] = list(ALERT_LOOK_LABELS)
        if f["id"] == "alert-banner":
            f["hints"] = list(ALERT_BANNER_HINTS)
        if f["id"] in MODEL_FAMILIES:
            f["counter"] = "model_counter"
        if f["id"] in FACING_FAMILIES:
            f["facing_labels"] = True
    fams.sort(key=lambda f: FAMILY_ORDER.index(f["id"]))
    return fams


def build():
    sky = load("art/buildings/skyscrapers.json")
    entries = []
    entries += ground_entries(load("art/ground/ground_atlas.json"), load("art/ground/road_tile.json"))
    entries += building_entries(sky)
    entries += piece_building_entries(load("data/level/creator_buildings.json"))
    platform_art(entries, load("art/buildings/platforms/platforms.json")
                 if os.path.isfile(os.path.join(GAME, "art/buildings/platforms/platforms.json")) else {})
    entries += boulder_entries(load("art/boulders/boulders.json"))
    entries += elevation_entries(load("data/level/elevation_sample_map.json"))
    entries += prop_entries(load("data/level/props.json"))
    entries += sidewalk_entries(load("art/ground/sidewalk_tiles.json"))
    entries += crater_entries(load("data/level/craters.json"))
    entries += alert_entries()
    return {
        "about": "T-232: every placeable asset already in the game, built by game/tools/build_creator_assets.py "
                 "from the art data. Do not edit by hand; rebuild with the script.",
        "building_pavements": list(sky["pavements"]),
        "entries": entries,
        "groups": list(GROUPS),
        "families": family_entries(entries),
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
