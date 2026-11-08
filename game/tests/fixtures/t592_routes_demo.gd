extends Control
## Screenshot fixture (task T-592): the level creator with needle routes. Three boulder pairs along a
## road are a route clicked from the far end back (numbered 1, 2, 3 in click order, in the first
## route's colour, with its label); a barrier and cones pair is a second route of one; a crate pair is
## in no route (mint green, as before). The route tool is on, the first route picked for changing
## (drawn thicker, its second pair picked, so Remove from route and the order switch show, set to Random).
## bash game/tools/screenshot.sh res://tests/fixtures/t592_routes_demo.tscn art-archive/T-592/screenshots/route_in_editor.png 30

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
	var ids: Array = []
	for i in 3:
		var y := -33.0 + 12.0 * i
		var a := _place("boulder-a", Vector2(-7, y))
		var b := _place("boulder-b", Vector2(5, y))
		ids.append(str(editor.document.make_pair(a, b).id))
	var barrier := _place("prop-barrier", Vector2(-25, 9))
	var cones := _place("prop-cones", Vector2(-13, 9))
	var p2 := str(editor.document.make_pair(barrier, cones).id)
	var c1 := _place("prop-crates", Vector2(13, 9))
	var c2 := _place("prop-crates", Vector2(23, 9))
	editor.document.make_pair(c1, c2)
	editor.set_route_tool(true)
	editor.route_click_pair(p2)
	editor.finish_route()
	editor.set_route_order("random")
	for i in [2, 1, 0]:
		editor.route_click_pair(ids[i])
	editor.route_click_pair(ids[1])  # picks it: Remove from route shows
	editor.message_label.text = CreatorTexts.get_text("route_pair_added") % 3
	await get_tree().process_frame
	editor.zoom_by(2.6, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(Vector2(-3, -12)))
	editor._overlay.queue_redraw()
