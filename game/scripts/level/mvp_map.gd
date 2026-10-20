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
##
## See-through buildings (task T-034; Visual style, Decisions): in the
## isometric view each building is its own node (map_building.gd) that rises
## BUILDING_HEIGHT_UNITS and is drawn in depth order with the car. While a
## building covers the car on screen (the car is behind it and the car's drawn
## shape overlaps it), that building alone fades as a whole to
## SEE_THROUGH_ALPHA over SEE_THROUGH_FADE_TIME seconds, and fades back when
## the car comes out. With `car` set the map does this every frame; otherwise
## call update_see_through(). car_z_index() says where the car goes in the
## depth order (the run puts its car drawing there).
##
## Boulder art (task T-065): in the isometric view every boulder (the pattern
## copies', the meteor challenges' and the meteor boulders') is drawn as one of
## the boulder sprites listed in art/boulders/boulders.json (made by
## game/tools/build_boulder_art.py), in screen pixels with nearest filtering.
## The variant comes from the boulder's position (boulder_variant), so the same
## boulder always gets the same sprite. Each sprite's opaque width is fitted to
## its collision circle's on-screen width and its bottom stands on the
## circle's front edge (boulder_sprite_rect). Boulders take part in the depth
## order: a boulder is drawn under the buildings that cover it (it is behind
## them and they overlap on screen) and over the rest, and the car is drawn
## under a boulder it is behind and overlaps on screen (car_z_index). The
## flat view keeps the placeholder circles. Only the drawing changed: the
## boulders' bodies, sizes and placement are as before.

const ChallengeTracker := preload("res://scripts/level/challenge_tracker.gd")
const ChallengeArrow := preload("res://scripts/level/challenge_arrow.gd")
const MapBuilding := preload("res://scripts/level/map_building.gd")

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
## The boulder sprites (T-065): variants, their opaque boxes and outlines.
const BOULDER_ART_PATH := "res://art/boulders/boulders.json"
## The building atlas and its list (task T-064); without it the placeholder boxes stay.
const BUILDING_ART_PATH := "res://art/buildings/skyscrapers.json"
const BuildingTowers := preload("res://scripts/level/building_towers.gd")
const KaijuSigns := preload("res://scripts/level/kaiju_signs.gd")
## See-through buildings (Visual style, Decisions, 2026-10-10): how visible a
## building is while it covers the car (0.15 = 15%), and how long the fade
## takes, in seconds (both ways).
const SEE_THROUGH_ALPHA := 0.15
const SEE_THROUGH_FADE_TIME := 0.15
## How tall the placeholder buildings are drawn in the isometric view, in
## units (a placeholder until the building art, task T-064).
const BUILDING_HEIGHT_UNITS := 15.0
## The drawn car (Drifting, Decisions: 1 unit wide, 3 long), and how high its
## drawing reaches above the ground, in units, for the cover test.
const CAR_LENGTH_UNITS := 3.0
const CAR_WIDTH_UNITS := 1.0
const CAR_HEIGHT_UNITS := 1.0
## z_index of the first building in depth order; each next one is
## BUILDING_Z_STEP higher, leaving two levels between any two buildings: the
## upper one for the boulders and the car in front of them, the lower one for
## the car while a boulder covers it (T-065). The ground, drift marks, arrows
## and the flat view's placeholder boulders stay at 0, under every building.
const BUILDING_Z_BASE := 2
const BUILDING_Z_STEP := 3

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
## The map's elevation (task T-206, elevation_layer.gd), or null: set by the
## layer's setup(). With it, the depth order's top, the car's place in it, the
## boulders' places and the open-spot check take the raised areas into
## account, and the layer fades the buildings itself (not _process).
var elevation = null
## Whether this map builds its preset challenges. Set before the map enters the
## tree; the default is CHALLENGES_ENABLED (off in the MVP).
var challenges_enabled := CHALLENGES_ENABLED

