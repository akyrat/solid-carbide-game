extends Control
## Screenshot fixture (task T-264): the level creator's editor with either a 3 rooftop and ramps
## climbing to it from all four sides, their arrows up or down (`mode` "ramps", `arrows`), or S, M
## and L platforms at heights 3 and 6, each placed with one click (`mode` "sizes"). Built through
## the editor as the board would (pick, turn, key A, size buttons, click).
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_ramps_up.tscn art-archive/T-264/screenshots/ramps_up.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")

@export var mode := "ramps"
@export var arrows := "up"
@export var centre_units := Vector2(12, 12)
@export var zoom_factor := 2.2

var editor: LevelCreatorEditor


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	if mode == "ramps":
		_build_ramps()
	else:
		_build_sizes()
	await get_tree().process_frame
	editor.zoom_by(zoom_factor, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(centre_units))


func _build_ramps() -> void:
	editor.panel.pick("rooftop-3")
	editor.place_asset("rooftop-3", Vector2(1, 1), Vector2(24, 24))
	if arrows == "down":
		editor.arrows_pick()
	# [view, top-left corner, dragged size]: each climbs to one side of the 3.
	for s in [["north", Vector2(7, 25), Vector2(10, 0)], ["east", Vector2(-13, 7), Vector2(0, 10)],
			["south", Vector2(7, -13), Vector2(10, 0)], ["west", Vector2(25, 7), Vector2(0, 10)]]:
		editor.panel.pick("ramp-0-3")
		for i in 4:
			if editor.pick_view == s[0]:
				break
			editor.rotate_pick()
		editor.place_asset("ramp-0-3", s[1] + Vector2(1, 1), s[2])
	editor.panel.pick("ramp-0-3")


func _build_sizes() -> void:
	var x := -60.0
	for h in [3, 6]:
		var id := "rooftop-%d" % h
		editor.panel.pick(id)
		x = -60.0
		for key in ["s", "m", "l"]:
			editor.set_platform_size(key)
			var side: float = LevelCreatorEditor.PLATFORM_SIZES[key]
			editor.place_asset(id, Vector2(x + 1, (-40.0 if h == 3 else 20.0) + 1))
			x += side + 12.0
	editor.set_platform_size("m")
	editor.panel.pick("rooftop-3")
