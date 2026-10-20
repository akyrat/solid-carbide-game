extends GutTest
## Task T-198: the PixelLab rooftop and parking-garage ramp art of the elevation
## sample map (game/art/elevation_sample/, one sprite and record per area, built
## by game/tools/build_elevation_sample_art.py). The sample map scene shows each
## area's art in place of the script drawing, falls back to the script drawing
## when an area's art is missing, and the art fades with its area when the area
## turns see-through. The elevation test scene keeps its own art.

const SCENE := preload("res://scenes/elevation_sample/elevation_sample_map.tscn")
const PlatformDrawingScript := preload("res://scripts/level/elevation_platform_drawing.gd")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const DIR := "res://art/elevation_sample/"
const LAYOUT := "res://data/level/elevation_sample_map.json"
const MAX_COLORS := 30

var scene: Node2D
var data: Dictionary


func before_each() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	scene = SCENE.instantiate()
	add_child_autofree(scene)
	scene.car.set_physics_process(false)
	scene.car.use_keyboard = false
	scene.car.detect_tricks = false


func _ids() -> Array:
	var ids := []
	for p in data.platforms:
		ids.append(str(p.id))
	for r in data.ramps:
		ids.append(str(r.id))
	return ids


func _area(id: String):
	for a in scene.areas:
		if str(a.block.id) == id:
			return a
	return null


func test_one_sprite_and_record_per_area() -> void:
	for id in _ids():
		assert_true(ResourceLoader.exists(DIR + id + ".png"), id + " sprite")
		var rec = JSON.parse_string(FileAccess.get_file_as_string(DIR + id + ".json"))
		assert_eq(rec.task, "T-198")
		assert_eq(int(rec.px_per_unit), 32)
		assert_eq(float(rec.drawn_at_scale), 0.5)
		assert_gt(rec.pixellab.size(), 0, id + " names its PixelLab records")


func test_the_rules_hold_for_each_sprite() -> void:
	for id in _ids():
		var img := (load(DIR + id + ".png") as Texture2D).get_image()
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
		assert_eq(semi, 0, id + ": no semi-transparent pixels")
		assert_lte(colours.size(), MAX_COLORS, id + ": colours")
		assert_eq(reddish, 0, id + ": no Redgull red")
		for corner in [Vector2i(0, 0), Vector2i(img.get_width() - 1, 0), Vector2i(0, img.get_height() - 1), Vector2i(img.get_width() - 1, img.get_height() - 1)]:
			assert_eq(img.get_pixelv(corner).a, 0.0, id + ": transparent corner")


func test_every_area_shows_its_art_sprite() -> void:
	assert_eq(scene.areas.size(), _ids().size())
	for id in _ids():
		var a = _area(id)
		assert_not_null(a, id)
		assert_not_null(a.art_sprite, id + " shows its art")
		assert_eq(a.art_sprite.scale, Vector2(0.5, 0.5))
		assert_eq(a.art_sprite.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
		assert_eq(a.art_sprite.texture.resource_path, DIR + id + ".png")


func test_the_art_is_placed_by_its_record() -> void:
	for id in _ids():
		var a = _area(id)
		var rec = JSON.parse_string(FileAccess.get_file_as_string(DIR + id + ".json"))
		var origin := Vector2(rec.top_left_art_px[0], rec.top_left_art_px[1]) * 0.5
		assert_eq(a.art_sprite.position, origin)
		# The sprite covers the area's top face: its corners lie inside the image.
		var size: Vector2 = a.art_sprite.texture.get_size() * 0.5
		for corner in a.top_face():
			assert_true(Rect2(origin, size).grow(1.0).has_point(corner), "%s: top corner %s inside the sprite" % [id, corner])


func test_the_script_drawing_is_the_fallback_when_the_art_is_missing() -> void:
	var d = PlatformDrawingScript.new()
	add_child_autofree(d)
	d.setup("platform", _area("roof-nw-3").block, scene.ISO_TRANSFORM,
		PlatformDrawingScript.SAMPLE_ART_DIR, "no-such-area")
	assert_null(d.art_sprite, "no art for that name: no sprite")
	var found := d.east_face()
	assert_false(found.is_empty(), "the script drawing's geometry is still there to draw")
	# And with the art present it has a sprite.
	var e = PlatformDrawingScript.new()
	add_child_autofree(e)
	e.setup("platform", _area("roof-nw-3").block, scene.ISO_TRANSFORM, PlatformDrawingScript.SAMPLE_ART_DIR, "roof-nw-3")
	assert_not_null(e.art_sprite)


func test_the_art_fades_with_its_area() -> void:
	var a = _area("roof-nw-3")
	assert_eq(a.alpha(), 1.0)
	assert_eq(a.art_sprite.modulate.a, 1.0, "the sprite itself stays solid: the area's modulate carries the fade")
	# A car behind the rooftop, lower than its top, under it on screen.
	var centre := Vector2(-100.0, -81.0)
	scene.place_car(centre, 0.0)
	scene.car.height = 0.0
	var shape: PackedVector2Array = scene.car_shape_at(0.0)
	var covered := false
	for i in 40:
		covered = a.update_fade(centre, 0.5, 0.0, shape, 0.02)
	assert_true(covered, "the rooftop covers the car behind it")
	assert_almost_eq(a.alpha(), MvpMapScript.SEE_THROUGH_ALPHA, 0.001, "faded to the buildings' see-through alpha")
	# The sprite's effective alpha is the area's (parent modulate x its own).
	assert_almost_eq(a.modulate.a * a.art_sprite.modulate.a, a.alpha(), 0.0001)
	# And back to solid when nothing covers the car.
	for i in 40:
		a.update_fade(Vector2(0, 0), 0.5, 0.0, shape, 0.02)
	assert_eq(a.alpha(), 1.0, "solid again")


func test_the_elevation_test_scene_keeps_its_own_art() -> void:
	var d = PlatformDrawingScript.new()
	add_child_autofree(d)
	d.setup("platform", {"id": "p", "rect": Rect2(0, 0, 4, 4), "height": 3.0}, Transform2D.IDENTITY)
	assert_not_null(d.art_sprite, "the default art is art/elevation/platform.png")
	assert_eq(d.art_sprite.texture.resource_path, "res://art/elevation/platform.png")
