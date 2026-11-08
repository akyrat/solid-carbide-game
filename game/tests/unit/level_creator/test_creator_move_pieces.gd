extends GutTest
## Task T-581, added scope (the board, 2026-11-08: "I want to be able to move things on the map, like
## obstacles that I place, and the decoration as well"): with nothing picked, press on a placed piece and
## drag it. It follows the mouse on the free step, snaps with Shift, keeps its id (pairs and links stay
## valid), is refused where a placement would be (and stays put), and a rooftop takes what stands on it
## along. The test levels go under the test folder, never into game/data/levels/.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const KaijuSigns := preload("res://scripts/level/kaiju_signs.gd")


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	e.level_data["spawn"] = {"x": 111.0, "y": 111.0, "heading": 270}
	e.levels_dir = RunPaths.file("t581_move_levels")
	add_child_autofree(e)
	return e


func _place(e: LevelCreatorEditor, id: String, at: Vector2, view: String = "") -> Dictionary:
	e.panel.pick(id)
	for i in 4:
		if view == "" or e.pick_view == view:
			break
		e.rotate_pick()
	var p := e.place_asset(id, at)
	e.panel.pick("")
	assert_false(p.is_empty(), "%s placed at %s" % [id, at])
	return p


func _r(item: Dictionary) -> Rect2:
	return Rect2(float(item.x), float(item.y), float(item.w), float(item.h))


## Presses at `from`, drags to `to` and releases there (the editor's own drag functions).
func _drag(e: LevelCreatorEditor, from: Vector2, to: Vector2) -> bool:
	assert_true(e.press_piece(from), "a piece under %s" % from)
	e.update_piece_drag(from.lerp(to, 0.5))
	e.update_piece_drag(to)
	return e.end_piece_drag(to)


func _run_check(data: Dictionary, file_name: String) -> Array:
	var path := RunPaths.file(file_name)
	assert_eq(LevelStore.save_level(path, data), OK)
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output).strip_edges()]


# ---- Each kind ----------------------------------------------------------------------------------

func test_each_kind_moves_by_the_drag_on_the_free_step() -> void:
	var cases := [["skyscraper-1", ""], ["short-3", ""], ["building-small", ""], ["boulder-a", ""],
		["prop-barrier", "north"], ["prop-street-lamp", "north"], ["prop-water-tank", "east"], ["crater-2", ""],
		["alert-sign-head", ""], ["rooftop-3", ""], ["ramp-0-3", "north"]]
	for c in cases:
		var e := _editor()
		var p := _place(e, c[0], Vector2(-40, -40), c[1])
		var before := e.document.piece_rect(p)
		var id := str(p.item.get("id", ""))
		var grab := before.get_center()
		assert_true(_drag(e, grab, grab + Vector2(13.37, -7.62)), "%s moved" % c[0])
		var after := e.document.piece_rect(p)
		assert_eq(after.position, before.position + Vector2(13.25, -7.5), "%s: by the drag, on quarter units" % c[0])
		assert_eq(after.size, before.size, "%s: same size" % c[0])
		assert_eq(str(p.item.get("id", "")), id, "%s keeps its id" % c[0])


func test_shift_snaps_the_moved_piece_to_the_grid_and_its_neighbours() -> void:
	var e := _editor()
	var a := _place(e, "skyscraper-1", Vector2(40, 40))  # 40..52
	var b := _place(e, "skyscraper-1", Vector2(70, 40))
	e.snap_held = true
	# Dragged to 2.6 units east of a: Shift puts it flush against a's east wall.
	assert_true(_drag(e, Vector2(76, 46), Vector2(60.6, 46.3)))
	assert_eq(_r(b.item).position, Vector2(52, 40), "flush against its neighbour")
	e.snap_held = false
	assert_true(_drag(e, Vector2(58, 46), Vector2(61.1, 47.3)))
	assert_eq(_r(b.item).position, Vector2(55, 41.25), "free: by the drag")
	assert_eq(_r(a.item).position, Vector2(40, 40), "the other one did not move")


func test_a_click_without_a_drag_only_selects() -> void:
	var e := _editor()
	var p := _place(e, "boulder-a", Vector2(10, 10))
	assert_false(_drag(e, Vector2(11.5, 11.5), Vector2(11.55, 11.6)), "no move")
	assert_eq(Vector2(p.item.x, p.item.y), Vector2(11.5, 11.5))
	assert_true(LevelCreatorEditor._same_piece(e.selected, p), "selected")


