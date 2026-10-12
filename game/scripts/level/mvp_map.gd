extends Node2D
## The MVP map (task T-019): the city grid, the obstacle pattern copies and the
## preset challenges, built from the layout data file
## (data/level/mvp_map.json, made by game/tools/build_mvp_map.py).
##
## Ground art (task T-103): in the isometric view the roads and the gravel
## centre are drawn from the ground tile atlas (art/ground/ground_atlas.png),
## one 2 x 2 unit tile per cell as listed in data/level/mvp_ground.json (both
## made by game/tools/build_ground_tiles.py). The flat view, the outside of the
## map and the buildings keep the flat placeholder colours.
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
##
## Meteor challenges (task T-035): during a run, the kaiju's meteor attack can
## place one of the 3 challenge designs (the fitted versions, in the layout
## data's challenge_designs) anywhere with add_meteor_challenge(). It gets
## boulders and a green arrow, follows the same completion rule, and on
## completion sends meteor_challenge_completed (never challenge_completed).
## can_place_meteor_challenge() says whether a design fits at a spot.
##
## Challenges are left out of the MVP (Level design, Decisions, 2026-10-11):
## with challenges_enabled false (the default, CHALLENGES_ENABLED) the map
## builds no trackers and no arrows, so it never sends challenge_completed; the
## pattern copies' boulders stay as plain obstacles. The challenge code and data
## are kept, unused: set CHALLENGES_ENABLED to true to bring them back.
##
## Meteor boulders (task T-097): the kaiju's meteors leave plain boulders where
## they land. add_meteor_boulder() places one during a run (same size, look and
## collision as the map's boulders); can_place_meteor_boulder() is its
## placement check. A new run builds a new map, so they go with the old one.

const ChallengeTracker := preload("res://scripts/level/challenge_tracker.gd")
const ChallengeArrow := preload("res://scripts/level/challenge_arrow.gd")

const LAYOUT_PATH := "res://data/level/mvp_map.json"
## The ground tiles' layout (T-103): the atlas tile on every 2 x 2 unit cell.
const GROUND_PATH := "res://data/level/mvp_ground.json"
## Pixels per unit, the same as Car.PX_PER_UNIT.
const PX_PER_UNIT := 16.0
## The same 2:1 isometric projection as the drift prototype.
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## How thick the invisible wall beyond the map's edge is, in units.
const EDGE_WALL_THICKNESS := 8.0
## Spacing (units) of the corridor samples the placement check tests.
const PLACEMENT_STEP := 0.1
## Challenges are left out of the MVP (Level design, Decisions, 2026-10-11).
## The one switch to bring them back: true builds the preset challenges (arrows
## and completion checks) on every map, the run's included.
const CHALLENGES_ENABLED := false
## Fallback boulder size (units across) if the layout data has no boulder.
const DEFAULT_BOULDER_DIAMETER := 3.0

## Fired once when a preset challenge is completed (XP and the HUD hook in here later).
signal challenge_completed(challenge_id: String)
## Fired once when a meteor challenge (add_meteor_challenge) is completed, with
## the id add_meteor_challenge returned. Preset challenges never send it.
signal meteor_challenge_completed(challenge_id: String)

## Placeholder colours (Visual style: night, dark navy and purple).
var outside_color := Color(0.03, 0.03, 0.06)
var road_color := Color(0.20, 0.21, 0.26)
var gravel_color := Color(0.40, 0.36, 0.30)
var building_color := Color(0.22, 0.15, 0.38)
var building_edge_color := Color(0.45, 0.30, 0.70)
var boulder_color := Color(0.13, 0.12, 0.15)
var boulder_edge_color := Color(0.95, 0.45, 0.25)
## Visual style, Decisions: the arrows of the kaiju's meteor challenges are green.
var meteor_band_color := Color(0.25, 0.85, 0.35, 0.45)
var meteor_line_color := Color(0.50, 1.0, 0.55, 1.0)

## Optional: the car to check the challenges against every physics step.
var car: Node2D = null
## Whether this map builds its preset challenges. Set before the map enters the
## tree; the default is CHALLENGES_ENABLED (off in the MVP).
var challenges_enabled := CHALLENGES_ENABLED

