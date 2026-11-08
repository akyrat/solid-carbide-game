extends RefCounted
## T-574 tweak 10/11: records a stand-in demo take for a trick slide through the practice session's own
## recorder (PracticeTake), driving the practice tests' scripted routes. Used by
## tools/make_standin_takes.gd and by tests/unit/run/test_standin_takes.gd. Since T-590's charged
## jump (tweak 11) the hop is a tap (pressed and let go on the same step) and Space is held only in
## the air, which catches the rail.

const SessionScene := preload("res://scenes/run/practice_session.tscn")
const STANDIN_COMMENT := "STAND-IN take (T-574 tweak 10, step 2): recorded by game/tools/make_standin_takes.gd from the practice tests' scripted drive, not by the board. Record your own with F6 and F7 on this slide to replace it."
const AIR_ROUTE := [Vector2(-10, 8), Vector2(-20, 14), Vector2(-28, 19), Vector2(-26, 22.5),
	Vector2(-12, 22.5), Vector2(4, 22.5)]
const GRIND_ROUTE := [Vector2(0, 6), Vector2(-8, 6), Vector2(-14, 2), Vector2(-30, 2)]

var session: PracticeSession


static func is_standin(t: PracticeTake) -> bool:
	return t.comment.begins_with("STAND-IN")


## Records `trick`'s stand-in take into `dir` and returns what it did.
func record(trick: String, dir: String, parent: Node) -> Dictionary:
	session = SessionScene.instantiate()
	session.takes_dir = dir
	parent.add_child(session)
	session.setup(trick)
	session.start()
	session.set_focused(true)
	session.start_recording()
	match trick:
		"drift":
			_hold([false, false, 0.0], 0.3)
			_hold([true, false, 1.0], 4.0)  # W + A: a drift, past the 3 s goal
		"alt_drift":
			_hold([false, false, 0.0], 0.3)
			_hold([true, false, 1.0], 1.0)  # forward, release, backward (the tests' alternate drift)
			_hold([false, false, 1.0], 0.2)
			_hold([false, true, 1.0], 1.0)
		"air_spin":
			_route(AIR_ROUTE, 3, true)
		"grind":
			_route(GRIND_ROUTE, 99, false, 2, 6.0)
	_hold([false, false, 0.0], 1.2)  # coast a moment: the count and its popup show
	session.take.comment = STANDIN_COMMENT
	var successes := session.successes
	var seconds := session.drift_seconds
	var steps := session.take.steps()
	var err := session.stop_and_save()
	session.queue_free()
	return {"saved": err == OK, "steps": steps, "successes": successes, "drift_seconds": snappedf(seconds, 0.01)}


func _hold(keys: Array, seconds: float) -> void:
	for i in roundi(seconds * 50.0):
		var car = session.car
		car.use_keyboard = false
		car.scripted_input = keys
		car.scripted_jump_held = false
		car.physics_step()


## test_practice_session.gd's _route: steer through `pts`, slow until waypoint `slow_until`, spin in
## the air when `spin`, hop at waypoint `hop_at` (held through the grind), until the car lands.
func _route(pts: Array, slow_until: int, spin: bool, hop_at := -1, slow_speed := 8.0) -> void:
	var wi := 0
	var pressed := false
	var flew := false
	for i in 1500:
		var car = session.car
		car.use_keyboard = false
		var pos: Vector2 = car.model.get_position()
		if wi < pts.size() and pos.distance_to(pts[wi]) < 3.5:
			if wi == hop_at and not pressed and not car.airborne:
				car.press_jump()
				pressed = true
			wi += 1
		var steer := 0.0
		if car.airborne:
			steer = 1.0 if spin else 0.0
		elif wi < pts.size():
			var diff := wrapf((pts[wi] - pos).angle() - car.model.rotation, -PI, PI)
			steer = -clampf(diff * 3.0, -1.0, 1.0)
		var slow: bool = wi < slow_until and car.model.get_velocity().length() > slow_speed
		car.scripted_input = [not slow, false, steer]
		car.scripted_jump_held = pressed and (car.airborne or car.grind.active)
		car.physics_step()
		if car.airborne:
			flew = true
		if flew and not car.airborne and not car.grind.active:
			break
