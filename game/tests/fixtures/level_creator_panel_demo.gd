extends Control
## Screenshot fixture (task T-262): the level creator's side panel, one button per kind of piece in
## six groups, on a new level with a few pieces placed with their looks (keys V, R, M, H).
## `pick`: "" the whole panel with nothing picked; a family id ("skyscraper", "boulder") picked
## with `looks` presses of V and `mirror` of M, so its looks strip shows under its group.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_panel_demo.tscn art-archive/T-262/screenshots/panel.png 30
## (level_creator_panel_skyscraper.tscn, level_creator_panel_boulder.tscn, _end.tscn: the other shots)

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")

@export var pick := ""
@export var looks := 0
@export var mirror := false
## True: the side panel scrolled to its end.
@export var scroll_panel_to_end := false

var editor: LevelCreatorEditor


func _place(fid: String, at: Vector2, v: int = 0, r: int = 0, m: bool = false) -> void:
	editor.panel.pick(fid)
	for i in v:
		editor.look_pick()
	for i in r:
		editor.rotate_pick()
	if m:
		editor.mirror_pick()
	editor.place_asset(editor.panel.picked, at)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	# A road along x with its centre line, a zebra crossing, some cracked road.
	for x in range(-40, 40, 2):
		_place("road", Vector2(x, -6), 0, 1)
		_place("centre-line", Vector2(x, -4), 0, 1)
		_place("centre-line", Vector2(x, -2), 6, 1)
		_place("road", Vector2(x, 0), 0, 1)
	for y in range(-6, 2, 2):
		_place("zebra-crossing", Vector2(-8, y))
	for x in range(10, 30, 2):
		_place("cracked-road", Vector2(x, -6), 1, 1)
	# Skyscrapers in four of their looks, low-rise and small buildings north of the road.
	_place("skyscraper", Vector2(-40, -32), 0)
	_place("skyscraper", Vector2(-26, -32), 1)
	_place("skyscraper", Vector2(-12, -32), 4)
	_place("skyscraper", Vector2(2, -32), 9)
	_place("lowrise", Vector2(16, -32), 2, 0, true)
	_place("building-small", Vector2(30, -24), 0, 0, true)
	# Boulders, both looks and mirrors, and props south of the road.
	_place("boulder", Vector2(-30, 8))
	_place("boulder", Vector2(-24, 12), 1, 0, true)
	_place("barrier", Vector2(-12, 6), 0, 1)
	_place("cones", Vector2(-6, 8))
	_place("street-lamp", Vector2(4, 6))
	_place("crates", Vector2(10, 10))
	editor.panel.pick("")
	await get_tree().process_frame
	editor.zoom_by(1.7, editor.map_view.size / 2.0)
	editor.pan_by(Vector2(0, 60))
	if pick != "":
		editor.panel.pick(pick)
		for i in looks:
			editor.look_pick()
		if mirror:
			editor.mirror_pick()
		editor.hover_cell = editor.document.cell_at(Vector2(20, 14))
		editor._overlay.queue_redraw()
	if scroll_panel_to_end or pick != "":
		await get_tree().process_frame
		await get_tree().process_frame
		var scroll: ScrollContainer = editor.panel.get_node("Scroll")
		if scroll_panel_to_end:
			scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		else:
			scroll.ensure_control_visible(editor.panel.looks_strip)
