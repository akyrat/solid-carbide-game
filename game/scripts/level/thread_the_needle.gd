class_name ThreadTheNeedle
extends RefCounted
## The thread the needle trick in a run (task T-272; Level design, Decisions, "Thread the needle"):
## driving through the gap between two obstacles the board paired in the level creator (the level
## file's "pairs", read through ObstaclePairs). The run scene makes one per map (run.gd), feeds it
## the car's position after every physics step (observe) and every crash (touched), and pays the
## trick through RunState.add_needle_trick when `threaded` fires.
##
## A pass: the car's centre crosses the line between the two obstacles' centres (only the gap part
## can be reached: the rest lies inside the obstacles). The rules are combo.json's
## "thread_the_needle" (ComboData.needle_rules; the numbers and their reasons are there):
## - a touch of either obstacle from touch_window_seconds before the crossing until clear_seconds
##   after it voids the pass (the crash cuts the combo as always, through the car's hit_obstacle);
## - the trick fires clear_seconds after the crossing, when no touch came;
## - the same pair pays again only once repeat_seconds have gone by since it last paid (either
##   direction);
## - with counts_in_air false, a crossing while the car is in the air does not count.
## A level without pairs (the game's own map) has no gates and nothing happens.

## Emitted once per paid pass, with the pair's id.
signal threaded(pair_id: String)

## One per pair whose two obstacles exist: {id, refs: [a, b], a, b (the line, units),
## last_touch, last_paid, pending (the crossing's time, -1 for none)}.
var gates: Array = []
var rules: Dictionary = {}
## Seconds since the run's map was built (the sum of observe's dt).
var time := 0.0
var last_position = null
var _layout: Dictionary = {}


func _init(layout: Dictionary = {}, needle_rules: Dictionary = {}) -> void:
	setup(layout, needle_rules)


## The gates of `layout`'s pairs, with `needle_rules` (ComboData.needle_rules(); its defaults when empty).
func setup(layout: Dictionary, needle_rules: Dictionary = {}) -> void:
	_layout = layout
	rules = needle_rules if not needle_rules.is_empty() else ComboData.new().needle_rules()
	gates = []
	time = 0.0
	last_position = null
	for p in ObstaclePairs.pairs_of(layout):
		var line := ObstaclePairs.line_of(layout, p)
		if line.is_empty():
			continue
		gates.append({"id": str(p.get("id", "")), "refs": [str(p.a), str(p.b)], "a": line.a, "b": line.b,
			"gap_a": line.gap_a, "gap_b": line.gap_b, "last_touch": -INF, "last_paid": -INF, "pending": -1.0})


## The car's centre is at `position` (units) after a step of `dt` seconds, `airborne` whether that
## step ended in the air. Returns the ids of the pairs paid on this step (each also `threaded`).
func observe(position: Vector2, airborne: bool, dt: float) -> Array:
	time += dt
	var paid: Array = []
	var from = last_position
	last_position = position
	for g in gates:
		if float(g.pending) >= 0.0 and time - float(g.pending) >= float(rules.clear_seconds) - 0.000001:
			g.pending = -1.0
			g.last_paid = time
			paid.append(str(g.id))
		if from == null or float(g.pending) >= 0.0:
			continue
		if not ObstaclePairs.crosses(from, position, g.a, g.b):
			continue
		if airborne and not bool(rules.counts_in_air):
			continue
		if time - float(g.last_paid) < float(rules.repeat_seconds) - 0.000001:
			continue
		if time - float(g.last_touch) <= float(rules.touch_window_seconds) + 0.000001:
			continue
		g.pending = time
		if float(rules.clear_seconds) <= 0.0:
			g.pending = -1.0
			g.last_paid = time
			paid.append(str(g.id))
	for id in paid:
		threaded.emit(id)
	return paid


## The car hit `collider` (its `hit_obstacle`): a touch of a paired obstacle voids a pass in progress
## and any crossing in the next touch_window_seconds.
func touched(collider: Object, shape_index: int) -> void:
	var ref := ref_of_body(collider, shape_index)
	if ref == "":
		return
	for g in gates:
		if ref in g.refs:
			g.last_touch = time
			g.pending = -1.0


## The obstacle ref (ObstaclePairs) of a body the car hit: a prop's id (its "prop_id"), or a pattern
## copy's boulder (its "copy_id" and the shape's index). "" for anything else.
func ref_of_body(collider: Object, shape_index: int) -> String:
	if collider == null:
		return ""
	if collider.has_meta("prop_id"):
		return str(collider.get_meta("prop_id"))
	if collider.has_meta("copy_id"):
		var cid := str(collider.get_meta("copy_id"))
		for copy in _layout.get("pattern_copies", []):
			if str(copy.get("id", "")) == cid:
				return ObstaclePairs.boulder_ref(copy, maxi(shape_index, 0))
	return ""


# ---- The marker on the ground (a proposal) -----------------------------------------------------

## How a pair shows in the run (a proposal for the playtest): a faint dashed chalk line across the
## gap, on the ground, under the cars, enemies and obstacles. Never Redgull red.
const MARKER_COLOR := Color(0.95, 0.95, 0.88, 0.35)
const MARKER_WIDTH_UNITS := 0.25
const MARKER_DASH_UNITS := 0.75


## Draws a marker per gate into `map` (an mvp_map.gd node): one Node2D per pair under
## map.view_root, right over the ground tiles (where the drift marks go), lifted by `height_at`
## (Callable(units) -> float, the ground height; none: the street) and taking depth_for's depth on
## raised ground (Callable(units, rotation, height) -> int). Returns the markers' root ("NeedleMarkers").
func build_markers(map: Node2D, height_at := Callable(), depth_for := Callable()) -> Node2D:
	var root := Node2D.new()
	root.name = "NeedleMarkers"
	map.view_root.add_child(root)
	map.view_root.move_child(root, map.ground_tiles.get_index() + 1)
	for g in gates:
		var m := _Marker.new()
		m.name = "Needle_" + str(g.id).replace("-", "_")
		var px: float = map.PX_PER_UNIT
		var mid: Vector2 = (g.gap_a + g.gap_b) / 2.0
		var h: float = float(height_at.call(mid)) if height_at.is_valid() else 0.0
		var lift := Vector2(0.0, -h * px)
		m.from = map.ISO_TRANSFORM * (g.gap_a * px) + lift
		m.to = map.ISO_TRANSFORM * (g.gap_b * px) + lift
		m.width = MARKER_WIDTH_UNITS * px
		m.dash = MARKER_DASH_UNITS * px
		if h > 0.0 and depth_for.is_valid():
			m.z_index = int(depth_for.call(mid, 0.0, h)) - 1
		root.add_child(m)
	return root


class _Marker extends Node2D:
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var width := 4.0
	var dash := 12.0

	func _draw() -> void:
		draw_dashed_line(from, to, MARKER_COLOR, width, dash)
