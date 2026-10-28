extends GutTest
## Task T-049: the HUD shows the run's health, subs (XP) and coins, with the
## approved texts from T-048 and T-331. Since T-337 the subs show in the sub
## goal square (no likes bar, no "Hype Lv").

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


func test_sub_goal_follows_xp() -> void:
	var r := _run()
	var hud: Hud = r.hud
	assert_eq(hud.sub_goal.fill, 0.0)
	var need: float = r.state.xp_needed()
	r.state.add_xp(need * 0.5)
	hud.settle_likes()
	assert_almost_eq(hud.sub_goal.fill, r.state.xp / need, 0.001)
	assert_eq(hud.sub_goal.goal, int(ceilf(need)))
	r.state.add_xp(need)
	assert_eq(r.state.level, 2)
	hud.settle_likes()
	assert_almost_eq(hud.sub_goal.fill, r.state.xp / r.state.xp_needed(), 0.001)
	assert_eq(hud.sub_goal.goal, int(ceilf(r.state.xp_needed())), "the next goal")


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
	assert_almost_eq(r.hud.health_bar.value, r.state.max_health, 0.001)
	assert_eq(r.hud.sub_goal.fill, 0.0)
	assert_eq(r.hud.sub_goal.subs, 0)
	assert_false(r.hud.sub_goal.lit)


func test_max_level_keeps_the_bar_full() -> void:
	var r := _run()
	for i in 200:
		if r.state.is_max_level():
			break
		r.state.add_xp(r.state.xp_needed())
	assert_true(r.state.is_max_level())
	r.hud.settle_likes()
	assert_eq(r.hud.sub_goal.fill, 1.0)
	assert_true(r.hud.sub_goal.lit, "the top level reads as the goal reached")


func test_labels_are_exactly_the_approved_text() -> void:
	var r := _run()
	var hud: Hud = r.hud
	assert_eq(hud.coins_label.text, "Coins")
	assert_eq(Hud.TEXT_SUB_GOAL, "{subs} / {goal} SUBS")
	assert_eq(hud.sub_goal.label.text, "0 / %d SUBS" % int(ceilf(r.state.xp_needed())))


func test_no_hype_lv_and_no_likes_row_left() -> void:
	# T-337: "Hype Lv" is gone for good, with the likes bar and its row.
	var src := FileAccess.get_file_as_string("res://scripts/hud/hud.gd")
	for word in ["TEXT_LEVEL", "Hype Lv", "level_label", "likes_bar", "likes_row", "LevelUpFlash"]:
		assert_false(src.contains(word), "hud.gd has no %s" % word)
	assert_false(FileAccess.file_exists("res://scripts/hud/level_up_flash.gd"), "the level-up pop is gone")
	var r := _run()
	for key in ["level_label", "likes_bar", "likes_row", "likes_label", "heart", "heart_box", "level_up_flash"]:
		assert_eq(r.hud.get(key), null, "no %s on the HUD" % key)
	assert_eq(_texts_with(r.hud, "HYPE").size() + _texts_with(r.hud, "Hype").size(), 0, "no Hype text anywhere on the HUD")


func _texts_with(n: Node, word: String) -> Array:
	var out: Array = []
	if n is Label and (n as Label).text.contains(word):
		out.append(n)
	for c in n.get_children():
		out.append_array(_texts_with(c, word))
	return out


func test_heart_is_the_only_red_part() -> void:
	var r := _run()
	assert_eq(r.hud.health_heart.get_child_count(), 0, "the heart is its art, no drawn shape")
	assert_eq(r.hud.health_heart.texture.resource_path, Hud.HEART_PATH)
	for c: Color in [Hud.HEALTH_COLOR, SubGoal.FILL_COLOR, Hud.COINS_COLOR]:
		var red: bool = c.h < 0.04 or c.h > 0.96
		assert_false(red, "not red: %s" % c)
