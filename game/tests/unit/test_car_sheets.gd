extends GutTest
## Tests for the placeholder car sprite sheets (T-013, redrawn at 3:1 in T-018), drawn by
## tools/car_sheet_generator.gd and written by tools/generate_car_sheets.gd.

const Generator := preload("res://tools/car_sheet_generator.gd")
const SHEET_DIR := "res://art/placeholders/car"
const TMP_DIR := "user://test_car_sheets"


func _sheet_path(view: String) -> String:
	return SHEET_DIR.path_join("car_%s.png" % view)


func _json_path(view: String) -> String:
	return SHEET_DIR.path_join("car_%s.json" % view)


## The committed PNG as raw pixels (not the imported texture).
func _load_committed(view: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(_sheet_path(view)))


func _read_json(view: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_json_path(view)))
	return data if data is Dictionary else {}


## Centroid of the pixels of one colour inside a frame, relative to the car's centre.
func _centroid(image: Image, frame: int, color: Color) -> Vector2:
	var sum := Vector2.ZERO
	var count := 0
	for y in Generator.FRAME:
		for x in Generator.FRAME:
			if image.get_pixel(frame * Generator.FRAME + x, y).is_equal_approx(color):
				sum += Vector2(x + 0.5, y + 0.5)
				count += 1
	if count == 0:
		return Vector2.ZERO
	return sum / count - Generator.CENTER


func _angle_diff_deg(a: float, b: float) -> float:
	return absf(wrapf(a - b, -180.0, 180.0))


func test_sheets_have_16_equal_frames() -> void:
	for view in Generator.VIEWS:
		var image := _load_committed(view)
		assert_not_null(image, "%s sheet loads" % view)
		if image == null:
			continue
		assert_eq(image.get_width(), 16 * 80, "%s sheet width = 16 frames of 80" % view)
		assert_eq(image.get_height(), 80, "%s sheet height = one row of 80" % view)


func test_godot_imports_sheets() -> void:
	for view in Generator.VIEWS:
		var tex: Texture2D = load(_sheet_path(view))
		assert_not_null(tex, "Godot imports %s" % _sheet_path(view))
		if tex != null:
			assert_eq(tex.get_size(), Vector2(1280, 80), "imported size of %s" % view)


func test_json_layout() -> void:
	for view in Generator.VIEWS:
		var data := _read_json(view)
		assert_false(data.is_empty(), "%s JSON parses" % view)
		assert_eq(int(data.get("frame_width", 0)), 80, "%s frame_width" % view)
		assert_eq(int(data.get("frame_height", 0)), 80, "%s frame_height" % view)
		assert_eq(int(data.get("frame_count", 0)), 16, "%s frame_count" % view)
		assert_eq(float(data.get("frame0_heading_deg", -1.0)), 0.0, "%s frame 0 heading" % view)
		assert_eq(float(data.get("step_deg", 0.0)), 22.5, "%s step" % view)
		assert_true(data.has("order"), "%s has order" % view)
		assert_eq(data.get("center_px", {}), {"x": 40.0, "y": 40.0}, "%s centre pixel" % view)
		assert_eq(data.get("car_size_units", {}), {"width": 1.0, "length": 3.0}, "%s size in units" % view)
		assert_eq(data.get("car_size_px", {}), {"width": 16.0, "length": 48.0}, "%s size in pixels" % view)
		assert_eq(float(data.get("px_per_unit", 0.0)), 16.0, "%s pixels per unit" % view)
		assert_eq(data.get("file", ""), "car_%s.png" % view, "%s file name" % view)
		assert_true(bool(data.get("placeholder", false)), "%s marked as placeholder" % view)
		assert_eq((data.get("frames", []) as Array).size(), 16, "%s lists 16 frames" % view)


