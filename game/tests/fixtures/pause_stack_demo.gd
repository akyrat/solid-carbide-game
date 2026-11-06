extends Node
## Screenshot fixture for T-537: a paused run at a chosen window size (the stacked pause
## screen). Uses its own settings file. Scenes: pause_stack_1280.tscn, pause_stack_large.tscn.

@export var window_size := Vector2i(1280, 720)
@export var god_mode := false
var TEST_SETTINGS := RunPaths.file("screenshot_settings_t537.cfg")
var game: Node
var _frames := 0


func _ready() -> void:
	GameSettings.path = TEST_SETTINGS
	DirAccess.remove_absolute(TEST_SETTINGS)
	get_window().size = window_size
	GodMode.unlocked = god_mode
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 40:
		game.pause_screen.pause()


func _exit_tree() -> void:
	GodMode.unlocked = false
	DirAccess.remove_absolute(TEST_SETTINGS)
	GameSettings.path = GameSettings.DEFAULT_PATH