## Which layout file the map loads (task T-196). Set before the map enters the
## tree to build another map from the same keys (the elevation sample map's
## data/level/elevation_sample_map.json); the default is the MVP map's.
var layout_path := LAYOUT_PATH
## The layout data, as loaded from layout_path.
var layout: Dictionary = {}
## The ground tiles' layout, as loaded from GROUND_PATH ({} if missing).
var ground_layout: Dictionary = {}
## The boulder sprites' list, as loaded from BOULDER_ART_PATH ({} if missing).
var boulder_art: Dictionary = {}
## The boulder variants' textures, in boulder_art's order.
var boulder_textures: Array[Texture2D] = []
## The building atlas list (T-064, {} if missing) and its texture.
var building_art: Dictionary = {}
## Set false before the map enters the tree to keep the placeholder boxes (tests of the boxes).
var building_art_enabled := true
var building_atlas: Texture2D = null
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
## Holds one sprite per boulder (T-065), in screen pixels of the isometric view.
var boulder_sprites_root: Node2D
## The boulder sprites, in the order they were made (the map's own first).
var boulder_sprites: Array = []
## Boulder key (boulder_key) -> its sprite, so each boulder gets one sprite.
var _boulder_sprite_by_key: Dictionary = {}
var ground_draw: Node2D
var ground_tiles: Node2D
## The container of the building nodes (named "Buildings"); it also draws the map's outline.
var buildings_draw: Node2D
## The building nodes (map_building.gd), in the layout data's order.
var buildings: Array = []
## The skyscrapers' own fade nodes (T-064, per-slot fade): four per block when the building art is
## loaded, in depth order. Empty without the art; then the blocks (`buildings`) fade as wholes.
var slots: Array = []
## The kaiju alert signs (T-130): every sprite, and the root of the pavement ones (kaiju_signs.gd).
var alert_signs: Array = []
var alert_signs_root: Node2D
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
## How many meteor boulders were ever added (names the bodies, so a name is never reused).
var _meteor_boulder_count := 0


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
		layout = load_layout(layout_path)
	if ground_layout.is_empty():
		ground_layout = load_layout(GROUND_PATH)
	if boulder_art.is_empty():
		boulder_art = load_layout(BOULDER_ART_PATH)
	_load_boulder_textures()
	if building_art_enabled and building_art.is_empty():
		building_art = load_layout(BUILDING_ART_PATH)
	if not building_art.is_empty():
		building_atlas = BuildingTowers.load_texture(str(building_art.texture))
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
	_build_buildings()
	alert_signs = KaijuSigns.build(self)
	arrows_root = Node2D.new()
	arrows_root.name = "Arrows"
	view_root.add_child(arrows_root)
	boulders_draw = _BouldersDraw.new()
	boulders_draw.name = "Boulders"
	boulders_draw.map = self
	view_root.add_child(boulders_draw)
	boulder_sprites_root = Node2D.new()
	boulder_sprites_root.name = "BoulderSprites"
	boulder_sprites_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view_root.add_child(boulder_sprites_root)

	_build_walls()
	_build_boulders()
	_sync_boulder_sprites()
	if challenges_enabled:
		_build_challenges()
	set_view(view)