func test_only_body_and_nose_colours() -> void:
	for view in Generator.VIEWS:
		var image := _load_committed(view)
		for frame in Generator.DIRECTIONS:
			var body := 0
			var nose := 0
			var other := 0
			for y in Generator.FRAME:
				for x in Generator.FRAME:
					var c := image.get_pixel(frame * Generator.FRAME + x, y)
					if c.a == 0.0:
						continue
					if c.is_equal_approx(Generator.BODY_COLOR):
						body += 1
					elif c.is_equal_approx(Generator.NOSE_COLOR):
						nose += 1
					else:
						other += 1
			assert_eq(other, 0, "%s frame %d: no colours besides body and nose" % [view, frame])
			assert_gt(nose, 0, "%s frame %d has a nose" % [view, frame])
			assert_gt(body, nose * 2, "%s frame %d: body is the larger part" % [view, frame])


func test_flat_frame0_exact_rectangle() -> void:
	# Heading 0: a 48 x 16 rectangle (3:1) centred on (40, 40), nose = the right-most 8 columns.
	var image := _load_committed("flat")
	for y in 80:
		for x in 80:
			var inside := x >= 16 and x < 64 and y >= 32 and y < 48
			var c := image.get_pixel(x, y)
			if not inside:
				assert_eq(c.a, 0.0, "(%d, %d) is transparent" % [x, y])
			elif x >= 56:
				assert_true(c.is_equal_approx(Generator.NOSE_COLOR), "(%d, %d) is nose" % [x, y])
			else:
				assert_true(c.is_equal_approx(Generator.BODY_COLOR), "(%d, %d) is body" % [x, y])


func test_flat_frame4_exact_rectangle() -> void:
	# Heading 90 (nose down): a 16 x 48 rectangle centred on (40, 40), nose = the bottom 8 rows.
	var image := _load_committed("flat")
	var origin := 4 * 80
	for y in 80:
		for x in 80:
			var inside := x >= 32 and x < 48 and y >= 16 and y < 64
			var c := image.get_pixel(origin + x, y)
			if not inside:
				assert_eq(c.a, 0.0, "frame 4 (%d, %d) is transparent" % [x, y])
			elif y >= 56:
				assert_true(c.is_equal_approx(Generator.NOSE_COLOR), "frame 4 (%d, %d) is nose" % [x, y])
			else:
				assert_true(c.is_equal_approx(Generator.BODY_COLOR), "frame 4 (%d, %d) is body" % [x, y])


func test_every_frame_is_3_to_1_before_projection() -> void:
	# Un-project every drawn pixel to the flat world and measure the car along and
	# across its heading: 48 long and 16 wide (within a pixel of sampling error).
	for view in Generator.VIEWS:
		var image := _load_committed(view)
		for frame in Generator.DIRECTIONS:
			var forward := Generator.nose_world(frame)
			var right := forward.orthogonal()
			var min_a := INF
			var max_a := -INF
			var min_c := INF
			var max_c := -INF
			for y in Generator.FRAME:
				for x in Generator.FRAME:
					if image.get_pixel(frame * Generator.FRAME + x, y).a == 0.0:
						continue
					var world := Generator.unproject(view, Vector2(x + 0.5, y + 0.5) - Generator.CENTER)
					min_a = minf(min_a, world.dot(forward))
					max_a = maxf(max_a, world.dot(forward))
					min_c = minf(min_c, world.dot(right))
					max_c = maxf(max_c, world.dot(right))
			var length := max_a - min_a
			var width := max_c - min_c
			assert_almost_eq(length, 48.0, 2.5, "%s frame %d length %.1f" % [view, frame, length])
			assert_almost_eq(width, 16.0, 2.5, "%s frame %d width %.1f" % [view, frame, width])
			# Centred on the frame's centre.
			assert_almost_eq((max_a + min_a) * 0.5, 0.0, 1.5, "%s frame %d centred along" % [view, frame])
			assert_almost_eq((max_c + min_c) * 0.5, 0.0, 1.5, "%s frame %d centred across" % [view, frame])


