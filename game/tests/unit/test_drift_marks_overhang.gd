extends GutTest
## Task T-411: a rear tyre hanging over a rooftop's edge lays no tyre mark, so
## marks never streak down the wall. Before T-411 each tyre's mark was lifted by
## the ground under that tyre alone (point_px), so a tyre over the street
## dropped its line 3 units down the side.
##
## Ground: data/level/elevation_test.json, platform (-8, -8) to (8, 8), height 3.
## view_basis stays the identity, so a point is lifted straight up by h x 16 px.

const MarksScene := preload("res://scenes/driving/drift_marks.tscn")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const PX := 16.0

var _ground


func _marks() -> Node2D:
	_ground = GroundHeightScript.from_file()
	var m: Node2D = MarksScene.instantiate()
	add_child_autofree(m)
	m.set_process(false)
	m.height_at = func(u: Vector2) -> float: return _ground.height_at(u)
	m.depth_for = func(_u: Vector2, _r: float, _h: float) -> int: return 1
	return m


## The lowest ground any laid point stands on: un-lifting each point by every
## candidate height and keeping the one that matches its ground.
func _lowest_lift(m: Node2D) -> float:
	var lowest := INF
	for line in m.pieces():
		for i in line.get_point_count():
			var p: Vector2 = line.get_point_position(i)
			# A point at flat (x, y) lifted by h is drawn at (x, y - h * PX).
			for h in [0.0, 3.0]:
				var flat := Vector2(p.x, p.y + h * PX) / PX
				if absf(_ground.height_at(flat) - h) < 0.01:
					lowest = minf(lowest, h)
	return lowest


func test_a_tyre_over_the_roof_edge_lays_nothing_and_its_line_ends() -> void:
	var m := _marks()
	# Drifting east along the south edge (y = 8): the right rear tyre (y + 0.375) hangs over it.
	for i in 20:
		m.lay(true, Vector2(-6.0 + 0.4 * i, 7.8), 0.0, 3.0)
	var by_mark: Dictionary = m.marks()
	assert_eq(by_mark.size(), 1, "only the left tyre, on the roof, lays a mark")
	for mark in by_mark:
		assert_eq(by_mark[mark].tyre, 0)
	assert_almost_eq(_lowest_lift(m), 3.0, 0.1, "no point drops below the roof")


func test_a_tyre_leaving_the_roof_ends_its_mark_and_starts_a_new_one_back_on() -> void:
	var m := _marks()
	# On the roof, then the right tyre swings over the edge, then back on.
	for i in 10:
		m.lay(true, Vector2(-6.0 + 0.4 * i, 7.3), 0.0, 3.0)
	for i in 10:
		m.lay(true, Vector2(-2.0 + 0.4 * i, 7.8), 0.0, 3.0)
	assert_null(m._open[1], "the right tyre's line ended over the edge")
	for i in 10:
		m.lay(true, Vector2(2.0 + 0.4 * i, 7.3), 0.0, 3.0)
	var right_marks := 0
	for mark in m.marks():
		if m.marks()[mark].tyre == 1:
			right_marks += 1
	assert_eq(right_marks, 2, "a new right mark once back on the roof")
	assert_almost_eq(_lowest_lift(m), 3.0, 0.1)


func test_without_a_car_height_nothing_changes() -> void:
	var m := _marks()
	for i in 10:
		m.lay(true, Vector2(-6.0 + 0.4 * i, 7.8), 0.0)
	assert_eq(m.marks().size(), 2, "both tyres, as before T-411")


func test_on_the_street_both_tyres_lay() -> void:
	var m := _marks()
	for i in 10:
		m.lay(true, Vector2(20.0 + 0.4 * i, 20.0), 0.0, 0.0)
	assert_eq(m.marks().size(), 2)
