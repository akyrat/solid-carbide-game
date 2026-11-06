extends GutTest
## Task T-542 (Level design, Decisions, "Rails"; Content, "Rails in the level creator (task T-542)"): the
## rail piece of the level creator. Laid with a drag (or a click: a default-length rail in the picked
## direction), at the picked height or just above the street or rooftop under each end; selected, moved,
## resized, turned, given another height and deleted; drawn with T-541's placeholder; saved to and loaded
## from the level file's "rails" list (T-541's format) and playable as a full run, where the car grinds
## them. The test levels are written under the test folder, never into game/data/levels/.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const CarScript := preload("res://scripts/driving/car.gd")
const Rails := preload("res://scripts/level/rails.gd")
const PX := 16.0
## A rooftop at height 3: x -30..-14, y -60..-44.
const ROOF := Vector2(-30, -60)


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	e.level_data["spawn"] = {"x": 111.0, "y": 111.0, "heading": 270}
	e.levels_dir = RunPaths.file("t542_levels")
	add_child_autofree(e)
	return e


func _with_roof(e: LevelCreatorEditor) -> void:
	assert_false(e.document.place("rooftop-3", ROOF + Vector2(1, 1), "", false, Vector2(16, 16)).is_empty())
	e._rebuild_map()


## The local mouse position of a map point `u` at height `z` (where the bar's end is drawn).
func _local(e: LevelCreatorEditor, u: Vector2, z: float = 0.0) -> Vector2:
	return e.units_to_screen(u) - Vector2(0.0, z * PX * e.zoom)


## Picks the rail piece at the height member `height` ("auto", "1", "3.1", "6.1").
func _pick_rail(e: LevelCreatorEditor, height: String = "auto") -> void:
	e.panel.pick("rail")
	for i in 5:
		if str(e.panel.member.get("height", "")) == height:
			break
		e.height_pick()
	assert_eq(str(e.panel.member.get("height", "")), height)


## Lays a rail with the mouse: press at a, move, release at b (heights as the pick).
func _drag_lay(e: LevelCreatorEditor, a: Vector2, b: Vector2, za: float, zb: float) -> Dictionary:
	e.begin_rail_drag(_local(e, a, za))
	e.update_rail_drag(_local(e, b, zb))
	return e.end_rail_drag(_local(e, b, zb))


func _sorted_rails(rails: Array) -> Array:
	var out := rails.duplicate(true)
	out.sort_custom(func(x, y): return str(x.id) < str(y.id))
	return out


# ---- The panel ------------------------------------------------------------------------------------

func test_the_rail_is_a_levels_piece_with_its_label_heights_and_hints() -> void:
	var e := _editor()
	var levels: Array = e.panel.entries_by_category()[CreatorTexts.get_text("group_levels")]
	assert_true("rail" in levels, str(levels))
	assert_eq(e.panel.buttons["rail"].text, CreatorTexts.get_text("piece_rail"))
	assert_eq(CreatorTexts.get_text("piece_rail"), "Rail")
	assert_eq(CreatorFamilies.family("rail").heights, ["auto", "1", "3.1", "6.1"])
	e.panel.pick("rail")
	assert_true(e.panel.looks_strip.visible)
	for k in ["rail_drag_hint", "rail_turn_hint", "rail_height_hint"]:
		assert_true(CreatorTexts.get_text(k) in e.panel.look_notes.text, k)
	assert_eq(e.rail_height_mode(), "auto", "auto is the first height")
	assert_eq(e.size_label.text, CreatorTexts.get_text("rail_hint"))


func test_h_steps_the_heights_and_the_top_bar_names_them() -> void:
	var e := _editor()
	e.panel.pick("rail")
	assert_eq(e.height_label.text, CreatorTexts.get_text("rail_height_auto"))
	var seen: Array = []
	for i in 4:
		seen.append(e.rail_height_mode())
		e.height_pick()
	assert_eq(seen, ["auto", "1", "3.1", "6.1"])
	assert_eq(e.rail_height_mode(), "auto", "round again")
	e.height_pick()
	assert_eq(e.height_label.text, CreatorTexts.get_text("rail_height_fixed").format({"h": "1"}))


