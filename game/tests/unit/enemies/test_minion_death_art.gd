extends GutTest
## Task T-544: the minion's death sheets (PixelLab art) load for all 8 directions and a dying
## minion plays them instead of the code placeholder.

const MinionSpriteScript := preload("res://scripts/enemies/minion_sprite.gd")


func test_the_death_sheet_loads_for_every_drawn_direction_and_the_mirrored_ones() -> void:
	for entry in MinionSpriteScript.SHEETS:
		var tex := MinionSpriteScript.death_sheet(entry[0])
		assert_not_null(tex, "death sheet for %s (mirrored: %s)" % [entry[0], entry[1]])
		if tex != null:
			assert_eq(tex.get_size(), Vector2(MinionSpriteScript.FRAME_SIZE * 8, MinionSpriteScript.FRAME_SIZE), "8 frames of 48 in a row: " + entry[0])


func test_each_death_sheet_is_transparent_with_a_visible_body_in_every_frame() -> void:
	for d in ["e", "se", "s", "ne", "n"]:
		var img := MinionSpriteScript.death_sheet(d).get_image()
		for f in 8:
			var opaque := 0
			for y in 48:
				for x in 48:
					var a := img.get_pixel(f * 48 + x, y).a
					assert_true(a == 0.0 or a == 1.0, "alpha 0 or 1 (%s frame %d)" % [d, f])
					if a == 1.0:
						opaque += 1
			assert_gt(opaque, 40, "a body is drawn in %s frame %d" % [d, f])
		assert_eq(img.get_pixel(0, 0).a, 0.0, "corner transparent: " + d)
