extends Node2D
## The drift prototype (task T-012): the Unity car on a flat, empty ground, with
## a tuning panel and a flat / isometric view switch.
##
## The physics always runs in a flat top-down world (the Car node, under
## PhysicsWorld, which is never drawn). The View node draws that world either
## flat or in a 2:1 isometric projection; switching only changes the drawing.
## By default the camera sits exactly on the drawn car, never rotates and has no
## smoothing, like the Unity camera (report section 7); the camera options (task
## T-123, `camera_follow`) can add smoothing and the dynamic camera.
##
## A test room (task T-033: a few walls and a boulder, test_room.gd) lets the
## board try the car's bounce. Its static bodies are in PhysicsWorld; the View
## draws them.
##
## Drift marks (task T-117) are drawn on the ground, under the test room and
## the car, in the current view. Drift smoke (task T-121) is drawn over the
## test room and under the car.

const CarScript := preload("res://scripts/driving/car.gd")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const GroundGridScript := preload("res://scripts/driving/ground_grid.gd")
const TuningPanelScript := preload("res://scripts/driving/tuning_panel.gd")
const TestRoomScript := preload("res://scripts/driving/test_room.gd")
const TrickPopupsScript := preload("res://scripts/hud/trick_popups.gd")
const PauseScreenScript := preload("res://scripts/ui/pause_screen.gd")
const GameSettingsScript := preload("res://scripts/ui/game_settings.gd")
const DriftMarksScene := preload("res://scenes/driving/drift_marks.tscn")
const CameraFollowScript := preload("res://scripts/driving/camera_follow.gd")
const DriftSmokeScene := preload("res://scenes/driving/drift_smoke.tscn")

const ACTION_TOGGLE_PANEL := "toggle_tuning_panel"
const ACTION_TOGGLE_VIEW := "toggle_view"

## The standard 2:1 isometric projection, the same one the isometric car sheet
## uses: screen = (x - y, (x + y) / 2), in flat world pixels.
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)

## "flat" or "iso".
var view := "iso"
## Camera zoom as Unity's orthographic size: half the visible height, in units.
var zoom := 14.4
var physics_interpolation := true

var physics_world: Node2D
var car: CharacterBody2D
var view_root: Node2D
var ground: Node2D
var drift_marks: Node2D
var test_room: Node2D
var drift_smoke: Node2D
var car_sprite: Sprite2D
var trick_popups: Node2D
var camera: Camera2D
var panel: CanvasLayer
var hint: CanvasLayer
var pause_screen: CanvasLayer
## The camera options (task T-123): where the camera is and its size, read from
## the saved settings at start. The pause screen's controls (task T-124) call
## its API directly.
var camera_follow = CameraFollowScript.new()


