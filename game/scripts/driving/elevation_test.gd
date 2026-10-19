extends Node2D
## The elevation test scene (task T-185; Drifting, Decisions, "Elevation"):
## the drift prototype's car, camera and isometric view (W/A/S/D), on the
## platform and the ramp of game/data/level/elevation_test.json, with the car's
## real height (car_height.gd, tasks T-183 and T-184).
##
## The illusion of height: the car's drawing is lifted up the screen by its
## height (16 px per unit, car_sprite.gd, lift_for_height), while its shadow
## (car_shadow.gd) stays at its map position on the ground under it: the
## platform's top or the ramp when over them, the street otherwise. The platform
## and the ramp are script-drawn placeholders (elevation_platform_drawing.gd),
## in depth order with the car and its shadow (update_depth).
##
## Not the project's main scene and not reachable from the menus. No on-screen
## text. Run it from the editor (open the scene, F6) or with
## "$GODOT_BIN" --path game res://scenes/elevation_test/elevation_test.tscn.

const CarScript := preload("res://scripts/driving/car.gd")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const CarShadowScript := preload("res://scripts/driving/car_shadow.gd")
const GroundGridScript := preload("res://scripts/driving/ground_grid.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const PlatformDrawingScript := preload("res://scripts/level/elevation_platform_drawing.gd")
const GameSettingsScript := preload("res://scripts/ui/game_settings.gd")
const CameraFollowScript := preload("res://scripts/driving/camera_follow.gd")

## The drift prototype's isometric projection: screen = (x - y, (x + y) / 2).
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)

## Where the car starts (flat units) and its heading: on the street east of
## the ramp's foot, facing west, so W drives straight up the ramp (proposal).
const START_UNITS := Vector2(26.0, 0.0)
const START_ROTATION := PI

## The car's footprint around its centre for the depth order, units (its 1 by
## 1 physics body).
const DEPTH_RADIUS := 0.5

## z_index layout: the street far under everything; each area i at
## Z_STEP * (i + 1); the shadow and the car in the slot just under the first
## area they are behind (shadow under car), or over every area.
const Z_GROUND := -100
const Z_STEP := 3

## The option (T-187): draw the car bigger when high. Off by default; tick it in
## the editor's Inspector (the scene's root) to try it. The shadow keeps its size.
@export var draw_bigger_when_high := false
## Extra drawing scale per unit of height when the option is on (a proposal):
## 0.05, so the platform's top (3 units) draws the car 1.15 times as big.
const HEIGHT_SCALE_PER_UNIT := 0.05

var ground_height: GroundHeight
var physics_world: Node2D
var car: CharacterBody2D
var view_root: Node2D
var ground: Node2D
## The area drawings, back to front.
var areas: Array = []
var shadow: Node2D
var car_sprite: Sprite2D
var camera: Camera2D
var camera_follow = CameraFollowScript.new()


func _ready() -> void:
	ground_height = GroundHeightScript.from_file()

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
	ground = GroundGridScript.new()
	ground.name = "Ground"
	ground.px_per_unit = CarScript.PX_PER_UNIT
	ground.transform = ISO_TRANSFORM
	ground.z_index = Z_GROUND
	view_root.add_child(ground)

	var list: Array = []
	for p in ground_height.platforms:
		list.append(["platform", p])
	for r in ground_height.ramps:
		list.append(["ramp", r])
	# Back to front: the area whose centre is further north-west first.
	list.sort_custom(func(a, b) -> bool:
		var ca: Vector2 = (a[1].rect as Rect2).get_center()
		var cb: Vector2 = (b[1].rect as Rect2).get_center()
		return ca.x + ca.y < cb.x + cb.y)
	for i in list.size():
		var d = PlatformDrawingScript.new()
		d.name = "%s_%s" % [list[i][0], list[i][1].id]
		d.setup(list[i][0], list[i][1], ISO_TRANSFORM)
		d.z_index = Z_STEP * (i + 1)
		view_root.add_child(d)
		areas.append(d)

	shadow = CarShadowScript.new()
	shadow.name = "CarShadow"
	shadow.view_basis = ISO_TRANSFORM
	view_root.add_child(shadow)
	car_sprite = CarSpriteScript.new()
	car_sprite.name = "CarSprite"
	car_sprite.world_px_per_unit = CarScript.PX_PER_UNIT
	view_root.add_child(car_sprite)
	car_sprite.use_sheet("iso")
	car_sprite.height_scale_per_unit = HEIGHT_SCALE_PER_UNIT if draw_bigger_when_high else 0.0

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
## ground there (for the start and for the screenshot fixtures).
func place_car(units: Vector2, rot: float) -> void:
	car.model.set_position(units)
	car.model.rotation = rot
	car.model.set_velocity(Vector2.ZERO)
	car.rotation = rot
	car.position = units * CarScript.PX_PER_UNIT
	car.ground = ground_height  # resets the height onto the ground there


## The drawn pixel of a flat position (units) on height-0 ground.
static func drawn_ground(units: Vector2) -> Vector2:
	return ISO_TRANSFORM * (units * CarScript.PX_PER_UNIT)


## After each physics step: the car's drawing (lifted by its height), its
## shadow (on the ground under it), the depth order and the camera.
##
## The camera follows the car's map position on height-0 ground, not the
## lifted drawing, so a jump shows as the car rising on screen (a proposal).
func sync_view(snap_camera: bool = true) -> void:
	var units: Vector2 = car.model.get_position()
	var at_ground := drawn_ground(units)
	car_sprite.place(at_ground, car.height)
	car_sprite.set_heading(car.rotation)
	var under: float = ground_height.height_at(units)
	shadow.place(units, car.rotation, under)
	update_depth()
	var frac: float = CameraFollowScript.speed_fraction_of(car.model)
	if snap_camera:
		camera_follow.snap(at_ground, frac)
	else:
		camera_follow.step(at_ground, frac, car.model.dt)
	camera.position = camera_follow.position
	if snap_camera or camera_follow.dynamic:
		_apply_zoom()
	ground.follow(car.position)


## The z_index for something at centre (flat units) and height (units): just
## under the first area (back to front) it is behind, otherwise over them all.
## offset 0 is the shadow's place, 1 the car's (over its shadow).
func z_for(centre: Vector2, height: float, offset: int) -> int:
	for i in areas.size():
		if areas[i].is_behind(centre, DEPTH_RADIUS, height):
			return Z_STEP * (i + 1) - 2 + offset
	return Z_STEP * (areas.size() + 1) - 2 + offset


func update_depth() -> void:
	var units: Vector2 = car.model.get_position()
	shadow.z_index = z_for(units, ground_height.height_at(units), 0)
	car_sprite.z_index = z_for(units, car.height, 1)


func _apply_zoom() -> void:
	var h := get_viewport().get_visible_rect().size.y
	var z: float = h / (2.0 * camera_follow.size * CarScript.PX_PER_UNIT)
	camera.zoom = Vector2(z, z)
