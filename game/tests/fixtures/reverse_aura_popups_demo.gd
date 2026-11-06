extends Node
## Screenshot fixture (task T-536): a run started from the main menu (the
## tutorial slides skipped) on the game's map, from the car's own start, with trick
## detection on, so the run's combo and popups react as in play. `mode` "reverse": S and A held from a standstill, a reverse
## drift, paying REVERSE DRIFT! after 1 s. `mode` "aura": no keys, the car
## stays still and pays AURA FARMING! at 6 s, 7 s, ... `popup_frame` frames
## after the `shot_trick`-th trick of the mode the viewport is saved to the
## absolute path in the environment variable REVERSE_AURA_PNG (if set), and the
## scene quits.
##   "$GODOT_BIN" --path game res://tests/fixtures/reverse_aura_popups.tscn
##   (REVERSE_AURA_MODE=aura overrides `mode`)

@export var mode := "reverse"
@export var steer := 1.0
@export var popup_frame := 14
@export var shot_trick := 1

var game: Node
var run: Node2D
var _frames := 0
var _paid := 0
var _paid_frame := -1


func _ready() -> void:
	var env_mode := OS.get_environment("REVERSE_AURA_MODE")
	if env_mode != "":
		mode = env_mode
	game = preload("res://scenes/game/game.tscn").instantiate()
	game.tutorial_enabled = false
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = true
	car.tricks.reset()
	car.scripted_input = [false, true, steer] if mode == "reverse" else [false, false, 0.0]
	var want := "reverse_drift" if mode == "reverse" else "aura"
	car.trick.connect(func(id: String) -> void:
		print("reverse_aura_popups_demo: trick %s at frame %d, combo %.2f" % [id, _frames, run.state.combo])
		if id == want:
			_paid += 1
			if _paid == shot_trick:
				_paid_frame = _frames)


func _process(_delta: float) -> void:
	if run == null:
		return
	run.state.health = run.state.max_health
	_frames += 1
	if _paid_frame < 0:
		if _frames > 6000:
			print("reverse_aura_popups_demo: no trick, quitting")
			get_tree().quit(1)
		return
	if _frames - _paid_frame == popup_frame:
		var path := OS.get_environment("REVERSE_AURA_PNG")
		if path != "":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(path)
			print("reverse_aura_popups_demo: saved %s" % path)
		get_tree().quit()
