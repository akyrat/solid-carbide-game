extends GutTest
## Task T-247: the HUD's drift counter appears when a drift starts, counts up in
## hundredths of a second matching the drift's length, disappears when the drift
## ends, and shows only a two-decimal number and its placeholder icon.

const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const RUN := preload("res://scenes/run/run.tscn")
const DT := 0.02


class FakeCar extends Node:
	signal stepped
	var airborne := false
	var model = null

	func tick(drifting: bool, in_air := false) -> void:
		airborne = in_air
		model.is_drifting = drifting
		stepped.emit()


class FakeModel extends RefCounted:
	var dt := DT
	var is_drifting := false


func _hud() -> Array:
	var hud: Hud = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	var car := FakeCar.new()
	car.model = FakeModel.new()
	add_child_autofree(car)
	hud.bind_car(car)
	return [hud, car]


func test_hidden_when_not_drifting() -> void:
	var p := _hud()
	assert_false(p[0].drift_counter.visible)
	p[1].tick(false)
	assert_false(p[0].drift_counter.visible)


func test_appears_when_a_drift_starts() -> void:
	var p := _hud()
	p[1].tick(false)
	p[1].tick(true)
	assert_true(p[0].drift_counter.is_visible_in_tree())


func test_counts_up_in_hundredths_matching_the_drift() -> void:
	var p := _hud()
	var c: DriftCounter = p[0].drift_counter
	var seen: Array[String] = []
	for i in 30:
		p[1].tick(true)
		seen.append(c.number_label.text)
	assert_eq(seen[0], "0.02")
	assert_eq(seen[24], "0.50")
	assert_eq(seen[29], "0.60")
	assert_almost_eq(c.drift_time, 30 * DT, 0.0001)
	var re := RegEx.create_from_string("^\\d+\\.\\d\\d$")
	assert_not_null(re.search(c.number_label.text), "two decimals, no unit")


func test_disappears_when_the_drift_ends_and_starts_over() -> void:
	var p := _hud()
	var c: DriftCounter = p[0].drift_counter
	for i in 10:
		p[1].tick(true)
	p[1].tick(false)
	assert_false(c.visible)
	assert_eq(c.drift_time, 0.0)
	p[1].tick(true)
	assert_eq(c.number_label.text, "0.02")


func test_both_counters_show_at_once_and_are_independent() -> void:
	var p := _hud()
	p[1].tick(true, true)
	assert_true(p[0].drift_counter.visible and p[0].airtime_counter.visible)
	p[1].tick(false, true)
	assert_false(p[0].drift_counter.visible)
	assert_true(p[0].airtime_counter.visible)


func test_rebinding_a_new_car_resets_it() -> void:
	var p := _hud()
	for i in 5:
		p[1].tick(true)
	var car2 := FakeCar.new()
	car2.model = FakeModel.new()
	add_child_autofree(car2)
	p[0].bind_car(car2)
	assert_false(p[0].drift_counter.visible)
	p[1].tick(true)
	assert_false(p[0].drift_counter.visible, "the old car is no longer followed")


func test_only_a_number_and_an_icon_never_red() -> void:
	var p := _hud()
	var c: DriftCounter = p[0].drift_counter
	assert_eq(c.get_child_count(), 2)
	assert_true(c.icon is Control and not (c.icon is Label))
	assert_ne(c.icon.get_script(), p[0].airtime_counter.icon.get_script(), "its own icon")
	for col: Color in [DriftCounter.NUMBER_COLOR, DriftCounter.OUTLINE_COLOR]:
		assert_ne(col, Hud.HEART_COLOR)
		assert_false(col.r > 0.6 and col.g < 0.3 and col.b < 0.3)
	for mark: Array in [DriftCounter.MARK_A, DriftCounter.MARK_B]:
		for pt: Vector2 in mark:
			assert_true(Rect2(Vector2.ZERO, DriftCounter.ICON_SIZE).has_point(pt))


func test_sits_under_the_airtime_counter_in_a_run() -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(1152, 648)
	add_child_autofree(sv)
	var r: Node2D = RUN.instantiate()
	sv.add_child(r)
	await get_tree().process_frame
	var a: AirtimeCounter = r.hud.airtime_counter
	var d: DriftCounter = r.hud.drift_counter
	assert_eq(d.position.x, a.position.x)
	assert_gte(d.position.y, a.position.y + a.size.y, "no overlap")
	assert_false(d.visible)
	r.car.model.is_drifting = true
	r.car.stepped.emit()
	assert_true(d.visible)