func test_moving_with_the_mouse_and_esc() -> void:
	var e := _editor()
	var p := _place(e, "prop-crates", Vector2(10, 10), "north")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = e.units_to_screen(Vector2(11, 11))
	e._on_map_input(press)
	var move := InputEventMouseMotion.new()
	move.position = e.units_to_screen(Vector2(21.3, 16.1))
	e._on_map_input(move)
	assert_false(e.piece_drag.is_empty(), "dragging")
	assert_eq(e.piece_drag.ghost[0].position, Vector2(20.25, 15.0), "the outline shows where it lands")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = move.position
	e._on_map_input(release)
	assert_eq(_r(p.item).position, Vector2(20.25, 15.0))
	# Esc during a drag: it stays.
	e._on_map_input(press)
	press.position = e.units_to_screen(Vector2(21, 16))
	e._on_map_input(press)
	move.position = e.units_to_screen(Vector2(40, 40))
	e._on_map_input(move)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	e._unhandled_key_input(esc)
	assert_true(e.piece_drag.is_empty())
	assert_eq(_r(p.item).position, Vector2(20.25, 15.0), "Esc: back where it was")


# ---- Pairs and links ----------------------------------------------------------------------------

func test_paired_obstacles_keep_their_pair_when_moved() -> void:
	var e := _editor()
	var a := _place(e, "boulder-a", Vector2(0, 0))
	var b := _place(e, "prop-barrier", Vector2(8, 0), "north")
	var pair := e.document.make_pair(a, b)
	assert_false(pair.is_empty())
	var refs := [str(pair.a), str(pair.b)]
	assert_true(_drag(e, Vector2(1.5, 1.5), Vector2(-4.25, 6.0)))
	assert_true(_drag(e, Vector2(10, 0.5), Vector2(14.5, 3.75)))
	assert_eq(e.document.pairs().size(), 1)
	assert_eq([str(e.document.pairs()[0].a), str(e.document.pairs()[0].b)], refs, "the same two obstacles")
	var line := ObstaclePairs.line_of(e.level_data, e.document.pairs()[0])
	assert_false(line.is_empty(), "the pair's line follows them")
	assert_almost_eq(line.a, Vector2(-4.25, 6.0), Vector2(0.01, 0.01))
	var res := _run_check(e.document.file_data("t581 pair"), "t581_move_pair.json")
	assert_eq(res, [0, "OK"])


## A rooftop at 3 (0..16, 0..16), a ramp 0 to 3 climbing north onto its south side, a 6 on it with a
## prop, and a boulder on the street.
func _garage(e: LevelCreatorEditor) -> Dictionary:
	var roof := _place(e, "rooftop-3", Vector2(0, 0))
	var ramp := _place(e, "ramp-0-3", Vector2(3, 16), "north")
	e.set_platform_size("s")
	var six := _place(e, "rooftop-6", Vector2(2, 2))
	var lamp := _place(e, "prop-roof-vent", Vector2(12, 12), "north")
	var rock := _place(e, "boulder-b", Vector2(-20, 30))
	assert_eq(str(ramp.item.platform), str(roof.item.id))
	assert_eq(str(six.item.get("on", "")), str(roof.item.id))
	return {"roof": roof, "ramp": ramp, "six": six, "lamp": lamp, "rock": rock}


func test_a_rooftop_takes_its_ramps_rooftops_and_objects_along() -> void:
	var e := _editor()
	var g := _garage(e)
	assert_true(_drag(e, Vector2(14, 6), Vector2(14 + 30.25, 6 - 20.5)))
	assert_eq(_r(g.roof.item).position, Vector2(30.25, -20.5))
	assert_eq(_r(g.ramp.item).position, Vector2(33.25, -4.5), "its ramp came along")
	assert_eq(_r(g.six.item).position, Vector2(32.25, -18.5), "the 6 on it came along")
	assert_eq(_r(g.lamp.item).position, Vector2(42.25, -8.5), "the object on it came along")
	assert_eq(Vector2(g.rock.item.x, g.rock.item.y), Vector2(-18.5, 31.5), "the boulder on the street stayed")
	assert_eq(str(g.ramp.item.platform), str(g.roof.item.id), "still linked")
	assert_eq(str(g.six.item.get("on", "")), str(g.roof.item.id))
	assert_eq(_run_check(e.document.file_data("t581 garage"), "t581_move_garage.json"), [0, "OK"])


