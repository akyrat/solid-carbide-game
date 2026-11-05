extends Node
## GIF fixture (task T-539): a pair of the kaiju's meteors lands near the car (the faint
## cyan line shows they are paired), then the car drifts through the gap between them
## (real driving: W held and steering, so the car's own drift state is on): both boulders
## break, the beam runs from the pair to the kaiju and the kaiju flashes. The kaiju stands
## still and no new attack starts. Record it with game/tools/record_meteor_pair_gif.sh.

var run: Node2D
var met: Node
var pair: Dictionary
var _mid := Vector2.ZERO
var _side := Vector2.ZERO
var _t := 0.0
var _struck_at := -1.0
const START_DRIVE := 1.6


func _ready() -> void:
	var KaijuBoss = load("res://scripts/enemies/kaiju_boss.gd")
	KaijuBoss.playtest_override = -1.0
	run = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	await get_tree().process_frame
	run.minions.enabled = false
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	car.scripted_input = [false, false, 0.0]
	var boss: Node = run.kaiju_boss
	met = boss.meteors
	met.enabled = false
	met.rng.seed = int(OS.get_environment("PAIR_SEED")) if OS.get_environment("PAIR_SEED") != "" else 539
	var c: Vector2 = car.position / 16.0
	var pr = met.pick_pair()
	if pr == null:
		push_error("T-539 demo: no pair found")
		return
	pair = met.add_pair_warnings(pr[0], pr[1])
	for w in met.warnings:
		w.time_left = 0.6
	_mid = (pair.a + pair.b) / 2.0
	var along: Vector2 = (pair.b - pair.a).normalized()
	_side = Vector2(-along.y, along.x)
	if _side.dot(c - _mid) < 0.0:
		_side = -_side  # drive from the car's side of the pair to the far side
	# The car parked 9 units back from the gap, facing it; the kaiju beyond the pair.
	car.model.set_position(_mid + _side * 9.0)
	car.model.rotation = (-_side).angle()
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	boss.enabled = false
	# The kaiju off to one side of the car's path, so the beam crosses the screen.
	var along_dir: Vector2 = Vector2(-_side.y, _side.x)
	for d in [10.0, 12.0, 8.0, 14.0]:
		for sgn in [1.0, -1.0]:
			for back in [-2.0, 0.0, -4.0, 2.0]:
				var p: Vector2 = _mid + along_dir * d * sgn + _side * back
				if boss.kaiju == null and boss.is_free_spot(p):
					var k: Node = boss.appear_at(p)
					k.heading = -along_dir * sgn
					boss.update_drawing()

	run.camera_follow.dynamic = false
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	met.pair_struck.connect(func(_a, _b, dmg) -> void:
		_struck_at = _t
		print("T-539 demo: pair struck at %.2f s, kaiju took %.0f, health %.0f" % [_t, dmg, boss.kaiju.health]))
	car.stepped.connect(_on_stepped)
	print("T-539 demo: pair %s - %s (%.1f apart), car %s, kaiju %s" % [pair.a, pair.b, pair.a.distance_to(pair.b), car.model.get_position(), boss.kaiju.position_units() if boss.kaiju else null])


func _on_stepped() -> void:
	var car: CharacterBody2D = run.car
	_t += car.model.dt if car.model.dt > 0.0 else 1.0 / 60.0
	run.state.health = run.state.max_health
	if _t < START_DRIVE:
		car.scripted_input = [false, false, 0.0]
		return
	# Steer towards a point beyond the gap, always a little (so the car drifts), harder when off line.
	var target: Vector2 = _mid - _side * 12.0
	var to: Vector2 = target - car.model.get_position()
	var err: float = wrapf(to.angle() - car.model.rotation, -PI, PI)
	var steer: float = -clampf(err * 2.5, -1.0, 1.0)  # a positive steer turns the car clockwise (rotation down)
	if absf(steer) < 0.3:
		steer = 0.3 * (-1.0 if err >= 0.0 else 1.0)
	if OS.get_environment("PAIR_DEBUG") != "" and int(_t * 50) % 5 == 0:
		print("t %.2f pos %s rot %.2f drift %s d %.2f" % [_t, car.model.get_position(), car.model.rotation, car.model.is_drifting, _side.dot(car.model.get_position() - _mid)])
	var past: bool = _side.dot(car.model.get_position() - _mid) < -4.0
	if past:
		car.scripted_input = [false, false, 0.0]
	else:
		car.scripted_input = [true, false, steer]
