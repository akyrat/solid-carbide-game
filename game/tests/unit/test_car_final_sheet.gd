extends GutTest
## Tasks T-101 and T-102: the final pixel-art car sheet (32 directions since T-102) (isometric view), its layout JSON
## (T-013's convention) and its use in the run and the drift prototype.
## The sheet is built by tools/build_car_sheet32.py from T-101's 16 frames (Python
## tests: tools/test_build_car_sheet32.py).

const SHEET := "res://art/car/car_iso.png"
const LAYOUT := "res://art/car/car_iso.json"
const APPROVED := "res://art/car/car_sw_front.png"
const RunScene := preload("res://scenes/run/run.tscn")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")


func _layout() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))


func _image(path: String) -> Image:
	return (load(path) as Texture2D).get_image()


func test_sheet_is_32_frames_of_128_and_imports() -> void:
	var tex: Texture2D = load(SHEET)
	assert_not_null(tex, "Godot imports the sheet")
	assert_eq(tex.get_width(), 32 * 128)
	assert_eq(tex.get_height(), 128)


func test_layout_follows_t013_convention() -> void:
	var l := _layout()
	assert_eq(int(l.frame_count), 32)
	assert_eq(int(l.columns), 32)
	assert_eq(int(l.rows), 1)
	assert_eq(int(l.frame_width), 128)
	assert_eq(int(l.frame_height), 128)
	assert_eq(float(l.step_deg), 11.25)
	assert_eq(float(l.frame0_heading_deg), 0.0)
	assert_eq(l.file, "car_iso.png")
	assert_false(l.placeholder)
	assert_eq(l.frames.size(), 32)
	for i in 32:
		assert_eq(int(l.frames[i].index), i)
		assert_eq(float(l.frames[i].heading_deg), i * 11.25)
	assert_eq(float(l.car_size_units.length), 3.0)
	assert_eq(float(l.car_size_px.length), 3.0 * float(l.px_per_unit))


func test_frame_8_is_the_approved_sprite() -> void:
	var sheet := _image(SHEET)
	var approved := _image(APPROVED)
	var same := true
	for y in 128:
		for x in 128:
			var got := sheet.get_pixel(8 * 128 + x, y)
			var want := approved.get_pixel(x, y)
			# Fully transparent pixels count as equal whatever their hidden colour
			# (Godot's import may change it).
			if got.a8 == 0 and want.a8 == 0:
				continue
			if got.to_rgba32() != want.to_rgba32():
				same = false
	assert_true(same, "frame 8 (T-101's frame 4) is T-014's sprite, pixel for pixel (visible pixels)")


func test_every_frame_keeps_the_pixel_rules_and_the_approved_palette() -> void:
	var sheet := _image(SHEET)
	var approved := _image(APPROVED)
	var palette := {}
	for y in 128:
		for x in 128:
			var c := approved.get_pixel(x, y)
			if c.a8 == 255:
				palette[c.to_rgba32()] = true
	var semi := 0
	var foreign := 0
	for i in 32:
		var opaque := 0
		for y in 128:
			for x in 128:
				var c := sheet.get_pixel(i * 128 + x, y)
				if c.a8 != 0 and c.a8 != 255:
					semi += 1
				elif c.a8 == 255:
					opaque += 1
					if not palette.has(c.to_rgba32()):
						foreign += 1
		assert_gt(opaque, 1000, "frame %d shows the car" % i)
		for corner in [Vector2i(0, 0), Vector2i(127, 0), Vector2i(0, 127), Vector2i(127, 127)]:
			assert_eq(sheet.get_pixel(i * 128 + corner.x, corner.y).a8, 0, "frame %d corner transparent" % i)
	assert_eq(semi, 0, "no semi-transparent pixels")
	assert_eq(foreign, 0, "every opaque pixel uses a colour of the approved sprite")


func test_run_draws_the_final_car_about_3_units_long() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var sp: Sprite2D = run.car_sprite
	assert_eq(sp.texture.resource_path, SHEET)
	assert_eq(sp.hframes, 32)
	var l := _layout()
	# 3 units of the drawing, in sprite pixels, times the sprite's scale = 3 world units.
	var drawn_length: float = float(l.car_size_px.length) * sp.scale.x
	assert_almost_eq(drawn_length, 3.0 * 16.0, 0.001, "3 units long (16 world px per unit)")
	assert_eq(sp.frame, sp.frame_for_rotation(run.car.rotation))


func test_drift_prototype_iso_view_draws_the_final_car() -> void:
	var p: Node2D = PrototypeScene.instantiate()
	add_child_autofree(p)
	assert_eq(p.view, "iso")
	assert_eq(p.car_sprite.texture.resource_path, SHEET)
	assert_eq(p.car_sprite.scale, Vector2(0.5, 0.5))
