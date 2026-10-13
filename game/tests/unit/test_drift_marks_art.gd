extends GutTest
## Task T-118: the drift marks' final tyre texture, drawn by
## game/tools/build_drift_mark.py and swapped into the drift marks scene.

const MarksScene := preload("res://scenes/driving/drift_marks.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const HudScript := preload("res://scripts/hud/hud.gd")
const ART_PATH := "res://art/effects/drift_mark.png"
const RECORD_PATH := "res://art/effects/drift_mark.json"


func _marks() -> Node2D:
	var m: Node2D = MarksScene.instantiate()
	add_child_autofree(m)
	m.set_process(false)
	return m


func _record() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(RECORD_PATH))


func test_the_scene_uses_the_drawn_texture_tiled() -> void:
	var m := _marks()
	assert_eq(m.mark_texture.resource_path, ART_PATH)
	assert_eq(m.texture_mode, Line2D.LINE_TEXTURE_TILE, "tiled along the mark")
	assert_eq(m.mark_color, Color(1, 1, 1, 1), "no tint: the texture's own colours")
	assert_eq(m.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	for i in 5:
		m.lay(true, Vector2(0.5 * i, 0.0), 0.3)
	for l in m.pieces():
		assert_eq(l.texture, m.mark_texture)
		assert_eq(l.texture_mode, Line2D.LINE_TEXTURE_TILE)
		assert_eq(l.texture_repeat, CanvasItem.TEXTURE_REPEAT_ENABLED, "repeats along the mark")
		assert_eq(l.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)


func test_the_texture_matches_its_record() -> void:
	var rec := _record()
	assert_false(rec.has("endpoint"), "a script-made record, not a PixelLab one")
	var img: Image = load(ART_PATH).get_image()
	var tread: Array = rec.tread
	assert_eq(img.get_height(), tread.size(), "rows across the mark")
	assert_eq(img.get_width(), String(tread[0]).length(), "texels along the mark")
	for y in tread.size():
		var row: String = tread[y]
		for x in row.length():
			var c: Color = img.get_pixel(x, y)
			var ch := row[x]
			if ch == ".":
				assert_eq(c.a, 0.0, "clear at %d,%d" % [x, y])
			else:
				var want: Array = rec.palette[ch]
				assert_eq(Color8(int(want[0]), int(want[1]), int(want[2])).to_html(false), c.to_html(false), "colour at %d,%d" % [x, y])
				assert_eq(c.a, 1.0)


func test_the_texture_is_dark_rubber_with_a_transparent_background() -> void:
	var img: Image = load(ART_PATH).get_image()
	var w := img.get_width()
	var h := img.get_height()
	for corner in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]:
		assert_eq(img.get_pixelv(corner).a, 0.0, "transparent corner")
	var red: Color = HudScript.HEART_COLOR
	var colours := {}
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			assert_true(c.a == 0.0 or c.a == 1.0, "no semi-transparent pixels")
			if c.a == 0.0:
				assert_true(y == 0 or y == h - 1, "only the shoulder rows have gaps: the mark never breaks up")
				continue
			colours[c.to_html(false)] = true
			assert_lt(c.get_luminance(), 0.2, "dark rubber")
			assert_gt(Vector3(c.r - red.r, c.g - red.g, c.b - red.b).length(), 0.5, "far from Redgull red")
	assert_lte(colours.size(), 30, "about 30 colours or fewer")
	assert_gt(colours.size(), 1, "a tread pattern, not one flat colour")


func test_marks_in_a_run_use_the_new_texture() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.drift_marks.set_process(false)
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.scripted_input = [true, false, -1.0]
	for i in 40:
		car.physics_step()
	assert_gt(run.drift_marks.pieces().size(), 0)
	for l in run.drift_marks.pieces():
		assert_eq(l.texture.resource_path, ART_PATH)