func test_r_turns_the_direction_a_clicked_rail_is_laid_in() -> void:
	var e := _editor()
	e.panel.pick("rail")
	assert_false(e.rotate_button.disabled)
	assert_eq(e.direction_label.text, CreatorTexts.get_text("rail_direction").format({"deg": 0}))
	e.rotate_pick()
	e.rotate_pick()
	assert_eq(e.rail_turn, 2)
	assert_eq(e.direction_label.text, CreatorTexts.get_text("rail_direction").format({"deg": 90}))
	for i in 6:
		e.rotate_pick()
	assert_eq(e.rail_turn, 0, "eight steps make a full turn")


# ---- Laying ---------------------------------------------------------------------------------------

func test_a_drag_lays_a_rail_between_its_ends_at_the_picked_height() -> void:
	var e := _editor()
	_pick_rail(e, "1")
	var piece := _drag_lay(e, Vector2(10, 20), Vector2(10, -10), 1.0, 1.0)
	assert_false(piece.is_empty())
	assert_eq(piece.kind, "rail")
	var it: Dictionary = piece.item
	assert_eq([it.id, it.x1, it.y1, it.z1, it.x2, it.y2, it.z2], ["rail-1", 10.0, 20.0, 1.0, 10.0, -10.0, 1.0])
	assert_eq(e.document.rails().size(), 1)
	assert_eq(e.document.placed_pieces().filter(func(q): return q.kind == "rail").size(), 1)
	assert_eq(Rails.problem(it), "", "the game takes it")
	var second := _drag_lay(e, Vector2(20, 20), Vector2(30, 20), 1.0, 1.0)
	assert_eq(second.item.id, "rail-2", "the next free id")


func test_auto_height_is_one_over_the_street_or_the_rooftop_under_each_end() -> void:
	var e := _editor()
	_with_roof(e)
	_pick_rail(e, "auto")
	# From the street onto the rooftop: the bar climbs from 1 to 4 (T-542 round 2: 1 over the ground under each end).
	var it: Dictionary = _drag_lay(e, Vector2(-40, -52), Vector2(-22, -52), 1.0, 4.0).item
	assert_eq([it.x1, it.y1, it.z1, it.x2, it.y2, it.z2], [-40.0, -52.0, 1.0, -22.0, -52.0, 4.0])
	# Along the rooftop: level at 4; and the whole piece reads back through the game's own check.
	var it2: Dictionary = _drag_lay(e, Vector2(-28, -58), Vector2(-16, -46), 4.0, 4.0).item
	assert_almost_eq(float(it2.z1), 4.0, 1e-6)
	assert_almost_eq(float(it2.z2), 4.0, 1e-6)
	assert_eq(Rails.from_layout(e.document.data).size(), 2)


func test_a_fixed_height_ignores_what_is_under_the_end() -> void:
	var e := _editor()
	_with_roof(e)
	_pick_rail(e, "6.1")
	var it: Dictionary = _drag_lay(e, Vector2(-28, -58), Vector2(-16, -46), 6.1, 6.1).item
	assert_eq([it.z1, it.z2], [6.1, 6.1])


func test_a_click_lays_a_default_length_rail_in_the_picked_direction() -> void:
	var e := _editor()
	_pick_rail(e, "1")
	e.rotate_pick()
	e.rotate_pick()  # 90 degrees: along +y (south on the map)
	var it: Dictionary = _drag_lay(e, Vector2(4, 4), Vector2(4, 4), 1.0, 1.0).item
	assert_eq([it.x1, it.y1, it.x2, it.y2], [4.0, 4.0, 4.0, 4.0 + RailPiece.DEFAULT_LENGTH])
	e.rotate_pick()  # 135 degrees
	var d := RailPiece.direction_of(e.rail_turn)
	assert_almost_eq(d.x, -sqrt(0.5), 1e-6)
	assert_almost_eq(d.y, sqrt(0.5), 1e-6)


func test_ends_snap_to_half_units() -> void:
	var e := _editor()
	_pick_rail(e, "1")
	var it: Dictionary = e.lay_rail(Vector2(1.13, 2.37), Vector2(9.74, 2.12)).item
	assert_eq([it.x1, it.y1, it.x2, it.y2], [1.0, 2.5, 9.5, 2.0])


