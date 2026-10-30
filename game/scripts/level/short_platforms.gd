extends RefCounted
## Short buildings become platforms (task T-405; Level design, Decisions, "Short buildings become
## platforms", 2026-10-30): the low-rise ("short-N"), the small ("building-small") and the long
## ("building-long") buildings of a layout are no longer solid buildings but platforms at HEIGHT
## (3 units), with their own art cut to that height (art/buildings/platforms/, made by
## game/tools/build_short_platform_art.py). Only the skyscrapers stay solid, at any height.
##
## The level file is unchanged: a short building stays an entry of `buildings` ({x, y, w, h,
## asset, look}); this script is the one place that turns it into a platform. GroundHeight
## (ground_height.gd load_data) adds platforms_of(layout) after the file's own rooftops, so the car,
## the enemies' navigation, the elevation layer's drawing and depth order, the props' heights and
## the creator's ramps all see them as rooftops. mvp_map.gd builds walls only for wall_rects(layout).
##
## The game's own map (a layout with a "platforms" key and whole blocks of four, no "asset"): each
## short slot of a block (building_towers.gd make_plan) becomes a platform on its 12 x 12 tower
## footprint, and the block's walls are its skyscraper slots only (15 x 15 each, their pavement
## included); the short slot's pavement ring is street. A layout without "platforms" (the old MVP
## map, mvp_map.json, played without heights) keeps its whole blocks as they were.
##
## Mirrored in Python by game/tools/short_platforms.py (check_height_data.py, check_level.py).

const BuildingTowers := preload("res://scripts/level/building_towers.gd")

## The platforms' height, units (the board's answer, 2026-10-30).
const HEIGHT := 3.0
## The art record: per source texture, the four images and the anchor (build_short_platform_art.py).
const ART_RECORD_PATH := "res://art/buildings/platforms/platforms.json"
## The building art (the short bodies of the low-rise and the blocks' slot sizes).
const BUILDING_ART_PATH := "res://art/buildings/skyscrapers.json"

static var _record: Dictionary = {}
static var _building_art: Dictionary = {}


## True for a building that is a platform: "short-N", "building-small" or "building-long".
static func is_platform_asset(asset: String) -> bool:
	return asset.begins_with("short-") or asset == "building-small" or asset == "building-long"


static func is_platform_entry(entry: Dictionary) -> bool:
	return is_platform_asset(str(entry.get("asset", "")))


## True when the layout's whole blocks (entries with no asset) have their short slots turned into
## platforms: a layout in the elevation map's format (it has "platforms").
static func applies_to_blocks(layout: Dictionary) -> bool:
	return layout.has("platforms")


## A number as the ids write it: "12" for 12.0, "13.5" for 13.5.
static func num(v: float) -> String:
	return str(int(round(v))) if is_equal_approx(v, round(v)) else str(v)


## The platform id of a building entry, from where it stands (so it stays the same when other
## pieces are placed or deleted): "building@<x>,<y>".
static func id_of(entry: Dictionary) -> String:
	return "building@%s,%s" % [num(float(entry.x)), num(float(entry.y))]


static func building_art() -> Dictionary:
	if _building_art.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(BUILDING_ART_PATH))
		_building_art = d if d is Dictionary else {}
	return _building_art


static func art_record() -> Dictionary:
	if _record.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(ART_RECORD_PATH))
		_record = d if d is Dictionary else {}
	return _record


## The art of the source texture `res` as a platform: {full, clean, ns, ew (texture paths),
## anchor (Vector2, the art pixel on the footprint's front corner)}; {} when it has none.
static func art_of(res: String) -> Dictionary:
	var t = art_record().get("textures", {}).get(res, null)
	if not (t is Dictionary):
		return {}
	return {"full": str(t.full), "clean": str(t.clean), "ns": str(t.ns), "ew": str(t.ew),
		"anchor": Vector2(float(t.anchor_art_px[0]), float(t.anchor_art_px[1]))}


