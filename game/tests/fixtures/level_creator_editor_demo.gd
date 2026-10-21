extends Control
## Screenshot fixture (task T-235): the level creator's editor on a new level with pieces of every
## kind placed (ground and road tiles, buildings, boulders, a rooftop and its ramp), a boulder
## picked in the side panel with its outline under the "mouse", and a building selected.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_editor_demo.tscn art-archive/T-235/screenshots/editor.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")

## True: the side panel scrolled to its end (the buildings, boulders, rooftops and ramps);
## level_creator_editor_panel_end.tscn.
@export var scroll_panel_to_end := false

var editor: LevelCreatorEditor


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	# A road across, with zebra crossings, and a patch of other gravel.
	for x in range(-50, 50, 2):
		editor.place_asset("road-x_plain_a0", Vector2(x, -6))
		editor.place_asset("road-x_line_r_a0", Vector2(x, -4))
		editor.place_asset("road-x_line_l_a0", Vector2(x, -2))
		editor.place_asset("road-x_plain_a0", Vector2(x, 0))
	for y in range(-6, 2, 2):
		editor.place_asset("road-y_zebra_a0", Vector2(-10, y))
	for x in range(-48, -30, 2):
		for y in range(10, 24, 2):
			editor.place_asset("ground-gravel1" if (x + y) % 4 == 0 else "ground-gravel2", Vector2(x, y))
	editor.place_asset("road-road_tile", Vector2(30, 10))
	# Buildings north of the road.
	editor.place_asset("skyscraper-2", Vector2(-40, -30))
	editor.place_asset("short-0", Vector2(-24, -24))
	editor.place_asset("skyscraper-5", Vector2(4, -30))
	# Boulders south of the road.
	editor.place_asset("boulder-a", Vector2(-20, 10))
	editor.place_asset("boulder-b", Vector2(-12, 14))
	# A rooftop at 6 with a ramp (heights and their links are the next ticket).
	editor.place_asset("rooftop-6", Vector2(20, 14))
	editor.place_asset("ramp-0-3", Vector2(30, 44))
	await get_tree().process_frame
	editor.zoom_by(1.6, editor.map_view.size / 2.0)
	editor.pan_by(Vector2(0, 40))
	editor.select_at(Vector2(10, -24))
	editor.panel.pick("boulder-a")
	editor.hover_cell = editor.document.cell_at(Vector2(-4, 16))
	editor._overlay.queue_redraw()
	if scroll_panel_to_end:
		await get_tree().process_frame
		var scroll: ScrollContainer = editor.panel.get_node("Scroll")
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