func test_a_rail_the_game_would_skip_or_outside_the_map_is_refused_with_a_message() -> void:
	var e := _editor()
	_pick_rail(e, "1")
	assert_true(e.lay_rail(Vector2(115, 0), Vector2(135, 0)).is_empty(), "reaches out of the map")
	assert_eq(e.message_label.text, CreatorTexts.get_text("rail_refused"))
	assert_eq(e.document.rails().size(), 0)
	assert_eq(e.document.place_rail(Vector2(0, 0), Vector2(0.4, 0), 1.0, 1.0), {}, "shorter than a unit")
	assert_eq(e.document.place_rail(Vector2(0, 0), Vector2(5, 0), 0.0, 0.0), {}, "at the street")
	assert_eq(e.document.rails().size(), 0)
	assert_true(e.lay_rail(Vector2(0, 0), Vector2(8, 0)).has("item"))
	assert_eq(e.message_label.text, "", "the message clears")


func test_the_mouse_lays_a_rail_press_move_release() -> void:
	var e := _editor()
	_pick_rail(e, "1")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = _local(e, Vector2(-20, 30), 1.0)
	e._on_map_input(press)
	assert_false(e.rail_drag.is_empty(), "the drag has begun")
	var move := InputEventMouseMotion.new()
	move.position = _local(e, Vector2(10, 30), 1.0)
	e._on_map_input(move)
	assert_eq(e.rail_new.b, Vector2(10, 30), "the far end follows the mouse")
	assert_eq(e.document.rails().size(), 0, "nothing is laid before the release")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = move.position
	e._on_map_input(release)
	assert_eq(e.document.rails().size(), 1)
	var it: Dictionary = e.document.rails()[0]
	assert_eq([it.x1, it.y1, it.x2, it.y2], [-20.0, 30.0, 10.0, 30.0])
	assert_true(e.rail_drag.is_empty() and e.rail_new.is_empty())


# ---- Selecting, moving, resizing, turning, deleting -----------------------------------------------

## A rail along y = 0 from x = -10 to 10 at height 1, laid and selected by a click on its bar.
func _rail_selected(e: LevelCreatorEditor) -> Dictionary:
	_pick_rail(e, "1")
	var piece := e.lay_rail(Vector2(-10, 0), Vector2(10, 0))
	e.panel.pick("")
	assert_true(e.press_rail(_local(e, Vector2(0, 0), 1.0)), "the bar is under the mouse")
	e.end_rail_drag(_local(e, Vector2(0, 0), 1.0))
	assert_eq(e.selected_rail(), piece.item)
	return piece.item


func test_a_click_on_the_bar_selects_the_rail_and_the_top_bar_reads_it_out() -> void:
	var e := _editor()
	var it := _rail_selected(e)
	assert_eq(e.selected.kind, "rail")
	assert_true(CreatorTexts.get_text("rail_selected").format({"id": "rail-1", "length": 20.0, "z1": 1.0, "z2": 1.0, "deg": 0}) == e.size_label.text,
		e.size_label.text)
	assert_false(e.rotate_button.disabled)
	e.select_at_mouse(_local(e, Vector2(60, 60), 0.0))
	assert_true(e.selected_rail().is_empty(), "clicking elsewhere drops it")
	assert_eq(e.document.rails()[0], it, "and changes nothing")


func test_a_click_away_from_every_rail_is_not_a_rail_press() -> void:
	var e := _editor()
	_rail_selected(e)
	assert_false(e.press_rail(_local(e, Vector2(0, 30), 1.0)))
	assert_false(e.press_rail(_local(e, Vector2(40, 0), 1.0)), "past the end")


func test_dragging_the_bar_moves_the_rail() -> void:
	var e := _editor()
	var it := _rail_selected(e)
	assert_true(e.press_rail(_local(e, Vector2(0, 0), 1.0)))
	assert_eq(e.rail_drag.mode, "body")
	e.update_rail_drag(_local(e, Vector2(3, 7), 1.0))
	e.end_rail_drag(_local(e, Vector2(3, 7), 1.0))
	assert_eq([it.x1, it.y1, it.x2, it.y2], [-7.0, 7.0, 13.0, 7.0])
	assert_eq([it.z1, it.z2], [1.0, 1.0], "the heights stay")
	assert_true(e.move_rail(Vector2(-3, -7)))
	assert_eq([it.x1, it.y1, it.x2, it.y2], [-10.0, 0.0, 10.0, 0.0])


