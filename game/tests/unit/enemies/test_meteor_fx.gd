extends GutTest
## Task T-070: the comet tail behind a falling meteor and the impact animation
## where it lands: the tail only while falling, the impact once on landing, the
## setting that picks the version, the sheets, and no red.

const RunScene := preload("res://scenes/run/run.tscn")
const KaijuBossScript := preload("res://scripts/enemies/kaiju_boss.gd")
const MeteorsScript := preload("res://scripts/enemies/kaiju_meteors.gd")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const DT := 0.02

var run: Node2D
var met: Node


func before_each() -> void:
	KaijuBossScript.playtest_override = -1.0
	FlameScript.playtest_override = 0
	MeteorFx.override = "pixel"
	run = RunScene.instantiate()
	add_child_autofree(run)
	met = run.kaiju_boss.meteors
	met.rng.seed = 70
	met.enabled = false
	run.minions.enabled = false
	run.car.use_keyboard = false


func after_each() -> void:
	MeteorFx.override = ""
	KaijuBossScript.playtest_override = -2.0
	FlameScript.playtest_override = -1


func _steps(seconds: float) -> void:
	for i in int(round(seconds / DT)):
		met.step(DT)


func _spot() -> Vector2:
	var car_units: Vector2 = run.car.position / 16.0
	for i in 64:
		var p := car_units + Vector2.RIGHT.rotated(TAU * i / 64.0 + 0.3) * 8.0
		if met.is_good_spot(p):
			return p
	fail_test("no good spot")
	return Vector2.ZERO


func _kaiju_far() -> void:
	var boss: Node = run.kaiju_boss
	var car_units: Vector2 = run.car.position / 16.0
	for i in 64:
		var p := car_units + Vector2.LEFT.rotated(TAU * i / 64.0) * 14.0
		if boss.is_free_spot(p):
			boss.appear_at(p)
			boss.enabled = false
			return


func test_the_tail_shows_only_while_the_meteor_falls() -> void:
	for ver in ["pixel", "pixellab", "particles"]:
		MeteorFx.override = ver
		var fall: float = MeteorsScript.FALL_SECONDS
		assert_false(MeteorFx.tail_active(fall + 0.5, fall), "%s: not before it appears" % ver)
		assert_true(MeteorFx.tail_active(fall, fall), "%s: from the start of the fall" % ver)
		assert_true(MeteorFx.tail_active(0.1, fall), "%s: while it falls" % ver)
		assert_false(MeteorFx.tail_active(0.0, fall), "%s: not once it has landed" % ver)
		assert_false(MeteorFx.tail_active(-0.1, fall), "%s: not after" % ver)
	MeteorFx.override = "off"
	assert_false(MeteorFx.tail_active(0.2, 0.5), "off: no tail at all")


func test_a_meteor_is_falling_only_in_the_last_part_of_its_warning() -> void:
	_kaiju_far()
	var w: Dictionary = met.add_warning(_spot())
	assert_eq(met.falling().size(), 0, "the warning circle alone")
	_steps(w.time_left - 0.3)
	assert_eq(met.falling().size(), 1, "falling, the tail shows")
	_steps(0.5)
	assert_eq(met.falling().size(), 0, "landed: no meteor, no tail")


func test_the_impact_plays_once_on_landing_then_goes() -> void:
	_kaiju_far()
	var landed := []
	met.meteor_landed.connect(func(u: Vector2, _hit: bool) -> void: landed.append(u))
	var w: Dictionary = met.add_warning(_spot())
	_steps(w.time_left - 0.1)
	assert_eq(met.dust.size(), 0, "no impact before it lands")
	_steps(0.2)
	assert_eq(landed.size(), 1)
	assert_eq(met.dust.size(), 1, "one impact animation")
	assert_almost_eq(float(met.dust[0].age), 0.1, 0.05)
	_steps(0.1)
	assert_eq(met.dust.size(), 1, "still playing")
	_steps(MeteorFx.impact_seconds())
	assert_eq(met.dust.size(), 0, "played once and gone")
	_steps(1.0)
	assert_eq(met.dust.size(), 0, "never again")
	assert_eq(landed.size(), 1)


func test_each_version_draws_without_trouble() -> void:
	_kaiju_far()
	for ver in ["pixel", "pixellab", "particles", "off"]:
		MeteorFx.override = ver
		met.clear()
		var w: Dictionary = met.add_warning(_spot())
		_steps(w.time_left - 0.3)
		await get_tree().process_frame
		await get_tree().process_frame
		_steps(0.35)
		await get_tree().process_frame
		assert_eq(met.dust.size(), 1, "%s: an impact is playing" % ver)
		await get_tree().process_frame
		assert_true(is_instance_valid(met.sky_draw), ver)


func test_the_setting_picks_the_version() -> void:
	MeteorFx.override = ""
	assert_true(MeteorFx.version() in MeteorFx.VERSIONS, "the file or the environment gives a known version")
	var f := FileAccess.open(MeteorFx.SETTINGS_PATH, FileAccess.READ)
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	assert_true(str(d["version"]) in MeteorFx.VERSIONS, "data/meteor_fx.json names a known version")
	MeteorFx.override = "particles"
	assert_eq(MeteorFx.version(), "particles")
	assert_almost_eq(MeteorFx.impact_seconds(), 0.6, 0.001)


func test_the_sheets_exist_with_the_right_frames_and_no_red() -> void:
	for ver in ["pixel", "pixellab"]:
		var tail := MeteorFx.texture("tail", ver)
		var imp := MeteorFx.texture("impact", ver)
		var n := MeteorFx.TAIL_FRAMES_PIXELLAB if ver == "pixellab" else MeteorFx.TAIL_FRAMES_PIXEL
		assert_eq(tail.get_width(), int(MeteorFx.CELL) * n, "%s tail sheet" % ver)
		assert_eq(tail.get_height(), int(MeteorFx.CELL))
		assert_eq(imp.get_width(), int(MeteorFx.CELL) * MeteorFx.IMPACT_FRAMES, "%s impact sheet" % ver)
		for tex in [tail, imp]:
			var img: Image = tex.get_image()
			var red := 0
			var semi := 0
			for y in img.get_height():
				for x in img.get_width():
					var c := img.get_pixel(x, y)
					if c.a > 0.0 and c.a < 1.0:
						semi += 1
					if c.a > 0.0 and c.r > 0.6 and c.g < 0.35 and c.b < 0.35:
						red += 1
			assert_eq(semi, 0, "%s: no semi-transparent pixels" % ver)
			assert_eq(red, 0, "%s: no red" % ver)


func test_particle_colours_are_not_red() -> void:
	for c in [MeteorFx.WHITE, MeteorFx.PINK, MeteorFx.MAGENTA, MeteorFx.VIOLET, MeteorFx.DEEP, MeteorFx.NAVY,
			MeteorFx.DARK, MeteorFx.DUST_LIGHT, MeteorFx.DUST_MID, MeteorFx.DUST_DARK]:
		assert_false(c.r > 0.6 and c.g < 0.35 and c.b < 0.35, "no red: %s" % c)


func test_frames_stay_in_range() -> void:
	for ver in ["pixel", "pixellab", "particles"]:
		MeteorFx.override = ver
		for t in [0.0, 0.1, 0.49, 0.5, 5.0]:
			assert_between(MeteorFx.impact_frame(t), 0, MeteorFx.IMPACT_FRAMES - 1)
			assert_between(MeteorFx.tail_frame(t), 0, 7)
