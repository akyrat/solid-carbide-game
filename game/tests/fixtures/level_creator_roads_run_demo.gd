extends Control
## Screenshot fixture (task T-391): a level with roads painted in the level creator's editor (a
## centre-line road crossing a plain road, a cracked road with a zebra crossing, a T-junction, and a
## rooftop with its ramp beside the road), saved into this run's own temporary levels folder
## (RunPaths, never the real one), then played from the creator's list with its Play button. The
## run draws the painted roads (LevelGround). `stage` "editor" stops in the editor instead, for a
## side-by-side look.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_roads_run_demo.tscn art-archive/T-391/screenshots/run_painted_roads.png 120

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const CREATOR_SCENE := preload("res://scenes/level_creator/level_creator.tscn")
@export var stage := "run"

var creator: LevelCreator


func _paint(editor: LevelCreatorEditor, family: String, blocks: Array) -> void:
	editor.panel.pick(family)
	editor.paint_road(blocks.map(func(b): return RoadBrush.block_rect(editor.document, b).get_center()))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dir := RunPaths.file("t391_screenshot_levels")
	var editor: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	editor.levels_dir = dir
	editor.open_new()
	add_child(editor)
	_paint(editor, "centre-line", [Vector2i(24, 28), Vector2i(36, 28)])
	_paint(editor, "road", [Vector2i(30, 22), Vector2i(30, 36)])
	_paint(editor, "cracked-road", [Vector2i(24, 33), Vector2i(29, 33)])
	editor.panel.pick("zebra-crossing")
	editor.place_zebra(RoadBrush.block_rect(editor.document, Vector2i(26, 33)).position + Vector2(1, 1))
	editor.panel.pick("")
	var roof := RoadBrush.block_rect(editor.document, Vector2i(32, 30)).position
	editor.place_asset("rooftop-3", roof, Vector2(8, 8))
	editor.place_asset("ramp-0-3", roof + Vector2(0, 8), Vector2(8, 0))
	editor.name_field.text = "Painted roads"
	editor.save_button.pressed.emit()
	print("saved: ", editor.level_path)
	if stage == "editor":
		return
	remove_child(editor)
	editor.queue_free()
	creator = CREATOR_SCENE.instantiate()
	creator.levels_dir = dir
	add_child(creator)
	creator.list_screen.rows[0].play.pressed.emit()
	print("run on: ", creator.run.layout_path)


func _exit_tree() -> void:
	RunPaths.cleanup()
