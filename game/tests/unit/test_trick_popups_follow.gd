extends GutTest
## Task T-125: trick popups stay with the car for their whole life and do not
## sit on top of each other.

const RunScene := preload("res://scenes/run/run.tscn")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")
const Popups := preload("res://scripts/hud/trick_popups.gd")


func _rect(p) -> Rect2:
	return Rect2(p.position - p.size() / 2.0, p.size())


func test_popup_keeps_its_offset_from_a_moving_car_for_its_whole_life() -> void:
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	var car := [Vector2(100, 100)]
	var follow := func() -> Vector2: return car[0]
	var pop = tp.show_popup("FULL 360!", car[0], 28, follow)
	var t := 0.0
	while t < 0.95:
		car[0] += Vector2(37, -21)
		pop.advance(0.05)
		t += 0.05
		var expected: Vector2 = car[0] + Popups.START_OFFSET + Vector2(0, -pop.rise())
		assert_true(pop.position.is_equal_approx(expected), "at %.2f s the popup is where the moving car puts it" % t)
		assert_almost_eq(pop.position.y - car[0].y, Popups.START_OFFSET.y - pop.rise(), 0.001)
	assert_almost_eq(pop.position.x - car[0].x, 0.0, 0.001, "centred over the car")


func test_physics_step_places_the_popup_at_the_cars_current_position() -> void:
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	var car := [Vector2.ZERO]
	var pop = tp.show_popup("FULL 360!", car[0], 28, func() -> Vector2: return car[0])
	car[0] = Vector2(500, 300)
	pop.place()
	assert_eq(pop.position, Vector2(500, 300) + Popups.START_OFFSET)


func test_popup_without_follow_stays_put() -> void:
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	var pop = tp.show_popup("FULL 360!", Vector2(10, 10))
	pop.advance(0.0)
	assert_eq(pop.position, Vector2(10, 10) + Popups.START_OFFSET)


func test_run_popup_follows_the_drawn_car() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.car.trick.emit("three_sixty")
	var pop = run.trick_popups.popups().back()
	for i in 5:
		run.car_sprite.position += Vector2(60, 25)
		pop.advance(0.1)
		var rel: Vector2 = pop.position - run.car_sprite.position
		assert_eq(rel, pop.offset(), "same offset from the drawn car, frame %d" % i)
	assert_lt(pop.position.y, run.car_sprite.position.y, "still above the car")


func test_challenge_popup_follows_the_car() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.state.score.emit(120.0, "c")
	var pop = run.trick_popups.popups().back()
	assert_true(pop.text.begins_with("Trending"))
	run.car_sprite.position += Vector2(300, 0)
	pop.advance(0.2)
	assert_eq(pop.position - run.car_sprite.position, pop.offset())


func test_prototype_popup_follows_the_drawn_car() -> void:
	var proto: Node2D = PrototypeScene.instantiate()
	add_child_autofree(proto)
	proto.car.trick.emit("three_sixty")
	var pop = proto.trick_popups.popups().back()
	proto.car_sprite.position += Vector2(200, -80)
	pop.advance(0.3)
	assert_true((pop.position - proto.car_sprite.position).is_equal_approx(pop.offset()))


func test_popups_shown_together_do_not_overlap() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	for id in ["extended_drift", "three_sixty", "alternate_drift", "three_sixty"]:
		run.car.trick.emit(id)
	var shown: Array = run.trick_popups.popups()
	assert_eq(shown.size(), 4)
	for i in shown.size():
		for j in range(i + 1, shown.size()):
			assert_false(_rect(shown[i]).intersects(_rect(shown[j])), "popups %d and %d overlap" % [i, j])


func test_popups_born_a_little_apart_do_not_cover_an_older_one() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.car.trick.emit("extended_drift")
	for i in 6:
		for p in run.trick_popups.popups():
			p.advance(0.1)
		run.car.trick.emit("extended_drift" if i % 2 == 0 else "three_sixty")
	var shown: Array = run.trick_popups.popups()
	for i in shown.size():
		for j in range(i + 1, shown.size()):
			assert_false(_rect(shown[i]).intersects(_rect(shown[j])), "popups %d and %d overlap" % [i, j])


func test_stack_resets_once_popups_are_gone() -> void:
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	var a = tp.show_popup("FULL 360!", Vector2.ZERO)
	var b = tp.show_popup("FULL 360!", Vector2.ZERO)
	assert_lt(b.stack, a.stack, "the second goes above the first")
	a.advance(2.0)
	b.advance(2.0)
	await get_tree().process_frame
	var c = tp.show_popup("FULL 360!", Vector2.ZERO)
	assert_eq(c.stack, 0.0)
