extends Control
## Screenshot fixture (task T-280): the level creator showing the spawn point.
## T280_SHOT=new: a new level (a road across it) with its spawn point at the centre, not selected.
## T280_SHOT=roof (default): the spawn point moved onto a rooftop beside a ramp, turned to face the
## ramp and selected (the top bar shows the hint).
## T280_SHOT=refused: a building placed, the start dragged onto it and refused (the message shows).
## T280_SHOT=drag: the start part-way through a drag, its ghost at the cell under the mouse.
## T280_SHOT=levelsave: also writes the roof level to user://t280_spawn_level.json for the drive fixture.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_spawn_demo.tscn art-archive/T-280/screenshots/x.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")

var editor: LevelCreatorEditor


func _place(asset: String, at: Vector2, view: String = "", size: Vector2 = Vector2.ZERO) -> Dictionary:
	editor.panel.pick(asset)
	if view != "":
		editor.pick_view = view
	var p := editor.place_asset(asset, at, size)
	editor.panel.pick("")
	return p


## The level the drive fixture plays: a rooftop with a ramp down its east side, the start on the
## rooftop facing the ramp. Returns the roof's piece.
static func build_roof_level(ed: LevelCreatorEditor, placer: Callable) -> void:
	ed.panel.pick("road")
	ed.paint_road([Vector2(-1, -60), Vector2(-1, 60)])
	ed.panel.pick("")
	placer.call("rooftop-3", Vector2(-7, -7), "", Vector2(16, 16))
	placer.call("ramp-0-3", Vector2(10, -3), "west", Vector2.ZERO)
	ed.move_spawn(Vector2(-4, 1))
	ed.select_spawn()
	ed.turn_spawn()
	ed.turn_spawn()  # 270 -> 315 -> 0: facing east, the ramp


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	var mode := OS.get_environment("T280_SHOT")
	if mode == "new":
		editor.panel.pick("road")
		editor.paint_road([Vector2(-1, -60), Vector2(-1, 60)])
		editor.panel.pick("road")
		editor.paint_road([Vector2(-60, 1), Vector2(60, 1)])
		editor.panel.pick("")
		_place("building-small", Vector2(21, -21))
		_place("boulder-a", Vector2(-21, 21))
	else:
		build_roof_level(editor, func(a, at, v, s): return _place(a, at, v, s))
		if mode == "refused":
			var b := _place("building-small", Vector2(31, 31))
			editor.move_spawn(editor.document.piece_rect(b).get_center())
		elif mode == "drag":
			editor.begin_spawn_drag()
			editor.update_spawn_drag(Vector2(-14, 9))
		elif mode == "levelsave":
			LevelStore.save_level("user://t280_spawn_level.json", editor.document.file_data("T-280 spawn"))
	await get_tree().process_frame
	var focus := Vector2(2, 0) if mode != "new" else Vector2.ZERO
	editor.zoom_by(2.6 if mode != "new" else 1.7, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(focus))
	editor._overlay.queue_redraw()
