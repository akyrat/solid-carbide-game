extends Node2D
## The elevation sample map (task T-196; Level design, Decisions and Content,
## "Elevation sample map"): a drive-only scene, the elevation test scene made
## city-sized. No enemies, weapons, run timer, likes, levels or HUD: the car
## just drives around freely (W/A/S/D).
##
## What it shows, in the isometric view:
## - the MVP map's ground art, buildings (see-through), boulders and edge walls,
##   built by mvp_map.gd from data/level/elevation_sample_map.json (its
##   layout_path);
## - every raised area (rooftop) and ramp of that file, drawn by
##   elevation_platform_drawing.gd's script drawing (the placeholder until the
##   art ticket), see-through like the buildings while they cover the car;
## - the car with its final sprite lifted by its height, its round shadow on
##   the ground under it (car_shadow.gd), and its real height on the map's
##   ground (car_height.gd via GroundHeight, read from the same file);
## - the camera following as in the elevation test scene (camera_follow.gd,
##   the saved zoom and camera options).
##
## Depth order (task T-197; Level design, Decisions, "Elevation sample map:
## depth order"): the buildings' slots and the raised areas are sorted
## together, back to front (restack, drawn_before), and each gets its own
## z_index, BUILDING_Z_STEP apart from DEPTH_Z_BASE. A stacked rooftop and a
## ramp standing on a rooftop come after the rooftop under them; an item
## wholly on another's far side (west or north) comes before it. The car and
## its shadow go just under the lowest item that covers them (they are behind
## it, lower than its top, and overlap it on screen), or over everything: so
## they are drawn over the areas they are on, above or in front of.
##
## See-through: every raised area and ramp covering the car fades
## (elevation_platform_drawing.gd, update_fade), and so does every building
## covering it (map_building.gd, update_fade), both with the car's shape drawn
## at its height, the same shape the depth order uses; the fade step is
## map_building.gd's faded_alpha for both.
##
## Not the project's main scene and not reachable from the menus (a proposal).
## No on-screen text. Run it from the editor (open the scene, F6) or with
## "$GODOT_BIN" --path game res://scenes/elevation_sample/elevation_sample_map.tscn.

