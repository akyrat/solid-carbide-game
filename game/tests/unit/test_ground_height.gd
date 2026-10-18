extends GutTest
## Ground-height query of the elevation test scene (T-182).
## Data: platform x,y in [-8, 8], height 3; ramp east of it, x in [8, 20], y in [-4, 4].

var g: GroundHeight


func before_each() -> void:
	g = GroundHeight.from_file()


func test_data_has_lists_with_one_platform_and_one_ramp() -> void:
	assert_eq(g.platforms.size(), 1)
	assert_eq(g.ramps.size(), 1)
	assert_eq(g.ramps[0].bottom_height, 0.0)
	assert_eq(g.ramps[0].top_height, g.platforms[0].height)


func test_off_the_platform_is_zero() -> void:
	assert_eq(g.height_at(Vector2(-30, 0)), 0.0)
	assert_eq(g.height_at(Vector2(0, 30)), 0.0)
	assert_eq(g.height_at(Vector2(14, 10)), 0.0, "beside the ramp")


func test_on_top_is_the_platform_height() -> void:
	var h: float = g.platforms[0].height
	assert_eq(g.height_at(Vector2(0, 0)), h)
	assert_eq(g.height_at(Vector2(-7, 7)), h)


func test_ramp_foot_middle_and_top() -> void:
	var h: float = g.platforms[0].height
	assert_almost_eq(g.height_at(Vector2(20, 0)), 0.0, 0.0001)
	assert_almost_eq(g.height_at(Vector2(14, 0)), h / 2.0, 0.0001)
	assert_almost_eq(g.height_at(Vector2(8, 0)), h, 0.0001)
	assert_almost_eq(g.height_at(Vector2(14, 3.5)), h / 2.0, 0.0001, "same across the ramp")


func test_is_ramp() -> void:
	assert_true(g.is_ramp(Vector2(14, 0)))
	assert_false(g.is_ramp(Vector2(0, 0)))
	assert_false(g.is_ramp(Vector2(14, 10)))


func test_climbing_the_ramp_changes_height_gradually() -> void:
	var step := 0.1
	var slope: float = g.platforms[0].height / 12.0
	var x := 22.0
	var prev := g.height_at(Vector2(x, 0))
	while x > 6.0:
		x -= step
		var cur := g.height_at(Vector2(x, 0))
		assert_true(absf(cur - prev) <= slope * step + 0.0001, "no jump at x=%s" % x)
		prev = cur
	assert_almost_eq(prev, g.platforms[0].height, 0.0001)
	var e := g.edge_between(Vector2(22, 0), Vector2(0, 0))
	assert_false(e.drop, "driving up the ramp is not a drop")
	e = g.edge_between(Vector2(0, 0), Vector2(22, 0))
	assert_false(e.drop, "driving down the ramp is not a drop")


func test_other_edges_are_drop_offs() -> void:
	var h: float = g.platforms[0].height
	for pair in [
		[Vector2(0, 0), Vector2(-12, 0)],  # west
		[Vector2(0, 0), Vector2(0, -12)],  # north
		[Vector2(0, 0), Vector2(0, 12)],   # south
		[Vector2(0, 6), Vector2(12, 6)],   # east side, beside the ramp
	]:
		var e := g.edge_between(pair[0], pair[1])
		assert_true(e.drop, "drop-off from %s to %s" % [pair[0], pair[1]])
		assert_almost_eq(e.height, h, 0.0001)
		assert_false(e.up)
		var back := g.edge_between(pair[1], pair[0])
		assert_true(back.drop)
		assert_true(back.up, "the same edge from below is a climb")


func test_move_that_stays_level_is_not_a_drop() -> void:
	assert_false(g.edge_between(Vector2(-5, -5), Vector2(5, 5)).drop)
	assert_false(g.edge_between(Vector2(-30, -30), Vector2(-20, -30)).drop)


func test_bad_file_gives_flat_ground() -> void:
	var flat := GroundHeight.new()
	assert_false(flat.load_file("res://data/level/does_not_exist.json"))
	assert_eq(flat.height_at(Vector2.ZERO), 0.0)