## The layout data, as loaded from LAYOUT_PATH.
var layout: Dictionary = {}
## The ground tiles' layout, as loaded from GROUND_PATH ({} if missing).
var ground_layout: Dictionary = {}
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
var boulders_draw: Node2D
var ground_draw: Node2D
var ground_tiles: Node2D
var buildings_draw: Node2D
## Meteor challenges: id -> {id, design, centre, angle, boulders,
## corridor_width, centre_line}, everything placed, in units.
var meteor_challenges: Dictionary = {}
## Meteor challenge ids, in the order they were created.
var _meteor_ids: Array = []
## One static body per meteor challenge, for its boulders (layer 1).
var meteor_boulder_bodies: Array[StaticBody2D] = []
var _meteor_count := 0
## Meteor boulders (add_meteor_boulder): {x, y, diameter} in units, in order.
var meteor_boulders: Array = []


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
	if ground_layout.is_empty():
		ground_layout = load_layout(GROUND_PATH)
	_build()


func _build() -> void:
	physics_root = Node2D.new()
	physics_root.name = "Physics"
	physics_root.visible = false
	add_child(physics_root)
	view_root = Node2D.new()
	view_root.name = "View"
	add_child(view_root)

	ground_draw = _GroundDraw.new()
	ground_draw.name = "Ground"
	ground_draw.map = self
	view_root.add_child(ground_draw)
	ground_tiles = _GroundTiles.new()
	ground_tiles.name = "GroundTiles"
	ground_tiles.map = self
	view_root.add_child(ground_tiles)
	buildings_draw = _BuildingsDraw.new()
	buildings_draw.name = "Buildings"
	buildings_draw.map = self
	view_root.add_child(buildings_draw)
	arrows_root = Node2D.new()
	arrows_root.name = "Arrows"
	view_root.add_child(arrows_root)
	boulders_draw = _BouldersDraw.new()
	boulders_draw.name = "Boulders"
	boulders_draw.map = self
	view_root.add_child(boulders_draw)

	_build_walls()
	_build_boulders()
	if challenges_enabled:
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


## Challenge ids, in the layout data's order. Empty when challenges are off.
func challenge_ids() -> Array:
	var out := []
	if not challenges_enabled:
		return out
	for ch in layout.challenges:
		out.append(ch.id)
	return out


## The layout data entry for one challenge (points in units), or {}
## ({} too when challenges are off).
func get_challenge(challenge_id: String) -> Dictionary:
	if not challenges_enabled:
		return {}
	for ch in layout.challenges:
		if ch.id == challenge_id:
			return ch
	return {}


## True once a challenge (preset or meteor) has been completed.
func is_challenge_completed(challenge_id: String) -> bool:
	return trackers.has(challenge_id) and trackers[challenge_id].is_completed


## Checks every open challenge against the drawn car, given in units (centre)
## and radians. Call once per physics step, or set `car` instead.
func update_car(car_centre_units: Vector2, car_rotation: float) -> void:
	for id in trackers:
		var tracker = trackers[id]
		if tracker.update(car_centre_units, car_rotation):
			_complete(id)


func _complete(challenge_id: String) -> void:
	arrows[challenge_id].visible = false
	if meteor_challenges.has(challenge_id):
		meteor_challenge_completed.emit(challenge_id)
	else:
		challenge_completed.emit(challenge_id)


# ---- Meteor challenges (task T-035) ---------------------------------------------------------

## The ids of the challenge designs a meteor challenge can use:
## "single-boulder/arrow-1", "single-boulder/arrow-2", "two-boulders/arrow-1".
func challenge_design_ids() -> Array:
	var out := []
	for d in layout.get("challenge_designs", []):
		out.append(d.id)
	return out


## One design as in the layout data (unplaced: units from the pattern's centre,
## rotation 0), or {} for an unknown id.
func get_challenge_design(design_id: String) -> Dictionary:
	for d in layout.get("challenge_designs", []):
		if d.id == design_id:
			return d
	return {}


