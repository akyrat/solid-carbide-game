extends Node2D
## The drift prototype (task T-012): the Unity car on a flat, empty ground, with
## a tuning panel and a flat / isometric view switch.
##
## The physics always runs in a flat top-down world (the Car node, under
## PhysicsWorld, which is never drawn). The View node draws that world either
## flat or in a 2:1 isometric projection; switching only changes the drawing.
## The camera sits exactly on the drawn car, never rotates and has no smoothing,
## like the Unity camera (report section 7).

const CarScript := preload("res://scripts/driving/car.gd")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const GroundGridScript := preload("res://scripts/driving/ground_grid.gd")
const TuningPanelScript := preload("res://scripts/driving/tuning_panel.gd")

const ACTION_TOGGLE_PANEL := "toggle_tuning_panel"
const ACTION_TOGGLE_VIEW := "toggle_view"

## The standard 2:1 isometric projection, the same one the isometric car sheet
## uses: screen = (x - y, (x + y) / 2), in flat world pixels.
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)

## "flat" or "iso".
var view := "flat"
## Camera zoom as Unity's orthographic size: half the visible height, in units.
var zoom := 14.4
var physics_interpolation := false

var physics_world: Node2D
var car: CharacterBody2D
var view_root: Node2D
var ground: Node2D
var car_sprite: Sprite2D
var camera: Camera2D
var panel: CanvasLayer
var hint: CanvasLayer


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
	car_sprite = CarSpriteScript.new()
	car_sprite.name = "CarSprite"
	car_sprite.world_px_per_unit = CarScript.PX_PER_UNIT
	view_root.add_child(car_sprite)

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
	hint_label.text = "W/S drive, A/D steer   Tab: tuning panel   V: flat / isometric view"
	hint_label.position = Vector2(8, 4)
	hint_label.add_theme_font_size_override("font_size", 12)
	hint.add_child(hint_label)
	add_child(hint)

	set_physics_interpolation(physics_interpolation)
	set_view(view)
	set_zoom(zoom)
	get_viewport().size_changed.connect(_apply_zoom)
	car.stepped.connect(sync_view)


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
	car_sprite.use_sheet(v)
	sync_view()
	car_sprite.reset_physics_interpolation()
	camera.reset_physics_interpolation()
	if panel != null and panel.view_toggle != null:
		panel.view_toggle.set_pressed_no_signal(v == "iso")


## Places the drawn car and the camera on the car's current position.
func sync_view() -> void:
	var drawn := view_transform() * car.position
	car_sprite.position = drawn
	car_sprite.set_heading(car.rotation)
	camera.position = drawn
	ground.follow(car.position)


func set_zoom(orthographic_size: float) -> void:
	zoom = orthographic_size
	_apply_zoom()


## Godot's zoom is a magnification: visible height in pixels / (2 * size * px per unit).
func _apply_zoom() -> void:
	var height := get_viewport().get_visible_rect().size.y
	var z := height / (2.0 * zoom * CarScript.PX_PER_UNIT)
	camera.zoom = Vector2(z, z)


func set_physics_interpolation(on: bool) -> void:
	physics_interpolation = on
	get_tree().physics_interpolation = on
	if panel != null and panel.interpolation_toggle != null:
		panel.interpolation_toggle.set_pressed_no_signal(on)
