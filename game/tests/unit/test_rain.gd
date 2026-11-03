extends GutTest
## Task T-507: rain over the map. The rain_enabled setting (default false since T-510, saved with the other
## settings), its effect at once, the numbers from data/rain.json, the drawing order in the run
## (over the world, under the HUD), and the rain moving along its slant with splashes.

const RainScript := preload("res://scripts/level/rain.gd")
const RunScene := preload("res://scenes/run/run.tscn")
var TEST_PATH := RunPaths.file("test_settings_t507.cfg")


func before_each() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)


func after_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()


func _rain() -> CanvasLayer:
	var r: CanvasLayer = RainScript.new()
	r.screen_size_override = Vector2(1920, 1080)
	r.canvas_override = Transform2D.IDENTITY
	add_child_autofree(r)
	return r


# --- The setting ---

func test_setting_defaults_to_false() -> void:
	assert_false(GameSettings.DEFAULT_RAIN_ENABLED)
	assert_false(GameSettings.load_rain_enabled())


func test_saved_settings_without_the_rain_key_read_false() -> void:
	GameSettings.save_zoom(10.0)
	assert_false(GameSettings.load_rain_enabled())


func test_no_rain_draws_in_a_new_players_run() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.car.use_keyboard = false
	await wait_process_frames(4)
	assert_false(run.rain.enabled)
	assert_false(run.rain.visible)
	assert_eq(run.rain.draw_count, 0)
	assert_eq(run.rain.drops.size(), 0)


func test_setting_round_trip() -> void:
	assert_true(GameSettings.save_rain_enabled(false))
	assert_false(GameSettings.load_rain_enabled())
	assert_true(GameSettings.save_rain_enabled(true))
	assert_true(GameSettings.load_rain_enabled())


func test_setting_saved_with_the_other_settings() -> void:
	GameSettings.save_sfx_volume(55.0)
	GameSettings.save_rain_enabled(false)
	GameSettings.save_zoom(10.0)
	assert_eq(GameSettings.load_sfx_volume(), 55.0)
	assert_eq(GameSettings.load_zoom(), 10.0)
	assert_false(GameSettings.load_rain_enabled())
	var cfg := ConfigFile.new()
	assert_eq(cfg.load(TEST_PATH), OK)
	assert_eq(cfg.get_value("graphics", "rain_enabled"), false)


func test_a_bad_saved_value_reads_as_the_default() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("graphics", "rain_enabled", "yes")
	cfg.save(TEST_PATH)
	assert_false(GameSettings.load_rain_enabled())


# --- Showing and hiding ---

func test_rain_reads_the_saved_setting_when_it_starts() -> void:
	GameSettings.save_rain_enabled(false)
	var r := _rain()
	assert_false(r.enabled)
	assert_false(r.visible)


func test_no_rain_draws_when_disabled() -> void:
	GameSettings.save_rain_enabled(false)
	var r := _rain()
	await wait_process_frames(4)
	assert_eq(r.draw_count, 0, "no drawing while the setting is off")
	assert_eq(r.drops.size(), 0)
	assert_false(r.is_processing())


func test_rain_draws_when_enabled() -> void:
	GameSettings.save_rain_enabled(true)
	var r := _rain()
	assert_true(r.enabled)
	await wait_process_frames(4)
	assert_gt(r.draw_count, 0)
	assert_eq(r.drops.size(), r.target_drop_count())
	assert_gt(r.drops.size(), 0)


func test_saving_the_setting_switches_the_rain_at_once() -> void:
	GameSettings.save_rain_enabled(true)
	var r := _rain()
	await wait_process_frames(2)
	GameSettings.save_rain_enabled(false)
	assert_false(r.enabled, "off as soon as it is saved, without waiting a frame")
	assert_false(r.visible)
	var drawn: int = r.draw_count
	await wait_process_frames(3)
	assert_eq(r.draw_count, drawn, "no more drawing while off")
	GameSettings.save_rain_enabled(true)
	assert_true(r.enabled, "on as soon as it is saved")
	assert_true(r.visible)
	await wait_process_frames(3)
	assert_gt(r.draw_count, drawn)


# --- Numbers from the JSON ---

func test_numbers_come_from_the_json_file() -> void:
	var data: Dictionary = GameData.unwrap(GameData.load_file("rain"))
	var r := _rain()
	for k in ["drops_per_screen", "fall_speed", "angle_deg", "drop_length", "splash_chance", "max_splashes", "splash_life"]:
		assert_true(data.has(k), "rain.json has %s" % k)
		assert_eq(float(r.config[k]), float(data[k]), k)


