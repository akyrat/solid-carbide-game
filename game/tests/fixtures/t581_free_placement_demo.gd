extends Control
## Screenshot fixture (task T-581): free placement in the level creator. The same clicks off the grid
## (a rooftop at 3 with a ramp 0 to 3 dropped half a unit short of its south side, a skyscraper, props, a
## boulder, a rail and the spawn point), with a skyscraper picked and the mouse off the grid. The stage
## comes from the environment variable T581_SHOT:
## - "free" (default): without Shift, every piece where it was dropped, on quarter units; the ramp goes onto
##   the rooftop's side (within LevelSnapping.FREE_RAMP_REACH) and links; the preview at the mouse.
## - "shift": the same clicks with Shift held: every piece on the 2 x 2 grid and the neighbours' edges.
## - "run": the free level saved to user:// and played: the car starts on the street south of the ramp,
##   holds W up the off-grid ramp and brakes on the off-grid rooftop.
## T581_SHOT=free bash game/tools/screenshot.sh res://tests/fixtures/t581_free_placement_demo.tscn art-archive/T-581/screenshots/free.png 30
## T581_SHOT=shift bash game/tools/screenshot.sh res://tests/fixtures/t581_free_placement_demo.tscn art-archive/T-581/screenshots/shift.png 30
## - "move_before", "move_drag", "move_after", "move_refused" (the added scope: moving placed pieces): a garage
##   (a rooftop with its ramp, a 6 and a roof vent on it), a skyscraper, a boulder and a barrier paired, a
##   street lamp, a crater and an alert sign; then the garage dragged (the outline shows it and what it carries),
##   every kind moved, and a skyscraper dragged onto the garage (refused: a grey outline).
## T581_SHOT=move_after bash game/tools/screenshot.sh res://tests/fixtures/t581_free_placement_demo.tscn art-archive/T-581/screenshots/move_after.png 30
## T581_SHOT=run bash game/tools/screenshot.sh res://tests/fixtures/t581_free_placement_demo.tscn art-archive/T-581/screenshots/run_on_free_level.png 500

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")

@export var centre_units := Vector2(30, 46)
@export var zoom_factor := 2.2
## The mouse, with a skyscraper picked, off the grid.
const HOVER := Vector2(55.6, 47.3)

var editor: LevelCreatorEditor
var run: Node2D


## The demo level's clicks (the same for both stages; `snap`: Shift held).
static func build(e: LevelCreatorEditor, snap: bool) -> void:
	e.snap_held = snap
	e.level_data["spawn"] = {"x": 28.5, "y": 70.25, "heading": 270}
	for c in [["rooftop-3", Vector2(20.25, 30.75), ""], ["ramp-0-3", Vector2(23.5, 47.25), "north"],
			["skyscraper-1", Vector2(41.25, 28.75), ""], ["skyscraper-2", Vector2(54.75, 30.5), ""],
			["prop-barrier", Vector2(9.75, 50.5), "east"], ["prop-cones", Vector2(13.25, 57.25), "north"],
			["prop-water-tank", Vector2(26.75, 34.25), "north"], ["boulder-a", Vector2(44.75, 50.25), ""],
			["crater-1", Vector2(36.25, 60.75), ""]]:
		e.panel.pick(c[0])
		for i in 4:
			if c[2] == "" or e.pick_view == c[2]:
				break
			e.rotate_pick()
		e.place_asset(c[0], c[1])
	e.panel.pick("rail")
	e.lay_rail(Vector2(5.3, 64.6), Vector2(19.9, 64.6))
	e.panel.pick("")
	e.move_spawn(Vector2(28.4, 70.3))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stage := OS.get_environment("T581_SHOT")
	if stage == "":
		stage = "free"
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	if stage.begins_with("move"):
		await _move_stage(stage)
		return
	build(editor, stage == "shift")
	for k in ["platforms", "ramps", "buildings", "props", "rails"]:
		print("t581 %s %s: %s" % [stage, k, JSON.stringify(editor.level_data.get(k, []))])
	print("t581 %s spawn: %s" % [stage, JSON.stringify(editor.level_data.spawn)])
	if stage == "run":
		_start_run()
		return
	editor.panel.pick("skyscraper-1")
	await get_tree().process_frame
	editor.zoom_by(zoom_factor, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(centre_units))
	editor.hover_units = HOVER
	editor.hover_cell = editor.document.cell_at(HOVER)
	editor._overlay.queue_redraw()


