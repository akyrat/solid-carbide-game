extends Node
## GIF fixture (task T-551, the grind overhaul): a run on the game's map with T-541's rail-3 and
## rail-4 added (a copy in user://, as t548_rail_gif_demo.gd), W held, the car driving north from
## below rail-3. A readout at the bottom (a recording aid, never in the game) shows whether Space is
## held, the tilt step, the grind and the last jump effect. The scene is the environment variable
## T551_SCENE:
##   "tilt"     Jump tier 2 (the longer hop): Space pressed and held, the car tilts in the air through
##              its 3 frames, Space let go still in the air, the frames play back; then a second hop
##              held to the landing (the tilt plays out on the ground).
##   "grind"    (default) Jump tier 1: a hop with Space held catches rail-3 (the arrow shows), D turns
##              the nose about 40 degrees right, Space let go launches it where it faces, Space held
##              again catches rail-4.
##   "back"     onto rail-3 as above, D spins the car round to face backwards (the arrow with it),
##              and letting go launches it backwards (south), against its travel.
##   "spin"     (T-555, the tilt art in several directions) Jump tier 2, the car standing: three hops, each with
##              Space held and A held in the air, so the tilted car turns through many directions, Space let
##              go before landing (the frames play back).
##   "effects"  five hops in a row, each with the next jump effect (dash_cloud, spring, jet_thrust,
##              stunt_sparks, shockwave_ring), the car standing still.
## The scene quits `after_end` frames after it is done (or after max_steps).
##   T551_SCENE=grind "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/t551_overhaul_gif.tscn
## then: python game/tools/make_turn_gif.py C:/abs/dir out.gif --glob "f*.png" --every 2 --size 640 420 --scale 1 --ms 40

const JumpEffectChoice := preload("res://scripts/driving/jump_effect_choice.gd")
const GAME_MAP := "res://data/level/kaiju_city_map.json"
const TEST_MAP := "user://t551_map_with_rails.json"
const RAILS := [
	{"id": "rail-3", "x1": 5.0, "x2": 5.0, "y1": -6.0, "y2": -60.0, "z1": 1.0, "z2": 1.0},
	{"id": "rail-4", "x1": 8.5, "x2": 8.5, "y1": -14.0, "y2": -68.0, "z1": 1.0, "z2": 1.0},
]

@export var after_end := 40
@export var max_steps := 900
@export var hop_step := 30

var run: Node2D
var scene := "grind"
var label: Label
var _steps := 0
var _end_step := -1
var _released := false
var _release_step := -10
var _turn_target := 40.0
var _effect_i := 0
var _next_hop := 0


