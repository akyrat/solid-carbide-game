extends GutTest
## Task T-600: slide marks (lighter marks from all four tyres while the car has sideways
## speed without W and without drifting) and tire marks that last half as long.

const MarksScene := preload("res://scenes/driving/drift_marks.tscn")
const RunScene := preload("res://scenes/run/run.tscn")

const W_AND_D := [true, false, -1.0]
const NOTHING := [false, false, 0.0]
const W_ONLY := [true, false, 0.0]


func _run() -> Node2D:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.drift_marks.set_process(false)
	return run


func _drive(car: CharacterBody2D, input: Array, steps: int) -> void:
	car.use_keyboard = false
	car.scripted_input = input
	for i in steps:
		car.physics_step()


func _kinds(marks: Node2D) -> Dictionary:
	var out := {"drift": 0, "slide": 0}
	for m in marks.marks().values():
		out["slide" if m.slide else "drift"] += 1
	return out


func test_sliding_out_of_a_drift_without_w_leaves_lighter_marks_from_all_four_tyres() -> void:
	var run := _run()
	var marks: Node2D = run.drift_marks
	_drive(run.car, W_AND_D, 40)
	assert_true(run.car.model.is_drifting)
	assert_false(marks.is_sliding())
	_drive(run.car, NOTHING, 10)
	assert_false(run.car.model.is_drifting)
	assert_gt(absf(run.car.model.sideways_speed()), marks.slide_start_speed, "sideways without W")
	assert_true(marks.is_sliding())
	var tyres_with_slide := {}
	for p in marks._pieces:
		if p.slide:
			tyres_with_slide[p.tyre] = true
			assert_almost_eq(p.line.modulate.a, marks.slide_alpha, 0.0001)
			assert_lt(marks.slide_alpha, 1.0, "lighter than a drift mark")
	assert_eq(tyres_with_slide.size(), 4, "front and back wheels")


func test_a_straight_coast_leaves_no_marks() -> void:
	var run := _run()
	var marks: Node2D = run.drift_marks
	_drive(run.car, W_ONLY, 60)
	_drive(run.car, NOTHING, 80)
	assert_almost_eq(run.car.model.sideways_speed(), 0.0, 0.5)
	assert_false(marks.is_laying())
	assert_eq(marks.marks().size(), 0)
	assert_eq(marks.segment_count(), 0)


func test_w_held_while_sideways_leaves_no_slide_marks() -> void:
	var run := _run()
	var marks: Node2D = run.drift_marks
	_drive(run.car, W_AND_D, 40)
	_drive(run.car, NOTHING, 3)
	_drive(run.car, W_ONLY, 4)
	assert_false(marks.is_sliding(), "accelerating is not a slide")


func test_slide_marks_stop_below_the_stop_speed() -> void:
	var run := _run()
	var marks: Node2D = run.drift_marks
	_drive(run.car, W_AND_D, 40)
	_drive(run.car, NOTHING, 400)  # the sideways speed fades away
	assert_lt(absf(run.car.model.sideways_speed()), marks.slide_stop_speed)
	assert_false(marks.is_sliding())


func test_a_slide_joins_the_drift_mark_when_set_to() -> void:
	var m: Node2D = MarksScene.instantiate()
	add_child_autofree(m)
	m.set_process(false)
	for i in 10:
		m.lay(true, Vector2(0.5 * i, 0.0), 0.0)
	var before: Dictionary = m.marks()
	var last_drift: Vector2 = m._open[0].line.get_point_position(m._open[0].line.get_point_count() - 1)
	for i in 10:
		m.lay(false, Vector2(5.0 + 0.5 * i, 0.0), 0.0, NAN, true)
	var first_slide = null
	for p in m._pieces:
		if p.slide and p.tyre == 0:
			first_slide = p
			break
	assert_not_null(first_slide)
	assert_eq(first_slide.line.get_point_position(0), last_drift, "starts where the drift mark ended")
	assert_eq(first_slide.mark, m._pieces[0].mark, "the same mark")
	# And not joined when switched off.
	var n: Node2D = MarksScene.instantiate()
	add_child_autofree(n)
	n.set_process(false)
	n.slide_joins_drift = false
	for i in 10:
		n.lay(true, Vector2(0.5 * i, 0.0), 0.0)
	for i in 10:
		n.lay(false, Vector2(5.0 + 0.5 * i, 0.0), 0.0, NAN, true)
	for p in n._pieces:
		if p.slide and p.tyre == 0:
			assert_ne(p.mark, n._pieces[0].mark, "a new mark")


func test_drift_marks_keep_their_look_and_slide_marks_have_no_heat() -> void:
	var m: Node2D = MarksScene.instantiate()
	add_child_autofree(m)
	m.set_process(false)
	m.set_multiplier(5.0)
	for i in 10:
		m.lay(true, Vector2(0.5 * i, 0.0), 0.0)
	for i in 10:
		m.lay(false, Vector2(5.0 + 0.5 * i, 0.0), 0.0, NAN, true)
	for p in m._pieces:
		if p.slide:
			assert_eq(p.step, 0)
			assert_null(p.glow)
			assert_almost_eq(p.line.modulate.a, m.slide_alpha, 0.0001)
		else:
			assert_eq(p.step, 3)
			assert_eq(p.line.modulate.a, 1.0)


func test_every_tire_mark_lasts_half_as_long_as_drift_marks_did() -> void:
	var m: Node2D = MarksScene.instantiate()
	add_child_autofree(m)
	m.set_process(false)
	const OLD_TOTAL := 6.0 + 1.0  # lifetime + fade before T-600
	assert_almost_eq(m.lifetime + m.fade_time, OLD_TOTAL / 2.0, 0.0001)
	for kind in ["drift", "slide"]:
		m.clear()
		for i in 12:
			m.lay(kind == "drift", Vector2(0.5 * i, 0.0), 0.0, NAN, kind == "slide")
		m.lay(false, Vector2(20, 0), 0.0)
		assert_gt(m.pieces().size(), 0)
		m.advance(OLD_TOTAL / 2.0 - 0.01)
		assert_gt(m.pieces().size(), 0, "%s: still there just before" % kind)
		m.advance(0.02)
		assert_eq(m.pieces().size(), 0, "%s: gone after half of the old time" % kind)


func test_a_slide_costs_no_more_segments_per_second_than_a_drift() -> void:
	# Both at the car's cruise speed (11 units/s = 0.22 units a step), 3 seconds.
	var steps := 150
	var counts := {}
	for kind in ["drift", "slide"]:
		var m: Node2D = MarksScene.instantiate()
		add_child_autofree(m)
		m.set_process(false)
		var t0 := Time.get_ticks_usec()
		for i in steps:
			m.lay(kind == "drift", Vector2(0.22 * i, 0.0), 0.0, NAN, kind == "slide")
		counts[kind] = [m.segment_count(), m.pieces().size(), Time.get_ticks_usec() - t0]
	gut.p("segments, pieces, usec for %d steps: %s" % [steps, counts])
	assert_lte(counts.slide[0], counts.drift[0], "no more segments a second")
	assert_lte(counts.slide[1], counts.drift[1] + 1, "no more Line2D pieces a second")
