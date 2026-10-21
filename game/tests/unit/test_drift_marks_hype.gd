extends GutTest
## Task T-249: the drift trail heats up with the combo. Marks take the heat
## step (the combo heat's own thresholds) when laid and keep it.

const MarksScene := preload("res://scenes/driving/drift_marks.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")


func _marks() -> Node2D:
	var m: Node2D = MarksScene.instantiate()
	add_child_autofree(m)
	m.set_process(false)
	return m


func _drift(m: Node2D, steps := 5, from_x := 0.0) -> void:
	for i in steps:
		m.lay(true, Vector2(from_x + 0.5 * i, 0.0), 0.3)
	m.lay(false, Vector2.ZERO, 0.0)


func test_the_step_follows_the_combo_heat_thresholds() -> void:
	var m := _marks()
	var cases := {1.0: 0, 1.99: 0, 2.0: 1, 2.99: 1, 3.0: 2, 3.99: 2, 4.0: 3, 6.0: 3}
	for mult in cases:
		m.set_multiplier(mult)
		assert_eq(m.heat_step, cases[mult], "x%s" % mult)
		assert_eq(m.heat_step, ComboHeat.step_for(mult))


func test_marks_take_the_step_they_are_laid_at_and_keep_it() -> void:
	var m := _marks()
	var x := 0.0
	for mult in [1.0, 2.0, 3.0, 4.0]:
		m.set_multiplier(mult)
		_drift(m, 5, x)
		x += 10.0
	m.set_multiplier(1.0)  # the combo drops: old marks keep their look
	_drift(m, 5, x)
	var steps: Array = []
	for mark in m.marks():
		steps.append(m.step_of_mark(mark))
	steps.sort()
	assert_eq(steps, [0, 0, 0, 0, 1, 1, 2, 2, 3, 3])


func test_plain_marks_have_no_glow_or_core() -> void:
	var m := _marks()
	_drift(m)
	for line in m.pieces():
		assert_eq(line.get_child_count(), 0)


func test_each_hot_step_has_a_glow_behind_and_gets_hotter() -> void:
	var m := _marks()
	var widths: Array = []
	for step in [1, 2, 3]:
		m.set_multiplier(float(step + 1))
		_drift(m, 5, step * 10.0)
		var line: Line2D = m.pieces().back()
		var glow: Line2D = line.get_node("Glow")
		assert_true(glow.show_behind_parent)
		assert_gt(glow.width, line.width, "the glow shows round the mark")
		assert_eq(glow.get_point_count(), line.get_point_count())
		widths.append(glow.width)
	assert_true(widths[0] < widths[1] and widths[1] < widths[2])
	assert_false(m.pieces()[0].has_node("Core"), "step 1 has no core")
	assert_true(m.pieces()[m.pieces().size() - 1].has_node("Core"))


func test_sparks_only_at_hot_steps_flames_only_at_the_top() -> void:
	var m := _marks()
	m.set_multiplier(1.0)
	_drift_open(m)
	for i in 30:
		m.advance(0.05)
	assert_eq(m.get_node("HeatSparks").particles.size(), 0, "no sparks below x2")
	m.clear()
	m.set_multiplier(2.0)
	_drift_open(m)
	for i in 6:
		m.advance(0.05)
	var sparks: Array = m.get_node("HeatSparks").particles
	assert_gt(sparks.size(), 0)
	for p in sparks:
		assert_false(p.flame)
	m.clear()
	m.set_multiplier(4.0)
	_drift_open(m)
	for i in 10:
		m.advance(0.05)
	var flames := 0
	for p in m.get_node("HeatSparks").particles:
		if p.flame:
			flames += 1
	assert_gt(flames, 0)


func _drift_open(m: Node2D) -> void:
	for i in 5:
		m.lay(true, Vector2(0.5 * i, 0.0), 0.3)


func test_sparks_stop_when_the_drift_ends_and_pop_out() -> void:
	var m := _marks()
	m.set_multiplier(4.0)
	_drift_open(m)
	m.advance(0.1)
	m.lay(false, Vector2.ZERO, 0.0)
	for i in 20:
		m.advance(0.1)
	assert_eq(m.get_node("HeatSparks").particles.size(), 0)


func test_every_heat_colour_is_opaque_and_never_red() -> void:
	var m := _marks()
	assert_eq(m.heat_looks.size(), 3)
	var colors: Array = []
	for look in m.heat_looks:
		colors.append_array([look.glow_color, look.core_color])
		colors.append_array(look.flicker_colors)
		colors.append_array(look.spark_colors)
	colors.append_array(m.get_node("HeatSparks").FLAME_COLORS)
	for c: Color in colors:
		assert_eq(c.a, 1.0)
		assert_gt(c.r, 0.9, "yellows, oranges, white-hot")
		assert_gt(c.g, 0.55, "never Redgull red")
		assert_gt(c.g, c.r * 0.55)


func test_the_looks_use_the_combo_heat_palette() -> void:
	var m := _marks()
	var allowed: Array = ComboHeat.all_colors()
	allowed.append(Color(1.0, 0.72, 0.16))
	for look in m.heat_looks:
		assert_true(allowed.has(look.glow_color), "glow %s" % look.glow_color)
		assert_true(allowed.has(look.core_color))


func test_the_run_feeds_the_combo_to_the_marks() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.drift_marks.set_process(false)
	assert_eq(run.drift_marks.heat_step, 0)
	run.state._set_combo(2.5)
	assert_eq(run.drift_marks.heat_step, 1)
	run.state._set_combo(4.2)
	assert_eq(run.drift_marks.heat_step, 3)
	run.start_run()
	assert_eq(run.drift_marks.heat_step, 0, "a new run starts plain")


func test_the_drift_prototype_keeps_the_plain_marks() -> void:
	var proto: Node = PrototypeScene.instantiate()
	add_child_autofree(proto)
	proto.drift_marks.set_process(false)
	assert_eq(proto.drift_marks.heat_step, 0)
	proto.drift_marks.lay(true, Vector2.ZERO, 0.0)
	proto.drift_marks.lay(true, Vector2(1, 0), 0.0)
	for line in proto.drift_marks.pieces():
		assert_eq(line.get_child_count(), 0)
