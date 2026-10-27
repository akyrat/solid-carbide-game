class_name ObstaclePairs
extends RefCounted
## Pairs of obstacles for the thread the needle trick (task T-272; Level design, Decisions, "Thread
## the needle"). A level file's "pairs" list, written by the level creator, holds
## [{id: "pair-N", a: <ref>, b: <ref>}], each ref naming one obstacle of the level:
## - a boulder: its pattern copy's id ("boulder-3", the creator's one-boulder copies), or
##   "<copy id>/<index>" for a copy holding several boulders (index from 0; the game's own map);
## - a prop: its id ("prop-2"), when the prop is an obstacle (OBSTACLES_GROUP below).
## The run reads the pairs through here (thread_the_needle.gd), the creator writes them
## (level_document.gd), and game/tools/check_level.py checks them by the same rules.
##
## Which pieces are obstacles: the boulders and the props of the panel's Obstacles group (the
## catalogue's families in group "obstacles", data/level/creator_assets.json: barrier, cones and
## crates), the pieces the car crashes into and that cut the combo, as the board listed them.

const CATALOGUE_PATH := "res://data/level/creator_assets.json"
const OBSTACLES_GROUP := "obstacles"

static var _obstacle_props: Array = []


## The prop catalogue ids that are obstacles (the Obstacles group's props).
static func obstacle_props() -> Array:
	if _obstacle_props.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE_PATH))
		var out: Array = []
		if d is Dictionary:
			for f in d.get("families", []):
				if str(f.get("group", "")) != OBSTACLES_GROUP:
					continue
				for m in f.get("members", []):
					var a := str(m.get("asset", ""))
					if a.begins_with("prop-") and not a in out:
						out.append(a)
		_obstacle_props = out
	return _obstacle_props


## The layout's pairs (a level's data), [] when it has none.
static func pairs_of(layout: Dictionary) -> Array:
	var l = layout.get("pairs", [])
	return l if l is Array else []


## The ref naming boulder `index` of pattern copy `copy`: the copy's id when it holds one boulder.
static func boulder_ref(copy: Dictionary, index: int) -> String:
	var bs: Array = copy.get("boulders", [])
	if bs.size() == 1 and index == 0:
		return str(copy.get("id", ""))
	return "%s/%d" % [str(copy.get("id", "")), index]


## The obstacle `ref` names in `layout`: {kind: "boulder", copy, index, item} or {kind: "prop", item},
## with its collision, shape "circle" (centre, radius) or "rect" (rect), in units. {} when the ref
## names nothing, or a prop that is not an obstacle.
static func resolve(layout: Dictionary, ref: String) -> Dictionary:
	if ref == "":
		return {}
	var copy_id := ref
	var index := -1
	var slash := ref.rfind("/")
	if slash > 0 and ref.substr(slash + 1).is_valid_int():
		copy_id = ref.substr(0, slash)
		index = int(ref.substr(slash + 1))
	var copies = layout.get("pattern_copies", [])
	for copy in (copies if copies is Array else []):
		if not (copy is Dictionary) or str(copy.get("id", "")) != copy_id:
			continue
		var bs: Array = copy.get("boulders", [])
		if index < 0:
			if bs.size() != 1:
				return {}
			index = 0
		if index >= bs.size():
			return {}
		var b: Dictionary = bs[index]
		return {"kind": "boulder", "copy": copy, "index": index, "item": b, "shape": "circle",
			"centre": Vector2(float(b.x), float(b.y)), "radius": float(b.diameter) / 2.0}
	if index >= 0:
		return {}
	for it in LevelProps.items_of(layout):
		if it is Dictionary and str(it.get("id", "")) == ref:
			if not str(it.get("asset", "")) in obstacle_props():
				return {}
			var out := {"kind": "prop", "item": it}
			out.merge(LevelProps.collision_of(it))
			return out
	return {}


## The obstacle's centre (units): a boulder's or round prop's middle, a rectangle's centre.
static func centre_of(obstacle: Dictionary) -> Vector2:
	if str(obstacle.get("shape", "")) == "circle":
		return obstacle.centre
	return (obstacle.rect as Rect2).get_center()


## Where the line from the obstacle's centre towards `towards` leaves the obstacle (units).
static func edge_towards(obstacle: Dictionary, towards: Vector2) -> Vector2:
	var c := centre_of(obstacle)
	var d := towards - c
	if d.length() < 0.000001:
		return c
	var dir := d.normalized()
	if str(obstacle.get("shape", "")) == "circle":
		return c + dir * minf(float(obstacle.radius), d.length())
	var half: Vector2 = (obstacle.rect as Rect2).size / 2.0
	var t := INF
	if absf(dir.x) > 0.000001:
		t = minf(t, half.x / absf(dir.x))
	if absf(dir.y) > 0.000001:
		t = minf(t, half.y / absf(dir.y))
	return c + dir * minf(t, d.length())


## A pair's line in units: {a, b} the two obstacles' centres (the line the car crosses), and
## {gap_a, gap_b} the part of it between the two obstacles (its drawing). {} when either ref
## names nothing.
static func line_of(layout: Dictionary, pair: Dictionary) -> Dictionary:
	var oa := resolve(layout, str(pair.get("a", "")))
	var ob := resolve(layout, str(pair.get("b", "")))
	if oa.is_empty() or ob.is_empty():
		return {}
	var a := centre_of(oa)
	var b := centre_of(ob)
	return {"a": a, "b": b, "gap_a": edge_towards(oa, b), "gap_b": edge_towards(ob, a),
		"obstacle_a": oa, "obstacle_b": ob}


## True when a move from `from` to `to` crosses the segment `a`-`b` (touching an end counts).
static func crosses(from: Vector2, to: Vector2, a: Vector2, b: Vector2) -> bool:
	if from.is_equal_approx(to):
		return false
	return Geometry2D.segment_intersects_segment(from, to, a, b) != null