func _build_buildings() -> void:
	var i := 0
	for d in layout.buildings:
		var b = MapBuilding.new()
		b.name = "Building%02d" % (i + 1)
		b.footprint = rect_of(d)
		b.height_units = BUILDING_HEIGHT_UNITS
		b.see_through_alpha = SEE_THROUGH_ALPHA
		b.fade_time = SEE_THROUGH_FADE_TIME
		b.top_color = building_color
		b.left_color = building_color.darkened(0.35)
		b.right_color = building_color.darkened(0.2)
		b.edge_color = building_edge_color
		buildings_draw.add_child(b)
		buildings.append(b)
		if building_atlas != null:
			var towers = BuildingTowers.new()
			towers.name = "Towers"
			towers.setup(building_art, building_atlas, b.footprint)
			b.add_child(towers)
			b.towers = towers
			buildings_draw.add_child(towers.pavement_root)
			buildings_draw.move_child(towers.pavement_root, 0)
			for node in towers.slot_nodes:
				node.see_through_alpha = SEE_THROUGH_ALPHA
				node.fade_time = SEE_THROUGH_FADE_TIME
				buildings_draw.add_child(node)
				slots.append(node)
			b.height_units = towers.tallest_units
			b.custom_silhouette = towers.outline
		i += 1
	# Draw order: by the front corner (x + y), nearest to the viewer on top.
	var order := fade_items().duplicate()
	order.sort_custom(func(p, q):
		if p.depth_key() != q.depth_key():
			return p.depth_key() < q.depth_key()
		return p.footprint.position.x < q.footprint.position.x)
	for k in order.size():
		order[k].z_index = BUILDING_Z_BASE + BUILDING_Z_STEP * k


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
	return is_open_spot(centre, boulder_diameter() / 2.0)


## True when a circle of `radius` units centred on `centre` (units from the
## map's centre) lies wholly inside the map and does not overlap a building or
## any boulder on the map (the pattern copies', meteor challenges' or meteor
## boulders'): open ground the car can drive on. Touching is allowed. Used by
## the meteor boulders' placement check and by the gift pack (T-144) to land
## its package on open road.
func is_open_spot(centre: Vector2, radius: float) -> bool:
	var r := radius
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
	# T-206: with elevation, open ground is street level only (no rooftop or ramp).
	if elevation != null and not elevation.is_street(centre, r):
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
	_meteor_boulder_count += 1
	var body := StaticBody2D.new()
	body.name = "Boulders_meteor_boulder_%d" % _meteor_boulder_count
	body.set_meta("meteor_boulder", _meteor_boulder_count)
	body.set_meta("boulder_key", boulder_key(boulder))
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
	_sync_boulder_sprites()
	return body


## Sets how see-through a meteor boulder is drawn: `alpha` 1 is fully visible,
## 0 invisible (T-142). Its collision is not changed. Only the boulder art (the
## isometric view) fades; the flat view's placeholder circles do not.
func set_meteor_boulder_alpha(body: Node, alpha: float) -> void:
	if body == null or not is_instance_valid(body) or not body.has_meta("boulder_key"):
		return
	var sp = _boulder_sprite_by_key.get(body.get_meta("boulder_key"))
	if sp != null and is_instance_valid(sp):
		sp.modulate.a = clampf(alpha, 0.0, 1.0)


## Takes a meteor boulder off the map (T-142): its body (so it no longer blocks
## the car or anything else), its sprite and its entry in meteor_boulders and
## all_boulders(), so the spot is free for a new boulder. Only meteor boulders
## can be removed, never the map's own.
func remove_meteor_boulder(body: Node) -> void:
	if body == null or not is_instance_valid(body) or not body.has_meta("boulder_key"):
		return
	var key: String = body.get_meta("boulder_key")
	for i in meteor_boulders.size():
		if boulder_key(meteor_boulders[i]) == key:
			meteor_boulders.remove_at(i)
			break
	meteor_boulder_bodies.erase(body)
	var sp = _boulder_sprite_by_key.get(key)
	if sp != null and is_instance_valid(sp):
		boulder_sprites.erase(sp)
		sp.get_parent().remove_child(sp)
		sp.queue_free()
	_boulder_sprite_by_key.erase(key)
	body.get_parent().remove_child(body)
	body.queue_free()
	boulders_draw.queue_redraw()


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
	_sync_boulder_sprites()
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


func _process(delta: float) -> void:
	if car != null and elevation == null:
		update_see_through(car.position / PX_PER_UNIT, car.rotation, delta)


# ---- See-through buildings (task T-034) -----------------------------------------------------

## The drawn car's shape on screen, in the map's screen pixels (isometric
## view): its 1 by 3 unit rectangle on the ground at `centre` (units) and
## `rotation` (radians, nose along +x at 0), together with the same rectangle
## raised CAR_HEIGHT_UNITS, as one convex outline.
func car_screen_shape(centre: Vector2, rotation: float) -> PackedVector2Array:
	return car_screen_shape_at(centre, rotation)


