extends Control
## Screenshot fixture (task T-239): a custom level built in the level creator's editor (a 3 rooftop
## with a 6 on it, their ramps, a building and a boulder near the start), saved into this run's own
## temporary levels folder (RunPaths, never the real one), then played from the creator's list with
## its Play button as a full run. `stage` "list" stops on the list with the level listed; "run"
## presses Play; "ended" presses Play, ends the run as a win and shows the list it returns to.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_play_demo.tscn art-archive/T-239/screenshots/run_on_custom_level.png 120

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const CREATOR_SCENE := preload("res://scenes/level_creator/level_creator.tscn")
## The level's name (a demo name, not shown to players).
@export var demo_name := "Rooftop corner"
@export var stage := "run"
## Where the car is put for the "run" shot, in units.
@export var car_units := Vector2(-21, 16)

var creator: LevelCreator


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dir := RunPaths.file("t239_screenshot_levels")
	var editor: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	editor.levels_dir = dir
	editor.open_new()
	add_child(editor)
	for step in [["rooftop-3", Vector2(-35.5, -35.5)], ["rooftop-6", Vector2(18.5, -35.5)],
			["ramp-0-3", Vector2(-25.5, -5.5)], ["ramp-3-6", Vector2(6.5, -25.5)],
			["skyscraper-3", Vector2(14.5, 8.5)], ["boulder-a", Vector2(-12.5, 10.5)]]:
		editor.panel.pick(step[0])
		editor.place_asset(step[0], step[1])
	editor.name_field.text = demo_name
	editor.save_button.pressed.emit()
	print("saved: ", editor.level_path)
	var saved := LevelStore.load_level(editor.level_path)
	print("buildings: ", saved.buildings, "\nplatforms: ", saved.platforms, "\nramps: ", saved.ramps)
	remove_child(editor)
	editor.queue_free()

	creator = CREATOR_SCENE.instantiate()
	creator.levels_dir = dir
	add_child(creator)
	if stage == "list":
		return
	creator.list_screen.rows[0].play.pressed.emit()
	print("run on: ", creator.run.layout_path)
	if stage == "ended":
		creator.run.state.kaiju_killed()
		return
	# The car on the street just south of the level's ramp up to the 3, facing it.
	var car = creator.run.car
	car.model.x = car_units.x
	car.model.y = car_units.y
	car.model.rotation = -PI / 2.0
	car.position = car_units * 16.0
	creator.run.sync_view(true)


func _exit_tree() -> void:
	RunPaths.cleanup()
