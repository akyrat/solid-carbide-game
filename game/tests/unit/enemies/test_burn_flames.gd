extends GutTest
## Task T-071: the flames on a burning enemy (burn_flames.gd). They show while any weapon burns the enemy,
## go when the last one stops, and are a drawing only (no damage, no tint change).

const FakeEnemy := preload("res://tests/fixtures/weapons/fake_enemy.gd")
const FakeBigEnemy := preload("res://tests/fixtures/weapons/fake_big_enemy.gd")


func _enemy(big := false) -> Node2D:
	var e: Node2D = FakeBigEnemy.new() if big else FakeEnemy.new()
	add_child_autofree(e)
	return e


func test_a_source_puts_flames_on_the_enemys_sprite() -> void:
	var e := _enemy()
	assert_false(BurnFlames.is_burning(e))
	BurnFlames.add_source(e, "flamethrower")
	assert_true(BurnFlames.is_burning(e))
	assert_not_null(e.sprite.get_node_or_null(BurnFlames.NODE_NAME), "a child of the drawing node")


func test_two_sources_share_one_set_of_flames_and_the_last_one_ends_them() -> void:
	var e := _enemy()
	BurnFlames.add_source(e, "flamethrower")
	BurnFlames.add_source(e, 123)
	assert_eq(e.sprite.get_children().size(), 1, "one set of flames, not two")
	BurnFlames.remove_source(e, "flamethrower")
	assert_true(BurnFlames.is_burning(e), "still burning from the other source")
	BurnFlames.remove_source(e, 123)
	assert_false(BurnFlames.is_burning(e))
	await get_tree().process_frame
	assert_eq(e.sprite.get_children().size(), 0, "the flames are gone")


func test_removing_a_source_that_was_never_added_is_harmless() -> void:
	var e := _enemy()
	BurnFlames.remove_source(e, "nothing")
	assert_false(BurnFlames.is_burning(e))


func test_an_enemy_without_a_sprite_is_ignored() -> void:
	var n := Node2D.new()
	add_child_autofree(n)
	BurnFlames.add_source(n, "x")
	assert_false(BurnFlames.is_burning(n))


func test_a_bigger_enemy_gets_bigger_flames_in_whole_steps() -> void:
	var small := _enemy()
	var big := _enemy(true)
	BurnFlames.add_source(small, "a")
	BurnFlames.add_source(big, "a")
	var s: BurnFlames = small.sprite.get_node(BurnFlames.NODE_NAME)
	var b: BurnFlames = big.sprite.get_node(BurnFlames.NODE_NAME)
	assert_eq(s.steps, 1)
	assert_gt(b.steps, 1)
	assert_lte(b.steps, BurnFlames.MAX_STEPS)


func test_the_flames_flicker_between_two_frames() -> void:
	var e := _enemy()
	BurnFlames.add_source(e, "a")
	var f: BurnFlames = e.sprite.get_node(BurnFlames.NODE_NAME)
	var first := f.frame
	f._process(BurnFlames.FLICKER_SECONDS + 0.001)
	assert_ne(f.frame, first)
	f._process(BurnFlames.FLICKER_SECONDS + 0.001)
	assert_eq(f.frame, first)


func test_the_art_is_two_frames_of_the_stated_size() -> void:
	var img: Image = BurnFlames.ART.get_image()
	assert_eq(img.get_width(), int(BurnFlames.FRAME_SIZE.x) * BurnFlames.FRAMES)
	assert_eq(img.get_height(), int(BurnFlames.FRAME_SIZE.y))