## The same shape for any scene in this projection, lifted `lift_px` screen
## pixels up (the elevation test scene's car drawn at its height, task T-191).
static func car_screen_shape_at(centre: Vector2, rotation: float, lift_px: float = 0.0) -> PackedVector2Array:
	var half := Vector2(CAR_LENGTH_UNITS, CAR_WIDTH_UNITS) / 2.0
	var up := Vector2(0.0, -CAR_HEIGHT_UNITS * PX_PER_UNIT)
	var lift := Vector2(0.0, -lift_px)
	var pts := PackedVector2Array()
	for s in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var corner: Vector2 = centre + (half * s).rotated(rotation)
		var p := ISO_TRANSFORM * (corner * PX_PER_UNIT) + lift
		pts.append(p)
		pts.append(p + up)
	return Geometry2D.convex_hull(pts)


## What fades and sorts with the car: the skyscraper slots when the art is loaded, else the blocks.
func fade_items() -> Array:
	return slots if not slots.is_empty() else buildings


## Fades the buildings covering the car (centre in units, rotation in
## radians) and fades the others back, by `delta` seconds. In the flat view no
## building covers anything, so every building is solid.
func update_see_through(car_centre_units: Vector2, car_rotation: float, delta: float) -> void:
	if view != "iso":
		for b in fade_items():
			b.reset_fade()
		return
	var shape := car_screen_shape(car_centre_units, car_rotation)
	for b in fade_items():
		b.update_fade(car_centre_units, shape, delta)


## The buildings that covered the car at the last update_see_through().
func covering_buildings() -> Array:
	var out := []
	for b in fade_items():
		if b.covering:
			out.append(b)
	return out


## The z_index for the car's drawing so it is drawn under every building that
## covers it and over every other building: just under the lowest covering
## building, or over all of them when none covers it.
func car_z_index(car_centre_units: Vector2, car_rotation: float) -> int:
	var z := top_z_index()
	if view != "iso":
		return z
	var shape := car_screen_shape(car_centre_units, car_rotation)
	for b in fade_items():
		if b.covers(car_centre_units, shape):
			z = mini(z, b.z_index - 1)
	# Boulders (T-065): under every boulder sprite that covers the car.
	var box := _bounds(shape)
	for s in boulder_sprites:
		if s.covers(car_centre_units, shape, box):
			z = mini(z, s.z_index - 1)
	# T-206: and under the raised areas that cover it, at street level.
	if elevation != null:
		z = elevation.z_under_areas(z, car_centre_units, elevation.DEPTH_RADIUS, 0.0, shape)
	return z


## A z_index over every building (the car's when nothing covers it), and over
## every raised area when the map has elevation (T-206).
func top_z_index() -> int:
	if elevation != null:
		return elevation.top_z_index()
	return own_top_z_index()


## A z_index over every building, the map's own order (without elevation).
func own_top_z_index() -> int:
	return BUILDING_Z_BASE + BUILDING_Z_STEP * fade_items().size()


# ---- Boulder art (task T-065) ---------------------------------------------------------------

func _load_boulder_textures() -> void:
	boulder_textures.clear()
	for v in boulder_art.get("variants", []):
		var tex = load(str(v.texture))
		if tex is Texture2D:
			boulder_textures.append(tex)
		else:
			push_error("Missing boulder texture: %s" % v.texture)
			boulder_textures.clear()
			return


## True when the isometric view draws the boulder sprites instead of the
## placeholder circles.
func uses_boulder_art() -> bool:
	return view == "iso" and not boulder_textures.is_empty()


## A boulder's identity for its sprite: its centre, to a hundredth of a unit.
static func boulder_key(b: Dictionary) -> String:
	return "%d,%d" % [roundi(float(b.x) * 100.0), roundi(float(b.y) * 100.0)]


