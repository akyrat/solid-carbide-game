extends Control
## Screenshot fixture (task T-517): the Drift Guide on the game's map, the car drifting left
## (steer +1) or right (steer -1) from the spawn point, the guide on (test settings file).
## bash game/tools/screenshot.sh res://tests/fixtures/drift_guide_left.tscn art-archive/T-517/screenshots/left.png 90

const RunScene := preload("res://scenes/run/run.tscn")
const MAP := "res://data/level/kaiju_city_map.json"

## +1 = A (left drift), -1 = D (right drift).
@export var steer := 1.0

var run: Node2D


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameSettings.path = "user://drift_guide_demo_settings.cfg"
	GameSettings.save_drift_guide_enabled(true)
	run = RunScene.instantiate()
	run.layout_path = MAP
	add_child(run)
	run.car.use_keyboard = false
	run.weapons.enabled = false


func _physics_process(_delta: float) -> void:
	run.car.scripted_input = [true, false, steer]
	run.state.health = run.state.max_health
