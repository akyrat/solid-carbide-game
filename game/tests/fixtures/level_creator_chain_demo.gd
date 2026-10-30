extends Control
## Screenshot fixture (task T-394): the level creator with a row of five boulders zigzagging along a
## road, picked in order with Shift+click and paired as a chain with P (four pairs, B, C and D each
## in two: a dashed line across every gap), and a second row of three obstacles picked with
## Shift+click, ringed thicker and numbered 1, 2, 3, before Pair.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_chain_demo.tscn art-archive/T-394/screenshots/chain_in_editor.png 30

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
	# A row of five zigzagging along the road, paired as a chain with Shift+click and P.
	var row: Array = []
	for i in 5:
		row.append(_place("boulder-a" if i % 2 == 0 else "boulder-b", Vector2(-5.0 if i % 2 == 0 else 3.0, -9.0 - 6.0 * i)))
	editor.set_pair_tool(true)
	for p in row:
		editor.pair_click(editor.document.piece_rect(p).get_center(), true)
	editor.pair_pick()
	# A second row picked (numbered 1, 2, 3), not paired yet.
	for i in 3:
		var p := _place(["prop-barrier", "prop-cones", "prop-crates"][i], Vector2(-25.0 + 10.0 * i, 9.0))
		editor.pair_click(editor.document.piece_rect(p).get_center(), true)
	editor.message_label.text = CreatorTexts.get_text("pair_made")
	await get_tree().process_frame
	editor.zoom_by(3.2, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(Vector2(-5, -10)))
	editor._overlay.queue_redraw()
