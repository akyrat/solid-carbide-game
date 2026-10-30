extends GutTest
## Task T-403: the red hit flash (Game loop architecture, Decisions, "A red flash when
## the car takes damage"). The helper (scripts/run/hit_flash.gd), its numbers from
## run.json, the car flashing on a hit that counts and not on an ignored one.

const RunScene := preload("res://scenes/run/run.tscn")
const KaijuBossScript := preload("res://scripts/enemies/kaiju_boss.gd")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")


func after_each() -> void:
	KaijuBossScript.playtest_override = -2.0
	FlameScript.playtest_override = -1


func _run_scene() -> Node2D:
	KaijuBossScript.playtest_override = -1.0
	FlameScript.playtest_override = 0
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	return run


func test_the_numbers_come_from_run_json() -> void:
	var d := RunData.new()
	var flash := HitFlash.from_data(d)
	assert_eq(flash.seconds, d.hit_flash_seconds())
	assert_eq(flash.color, d.hit_flash_color())
	assert_gt(d.hit_flash_seconds(), 0.0)
	assert_gt(d.hit_flash_color().r, d.hit_flash_color().g, "red")
	assert_gt(d.hit_flash_color().r, d.hit_flash_color().b, "red")


func test_the_helper_lasts_its_seconds_then_is_white() -> void:
	var flash := HitFlash.new()
	flash.seconds = 0.4
	flash.color = Color(1, 0, 0)
	var item := Node2D.new()
	add_child_autofree(item)
	flash.apply_to(item)
	assert_eq(item.modulate, Color.WHITE, "plain before a hit")
	flash.trigger()
	flash.apply_to(item)
	assert_eq(item.modulate, Color(1, 0, 0), "red at once")
	flash.advance(0.39)
	assert_true(flash.is_active())
	flash.advance(0.02)
	flash.apply_to(item)
	assert_false(flash.is_active())
	assert_eq(item.modulate, Color.WHITE, "plain after")
	flash.trigger()
	flash.advance(0.3)
	flash.trigger()
	flash.advance(0.3)
	assert_true(flash.is_active(), "a new hit restarts the flash")
	flash.reset()
	assert_false(flash.is_active())


func test_the_car_flashes_red_on_a_hit_with_the_blink_still_working() -> void:
	var run := _run_scene()
	var d := RunData.new()
	assert_eq(run.car_sprite.modulate, Color.WHITE)
	run.state.damage_car(1.0)
	run.car_flash.apply_to(run.car_sprite)
	run.apply_blink()
	assert_eq(run.car_sprite.modulate, d.hit_flash_color(), "red, with the file's colour")
	assert_false(run.car_sprite.visible, "hidden in the first blink phase")
	# Second blink phase: shown, and red.
	run.state.advance(d.blink_interval_seconds() + 0.001)
	run.car_flash.advance(d.blink_interval_seconds() + 0.001)
	run.apply_blink()
	run.car_flash.apply_to(run.car_sprite)
	assert_true(run.car_sprite.visible)
	assert_eq(run.car_sprite.modulate, d.hit_flash_color(), "shown phase is red")
	# Past the flash, still blinking, plain.
	run.state.advance(d.hit_flash_seconds())
	run.car_flash.advance(d.hit_flash_seconds())
	run.car_flash.apply_to(run.car_sprite)
	assert_eq(run.car_sprite.modulate, Color.WHITE, "plain after the flash")
	assert_true(run.state.is_invulnerable(), "the invulnerability goes on")


func test_a_hit_ignored_during_the_invulnerability_does_not_flash() -> void:
	var run := _run_scene()
	run.state.damage_car(1.0)
	run.car_flash.advance(0.5)
	assert_false(run.car_flash.is_active())
	run.state.damage_car(1.0)  # ignored: invulnerable
	assert_false(run.car_flash.is_active(), "no new flash")
	assert_eq(run.state.hearts, 4)


func test_a_new_run_clears_the_flash() -> void:
	var run := _run_scene()
	run.state.damage_car(1.0)
	assert_true(run.car_flash.is_active())
	run.start_run()
	assert_false(run.car_flash.is_active())
	assert_eq(run.car_sprite.modulate, Color.WHITE)
