extends GutTest
## Tests for the challenge drivability check (task T-021): tools/challenge_checker.gd.

const Checker := preload("res://tools/challenge_checker.gd")
const CarModel := preload("res://scripts/driving/car_model.gd")


func _drawing(points: Array, boulders: Array = [], rows: Array = []) -> Dictionary:
	if rows.is_empty():
		for i in 40:
			rows.append("R".repeat(40))
	return {"width": 40, "height": 40, "rows": rows, "boulders": boulders,
		"arrow": {"points": points, "corridor_width": 3.0}}


## A wide, gentle curve: a quarter circle of radius 14, no boulders.
func _gentle() -> Dictionary:
	var pts := []
	for i in 9:
		var a := -PI / 2.0 + PI / 2.0 * i / 8.0
		pts.append([-7.0 + 14.0 * cos(a), 7.0 + 14.0 * sin(a)])
	return _drawing(pts)


## An impossibly tight turn: a U-turn round a boulder, with a second boulder
## outside it, leaving a gap of 0.6 units, too narrow for the car's 1 x 1 body.
func _tight() -> Dictionary:
	return _drawing([[-8, 1.6], [-2, 1.6], [0, 1.6], [1.6, 0], [0, -1.6], [-2, -1.6], [-8, -1.6]],
		[{"x": 0, "y": 0, "diameter": 3}, {"x": 3.6, "y": 0, "diameter": 3}])


func _checker(data: Dictionary) -> Object:
	var c = Checker.new()
	assert_eq(c.load_drawing(data), "", "drawing loads")
	return c


func test_wide_gentle_curve_passes() -> void:
	var c = _checker(_gentle())
	var r: Dictionary = c.check()
	assert_true(r.passed, c.summary(r, "gentle"))
	assert_true(c.summary(r, "gentle").begins_with("PASS"))


func test_impossibly_tight_turn_fails_and_says_where() -> void:
	var c = _checker(_tight())
	var r: Dictionary = c.check()
	assert_false(r.passed)
	var line: String = c.summary(r, "tight")
	assert_true(line.begins_with("FAIL"), line)
	assert_string_contains(line, "near drawing point")
	assert_string_contains(line, "units along the arrow")
	assert_true(r.where.point >= 2 and r.where.point <= 5, "fails at the U-turn: %s" % line)


func test_same_result_every_run() -> void:
	for data in [_gentle(), _tight()]:
		var a: Dictionary = _checker(data).check()
		var b: Dictionary = _checker(data).check()
		assert_eq(a.passed, b.passed)
		assert_eq(a.best.steps, b.best.steps)
		assert_eq(a.best.progress, b.best.progress)
		assert_eq(a.best.settings, b.best.settings)
		assert_eq(a.best.line, b.best.line, "same driven line, point for point")


func test_drives_the_game_car_model() -> void:
	var c = _checker(_gentle())
	var car = c.make_car(5.0)
	assert_eq(car.get_script(), CarModel, "the check drives scripts/driving/car_model.gd")
	assert_almost_eq(car.total_speed(), 5.0, 1e-9)


func test_tuning_overrides_reach_the_car() -> void:
	var c = _checker(_gentle())
	c.tuning_overrides = {"top_speed_multiplier": 3.0}
	var car = c.make_car(0.0)
	assert_almost_eq(car.tuning.top_speed(), 33.0, 1e-9)


func test_wide_curve_drive_at_top_speed_records_the_line() -> void:
	var c = _checker(_gentle())
	var r: Dictionary = c.drive(0.0, 3.5, 0.6, true)
	assert_eq(r.line.size(), r.steps + 1, "one point per physics step, plus the start")
	assert_eq(r.speeds.size(), r.line.size())


func test_centre_line_follows_the_drawing() -> void:
	var c = _checker(_drawing([[0, 0], [10, 0]]))
	assert_almost_eq(c.length, 10.0, 1e-9)
	assert_almost_eq(c.point_at(4.0).x, 4.0, 1e-9)
	# The rounded curve starts and ends on the drawing's first and last points.
	var g = _checker(_gentle())
	assert_almost_eq(g.point_at(0.0).x, -7.0, 1e-6)
	assert_almost_eq(g.point_at(g.length).x, 7.0, 1e-6)


func test_drawn_car_touch_uses_its_1_by_3_shape() -> void:
	var c = _checker(_drawing([[-10, 0], [10, 0]]))
	# Centre 2.9 units to the side: nose across the arrow reaches it, nose along it does not.
	assert_true(c.drawn_car_touches(0.0, 2.9, -PI / 2.0, 0.0, 20.0))
	assert_false(c.drawn_car_touches(0.0, 2.9, 0.0, 0.0, 20.0))
	assert_true(c.drawn_car_touches(0.0, 1.9, 0.0, 0.0, 20.0))


func test_body_hits_boulder_with_its_1_by_1_body() -> void:
	var c = _checker(_drawing([[-10, 0], [10, 0]], [{"x": 0, "y": 0, "diameter": 3}]))
	assert_eq(c.body_hits_boulder(1.9, 0.0, 0.0), 0)
	assert_eq(c.body_hits_boulder(2.1, 0.0, 0.0), -1)
	# The drawn car's nose sticking over the boulder does not count.
	assert_eq(c.body_hits_boulder(2.6, 0.0, PI), -1)


func test_buildings_block_the_car() -> void:
	var rows := []
	for i in 40:
		rows.append("R".repeat(40))
	rows[20] = "R".repeat(25) + "B".repeat(15)  # cells x 5..20, y 0..1
	var c = _checker(_drawing([[0, 0.5], [10, 0.5]], [], rows))
	assert_true(c.body_hits_building(5.2, 0.5, 0.0))
	assert_false(c.body_hits_building(4.0, 0.5, 0.0))
	var r: Dictionary = c.drive(11.0, 2.5, 0.0)
	assert_false(r.passed)
	assert_eq(r.kind, "building")
