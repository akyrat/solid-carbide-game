extends GutTest


func test_loads_through_loader() -> void:
	var r := GameData.load_file("combo")
	assert_true(r.ok, r.error)
	assert_true(ComboData.new().is_ok())


func test_trick_order() -> void:
	var c := ComboData.new()
	assert_gt(c.trick_add("alternate_drift"), c.trick_add("three_sixty"))
	assert_gt(c.trick_add("three_sixty"), c.drift_amount(1.0))
	assert_gt(c.drift_amount(1.0), 0.0)


func test_decided_values() -> void:
	var c := ComboData.new()
	assert_eq(c.collision_cut(), 0.8)
	assert_eq(c.drain_wait_seconds(), 2.0)
	assert_eq(c.start_multiplier(), 1.0)


func test_collision_cuts_part_above_start() -> void:
	var c := ComboData.new()
	assert_almost_eq(c.after_collision(5.0), 1.8, 0.0001)
	assert_eq(c.after_collision(1.0), 1.0)


func test_cap_and_drain() -> void:
	var c := ComboData.new()
	assert_eq(c.after_trick(c.max_multiplier(), "alternate_drift"), c.max_multiplier())
	assert_eq(c.after_idle(4.0, 2.0), 4.0)
	assert_almost_eq(c.after_idle(4.0, 4.0), 3.0, 0.0001)
	assert_eq(c.after_idle(2.0, 60.0), 1.0)


func test_spawn_multiplier() -> void:
	var c := ComboData.new()
	assert_eq(c.spawn_multiplier(1.0), 1.0)
	assert_almost_eq(c.spawn_multiplier(5.0), 1.6, 0.0001)
	assert_eq(c.spawn_multiplier(6.0), 1.75)
