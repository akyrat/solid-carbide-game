extends Node2D
## The MVP map (task T-019): the city grid, the obstacle pattern copies and the
## preset challenges, built from the layout data file
## (data/level/mvp_map.json, made by game/tools/build_mvp_map.py). Flat
## placeholder colours; the art comes later.
##
## Units and physics match the drift car (scripts/driving/car.gd): 16 pixels per
## unit, the flat top-down physics world, the map's centre on this node's origin.
## The node has two parts, like the drift prototype:
## - Physics: static bodies in flat world pixels (buildings, the map's edge and
##   the boulders), on collision layer 1. They are never drawn.
## - View: the drawing, flat or through the 2:1 isometric projection (set_view).
##
## Driving: give the map the car (`car`, a node whose position is in the same
## flat world pixels as Physics and whose rotation 0 points its nose along +x),
## or call update_car() once per physics step. Each challenge then checks the
## completion rule (challenge_tracker.gd). When one is completed, its arrow
## disappears, its boulders stay, and challenge_completed fires once.

const ChallengeTracker := preload("res://scripts/level/challenge_tracker.gd")
const ChallengeArrow := preload("res://scripts/level/challenge_arrow.gd")

const LAYOUT_PATH := "res://data/level/mvp_map.json"
## Pixels per unit, the same as Car.PX_PER_UNIT.
const PX_PER_UNIT := 16.0
## The same 2:1 isometric projection as the drift prototype.
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## How thick the invisible wall beyond the map's edge is, in units.
const EDGE_WALL_THICKNESS := 8.0

## Fired once when a challenge is completed (XP and the HUD hook in here later).
signal challenge_completed(challenge_id: String)

## Placeholder colours (Visual style: night, dark navy and purple).
var outside_color := Color(0.03, 0.03, 0.06)
var road_color := Color(0.20, 0.21, 0.26)
var gravel_color := Color(0.40, 0.36, 0.30)
var building_color := Color(0.22, 0.15, 0.38)
var building_edge_color := Color(0.45, 0.30, 0.70)
var boulder_color := Color(0.13, 0.12, 0.15)
var boulder_edge_color := Color(0.95, 0.45, 0.25)

## Optional: the car to check the challenges against every physics step.
var car: Node2D = null

## The layout data, as loaded from LAYOUT_PATH.
var layout: Dictionary = {}
## "flat" or "iso".
var view := "flat"

var physics_root: Node2D
var view_root: Node2D
var arrows_root: Node2D
var walls: StaticBody2D
var boulder_bodies: Array[StaticBody2D] = []
## challenge id -> ChallengeTracker
var trackers: Dictionary = {}
## challenge id -> ChallengeArrow node
var arrows: Dictionary = {}


static func load_layout(path: String = LAYOUT_PATH) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	return data if data is Dictionary else {}


static func rect_of(d: Dictionary) -> Rect2:
	return Rect2(float(d.x), float(d.y), float(d.w), float(d.h))


