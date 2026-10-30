extends Control
## Screenshot and GIF fixture (task T-405): short buildings joined into platforms
## (t405_platforms_level.gd), in the editor (`stage` "editor"), parked in a run ("run", the car on
## the joined low-rises), driven ("drive": from the spawn up the ramp, across the low-rises and the
## rooftop, off its east edge over the barrier and into the skyscraper) or on the game's own map
## ("game_map": a block's short buildings as platforms).
## bash game/tools/screenshot.sh res://tests/fixtures/t405_platforms_demo.tscn art-archive/T-405/screenshots/editor_joined.png 30
## GIF: "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/m/f.png res://tests/fixtures/t405_platforms_demo_drive.tscn --quit-after 260

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const Level := preload("res://tests/fixtures/t405_platforms_level.gd")
## Where the view looks (units).
const FOCUS := Vector2(4, -2)
@export var stage := "editor"

var editor: LevelCreatorEditor
var run: Node2D
var _frames := 0
var _label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var path := RunPaths.file("t405_demo/t405_platforms.json")
	LevelStore.save_level(path, Level.file_data())
	if stage == "editor":
		editor = EDITOR_SCENE.instantiate()
		editor.levels_dir = RunPaths.file("t405_demo")
		add_child(editor)
		editor.open_level(path)
		return
	run = RunScene.instantiate()
	if stage != "game_map":
		run.layout_path = path
	add_child(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	_label = Label.new()
	_label.position = Vector2(16, 16)
	_label.add_theme_font_size_override("font_size", 22)
	add_child(_label)


func _process(_delta: float) -> void:
	_frames += 1
	if editor != null and _frames >= 3:
		editor.zoom = 1.0
		editor.view_origin = editor.map_view.size / 2.0 - editor.ISO_TRANSFORM * (FOCUS * editor.PX_PER_UNIT)
		editor._apply_view()
	if run == null:
		return
	if stage == "run":
		run.car.model.set_position(Vector2(-1, -5))
		run.car.model.rotation = 0.0
		run.car.model.set_velocity(Vector2.ZERO)
		run.car.height_model.reset(Vector2(-1, -5))
		run.car._sync_from_model()
		run.sync_view()
	elif stage == "game_map":
		# The game's own map: the first block's two short buildings, platforms now, the car on the street south of them.
		run.car.model.set_position(Vector2(27, -62))
		run.car.model.rotation = -PI / 2.0
		run.car.model.set_velocity(Vector2.ZERO)
		run.car.height_model.reset(Vector2(27, -62))
		run.car._sync_from_model()
		run.sync_view()
	elif stage == "drive":
		# W held, steering back onto y = -5 heading east.
		var err: float = wrapf(-run.car.model.rotation, -PI, PI) - (run.car.model.y + 5.0) * 0.05
		run.car.scripted_input = [_frames > 20, false, clampf(err * 2.0, -1.0, 1.0)]
		_label.text = "height %.1f  %s" % [run.car.height, "in the air" if run.car.airborne else "on the ground"]


func _exit_tree() -> void:
	RunPaths.cleanup()