## A design placed at `centre` (units from the map's centre) and turned by
## `angle` (radians, clockwise on screen, like Node2D.rotation): its boulders
## ({x, y, diameter}) and its arrow's centre line, in map units. {} for an
## unknown design.
func place_design(design_id: String, centre: Vector2, angle: float) -> Dictionary:
	var d := get_challenge_design(design_id)
	if d.is_empty():
		return {}
	var boulders := []
	for b in d.boulders:
		var p := Vector2(float(b.x), float(b.y)).rotated(angle) + centre
		boulders.append({"x": p.x, "y": p.y, "diameter": float(b.diameter)})
	var line := PackedVector2Array()
	for p in points_of(d.centre_line):
		line.append(p.rotated(angle) + centre)
	return {"boulders": boulders, "centre_line": line, "corridor_width": float(d.corridor_width)}


## Every boulder on the map now: the pattern copies', the meteor challenges'
## and the meteor boulders' ({x, y, diameter} in units).
func all_boulders() -> Array:
	var out := []
	for copy in layout.pattern_copies:
		out.append_array(copy.boulders)
	for id in _meteor_ids:
		out.append_array(meteor_challenges[id].boulders)
	out.append_array(meteor_boulders)
	return out


# ---- Meteor boulders (task T-097) -----------------------------------------------------------

## How big a boulder is (units across): the same as the map's own boulders.
func boulder_diameter() -> float:
	for copy in layout.get("pattern_copies", []):
		for b in copy.boulders:
			return float(b.diameter)
	return DEFAULT_BOULDER_DIAMETER


## The placement check for a meteor boulder: true when a boulder centred on
## `centre` (units from the map's centre) lies wholly inside the map and does
## not overlap a building or any boulder already on the map (the pattern
## copies', meteor challenges' or other meteor boulders'). Touching is allowed.
func can_place_meteor_boulder(centre: Vector2) -> bool:
	var r := boulder_diameter() / 2.0
	var m := rect_of(layout.map.rect)
	if centre.x - r < m.position.x or centre.x + r > m.end.x:
		return false
	if centre.y - r < m.position.y or centre.y + r > m.end.y:
		return false
	for b in layout.buildings:
		if _rect_distance(centre, rect_of(b)) < r:
			return false
	for o in all_boulders():
		if centre.distance_to(Vector2(float(o.x), float(o.y))) < r + float(o.diameter) / 2.0:
			return false
	return true


## Places one plain boulder at `centre` (units from the map's centre) during a
## run, where a meteor landed: the same size, look and collision as the map's
## boulders (a static body on collision layer 1, the car bounces off it). No
## challenge or arrow comes with it. Returns its body, which is also added to
## meteor_boulder_bodies. It does not run the placement check: call
## can_place_meteor_boulder first.
func add_meteor_boulder(centre: Vector2) -> StaticBody2D:
	var d := boulder_diameter()
	var boulder := {"x": centre.x, "y": centre.y, "diameter": d}
	meteor_boulders.append(boulder)
	var body := StaticBody2D.new()
	body.name = "Boulders_meteor_boulder_%d" % meteor_boulders.size()
	body.set_meta("meteor_boulder", meteor_boulders.size())
	physics_root.add_child(body)
	var shape := CircleShape2D.new()
	shape.radius = d / 2.0 * PX_PER_UNIT
	var cs := CollisionShape2D.new()
	cs.name = "Boulder1"
	cs.shape = shape
	cs.position = centre * PX_PER_UNIT
	body.add_child(cs)
	meteor_boulder_bodies.append(body)
	boulders_draw.queue_redraw()
	return body


## The placement check: true when the design fits at `centre` and `angle`
## (as in place_design): none of its boulders and no part of its corridor
## overlaps a building, another boulder already on the map, or the map's edge.
func can_place_meteor_challenge(design_id: String, centre: Vector2, angle: float) -> bool:
	var placed := place_design(design_id, centre, angle)
	if placed.is_empty():
		return false
	var m := rect_of(layout.map.rect)
	var buildings := []
	for b in layout.buildings:
		buildings.append(rect_of(b))
	var others := all_boulders()
	# Circles that must fit: each new boulder, and the corridor as circles of
	# half its width along the centre line, every PLACEMENT_STEP units.
	var circles := []
	for b in placed.boulders:
		circles.append([Vector2(b.x, b.y), b.diameter / 2.0])
	var r: float = placed.corridor_width / 2.0
	for p in _densify(placed.centre_line, PLACEMENT_STEP):
		circles.append([p, r])
	for c in circles:
		var p: Vector2 = c[0]
		var radius: float = c[1]
		if p.x - radius < m.position.x or p.x + radius > m.end.x:
			return false
		if p.y - radius < m.position.y or p.y + radius > m.end.y:
			return false
		for rect in buildings:
			if _rect_distance(p, rect) < radius:
				return false
		for o in others:
			if p.distance_to(Vector2(float(o.x), float(o.y))) < radius + float(o.diameter) / 2.0:
				return false
	return true


