extends GutTest
## Task T-243: the HUD's airtime counter appears when the car leaves the ground,
## counts up in hundredths of a second matching the airtime, disappears on
## landing, and shows only a two-decimal number and the placeholder icon.

const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const RUN := preload("res://scenes/run/run.tscn")
const DT := 0.02


## A stand-in for the car: the HUD reads its stepped signal, airborne and model.dt.
class FakeCar extends Node:
	signal stepped
	var airborne := false
	var model = null

	func tick(in_air: bool) -> void:
		airborne = in_air
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


func test_hidden_on_the_ground() -> void:
	var p := _hud()
	assert_false(p[0].airtime_counter.visible, "hidden at the start")
	p[1].tick(false)
	assert_false(p[0].airtime_counter.visible, "hidden while driving")


func test_appears_when_the_car_leaves_the_ground() -> void:
	var p := _hud()
	p[1].tick(false)
	p[1].tick(true)
	assert_true(p[0].airtime_counter.visible, "shown from the first airborne step")
	assert_true(p[0].airtime_counter.is_visible_in_tree())


func test_counts_up_in_hundredths_matching_the_airtime() -> void:
	var p := _hud()
	var c: AirtimeCounter = p[0].airtime_counter
	var seen: Array[String] = []
	for i in 30:
		p[1].tick(true)
		seen.append(c.number_label.text)
	assert_eq(seen[0], "0.02")
	assert_eq(seen[24], "0.50", "25 steps of 0.02 s")
	assert_eq(seen[29], "0.60")
	assert_almost_eq(c.airtime, 30 * DT, 0.0001)
	assert_eq(c.number_label.text, AirtimeCounter.airtime_text(c.airtime))
	for i in seen.size() - 1:
		assert_true(seen[i + 1] > seen[i], "never counts back")


func test_two_decimals_and_no_unit() -> void:
	assert_eq(AirtimeCounter.airtime_text(0.0), "0.00")
	assert_eq(AirtimeCounter.airtime_text(1.0), "1.00")
	assert_eq(AirtimeCounter.airtime_text(1.234), "1.23")
	assert_eq(AirtimeCounter.airtime_text(12.5), "12.50")
	var p := _hud()
	p[1].tick(true)
	var re := RegEx.create_from_string("^\\d+\\.\\d\\d$")
	assert_not_null(re.search(p[0].airtime_counter.number_label.text))


func test_disappears_on_landing_and_starts_over() -> void:
	var p := _hud()
	var c: AirtimeCounter = p[0].airtime_counter
	for i in 10:
		p[1].tick(true)
	assert_true(c.visible)
	p[1].tick(false)
	assert_false(c.visible, "gone on landing")
	assert_eq(c.airtime, 0.0)
	p[1].tick(true)
	assert_eq(c.number_label.text, "0.02", "the next jump counts from zero")


func test_rebinding_a_new_car_resets_it() -> void:
	var p := _hud()
	for i in 5:
		p[1].tick(true)
	var car2 := FakeCar.new()
	car2.model = FakeModel.new()
	add_child_autofree(car2)
	p[0].bind_car(car2)
	assert_false(p[0].airtime_counter.visible)
	p[1].tick(true)
	assert_false(p[0].airtime_counter.visible, "the old car is no longer followed")
	car2.tick(true)
	assert_true(p[0].airtime_counter.visible)


func test_shows_only_the_number_and_the_icon_never_redgull_red() -> void:
	var p := _hud()
	var c: AirtimeCounter = p[0].airtime_counter
	assert_eq(c.get_child_count(), 2, "the icon and the number, nothing else")
	assert_not_null(c.icon)
	assert_not_null(c.number_label)
	for col: Color in [AirtimeCounter.NUMBER_COLOR, AirtimeCounter.OUTLINE_COLOR]:
		assert_ne(col, Hud.HEART_COLOR)
		assert_false(col.r > 0.6 and col.g < 0.3 and col.b < 0.3, "not red")
	for pt: Vector2 in AirtimeCounter.WING_POINTS:
		assert_true(Rect2(Vector2.ZERO, AirtimeCounter.ICON_SIZE).has_point(pt), "the wing fits its box")


func test_sits_right_of_the_centre_below_the_popups() -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(1152, 648)
	add_child_autofree(sv)
	var r: Node2D = RUN.instantiate()
	sv.add_child(r)
	await get_tree().process_frame
	var c: AirtimeCounter = r.hud.airtime_counter
	var centre := Vector2(sv.size) / 2.0
	assert_gt(c.position.x, centre.x, "right of the car")
	assert_gt(c.position.y + c.size.y, centre.y - 40.0, "not above where popups start")
	assert_lt(c.position.y, centre.y + 100.0)
	assert_false(c.visible, "hidden at the start of a run")


func test_a_run_follows_its_car() -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(1152, 648)
	add_child_autofree(sv)
	var r: Node2D = RUN.instantiate()
	sv.add_child(r)
	await get_tree().process_frame
	var c: AirtimeCounter = r.hud.airtime_counter
	r.car.height_model.airborne = true
	r.car.stepped.emit()
	assert_true(c.visible)
	r.start_run()  # a new car: the counter starts over
	assert_false(c.visible)
