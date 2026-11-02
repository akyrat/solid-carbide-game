extends Control
## Screenshot fixture (task T-507): rain over the game's map (Kaiju City, data/level/
## kaiju_city_map.json), the car parked on a street (the map's spawn point) or on a rooftop
## (roof-1, height 3), minions coming in, the HUD on top. The settings go to a test file, rain on.
## bash game/tools/screenshot.sh res://tests/fixtures/rain_demo_street.tscn art-archive/T-507/screenshots/street.png 240
## bash game/tools/screenshot.sh res://tests/fixtures/rain_demo_rooftop.tscn art-archive/T-507/screenshots/rooftop.png 240

const RunScene := preload("res://scenes/run/run.tscn")
const MAP := "res://data/level/kaiju_city_map.json"
const STREET := Vector2(1, 1)
const ROOFTOP := Vector2(-32, 36)

## true: on roof-1; false: on the street at the spawn point.
@export var rooftop := false

var run: Node2D


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameSettings.path = "user://rain_demo_settings.cfg"
	GameSettings.save_rain_enabled(true)
	run = RunScene.instantiate()
	run.layout_path = MAP
	add_child(run)
	run.car.use_keyboard = false
	run.weapons.enabled = false
	run.minions.rng.seed = 507


func _physics_process(_delta: float) -> void:
	var at := ROOFTOP if rooftop else STREET
	run.car.model.set_position(at)
	run.car.model.rotation = 0.0
	run.car.model.set_velocity(Vector2.ZERO)
	run.car._sync_from_model()
	run.state.health = run.state.max_health
	run.sync_view()
