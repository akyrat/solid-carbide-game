extends Node
## GIF fixture (task T-272): a small level built in the creator's editor (a road, two boulders paired
## with the pair tool, one each side of it) saved to a temporary file and played as a run (run.tscn
## with that layout_path, the creator level's own ground). The car is driven by script (W held)
## north through the gap: the faint dashed marker lies across it, and THREAD THE NEEDLE! +0.5 pops.
## Every `frame_every` frames a frame is saved into `frames_dir` (user://, outside game/) for
## tools/frames_to_gif.py, and the frame with the popup fully up into `popup_png` when set.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_pairs_drive.tscn art-archive/T-272/screenshots/drive_end.png 260

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")

## The car's start (units), heading north, and how many physics steps W is held.
const START := Vector2(-0.5, 4)
const STEPS := 100

@export var frames_dir := "user://t272_drive_frames"
@export var frame_every := 2
@export var zoom := 9.0
## Where the frame with the popup is saved (an absolute path), "" for none: the T272_POPUP_PNG
## environment variable when set.
@export var popup_png := ""

var run: Node2D
var _steps := 0
var _frame := 0
var _saved := 0
var _popup_frame := -1


func _place(editor: LevelCreatorEditor, asset: String, at: Vector2) -> Dictionary:
	editor.panel.pick(asset)
	var p := editor.place_asset(asset, at)
	editor.panel.pick("")
	return p


func _ready() -> void:
	if popup_png == "":
		popup_png = OS.get_environment("T272_POPUP_PNG")
	var editor: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	editor.panel.pick("road")
	editor.paint_road([Vector2(-1, -60), Vector2(-1, 40)])
	editor.panel.pick("")
	var a := _place(editor, "boulder-a", Vector2(-5, -21))
	var b := _place(editor, "boulder-b", Vector2(3, -21))
	editor.set_pair_tool(true)
	editor.pair_click(editor.document.piece_rect(a).get_center())
	editor.pair_click(editor.document.piece_rect(b).get_center())
	var path := "user://t272_pairs_level.json"
	LevelStore.save_level(path, editor.document.file_data("T-272 thread the needle"))
	var ground: Dictionary = editor.document.ground_layout()
	remove_child(editor)
	editor.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frames_dir))
	for f in DirAccess.get_files_at(frames_dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(frames_dir.path_join(f)))
	print("level_creator_pairs_drive: frames in ", ProjectSettings.globalize_path(frames_dir))
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
	run.car.hit_obstacle.connect(func(_c, _i, _n, _s): print("level_creator_pairs_drive: crashed"))
	run.state.combo_trick.connect(func(id, added, m):
		print("level_creator_pairs_drive: trick %s +%s, combo %s" % [id, added, m])
		_popup_frame = _frame + 20)
	var car = run.car
	car.model.set_position(START)
	car.model.rotation = -PI / 2.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	run.needle.last_position = null
	car.scripted_input = [true, false, 0.0]
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()


func _on_stepped() -> void:
	_steps += 1
	if _steps == STEPS:
		run.car.scripted_input = [false, true, 0.0]
		print("level_creator_pairs_drive: braking at ", run.car.model.get_position())
	elif _steps == STEPS + 40:
		run.car.scripted_input = [false, false, 0.0]


func _process(_delta: float) -> void:
	if run != null and run.state != null:
		run.state.health = run.state.max_health
	_frame += 1
	if _frame == _popup_frame and popup_png != "":
		get_viewport().get_texture().get_image().save_png(popup_png)
	if _steps < STEPS + 60 and _frame % frame_every == 0:
		var img := get_viewport().get_texture().get_image()
		img.save_png(frames_dir.path_join("f%05d.png" % _saved))
		_saved += 1
