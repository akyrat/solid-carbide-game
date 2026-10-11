extends Node2D
## The run scene (task T-036): the MVP map with the drift car on it, the camera
## following the car as in the drift prototype, and the run's state
## (RunState, child "RunState").
##
## Physics runs in the flat top-down world (the map's Physics node and the
## car, under PhysicsWorld; neither is drawn). The map draws itself, and the
## View node draws the car on top of it, in the isometric view the drift
## prototype starts in. The camera sits exactly on the drawn car (no rotation,
## no smoothing).
##
## Other agents reach the run's state through `state`, or from anywhere in the
## tree with get_tree().get_first_node_in_group("run_state").

const MapScene := preload("res://scenes/level/mvp_map.tscn")
const CarScript := preload("res://scripts/driving/car.gd")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const RunStateScript := preload("res://scripts/run/run_state.gd")
const HudScene := preload("res://scenes/hud/hud.tscn")
const TrickPopupsScript := preload("res://scripts/hud/trick_popups.gd")

## Same 2:1 isometric projection as the drift prototype and the map.
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## Where the car starts, in units from the map's centre: the centre of the
## gravel square, the one open space on the map.
const START_POSITION_UNITS := Vector2.ZERO
## The car's heading at the start, in radians: nose along -y (up in the flat
## view), as in the drift prototype (CarModel's default).
const START_ROTATION := -PI / 2.0
## Camera zoom as Unity's orthographic size, the drift prototype's default.
const ZOOM := 14.4
const VIEW := "iso"

## Emitted after start_run() has rebuilt the map and the car, before the
## state's run_started, so listeners can pick up the new `map` and `car`.
signal world_rebuilt

var state: RunState
var hud: Hud
var map: Node2D
var physics_world: Node2D
var car: CharacterBody2D
var view_root: Node2D
var car_sprite: Sprite2D
var camera: Camera2D
var trick_popups: Node2D
## The camera zoom now, as Unity's orthographic size. The pause screen's zoom
## slider changes it through set_zoom() (task T-055).
var zoom := ZOOM
## The pause screen refreshes a tuning panel when there is one; the run has none.
var panel: CanvasLayer = null


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.03, 0.03, 0.06))
	get_tree().physics_interpolation = true

	physics_world = Node2D.new()
	physics_world.name = "PhysicsWorld"
	physics_world.visible = false
	add_child(physics_world)

	view_root = Node2D.new()
	view_root.name = "View"
	add_child(view_root)
	car_sprite = CarSpriteScript.new()
	car_sprite.name = "CarSprite"
	car_sprite.world_px_per_unit = CarScript.PX_PER_UNIT
	view_root.add_child(car_sprite)
	car_sprite.use_sheet(VIEW)

	trick_popups = TrickPopupsScript.new()
	trick_popups.name = "TrickPopups"
	view_root.add_child(trick_popups)

	camera = Camera2D.new()
	camera.name = "Camera"
	camera.ignore_rotation = true
	camera.position_smoothing_enabled = false
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	view_root.add_child(camera)
	camera.make_current()

	state = RunStateScript.new()
	state.name = "RunState"
	state.add_to_group("run_state")
	add_child(state)

	hud = HudScene.instantiate()
	add_child(hud)
	hud.bind(state)

	get_viewport().size_changed.connect(_apply_zoom)
	_apply_zoom()
	start_run()


## Starts a fresh run: a new map (every challenge open again), the car back
## at the start, and the state reset (full health, 8:00, 0 coins).
func start_run() -> void:
	_build_world()
	world_rebuilt.emit()
	state.start_run()


func _build_world() -> void:
	if map != null:
		remove_child(map)
		map.queue_free()
	if car != null:
		physics_world.remove_child(car)
		car.queue_free()

	map = MapScene.instantiate()
	map.name = "Map"
	add_child(map)
	move_child(map, 0)  # drawn under the car
	map.set_view(VIEW)

	car = CarScript.new()
	car.name = "Car"
	car.model.x = START_POSITION_UNITS.x
	car.model.y = START_POSITION_UNITS.y
	car.model.rotation = START_ROTATION
	physics_world.add_child(car)
	car.stepped.connect(sync_view)
	trick_popups.bind(car, func() -> Vector2: return car_sprite.position)
	map.car = car
	sync_view()
	car_sprite.reset_physics_interpolation()
	camera.reset_physics_interpolation()


## Places the drawn car and the camera on the car's current position.
func sync_view() -> void:
	var drawn := ISO_TRANSFORM * car.position
	car_sprite.position = drawn
	car_sprite.set_heading(car.rotation)
	camera.position = drawn


## Sets the camera zoom (Unity's orthographic size), as the pause screen's slider does.
func set_zoom(orthographic_size: float) -> void:
	zoom = orthographic_size
	_apply_zoom()


## Godot's zoom is a magnification: visible height in pixels / (2 * size * px per unit).
func _apply_zoom() -> void:
	var height := get_viewport().get_visible_rect().size.y
	var z := height / (2.0 * zoom * CarScript.PX_PER_UNIT)
	camera.zoom = Vector2(z, z)
