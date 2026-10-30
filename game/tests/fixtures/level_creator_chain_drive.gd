extends Node
## GIF fixture (task T-394): a small level built in the creator's editor (a road, and a row of four
## boulders zigzagging along it, one each side in turn, paired as a chain with Shift+click and P)
## saved to a temporary file and played as a run (as T-272's level_creator_pairs_drive.gd). The car
## is driven by script (W held) north along the road, threading the three gaps one after another:
## THREAD THE NEEDLE! pops for each. Every `frame_every` frames a frame is saved into `frames_dir`
## (user://, outside game/) for tools/frames_to_gif.py, and the frame with the last popup up into
## `popup_png` when set (the T394_POPUP_PNG environment variable).
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_chain_drive.tscn art-archive/T-394/screenshots/chain_drive_end.png 300

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")

## The car's start (units), heading north, and how many physics steps W is held.
const START := Vector2(-0.5, 4)
const STEPS := 150

@export var frames_dir := "user://t394_drive_frames"
@export var frame_every := 2
@export var zoom := 9.0
## Where the frame with the popup is saved (an absolute path), "" for none: the T394_POPUP_PNG
## environment variable when set.
@export var popup_png := ""

var run: Node2D
var _steps := 0
var _frame := 0
var _saved := 0
var _popup_frame := -1
var _paid := 0


func _place(editor: LevelCreatorEditor, asset: String, at: Vector2) -> Dictionary:
	editor.panel.pick(asset)
	var p := editor.place_asset(asset, at)
	editor.panel.pick("")
	return p


func _ready() -> void:
	if popup_png == "":
		popup_png = OS.get_environment("T394_POPUP_PNG")
	var editor: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	editor.panel.pick("road")
	editor.paint_road([Vector2(-1, -60), Vector2(-1, 40)])
	editor.panel.pick("")
	var row: Array = []
	for i in 4:
		row.append(_place(editor, "boulder-a" if i % 2 == 0 else "boulder-b", Vector2(-5.0 if i % 2 == 0 else 3.0, -15.0 - 6.0 * i)))
	editor.set_pair_tool(true)
	for p in row:
		editor.pair_click(editor.document.piece_rect(p).get_center(), true)
	editor.pair_pick()
	print("level_creator_chain_drive: pairs ", editor.document.pairs())
	var path := "user://t394_chain_level.json"
	LevelStore.save_level(path, editor.document.file_data("T-394 chain"))
	var ground: Dictionary = editor.document.ground_layout()
	remove_child(editor)
	editor.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frames_dir))
	for f in DirAccess.get_files_at(frames_dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(frames_dir.path_join(f)))
	print("level_creator_chain_drive: frames in ", ProjectSettings.globalize_path(frames_dir))
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
	run.car.hit_obstacle.connect(func(_c, _i, _n, _s): print("level_creator_chain_drive: crashed"))
	run.state.combo_trick.connect(func(id, added, m):
		print("level_creator_chain_drive: trick %s +%s, combo %s" % [id, added, m])
		_paid += 1
		if _paid == 3:
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
		print("level_creator_chain_drive: braking at ", run.car.model.get_position())
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
