extends GutTest
## Task T-049: the HUD shows the run's health, likes (XP) and level, and coins,
## with the approved texts from T-048.

const RUN := preload("res://scenes/run/run.tscn")


func _run() -> Node2D:
	var r: Node2D = RUN.instantiate()
	add_child_autofree(r)
	return r


func test_health_bar_follows_health() -> void:
	var r := _run()
	var hud: Hud = r.hud
	assert_almost_eq(hud.health_bar.value, r.state.max_health, 0.001)
	assert_almost_eq(hud.health_bar.max_value, r.state.max_health, 0.001)
	r.state.damage_car(r.state.max_health * 0.25)
	assert_almost_eq(hud.health_bar.value, r.state.health, 0.001)
	assert_lt(hud.health_bar.value, hud.health_bar.max_value)


func test_likes_bar_and_level_follow_xp() -> void:
	var r := _run()
	var hud: Hud = r.hud
	assert_eq(hud.level_label.text, "Hype Lv 1")
	assert_eq(hud.likes_bar.value, 0.0)
	var need: float = r.state.xp_needed()
	r.state.add_xp(need * 0.5)
	hud.settle_likes()
	assert_almost_eq(hud.likes_bar.value, r.state.xp, 0.001)
	assert_almost_eq(hud.likes_bar.max_value, need, 0.001)
	r.state.add_xp(need)
	assert_eq(r.state.level, 2)
	assert_eq(hud.level_label.text, "Hype Lv 2")
	hud.settle_likes()
	assert_almost_eq(hud.likes_bar.value, r.state.xp, 0.001)
	assert_almost_eq(hud.likes_bar.max_value, r.state.xp_needed(), 0.001)


func test_coins_follow_the_run() -> void:
	var r := _run()
	assert_eq(r.hud.coins_value_label.text, "0")
	r.state.add_coins(7)
	assert_eq(r.hud.coins_value_label.text, "7")
	r.state.add_coins(5)
	assert_eq(r.hud.coins_value_label.text, "12")


func test_fresh_run_resets_the_values() -> void:
	var r := _run()
	r.state.add_coins(9)
	r.state.damage_car(1.0)
	r.state.add_xp(r.state.xp_needed() * 1.2)
	r.start_run()
	assert_eq(r.hud.coins_value_label.text, "0")
	assert_eq(r.hud.level_label.text, "Hype Lv 1")
	assert_almost_eq(r.hud.health_bar.value, r.state.max_health, 0.001)
	assert_eq(r.hud.likes_bar.value, 0.0)


func test_max_level_keeps_the_bar_full() -> void:
	var r := _run()
	for i in 200:
		if r.state.is_max_level():
			break
		r.state.add_xp(r.state.xp_needed())
	assert_true(r.state.is_max_level())
	r.hud.settle_likes()
	assert_eq(r.hud.likes_bar.value, r.hud.likes_bar.max_value)
	assert_eq(r.hud.level_label.text, "Hype Lv %d" % r.state.level)


func test_labels_are_exactly_the_approved_text() -> void:
	var r := _run()
	var hud: Hud = r.hud
	assert_eq(hud.likes_label.text, "Likes")
	assert_eq(hud.coins_label.text, "Coins")
	assert_eq(Hud.TEXT_LEVEL, "Hype Lv {level}")
	assert_eq(hud.level_label.text, "Hype Lv 1")
	assert_not_null(hud.heart)


func test_heart_is_the_only_red_part() -> void:
	var r := _run()
	assert_eq(r.hud.heart.get_child_count(), 0, "the heart is its art, no drawn shape")
	assert_eq(r.hud.heart.texture.resource_path, Hud.HEART_PATH)
	for c: Color in [Hud.HEALTH_COLOR, Hud.LIKES_COLOR, Hud.COINS_COLOR, Hud.TIMER_COLOR]:
		var red: bool = c.h < 0.04 or c.h > 0.96
		assert_false(red, "not red: %s" % c)
