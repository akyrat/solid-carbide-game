extends Node
## GIF fixture for the charged jump (task T-590): a run started from the main menu with Jump at
## tier 1, the car standing still, stepped once per drawn frame so frame N is physics step N:
## a tap at `tap_step` (pressed and let go at once: the x1 hop), then, once it has landed, Space
## pressed at `charge_step` and held for `charge_steps` (3 s: the car tilts, Tweak 1), then let go (the
## x1.5 hop, with a bigger jump effect). With `record_dir` set (relative to the repo root), every `record_every`th frame is
## saved there as a PNG for frames_to_gif.py, until `record_frames`.

@export var tap_step := 10
@export var charge_step := 80
@export var charge_steps := 150
@export var record_dir := ""
@export var record_every := 2
@export var record_frames := 0

var game: Node
var car: CharacterBody2D
var _step := 0


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()
	game.run.state.grant_power_up("jump")
	car = game.run.car
	car.use_keyboard = false
	car.set_physics_process(false)
	if record_dir != "":
		if record_dir.is_relative_path():
			record_dir = ProjectSettings.globalize_path("res://").path_join("..").path_join(record_dir).simplify_path()
		DirAccess.make_dir_recursive_absolute(record_dir)


func _process(_delta: float) -> void:
	if car == null or not is_instance_valid(car):
		return
	game.run.state.health = game.run.state.max_health
	if _step == tap_step:
		car.press_jump()
	if _step == charge_step:
		car.press_jump()
		car.scripted_jump_held = true
	if _step == charge_step + charge_steps:
		car.scripted_jump_held = false
	car.scripted_input = [false, false, 0.0]
	car.physics_step()
	_step += 1
	if _step % 10 == 0:
		print("t590_demo: step %d height %.2f charging %s fraction %.2f" % [_step, car.height, car.jump.charging, car.jump.charge_fraction()])
	if record_dir != "" and _step <= record_frames and _step % record_every == 0:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(record_dir.path_join("frame_%04d.png" % _step))
