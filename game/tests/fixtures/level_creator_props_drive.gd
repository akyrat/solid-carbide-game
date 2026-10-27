extends Node
## GIF fixture (task T-253): a small level built in the creator's editor (a concrete barrier, a crate
## stack and a street lamp in a row on the street, a water tank on a rooftop) saved to a temporary
## file and played as a run (run.tscn with that layout_path, the creator level's own ground), with
## the car driven by script (W held) north into each prop in turn: it crashes and bounces off. Every
## `frame_every` frames a frame is saved into `frames_dir` (user://, outside game/) for
## tools/frames_to_gif.py.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_props_drive.tscn art-archive/T-253/screenshots/drive_end.png 700

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")

## [asset, rotation, top-left corner of the footprint (units)].
const PROPS := [
	["prop-barrier", "north", Vector2(-34, -10)],
	["prop-crates", "north", Vector2(-2, -10)],
	["prop-street-lamp", "north", Vector2(30, -10)],
]
## [start (units), heading (radians: -PI / 2 north), physics steps with W held].
const LEGS := [
	[Vector2(-32, 12), -PI / 2.0, 150],
	[Vector2(-1, 12), -PI / 2.0, 150],
	[Vector2(31, 12), -PI / 2.0, 150],
]

@export var frames_dir := "user://t253_drive_frames"
@export var frame_every := 2
@export var zoom := 9.0

var run: Node2D
var _leg := -1
var _steps := 0
var _frame := 0
var _saved := 0
var _hits := 0


func _ready() -> void:
	var editor: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	for p in PROPS:
		editor.panel.pick(p[0])
		for i in 4:
			if editor.pick_view == p[1]:
				break
			editor.rotate_pick()
		editor.place_asset(p[0], p[2] + Vector2(1, 1))
	editor.panel.pick("rooftop-3")
	editor.place_asset("rooftop-3", Vector2(61, -29), Vector2(30, 30))
	editor.panel.pick("prop-water-tank")
	editor.place_asset("prop-water-tank", Vector2(71, -19))
	var path := "user://t253_props_level.json"
	LevelStore.save_level(path, editor.document.file_data("T-253 props"))
	var ground: Dictionary = editor.document.ground_layout()
	remove_child(editor)
	editor.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frames_dir))
	for f in DirAccess.get_files_at(frames_dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(frames_dir.path_join(f)))
	print("level_creator_props_drive: frames in ", ProjectSettings.globalize_path(frames_dir))
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
	run.car.hit_obstacle.connect(func(_c, _i, _n, _s): _hits += 1)
	_next_leg()


func _next_leg() -> void:
	_leg += 1
	_steps = 0
	if _leg >= LEGS.size():
		run.car.scripted_input = [false, false, 0.0]
		print("level_creator_props_drive: crashes ", _hits)
		return
	var leg: Array = LEGS[_leg]
	var car = run.car
	car.model.set_position(leg[0])
	car.model.rotation = leg[1]
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.scripted_input = [true, false, 0.0]
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()


func _on_stepped() -> void:
	_steps += 1
	if _leg < LEGS.size() and _steps >= int(LEGS[_leg][2]):
		print("level_creator_props_drive: leg %d ended at %s" % [_leg, run.car.model.get_position()])
		_next_leg()


func _process(_delta: float) -> void:
	if run != null and run.state != null:
		run.state.health = run.state.max_health
	_frame += 1
	if _leg < LEGS.size() and _frame % frame_every == 0:
		var img := get_viewport().get_texture().get_image()
		img.save_png(frames_dir.path_join("f%05d.png" % _saved))
		_saved += 1
