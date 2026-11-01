extends SceneTree
## A scripted run for the performance recorder (task T-468; game/docs/game-loop/perf-recorder.md):
## the game's own run on its own map, the car driven by a fixed pattern of drifts (W held,
## A and D in turns, a short reverse when it is stuck), every level-up's first card taken,
## the car kept alive, for a set time. With --record-perf it writes a recording like the
## board's (game/perf/<date-time>/), to compare with it or to measure the recorder's overhead.
##
## Usage (normally through tools/perf_sample_run.sh, from the repo root; needs a window):
##   godot --path game -s res://tools/perf_sample_run.gd -- [--record-perf] [--seconds=150]
##       [--start-at=300] [--all-weapons] [--no-hold-health] [--no-vsync] [--park] [--no-weapons]
## --start-at moves the run's clock on that many seconds at the start (300 = 5:00 in, when
## the spawn timer is fast; the kaiju then comes at 7:00, 120 s later). --all-weapons gives
## the car every weapon at the start, so every weapon's zone shows. It prints its own frame
## times (measured without the recorder), so a run with and one without --record-perf give
## the recorder's overhead (best with --no-vsync, so waiting for the screen hides nothing). The saves go to user://perf_sample_*, never the player's.

const GameScene := preload("res://scenes/game/game.tscn")
const WeaponsScript := preload("res://scripts/weapons/weapons.gd")

var seconds := 150.0
var start_at := 300.0
var all_weapons := false
var hold_health := true
## --no-vsync: frames as fast as they go, so the frame time is all work (for the overhead).
var no_vsync := false
## --park: the car stands still; --no-weapons: nothing shoots. Together the minions come in the
## same way every time, so a run with and one without the recorder carry the same load.
var park := false
var no_weapons := false

var game: Node = null
var run: Node2D = null
var _t0 := 0
var _last := 0
var _frame_ms: Array = []
var _stuck := 0.0
var _reverse_left := 0.0
var _done := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			seconds = float(a.get_slice("=", 1))
		elif a.begins_with("--start-at="):
			start_at = float(a.get_slice("=", 1))
		elif a == "--all-weapons":
			all_weapons = true
		elif a == "--no-hold-health":
			hold_health = false
		elif a == "--no-vsync":
			no_vsync = true
		elif a == "--park":
			park = true
		elif a == "--no-weapons":
			no_weapons = true
	PlayerProgress.path = "user://perf_sample_progress.json"
	RunHistory.path = "user://perf_sample_history.json"
	GameSettings.path = "user://perf_sample_settings.cfg"
	GameFlow.tutorial_enabled = false
	if all_weapons:
		WeaponsScript.all_weapons_override = 1
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


## Builds the game once the tree is running (nodes added in _initialize are not ready yet).
func _setup() -> void:
	if no_vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	game = GameScene.instantiate()
	root.add_child(game)
	game.start_run()
	run = game.run
	run.car.use_keyboard = false
	run.minions.rng.seed = 468
	if no_weapons:
		run.weapons.enabled = false
	if start_at > 0.0:
		run.state.advance(start_at)
	physics_frame.connect(_drive)
	process_frame.connect(_on_frame)
	_t0 = Time.get_ticks_usec()
	_last = _t0
	print("perf_sample_run: %.0f s from run time %.0f s, all weapons %s, recording %s" % [
		seconds, start_at, all_weapons, PerfRecorder.is_enabled()])


func _elapsed() -> float:
	return (Time.get_ticks_usec() - _t0) / 1000000.0


## The fixed drive: a 4-second pattern of left and right drifts with W held, and a reverse
## when the car has been nearly still for a second (stuck on a wall or in the swarm).
func _drive() -> void:
	if game == null or run == null or not is_instance_valid(run):
		return
	var car = run.car
	if hold_health and run.state.is_running():
		run.state.health = run.state.max_health
	if park:
		car.scripted_input = [false, false, 0.0]
		return
	var dt := 1.0 / Engine.physics_ticks_per_second
	var speed: float = car.model.get_velocity().length()
	_stuck = _stuck + dt if speed < 2.0 else 0.0
	if _stuck > 1.0:
		_reverse_left = 0.8
		_stuck = 0.0
	if _reverse_left > 0.0:
		_reverse_left -= dt
		car.scripted_input = [false, true, 1.0]
		return
	var t := fmod(_elapsed(), 4.0)
	var steer := 0.0
	if t < 1.5:
		steer = 1.0
	elif t >= 2.0 and t < 3.5:
		steer = -1.0
	car.scripted_input = [true, false, steer]


func _on_frame() -> void:
	if game == null:
		return
	var now := Time.get_ticks_usec()
	var ms := (now - _last) / 1000.0
	_last = now
	if _elapsed() > 2.0:
		_frame_ms.append(ms)
	if game.pause_screen != null and is_instance_valid(game.pause_screen) and game.pause_screen.is_paused():
		game.pause_screen.toggle()  # losing the window's focus pauses the run (T-416): go on
	if run != null and is_instance_valid(run):
		var screen = run.level_up_screen
		if screen.is_open():
			if screen.is_animating():
				screen.skip_animation()
			else:
				screen.take_highlighted()
	if not _done and (_elapsed() >= seconds or game.run == null):
		_done = true
		_report()
		root.remove_child(game)
		game.free()
		quit()


func _report() -> void:
	var s := _frame_ms.duplicate()
	s.sort()
	var n := s.size()
	if n == 0:
		print("perf_sample_run: no frames")
		return
	var total := 0.0
	for v in s:
		total += v
	var over := s.filter(func(v: float) -> bool: return v >= 25.0).size()
	var alive: int = run.minions.minions.size() if run != null and is_instance_valid(run) else -1
	print("perf_sample_run: frames=%d mean=%.3f ms median=%.3f p95=%.3f p99=%.3f max=%.3f spikes>=25ms=%d minions_alive_at_end=%d recording=%s" % [
		n, total / n, s[n / 2], s[int(n * 0.95)], s[int(n * 0.99)], s[n - 1], over, alive, PerfRecorder.is_enabled()])
