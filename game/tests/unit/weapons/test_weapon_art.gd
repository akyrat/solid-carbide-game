extends GutTest
## Task T-175: the final PixelLab art of the neon underglow, the molotov (bottle
## and fire area) and the windshield wiper replaces the code-drawn placeholders,
## at scale 0.5 (32 art pixels per unit), in a run with all the weapons owned.

const RunScene := preload("res://scenes/run/run.tscn")
const WeaponsScript := preload("res://scripts/weapons/weapons.gd")
const Glow := preload("res://scripts/weapons/neon_underglow.gd")
const Molotovs := preload("res://scripts/weapons/molotovs.gd")
const Fire := preload("res://scripts/weapons/molotov_fire.gd")
const Wiper := preload("res://scripts/weapons/windshield_wiper.gd")

var run: Node2D
var rack: Node


func before_each() -> void:
	WeaponsScript.all_weapons_override = 1
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	rack = run.weapons


func after_each() -> void:
	WeaponsScript.all_weapons_override = -1


func _size(path: String) -> Vector2i:
	var tex: Texture2D = load(path)
	assert_not_null(tex, "Godot loads %s" % path)
	return Vector2i(tex.get_size()) if tex != null else Vector2i.ZERO


func test_the_art_files_have_their_sizes() -> void:
	assert_eq(_size(Glow.ART_PATH), Vector2i(224, 112))
	assert_eq(_size(Molotovs.ART_PATH), Vector2i(32, 32))
	assert_eq(_size(Fire.ART_PATH), Vector2i(136, 68))
	assert_eq(_size(Fire.ART_FLIP_PATH), Vector2i(136, 68))
	assert_eq(_size(Wiper.ART_PATH), Vector2i(Wiper.ART_CELL.x * Wiper.ART_COLS, Wiper.ART_CELL.y * 4))


func test_the_imported_art_keeps_its_colours_and_transparent_corner() -> void:
	var tex: Texture2D = load(Glow.ART_PATH)
	var img := tex.get_image()
	assert_eq(img.get_pixel(0, 0).a, 0.0, "the corner is transparent")
	var colours := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				colours[c.to_html(false)] = true
	assert_gt(colours.size(), 3, "the ring is not one flat colour")


func test_the_underglow_art_is_at_scale_half_for_its_radius() -> void:
	var drawing = rack.underglow.drawing
	assert_not_null(drawing, "the underglow is drawn in the run")
	assert_almost_eq(drawing.art_scale(), 0.5, 0.001, "scale 0.5 at tier 1's radius")


func test_the_wiper_picks_a_frame_for_its_direction_and_draws() -> void:
	var drawing = rack.wiper.drawing
	assert_not_null(drawing, "the wiper is drawn in the run")
	for angle in [0.0, 1.0, 2.5, 4.0, 6.2]:
		var flat := Vector2.from_angle(angle) * 40.0
		drawing.set_arm(Wiper.ISO_TRANSFORM.basis_xform(flat))
		var expected := int(round(angle / TAU * float(Wiper.ART_FRAMES))) % Wiper.ART_FRAMES
		assert_eq(drawing.frame_index(), expected, "frame for %s radians" % angle)
	drawing.queue_redraw()
	await get_tree().process_frame
	pass_test("the wiper's art draws without error")


func test_a_bottle_and_its_fire_use_the_art() -> void:
	var bottle = rack.molotov.throw_to(run.car.model.get_position() + Vector2(3, 0))
	assert_not_null(bottle)
	bottle.queue_redraw()
	var fire = rack.molotov.land(run.car.model.get_position() + Vector2(3, 0))
	assert_not_null(fire)
	await get_tree().process_frame
	fire._flicker = 1
	fire.queue_redraw()
	await get_tree().process_frame
	pass_test("bottle and fire draw the art without error")
