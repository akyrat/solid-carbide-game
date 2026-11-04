extends Node
## Video fixture (task T-528): the real run, the real car and HUD, with the Polarized Steering
## Wheel at tier 1 for 10 s then tier 2 for 10 s. A bot coasts, steers until the nose is 62+
## degrees off, and presses W to fire a burst as soon as the wheel's cooldown allows (the same
## input logic as game/tools/speed_bot.gd), so the power-up slot icon is seen going dark and
## filling back up, with the ready flash. A few minions stand around; the car's health is topped
## up and it is put back near the start when it drifts far. Record it with
## record_wheel_cooldown_video.sh.

const TIER_SECONDS := 10.0
const WHEEL := "polarized_steering_wheel"
const HOME := Vector2(-20, 0)

var run: Node2D
var _phase := "HOLD"
var _n := 0
var _t := 0.0
var _tier := 1
var _dir := 1.0


func _ready() -> void:
	run = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	await get_tree().process_frame
	run.minions.enabled = false
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	run.state.set_power_up_tier(WHEEL, 1)
	car.polarized.set_tier(1)
	_home()
	run.camera_follow.dynamic = false
	run.set_zoom(9.0)
	run.sync_view()
	for p in [Vector2(-8, 3), Vector2(2, -4), Vector2(10, 5), Vector2(-2, 6)]:
		run.minions.spawn_minion_at(p)
	car.stepped.connect(_on_stepped)


func _home() -> void:
	var car: CharacterBody2D = run.car
	car.model.set_position(HOME)
	car.model.rotation = 0.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()


func _on_stepped() -> void:
	var car: CharacterBody2D = run.car
	var wheel = car.polarized
	_t += car.model.dt
	if _tier == 1 and _t >= TIER_SECONDS:
		_tier = 2
		run.state.set_power_up_tier(WHEEL, 2)
		wheel.set_tier(2)
	run.state.health = run.state.max_health
	if car.model.get_velocity().length() < 1.0 and _phase == "HOLD" and _n > 100 or \
			(Vector2(car.model.x, car.model.y)).length() > 45.0:
		_home()
		_n = 0
		_phase = "HOLD"
	var w := true
	var steer := 0.0
	match _phase:
		"HOLD":
			_n += 1
			if _n >= 20 and wheel.is_ready():
				_phase = "COAST"
				_n = 0
				_dir = -_dir
		"COAST":
			w = false
			steer = _dir
			_n += 1
			var ang: float = wheel.angle_between(car.model.rotation, car.model.get_velocity())
			if ang >= 62.0 or _n > 58:
				_phase = "PRESS"
		"PRESS":
			_phase = "AFTER"
			_n = 0
		"AFTER":
			_n += 1
			if _n >= 2:
				_phase = "HOLD"
				_n = 0
	car.scripted_input = [w, false, steer]
	run.minions.update_drawing()