func test_frames_leave_an_empty_border() -> void:
	# The frame is large enough for the longer car: no frame touches its edges.
	for view in Generator.VIEWS:
		var image := _load_committed(view)
		for frame in Generator.DIRECTIONS:
			var touched := 0
			for i in Generator.FRAME:
				for p in [Vector2i(i, 0), Vector2i(i, Generator.FRAME - 1),
						Vector2i(0, i), Vector2i(Generator.FRAME - 1, i)]:
					if image.get_pixel(frame * Generator.FRAME + p.x, p.y).a != 0.0:
						touched += 1
			assert_eq(touched, 0, "%s frame %d stays inside the frame" % [view, frame])


func test_nose_faces_chosen_directions() -> void:
	# Expected screen direction of the nose: flat frames 0/4/8/12 = right/down/left/up;
	# iso frames 0/2/4/6/8 = world east/south-east/south/south-west/west projected 2:1.
	var cases := [
		["flat", 0, 0.0], ["flat", 4, 90.0], ["flat", 8, 180.0], ["flat", 12, 270.0],
		["flat", 2, 45.0], ["flat", 3, 67.5],
		["iso", 0, rad_to_deg(Vector2(1, 0.5).angle())],
		["iso", 2, 90.0],
		["iso", 4, rad_to_deg(Vector2(-1, 0.5).angle())],
		["iso", 6, 180.0],
		["iso", 14, 0.0],
		["iso", 10, 270.0],
	]
	for c in cases:
		var image := _load_committed(c[0])
		var nose := _centroid(image, c[1], Generator.NOSE_COLOR)
		var got := fposmod(rad_to_deg(nose.angle()), 360.0)
		assert_lt(_angle_diff_deg(got, c[2]), 6.0,
			"%s frame %d nose at %.1f deg, expected %.1f" % [c[0], c[1], got, c[2]])


func test_nose_turns_22_5_degrees_per_frame_in_world() -> void:
	for view in Generator.VIEWS:
		var image := _load_committed(view)
		for frame in Generator.DIRECTIONS:
			var nose_world := Generator.unproject(view, _centroid(image, frame, Generator.NOSE_COLOR))
			var got := fposmod(rad_to_deg(nose_world.angle()), 360.0)
			assert_lt(_angle_diff_deg(got, frame * 22.5), 4.0,
				"%s frame %d world heading %.1f, expected %.1f" % [view, frame, got, frame * 22.5])


func test_committed_sheets_match_generator() -> void:
	for view in Generator.VIEWS:
		var committed := _load_committed(view)
		var built := Generator.build_sheet(view)
		assert_eq(committed.get_data(), built.get_data(),
			"%s sheet is up to date with the generator (rerun generate_car_sheets)" % view)
		var json_text := FileAccess.get_file_as_string(_json_path(view))
		var built_json: Dictionary = JSON.parse_string(Generator.describe_json(view, "car_%s.png" % view, "x"))
		var committed_json: Dictionary = JSON.parse_string(json_text)
		built_json.erase("record")
		committed_json.erase("record")
		assert_eq(committed_json, built_json, "%s JSON layout is up to date" % view)


func test_two_runs_are_byte_identical() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TMP_DIR))
	for view in Generator.VIEWS:
		var a := TMP_DIR.path_join("a_%s.png" % view)
		var b := TMP_DIR.path_join("b_%s.png" % view)
		assert_eq(Generator.build_sheet(view).save_png(a), OK, "first save")
		assert_eq(Generator.build_sheet(view).save_png(b), OK, "second save")
		assert_eq(FileAccess.get_file_as_bytes(a), FileAccess.get_file_as_bytes(b),
			"%s PNG bytes identical on a second run" % view)
		assert_eq(FileAccess.get_file_as_bytes(a),
			FileAccess.get_file_as_bytes(_sheet_path(view)),
			"%s PNG bytes identical to the committed sheet" % view)
		assert_eq(Generator.describe_json(view, "f", "c"), Generator.describe_json(view, "f", "c"),
			"%s JSON identical on a second run" % view)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(a))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(b))
