extends Node
## Screenshot fixture (task T-612, round 2): starts a run, presses N, pauses and opens the God
## mode page with its "Call the kaiju" button; with the environment variable T612_PRESS=1 it
## presses the button, so the page shows it disabled, reading "Kaiju is here".
##   bash game/tools/screenshot.sh res://tests/fixtures/t612_spawn_boss_shot.tscn out.png 60

var game: Node
var _frames := 0


func _ready() -> void:
	get_window().size = Vector2i(1152, 648)
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
		game.pause_screen.open_god_mode()
		if OS.get_environment("T612_PRESS") == "1":
			game.pause_screen.god_mode_page.spawn_boss_button.pressed.emit()