## Which variant (index into boulder_art.variants) a boulder is drawn with:
## from its position only, so it is the same on every map and every run.
func boulder_variant(b: Dictionary) -> int:
	var n := maxi(boulder_textures.size(), 1)
	return posmod(boulder_key(b).hash(), n)


## Where a boulder's sprite is drawn, in the map's screen pixels (isometric
## view): the sprite's opaque width equals the collision circle's on-screen
## width (diameter x sqrt 2), centred on the circle, and the bottom of its
## opaque pixels stands on the circle's front edge. Returns
## {position, scale, rect (the opaque box on screen)}.
func boulder_sprite_rect(b: Dictionary, variant: int) -> Dictionary:
	var v: Dictionary = boulder_art.variants[variant]
	var bb: Array = v.bbox
	var x0 := float(bb[0])
	var y1 := float(bb[3])
	var w := float(bb[2]) - x0
	var h := y1 - float(bb[1])
	var d := float(b.diameter) * PX_PER_UNIT
	var s := d * sqrt(2.0) / w
	var c := ISO_TRANSFORM * (Vector2(float(b.x), float(b.y)) * PX_PER_UNIT)
	var bottom := c + Vector2(0.0, d * sqrt(2.0) / 4.0)
	var pos := Vector2(bottom.x - (x0 + w / 2.0) * s, bottom.y - y1 * s)
	var rect := Rect2(Vector2(bottom.x - w * s / 2.0, bottom.y - h * s), Vector2(w * s, h * s))
	return {"position": pos, "scale": s, "rect": rect}


## Makes the sprite of every boulder that has none yet (the map's at build
## time, the meteors' as they land), with its place in the depth order.
func _sync_boulder_sprites() -> void:
	if boulder_textures.is_empty() or boulder_sprites_root == null:
		return
	for b in all_boulders():
		var key := boulder_key(b)
		if _boulder_sprite_by_key.has(key):
			continue
		var k := boulder_variant(b)
		var r := boulder_sprite_rect(b, k)
		var sp := _BoulderSprite.new()
		sp.name = "Boulder%03d" % (boulder_sprites.size() + 1)
		sp.texture = boulder_textures[k]
		sp.centered = false
		sp.position = r.position
		sp.scale = Vector2(r.scale, r.scale)
		sp.variant = str(boulder_art.variants[k].id)
		sp.centre_units = Vector2(float(b.x), float(b.y))
		var outline := PackedVector2Array()
		for p in boulder_art.variants[k].hull:
			outline.append(r.position + Vector2(float(p[0]), float(p[1])) * r.scale)
		sp.outline = outline
		sp.box = r.rect
		sp.z_index = _boulder_z(sp.centre_units, outline)
		boulder_sprites_root.add_child(sp)
		boulder_sprites.append(sp)
		_boulder_sprite_by_key[key] = sp


## A boulder's z_index: just under the lowest building that covers it (the
## boulder is behind the building and they overlap on screen), or over every
## building. The car's level for that place, so the car in front of the
## boulder (later in the tree) is drawn over it.
func _boulder_z(centre_units: Vector2, outline: PackedVector2Array) -> int:
	var z := _boulder_z_buildings(centre_units, outline)
	# T-206: with elevation, over the areas too, and under the ones covering it.
	if elevation != null:
		if z >= own_top_z_index():
			z = elevation.top_z_index()
		z = elevation.boulder_z_under_areas(z, centre_units, outline)
	return z


## A boulder's z_index among the buildings only.
func _boulder_z_buildings(centre_units: Vector2, outline: PackedVector2Array) -> int:
	var z := own_top_z_index()
	for b in fade_items():
		if b.is_behind(centre_units) and not Geometry2D.intersect_polygons(b.iso_silhouette(), outline).is_empty():
			z = mini(z, b.z_index - 1)
	return z


static func _bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	return r