func _ready() -> void:
	physics_world = Node2D.new()
	physics_world.name = "PhysicsWorld"
	physics_world.visible = false
	add_child(physics_world)
	car = CarScript.new()
	car.name = "Car"
	physics_world.add_child(car)

	view_root = Node2D.new()
	view_root.name = "View"
	add_child(view_root)
	ground = GroundGridScript.new()
	ground.name = "Ground"
	ground.px_per_unit = CarScript.PX_PER_UNIT
	view_root.add_child(ground)
	drift_marks = DriftMarksScene.instantiate()
	drift_marks.name = "DriftMarks"
	view_root.add_child(drift_marks)
	drift_marks.bind(car)
	test_room = TestRoomScript.new()
	test_room.name = "TestRoom"
	view_root.add_child(test_room)
	test_room.build_bodies(physics_world)
	drift_smoke = DriftSmokeScene.instantiate()
	drift_smoke.name = "DriftSmoke"
	view_root.add_child(drift_smoke)
	drift_smoke.bind(car, drift_marks)
	car_sprite = CarSpriteScript.new()
	car_sprite.name = "CarSprite"
	car_sprite.world_px_per_unit = CarScript.PX_PER_UNIT
	view_root.add_child(car_sprite)

	trick_popups = TrickPopupsScript.new()
	trick_popups.name = "TrickPopups"
	view_root.add_child(trick_popups)
	trick_popups.bind(car, func() -> Vector2: return car_sprite.position)

	camera = Camera2D.new()
	camera.name = "Camera"
	camera.ignore_rotation = true
	camera.position_smoothing_enabled = false
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	view_root.add_child(camera)
	camera.make_current()

	panel = TuningPanelScript.new()
	panel.name = "TuningPanelLayer"
	add_child(panel)
	panel.setup(self)
	panel.visible = false

	hint = CanvasLayer.new()
	hint.name = "Hint"
	var hint_label := Label.new()
	hint_label.text = "W/S drive, A/D steer   Tab: tuning panel   V: flat / isometric view   Esc: pause"
	hint_label.position = Vector2(8, 4)
	hint_label.add_theme_font_size_override("font_size", 12)
	hint.add_child(hint_label)
	add_child(hint)

	zoom = GameSettingsScript.load_zoom()
	camera_follow.changed.connect(_apply_zoom)
	pause_screen = PauseScreenScript.new()
	pause_screen.name = "PauseScreenLayer"
	add_child(pause_screen)
	pause_screen.setup(self)

	set_physics_interpolation(physics_interpolation)
	set_view(view)
	set_zoom(zoom)
	camera_follow.load_saved()  # after the zoom, so the dynamic camera starts at its own size
	panel.refresh()
	get_viewport().size_changed.connect(_apply_zoom)
	car.stepped.connect(_on_car_moved)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_TOGGLE_PANEL):
		panel.toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(ACTION_TOGGLE_VIEW):
		set_view("flat" if view == "iso" else "iso")
		get_viewport().set_input_as_handled()


## The transform from flat world pixels to drawn pixels for the current view.
func view_transform() -> Transform2D:
	return ISO_TRANSFORM if view == "iso" else Transform2D.IDENTITY


## Switches the drawing between "flat" and "iso". Never touches the car.
func set_view(v: String) -> void:
	view = v
	ground.transform = view_transform()
	drift_marks.transform = view_transform()
	test_room.transform = view_transform()
	drift_smoke.view_transform = view_transform()
	car_sprite.use_sheet(v)
	sync_view()
	car_sprite.reset_physics_interpolation()
	camera.reset_physics_interpolation()
	if panel != null and panel.view_toggle != null:
		panel.view_toggle.set_pressed_no_signal(v == "iso")


## After each physics step: the drawn car, and the camera one step on.
func _on_car_moved() -> void:
	sync_view(false)


## Places the drawn car on the car's current position, and the camera: straight
## on it when snap_camera is true (or both camera options are off), otherwise
## one physics step of the camera options toward it.
func sync_view(snap_camera: bool = true) -> void:
	var drawn := view_transform() * car.position
	car_sprite.position = drawn
	car_sprite.set_heading(car.rotation)
	var frac: float = CameraFollowScript.speed_fraction_of(car.model)
	if snap_camera:
		camera_follow.snap(drawn, frac)
	else:
		camera_follow.step(drawn, frac, car.model.dt)
	camera.position = camera_follow.position
	if snap_camera or camera_follow.dynamic:
		_apply_zoom()
	ground.follow(car.position)


func set_zoom(orthographic_size: float) -> void:
	zoom = orthographic_size
	camera_follow.set_base_size(orthographic_size)  # applies the zoom


## Godot's zoom is a magnification: visible height in pixels / (2 * size * px per unit).
## The size is the slider's zoom, or the dynamic camera's when it is on.
func _apply_zoom() -> void:
	var height := get_viewport().get_visible_rect().size.y
	var z: float = height / (2.0 * camera_follow.size * CarScript.PX_PER_UNIT)
	camera.zoom = Vector2(z, z)


func set_physics_interpolation(on: bool) -> void:
	physics_interpolation = on
	get_tree().physics_interpolation = on
	if panel != null and panel.interpolation_toggle != null:
		panel.interpolation_toggle.set_pressed_no_signal(on)
