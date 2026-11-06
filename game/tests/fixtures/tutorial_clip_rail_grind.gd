extends Node
## Tutorial clip fixture (task T-543): the real car landing on a rail on the game's own map and
## grinding along it, for the trick list's GRIND! clip. Same recording as the other clips
## (tools/record_tutorial_clips.py, Godot's movie maker, 480 x 320 crop of the window), but the
## scene is a run started from the main menu on the game's map (the rails are the level's), with
## the HUD hidden, no minions and no kaiju, Jump at tier 1 (as the playtest switch gives it),
## W held, one Jump from south of the spawn onto rail-3 (the T-541 GIF fixture's route), and the
## camera following. It quits `after_end` steps after the grind ends.
## Prints the same "tutorial_clip_demo: ..." lines the recorder reads (tricks, key timeline).

@export var hop_step := 15
@export var after_end := 12
@export var max_steps := 700
## Seconds on the rail before the Jump that leaves it.
@export var jump_off_after := 1.6

var game: Node
var run: Node2D
var _steps := 0
var _end_step := -1
var _jumped_off := false
var _keys: Array[String] = []


func _ready() -> void:
	GameFlow.tutorial_enabled = false
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.hud.visible = false
	run.trick_popups.visible = false
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
	car.grind.grind_started.connect(func(i: int) -> void:
		print("tutorial_clip_demo: grind on %s at step %d" % [car.grind.rails[i].id, _steps]))
	car.grind.grind_ended.connect(func(reason: String, seconds: float, length: float) -> void:
		_end_step = _steps
		print("tutorial_clip_demo: grind ended (%s) at step %d, %.2f s, %.1f units" % [reason, _steps, seconds, length]))
	run.state.combo_trick.connect(func(id: String, _added: float, _m: float) -> void:
		print("tutorial_clip_demo: trick %s at step %d" % [id, _steps]))
	car.stepped.connect(_on_stepped)


func _on_stepped() -> void:
	_steps += 1
	_keys.append("W")
	var car = run.car
	run.state.health = run.state.max_health
	if _steps == hop_step:
		car.press_jump()
	if car.grind.active and car.grind.seconds > jump_off_after and car.jump.cooldown_left <= 0.0 and not _jumped_off:
		_jumped_off = true
		car.press_jump()  # off the rail: the grind pays
	if _end_step >= 0 and _steps - _end_step >= after_end or _steps >= max_steps:
		print("tutorial_clip_demo: keys " + ",".join(_keys))
		get_tree().quit()


func _process(_delta: float) -> void:
	# The window losing focus pauses the run (game_flow.gd): a recording carries on.
	if run != null and game.pause_screen != null and game.pause_screen.is_paused():
		game.pause_screen.toggle()
