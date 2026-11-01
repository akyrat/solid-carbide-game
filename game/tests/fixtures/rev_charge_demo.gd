extends Node
## Screenshot and GIF fixture for Rev Charge (task T-460): a run started from
## the main menu with Rev Charge granted at `tier`, the car stepped once per
## drawn frame so frame N is physics step N: W alone for `drive_steps`, then
## W+S for a full charge plus `hold_extra_steps`, then S is released (W held)
## and the boost runs. With `record_dir` set, every `record_every`th frame is
## saved there as a PNG (frames for frames_to_gif.py) until `record_frames`.

@export var tier := 4
@export var drive_steps := 40
@export var hold_extra_steps := 15
@export var record_dir := ""
@export var record_every := 2
@export var record_frames := 0

var game: Node
var car: CharacterBody2D
var _step := 0
var _charge_steps := 0


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()  # straight into a run, past the tutorial slides (T-387)
	for i in tier:
		game.run.state.grant_power_up("rev_charge")
	car = game.run.car
	car.use_keyboard = false
	car.set_physics_process(false)
	_charge_steps = int(round(car.rev_charge.charge_seconds / car.model.dt)) + hold_extra_steps
	if record_dir != "":
		# Relative to the repo root (the folder above game/).
		record_dir = ProjectSettings.globalize_path("res://").path_join("..").path_join(record_dir).simplify_path()
		DirAccess.make_dir_recursive_absolute(record_dir)


func _process(_delta: float) -> void:
	if car == null or not is_instance_valid(car):
		return
	var w := true
	var s := _step >= drive_steps and _step < drive_steps + _charge_steps
	car.scripted_input = [w, s, 0.0]
	car.physics_step()
	_step += 1
	if record_dir != "" and _step <= record_frames and _step % record_every == 0:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(record_dir.path_join("frame_%04d.png" % _step))