func test_dragging_an_end_resizes_and_turns_the_rail_the_other_end_stays() -> void:
	var e := _editor()
	var it := _rail_selected(e)
	assert_true(e.press_rail(_local(e, Vector2(10, 0), 1.0)))
	assert_eq(e.rail_drag.mode, "b")
	e.update_rail_drag(_local(e, Vector2(10, 15), 1.0))
	e.end_rail_drag(_local(e, Vector2(10, 15), 1.0))
	assert_eq([it.x1, it.y1, it.x2, it.y2], [-10.0, 0.0, 10.0, 15.0], "end b moved, end a stayed")
	assert_almost_eq(RailPiece.length_of(it), 25.0, 1e-6)
	assert_true(e.press_rail(_local(e, Vector2(-10, 0), 1.0)))
	assert_eq(e.rail_drag.mode, "a")
	e.update_rail_drag(_local(e, Vector2(-20, 0), 1.0))
	e.end_rail_drag(_local(e, Vector2(-20, 0), 1.0))
	assert_eq([it.x1, it.y1, it.x2, it.y2], [-20.0, 0.0, 10.0, 15.0])


func test_brackets_shorten_and_lengthen_and_never_below_the_games_minimum() -> void:
	var e := _editor()
	var it := _rail_selected(e)
	assert_true(e.resize_rail(RailPiece.LENGTH_STEP))
	assert_almost_eq(RailPiece.length_of(it), 21.0, 1e-6)
	assert_eq(RailPiece.end_a(it), Vector2(-10, 0), "end a stays")
	for i in 40:
		e.resize_rail(-RailPiece.LENGTH_STEP)
	assert_almost_eq(RailPiece.length_of(it), Rails.MIN_LENGTH, 1e-6)
	assert_eq(Rails.problem(it), "")
	# The keys do the same.
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_BRACKETRIGHT
	e._unhandled_key_input(key)
	assert_almost_eq(RailPiece.length_of(it), Rails.MIN_LENGTH + 1.0, 1e-6)
	key.keycode = KEY_BRACKETLEFT
	e._unhandled_key_input(key)
	assert_almost_eq(RailPiece.length_of(it), Rails.MIN_LENGTH, 1e-6)


func test_r_turns_the_selected_rail_round_its_middle() -> void:
	var e := _editor()
	var it := _rail_selected(e)
	assert_eq(RailPiece.angle_deg(it), 0.0)
	e.rotate_pick()
	assert_almost_eq(RailPiece.angle_deg(it), 45.0, 1.0)
	assert_almost_eq(RailPiece.length_of(it), 20.0, 0.8, "snapping to half units only nudges the length")
	assert_almost_eq((RailPiece.end_a(it) + RailPiece.end_b(it)).length(), 0.0, 0.6, "round the middle")
	e.rotate_pick()
	e.rotate_pick()
	e.rotate_pick()
	assert_almost_eq(RailPiece.angle_deg(it), 180.0, 1.0, "four steps turn it half way")
	assert_eq(e.rail_turn, 0, "the laying direction is not touched")


func test_h_steps_the_selected_rails_height_for_both_ends() -> void:
	var e := _editor()
	_with_roof(e)
	var it := _rail_selected(e)
	e.step_pick("height")
	assert_eq([it.z1, it.z2], [3.1, 3.1], "1 -> 3.1")
	e.height_pick()
	assert_eq([it.z1, it.z2], [6.1, 6.1])
	e.height_pick()
	assert_eq([it.z1, it.z2], [1.0, 1.0], "auto: the street under both ends")
	# Over the rooftop: the rail from the street onto it, then round again to auto: 1.0 and 4.0.
	assert_true(e.move_rail(Vector2(-30, -52)))
	e.step_pick("height")
	assert_eq([it.z1, it.z2], [3.1, 3.1])
	e.step_pick("height")
	assert_eq([it.z1, it.z2], [6.1, 6.1])
	e.step_pick("height")
	assert_almost_eq(float(it.z1), 1.0, 1e-6)
	assert_almost_eq(float(it.z2), 4.0, 1e-6)


func test_escape_during_an_edit_puts_the_rail_back() -> void:
	var e := _editor()
	var it := _rail_selected(e)
	var before := it.duplicate()
	assert_true(e.press_rail(_local(e, Vector2(10, 0), 1.0)))
	e.update_rail_drag(_local(e, Vector2(25, 9), 1.0))
	assert_ne(it, before)
	e.cancel_rail_drag()
	assert_eq(it, before)
	assert_true(e.rail_drag.is_empty())
	# Escape during a new rail's drag drops it.
	_pick_rail(e, "1")
	e.begin_rail_drag(_local(e, Vector2(0, 20), 1.0))
	e.update_rail_drag(_local(e, Vector2(9, 20), 1.0))
	e.cancel_rail_drag()
	assert_eq(e.document.rails().size(), 1)


