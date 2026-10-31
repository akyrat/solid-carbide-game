extends GutTest
## Task T-338: the hearts in a row at the top left, in place of the health bar.

const RUN := preload("res://scenes/run/run.tscn")


func _run() -> Node2D:
	var r: Node2D = RUN.instantiate()
	add_child_autofree(r)
	return r


func _full(row: HeartRow) -> Array:
	return row.hearts.map(func(h: TextureRect) -> bool: return h.texture.resource_path == HeartRow.FULL_PATH)


func test_five_full_hearts_at_the_layout_place() -> void:
	var r := _run()
	var row: HeartRow = r.hud.heart_row
	assert_eq(row.hearts.size(), int(r.state.max_health))
	assert_eq(_full(row).count(true), row.hearts.size(), "all full at the start")
	# T-431: in the layout page's pixels (the HUD scales with the window; headless it is 64 x 64).
	var s: float = r.hud.hud_scale()
	assert_almost_eq(row.get_global_rect().position / s, Vector2(36, 24), Vector2(0.01, 0.01))
	if row.hearts.size() == 5:
		assert_almost_eq(row.get_global_rect().size / s, Vector2(220, 40), Vector2(0.01, 0.01))
	assert_null(r.hud.get("health_bar"))


func test_a_hit_empties_the_last_heart_and_a_heal_fills_it() -> void:
	var r := _run()
	var row: HeartRow = r.hud.heart_row
	var n := row.hearts.size()
	r.state.damage_car(1.0)
	assert_eq(row.full_count, n - 1)
	assert_eq(_full(row).count(true), n - 1)
	assert_false(_full(row)[n - 1], "the last heart is empty")
	assert_true(row.is_animating(), "the loss flashes")
	row.advance(HeartRow.LOSS_SECONDS + 0.01)
	assert_false(row.is_animating())
	assert_eq(row.hearts[n - 1].scale, Vector2.ONE)
	r.state.heal_car(1.0)
	assert_eq(row.full_count, n)
	assert_true(row.is_animating(), "the heal pops")
	row.advance(HeartRow.HEAL_SECONDS + 0.01)
	assert_true(_full(row)[n - 1])
	assert_eq(row.hearts[n - 1].scale, Vector2.ONE)


func test_a_garage_heart_adds_a_heart() -> void:
	var row := HeartRow.new()
	add_child_autofree(row)
	row.set_hearts(6, 6, false)
	assert_eq(row.hearts.size(), 6)
	assert_eq(_full(row).count(true), 6)
	row.set_hearts(3, 6)
	assert_eq(_full(row), [true, true, true, false, false, false])


func test_second_row_past_ten() -> void:
	var row := HeartRow.new()
	add_child_autofree(row)
	row.set_hearts(11, 11, false)
	assert_eq(row.hearts.size(), 11)
	assert_eq(row.hearts[0].position.y, row.hearts[9].position.y)
	assert_gt(row.hearts[10].position.y, row.hearts[0].position.y + 32.0, "the 11th is under the first row")
	assert_eq(row.hearts[10].position.x, row.hearts[0].position.x)


func test_new_run_resets_the_row() -> void:
	var r := _run()
	r.state.damage_car(2.0)
	r.start_run()
	assert_eq(r.hud.heart_row.full_count, r.hud.heart_row.max_hearts)


func test_weapon_icons_clear_of_the_row() -> void:
	var r := _run()
	var hud: Hud = r.hud
	assert_almost_eq(hud.weapon_icons.get_global_rect().position / hud.hud_scale(), Vector2(12, 88),
		Vector2(0.01, 0.01), "in the layout page's pixels (T-431)")
	assert_false(hud.weapon_icons.get_global_rect().intersects(hud.heart_row.get_global_rect()))


func test_no_half_hearts_or_red_bar_art() -> void:
	var row := HeartRow.new()
	add_child_autofree(row)
	row.set_hearts(2, 5, false)
	for h: TextureRect in row.hearts:
		assert_true(h.texture.resource_path in [HeartRow.FULL_PATH, HeartRow.EMPTY_PATH])