static func points_of(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in arr:
		out.append(Vector2(float(p[0]), float(p[1])))
	return out


func _ready() -> void:
	if layout.is_empty():
		layout = load_layout()
	_build()


func _build() -> void:
	physics_root = Node2D.new()
	physics_root.name = "Physics"
	physics_root.visible = false
	add_child(physics_root)
	view_root = Node2D.new()
	view_root.name = "View"
	add_child(view_root)

	var ground := _GroundDraw.new()
	ground.name = "Ground"
	ground.map = self
	view_root.add_child(ground)
	arrows_root = Node2D.new()
	arrows_root.name = "Arrows"
	view_root.add_child(arrows_root)
	var boulders_draw := _BouldersDraw.new()
	boulders_draw.name = "Boulders"
	boulders_draw.map = self
	view_root.add_child(boulders_draw)

	_build_walls()
	_build_boulders()
	_build_challenges()
	set_view(view)


func _build_walls() -> void:
	walls = StaticBody2D.new()
	walls.name = "Walls"
	physics_root.add_child(walls)
	var i := 0
	for b in layout.buildings:
		_add_rect_shape(walls, rect_of(b), "Building%02d" % (i + 1))
		i += 1
	# The hard stop at the map's edges: four thick walls just outside the map.
	var m := rect_of(layout.map.rect)
	var t := EDGE_WALL_THICKNESS
	_add_rect_shape(walls, Rect2(m.position.x - t, m.position.y - t, m.size.x + 2 * t, t), "EdgeTop")
	_add_rect_shape(walls, Rect2(m.position.x - t, m.end.y, m.size.x + 2 * t, t), "EdgeBottom")
	_add_rect_shape(walls, Rect2(m.position.x - t, m.position.y, t, m.size.y), "EdgeLeft")
	_add_rect_shape(walls, Rect2(m.end.x, m.position.y, t, m.size.y), "EdgeRight")


func _add_rect_shape(body: StaticBody2D, r: Rect2, shape_name: String) -> void:
	var shape := RectangleShape2D.new()
	shape.size = r.size * PX_PER_UNIT
	var cs := CollisionShape2D.new()
	cs.name = shape_name
	cs.shape = shape
	cs.position = r.get_center() * PX_PER_UNIT
	body.add_child(cs)


func _build_boulders() -> void:
	for copy in layout.pattern_copies:
		var body := StaticBody2D.new()
		body.name = "Boulders_%s" % str(copy.id).replace("-", "_")
		body.set_meta("copy_id", copy.id)
		physics_root.add_child(body)
		var j := 0
		for b in copy.boulders:
			var shape := CircleShape2D.new()
			shape.radius = float(b.diameter) / 2.0 * PX_PER_UNIT
			var cs := CollisionShape2D.new()
			cs.name = "Boulder%d" % (j + 1)
			cs.shape = shape
			cs.position = Vector2(float(b.x), float(b.y)) * PX_PER_UNIT
			body.add_child(cs)
			j += 1
		boulder_bodies.append(body)


func _build_challenges() -> void:
	for ch in layout.challenges:
		var line := points_of(ch.centre_line)
		var tracker := ChallengeTracker.new()
		tracker.setup(ch.id, line, float(ch.corridor_width))
		trackers[ch.id] = tracker
		var arrow := ChallengeArrow.new()
		arrow.name = "Arrow_%s" % str(ch.id).replace("-", "_")
		arrow.centre_line = line
		arrow.corridor_width = float(ch.corridor_width)
		arrow.px_per_unit = PX_PER_UNIT
		arrows_root.add_child(arrow)
		arrows[ch.id] = arrow


## Challenge ids, in the layout data's order.
func challenge_ids() -> Array:
	var out := []
	for ch in layout.challenges:
		out.append(ch.id)
	return out


## The layout data entry for one challenge (points in units), or {}.
func get_challenge(challenge_id: String) -> Dictionary:
	for ch in layout.challenges:
		if ch.id == challenge_id:
			return ch
	return {}


func is_challenge_completed(challenge_id: String) -> bool:
	return trackers[challenge_id].is_completed


## Checks every open challenge against the drawn car, given in units (centre)
## and radians. Call once per physics step, or set `car` instead.
func update_car(car_centre_units: Vector2, car_rotation: float) -> void:
	for id in trackers:
		var tracker = trackers[id]
		if tracker.update(car_centre_units, car_rotation):
			_complete(id)


func _complete(challenge_id: String) -> void:
	arrows[challenge_id].visible = false
	challenge_completed.emit(challenge_id)


func _physics_process(_delta: float) -> void:
	if car != null:
		update_car(car.position / PX_PER_UNIT, car.rotation)


## Switches the drawing between "flat" and "iso". Never touches the physics.
func set_view(v: String) -> void:
	view = v
	view_root.transform = ISO_TRANSFORM if v == "iso" else Transform2D.IDENTITY


## Draws the ground, the gravel centre and the buildings.
class _GroundDraw extends Node2D:
	var map

	func _draw() -> void:
		var u: float = map.PX_PER_UNIT
		var m: Rect2 = map.rect_of(map.layout.map.rect)
		var t: float = map.EDGE_WALL_THICKNESS
		draw_rect(Rect2((m.position - Vector2(t, t)) * u, (m.size + Vector2(2 * t, 2 * t)) * u), map.outside_color)
		draw_rect(Rect2(m.position * u, m.size * u), map.road_color)
		var g: Rect2 = map.rect_of(map.layout.gravel)
		draw_rect(Rect2(g.position * u, g.size * u), map.gravel_color)
		for b in map.layout.buildings:
			var r: Rect2 = map.rect_of(b)
			draw_rect(Rect2(r.position * u, r.size * u), map.building_color)
			draw_rect(Rect2(r.position * u, r.size * u), map.building_edge_color, false, 2.0)
		draw_rect(Rect2(m.position * u, m.size * u), map.building_edge_color, false, 3.0)


## Draws every boulder, over the arrows.
class _BouldersDraw extends Node2D:
	var map

	func _draw() -> void:
		var u: float = map.PX_PER_UNIT
		for copy in map.layout.pattern_copies:
			for b in copy.boulders:
				var c := Vector2(float(b.x), float(b.y)) * u
				var r := float(b.diameter) / 2.0 * u
				draw_circle(c, r, map.boulder_color)
				draw_arc(c, r - 1.0, 0.0, TAU, 32, map.boulder_edge_color, 2.0)
