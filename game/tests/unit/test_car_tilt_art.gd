extends GutTest
## Task T-555: the tilt art (game/art/car/car_iso_tilt.png and .json) is in, and the car's drawing
## shows it through T-551's hook (car_sprite.gd, set_tilt_step) instead of the placeholder shear.

const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const SHEET := "res://art/car/car_iso_tilt"

var _world: Node2D


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)


func _sprite() -> Sprite2D:
	var sprite: Sprite2D = CarSpriteScript.new()
	_world.add_child(sprite)
	sprite.use_sheet("iso")
	return sprite


func test_the_sheet_and_its_layout() -> void:
	assert_true(ResourceLoader.exists(SHEET + ".png"), "the tilt sheet is in game/art/car/")
	var tex: Texture2D = load(SHEET + ".png")
	assert_eq(tex.get_width(), 32 * 128, "32 directions")
	assert_eq(tex.get_height(), 3 * 128, "3 steps")
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SHEET + ".json"))
	assert_eq(int(layout.columns), 32)
	assert_eq(int(layout.rows), 3)
	assert_eq(int(layout.frame_width), 128)
	assert_eq(int(layout.frame_height), 128)
	assert_eq(float(layout.px_per_unit), 32.0)
	var normal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/car/car_iso.json"))
	assert_eq(float(layout.center_px.x), float(normal.center_px.x), "the car's own centre")
	assert_eq(float(layout.center_px.y), float(normal.center_px.y))
	assert_false(bool(layout.drop_shadow))


func test_the_hook_draws_the_art_not_the_placeholder() -> void:
	var sprite := _sprite()
	assert_true(sprite.has_tilt_art, "the art replaces the placeholder")
	for heading in [0.0, 0.7, 2.3, 4.0, 5.9]:
		sprite.set_tilt_step(0)
		sprite.set_heading(heading)
		var dir_frame: int = sprite.frame
		var base_scale: Vector2 = sprite.scale
		var normal_tex: Texture2D = sprite.texture
		for step in [1, 2, 3]:
			sprite.set_tilt_step(step)
			assert_eq(sprite.hframes, 32)
			assert_eq(sprite.vframes, 3)
			assert_eq(sprite.frame, (step - 1) * 32 + dir_frame, "row = step, column = direction")
			assert_ne(sprite.texture, normal_tex, "drawn from the tilt sheet")
			assert_eq(sprite.skew, 0.0, "no placeholder shear")
			assert_eq(sprite.scale, base_scale, "no placeholder squash")
		sprite.set_tilt_step(0)
		assert_eq(sprite.frame, dir_frame, "back to the normal frame")
		assert_eq(sprite.texture, normal_tex)


func test_turning_while_tilted_keeps_the_step() -> void:
	var sprite := _sprite()
	sprite.set_tilt_step(3)
	sprite.set_heading(0.0)
	var a: int = sprite.frame
	sprite.set_heading(PI)
	assert_eq(sprite.frame, 64 + 16, "held pose, the opposite direction")
	assert_ne(sprite.frame, a)


func test_every_tilt_frame_has_the_car() -> void:
	var img: Image = (load(SHEET + ".png") as Texture2D).get_image()
	for step in 3:
		for dir in 32:
			var opaque := 0
			for y in range(0, 128, 2):
				for x in range(0, 128, 2):
					if img.get_pixel(dir * 128 + x, step * 128 + y).a > 0.5:
						opaque += 1
			assert_gt(opaque, 500, "step %d direction %d has the car" % [step + 1, dir])
