extends Control
## Screenshot fixture (task T-272): the level creator with two pairs of obstacles for thread the
## needle (two boulders either side of a painted road, and a barrier with cones), each shown as a
## dashed line across the gap and a ring round each obstacle, and the pair tool still on with a crate
## stack held as the first of a new pair (ringed thicker; the top bar shows "Pair: click two
## obstacles" and the last message "Pair made. Drive between them.").
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_pairs_demo.tscn art-archive/T-272/screenshots/pair_in_editor.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")

var editor: LevelCreatorEditor


func _place(asset: String, at: Vector2) -> Dictionary:
	editor.panel.pick(asset)
	var p := editor.place_asset(asset, at)
	editor.panel.pick("")
	return p


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	editor.panel.pick("road")
	editor.paint_road([Vector2(-1, -60), Vector2(-1, 40)])
	editor.panel.pick("")
	var a := _place("boulder-a", Vector2(-9, -21))
	var b := _place("boulder-b", Vector2(7, -21))
	var barrier := _place("prop-barrier", Vector2(-25, 9))
	var cones := _place("prop-cones", Vector2(-13, 9))
	var crates := _place("prop-crates", Vector2(15, 9))
	_place("prop-crates", Vector2(27, 9))
	editor.set_pair_tool(true)
	for p in [a, b, barrier, cones]:
		editor.pair_click(editor.document.piece_rect(p).get_center())
	editor.pair_click(editor.document.piece_rect(crates).get_center())
	editor.message_label.text = CreatorTexts.get_text("pair_made")
	await get_tree().process_frame
	editor.zoom_by(3.2, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(Vector2(-3, 0)))
	editor._overlay.queue_redraw()