## Creates a meteor challenge during the run: places the design (see
## place_design) with its boulders (static bodies on layer 1, like the map's)
## and its green arrow, and starts checking the completion rule. Returns the new
## challenge's id ("meteor-1", "meteor-2", ...), or "" for an unknown design.
## It does not run the placement check; call can_place_meteor_challenge first.
func add_meteor_challenge(design_id: String, centre: Vector2, angle: float) -> String:
	var placed := place_design(design_id, centre, angle)
	if placed.is_empty():
		push_error("Unknown challenge design: %s" % design_id)
		return ""
	_meteor_count += 1
	var id := "meteor-%d" % _meteor_count
	var line: PackedVector2Array = placed.centre_line
	meteor_challenges[id] = {
		"id": id,
		"design": design_id,
		"centre": centre,
		"angle": angle,
		"boulders": placed.boulders,
		"corridor_width": placed.corridor_width,
		"centre_line": line,
	}
	_meteor_ids.append(id)

	var body := StaticBody2D.new()
	body.name = "Boulders_%s" % id.replace("-", "_")
	body.set_meta("challenge_id", id)
	physics_root.add_child(body)
	var j := 0
	for b in placed.boulders:
		var shape := CircleShape2D.new()
		shape.radius = float(b.diameter) / 2.0 * PX_PER_UNIT
		var cs := CollisionShape2D.new()
		cs.name = "Boulder%d" % (j + 1)
		cs.shape = shape
		cs.position = Vector2(b.x, b.y) * PX_PER_UNIT
		body.add_child(cs)
		j += 1
	meteor_boulder_bodies.append(body)

	var tracker := ChallengeTracker.new()
	tracker.setup(id, line, placed.corridor_width)
	trackers[id] = tracker
	var arrow := ChallengeArrow.new()
	arrow.name = "Arrow_%s" % id.replace("-", "_")
	arrow.centre_line = line
	arrow.corridor_width = placed.corridor_width
	arrow.px_per_unit = PX_PER_UNIT
	arrow.band_color = meteor_band_color
	arrow.line_color = meteor_line_color
	arrows_root.add_child(arrow)
	arrows[id] = arrow
	boulders_draw.queue_redraw()
	return id


## Meteor challenge ids, in the order they were created (open and completed).
func meteor_challenge_ids() -> Array:
	return _meteor_ids.duplicate()


## One meteor challenge's record (see add_meteor_challenge), or {}.
func get_meteor_challenge(challenge_id: String) -> Dictionary:
	return meteor_challenges.get(challenge_id, {})


## True for an id add_meteor_challenge returned.
func is_meteor_challenge(challenge_id: String) -> bool:
	return meteor_challenges.has(challenge_id)


## Meteor challenges not completed yet.
func open_meteor_challenge_ids() -> Array:
	var out := []
	for id in _meteor_ids:
		if not trackers[id].is_completed:
			out.append(id)
	return out


static func _rect_distance(p: Vector2, r: Rect2) -> float:
	var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
	var dy := maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
	return Vector2(dx, dy).length()