func _start_run() -> void:
	var path := "user://t581_free_level.json"
	LevelStore.save_level(path, editor.document.file_data("T-581 free placement"))
	var ground: Dictionary = editor.document.ground_layout()
	remove_child(editor)
	editor.free()
	run = RunScene.instantiate()
	run.layout_path = path
	add_child(run)
	run.map.ground_layout = ground
	run.map.ground_tiles.queue_redraw()
	run.minions.enabled = false
	run.minions.clear()
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	run.camera_follow.dynamic = false
	run.set_zoom(2.5)
	run.car.stepped.connect(_on_stepped)
	run.car.scripted_input = [true, false, 0.0]


func _on_stepped() -> void:
	if run.car.model.get_position().y < 40.0 and run.car.scripted_input[0]:
		run.car.scripted_input = [false, true, 0.0]
		print("t581 run: braking on the rooftop at ", run.car.model.get_position(), " height ", run.car.height)


## The moving stages (T-581, added scope).
func _move_stage(stage: String) -> void:
	var e := editor
	e.level_data["spawn"] = {"x": 28.5, "y": 70.25, "heading": 270}
	for c in [["rooftop-3", Vector2(10, 30), "", "m"], ["ramp-0-3", Vector2(13, 46), "north", "m"],
			["rooftop-6", Vector2(12, 32), "", "s"], ["prop-roof-vent", Vector2(22, 42), "north", "m"],
			["skyscraper-1", Vector2(44, 26), "", "m"], ["boulder-a", Vector2(34, 50), "", "m"],
			["prop-barrier", Vector2(42, 50.5), "north", "m"], ["prop-street-lamp", Vector2(6, 52), "north", "m"],
			["crater-1", Vector2(36, 62), "", "m"], ["alert-sign-head", Vector2(50, 44), "", "m"]]:
		e.set_platform_size(c[3])
		e.panel.pick(c[0])
		for i in 4:
			if c[2] == "" or e.pick_view == c[2]:
				break
			e.rotate_pick()
		e.place_asset(c[0], c[1])
	e.panel.pick("")
	var rock := e.document.piece_at(Vector2(35.5, 51.5))
	var bar := e.document.piece_at(Vector2(44, 51))
	e.document.make_pair(rock, bar)
	e._rebuild_map()
	match stage:
		"move_drag":
			e.press_piece(Vector2(24, 34))
			e.update_piece_drag(Vector2(24, 34) + Vector2(-8.75, -12.5))
		"move_after":
			for m in [[Vector2(24, 34), Vector2(-8.75, -12.5)], [Vector2(50, 32), Vector2(4.25, -6.5)],
					[Vector2(35.5, 51.5), Vector2(-3.25, 4.75)], [Vector2(44, 51), Vector2(2.5, 3.25)],
					[Vector2(7, 53), Vector2(1.75, -9.5)], [Vector2(37, 63), Vector2(-6.5, 1.25)],
					[Vector2(51, 45), Vector2(5.25, 6.75)]]:
				e.press_piece(m[0])
				e.end_piece_drag(m[0] + m[1])
		"move_refused":
			e.press_piece(Vector2(50, 32))
			e.update_piece_drag(Vector2(50, 32) + Vector2(-26, 8))
	for k in ["platforms", "ramps", "buildings", "props", "pattern_copies", "craters", "alert_signs", "pairs"]:
		print("t581 %s %s: %s" % [stage, k, JSON.stringify(e.level_data.get(k, []))])
	if not e.piece_drag.is_empty():
		print("t581 %s drag problem: '%s'" % [stage, e.piece_drag.problem])
	await get_tree().process_frame
	e.zoom_by(zoom_factor, e.map_view.size / 2.0)
	e.pan_by(e.map_view.size / 2.0 - e.units_to_screen(Vector2(30, 44)))
	e._overlay.queue_redraw()