func test_del_deletes_the_selected_rail_and_its_drawing() -> void:
	var e := _editor()
	_rail_selected(e)
	assert_not_null(e.rail_drawing)
	e.delete_selected()
	assert_eq(e.document.rails().size(), 0)
	assert_true(e.selected.is_empty())
	assert_null(e.rail_drawing, "no rails, no drawing")
	assert_eq(e.size_label.text, "")


func test_only_the_selected_rail_is_deleted() -> void:
	var e := _editor()
	var first := _rail_selected(e)
	_pick_rail(e, "1")
	e.lay_rail(Vector2(-10, 20), Vector2(10, 20))
	e.panel.pick("")
	assert_true(e.press_rail(_local(e, Vector2(0, 20), 1.0)))
	e.end_rail_drag(_local(e, Vector2(0, 20), 1.0))
	assert_eq(e.selected_rail().id, "rail-2")
	e.delete_selected()
	assert_eq(e.document.rails(), [first])


# ---- Drawing --------------------------------------------------------------------------------------

func test_rails_are_drawn_with_the_runs_placeholder_and_follow_every_change() -> void:
	var e := _editor()
	assert_null(e.rail_drawing, "none at first")
	_pick_rail(e, "1")
	e.lay_rail(Vector2(-10, 0), Vector2(10, 0))
	assert_not_null(e.rail_drawing)
	assert_eq(e.rail_drawing.rails.size(), 1)
	var pieces: int = e.rail_drawing.pieces.size()
	assert_gt(pieces, 4, "a bar cut into pieces for the depth order")
	assert_eq(e.rail_drawing.get_parent(), e.map.view_root)
	e.panel.pick("")
	e.press_rail(_local(e, Vector2(0, 0), 1.0))
	e.end_rail_drag(_local(e, Vector2(0, 0), 1.0))
	e.resize_rail(10.0)
	assert_gt(e.rail_drawing.pieces.size(), pieces, "redrawn longer")
	assert_eq(e.map.view_root.get_children().filter(func(n): return n.name == "Rails").size(), 1, "one drawing, the old one is gone")
	e._rebuild_map()
	assert_eq(e.rail_drawing.rails.size(), 1, "and again after the whole map is rebuilt")


# ---- Saved, reopened, played ----------------------------------------------------------------------

func _three_rails(e: LevelCreatorEditor) -> void:
	_with_roof(e)
	_pick_rail(e, "auto")
	e.lay_rail(Vector2(-40, -52), Vector2(-22, -52))
	_pick_rail(e, "6.1")
	e.lay_rail(Vector2(30, 30), Vector2(30, 60))
	_pick_rail(e, "1")
	e.lay_rail(Vector2(5, -6), Vector2(5, -60))
	e.panel.pick("")


func test_a_saved_level_loads_back_the_same_rails_in_the_files_format() -> void:
	var e := _editor()
	_three_rails(e)
	e.name_field.text = "T-542 rails"
	assert_eq(e.save(), OK)
	var path := e.level_path
	var saved := LevelStore.load_level(path)
	assert_eq(_sorted_rails(saved.rails), _sorted_rails(e.document.rails()))
	assert_eq(Rails.from_layout(saved).size(), 3, "the game reads all three")
	for r in saved.rails:
		assert_eq(Rails.problem(r), "", str(r.id))
		assert_eq(r.keys().size(), 7, "id, x1, y1, z1, x2, y2, z2")
	# The level check passes.
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	assert_eq(code, 0, "\n".join(output))
	# Reopened in the editor: the same rails, drawn, and editable.
	var e2: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e2.levels_dir = e.levels_dir
	e2.open_level(path)
	add_child_autofree(e2)
	assert_eq(_sorted_rails(e2.document.rails()), _sorted_rails(saved.rails))
	assert_eq(e2.rail_drawing.rails.size(), 3)
	e2.selected = {"kind": "rail", "item": e2.document.rails()[0]}
	assert_true(e2.resize_rail(1.0))
	assert_eq(e2.document.rails().size(), 3)


func test_a_level_with_no_rails_saves_without_a_rails_list() -> void:
	var e := _editor()
	e.name_field.text = "T-542 none"
	assert_eq(e.save(), OK)
	assert_false(LevelStore.load_level(e.level_path).has("rails"))