func _ready() -> void:
	GameFlow.tutorial_enabled = false
	scene = OS.get_environment("T551_SCENE") if OS.get_environment("T551_SCENE") != "" else "grind"
	_turn_target = 185.0 if scene == "back" else 40.0
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GAME_MAP))
	data["rails"] = RAILS
	var f := FileAccess.open(TEST_MAP, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	run = GameFlow.add_run(self, PlayerProgress.new(), TEST_MAP)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.state.set_power_up_tier("jump", 2 if scene in ["tilt", "spin"] else 1)
	run.facing_arrow.set_enabled(true)
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = true
	var start := Vector2(5.0, 6.0)
	if scene in ["tilt", "effects", "spin"]:
		start = Vector2(-4.0, 6.0)  # beside the rails, on the street
	car.model.set_position(start)
	car.model.rotation = -PI / 2.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	car.scripted_input = [scene not in ["effects", "spin"], false, 0.0]
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	label = Label.new()
	label.position = Vector2(270, 498)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	layer.add_child(label)
	car.grind.grind_started.connect(func(i: int) -> void:
		if scene == "grind" and car.grind.grinds >= 2:
			_end_step = _steps + 30
		print("t551_overhaul_gif_demo: grind on %s at step %d" % [car.grind.rails[i].id, _steps]))
	car.grind.grind_ended.connect(func(reason: String, seconds: float, _l: float) -> void:
		print("t551_overhaul_gif_demo: grind ended (%s) at step %d, %.2f s, leaving at %s" % [reason, _steps, seconds, car.model.get_velocity()])
		if scene == "back":
			_end_step = _steps + 20)
	car.jump_started.connect(func(kind: String, _at: Vector2, _h: float) -> void:
		print("t551_overhaul_gif_demo: jump effect %s (%s) at step %d" % [JumpEffectChoice.equipped_id(), kind, _steps]))
	car.stepped.connect(_on_stepped)


func _on_stepped() -> void:
	_steps += 1
	var car = run.car
	run.state.health = run.state.max_health
	match scene:
		"tilt":
			_tilt_step(car)
		"effects":
			_effects_step(car)
		"spin":
			_spin_step(car)
		_:
			_rail_step(car)
	label.text = "Space %s   tilt frame %d   %s   effect %s" % [
		"held" if car.scripted_jump_held else "up", car.tilt.step,
		"grinding" if car.grind.active else ("in the air" if car.airborne else "on the ground"),
		JumpEffectChoice.equipped_id()]
	if _end_step < 0 and _steps >= max_steps:
		print("t551_overhaul_gif_demo: no end in %d steps" % max_steps)
		_end_step = _steps


func _tilt_step(car) -> void:
	if _steps == hop_step:
		car.press_jump()
		car.scripted_jump_held = true
	elif _steps == hop_step + 35:
		car.scripted_jump_held = false  # let go in the air: the frames play back
	elif _steps == hop_step + 110:
		car.press_jump()
		car.scripted_jump_held = true  # held to the landing
	elif _steps == hop_step + 110 + 85:
		car.scripted_jump_held = false
		_end_step = _steps


func _rail_step(car) -> void:
	if _steps == hop_step:
		car.press_jump()  # the hop toward rail-3
		car.scripted_jump_held = true
	elif _steps == _release_step + 8:
		car.scripted_jump_held = true  # held again to catch rail-4
	var g = car.grind
	if g.active and g.rails[g.rail_index].id == "rail-3":
		var off: float = rad_to_deg(g.body_heading - g.travel().angle())
		car.scripted_input = [true, false, -1.0 if g.seconds > 0.8 and off < _turn_target else 0.0]
		if not _released and off >= _turn_target:
			_released = true
			_release_step = _steps
			car.scripted_jump_held = false  # let go: the launch where the car faces
	else:
		car.scripted_input = [true, false, 0.0]


## T-555: hops 100 steps apart; Space and A held from the takeoff, Space let go 40 steps in.
func _spin_step(car) -> void:
	var t := _steps - hop_step
	if t < 0:
		return
	var hop := t / 100
	var into := t % 100
	if hop >= 3:
		if _end_step < 0:
			_end_step = _steps
		car.scripted_input = [false, false, 0.0]
		return
	if into == 0:
		car.press_jump()
		car.scripted_jump_held = true
	elif into == 40:
		car.scripted_jump_held = false
	car.scripted_input = [false, false, -1.0 if into < 45 else 0.0]


func _effects_step(car) -> void:
	if _steps < _next_hop or car.airborne:
		return
	if _effect_i >= JumpEffectChoice.IDS.size():
		if _end_step < 0:
			_end_step = _steps
		return
	JumpEffectChoice.override_id = JumpEffectChoice.IDS[_effect_i]
	_effect_i += 1
	car.press_jump()
	_next_hop = _steps + 60


func _process(_delta: float) -> void:
	if run == null:
		return
	var ps := run.get_node_or_null("PauseScreenLayer")
	if ps != null and ps.has_method("is_paused") and ps.is_paused():
		ps.toggle()
	if _end_step >= 0 and _steps - _end_step >= after_end:
		JumpEffectChoice.override_id = ""
		DirAccess.remove_absolute(TEST_MAP)
		get_tree().quit()
