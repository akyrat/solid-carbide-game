extends GutTest
## Task T-237: in the level creator, pieces snap to the map's tile grid (edges on even units, as
## check_level.py checks) and to close neighbours within LevelSnapping.SNAP_DISTANCE (a ramp's top
## end onto a rooftop's side, a 6 onto its 3's edges, a building against a road); a rooftop or ramp
## that would overlap in a way check_level.py refuses is not placed, and the editor shows the overlap
## message of creator_texts.json.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	add_child_autofree(e)
	return e


func _place(e: LevelCreatorEditor, id: String, units: Vector2, rotate := false) -> Dictionary:
	e.panel.pick(id)
	if rotate:
		e.rotate_pick()
	return e.place_asset(id, units)


func _r(item: Dictionary) -> Rect2:
	return Rect2(float(item.x), float(item.y), float(item.w), float(item.h))


func _even(v: float) -> bool:
	return is_equal_approx(fposmod(v, 2.0), 0.0) or is_equal_approx(fposmod(v, 2.0), 2.0)


func _run_check_level(data: Dictionary, file_name: String) -> Array:
	var path := RunPaths.file(file_name)
	assert_eq(LevelStore.save_level(path, data), OK)
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output)]


# ---- The tile grid ------------------------------------------------------------------------------

func test_pieces_placed_from_off_grid_cursors_have_their_edges_on_even_units() -> void:
	var ids := ["skyscraper-1", "short-3", "rooftop-3", "rooftop-6", "ramp-0-3", "ramp-3-6"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 237
	var e: LevelCreatorEditor
	# Each asset in its own level, six times, in slots far enough apart that nothing snaps or overlaps.
	for id in ids:
		e = _editor()
		var n := 0
		for slot in [Vector2(-110, -110), Vector2(0, -110), Vector2(-110, -40), Vector2(0, -40),
				Vector2(-110, 30), Vector2(0, 30)]:
			var cursor: Vector2 = slot + Vector2(rng.randf_range(0.05, 1.95), rng.randf_range(0.05, 1.95))
			if n % 2 == 1:
				cursor += Vector2(1.0, 1.0)
			var p := _place(e, id, cursor, n % 2 == 1)
			n += 1
			assert_false(p.is_empty(), "%s placed at %s" % [id, cursor])
			if p.is_empty():
				continue
			var r := _r(p.item)
			for v in [r.position.x, r.position.y, r.end.x, r.end.y]:
				assert_true(_even(v), "%s at %s: edge %s on an even unit" % [id, cursor, v])
		var res := _run_check_level(e.level_data, "t237_grid_%s.json" % id)
		assert_false(res[1].contains("odd unit"), "check_level.py: " + res[1])
		assert_false(res[1].contains("outside the map"), "check_level.py: " + res[1])
	# Ground and road tiles: their cell's corners.
	var g := e.place_asset("road-x_plain_g4", Vector2(13.3, -7.9))
	assert_eq(e.document.cell_corner(g.cell), Vector2(12, -8))


func test_a_boulder_goes_on_the_cell_under_the_cursor() -> void:
	var e := _editor()
	var p := _place(e, "boulder-a", Vector2(10.7, -6.3))
	assert_almost_eq(Vector2(p.item.x, p.item.y), Vector2(10, -8) + Vector2(1.5, 1.5), Vector2(0.001, 0.001))


# ---- Close neighbours ---------------------------------------------------------------------------

func test_the_snap_distance_is_documented() -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	assert_true(readme.contains("SNAP_DISTANCE"), "game/README.md names the snap distance")
	assert_true(readme.contains("%d units" % int(LevelSnapping.SNAP_DISTANCE)), "and gives its value")


func test_a_ramp_snaps_its_top_end_onto_a_rooftops_side() -> void:
	var e := _editor()
	var r3 := _place(e, "rooftop-3", Vector2(-95.5, -95.5))  # -96..-12, -96..-66
	assert_eq(_r(r3.item), Rect2(-96, -96, 84, 30))
	# A ramp 0 to 3 (nw view: climbs the south side) two units short of the side.
	var ramp := _place(e, "ramp-0-3", Vector2(-80.5, -63.5))  # the clicked cell's corner: (-82, -64)
	assert_eq(_r(ramp.item).position, Vector2(-82, -66), "its top end on the rooftop's south side")
	assert_eq(ramp.item.platform, r3.item.id, "and it climbs that rooftop")


func test_a_ramp_over_a_rooftops_corner_slides_along_the_side_into_it() -> void:
	var e := _editor()
	var r3 := _place(e, "rooftop-3", Vector2(-95.5, -95.5))
	var ramp := _place(e, "ramp-0-3", Vector2(-19.5, -63.5))  # (-20, -64): 2 units past the east end
	assert_eq(_r(ramp.item).position, Vector2(-22, -66))
	assert_eq(ramp.item.platform, r3.item.id)


func test_a_ramp_3_to_6_snaps_onto_a_6s_side_and_the_whole_passes_check_level() -> void:
	var e := _editor()
	var r3 := _place(e, "rooftop-3", Vector2(-95.5, -95.5))
	var r6 := _place(e, "rooftop-6", Vector2(-41.5, -95.5))  # -42..-12: the 3's east end
	assert_eq(r6.item.on, r3.item.id)
	var a := _place(e, "ramp-0-3", Vector2(-84.5, -62.5))
	# A ramp 3 to 6 (nw: climbs the west side), its top end 4 units off the 6's west side.
	var b := _place(e, "ramp-3-6", Vector2(-57.5, -84.5))  # (-58, -86) .. x end -46
	assert_eq(_r(b.item).position, Vector2(-54, -86))
	assert_eq(b.item.platform, r6.item.id)
	assert_eq(a.item.platform, r3.item.id)
	var res := _run_check_level(e.level_data, "t237_heights.json")
	assert_eq(res[0], 0, "check_level.py: " + res[1])


func test_a_ramp_farther_away_does_not_move() -> void:
	var e := _editor()
	_place(e, "rooftop-3", Vector2(-95.5, -95.5))
	var ramp := _place(e, "ramp-0-3", Vector2(-80.5, -57.5))  # (-82, -58): 8 units off the side
	assert_eq(_r(ramp.item).position, Vector2(-82, -58), "stays where it was clicked")
	assert_eq(ramp.item.platform, "")


func test_a_6_lines_up_with_its_3s_edges() -> void:
	var e := _editor()
	var r3 := _place(e, "rooftop-3", Vector2(-95.5, -95.5))
	# Clicked at (-40, -94): 2 units past the 3's east edge and 2 below its north edge.
	var r6 := _place(e, "rooftop-6", Vector2(-39.5, -93.5))
	assert_eq(_r(r6.item), Rect2(-42, -96, 30, 30), "its east and north edges on the 3's")
	assert_eq(r6.item.on, r3.item.id, "and it stands on the 3")


func test_a_6_well_inside_its_3_does_not_move() -> void:
	var e := _editor()
	_place(e, "rooftop-3", Vector2(-95.5, -95.5))
	var r6 := _place(e, "rooftop-6", Vector2(-79.5, -95.5))  # -80..-50: 16 and 38 from the ends
	assert_eq(_r(r6.item).position, Vector2(-80, -96))


func test_a_building_snaps_against_a_road() -> void:
	var e := _editor()
	for y in range(-20, 40, 2):
		e.place_asset("road-y_plain_g4", Vector2(0.5, y + 0.5))  # a road one cell wide, x 0..2
	var near := _place(e, "skyscraper-2", Vector2(4.5, 10.5))  # 2 units off the road
	assert_eq(_r(near.item).position, Vector2(2, 10), "flush against the road")
	var far := _place(e, "skyscraper-2", Vector2(-19.5, 10.5))  # its east edge 6 units off the road
	assert_eq(_r(far.item).position, Vector2(-20, 10), "farther away: stays")


func test_a_building_snaps_against_a_building() -> void:
	var e := _editor()
	_place(e, "skyscraper-1", Vector2(40.5, 40.5))  # 40..52
	var b := _place(e, "short-1", Vector2(54.5, 42.5))  # (54, 42): 2 off its east side, 2 off its top
	assert_eq(_r(b.item).position, Vector2(52, 40), "flush on the east, lined up on the north")
	var c := _place(e, "short-1", Vector2(40.5, 62.5))  # 10 units below: too far
	assert_eq(_r(c.item).position, Vector2(40, 62))


func test_the_preview_shows_the_snapped_place() -> void:
	var e := _editor()
	_place(e, "rooftop-3", Vector2(-95.5, -95.5))
	e.panel.pick("ramp-0-3")
	var at := e.placement_at(Vector2(-80.5, -63.5))
	assert_eq(at.corner, Vector2(-82, -66))
	assert_eq(at.snapped, "ramp")


# ---- Overlaps the level check refuses -----------------------------------------------------------

func test_overlapping_rooftops_are_not_placed_and_the_message_shows() -> void:
	var e := _editor()
	_place(e, "rooftop-3", Vector2(-95.5, -95.5))
	assert_eq(e.message_label.text, "")
	# A second 3 across the first one's middle: neither stands on the other.
	var p := _place(e, "rooftop-3", Vector2(-59.5, -79.5))
	assert_eq(p, {}, "not placed")
	assert_eq(e.level_data.platforms.size(), 1)
	assert_eq(e.elevation.areas.size(), 1, "nor drawn")
	assert_eq(e.message_label.text, CreatorTexts.get_text("overlap_message"))
	assert_ne(e.last_problem, "")
	# check_level.py refuses that layout too.
	var data: Dictionary = e.level_data.duplicate(true)
	data.platforms.append({"id": "roof-x", "x": -60, "y": -80, "w": 84, "h": 30, "height": 3})
	var res := _run_check_level(data, "t237_overlap.json")
	assert_eq(res[0], 1)
	assert_string_contains(res[1], "overlap")
	# A piece placed fine afterwards clears the message.
	assert_false(_place(e, "rooftop-6", Vector2(60.5, 60.5)).is_empty())
	assert_eq(e.message_label.text, "")


func test_a_ramp_half_on_a_rooftop_is_not_placed() -> void:
	var e := _editor()
	_place(e, "rooftop-3", Vector2(-95.5, -95.5))
	var p := _place(e, "ramp-0-3", Vector2(-49.5, -71.5))  # y -72..-60 across the 3's south side
	assert_eq(p, {})
	assert_eq(e.level_data.ramps.size(), 0)
	assert_eq(e.message_label.text, CreatorTexts.get_text("overlap_message"))


func test_a_rooftop_over_a_placed_ramp_is_not_placed() -> void:
	var e := _editor()
	_place(e, "ramp-0-3", Vector2(20.5, 20.5))  # 20..30, 20..32
	var p := _place(e, "rooftop-6", Vector2(14.5, -3.5))  # 14..44, -4..26: over half the ramp
	assert_eq(p, {})
	assert_eq(e.level_data.platforms.size(), 0)
	assert_eq(e.message_label.text, CreatorTexts.get_text("overlap_message"))


func test_a_6_wholly_on_a_3_is_placed() -> void:
	var e := _editor()
	_place(e, "rooftop-3", Vector2(-95.5, -95.5))
	assert_false(_place(e, "rooftop-6", Vector2(-79.5, -95.5)).is_empty())
	assert_eq(e.message_label.text, "")
