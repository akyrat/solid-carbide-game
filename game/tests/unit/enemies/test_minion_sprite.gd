extends GutTest
## Task T-068: the minion's art. Direction choice, frame choice, and that the
## five drawn sheets exist with 8 frames of 48 x 48.

const SpriteScript := preload("res://scripts/enemies/minion_sprite.gd")


func test_compass_index_follows_screen_direction() -> void:
	assert_eq(SpriteScript.compass_index(Vector2.RIGHT), 0, "east")
	assert_eq(SpriteScript.compass_index(Vector2(1, 1)), 1, "south-east")
	assert_eq(SpriteScript.compass_index(Vector2.DOWN), 2, "south")
	assert_eq(SpriteScript.compass_index(Vector2.LEFT), 4, "west")
	assert_eq(SpriteScript.compass_index(Vector2.UP), 6, "north")
	assert_eq(SpriteScript.compass_index(Vector2(1, -1)), 7, "north-east")


func test_mirrored_directions_use_the_drawn_ones() -> void:
	var sw: Array = SpriteScript.SHEETS[3]
	var se: Array = SpriteScript.SHEETS[1]
	assert_eq(sw[0], se[0])
	assert_true(sw[1])
	assert_false(se[1])
	assert_true(SpriteScript.SHEETS[4][1], "west mirrors east")
	assert_true(SpriteScript.SHEETS[5][1], "north-west mirrors north-east")


func test_frame_for_covers_the_cycle() -> void:
	assert_eq(SpriteScript.frame_for(0.0), 0)
	assert_eq(SpriteScript.frame_for(0.999), SpriteScript.FRAME_COUNT - 1)
	assert_eq(SpriteScript.frame_for(0.5), 4)


func test_the_five_sheets_exist_and_are_8_frames() -> void:
	for d in ["s", "se", "e", "ne", "n"]:
		var tex: Texture2D = load("res://art/minion/minion_%s.png" % d)
		assert_not_null(tex, d)
		assert_eq(tex.get_width(), 8 * SpriteScript.FRAME_SIZE, d)
		assert_eq(tex.get_height(), SpriteScript.FRAME_SIZE, d)


func test_the_walk_advances_with_process_time() -> void:
	var s: Node2D = SpriteScript.new()
	add_child_autofree(s)
	var before: float = s._walk
	s._process(0.05)
	assert_ne(s._walk, before)
