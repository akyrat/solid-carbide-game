extends GutTest
## Task T-091: the trick popups. Each trick signal shows T-082's text near the
## car, rising and fading; extended-drift popups are smaller. Works in the run
## (also after a second run starts) and in the drift prototype.

const RunScene := preload("res://scenes/run/run.tscn")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")
const Popups := preload("res://scripts/hud/trick_popups.gd")

const NAMES := {
	"extended_drift": "LONG DRIFT!",
	"three_sixty": "FULL 360!",
	"alternate_drift": "ALT DRIFT!",
}


func _popup_texts(p: Node2D) -> Array:
	return p.popups().map(func(x) -> String: return x.text)


func test_each_trick_shows_its_text_near_the_car_rises_and_goes() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	for id in NAMES:
		var tp: Node2D = run.trick_popups
		var before: int = tp.popups().size()
		run.car.trick.emit(id)
		var shown: Array = tp.popups()
		assert_eq(shown.size(), before + 1, "%s shows a popup" % id)
		var pop = shown.back()
		assert_eq(pop.text, NAMES[id])
		var start: Vector2 = pop.position
		assert_lt(start.distance_to(run.car_sprite.position), 80.0, "near the car")
		assert_lt(start.y, run.car_sprite.position.y, "above the car, clear of it")
		pop.advance(0.5)
		assert_lt(pop.position.y, start.y, "rises")
		pop.advance(0.4)
		assert_lt(pop.modulate.a, 0.5, "fading")
		pop.advance(0.2)
		await get_tree().process_frame
		assert_false(is_instance_valid(pop), "goes away")


func test_extended_drift_is_smaller() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var sizes := {}
	for id in NAMES:
		run.car.trick.emit(id)
		sizes[id] = run.trick_popups.popups().back().font_size
	assert_lt(sizes["extended_drift"], sizes["three_sixty"])
	assert_eq(sizes["three_sixty"], sizes["alternate_drift"])


func test_unknown_trick_shows_nothing() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.car.trick.emit("nope")
	assert_eq(run.trick_popups.popups().size(), 0)


func test_popups_follow_the_new_car_after_a_second_run() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.start_run()
	run.car.trick.emit("three_sixty")
	assert_eq(_popup_texts(run.trick_popups), ["FULL 360!"])


func test_any_text_can_be_shown() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var pop = run.trick_popups.show_popup("+50 LIKES!", Vector2.ZERO)
	assert_eq(pop.text, "+50 LIKES!")


func test_real_drive_in_the_prototype_pops_a_popup() -> void:
	var proto: Node2D = PrototypeScene.instantiate()
	add_child_autofree(proto)
	proto.car.use_keyboard = false
	proto.car.scripted_input = [true, false, 1.0]
	for i in 100:
		proto.car._physics_process(0.02)
	assert_true(_popup_texts(proto.trick_popups).has("FULL 360!") or proto.car.tricks.counts.size() > 0)
	assert_gt(proto.trick_popups.popups().size(), 0, "a drive that does tricks shows popups")
