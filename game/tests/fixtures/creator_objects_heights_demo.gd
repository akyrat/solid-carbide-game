extends Control
## Screenshot fixture (task T-393): the board's case, its Kaiju City level (the untracked read-only
## copy in data/levels/kaiju_city.json; never saved) with its row of barriers running into a
## low-rise by the rooftops, in the editor (`stage` "editor", the view centred on the barriers) or
## in a run on the same file with the car parked beside the barriers.
## bash game/tools/screenshot.sh res://tests/fixtures/creator_objects_heights_demo.tscn art-archive/T-393/screenshots/after_editor.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const LEVEL := "res://data/levels/kaiju_city.json"
## Where the view looks (units): the last barriers by the low-rise.
const FOCUS := Vector2(-46, 58)
@export var stage := "editor"

var editor: LevelCreatorEditor
var run: Node2D
var _frames := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if stage == "editor":
		editor = EDITOR_SCENE.instantiate()
		editor.levels_dir = RunPaths.file("t393_screenshot_levels")
		add_child(editor)
		editor.open_level(LEVEL)
		return
	run = RunScene.instantiate()
	run.layout_path = LEVEL
	add_child(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false


func _process(_delta: float) -> void:
	_frames += 1
	if editor != null and _frames >= 3:
		editor.zoom = 1.0
		editor.view_origin = editor.map_view.size / 2.0 - editor.ISO_TRANSFORM * (FOCUS * editor.PX_PER_UNIT)
		editor._apply_view()
	if run != null:
		run.car.model.set_position(Vector2(-58, 61))
		run.car.model.rotation = 0.0
		run.car.model.set_velocity(Vector2.ZERO)
		run.car._sync_from_model()
		run.sync_view()


func _exit_tree() -> void:
	RunPaths.cleanup()