## Switches the drawing between "flat" and "iso". Never touches the physics.
func set_view(v: String) -> void:
	view = v
	view_root.transform = ISO_TRANSFORM if v == "iso" else Transform2D.IDENTITY
	if boulder_sprites_root != null:
		# Boulder sprites (T-065) in screen pixels: undo the view's projection.
		boulder_sprites_root.visible = uses_boulder_art()
		boulder_sprites_root.transform = ISO_TRANSFORM.affine_inverse() if v == "iso" else Transform2D.IDENTITY
	if boulders_draw != null:
		boulders_draw.queue_redraw()
	if ground_tiles != null:
		ground_tiles.visible = v == "iso" and ground_tiles.has_art()
		# The tiles are drawn in screen pixels: undo the view's projection.
		ground_tiles.transform = ISO_TRANSFORM.affine_inverse() if v == "iso" else Transform2D.IDENTITY
		ground_draw.queue_redraw()
	for b in buildings:
		b.set_view(v)
		if b.towers != null:
			# The pavement is in screen pixels: undo the view's projection; the flat view keeps the placeholder.
			b.towers.pavement_root.visible = uses_building_art()
			b.towers.pavement_root.transform = ISO_TRANSFORM.affine_inverse() if v == "iso" else Transform2D.IDENTITY
			b.draw_placeholder = not uses_building_art()
			b.queue_redraw()
		if v != "iso":
			b.reset_fade()
	if alert_signs_root != null:
		alert_signs_root.visible = uses_building_art()
		alert_signs_root.transform = ISO_TRANSFORM.affine_inverse() if v == "iso" else Transform2D.IDENTITY
	for node in slots:
		node.set_view(v)
		# The skyscraper art is in screen pixels too.
		node.towers.visible = uses_building_art()
		node.towers.transform = ISO_TRANSFORM.affine_inverse() if v == "iso" else Transform2D.IDENTITY
		if v != "iso":
			node.reset_fade()


## True when the isometric view draws the building art (T-064) instead of the placeholder boxes.
func uses_building_art() -> bool:
	return view == "iso" and building_atlas != null


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


## Holds the building nodes (map_building.gd, flat placeholder colours) and
## draws the map's outline on the ground.
class _BuildingsDraw extends Node2D:
	var map

	func _draw() -> void:
		var u: float = map.PX_PER_UNIT
		var m: Rect2 = map.rect_of(map.layout.map.rect)
		draw_rect(Rect2(m.position * u, m.size * u), map.building_edge_color, false, 3.0)


## Draws every boulder (the pattern copies', the meteor challenges' and the
## meteor boulders') as a placeholder circle, over the arrows, when the
## boulder sprites are not drawn (the flat view).
class _BouldersDraw extends Node2D:
	var map

	func _draw() -> void:
		if map.uses_boulder_art():
			return
		var u: float = map.PX_PER_UNIT
		for b in map.all_boulders():
			var c := Vector2(float(b.x), float(b.y)) * u
			var r := float(b.diameter) / 2.0 * u
			draw_circle(c, r, map.boulder_color)
			draw_arc(c, r - 1.0, 0.0, TAU, 32, map.boulder_edge_color, 2.0)


## One boulder's sprite (T-065), in the map's screen pixels (isometric view).
class _BoulderSprite extends Sprite2D:
	## The variant's id in boulders.json ("a", "b_mirror", ...).
	var variant := ""
	## The boulder's centre on the ground, in units.
	var centre_units := Vector2.ZERO
	## The outline of its opaque pixels on screen (convex), and its box.
	var outline := PackedVector2Array()
	var box := Rect2()

	## True when the boulder covers the car: the car's centre (units) is
	## behind the boulder's centre (smaller x + y, farther from the viewer)
	## and the car's screen shape overlaps the boulder's outline.
	func covers(car_centre_units: Vector2, car_shape: PackedVector2Array, car_box: Rect2) -> bool:
		if car_centre_units.x + car_centre_units.y >= centre_units.x + centre_units.y:
			return false
		if not box.intersects(car_box):
			return false
		return not Geometry2D.intersect_polygons(outline, car_shape).is_empty()
