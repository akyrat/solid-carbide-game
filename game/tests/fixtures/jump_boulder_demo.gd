extends Node
## Screenshot and GIF fixture for T-478 (Drifting, Content, "The Jump clears obstacles"): a run
## with Jump at tier 1, a boulder on an open stretch of street, the car driving at it with W held
## and pressing Space `press_before` units short of it. Frame N is physics step N. With
## `record_dir` set (relative to the repo root) every `record_every`th frame is saved there.

@export var tier := 1
@export var press_before := 7.5
@export var record_dir := ""
@export var record_every := 2
@export var record_frames := 0

var game: Node
var car: CharacterBody2D
var boulder_x := 0.0
var _step := 0
var _pressed := false


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()
	for i in tier:
		game.run.state.grant_power_up("jump")
	game.run.minions.enabled = false
	game.run.kaiju_boss.enabled = false
	car = game.run.car
	car.use_keyboard = false
	car.set_physics_process(false)
	var map = game.run.map
	var g = game.run.elevation.ground_height
	var found := false
	for y in range(-90, 90, 3):
		for x in range(-90, 40, 3):
			if found:
				break
			var ok := true
			for dx in range(-3, 24, 3):
				var p := Vector2(x + dx, y)
				if g.height_at(p) != 0.0 or g.is_ramp(p) or not map.is_open_spot(p, 2.5):
					ok = false
					break
			if ok:
				found = true
				car.model.set_position(Vector2(x, y))
				car.model.rotation = 0.0
				car.model.set_velocity(Vector2.ZERO)
				car.height_model.reset(Vector2(x, y))
				car._sync_from_model()
				boulder_x = x + 14.0
				map.add_meteor_boulder(Vector2(boulder_x, y))
	if record_dir != "":
		if record_dir.is_relative_path():
			record_dir = ProjectSettings.globalize_path("res://").path_join("..").path_join(record_dir).simplify_path()
		DirAccess.make_dir_recursive_absolute(record_dir)


func _process(_delta: float) -> void:
	if car == null or not is_instance_valid(car):
		return
	if not _pressed and boulder_x - car.model.x <= press_before:
		car.press_jump()
		_pressed = true
	car.scripted_input = [true, false, 0.0]
	car.model.rotation = 0.0
	car.physics_step()
	_step += 1
	if record_dir != "" and _step <= record_frames and _step % record_every == 0:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(record_dir.path_join("frame_%04d.png" % _step))
