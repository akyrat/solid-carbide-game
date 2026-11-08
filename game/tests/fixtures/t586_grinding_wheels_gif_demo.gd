extends Node
## GIF fixture (task T-586, Grinding Wheels): a run on the game's map with one long rail of its own
## in place of the map's (a copy in user://, as t578_launch_gif_demo.gd), Jump tier 1 (the hop onto
## the rail) and Grinding Wheels owned. The car drives north with W held, hops with Space held and
## catches the rail (bar at 1), grinds `grind_seconds` (3.4 s by default: the sparks yellow, orange
## after 1 s, red after 2 s), turns the nose a little east with D near the end, then Space is let go:
## the launch at the grind's speed x the stacks' multiplier (2x at 3 stacks). T586_SCENE=plain records
## the same without the power-up, for comparison. A readout at the bottom (a recording aid, never in
## the game) shows the grind's seconds, stacks, speed and the launch's speed.
## The scene quits `after_end` frames after the landing (or after max_steps).
##   "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/t586_grinding_wheels_gif.tscn
## then: python game/tools/make_turn_gif.py C:/abs/dir out.gif --glob "f*.png" --every 2 --size 640 420 --scale 1 --ms 40

const GAME_MAP := "res://data/level/kaiju_city_map.json"
const TEST_MAP := "user://t586_map_with_rail.json"
const RAILS := [
	{"id": "long", "x1": 5.0, "x2": 5.0, "y1": -2.0, "y2": -90.0, "z1": 1.0, "z2": 1.0},
]

@export var after_end := 40
@export var max_steps := 900
@export var hop_step := 30
## Seconds on the rail before Space is let go; D turns the nose for turn_steps just before.
@export var grind_seconds := 3.4
@export var turn_steps := 6

var run: Node2D
var label: Label
var scene := "wheels"
var _steps := 0
var _end_step := -1
var _on_rail := 0
var _launched := false
var _launch_at := Vector2.ZERO
var _text := ""
var _launch_text := ""


func _ready() -> void:
	GameFlow.tutorial_enabled = false
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GAME_MAP))
	scene = "plain" if OS.get_environment("T586_SCENE") == "plain" else "wheels"
	data["rails"] = RAILS
	var f := FileAccess.open(TEST_MAP, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	run = GameFlow.add_run(self, PlayerProgress.new(), TEST_MAP)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.state.set_power_up_tier("jump", 1)
	if scene == "wheels":
		run.state.set_power_up_tier("grinding_wheels", 1)
	run.facing_arrow.set_enabled(true)
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = true
	car.model.set_position(Vector2(5.0, 8.0))
	car.model.rotation = -PI / 2.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	car.scripted_input = [true, false, 0.0]
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	label = Label.new()
	label.position = Vector2(200, 498)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	layer.add_child(label)
	car.stepped.connect(_on_stepped)
	car.jump_started.connect(_on_jump)


func _on_stepped() -> void:
	_steps += 1
	var car = run.car
	run.state.health = run.state.max_health
	if _steps == hop_step:
		car.press_jump()
		car.scripted_jump_held = true
	var steer := 0.0
	var ride_steps := roundi(grind_seconds / car.model.dt)
	if car.grind.active:
		_on_rail += 1
		if _on_rail > ride_steps - turn_steps and _on_rail <= ride_steps:
			steer = -1.0  # D: the nose right of north, toward the east
		elif _on_rail > ride_steps:
			car.scripted_jump_held = false  # let go of Space: the launch
		var w = car.grinding_wheels
		_text = "grind %.1f s   stacks %d   speed %.1f" % [car.grind.seconds, w.stacks(car.grind.seconds),
			car.grind.speed]
	car.scripted_input = [not car.airborne and not _launched, false, steer]
	if _launched and not car.airborne and _end_step < 0:
		print("t586_grinding_wheels_gif_demo: %s, landed %.1f units away" % [_launch_text,
			car.model.get_position().distance_to(_launch_at)])
		_end_step = _steps
	var head := "Grinding Wheels" if scene == "wheels" else "no power-up"
	label.text = "%s   %s" % [head, _launch_text if _launched else _text]
	if _end_step < 0 and _steps >= max_steps:
		print("t586_grinding_wheels_gif_demo: no end in %d steps" % max_steps)
		_end_step = _steps


func _on_jump(kind: String, at_units: Vector2, _at_height: float) -> void:
	if kind != "rail_launch":
		return
	_launched = true
	_launch_at = at_units
	var g = run.car.grind
	var w = run.car.grinding_wheels
	var v: Vector2 = run.car.model.get_velocity()
	_launch_text = "after %.2f s: %d stacks, grind %.1f -> launched at %.1f (x%.2f)" % [g.seconds,
		w.stacks(g.seconds), g.speed, v.length(), w.launch_multiplier(g.seconds)]
	print("t586_grinding_wheels_gif_demo: %s" % _launch_text)


func _process(_delta: float) -> void:
	if run == null:
		return
	var ps := run.get_node_or_null("PauseScreenLayer")
	if ps != null and ps.has_method("is_paused") and ps.is_paused():
		ps.toggle()
	if _end_step >= 0 and _steps - _end_step >= after_end:
		DirAccess.remove_absolute(TEST_MAP)
		get_tree().quit()
