extends GutTest
## Task T-259: the drift marks show on rooftops and ramps, in the run (elevation
## map, shared with the level creator's runs). Marks laid there are lifted with
## the ground under each tyre, drawn over the area they lie on, and stay there
## after the car leaves. Heights: roof-nw-3 (3) under (-70, -81), roof-nw-6 (6)
## under (-27, -81), the street at (0, -81).

const RunScene := preload("res://scenes/run/run.tscn")
const MarksScene := preload("res://scenes/driving/drift_marks.tscn")

var run: Node2D


func before_each() -> void:
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.drift_marks.set_process(false)


func _under(units: Vector2) -> Array:
	var ground: float = run.elevation.ground_height.height_at(units)
	return run.elevation.areas.filter(func(a) -> bool:
		return a.rect().has_point(units) and absf(a.top_height_at(units) - ground) < 0.01)


## A short drift of `steps` steps, 0.2 units each along +x, from `from`.
func _drift(from: Vector2, steps: int = 8) -> void:
	for i in steps:
		run.drift_marks.lay(true, from + Vector2(0.2 * i, 0.0), 0.0)


## Every point of every piece, drawn on screen.
func _screen_points() -> Array:
	var out: Array = []
	for line in run.drift_marks.pieces():
		for i in line.get_point_count():
			out.append(run.ISO_TRANSFORM * line.get_point_position(i))
	return out


func _check_spot(from: Vector2, label: String) -> void:
	_drift(from)
	var marks = run.drift_marks
	assert_gt(marks.pieces().size(), 0, "%s: marks laid" % label)
	var ground: float = run.elevation.ground_height.height_at(from)
	# Each point is drawn lifted by the ground's height under its tyre.
	var first: Line2D = marks.pieces()[0]
	var tyre: Vector2 = marks.rear_tyres(from, 0.0)[0]
	var want: Vector2 = run.ISO_TRANSFORM * (tyre * 16.0)
	var got: Vector2 = run.ISO_TRANSFORM * first.get_point_position(0)
	var tyre_ground: float = run.elevation.ground_height.height_at(tyre)
	assert_almost_eq(got.y, want.y - tyre_ground * 16.0, 0.01, "%s: lifted by the ground" % label)
	assert_almost_eq(got.x, want.x, 0.01, "%s: not moved sideways" % label)
	if ground > 0.0:
		for a in _under(from):
			assert_gt(first.z_index, a.z_index, "%s: marks over %s" % [label, a.name])
	else:
		assert_eq(first.z_index, 0, "%s: street marks stay on the ground layer" % label)
	for line in marks.pieces():
		assert_true(line.is_visible_in_tree(), "%s: visible" % label)
		assert_eq(line.modulate.a, 1.0, "%s: fully visible" % label)
	# They stay where they are after the drift ends and the car leaves.
	var before := _screen_points()
	var z: int = first.z_index
	marks.lay(false, from + Vector2(5, 0), 0.0)
	marks.advance(1.0)
	assert_eq(_screen_points(), before, "%s: marks stay put" % label)
	assert_eq(first.z_index, z, "%s: and keep their depth" % label)


func test_marks_on_the_street_stay_on_the_ground() -> void:
	_check_spot(Vector2(0, -81), "street")


func test_marks_on_a_height_3_rooftop() -> void:
	_check_spot(Vector2(-70, -81), "roof 3")


func test_marks_on_a_height_6_rooftop() -> void:
	_check_spot(Vector2(-27, -81), "roof 6")


func test_marks_on_a_ramp() -> void:
	var r: Rect2 = run.elevation.ground_height.ramps[0].rect
	_check_spot(r.get_center() - Vector2(0.8, 0.0), "ramp")


func test_marks_over_every_area_across_its_whole_top() -> void:
	for a in run.elevation.areas:
		var r: Rect2 = a.rect()
		for fx in [0.2, 0.5]:
			for fy in [0.2, 0.5, 0.8]:
				run.drift_marks.clear()
				run.drift_marks.lay(false, Vector2.ZERO, 0.0)
				var p := r.position + Vector2(r.size.x * fx, r.size.y * fy)
				run.drift_marks.lay(true, p, 0.0)
				run.drift_marks.lay(true, p + Vector2(0.5, 0.0), 0.0)
				for line in run.drift_marks.pieces():
					for under in _under(p):
						assert_gt(line.z_index, under.z_index, "%s at %s: marks over %s" % [a.name, p, under.name])
				run.drift_marks.lay(false, p, 0.0)


func test_hype_look_on_a_rooftop() -> void:
	run.drift_marks.set_multiplier(4.0)
	_drift(Vector2(-27, -81))
	var line: Line2D = run.drift_marks.pieces()[0]
	assert_eq(run.drift_marks.step_of_mark(1), 3, "top heat step")
	assert_not_null(line.get_node_or_null("Glow"), "glow line")
	assert_not_null(line.get_node_or_null("Core"), "core line")
	for child in line.get_children():
		assert_true(child.z_as_relative, "%s shares the piece's depth" % child.name)
	assert_eq(run.drift_marks.get_node("HeatSparks").z_index, line.z_index, "sparks at the marks' depth")


func test_fade_and_lifetime_unchanged_on_a_rooftop() -> void:
	var marks = run.drift_marks
	_drift(Vector2(-27, -81))
	marks.lay(false, Vector2.ZERO, 0.0)
	var line: Line2D = marks.pieces()[0]
	marks.advance(marks.lifetime - 0.5)
	assert_eq(line.modulate.a, 1.0, "full before its lifetime")
	marks.advance(0.5 + marks.fade_time * 0.5)
	assert_almost_eq(line.modulate.a, 0.5, 0.01, "half faded")
	marks.advance(marks.fade_time)
	assert_eq(marks.pieces().size(), 0, "removed")


func test_a_piece_closes_when_the_depth_changes() -> void:
	var m: Node2D = MarksScene.instantiate()
	add_child_autofree(m)
	m.set_process(false)
	var z := [5]
	m.height_at = func(_u: Vector2) -> float: return 1.0
	m.depth_for = func(_u: Vector2, _r: float, _h: float) -> int: return z[0]
	for i in 3:
		m.lay(true, Vector2(0.3 * i, 0.0), 0.0)
	z[0] = 9
	for i in 3:
		m.lay(true, Vector2(1.0 + 0.3 * i, 0.0), 0.0)
	var depths := []
	for line in m.pieces():
		depths.append(line.z_index)
	assert_true(depths.has(5) and depths.has(9), "pieces at both depths: %s" % [depths])
	assert_eq(m.marks().size(), 2, "still two marks (one per tyre)")


func test_flat_ground_unchanged() -> void:
	var m: Node2D = MarksScene.instantiate()
	add_child_autofree(m)
	m.set_process(false)
	m.lay(true, Vector2(2, 3), 0.0)
	m.lay(true, Vector2(3, 3), 0.0)
	var tyres: Array = m.rear_tyres(Vector2(2, 3), 0.0)
	for i in m.pieces().size():
		assert_eq(m.pieces()[i].z_index, 0, "z 0")
		assert_almost_eq(m.pieces()[i].get_point_position(0).y, tyres[i].y * 16.0, 0.001, "not lifted")
