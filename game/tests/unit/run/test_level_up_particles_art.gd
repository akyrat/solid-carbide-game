extends GutTest
## Task T-074: the level-up effect's final particle art, a script-drawn sheet
## (tools/build_level_up_particles.py) read as a flipbook, one random shape per
## particle, drawn at the car art's density.

const BurstScene := preload("res://scenes/run/level_up_burst.tscn")
const SHEET := "res://art/effects/level_up_particles.png"
const RECORD := "res://art/effects/level_up_particles.json"

var burst: CPUParticles2D


func before_each() -> void:
	burst = BurstScene.instantiate()
	autofree(burst)


func _record() -> Dictionary:
	var f := FileAccess.open(RECORD, FileAccess.READ)
	return JSON.parse_string(f.get_as_text())


func test_scene_uses_the_particle_sheet() -> void:
	assert_eq(burst.texture.resource_path, SHEET)


func test_sheet_matches_its_record() -> void:
	var rec := _record()
	var frames: int = rec["frames"].size()
	var size: Array = rec["frame_size"]
	assert_eq(burst.texture.get_width(), frames * int(size[0]))
	assert_eq(burst.texture.get_height(), int(size[1]))


func test_each_particle_gets_one_random_shape() -> void:
	var mat := burst.material as CanvasItemMaterial
	assert_not_null(mat, "a CanvasItemMaterial reads the sheet as a flipbook")
	assert_true(mat.particles_animation)
	assert_eq(mat.particles_anim_h_frames, _record()["frames"].size(), "one frame per shape")
	assert_eq(mat.particles_anim_v_frames, 1)
	assert_eq(burst.anim_offset_min, 0.0)
	assert_eq(burst.anim_offset_max, 1.0, "any shape")
	assert_eq(burst.anim_speed_min, 0.0, "a particle keeps its shape")
	assert_eq(burst.anim_speed_max, 0.0)
	assert_eq(mat.blend_mode, CanvasItemMaterial.BLEND_MODE_MIX, "no additive glow: the glow is in the pixels")


func test_drawn_at_the_car_art_density_and_never_rotated() -> void:
	assert_eq(burst.scale_amount_min, 0.5, "32 art pixels per unit at 16 world pixels per unit, as the car")
	assert_eq(burst.scale_amount_max, 0.5)
	assert_eq(burst.angle_min, 0.0, "pixel art stays upright")
	assert_eq(burst.angle_max, 0.0)
	assert_eq(burst.angular_velocity_max, 0.0)


func test_particles_shrink_then_pop_out_without_fading() -> void:
	var c := burst.scale_amount_curve
	assert_eq(c.sample(0.0), 1.0, "full size at the start")
	assert_eq(c.sample(0.5), 1.0)
	assert_almost_eq(c.sample(0.75), 0.5, 0.01, "then half size")
	assert_eq(c.sample(0.95), 0.0, "then gone")
	for col in burst.color_ramp.colors:
		assert_eq(col.a, 1.0, "no alpha fade")
