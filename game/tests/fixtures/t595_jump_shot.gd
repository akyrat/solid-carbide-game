extends Node
## Screenshot fixture (task T-595): a run with Jump at tier 1, car standing still. Saves a frame a few
## steps after a tap jump and after a full-charge jump, to <out>_tap.png and <out>_charge.png, where
## <out> comes from the user argument --out=<path prefix> (after the "--").

@export var tap_step := 10
@export var charge_step := 80
@export var charge_steps := 150
@export var shot_after := 5

var game: Node
var car: CharacterBody2D
var out := "screenshots/t595"
var _step := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()
	game.run.state.grant_power_up("jump")
	car = game.run.car
	car.use_keyboard = false
	car.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())


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
	if _step == tap_step + shot_after:
		await _save("_tap")
	if _step == charge_step + charge_steps + shot_after:
		await _save("_charge")
		get_tree().quit()


func _save(suffix: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + suffix + ".png")