func test_a_test_file_changes_the_look() -> void:
	var path := RunPaths.file("test_rain_t507.json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"drops_per_screen": 10, "angle_deg": 0.0, "drop_length": 6, "fall_speed": 100.0}))
	f.close()
	var r := _rain()
	r.load_config(path)
	DirAccess.remove_absolute(path)
	assert_eq(r.target_drop_count(), 10)
	assert_eq(r.drop_texture.get_height(), 6)
	assert_eq(r.drop_texture.get_width(), 1, "angle 0: a straight streak")


# --- The look ---

func test_drops_fall_down_the_screen_at_a_slant() -> void:
	var r := _rain()
	r.set_process(false)
	r.step(0.0)
	for d in r.drops:
		d.life = 10.0
	var before: Vector2 = r.drops[0].p
	r.step(0.1)
	var moved: Vector2 = r.drops[0].p - before
	assert_gt(moved.y, 0.0, "falls down the screen")
	assert_lt(moved.x, 0.0, "leans: drifts sideways as it falls")
	assert_almost_eq(rad_to_deg(atan2(-moved.x, moved.y)), float(r.config.angle_deg), 0.01)
	assert_almost_eq(moved.length(), float(r.config.fall_speed) * 0.1, 0.01)


func test_drops_that_end_leave_splashes() -> void:
	var r := _rain()
	r.set_process(false)
	r.config.splash_chance = 1.0
	r.step(0.0)
	for i in 30:
		r.step(0.05)
	assert_gt(r.splashes.size(), 0)
	assert_lte(r.splashes.size(), r.max_splash_count())


func test_splashes_end_after_their_life() -> void:
	var r := _rain()
	r.set_process(false)
	r.splashes = [{"p": Vector2(10, 10), "age": 0.0}]
	r.config.splash_chance = 0.0
	r.step(float(r.config.splash_life) + 0.01)
	assert_eq(r.splashes.size(), 0)


func test_the_rain_moves_with_the_map() -> void:
	var r := _rain()
	r.step(0.0)
	var p := Vector2(100, 100)
	var a: Vector2 = r.to_screen_art(p, 1.0)
	r.canvas_override = Transform2D(0.0, Vector2(-10, 0))  # the camera moved 10 px right
	var b: Vector2 = r.to_screen_art(p, 1.0)
	assert_eq(b - a, Vector2(-10, 0))


func test_placeholder_drop_is_opaque_pixels_with_a_lit_tip() -> void:
	var img: Image = RainScript.make_drop_image(10, 18.0, Color8(170, 190, 220), Color8(215, 228, 245))
	assert_eq(img.get_height(), 10)
	var count := 0
	for y in img.get_height():
		for x in img.get_width():
			var a := img.get_pixel(x, y).a
			assert_true(a == 0.0 or a == 1.0, "no see-through pixels")
			if a == 1.0:
				count += 1
	assert_eq(count, 10, "one pixel per row")
	assert_eq(img.get_pixel(0, 9), Color8(215, 228, 245), "the lowest pixel is the lit tip, at the left")


func test_placeholder_has_none_of_greenbulls_colours() -> void:
	for k in ["drop_colour", "drop_highlight_colour", "splash_colour"]:
		var c: Array = RainScript.DEFAULTS[k]
		assert_false(c == [104, 220, 96] or c == [247, 208, 52] or c == [12, 76, 44], k)


func test_pixel_size_follows_the_zoom() -> void:
	var r := _rain()
	r.canvas_override = Transform2D.IDENTITY.scaled(Vector2(4, 4))
	assert_eq(r.pixel_size(), 2.0)
	r.canvas_override = Transform2D.IDENTITY.scaled(Vector2(0.5, 0.5))
	assert_eq(r.pixel_size(), 1.0, "never below one screen pixel")


# --- In the run ---

func test_run_draws_rain_over_the_world_and_under_the_hud() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.car.use_keyboard = false
	GameSettings.save_rain_enabled(true)
	var rain: CanvasLayer = run.get_node("Rain")
	assert_eq(rain, run.rain)
	assert_gt(rain.layer, 0, "over the map, the car and the enemies (the default canvas, layer 0)")
	assert_lt(rain.layer, run.hud.layer, "under the HUD")
	assert_lt(rain.layer, run.level_up_screen.layer)
	assert_false(run.view_root is CanvasLayer)
	assert_false(run.minions is CanvasLayer, "enemies draw on the world's canvas")
	await wait_process_frames(3)
	assert_gt(rain.draw_count, 0, "it rains in a run when the setting is on")
	GameSettings.save_rain_enabled(false)
	assert_false(rain.visible, "the run's rain hides as soon as the setting is saved off")


# --- The PixelLab art (T-509) ---

func test_the_rain_uses_the_art_not_the_placeholder() -> void:
	var r := _rain()
	assert_eq(str(r.config.drop_texture), "res://art/rain/rain_drops.png")
	assert_eq(str(r.config.splash_texture), "res://art/rain/rain_splash.png")
	assert_eq(r.drop_texture.get_size(), Vector2(24, 16), "3 drop variants of 8 x 16")
	assert_eq(int(r.config.drop_variants), 3)
	assert_eq(r.splash_texture.get_size(), Vector2(48, 8), "4 splash frames of 12 x 8")
	assert_eq(int(r.config.splash_frames), 4)


func test_drops_use_all_variants_and_draw() -> void:
	GameSettings.save_rain_enabled(true)
	var r := _rain()
	r.set_process(false)
	r.step(0.0)
	var seen := {}
	for d in r.drops:
		seen[d.v] = true
	assert_eq(seen.size(), 3, "every variant is in use")
	var drawn: int = r.draw_count
	r._canvas.queue_redraw()
	await wait_process_frames(2)
	assert_gt(r.draw_count, drawn)
