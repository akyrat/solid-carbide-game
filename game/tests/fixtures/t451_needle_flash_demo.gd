extends Node
## Screenshot fixture (task T-451): the T-272 pair level driven north through the gap; frames of the flash
## are saved into `out_dir` (an absolute path, the T451_OUT environment variable when set) at rest before,
## and 0.0, 0.15, 0.3 and 0.45 seconds into the flash, and after it ends.
## bash game/tools/screenshot.sh res://tests/fixtures/t451_needle_flash_demo.tscn x.png 400

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")

## The car's start (units), heading north, and how many physics steps W is held.
const START := Vector2(-0.5, 4)
const STEPS := 100

@export var frames_dir := "user://t272_drive_frames"
@export var frame_every := 2
@export var zoom := 5.5
## Where the frame with the popup is saved (an absolute path), "" for none: the T272_POPUP_PNG
## environment variable when set.
@export var popup_png := ""

var run: Node2D
var _steps := 0
var _frame := 0
var _saved := 0
var _popup_frame := -1
var out_dir := ""
var _shots := {}
var _before_done := false
var _after_done := false


func _place(editor: LevelCreatorEditor, asset: String, at: Vector2) -> Dictionary:
	editor.panel.pick(asset)
	var p := editor.place_asset(asset, at)
	editor.panel.pick("")
	return p


func _ready() -> void:
	out_dir = OS.get_environment("T451_OUT")
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
	print("t451_needle_flash_demo: frames in ", ProjectSettings.globalize_path(frames_dir))
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
	run.car.hit_obstacle.connect(func(_c, _i, _n, _s): print("t451_needle_flash_demo: crashed"))
	var car = run.car
	# Stop the car the moment the trick pays, so the pair stays in view while it flashes.
	run.needle.threaded.connect(func(_id):
		car.scripted_input = [false, true, 0.0]
		car.model.set_velocity(Vector2.ZERO))
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
		print("t451_needle_flash_demo: braking at ", run.car.model.get_position())
	elif _steps == STEPS + 40:
		run.car.scripted_input = [false, false, 0.0]


func _save(name: String) -> void:
	if out_dir != "":
		get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
		print("t451_needle_flash_demo: saved ", name)


func _process(_delta: float) -> void:
	if run == null or run.state == null:
		return
	run.state.health = run.state.max_health
	_frame += 1
	var fl: NeedleFlash = run.needle_flash
	if not _before_done and run.car.model.get_position().y < -14.0 and fl.active.is_empty():
		_before_done = true
		_save("0_before")
	if fl.active.has("pair-1"):
		var t: float = fl.active["pair-1"].t
		for mark in [0.0, 0.15, 0.3, 0.45]:
			var key := "flash_%03d" % int(round(mark * 100))
			if t >= mark and not _shots.has(key):
				_shots[key] = true
				_save(key)
	elif _shots.has("flash_045") and not _after_done:
		_after_done = true
		_save("9_after")
