extends GutTest
## T-332: the live viewers curve, its heat steps, motion, trick gain and format.


func _v() -> ViewersData:
	return ViewersData.new()


func test_loads() -> void:
	assert_true(GameData.load_file("viewers").ok)
	assert_true(_v().is_ok())


func test_anchors() -> void:
	var v := _v()
	assert_almost_eq(v.viewers_for(2.0), 20000.0, 200.0)
	assert_almost_eq(v.viewers_for(6.0), 1000000.0, 10000.0)
	assert_eq(v.viewers_for(2.0), 20000.0)
	assert_eq(v.viewers_for(6.0), 1000000.0)


func test_x1_is_in_the_data() -> void:
	var v := _v()
	assert_eq(v.base_viewers(), 2500.0)
	assert_eq(v.viewers_for(1.0), 2500.0)
	assert_eq(v.viewers_for(0.5), 2500.0, "held flat below x1")
	assert_eq(v.viewers_for(9.0), 1000000.0, "held flat above the cap")


func test_curve_rises_everywhere() -> void:
	var v := _v()
	var prev := v.viewers_for(1.0)
	var m := 1.01
	while m <= 6.0:
		var cur := v.viewers_for(m)
		assert_gt(cur, prev, "rises at x%.2f" % m)
		prev = cur
		m += 0.01


func test_curve_midpoints_match_the_formula() -> void:
	var v := _v()
	assert_almost_eq(v.viewers_for(3.0), 84736.0, 1.0)
	assert_almost_eq(v.viewers_for(4.0), 236026.0, 1.0)
	assert_almost_eq(v.viewers_for(5.0), 522451.0, 1.0)


func test_heat_thresholds_follow_combo_heat() -> void:
	var v := _v()
	var th := v.heat_thresholds()
	assert_eq(th.size(), ComboHeat.THRESHOLDS.size())
	for i in th.size():
		assert_almost_eq(float(th[i]), v.viewers_for(ComboHeat.THRESHOLDS[i]), 0.01 * float(th[i]))
	assert_eq(v.fire_viewers(), 1000000.0)


func test_steps_change_where_the_multiplier_steps_do() -> void:
	var v := _v()
	var m := 1.0
	while m <= 6.0:
		var shown := snappedf(m, 0.01)
		var heat := ComboHeat.step_for(shown)
		var expect := heat + (1 if shown >= 6.0 else 0)
		assert_eq(v.step_for_multiplier(shown), expect, "x%.2f" % shown)
		m += 0.01


func test_fire_at_the_cap_only() -> void:
	var v := _v()
	assert_eq(v.step_for_multiplier(6.0), 4)
	assert_eq(v.step_for_multiplier(5.9), 3)
	assert_true(v.is_fire(1000000.0))
	assert_false(v.is_fire(999999.0))
	assert_eq(v.step_for_viewers(0.0), 0)
	assert_eq(v.step_for_viewers(19999.0), 0)
	assert_eq(v.step_for_viewers(20000.0), 1)


func test_counts_up_faster_than_down() -> void:
	var v := _v()
	var up := v.count_toward(10000.0, 20000.0, 0.25) - 10000.0
	var down := 20000.0 - v.count_toward(20000.0, 10000.0, 0.25)
	assert_gt(up, 0.0)
	assert_gt(down, 0.0)
	assert_gt(up, down)
	assert_lt(v.count_toward(10000.0, 20000.0, 0.25), 20000.0)


func test_counting_arrives_and_never_overshoots() -> void:
	var v := _v()
	var s := 5000.0
	for i in 600:
		s = v.count_toward(s, 20000.0, 1.0 / 60.0)
		assert_lte(s, 20000.0)
	assert_eq(s, 20000.0)
	for i in 600:
		s = v.count_toward(s, 3000.0, 1.0 / 60.0)
		assert_gte(s, 3000.0)
	assert_eq(s, 3000.0)
	assert_eq(v.count_toward(100.0, 100.0, 0.1), 100.0)


func test_wobble_is_small_and_never_still() -> void:
	var v := _v()
	var lo := 2.0
	var hi := 0.0
	var changes := 0
	var last := -1.0
	var t := 0.0
	while t < 20.0:
		var w := v.wobble_factor(t)
		lo = minf(lo, w)
		hi = maxf(hi, w)
		if absf(w - last) > 1e-9:
			changes += 1
		last = w
		t += 0.02
	assert_gte(lo, 0.995 - 1e-9)
	assert_lte(hi, 1.005 + 1e-9)
	assert_gt(hi - lo, 0.005, "it really moves")
	assert_gt(changes, 900)
	assert_eq(v.with_wobble(0.0, 1.0), 0.0)
	assert_almost_eq(v.with_wobble(100000.0, 3.3), 100000.0, 500.0)


func test_trick_gain_and_crash_loss() -> void:
	var v := _v()
	assert_eq(v.trick_gain(2.0, 3.0), v.viewers_for(3.0) - v.viewers_for(2.0))
	assert_eq(v.trick_gain(3.0, 3.0), 0.0)
	assert_eq(v.trick_gain(3.0, 2.0), 0.0)
	assert_gt(v.trick_gain(1.0, 1.25), 0.0)
	assert_eq(v.trick_gain(5.8, 6.0), v.viewers_for(6.0) - v.viewers_for(5.8))
	assert_eq(v.trick_gain(6.0, 6.0), 0.0, "at the cap a trick brings nothing")
	assert_eq(v.crash_loss(4.0, 2.5), v.viewers_for(4.0) - v.viewers_for(2.5))
	assert_gt(v.crash_loss(4.0, 2.5), 0.0)
	assert_eq(v.crash_loss(1.0, 1.0), 0.0)
	assert_eq(v.crash_loss(2.0, 4.0), 0.0)
	var c := ComboData.new()
	var hit := c.after_collision(4.0)
	assert_almost_eq(v.crash_loss(4.0, hit), v.viewers_for(4.0) - v.viewers_for(hit), 0.001)


func test_format() -> void:
	var v := _v()
	assert_eq(v.format(0.0), "0")
	assert_eq(v.format(850.0), "850")
	assert_eq(v.format(999.0), "999")
	assert_eq(v.format(1000.0), "1,000")
	assert_eq(v.format(2500.0), "2,500")
	assert_eq(v.format(9999.0), "9,999")
	assert_eq(v.format(10000.0), "10.0K")
	assert_eq(v.format(20400.0), "20.4K")
	assert_eq(v.format(84736.0), "84.7K")
	assert_eq(v.format(99949.0), "99.9K")
	assert_eq(v.format(99960.0), "100K")
	assert_eq(v.format(236026.0), "236K")
	assert_eq(v.format(999499.0), "999K")
	assert_eq(v.format(999960.0), "1.00M")
	assert_eq(v.format(1000000.0), "1.00M")
	assert_eq(v.format(1020000.0), "1.02M")
	assert_eq(v.format(-5.0), "0")
