extends GutTest
## Task T-186: the PixelLab art of the elevation test scene's platform and ramp
## (game/art/elevation/) replaces the script drawing: the images exist with
## their records, follow Visual style's technical rules (hard edges, at most
## 30 colours, transparent background, no Redgull red), are placed so their
## size matches the pieces in data/level/elevation_test.json at 32 art px per
## unit drawn at 0.5, and the scene keeps the depth order with the car.

const SCENE := preload("res://scenes/elevation_test/elevation_test.tscn")
const DIR := "res://art/elevation/"
const MAX_COLORS := 30

var scene: Node2D


func before_each() -> void:
	scene = SCENE.instantiate()
	add_child_autofree(scene)
	scene.car.set_physics_process(false)
	scene.car.use_keyboard = false
	scene.car.detect_tricks = false


func _record(kind: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(DIR + kind + ".json"))


func _image(kind: String) -> Image:
	return (load(DIR + kind + ".png") as Texture2D).get_image()


func test_images_and_records_exist() -> void:
	for kind in ["platform", "ramp"]:
		assert_true(ResourceLoader.exists(DIR + kind + ".png"), kind + " image")
		var rec := _record(kind)
		assert_eq(rec.task, "T-186")
		assert_eq(int(rec.px_per_unit), 32)
		assert_gt(rec.pixellab.size(), 0, "names the PixelLab records it came from")


func test_the_image_sizes_match_the_pieces_at_32_px_per_unit() -> void:
	# Platform 16 x 16 units, height 3: (16 + 16) * 32 wide; (16 + 16) * 16 + 3 * 32 tall.
	var p := _image("platform")
	assert_eq(Vector2i(p.get_width(), p.get_height()), Vector2i(1024, 608))
	# Ramp 12 x 8 units east of it: (12 + 8) * 32 wide; from the top at height 3 to the foot.
	var r := _image("ramp")
	assert_eq(Vector2i(r.get_width(), r.get_height()), Vector2i(640, 416))


func test_the_rules_hold_for_each_image() -> void:
	for kind in ["platform", "ramp"]:
		var img := _image(kind)
		var colours := {}
		var semi := 0
		var reddish := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.0 and c.a < 1.0:
					semi += 1
				if c.a == 1.0:
					colours[c.to_rgba32()] = true
					if c.r8 > 110 and c.g8 < 60 and c.b8 < 70:
						reddish += 1
		assert_eq(semi, 0, kind + ": no semi-transparent pixels")
		assert_lte(colours.size(), MAX_COLORS, kind + ": colours")
		assert_eq(reddish, 0, kind + ": no Redgull red")
		for corner in [Vector2i(0, 0), Vector2i(img.get_width() - 1, 0), Vector2i(0, img.get_height() - 1), Vector2i(img.get_width() - 1, img.get_height() - 1)]:
			assert_eq(img.get_pixelv(corner).a, 0.0, kind + ": transparent corner")


func test_the_scene_uses_the_art_not_the_placeholder() -> void:
	assert_eq(scene.areas.size(), 2)
	for a in scene.areas:
		assert_not_null(a.art_sprite, a.kind + " has its art sprite")
		assert_eq(a.art_sprite.scale, Vector2(0.5, 0.5))
		assert_eq(a.art_sprite.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)


func test_the_art_lines_up_with_the_geometry() -> void:
	# The platform's top-left corner of the top face (-8, -8) at height 3 is the
	# top vertex of the image: drawn pixel (0, -8 * 16 - 48) = (0, -176).
	var p = scene.areas[0]
	var top: PackedVector2Array = p.top_face()
	assert_eq(p.art_sprite.position.y, top[0].y, "the image's top is the top face's top corner")
	assert_eq(p.art_sprite.position.x, top[3].x, "the image's left is the top face's west corner")
	var r = scene.areas[1]
	var rt: PackedVector2Array = r.top_face()
	assert_eq(r.art_sprite.position.y, rt[0].y, "the ramp's image top is its high north corner")
	assert_eq(r.art_sprite.position.x, rt[3].x)


func test_the_depth_order_with_the_car_is_unchanged() -> void:
	scene.place_car(Vector2(0, 0), 0.0)
	scene.sync_view()
	assert_gt(scene.car_sprite.z_index, scene.areas[0].z_index, "on the platform: over it")
	scene.place_car(Vector2(-10, 0), 0.0)
	scene.sync_view()
	assert_lt(scene.car_sprite.z_index, scene.areas[0].z_index, "west of it: under it")
