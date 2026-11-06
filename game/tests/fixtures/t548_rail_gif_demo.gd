extends Node
## GIF fixture (task T-548): the landing boost and the Jump off a rail where the car faces, in a
## run on the game's map with T-541's rail-3 and rail-4 added (the map has no rails of its own
## since T-546; the copy is written to user://, as test_run_rails.gd does). Jump at tier 1, W held.
## A readout in the top-left corner (a recording aid, never in the game) shows the speed along the
## rail and the boost left. The scene is the environment variable T548_SCENE:
##   "boost" (default)  a hop from the street onto rail-3: the speed jumps by land_boost on the
##                      landing and declines; D turns the nose about 40 degrees right of the rail,
##                      a Jump goes where it faces, onto rail-4: the second landing boosts again;
##   "back"             onto rail-3, D spins the car round until it faces backwards, and a Jump
##                      sends it off backwards (south), against its travel along the rail.
## The scene quits `after_end` frames after the last grind ends (or after max_steps).
##   "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/t548_rail_gif.tscn
## then: python game/tools/make_turn_gif.py C:/abs/dir out.gif --glob "f*.png" --every 2 --size 640 420 --scale 1 --ms 40

const GAME_MAP := "res://data/level/kaiju_city_map.json"
const TEST_MAP := "user://t548_map_with_rails.json"
const RAILS := [
	{"id": "rail-3", "x1": 5.0, "x2": 5.0, "y1": -6.0, "y2": -60.0, "z1": 1.0, "z2": 1.0},
	{"id": "rail-4", "x1": 8.5, "x2": 8.5, "y1": -14.0, "y2": -68.0, "z1": 1.0, "z2": 1.0},
]

@export var after_end := 45
@export var max_steps := 900
## The physics step of the hop onto rail-3.
@export var hop_step := 30

var run: Node2D
var scene := "boost"
var label: Label
var _steps := 0
var _end_step := -1
var _jumped_off := false
var _turn_target := 40.0


func _ready() -> void:
	GameFlow.tutorial_enabled = false
	scene = OS.get_environment("T548_SCENE") if OS.get_environment("T548_SCENE") != "" else "boost"
	_turn_target = 185.0 if scene == "back" else 40.0
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GAME_MAP))
	data["rails"] = RAILS
	var f := FileAccess.open(TEST_MAP, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	run = GameFlow.add_run(self, PlayerProgress.new(), TEST_MAP)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.state.set_power_up_tier("jump", 1)
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = true
	car.model.set_position(Vector2(5.0, 6.0))
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
	label.position = Vector2(230, 606)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	layer.add_child(label)
	car.grind.grind_started.connect(func(i: int) -> void:
		if scene == "boost" and car.grind.grinds >= 2:
			_end_step = _steps + 25  # about 1.4 s on rail-4, then stop
		print("t548_rail_gif_demo: grind on %s at step %d, speed %.2f" % [car.grind.rails[i].id, _steps, car.grind.speed]))
	car.grind.grind_ended.connect(_on_grind_ended)
	car.stepped.connect(_on_stepped)


func _on_grind_ended(reason: String, seconds: float, _length: float) -> void:
	print("t548_rail_gif_demo: grind ended (%s) at step %d, %.2f s, leaving along the nose at %.2f units/s" % [reason, _steps, seconds, run.car.grind.leave_velocity(reason).length()])
	if scene == "back":
		_end_step = _steps


func _on_stepped() -> void:
	_steps += 1
	var car = run.car
	run.state.health = run.state.max_health
	if _steps == hop_step:
		car.press_jump()  # the hop onto rail-3
	var g = car.grind
	if g.active and g.rails[g.rail_index].id == "rail-3":
		var off: float = rad_to_deg(g.body_heading - g.travel().angle())
		car.scripted_input = [true, false, -1.0 if g.seconds > 0.8 and off < _turn_target else 0.0]
		if not _jumped_off and off >= _turn_target:
			_jumped_off = true
			car.press_jump()
	else:
		car.scripted_input = [true, false, 0.0]
	if g.active:
		label.text = "on %s   speed along it %.1f   boost left %.1f" % [g.rails[g.rail_index].id, g.speed, g.boost_left]
	else:
		label.text = "off the rail   speed %.1f" % car.model.get_velocity().length()
	if _end_step < 0 and _steps >= max_steps:
		print("t548_rail_gif_demo: no end in %d steps" % max_steps)
		get_tree().quit()


func _process(_delta: float) -> void:
	if run == null:
		return
	# The window losing focus pauses the run (game_flow.gd): a recording carries on.
	var ps := run.get_node_or_null("PauseScreenLayer")
	if ps != null and ps.has_method("is_paused") and ps.is_paused():
		ps.toggle()
	if _end_step >= 0 and _steps - _end_step >= after_end:
		DirAccess.remove_absolute(TEST_MAP)
		get_tree().quit()
