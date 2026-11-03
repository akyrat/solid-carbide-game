extends Node
## Screenshot fixture (task T-510): a new player's run (no saved settings, a fresh test file),
## paused so the Rain checkbox shows unticked, with no rain over the map.
##   bash game/tools/screenshot.sh res://tests/fixtures/rain_default_off_demo.tscn art-archive/T-510/screenshots/new_player_no_rain.png 60

var TEST_SETTINGS := RunPaths.file("screenshot_settings_t510.cfg")
var game: Node
var _frames := 0


func _ready() -> void:
	GameSettings.path = TEST_SETTINGS
	DirAccess.remove_absolute(TEST_SETTINGS)
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()  # past the tutorial slides
	game.run.car.use_keyboard = false


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 30:
		game.pause_screen.pause()


func _exit_tree() -> void:
	DirAccess.remove_absolute(TEST_SETTINGS)
	GameSettings.path = GameSettings.DEFAULT_PATH
