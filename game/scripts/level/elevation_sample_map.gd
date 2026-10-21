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
## Depth order (task T-197) and see-through: elevation_layer.gd (task T-206
## took them out of this scene, so the run shares them). The scene keeps its
## own functions for them as thin calls to its layer (`elevation`).
##
## Not the project's main scene and not reachable from the menus (a proposal).
## No on-screen text. Run it from the editor (open the scene, F6) or with
## "$GODOT_BIN" --path game res://scenes/elevation_sample/elevation_sample_map.tscn.

const MapScene := preload("res://scenes/level/mvp_map.tscn")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const CarScript := preload("res://scripts/driving/car.gd")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const CarShadowScript := preload("res://scripts/driving/car_shadow.gd")
const ElevationLayerScript := preload("res://scripts/level/elevation_layer.gd")
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
const DEPTH_RADIUS := ElevationLayerScript.DEPTH_RADIUS

## z_index of the first item (building slot or area) in depth order.
const DEPTH_Z_BASE := ElevationLayerScript.DEPTH_Z_BASE

var map: Node2D
## The map's elevation (elevation_layer.gd): the areas, their depth order and see-through.
var elevation
## The map's ground height (ground_height.gd, a GroundHeight; untyped so the
## scene loads before the class cache is built), the layer's.
var ground_height
var physics_world: Node2D
var car: CharacterBody2D
var view_root: Node2D
## The raised areas' drawings (elevation_platform_drawing.gd), in the file's
## order: the platforms, then the ramps (the layer's).
var areas: Array:
	get:
		return elevation.areas if elevation != null else []
## Every item in the depth order (building slots and areas), back to front.
var depth_items: Array:
	get:
		return elevation.depth_items if elevation != null else []
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

	# The rooftops and ramps (elevation_layer.gd): drawn in the map's place in
	# the tree, sorted with its buildings.
	elevation = ElevationLayerScript.new()
	elevation.name = "Elevation"
	map.add_child(elevation)
	elevation.setup(map, LAYOUT_PATH)
	ground_height = elevation.ground_height

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


# ---- Depth order and see-through (elevation_layer.gd) ------------------------

static func item_rect(item) -> Rect2:
	return ElevationLayerScript.item_rect(item)


func item_base(item) -> float:
	return elevation.item_base(item)


func drawn_before(a, b) -> bool:
	return elevation.drawn_before(a, b)


func restack() -> void:
	elevation.restack()


func top_z_index() -> int:
	return elevation.top_z_index()


func boulder_z(sp) -> int:
	return elevation.boulder_z(sp)


## The car's drawn shape on screen at a height (units).
func car_shape_at(height: float) -> PackedVector2Array:
	return ElevationLayerScript.car_shape_at(car.model.get_position(), car.rotation, height)


## The z_index for the car drawn at `height` (units).
func z_for(height: float) -> int:
	return elevation.z_for(car.model.get_position(), car.rotation, height)


func update_depth() -> void:
	var units: Vector2 = car.model.get_position()
	car_sprite.z_index = z_for(car.height)
	shadow.z_index = z_for(ground_height.height_at(units)) - 1


## See-through for the car at its height, by `delta` seconds.
func update_see_through(delta: float) -> void:
	elevation.update_see_through(car.model.get_position(), car.rotation, car.height, delta)


func covering_areas() -> Array:
	return elevation.covering_areas()


func covering_buildings() -> Array:
	return elevation.covering_buildings()


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
