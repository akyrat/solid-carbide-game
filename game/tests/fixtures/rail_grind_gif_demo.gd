extends Node
## GIF fixture (task T-541): rail grinding in a run on the game's map (the main menu's Start),
## Jump at tier 1 (as the playtest switch gives it), trick detection on, W held. The scene is
## the environment variable RAIL_SCENE:
##   "jump" (default)  from just south of the spawn point, driving north: a hop onto rail-3, a
##                     grind, D turning the nose a little to the right of the rail, then (once
##                     the Jump's cooldown is over) a Jump slightly to the right, onto rail-4,
##                     and a grind to its end;
##   "climb"           off roof-12's north edge onto rail-1, up to roof-13;
##   "still"           the car parked by rail-3 and rail-4 (RAIL_STILL="x,y": elsewhere), the
##                     camera zoomed out, for a screenshot:
##                     bash game/tools/screenshot.sh res://tests/fixtures/rail_grind_gif.tscn out.png 30
## The scene quits `after_end` frames after the last grind ends (or after max_steps).
##   "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/rail_grind_gif.tscn
## then: python game/tools/make_turn_gif.py C:/abs/dir out.gif --glob "f*.png" --every 2 --size 640 420 --scale 1 --ms 40
## RAIL_POPUP_PNG (an absolute PNG path) saves the frame `popup_frame` frames after a grind ends.

@export var after_end := 45
@export var popup_frame := 10
@export var max_steps := 900
## The physics step of the hop onto rail-3 ("jump").
@export var hop_step := 30

var game: Node
var run: Node2D
var scene := "jump"
var _steps := 0
var _grinds_ended := 0
var _end_step := -1
var _jumped_off := false
var _release_step := -10
var _popup_saved := false


func _ready() -> void:
	GameFlow.tutorial_enabled = false
	scene = OS.get_environment("RAIL_SCENE") if OS.get_environment("RAIL_SCENE") != "" else "jump"
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.state.set_power_up_tier("jump", 1)
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = true
	var start := Vector2(5.0, 6.0)
	if scene == "climb":
		start = Vector2(-36.0, 12.0)
	car.model.set_position(start)
	car.model.rotation = -PI / 2.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	car.scripted_input = [true, false, 0.0]
	if scene == "still":
		var at := Vector2(3.0, -20.0)
		var env := OS.get_environment("RAIL_STILL")  # "x,y": park the car there instead
		if env != "":
			at = Vector2(float(env.split(",")[0]), float(env.split(",")[1]))
		car.model.set_position(at)
		car._sync_from_model()
		car.ground = run.elevation.ground_height
		car.scripted_input = [false, false, 0.0]
		car.set_physics_process(false)
		run.camera_follow.dynamic = false
		run.set_zoom(20.0)
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	car.grind.grind_started.connect(func(i: int) -> void:
		print("rail_grind_gif_demo: grind on %s at step %d, %s" % [car.grind.rails[i].id, _steps, car.model.get_position()]))
	car.grind.grind_ended.connect(_on_grind_ended)
	run.state.combo_trick.connect(func(id: String, added: float, m: float) -> void:
		print("rail_grind_gif_demo: trick %s at step %d, +%.2f, combo %.2f" % [id, _steps, added, m]))
	car.stepped.connect(_on_stepped)


func _on_grind_ended(reason: String, seconds: float, length: float) -> void:
	_grinds_ended += 1
	print("rail_grind_gif_demo: grind ended (%s) at step %d, %.2f s, %.1f units" % [reason, _steps, seconds, length])
	var last := 1 if scene == "climb" else 2
	if _grinds_ended >= last:
		_end_step = _steps


func _on_stepped() -> void:
	_steps += 1
	var car = run.car
	run.state.health = run.state.max_health
	if scene == "jump":
		if _steps == hop_step:
			car.press_jump()  # the hop onto rail-3
			car.scripted_jump_held = true  # T-551: Space held to catch and grind
		elif _steps == _release_step + 1:
			car.scripted_jump_held = true  # held again to catch rail-4
		if car.grind.active and car.grind.rail_index >= 0 and car.grind.rails[car.grind.rail_index].id == "rail-3":
			# From 1 s on the rail, D turns the nose about 25 degrees to the right of the rail line
			# (east, rail-4's side; the board's tweak: A and D spin the car on the rail), then let go.
			var off: float = rad_to_deg(angle_difference(atan2(car.grind.travel().y, car.grind.travel().x), car.grind.body_heading))
			if car.grind.seconds > 1.0 and off < 25.0:
				car.scripted_input = [true, false, -1.0]
			else:
				car.scripted_input = [true, false, 0.0]
			if not _jumped_off and car.grind.seconds > 1.6:
				_jumped_off = true
				car.scripted_jump_held = false  # T-551: let go of Space: the launch
				_release_step = _steps
		elif car.grind.active:
			car.scripted_input = [true, false, 0.0]
	if _end_step < 0 and _steps >= max_steps:
		print("rail_grind_gif_demo: no end in %d steps" % max_steps)
		get_tree().quit()


func _process(_delta: float) -> void:
	if run == null:
		return
	# The window losing focus pauses the run (game_flow.gd): a recording carries on.
	if game.pause_screen != null and game.pause_screen.is_paused():
		game.pause_screen.toggle()
	if scene == "still":
		return
	if _end_step < 0:
		return
	var since := _steps - _end_step
	if since >= popup_frame and not _popup_saved:
		_popup_saved = true
		var path := OS.get_environment("RAIL_POPUP_PNG")
		if path != "":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(path)
	if since >= after_end:
		get_tree().quit()
