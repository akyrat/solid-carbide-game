extends SceneTree
## T-574 tweak 10, step 2: records the stand-in demo takes (data/tutorial_takes/<trick>.json) by
## driving the practice tests' scripted routes (test_practice_session.gd's AIR_ROUTE and GRIND_ROUTE,
## the alt drift's legs, a W + A drift) through the practice session's own recorder (PracticeTake),
## so each is a real take that replays on the real car. Each is marked as a stand-in in its
## "_comment"; the board's own recordings (F6, F7 in the slides) replace them.
##
## Run, from the repo root:
##   "<godot>" --headless --path game -s res://tools/make_standin_takes.gd -- [--tricks=alt_drift,grind] [--dir=res://...] [--force]
## A take that is already there and is not a stand-in (no stand-in comment: the board's own) is
## left alone unless --force. tests/unit/run/test_standin_takes.gd checks that each one does its trick.

const SessionScene := preload("res://scenes/run/practice_session.tscn")
const STANDIN_COMMENT := "STAND-IN take (T-574 tweak 10, step 2): recorded by game/tools/make_standin_takes.gd from the practice tests' scripted drive, not by the board. Record your own with F6 and F7 on this slide to replace it."
const AIR_ROUTE := [Vector2(-10, 8), Vector2(-20, 14), Vector2(-28, 19), Vector2(-26, 22.5),
	Vector2(-12, 22.5), Vector2(4, 22.5)]
const GRIND_ROUTE := [Vector2(0, 6), Vector2(-8, 6), Vector2(-14, 2), Vector2(-30, 2)]

var session: PracticeSession


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var tricks := ["drift", "alt_drift", "air_spin", "grind"]
	var dir := PracticeTake.TAKES_DIR
	var force := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tricks="):
			tricks = Array(a.trim_prefix("--tricks=").split(","))
		elif a.begins_with("--dir="):
			dir = a.trim_prefix("--dir=")
		elif a == "--force":
			force = true
	var code := 0
	for t in tricks:
		var existing := PracticeTake.load_take(t, dir)
		if existing != null and not is_standin(existing) and not force:
			print("%s: kept (a take that is not a stand-in is there; --force to replace it)" % t)
			continue
		var r := record(t, dir)
		print("%s: %s" % [t, r])
		if not r.get("saved", false):
			code = 1
	quit(code)


static func is_standin(t: PracticeTake) -> bool:
	return t.comment.begins_with("STAND-IN")


## Records `trick`'s stand-in take into `dir` and returns what it did.
func record(trick: String, dir: String) -> Dictionary:
	session = SessionScene.instantiate()
	session.takes_dir = dir
	root.add_child(session)
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