## The line's points plus extra points so no two are more than `step` apart.
static func _densify(line: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if line.is_empty():
		return out
	out.append(line[0])
	for i in range(1, line.size()):
		var a := line[i - 1]
		var b := line[i]
		var n := maxi(1, ceili(a.distance_to(b) / step))
		for k in range(1, n + 1):
			out.append(a.lerp(b, float(k) / float(n)))
	return out


func _physics_process(_delta: float) -> void:
	if car != null:
		update_car(car.position / PX_PER_UNIT, car.rotation)


## Switches the drawing between "flat" and "iso". Never touches the physics.
func set_view(v: String) -> void:
	view = v
	view_root.transform = ISO_TRANSFORM if v == "iso" else Transform2D.IDENTITY
	if ground_tiles != null:
		ground_tiles.visible = v == "iso" and ground_tiles.has_art()
		# The tiles are drawn in screen pixels: undo the view's projection.
		ground_tiles.transform = ISO_TRANSFORM.affine_inverse() if v == "iso" else Transform2D.IDENTITY
		ground_draw.queue_redraw()


## True when the isometric view draws the ground art (T-103) instead of the
## flat road and gravel colours.
func uses_ground_art() -> bool:
	return ground_tiles != null and ground_tiles.visible


## Where the top vertex of cell (i, j) of the ground layout is drawn, in the
## map's screen pixels of the isometric view (the cell's corner with the
## smallest world x and y, projected).
func ground_cell_top(i: int, j: int) -> Vector2:
	var cell := float(ground_layout.cell_units)
	var corner := Vector2(float(ground_layout.origin[0]) + i * cell, float(ground_layout.origin[1]) + j * cell)
	return ISO_TRANSFORM * (corner * PX_PER_UNIT)


## Draws the outside of the map, and the road and gravel placeholder colours
## when the ground art is not drawn (the flat view).
class _GroundDraw extends Node2D:
	var map

	func _draw() -> void:
		var u: float = map.PX_PER_UNIT
		var m: Rect2 = map.rect_of(map.layout.map.rect)
		var t: float = map.EDGE_WALL_THICKNESS
		draw_rect(Rect2((m.position - Vector2(t, t)) * u, (m.size + Vector2(2 * t, 2 * t)) * u), map.outside_color)
		if map.uses_ground_art():
			return
		draw_rect(Rect2(m.position * u, m.size * u), map.road_color)
		var g: Rect2 = map.rect_of(map.layout.gravel)
		draw_rect(Rect2(g.position * u, g.size * u), map.gravel_color)


## The ground art (T-103): one atlas tile per 2 x 2 unit cell, in screen pixels
## of the isometric view. Each tile is 128 x 64 art pixels drawn at the art's
## scale (half size: 32 art pixels per unit, 16 world pixels per unit); the
## tiles' exact footprints fit together with no gap or overlap.
class _GroundTiles extends Node2D:
	var map
	var atlas: Texture2D

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func has_art() -> bool:
		if atlas == null and not map.ground_layout.is_empty():
			atlas = load(str(map.ground_layout.atlas))
		return atlas != null

	func _draw() -> void:
		if not has_art():
			return
		var g: Dictionary = map.ground_layout
		var tw := float(g.tile_px[0])
		var th := float(g.tile_px[1])
		var cols := int(g.atlas_columns)
		var s: float = float(g.cell_units) * map.PX_PER_UNIT * 2.0 / tw  # 0.5
		var size := Vector2(tw, th) * s
		var cells: Array = g.cells
		for j in cells.size():
			var row: Array = cells[j]
			for i in row.size():
				var k := int(row[i])
				if k < 0:
					continue
				var top: Vector2 = map.ground_cell_top(i, j)
				var src := Rect2((k % cols) * tw, (k / cols) * th, tw, th)
				draw_texture_rect_region(atlas, Rect2(top - Vector2(size.x / 2.0, 0.0), size), src)


## Draws the buildings (flat placeholder colours) over the ground.
class _BuildingsDraw extends Node2D:
	var map

	func _draw() -> void:
		var u: float = map.PX_PER_UNIT
		var m: Rect2 = map.rect_of(map.layout.map.rect)
		for b in map.layout.buildings:
			var r: Rect2 = map.rect_of(b)
			draw_rect(Rect2(r.position * u, r.size * u), map.building_color)
			draw_rect(Rect2(r.position * u, r.size * u), map.building_edge_color, false, 2.0)
		draw_rect(Rect2(m.position * u, m.size * u), map.building_edge_color, false, 3.0)


## Draws every boulder (the pattern copies' and the meteor challenges'), over the arrows.
class _BouldersDraw extends Node2D:
	var map

	func _draw() -> void:
		var u: float = map.PX_PER_UNIT
		for b in map.all_boulders():
			var c := Vector2(float(b.x), float(b.y)) * u
			var r := float(b.diameter) / 2.0 * u
			draw_circle(c, r, map.boulder_color)
			draw_arc(c, r - 1.0, 0.0, TAU, 32, map.boulder_edge_color, 2.0)
