extends Control
## GIF fixture (task T-263): the street grid of level_creator_road_brush_grid.gd painted in the
## level creator one block at a time, as a drag would (editor.gd begin_road_stroke and
## continue_road_stroke, the block outline under the "mouse"), then the zebra crossings clicked.
## Every `frame_every` frames a frame is saved into `frames_dir` (user://, outside game/) for
## tools/frames_to_gif.py:
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_road_brush_paint.tscn art-archive/T-263/screenshots/paint_end.png 640
## python game/tools/frames_to_gif.py "<frames folder>" art-archive/T-263/screenshots/paint.gif --fps 12 --skip 1 --scale 0.6 --crop 1.0 --shared --colors 64

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const Grid := preload("res://tests/fixtures/level_creator_road_brush_grid.gd")

@export var frames_dir := "user://t263_paint_frames"
@export var frame_every := 2
## Frames per painted block, and the frames held after each stroke and at the end.
@export var block_frames := 2
@export var pause_frames := 8
@export var zoom_factor := 2.3

var editor: LevelCreatorEditor
## [kind, ...]: ["pick", family, look], ["press", point], ["move", point], ["release"],
## ["zebra", point], ["wait"].
var _steps: Array = []
var _step := 0
var _wait := 0
var _frame := 0
var _saved := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frames_dir))
	for f in DirAccess.get_files_at(frames_dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(frames_dir.path_join(f)))
	print("level_creator_road_brush_paint: frames in ", ProjectSettings.globalize_path(frames_dir))
	for s in Grid.STROKES:
		_steps.append(["pick", s[0], s[1]])
		var pts: Array = s[2]
		_steps.append(["press", pts[0]])
		for i in range(1, pts.size()):
			var path := RoadBrush.blocks_between(pts[i - 1], pts[i])
			for b in path.slice(1):
				_steps.append(["move", b])
		_steps.append(["release"])
		_steps.append(["wait"])
	_steps.append(["pick", "zebra-crossing", 0])
	for z in Grid.ZEBRAS:
		_steps.append(["zebra", z])
		_steps.append(["wait"])
	_steps.append(["pick", "", 0])
	_steps.append(["wait"])
	await get_tree().process_frame
	editor.zoom_by(zoom_factor, editor.map_view.size / 2.0)
	var rect := RoadBrush.block_rect(editor.document, Grid.ORIGIN)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(rect.position + Vector2(5.5, 5.5) * 4.0))


func _hover(units: Vector2) -> void:
	editor.hover_units = units
	editor.hover_cell = editor.document.cell_at(units)
	editor._overlay.queue_redraw()


func _do(s: Array) -> int:
	match str(s[0]):
		"pick":
			if str(s[1]) == "":
				editor.panel.pick("")
			else:
				Grid.pick(editor, s[1], s[2])
			return pause_frames
		"press":
			var at := Grid.block_middle(editor, s[1])
			_hover(at)
			editor.begin_road_stroke(at)
			return block_frames
		"move":
			var at := Grid.block_middle(editor, s[1])
			_hover(at)
			editor.continue_road_stroke(at)
			return block_frames
		"release":
			editor.end_road_stroke()
			return 0
		"zebra":
			var at := Grid.tile_middle(editor, s[1][0], s[1][1])
			_hover(at)
			editor.place_zebra(at)
			return pause_frames
	return pause_frames


func _process(_delta: float) -> void:
	_frame += 1
	if _frame < 3:
		return
	if _wait > 0:
		_wait -= 1
	elif _step < _steps.size():
		_wait = _do(_steps[_step])
		_step += 1
	if _step <= _steps.size() and _frame % frame_every == 0:
		var img := get_viewport().get_texture().get_image()
		img.save_png(frames_dir.path_join("f%05d.png" % _saved))
		_saved += 1
