extends GutTest
## Task T-069: the kaiju's art. Direction choice, frame choice, the five sheets,
## and that the drawing keeps the placeholder's size functions.

const SpriteScript := preload("res://scripts/enemies/kaiju_sprite.gd")


func test_compass_index_follows_screen_direction() -> void:
	assert_eq(SpriteScript.compass_index(Vector2.RIGHT), 0, "east")
	assert_eq(SpriteScript.compass_index(Vector2(1, 1)), 1, "south-east")
	assert_eq(SpriteScript.compass_index(Vector2.DOWN), 2, "south")
	assert_eq(SpriteScript.compass_index(Vector2.LEFT), 4, "west")
	assert_eq(SpriteScript.compass_index(Vector2.UP), 6, "north")
	assert_eq(SpriteScript.compass_index(Vector2(1, -1)), 7, "north-east")


func test_mirrored_directions_use_the_drawn_ones() -> void:
	assert_eq(SpriteScript.SHEETS[3][0], SpriteScript.SHEETS[1][0])
	assert_true(SpriteScript.SHEETS[3][1])
	assert_false(SpriteScript.SHEETS[1][1])
	assert_true(SpriteScript.SHEETS[4][1], "west mirrors east")
	assert_true(SpriteScript.SHEETS[5][1], "north-west mirrors north-east")


func test_frame_for_covers_the_cycle() -> void:
	assert_eq(SpriteScript.frame_for(0.0), 0)
	assert_eq(SpriteScript.frame_for(0.999), SpriteScript.FRAME_COUNT - 1)
	assert_eq(SpriteScript.frame_for(0.5), 3)


func test_the_five_sheets_exist_and_are_6_frames_of_224() -> void:
	for d in ["s", "se", "e", "ne", "n"]:
		var tex: Texture2D = load("res://art/kaiju/kaiju_%s.png" % d)
		assert_not_null(tex, d)
		assert_eq(tex.get_width(), 6 * SpriteScript.FRAME_SIZE, d)
		assert_eq(tex.get_height(), SpriteScript.FRAME_SIZE, d)
	assert_true(SpriteScript.has_art())


func test_the_art_is_the_kaijus_seven_units_wide_canvas() -> void:
	assert_eq(SpriteScript.FRAME_SIZE * SpriteScript.ART_SCALE, SpriteScript.HEIGHT_UNITS * SpriteScript.PX, "224 art pixels at 0.5 = 7 units")
	assert_gt(SpriteScript.drawn_height_px(), 80.0)
	assert_lte(SpriteScript.drawn_height_px(), SpriteScript.HEIGHT_UNITS * SpriteScript.PX)
	assert_gt(SpriteScript.drawn_width_px(), 0.0)


func test_face_sets_the_screen_direction() -> void:
	var s: Node2D = SpriteScript.new()
	add_child_autofree(s)
	s.face(Vector2.RIGHT)  # flat +x is screen down-right
	assert_eq(SpriteScript.compass_index(s.facing), 1)
