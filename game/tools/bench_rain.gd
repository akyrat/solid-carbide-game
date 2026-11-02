extends SceneTree
## T-507: the rain's cost per frame. Plays the game's own run (car parked, weapons off, minions
## seeded, so every block carries the same load), headless, and switches the rain on and off in
## alternating blocks of frames through the saved setting (GameSettings.save_rain_enabled).
## Prints the mean and median frame time with and without rain, and the rain's own time per
## frame (its _process and _draw, measured inside rain.gd).
##
## Run, from the repo root:
##   bash game/tools/bench_rain.sh [--blocks=6] [--frames=300]
## (godot --headless --path game -s res://tools/bench_rain.gd -- [--blocks=6] [--frames=300])
## Headless, the rain is given a 1920 x 1080 screen (its drop and splash counts), so it carries a
## player's load; the renderer is the dummy one, so this is the CPU side only. The saves go to user://bench_rain_*, never the player's.

const GameScene := preload("res://scenes/game/game.tscn")

var blocks := 6
var frames_per_block := 300
## Frames skipped at the start of each block (the switch settling).
const SETTLE := 20

var game: Node = null
var run: Node2D = null
var _frame := 0
var _last := 0
var _on_ms: Array = []
var _off_ms: Array = []
var _rain_us: Array = []
var _draws_on := 0
var _draws_off := 0
var _drops_on := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--blocks="):
			blocks = int(a.get_slice("=", 1))
		elif a.begins_with("--frames="):
			frames_per_block = int(a.get_slice("=", 1))
	PlayerProgress.path = "user://bench_rain_progress.json"
	RunHistory.path = "user://bench_rain_history.json"
	GameSettings.path = "user://bench_rain_settings.cfg"
	GameFlow.tutorial_enabled = false
	process_frame.connect(_setup, CONNECT_ONE_SHOT)


func _setup() -> void:
	game = GameScene.instantiate()
	root.add_child(game)
	game.start_run()
	run = game.run
	run.car.use_keyboard = false
	run.minions.rng.seed = 507
	run.weapons.enabled = false
	run.state.advance(120.0)
	# Headless, the window is 64 x 64: give the rain a 1080p screen's worth of drops and
	# splashes, the load a player's screen carries.
	run.rain.screen_size_override = Vector2(1920, 1080)
	physics_frame.connect(_hold)
	process_frame.connect(_on_frame)
	GameSettings.save_rain_enabled(true)
	_last = Time.get_ticks_usec()


func _hold() -> void:
	if run != null and is_instance_valid(run):
		run.car.scripted_input = [false, false, 0.0]
		if run.state.is_running():
			run.state.health = run.state.max_health


func _on_frame() -> void:
	var now := Time.get_ticks_usec()
	var ms := (now - _last) / 1000.0
	_last = now
	var block := _frame / frames_per_block
	var in_block := _frame % frames_per_block
	var rain_on := block % 2 == 0
	if in_block == 0:
		GameSettings.save_rain_enabled(rain_on)
	elif in_block >= SETTLE:
		if rain_on:
			_on_ms.append(ms)
			_rain_us.append(run.rain.last_process_usec + run.rain.last_draw_usec)
		else:
			_off_ms.append(ms)
	if game.pause_screen != null and is_instance_valid(game.pause_screen) and game.pause_screen.is_paused():
		game.pause_screen.toggle()
	var screen = run.level_up_screen
	if screen.is_open():
		if screen.is_animating():
			screen.skip_animation()
		else:
			screen.take_highlighted()
	if rain_on:
		_draws_on = run.rain.draw_count
		_drops_on = maxi(_drops_on, run.rain.drops.size())
	_frame += 1
	if _frame >= blocks * frames_per_block:
		process_frame.disconnect(_on_frame)
		_report()
		GameSettings.save_rain_enabled(true)
		root.remove_child(game)
		game.free()
		quit()


func _report() -> void:
	var on := _stats(_on_ms)
	var off := _stats(_off_ms)
	var rain := _stats(_rain_us.map(func(u): return u / 1000.0))
	print("bench_rain: drops=%d screen=%s pixel=%.0f draws=%d" % [
		_drops_on, str(run.rain.screen_size()), run.rain.pixel_size(), _draws_on])
	print("bench_rain: rain on  frames=%d mean=%.3f ms median=%.3f ms p95=%.3f ms" % on)
	print("bench_rain: rain off frames=%d mean=%.3f ms median=%.3f ms p95=%.3f ms" % off)
	print("bench_rain: difference mean=%.3f ms median=%.3f ms" % [on[1] - off[1], on[2] - off[2]])
	print("bench_rain: rain's own process+draw frames=%d mean=%.3f ms median=%.3f ms p95=%.3f ms" % rain)


func _stats(a: Array) -> Array:
	var s := a.duplicate()
	s.sort()
	var n := s.size()
	if n == 0:
		return [0, 0.0, 0.0, 0.0]
	var total := 0.0
	for v in s:
		total += v
	return [n, total / n, s[n / 2], s[int(n * 0.95)]]
