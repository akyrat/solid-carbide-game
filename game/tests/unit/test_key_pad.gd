extends GutTest
## Task T-491: the live key pad lights exactly the keys of the clip's key timeline for the current frame.


func _player(clip: String) -> ClipPlayer:
	var p := ClipPlayer.new()
	p.size = Vector2(240, 160)
	add_child_autofree(p)
	p.set_clip(clip, true)
	return p


func _meta(clip: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://art/tutorial/clips/%s_sheet.json" % clip))


func test_the_pad_sits_in_the_bottom_right_corner() -> void:
	var p := _player("alt_drift")
	var pad := KeyPad.attach(p, 24.0)
	assert_eq(pad.get_parent(), p)
	assert_almost_eq(pad.position.x + pad.size.x + pad.margin, p.size.x, 0.01)
	assert_almost_eq(pad.position.y + pad.size.y + pad.margin, p.size.y, 0.01)


func test_alt_drift_lights_s_and_a_only_on_its_swap_frames() -> void:
	var p := _player("alt_drift")
	var pad := KeyPad.attach(p, 24.0)
	var keys: Array = _meta("alt_drift")["keys_per_frame"]
	var seen_swap := false
	for i in range(keys.size()):
		p.frame = i
		p.frame_changed.emit()
		var expect: Array = []
		for k in String(keys[i]).split(""):
			expect.append(k)
		expect.sort()
		assert_eq(pad.lit_keys(), "".join(expect), "frame %d" % i)
		if keys[i] == "AS":
			seen_swap = true
			assert_true(pad.is_lit("S") and pad.is_lit("A"))
			assert_false(pad.is_lit("W") or pad.is_lit("D"))
	assert_true(seen_swap, "the clip has S + A frames")


func test_the_pad_follows_the_clock_every_clip() -> void:
	for clip in ["long_drift", "three_sixty", "alt_drift", "ramp_jump", "air_three_sixty", "airtime", "thread_the_needle"]:
		var p := _player(clip)
		var pad := KeyPad.attach(p, 24.0)
		var keys: Array = _meta(clip)["keys_per_frame"]
		assert_eq(keys.size(), p.frame_count(), clip)
		var guard := 0
		while guard < 400:
			guard += 1
			p.advance(0.05)
			assert_eq(pad.held, String(keys[p.frame]), "%s frame %d" % [clip, p.frame])
