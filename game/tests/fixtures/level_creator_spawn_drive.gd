extends Node
## GIF fixture (task T-280): the level the demo fixture builds (the start on a rooftop, facing the
## ramp down its east side) saved to a temporary file and played as a run. The car is not placed by
## the fixture: the run starts it on the level's spawn point, at the rooftop's height and heading
## east, and W is held so it drives off the roof down the ramp. Every `frame_every` frames a frame
## is saved into `frames_dir` (user://, outside game/) for tools/frames_to_gif.py.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_spawn_drive.tscn art-archive/T-280/screenshots/drive_end.png 200

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const Demo := preload("res://tests/fixtures/level_creator_spawn_demo.gd")

const STEPS := 150

@export var frames_dir := "user://t280_drive_frames"
@export var frame_every := 2
@export var zoom := 7.0

var run: Node2D
var _steps := 0
var _frame := 0
var _saved := 0


func _ready() -> void:
	var editor: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	Demo.build_roof_level(editor, func(a, at, v, s):
		editor.panel.pick(a)
		if v != "":
			editor.pick_view = v
		var p := editor.place_asset(a, at, s)
		editor.panel.pick("")
		return p)
	var path := "user://t280_drive_level.json"
	LevelStore.save_level(path, editor.document.file_data("T-280 spawn drive"))
	var ground: Dictionary = editor.document.ground_layout()
	remove_child(editor)
	editor.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frames_dir))
	for f in DirAccess.get_files_at(frames_dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(frames_dir.path_join(f)))
	print("level_creator_spawn_drive: frames in ", ProjectSettings.globalize_path(frames_dir))
	run = RunScene.instantiate()
	run.layout_path = path
	add_child(run)
	run.map.ground_layout = ground
	run.map.ground_tiles.queue_redraw()
	run.minions.enabled = false
	run.minions.clear()
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	run.camera_follow.dynamic = false
	run.set_zoom(zoom)
	run.car.stepped.connect(_on_stepped)
	print("level_creator_spawn_drive: car starts at ", run.car.model.get_position(), " heading ",
		rad_to_deg(run.car.model.rotation), " height ", run.car.height)
	run.car.scripted_input = [true, false, 0.0]


func _on_stepped() -> void:
	_steps += 1
	if _steps == 1:
		print("level_creator_spawn_drive: first step at height ", run.car.height)
	if _steps == STEPS:
		run.car.scripted_input = [false, true, 0.0]
		print("level_creator_spawn_drive: braking at ", run.car.model.get_position(), " height ", run.car.height)


func _process(_delta: float) -> void:
	if run != null and run.state != null:
		run.state.health = run.state.max_health
	_frame += 1
	if _steps < STEPS + 30 and _frame % frame_every == 0:
		var img := get_viewport().get_texture().get_image()
		img.save_png(frames_dir.path_join("f%05d.png" % _saved))
		_saved += 1
