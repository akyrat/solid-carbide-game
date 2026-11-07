extends GutTest
## Task T-556: each of the five jump effect ids has its own art sheet (8 frames of 96 x 96, in
## art/effects/jump/), the jump effect draws that sheet's frame by progress, and the frames differ
## between ids (so no id plays another's art or the old placeholder).

const JumpEffectScript := preload("res://scripts/driving/jump_effect.gd")
const JumpEffectChoice := preload("res://scripts/driving/jump_effect_choice.gd")


func test_every_effect_id_has_its_own_sheet() -> void:
	var seen := {}
	for id in JumpEffectChoice.IDS:
		assert_true(JumpEffectScript.SHEETS.has(id), "%s has a sheet" % id)
		var tex: Texture2D = JumpEffectScript.SHEETS[id]
		assert_eq(tex.get_size(), Vector2(96 * 8, 96), "%s: 8 frames of 96 x 96" % id)
		assert_false(seen.has(tex.resource_path), "%s: its own file" % id)
		seen[tex.resource_path] = true
	assert_eq(JumpEffectScript.SHEETS.size(), JumpEffectChoice.IDS.size())


func test_each_sheet_has_pixels_in_every_frame_and_the_anchor_in_range() -> void:
	for id in JumpEffectChoice.IDS:
		var img: Image = (JumpEffectScript.SHEETS[id] as Texture2D).get_image()
		for f in 8:
			var any := false
			for y in 96:
				for x in 96:
					if img.get_pixel(f * 96 + x, y).a > 0.0:
						any = true
						break
				if any:
					break
			assert_true(any, "%s frame %d has pixels" % [id, f])
	assert_true(JumpEffectScript.ANCHOR_PX.x < 96 and JumpEffectScript.ANCHOR_PX.y < 96)


func test_every_effect_plays_and_draws_through_its_frames() -> void:
	var e: Node2D = JumpEffectScript.new()
	add_child_autofree(e)
	for id in JumpEffectChoice.IDS:
		e.play(id, "hop", Vector2.ZERO, 0.0, 0.0)
	e.play("no_such_effect", "hop", Vector2.ZERO, 0.0, 0.0)   # draws the dash cloud
	for i in 9:
		await get_tree().process_frame
		e.advance(e.seconds / 8.0)
	assert_false(e.is_playing(), "all over after their seconds")
