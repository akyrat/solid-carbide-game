extends Control
## Screenshot fixture (task T-398): the level creator with two roads crossing, sidewalks painted
## along them (the curbs added by themselves: straights, outer and inner corners round the
## crossing), the parked and broken cars at each of the four facings, and three meteor craters.
## T398_FOCUS=cars zooms on the cars, otherwise on the crossing's sidewalks.
## bash game/tools/screenshot.sh res://tests/fixtures/t398_street_editor.tscn art-archive/T-398/screenshots/editor_sidewalks.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const CARS := ["prop-parked-car-1", "prop-parked-car-2", "prop-parked-car-3", "prop-broken-car-1", "prop-broken-car-2"]

var editor: LevelCreatorEditor


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	editor.level_data["spawn"] = {"x": 101.0, "y": 101.0, "heading": 270}
	add_child(editor)
	editor.panel.pick("centre-line")
	editor.paint_road([Vector2(1, -40), Vector2(1, 40)])
	editor.paint_road([Vector2(-40, 1), Vector2(40, 1)])
	editor.panel.pick("sidewalk")
	for x in [-1, 5]:
		editor.paint_sidewalk([Vector2(x, -30), Vector2(x, 30)])
	for y in [-1, 5]:
		editor.paint_sidewalk([Vector2(-30, y), Vector2(30, y)])
	# A block corner filled in, so its inner corner shows.
	editor.paint_sidewalk([Vector2(-3, -3), Vector2(-3, -12)])
	editor.paint_sidewalk([Vector2(-3, -3), Vector2(-12, -3)])
	# The cars at each facing, along the sidewalk east of the crossing's south road.
	var n := 0
	for id in CARS:
		for rot in ["north", "east", "south", "west"]:
			editor.panel.pick(id)
			for i in 4:
				if editor.pick_view == rot:
					break
				editor.rotate_pick()
			editor.place_asset(id, Vector2(8.1 + 5.0 * (n % 4), 8.1 + 5.0 * (n / 4)))
			n += 1
	for i in 3:
		editor.panel.pick("crater-%d" % (i + 1))
		editor.place_asset("crater-%d" % (i + 1), Vector2(-20.9 + 4.0 * i, 1.1))
	var cars := OS.get_environment("T398_FOCUS") == "cars"
	if cars:
		# A car picked: the looks strip counts models and the top bar names the facing.
		editor.panel.pick("prop-parked-car-2")
		editor.rotate_pick()
	else:
		editor.panel.pick("sidewalk")
	await get_tree().process_frame
	editor.zoom_by(5.0 if cars else 3.5, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(Vector2(17, 20) if cars else Vector2(-4, 2)))
	editor._overlay.queue_redraw()
