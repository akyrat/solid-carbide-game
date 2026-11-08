extends Node
## T-599 screenshots: the pause screen's settings with Trick popups ticked off, and a run with the
## setting off where tricks still raise the combo but show no bubbles. Throwaway settings file.
@export var show := "pause"  # "pause" or "run"

var game: Node
var _frames := 0


func _ready() -> void:
	GameSettings.path = RunPaths.file("t599_demo.cfg")
	DirAccess.remove_absolute(GameSettings.path)
	GameSettings.save_trick_popups_enabled(false)
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 40:
		if show == "pause":
			game.pause_screen.pause()
		else:
			for i in 3:
				game.run.state.add_trick("three_sixty")
