extends Node
## Test fixture for the screenshots of T-505: starts a run, presses N, pauses, and (with
## open_page) opens the God mode page. `window_width` and `window_height` set the window size.

@export var open_page := false
@export var window_width := 1152
@export var window_height := 648

var game: Node
var _frames := 0


func _ready() -> void:
	get_window().size = Vector2i(window_width, window_height)
	GodMode.unlocked = false
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 30:
		var ev := InputEventAction.new()
		ev.action = "god_mode_unlock"
		ev.pressed = true
		game.run.god_mode._unhandled_input(ev)
		game.pause_screen.pause()
		if open_page:
			game.pause_screen.open_god_mode()
			# a few tiers set so the rows show something
			game.run.god_mode.set_tier("weapon", "flamethrower", 3)
			game.run.god_mode.set_tier("power_up", "jump", 1)
