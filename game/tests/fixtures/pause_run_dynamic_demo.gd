extends Node
## Screenshot fixture for the pause screen's camera controls in a run (task
## T-124): a run started from the main menu with the dynamic camera on and
## camera smoothing off (so both checkbox looks show), the stored min and max
## set to 10.0 and 17.5, then paused. It uses its own test settings file, never
## the player's real settings. Take it with about 60 frames:
##   bash game/tools/screenshot.sh res://tests/fixtures/pause_run_dynamic_asphalt.tscn screenshots/t124_asphalt.png 60

## A test settings file, removed before and after use.
var TEST_SETTINGS := RunPaths.file("screenshot_settings_t124.cfg")
const DYN_MIN := 10.0
const DYN_MAX := 17.5

## Where the car stands, in units: (0, 0) is the run's start on the gravel,
## (54, 0) the asphalt road east of the centre (T-118).
@export var start_units := Vector2.ZERO

var game: Node
var _frames := 0


func _ready() -> void:
	GameSettings.path = TEST_SETTINGS
	DirAccess.remove_absolute(TEST_SETTINGS)
	GameSettings.save_camera_smoothing(false)
	GameSettings.save_dynamic_camera(true)
	GameSettings.save_dynamic_zoom_min(DYN_MIN)
	GameSettings.save_dynamic_zoom_max(DYN_MAX)
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	var car: CharacterBody2D = game.run.car
	car.use_keyboard = false
	car.scripted_input = [false, false, 0.0]
	if start_units != Vector2.ZERO:
		car.model.set_position(start_units)
		car.position = start_units * car.PX_PER_UNIT


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 40:
		game.pause_screen.pause()


func _exit_tree() -> void:
	DirAccess.remove_absolute(TEST_SETTINGS)
	GameSettings.path = GameSettings.DEFAULT_PATH
