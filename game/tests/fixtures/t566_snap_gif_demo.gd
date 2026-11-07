extends Node
## GIF fixture (task T-566, the rail snap on the drawing): a run on the game's map with two rails of
## its own in place of the map's (a copy in user://, as t551_overhaul_gif_demo.gd), W held, the car
## driving north on the street with Space held from the takeoff. A readout at the bottom (a recording
## aid, never in the game) shows the car's height, the last snap and how far over or under the bar
## the car was when it snapped.
##   1. From below: a high rail (bar at 5) runs north 4 units east of the car. Jump (tier 1) from the
##      street: as the car rises, its drawing crosses the high bar's, with the car about 4 units
##      under it, and it snaps up onto it.
##   2. From above: off the high rail's end with Space still held, the car flies on; a low rail (bar
##      at 1) runs on 3 units west of it, and the falling car's drawing crosses the low bar's with
##      the car about 3 units over it: it snaps down onto it.
## The scene quits `after_end` frames after the second snap (or after max_steps).
##   "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/t566_snap_gif.tscn
## then: python game/tools/make_turn_gif.py C:/abs/dir out.gif --glob "f*.png" --every 2 --size 640 420 --scale 1 --ms 40

const GAME_MAP := "res://data/level/kaiju_city_map.json"
const TEST_MAP := "user://t566_map_with_rails.json"
const RAILS := [
	{"id": "high", "x1": 5.0, "x2": 5.0, "y1": -4.0, "y2": -30.0, "z1": 5.0, "z2": 5.0},
	{"id": "low", "x1": 2.0, "x2": 2.0, "y1": -32.0, "y2": -76.0, "z1": 1.0, "z2": 1.0},
]

@export var after_end := 45
@export var max_steps := 900
@export var hop_step := 30

var run: Node2D
var label: Label
var _steps := 0
var _end_step := -1
var _last := "no snap yet"
## The car's height at the end of the last step, so a snap can say how far over or under the bar it was.
var _height_before := 0.0


func _ready() -> void:
	GameFlow.tutorial_enabled = false
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GAME_MAP))
	data["rails"] = RAILS
	var f := FileAccess.open(TEST_MAP, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	run = GameFlow.add_run(self, PlayerProgress.new(), TEST_MAP)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.state.set_power_up_tier("jump", 1)
	run.facing_arrow.set_enabled(true)
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = true
	car.model.set_position(Vector2(1.0, 8.0))
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
	label.position = Vector2(250, 498)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	layer.add_child(label)
	car.stepped.connect(_on_stepped)
	car.grind.grind_started.connect(func(i: int) -> void: _on_snap(i, _height_before))


func _on_stepped() -> void:
	_steps += 1
	var car = run.car
	run.state.health = run.state.max_health
	if _steps == hop_step:
		car.press_jump()
		car.scripted_jump_held = true
	car.scripted_input = [true, false, 0.0]
	label.text = "Space %s   height %.1f   %s" % ["held" if car.scripted_jump_held else "up", car.height, _last]
	if _end_step < 0 and _steps >= max_steps:
		print("t566_snap_gif_demo: no end in %d steps" % max_steps)
		_end_step = _steps
	_height_before = car.height


## The car's grind_started: prints and shows how far over or under the bar the car snapped from.
func _on_snap(i: int, height_before: float) -> void:
	var car = run.car
	var r: Dictionary = car.grind.rails[i]
	var bar: float = car.grind.height()
	var gap := height_before - bar
	_last = "snapped onto %s from %.1f %s the bar" % [r.id, absf(gap), "over" if gap > 0.0 else "under"]
	print("t566_snap_gif_demo: step %d, %s" % [_steps, _last])
	if car.grind.grinds >= 2:
		_end_step = _steps


func _process(_delta: float) -> void:
	if run == null:
		return
	var ps := run.get_node_or_null("PauseScreenLayer")
	if ps != null and ps.has_method("is_paused") and ps.is_paused():
		ps.toggle()
	if _end_step >= 0 and _steps - _end_step >= after_end:
		DirAccess.remove_absolute(TEST_MAP)
		get_tree().quit()