func test_a_ramp_moved_off_its_rooftop_unlinks_and_back_on_links() -> void:
	var e := _editor()
	var g := _garage(e)
	assert_true(_drag(e, Vector2(8, 20), Vector2(8 + 40, 20)))
	assert_eq(str(g.ramp.item.platform), "", "off the rooftop: no link")
	# Back, dropped half a unit short of the side: it goes onto it (within the free reach) and links.
	assert_true(_drag(e, Vector2(48, 20), Vector2(8.3, 20.5)))
	assert_eq(_r(g.ramp.item).position.y, 16.0, "onto the side")
	assert_eq(str(g.ramp.item.platform), str(g.roof.item.id), "linked again")


# ---- Refusals -----------------------------------------------------------------------------------

func test_a_move_a_placement_would_refuse_is_refused_and_the_piece_stays() -> void:
	var e := _editor()
	var g := _garage(e)
	var other := _place(e, "rooftop-3", Vector2(60, 0))
	# A rooftop onto another rooftop: refused, grey outline while dragging, back where it was.
	assert_true(e.press_piece(Vector2(62, 2)))  # an S rooftop (8 x 8)
	e.update_piece_drag(Vector2(6, 2))
	assert_ne(str(e.piece_drag.problem), "", "the outline is grey")
	assert_false(e.end_piece_drag(Vector2(6, 2)))
	assert_eq(_r(other.item).position, Vector2(60, 0), "it stayed")
	assert_eq(e.message_label.text, CreatorTexts.get_text("overlap_message"))
	# An object into a skyscraper.
	var sky := _place(e, "skyscraper-1", Vector2(-60, -60))
	assert_false(_drag(e, Vector2(-18.5, 31.5), Vector2(-54, -54)))
	assert_eq(Vector2(g.rock.item.x, g.rock.item.y), Vector2(-18.5, 31.5))
	# A skyscraper over an object.
	assert_false(_drag(e, Vector2(-54, -54), Vector2(-18, 31)))
	assert_eq(_r(sky.item).position, Vector2(-60, -60))
	# A skyscraper over the start.
	assert_false(_drag(e, Vector2(-54, -54), Vector2(110, 110)))
	assert_eq(e.message_label.text, CreatorTexts.get_text("spawn_blocked"))
	assert_eq(_r(sky.item).position, Vector2(-60, -60))
	# Nothing changed: the level still passes.
	assert_eq(_run_check(e.document.file_data("t581 refused"), "t581_move_refused.json"), [0, "OK"])


func test_a_piece_dragged_past_the_map_edge_stays_on_the_map() -> void:
	var e := _editor()
	var p := _place(e, "skyscraper-1", Vector2(90, 0))
	assert_true(_drag(e, Vector2(96, 6), Vector2(130, 6)))
	assert_eq(_r(p.item).position, Vector2(108, 0), "against the map's edge")


func test_a_skyscrapers_banner_moves_with_it() -> void:
	var e := _editor()
	e.pick_banner = true
	var sky := _place(e, "skyscraper-1", Vector2(0, 0))
	e.pick_banner = false
	var banner := e.document.place_banner("alert-banner-head", sky.item, "south", 4.0, 3.0)
	assert_false(banner.is_empty())
	assert_true(_drag(e, Vector2(6, 6), Vector2(26.5, 6)))
	assert_eq(KaijuSigns.building_of(e.level_data, banner.item), sky.item, "still on its skyscraper")


func test_a_moved_level_saves_reopens_and_plays_its_heights() -> void:
	var e := _editor()
	var g := _garage(e)
	assert_true(_drag(e, Vector2(14, 6), Vector2(20.75, 9.25)))
	var path := RunPaths.file("t581_moved_level.json")
	assert_eq(LevelStore.save_level(path, e.document.file_data("t581 moved")), OK)
	var again := LevelStore.load_level(path)
	assert_eq(again.platforms[0].id, g.roof.item.id)
	assert_eq(Vector2(float(again.platforms[0].x), float(again.platforms[0].y)), Vector2(6.75, 3.25))
	var gh := GroundHeight.new()
	assert_true(gh.load_data(again), gh.error)
	assert_almost_eq(gh.height_at(Vector2(7.5, 4.0)), 3.0, 0.001, "the rooftop where it was moved")
	assert_almost_eq(gh.height_at(Vector2(1, 1)), 0.0, 0.001, "the street where it was")
