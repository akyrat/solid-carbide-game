extends GutTest
## Task T-112: the level-up effect, a burst of placeholder particles from the
## car on the run state's `level_up` signal (T-037).

const RunScene := preload("res://scenes/run/run.tscn")
const BurstScene := preload("res://scenes/run/level_up_burst.tscn")
const HudScript := preload("res://scripts/hud/hud.gd")

var run: Node2D


func before_each() -> void:
	run = RunScene.instantiate()
	add_child_autofree(run)
	await get_tree().process_frame


func after_each() -> void:
	get_tree().paused = false


func _level_up() -> void:
	run.state.add_xp(run.state.xp_needed())


func test_burst_is_in_the_run_and_not_playing_before() -> void:
	var burst: CPUParticles2D = run.level_up_burst
	assert_not_null(burst)
	assert_eq(burst.get_parent(), run.view_root, "drawn in the view, with the car")
	assert_gt(burst.get_index(), run.car_sprite.get_index(), "drawn over the car")
	assert_false(burst.emitting, "not playing before a level-up")
	assert_false(burst.is_playing())


func test_level_up_signal_starts_the_burst_on_the_car() -> void:
	var burst: CPUParticles2D = run.level_up_burst
	assert_false(burst.emitting)
	run.state.level_up.emit(2)
	assert_true(burst.emitting, "the level up signal starts the burst")
	assert_eq(burst.position, run.car_sprite.position, "at the car")


func test_a_real_level_up_starts_the_burst() -> void:
	var levels: Array = []
	run.state.level_up.connect(func(l: int) -> void: levels.append(l))
	assert_false(run.level_up_burst.emitting)
	_level_up()
	assert_eq(levels, [2])
	assert_true(run.level_up_burst.emitting)


func test_burst_follows_the_car_while_it_plays() -> void:
	_level_up()
	run.car.position += Vector2(200, -120)
	run.sync_view()
	assert_eq(run.level_up_burst.position, run.car_sprite.position)
	assert_true(run.level_up_burst.local_coords, "particles move with the car")


func test_several_level_ups_at_once_play_one_burst() -> void:
	var levels: Array = []
	run.state.level_up.connect(func(l: int) -> void: levels.append(l))
	run.state.add_xp(run.state.xp_needed() + RunData.new().xp_needed(2))
	assert_eq(levels, [2, 3])
	assert_true(run.level_up_burst.emitting)


func test_burst_ends_on_its_own() -> void:
	_level_up()
	var burst: CPUParticles2D = run.level_up_burst
	assert_true(burst.emitting)
	await get_tree().create_timer(burst.lifetime * 2.0 + 0.3).timeout
	assert_false(burst.emitting, "one burst, not a stream")


func test_burst_still_plays_while_the_run_is_paused() -> void:
	var burst: CPUParticles2D = run.level_up_burst
	assert_eq(burst.process_mode, Node.PROCESS_MODE_ALWAYS)
	run.state.pause_on_level_up = true
	_level_up()
	assert_true(get_tree().paused, "the level-up pauses the run")
	assert_true(burst.emitting)
	assert_true(burst.can_process(), "not frozen by the pause")


func test_settings_live_in_the_scene() -> void:
	var burst: CPUParticles2D = BurstScene.instantiate()
	autofree(burst)
	assert_not_null(burst.texture, "the particle texture is set in the scene")
	assert_true(burst.one_shot)
	assert_eq(burst.explosiveness, 1.0, "all at once")
	assert_gt(burst.amount, 0)
	assert_gt(burst.lifetime, 0.0)
	assert_gt(burst.initial_velocity_max, 0.0)
	assert_false(burst.emitting, "waits for a level-up")


func test_pixel_rules_nearest_no_alpha_fade() -> void:
	var burst: CPUParticles2D = BurstScene.instantiate()
	autofree(burst)
	assert_eq(burst.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "nearest-neighbour")
	assert_eq(burst.color.a, 1.0, "colour fully opaque")
	if burst.color_ramp != null:
		for c in burst.color_ramp.colors:
			assert_eq(c.a, 1.0, "colour ramp never fades alpha")
	if burst.color_initial_ramp != null:
		for c in burst.color_initial_ramp.colors:
			assert_eq(c.a, 1.0)
	assert_eq(burst.modulate.a, 1.0)
	assert_eq(burst.self_modulate.a, 1.0)
	var img := burst.texture.get_image()
	for y in img.get_height():
		for x in img.get_width():
			var a := img.get_pixel(x, y).a
			assert_true(a == 0.0 or a == 1.0, "no semi-transparent pixels")


## T-112 checked its placeholder (a light square of one colour) here; T-074
## swapped in the final particle sheet, so this checks every opaque pixel of
## the sheet against the same rule: far from Redgull red, and not any red.
func test_particle_art_is_not_redgull_red() -> void:
	var burst: CPUParticles2D = BurstScene.instantiate()
	autofree(burst)
	var img := burst.texture.get_image()
	var red: Color = HudScript.HEART_COLOR
	var opaque := 0
	var reds := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y) * burst.color
			if c.a == 0.0:
				continue
			opaque += 1
			var dist := Vector3(c.r - red.r, c.g - red.g, c.b - red.b).length()
			if dist <= 0.5 or (c.r > 0.5 and c.g < 0.4 and c.b < 0.4):
				reds += 1
	assert_gt(opaque, 0, "the sheet has particles")
	assert_eq(reds, 0, "far from Redgull red, and not any red")
	assert_eq(burst.color, Color(1, 1, 1, 1), "white, so the sprites show their own colours")


func test_burst_in_a_run_from_the_main_menu() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var r: Node2D = game.run
	assert_false(r.level_up_burst.emitting)
	r.state.add_xp(r.state.xp_needed())
	assert_true(r.level_up_burst.emitting)
