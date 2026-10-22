extends Node
## GIF fixture (task T-251): the small multi-layer level of level_creator_pieces_level.gd, built in
## the creator's editor and saved to a temporary file, played as a run (run.tscn with that
## layout_path, the creator level's own ground tiles), with the car driven by script (W held) along
## LEGS: up each ramp direction and off a rooftop's edge. Every `frame_every` frames a frame is saved
## into `frames_dir` (user://, outside game/) for tools/frames_to_gif.py.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_pieces_drive.tscn art-archive/T-251/screenshots/drive_end.png 1500

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const Level := preload("res://tests/fixtures/level_creator_pieces_level.gd")

## [start (units), heading (radians: 0 east, -PI / 2 north), physics steps with W held].
const LEGS := [
	[Vector2(-21, 38), -PI / 2.0, 215],   # north up the 0 to 3, across the 3, off its north edge
	[Vector2(-54, 3), 0.0, 255],          # east up the 0 to 3, up the 3 to 6, off the 6 and the 3
	[Vector2(5, -15), PI / 2.0, 150],     # on the 3: south up the 3 to 6, off the 6 and the 3
	[Vector2(78, -1), PI, 165],           # west up the 0 to 3 onto the small 3, off its west edge
	[Vector2(-22, 94), -PI / 2.0, 235],   # north up the 0 to 6, off the 6's north edge (a drop of 6)
]

@export var frames_dir := "user://t251_drive_frames"
@export var frame_every := 2
@export var zoom := 9.0

var run: Node2D
var _leg := -1
var _steps := 0
var _frame := 0
var _saved := 0


func _ready() -> void:
	var editor: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	Level.build(editor)
	var path := "user://t251_pieces_level.json"
	LevelStore.save_level(path, editor.document.file_data("T-251 pieces"))
	var ground: Dictionary = editor.document.ground_layout()
	remove_child(editor)
	editor.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frames_dir))
	for f in DirAccess.get_files_at(frames_dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(frames_dir.path_join(f)))
	print("level_creator_pieces_drive: frames in ", ProjectSettings.globalize_path(frames_dir))
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
	_next_leg()


func _next_leg() -> void:
	_leg += 1
	_steps = 0
	if _leg >= LEGS.size():
		run.car.scripted_input = [false, false, 0.0]
		return
	var leg: Array = LEGS[_leg]
	var car = run.car
	car.model.set_position(leg[0])
	car.model.rotation = leg[1]
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height  # back on the ground there (its height)
	car.scripted_input = [true, false, 0.0]
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()


func _on_stepped() -> void:
	_steps += 1
	if _leg < LEGS.size() and _steps >= int(LEGS[_leg][2]):
		print("level_creator_pieces_drive: leg %d ended at %s, height %.2f" % [_leg, run.car.model.get_position(), run.car.height])
		_next_leg()


func _process(_delta: float) -> void:
	if run != null and run.state != null:
		run.state.health = run.state.max_health
	_frame += 1
	if _leg < LEGS.size() and _frame % frame_every == 0:
		var img := get_viewport().get_texture().get_image()
		img.save_png(frames_dir.path_join("f%05d.png" % _saved))
		_saved += 1
