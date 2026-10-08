extends CharacterBody2D
## The player's car in the flat top-down physics world. Runs CarModel once per
## physics step (50 per second) and moves this body with the result.
##
## The body is a 1 x 1 unit square, as in the Unity prototype (Drifting,
## Decisions). It draws nothing itself: the drift prototype scene draws the car
## in the flat or isometric view.
##
## Position here is in pixels, PX_PER_UNIT pixels per unit; the model works in
## units.

const CarModel := preload("res://scripts/driving/car_model.gd")

## Pixels per unit in the flat world. Matches the placeholder car sheets
## (game/art/placeholders/car/*.json, px_per_unit), so a 1-unit-wide car is
## 16 pixels wide at zoom 1.
const PX_PER_UNIT := 16.0

## Input actions (game/project.godot, input map).
const ACTION_ACCELERATE := "car_accelerate"
const ACTION_REVERSE := "car_reverse"
const ACTION_STEER_LEFT := "car_steer_left"
const ACTION_STEER_RIGHT := "car_steer_right"

## Emitted after every physics step, once the body has moved.
signal stepped
## Emitted when W makes the car jump up to cruise speed (for the boost effect,
## task T-008). See CarModel.cruise_jump for the arguments.
signal cruise_jump(from_speed: float, w_just_pressed: bool)

var model = CarModel.new()
## The handling values (shared with the tuning panel).
var tuning:
	get:
		return model.tuning

## When false, physics_step uses scripted_input instead of the keyboard (tests).
var use_keyboard := true
## [W held, S held, steer] used when use_keyboard is false.
var scripted_input := [false, false, 0.0]


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := RectangleShape2D.new()
	shape.size = Vector2(PX_PER_UNIT, PX_PER_UNIT)
	var collision := CollisionShape2D.new()
	collision.name = "Body1x1"
	collision.shape = shape
	add_child(collision)
	model.dt = 1.0 / float(Engine.physics_ticks_per_second)
	model.cruise_jump.connect(func(from_speed: float, just: bool) -> void:
		cruise_jump.emit(from_speed, just))
	_sync_from_model()


func _physics_process(_delta: float) -> void:
	physics_step()


## One physics step: read the controls, run the model, move the body.
func physics_step() -> void:
	var w: bool
	var s: bool
	var steer: float
	if use_keyboard:
		w = Input.is_action_pressed(ACTION_ACCELERATE)
		s = Input.is_action_pressed(ACTION_REVERSE)
		steer = Input.get_action_strength(ACTION_STEER_LEFT) - Input.get_action_strength(ACTION_STEER_RIGHT)
	else:
		w = scripted_input[0]
		s = scripted_input[1]
		steer = scripted_input[2]
	model.update_velocity(w, s, steer)
	rotation = model.rotation
	velocity = model.get_velocity() * PX_PER_UNIT
	# Move by the model's own (64-bit) step, so the position matches the Unity
	# maths exactly. No collisions in this prototype; when walls come, the
	# collision response belongs here.
	model.x += model.vx * model.dt
	model.y += model.vy * model.dt
	position = model.get_position() * PX_PER_UNIT
	stepped.emit()


func _sync_from_model() -> void:
	rotation = model.rotation
	position = model.get_position() * PX_PER_UNIT
	velocity = model.get_velocity() * PX_PER_UNIT