const MapScene := preload("res://scenes/level/mvp_map.tscn")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const CarScript := preload("res://scripts/driving/car.gd")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const CarShadowScript := preload("res://scripts/driving/car_shadow.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const PlatformDrawingScript := preload("res://scripts/level/elevation_platform_drawing.gd")
const GameSettingsScript := preload("res://scripts/ui/game_settings.gd")
const CameraFollowScript := preload("res://scripts/driving/camera_follow.gd")

const LAYOUT_PATH := "res://data/level/elevation_sample_map.json"
const ISO_TRANSFORM := MvpMapScript.ISO_TRANSFORM

## Where the car starts (flat units) and its heading (proposal): on the road
## south of the north-west garage's 0-to-3 ramp (x -86 to -76, foot at y -54),
## 4 units from its foot, facing north, so W drives straight up the ramp.
const START_UNITS := Vector2(-81.0, -50.0)
const START_ROTATION := -PI / 2.0

## The car's footprint around its centre for the depth order, units.
const DEPTH_RADIUS := 0.5

## z_index of the first item (building slot or area) in depth order: one step
## over the map's own base, so a car under a boulder under the first item, and
## its shadow under it, still stay over the ground (z 0).
const DEPTH_Z_BASE := MvpMapScript.BUILDING_Z_BASE + MvpMapScript.BUILDING_Z_STEP

var map: Node2D
## The map's ground height (ground_height.gd, a GroundHeight; untyped so the
## scene loads before the class cache is built).
var ground_height
var physics_world: Node2D
var car: CharacterBody2D
var view_root: Node2D
## The raised areas' drawings (elevation_platform_drawing.gd), in the file's
## order: the platforms, then the ramps.
var areas: Array = []
## Every item in the depth order (building slots and areas), back to front.
var depth_items: Array = []
var shadow: Node2D
var car_sprite: Sprite2D
var camera: Camera2D
var camera_follow = CameraFollowScript.new()


func _ready() -> void:
	map = MapScene.instantiate()
	map.name = "Map"
	map.layout_path = LAYOUT_PATH
	add_child(map)
	map.set_view("iso")

	ground_height = GroundHeightScript.from_file(LAYOUT_PATH)

	physics_world = Node2D.new()
	physics_world.name = "PhysicsWorld"
	physics_world.visible = false
	add_child(physics_world)
	car = CarScript.new()
	car.name = "Car"
	physics_world.add_child(car)
	place_car(START_UNITS, START_ROTATION)

	view_root = Node2D.new()
	view_root.name = "View"
	add_child(view_root)
	for p in ground_height.platforms:
		_add_area("platform", p)
	for r in ground_height.ramps:
		_add_area("ramp", r)
	restack()

	shadow = CarShadowScript.new()
	shadow.name = "CarShadow"
	shadow.view_basis = ISO_TRANSFORM
	view_root.add_child(shadow)
	car_sprite = CarSpriteScript.new()
	car_sprite.name = "CarSprite"
	car_sprite.world_px_per_unit = CarScript.PX_PER_UNIT
	view_root.add_child(car_sprite)
	car_sprite.use_sheet("iso")

	# The scene fades the map's buildings itself (update_see_through), with the
	# car's shape at its height; map.car stays unset so the map does not fade
	# them a second time with the shape on the ground.

	camera = Camera2D.new()
	camera.name = "Camera"
	camera.ignore_rotation = true
	camera.position_smoothing_enabled = false
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	view_root.add_child(camera)
	camera.make_current()
	camera_follow.changed.connect(_apply_zoom)
	camera_follow.set_base_size(GameSettingsScript.load_zoom())
	camera_follow.load_saved()

	get_tree().physics_interpolation = true
	sync_view()
	car_sprite.reset_physics_interpolation()
	shadow.reset_physics_interpolation()
	camera.reset_physics_interpolation()
	get_viewport().size_changed.connect(_apply_zoom)
	car.stepped.connect(func() -> void: sync_view(false))


func _add_area(kind: String, block: Dictionary) -> void:
	var d = PlatformDrawingScript.new()
	d.name = "%s_%s" % [kind, str(block.id).replace("-", "_")]
	# The area's own art (task T-198): art/elevation_sample/<id>.png with its
	# record, built from this map's file. The elevation test's art
	# (art/elevation/) is drawn for that scene's own sizes, so it is not used.
	# With the art missing the script drawing is drawn instead (the fallback).
	d.setup(kind, block, ISO_TRANSFORM, PlatformDrawingScript.SAMPLE_ART_DIR, str(block.id))
	view_root.add_child(d)
	areas.append(d)


## Puts the car at a flat position (units) with a heading, at rest on the
## ground there (for the start and the screenshot fixtures).
func place_car(units: Vector2, rot: float) -> void:
	car.model.set_position(units)
	car.model.rotation = rot
	car.model.set_velocity(Vector2.ZERO)
	car.rotation = rot
	car.position = units * CarScript.PX_PER_UNIT
	car.ground = ground_height  # resets the height onto the ground there


static func drawn_ground(units: Vector2) -> Vector2:
	return ISO_TRANSFORM * (units * CarScript.PX_PER_UNIT)


# ---- Depth order -------------------------------------------------------------

## An item's footprint in units: a building slot's or an area's rectangle.
static func item_rect(item) -> Rect2:
	if item.get("footprint") != null:
		return item.footprint
	return item.rect()


## The height an item stands on: 0 for buildings and street areas, the area
## under it for a stacked rooftop or a ramp standing on a rooftop.
func item_base(item) -> float:
	if item.get("footprint") != null:
		return 0.0
	if item.kind == "ramp":
		return float(item.block.bottom_height)
	var on := str(item.block.get("on", ""))
	if on == "":
		return 0.0
	for p in ground_height.platforms:
		if p.id == on:
			return float(p.height)
	return 0.0


## True when item a must be drawn before (under) item b: a stands lower inside
## b's rectangle (a rooftop under a rooftop or a ramp standing on it), or a is
## wholly on b's far side (west or north of it) and b is not on a's.
func drawn_before(a, b) -> bool:
	var ra := item_rect(a)
	var rb := item_rect(b)
	var overlap := ra.position.x < rb.end.x and rb.position.x < ra.end.x \
		and ra.position.y < rb.end.y and rb.position.y < ra.end.y
	if overlap:
		return item_base(a) < item_base(b)
	var a_far := ra.end.x <= rb.position.x or ra.end.y <= rb.position.y
	var b_far := rb.end.x <= ra.position.x or rb.end.y <= ra.position.y
	return a_far and not b_far


## Sorts the map's building slots and the raised areas together, back to front
## (drawn_before, ties by the centre's x + y), and gives each its z_index; then
## puts the boulders and the pavement signs back in their places in that order.
func restack() -> void:
	var signs := {}
	if map.alert_signs_root != null:
		for sp in map.alert_signs_root.get_children():
			for s in map.fade_items():
				if s.z_index + 1 == sp.z_index:
					signs[sp] = s
	var items: Array = map.fade_items().duplicate()
	items.append_array(areas)
	var n := items.size()
	var before_count := []
	before_count.resize(n)
	before_count.fill(0)
	var edges := []
	for i in n:
		edges.append([])
	for i in n:
		for j in n:
			if i != j and drawn_before(items[i], items[j]):
				edges[i].append(j)
				before_count[j] += 1
	var done := []
	done.resize(n)
	done.fill(false)
	depth_items = []
	for _k in n:
		var best := -1
		for i in n:
			if done[i] or before_count[i] > 0:
				continue
			if best < 0 or _centre_sum(items[i]) < _centre_sum(items[best]):
				best = i
		if best < 0:
			# A cycle (should not happen): take the nearest-to-the-back left.
			for i in n:
				if not done[i] and (best < 0 or _centre_sum(items[i]) < _centre_sum(items[best])):
					best = i
		done[best] = true
		depth_items.append(items[best])
		for j in edges[best]:
			before_count[j] -= 1
	for k in depth_items.size():
		depth_items[k].z_index = DEPTH_Z_BASE + MvpMapScript.BUILDING_Z_STEP * k
	for sp in map.boulder_sprites:
		sp.z_index = boulder_z(sp)
	for sp in signs:
		sp.z_index = signs[sp].z_index + 1


static func _centre_sum(item) -> float:
	var c := item_rect(item).get_center()
	return c.x + c.y


## A z_index over every building and area.
func top_z_index() -> int:
	return DEPTH_Z_BASE + MvpMapScript.BUILDING_Z_STEP * depth_items.size()


## A boulder sprite's z_index: the map's (under the buildings that cover it),
## and under every raised area it is behind and overlaps on screen. A boulder
## nothing covers goes over every item, areas included (the map's own top is
## only over its buildings).
func boulder_z(sp) -> int:
	var z: int = map._boulder_z(sp.centre_units, sp.outline)
	if z >= map.top_z_index():
		z = top_z_index()
	for a in areas:
		if a.is_behind(sp.centre_units, 0.0, 0.0) \
				and not Geometry2D.intersect_polygons(a.silhouette(), sp.outline).is_empty():
			z = mini(z, a.z_index - 1)
	return z


## The car's drawn shape on screen at a height (units): the map's 1 by 3 unit
## car shape lifted by that height.
func car_shape_at(height: float) -> PackedVector2Array:
	return MvpMapScript.car_screen_shape_at(car.model.get_position(), car.rotation,
		height * CarScript.PX_PER_UNIT)


## The z_index for the car drawn at `height` (units): just under the lowest
## building, boulder or raised area that covers it, otherwise over them all.
func z_for(height: float) -> int:
	var units: Vector2 = car.model.get_position()
	var shape := car_shape_at(height)
	var z := top_z_index()
	for b in map.fade_items():
		if b.covers(units, shape):
			z = mini(z, b.z_index - 1)
	var box := MvpMapScript._bounds(shape)
	for s in map.boulder_sprites:
		if s.covers(units, shape, box):
			z = mini(z, s.z_index - 1)
	for a in areas:
		if a.covers(units, DEPTH_RADIUS, height, shape):
			z = mini(z, a.z_index - 1)
	return z


func update_depth() -> void:
	var units: Vector2 = car.model.get_position()
	car_sprite.z_index = z_for(car.height)
	shadow.z_index = z_for(ground_height.height_at(units)) - 1


## See-through: each raised area, ramp and building covering the car fades,
## the others fade back, by `delta` seconds. The areas with their own cover
## test (behind and lower than the top), the buildings with theirs (behind),
## both against the car's shape at its height, as the depth order (z_for).
func update_see_through(delta: float) -> void:
	var units: Vector2 = car.model.get_position()
	var shape := car_shape_at(car.height)
	for a in areas:
		a.update_fade(units, DEPTH_RADIUS, car.height, shape, delta)
	for b in map.fade_items():
		b.update_fade(units, shape, delta)


## The raised areas and ramps that covered the car at the last update_see_through().
func covering_areas() -> Array:
	return areas.filter(func(a) -> bool: return a.covering)


## The map's buildings (slots or blocks) that covered the car at the last update_see_through().
func covering_buildings() -> Array:
	return map.fade_items().filter(func(b) -> bool: return b.covering)


## After each physics step: the car's drawing (lifted by its height), its
## shadow (on the ground under it), the depth order and the camera (following
## the car's map position on height-0 ground, as the elevation test scene).
func sync_view(snap_camera: bool = true) -> void:
	var units: Vector2 = car.model.get_position()
	var at_ground := drawn_ground(units)
	car_sprite.place(at_ground, car.height)
	car_sprite.set_in_air(car_sprite.is_in_air(car.height, ground_height.height_at(units)))
	car_sprite.set_heading(car.rotation)
	shadow.place(units, ground_height.height_at(units))
	update_depth()
	update_see_through(car.model.dt)
	var frac: float = CameraFollowScript.speed_fraction_of(car.model)
	if snap_camera:
		camera_follow.snap(at_ground, frac)
	else:
		camera_follow.step(at_ground, frac, car.model.dt)
	camera.position = camera_follow.position
	if snap_camera or camera_follow.dynamic:
		_apply_zoom()


func _apply_zoom() -> void:
	var h := get_viewport().get_visible_rect().size.y
	var z: float = h / (2.0 * camera_follow.size * CarScript.PX_PER_UNIT)
	camera.zoom = Vector2(z, z)