func test_the_saved_level_played_as_a_run_has_the_rails_drawn_and_grindable() -> void:
	var e := _editor()
	_three_rails(e)
	var path := RunPaths.file("t542_run_level.json")
	assert_eq(LevelStore.save_level(path, e.document.file_data("T-542 run")), OK)
	var run: Node2D = RunScene.instantiate()
	run.layout_path = path
	add_child_autofree(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	assert_eq(run.car.grind.rails.size(), 3, "the car's grind has the level's rails")
	assert_not_null(run.rail_drawing, "and the run draws them")
	assert_eq(run.rail_drawing.rails.size(), 3)
	# Grindable: a car dropped onto the first rail (street to rooftop, rising 1 -> 3.1) moving along it locks on.
	var rail: Dictionary = run.car.grind.rails[0]
	var holder := Node2D.new()
	add_child_autofree(holder)
	var car: CharacterBody2D = CarScript.new()
	var start: Vector2 = Rails.point_at(rail, 3.0)
	car.model.set_position(start)
	car.model.rotation = atan2(rail.dir.y, rail.dir.x)
	holder.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.model.set_velocity(rail.dir * 10.0)
	car.grind.rails = run.car.grind.rails
	car.height_model.height = Rails.height_at(rail, 3.0) + 0.6
	car.height_model.leave_rail(0.0)
	var locked := false
	for i in 120:
		if car.grind.active:
			locked = true
			break
		car.physics_step()
	assert_true(locked, "the car locks onto the rail the creator laid")
	assert_eq(str(car.grind.rail.id), str(rail.id))


func test_auto_height_on_a_ramp_follows_the_slope_and_a_rail_on_it_stands_one_over_it() -> void:
	# T-542 round 2: a rail laid on a ramp sits 1 over the ramp's surface at each end (a ramp's foot too),
	# not 1 over the street at the foot and 0.1 over the top.
	var e := _editor()
	e.place_asset("ramp-0-3", Vector2(-9.5, -9.5))
	var r: Dictionary = e.level_data.ramps[0]
	var x: float = float(r.x) + float(r.w) / 2.0
	var y_foot: float = float(r.y) + float(r.h) - 0.5
	var y_top: float = float(r.y) + 0.5
	assert_almost_eq(e.document.auto_rail_height(Vector2(x, y_foot)), e.document.height_at(Vector2(x, y_foot)) + 1.0, 1e-6)
	assert_gt(e.document.height_at(Vector2(x, y_foot)), -1e-6)
	_pick_rail(e, "auto")
	var it: Dictionary = e.lay_rail(Vector2(x, y_foot), Vector2(x, y_top)).item
	assert_almost_eq(float(it.z1) - e.document.height_at(Vector2(x, y_foot)), 1.0, 1e-6, "1 over the foot")
	assert_almost_eq(float(it.z2) - e.document.height_at(Vector2(x, y_top)), 1.0, 1e-6, "1 over the top")
	assert_gt(float(it.z2), float(it.z1) + 1.0, "the bar climbs with the ramp")
	# The drawing: every piece's depth is at least the ramp's (it is drawn over the ramp, not under it).
	var ramp_z: int = int(e.elevation.areas[e.elevation.areas.size() - 1].z_index)
	for p in e.rail_drawing.pieces:
		assert_gt(p.base_z, ramp_z, "drawn over the ramp's own drawing")
		var ground := e.document.height_at(p.mid)
		assert_almost_eq(float(p.mid_height) - ground, 1.0, 0.01, "one over the ramp under the piece")
		assert_eq(p.shadow.size(), 2, "its shadow lies on the ramp")


func test_a_rail_on_a_rooftop_is_drawn_over_it_with_its_shadow_on_the_roof() -> void:
	var e := _editor()
	_with_roof(e)
	_pick_rail(e, "auto")
	var it: Dictionary = _drag_lay(e, Vector2(-28, -58), Vector2(-16, -58), 4.0, 4.0).item
	assert_not_null(e.rail_drawing)
	for p in e.rail_drawing.pieces:
		assert_eq(p.shadow.size(), 2)
		assert_almost_eq(float(p.mid_height), 4.0, 1e-6)
	assert_eq(e.rail_drawing.shadows.lines.size(), 0)
	assert_eq(it.z1, 4.0)