## The source texture (today's art) of a short building entry: the low-rise's short body, the
## small or long building's texture for its footprint and look; "" when unknown.
static func source_texture(entry: Dictionary) -> String:
	var asset := str(entry.get("asset", ""))
	var look := int(entry.get("look", 0))
	if asset.begins_with("short-") and asset.trim_prefix("short-").is_valid_int():
		var bodies: Array = building_art().get("short", {}).get("bodies", [])
		var i := 2 * int(asset.trim_prefix("short-")) + look
		return str(bodies[i]) if i >= 0 and i < bodies.size() else ""
	if asset == "building-small" or asset == "building-long":
		return str(BuildingTowers.piece_of(entry).get("texture", ""))
	return ""


## The short slots of a whole block (an entry with no asset) at `rect`: [{si, sj, rect (the
## tower's 12 x 12 footprint), slot (the 15 x 15 slot), body (short body index)}], and its
## skyscraper slots with "short": false. Empty without the building art.
static func block_slots(rect: Rect2) -> Array:
	var art := building_art()
	if art.is_empty():
		return []
	var slot := float(art.slot_units)
	var foot := float(art.foot_units)
	var margin := float(art.margin_units)
	var out: Array = []
	for e in BuildingTowers.make_plan(roundi(rect.position.x), roundi(rect.position.y)):
		var origin := rect.position + Vector2(e.si * slot, e.sj * slot)
		out.append({"si": e.si, "sj": e.sj, "short": bool(e.short),
			"rect": Rect2(origin + Vector2(margin, margin), Vector2(foot, foot)),
			"slot": Rect2(origin, Vector2(slot, slot)), "body": int(e.short_body)})
	return out


## The platforms the layout's short buildings make, in the height data's format
## ({id, x, y, w, h, height}) plus "short": true, "building" (the entry's index in `buildings`)
## and "texture" (its source art, art_of).
static func platforms_of(layout: Dictionary) -> Array:
	var out: Array = []
	var blocks := applies_to_blocks(layout)
	var bodies: Array = building_art().get("short", {}).get("bodies", [])
	var i := 0
	for b in layout.get("buildings", []):
		if not (b is Dictionary):
			i += 1
			continue
		if is_platform_entry(b):
			out.append({"id": id_of(b), "x": float(b.x), "y": float(b.y), "w": float(b.w), "h": float(b.h),
				"height": HEIGHT, "short": true, "building": i, "texture": source_texture(b)})
		elif blocks and is_block(b):
			for s in block_slots(Rect2(float(b.x), float(b.y), float(b.w), float(b.h))):
				if not s.short:
					continue
				var r: Rect2 = s.rect
				out.append({"id": "%s/%d,%d" % [id_of(b).replace("building@", "block@"), s.si, s.sj],
					"x": r.position.x, "y": r.position.y, "w": r.size.x, "h": r.size.y, "height": HEIGHT,
					"short": true, "building": i,
					"texture": str(bodies[s.body]) if s.body < bodies.size() else ""})
		i += 1
	return out


## The walls of the layout's buildings, solid at any height: [{rect, building (index), name}].
## A skyscraper (or any building that is not a platform) is one wall; a whole block is one wall,
## or with applies_to_blocks its skyscraper slots, one wall each; a short building none.
static func wall_rects(layout: Dictionary) -> Array:
	var out: Array = []
	var blocks := applies_to_blocks(layout)
	var i := 0
	for b in layout.get("buildings", []):
		var r := Rect2(float(b.x), float(b.y), float(b.w), float(b.h))
		var name := "Building%02d" % (i + 1)
		if is_platform_entry(b):
			pass
		elif blocks and is_block(b):
			for s in block_slots(r):
				if not s.short:
					out.append({"rect": s.slot, "building": i, "name": "%s_%d%d" % [name, s.si, s.sj]})
		else:
			out.append({"rect": r, "building": i, "name": name})
		i += 1
	return out


## True when the whole block entry `entry` of `layout` draws its short slots as platforms: a layout
## with heights, an entry with no asset, the size of a block of four slots (30 x 30).
static func block_short_slots_are_platforms(layout: Dictionary, entry: Dictionary) -> bool:
	return applies_to_blocks(layout) and is_block(entry)


## True for a whole block of four (no asset, 2 x 2 slots of the building art's slot size).
static func is_block(entry: Dictionary) -> bool:
	if str(entry.get("asset", "")) != "" or building_art().is_empty():
		return false
	var side := 2.0 * float(building_art().slot_units)
	return is_equal_approx(float(entry.get("w", 0)), side) and is_equal_approx(float(entry.get("h", 0)), side)
