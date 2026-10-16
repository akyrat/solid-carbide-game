extends GutTest
## Task T-123: the camera options (camera smoothing and the dynamic camera),
## their saved settings, and the API for the pause screen's controls (T-124),
## in the drift prototype, the run and a run started from the main menu.

const CameraFollowScript := preload("res://scripts/driving/camera_follow.gd")
const CarModelScript := preload("res://scripts/driving/car_model.gd")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const GameScene := preload("res://scenes/game/game.tscn")
var TEST_PATH := RunPaths.file("test_settings_t123.cfg")
const DT := 0.02


func before_each() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()


func _prototype() -> Node2D:
	var p: Node2D = PrototypeScene.instantiate()
	add_child_autofree(p)
	p.car.use_keyboard = false
	p.car.scripted_input = [true, false, 0.0]
	return p


func _run() -> Node2D:
	var r: Node2D = RunScene.instantiate()
	add_child_autofree(r)
	r.car.use_keyboard = false
	r.car.scripted_input = [true, false, 0.0]
	return r


func _expected_zoom(scene: Node2D, size: float) -> float:
	return scene.get_viewport().get_visible_rect().size.y / (2.0 * size * 16.0)


# --- Both options off: exactly as before. ---

func test_defaults_are_both_off_with_proposed_min_and_max_in_the_slider_range() -> void:
	assert_false(GameSettings.load_camera_smoothing())
	assert_false(GameSettings.load_dynamic_camera())
	var lo := GameSettings.load_dynamic_zoom_min()
	var hi := GameSettings.load_dynamic_zoom_max()
	assert_eq(lo, GameSettings.DEFAULT_DYNAMIC_ZOOM_MIN)
	assert_eq(hi, GameSettings.DEFAULT_DYNAMIC_ZOOM_MAX)
	assert_between(lo, GameSettings.MIN_ZOOM, GameSettings.MAX_ZOOM)
	assert_between(hi, GameSettings.MIN_ZOOM, GameSettings.MAX_ZOOM)
	assert_lt(lo, hi, "zoomed in at a standstill, out at top speed")


func test_model_with_both_off_sits_on_the_car_with_the_slider_zoom() -> void:
	var c = CameraFollowScript.new()
	c.set_base_size(9.0)
	for i in 20:
		c.step(Vector2(i * 7.0, -i * 3.0), 0.8, DT)
		assert_eq(c.position, Vector2(i * 7.0, -i * 3.0))
		assert_eq(c.size, 9.0)


func test_prototype_with_both_off_keeps_the_camera_exactly_on_the_car() -> void:
	var p := _prototype()
	p.set_zoom(9.5)
	await wait_physics_frames(30)
	assert_ne(p.car.position, Vector2.ZERO, "the car moved")
	assert_eq(p.camera.position, p.car_sprite.position, "exactly on the drawn car")
	assert_almost_eq(p.camera.zoom.y, _expected_zoom(p, 9.5), 1e-6, "the slider's zoom")
	assert_false(p.camera.position_smoothing_enabled)


func test_run_with_both_off_keeps_the_camera_exactly_on_the_car() -> void:
	var r := _run()
	r.set_zoom(12.0)
	await wait_physics_frames(30)
	assert_ne(r.car.position, Vector2.ZERO, "the car moved")
	assert_eq(r.camera.position, r.car_sprite.position, "exactly on the drawn car")
	assert_almost_eq(r.camera.zoom.y, _expected_zoom(r, 12.0), 1e-6, "the slider's zoom")


# --- Camera smoothing. ---

func test_model_smoothing_lags_behind_a_moving_car_and_catches_up_when_it_stops() -> void:
	var c = CameraFollowScript.new()
	c.smoothing = true
	c.snap(Vector2.ZERO, 0.0)
	var v := 33.0 * 16.0  # the game's top speed, in drawn pixels per second
	var target := Vector2.ZERO
	for i in 100:
		target.x += v * DT
		c.step(target, 1.0, DT)
		assert_lt(c.position.x, target.x, "behind the car")
	var lag: float = target.x - c.position.x
	assert_gt(lag, 0.0)
	# Settles near v / rate (in pixels): a short lag, a few units.
	assert_almost_eq(lag, v / CameraFollowScript.SMOOTHING_RATE, v * DT, "lag about v / rate")
	for i in 75:  # the car stopped: 1.5 s
		c.step(target, 0.0, DT)
	assert_lt(target.x - c.position.x, 0.5, "caught up to within half a pixel")


func test_prototype_smoothing_lags_and_catches_up() -> void:
	var p := _prototype()
	p.camera_follow.set_smoothing(true)
	await wait_physics_frames(40)
	var gap: Vector2 = p.car_sprite.position - p.camera.position
	assert_gt(gap.length(), 8.0, "the camera trails the moving car")
	p.car.scripted_input = [false, false, 0.0]
	p.car.model.set_velocity(Vector2.ZERO)
	await wait_physics_frames(60)
	assert_lt((p.car_sprite.position - p.camera.position).length(), 1.0, "caught up once stopped")


func test_run_smoothing_lags_behind_the_car() -> void:
	var r := _run()
	r.camera_follow.set_smoothing(true)
	await wait_physics_frames(40)
	assert_gt((r.car_sprite.position - r.camera.position).length(), 8.0, "the camera trails the car")
	r.camera_follow.set_smoothing(false)
	await wait_physics_frames(2)
	assert_eq(r.camera.position, r.car_sprite.position, "off again: back exactly on the car")


# --- The dynamic camera. ---

func test_target_zoom_is_min_at_standstill_max_at_top_speed_and_between_at_half() -> void:
	var c = CameraFollowScript.new()
	c.dynamic_min = 10.0
	c.dynamic_max = 18.0
	assert_eq(c.target_size(0.0), 10.0)
	assert_eq(c.target_size(1.0), 18.0)
	assert_eq(c.target_size(0.5), 14.0)
	assert_eq(c.target_size(2.0), 18.0, "clamped above top speed")


func test_speed_fraction_is_the_share_of_the_top_forward_speed() -> void:
	var m = CarModelScript.new()
	var top: float = m.tuning.top_speed()
	assert_eq(CameraFollowScript.speed_fraction_of(m), 0.0, "standstill")
	m.set_velocity(Vector2(0.0, -top))
	assert_almost_eq(CameraFollowScript.speed_fraction_of(m), 1.0, 1e-6, "top speed")
	m.set_velocity(Vector2(top * 0.5, 0.0))
	assert_almost_eq(CameraFollowScript.speed_fraction_of(m), 0.5, 1e-6, "half speed")


func test_actual_zoom_eases_toward_the_target_without_jumping() -> void:
	var c = CameraFollowScript.new()
	c.dynamic = true
	c.dynamic_min = 10.0
	c.dynamic_max = 18.0
	c.snap(Vector2.ZERO, 0.0)
	assert_eq(c.size, 10.0, "starts at the min at a standstill")
	var last: float = c.size
	for i in 50:  # one second at top speed
		c.step(Vector2.ZERO, 1.0, DT)
		assert_gt(c.size, last, "moves toward the max every step")
		assert_lt(c.size - last, 0.5, "never jumps (under 0.5 per step)")
		last = c.size
	assert_lt(c.size, 18.0, "still easing after a second")
	assert_gt(c.size, 10.0 + 8.0 * 0.9, "but over 90% of the way")
	for i in 150:
		c.step(Vector2.ZERO, 1.0, DT)
	assert_almost_eq(c.size, 18.0, 0.01, "settles at the max")


func test_prototype_dynamic_camera_follows_the_speed() -> void:
	var p := _prototype()
	p.car.scripted_input = [false, false, 0.0]
	p.set_zoom(14.4)
	p.camera_follow.set_dynamic(true)
	await wait_physics_frames(2)
	var lo: float = GameSettings.DEFAULT_DYNAMIC_ZOOM_MIN
	var hi: float = GameSettings.DEFAULT_DYNAMIC_ZOOM_MAX
	# From the slider's 14.4 it eases to the min at a standstill.
	await wait_physics_frames(150)
	assert_almost_eq(p.camera_follow.size, lo, 0.02, "the min at a standstill")
	assert_almost_eq(p.camera.zoom.y, _expected_zoom(p, p.camera_follow.size), 1e-6, "on the camera")
	p.car.collision_mask = 0  # drive through the test room's walls
	p.car.model.set_velocity(Vector2(0.0, -p.car.model.tuning.top_speed()))
	p.car.scripted_input = [true, false, 0.0]  # W holds top speed
	var sizes: Array[float] = []
	p.car.stepped.connect(func(): sizes.append(p.camera_follow.size))
	await wait_physics_frames(200)
	var last: float = lo
	for s in sizes:
		assert_true(s >= last - 1e-9 and s - last < 0.5, "eases out, step by step, no jumps")
		last = s
	assert_almost_eq(p.camera_follow.size, hi, 0.05, "the max at top speed")
	assert_almost_eq(p.zoom, 14.4, 1e-9, "the slider's zoom is kept")


func test_turning_the_dynamic_camera_off_goes_back_to_the_slider_zoom() -> void:
	var p := _prototype()
	p.set_zoom(8.0)
	p.camera_follow.set_dynamic(true)
	await wait_physics_frames(60)
	assert_ne(p.camera_follow.size, 8.0)
	p.camera_follow.set_dynamic(false)
	assert_eq(p.camera_follow.size, 8.0)
	assert_almost_eq(p.camera.zoom.y, _expected_zoom(p, 8.0), 1e-6, "applied at once")


func test_slider_still_zooms_when_the_dynamic_camera_is_off() -> void:
	var p := _prototype()
	p.pause_screen.zoom_slider.value = 7.0
	assert_almost_eq(p.camera.zoom.y, _expected_zoom(p, 7.0), 1e-6)


func test_run_dynamic_camera_eases_toward_its_target() -> void:
	var r := _run()
	r.camera_follow.set_dynamic(true)
	await wait_physics_frames(80)
	var goal: float = r.camera_follow.target_size(CameraFollowScript.speed_fraction_of(r.car.model))
	assert_gt(r.camera_follow.size, GameSettings.DEFAULT_DYNAMIC_ZOOM_MIN, "zooms out as the car speeds up")
	assert_almost_eq(r.camera_follow.size, goal, 1.5, "near the speed's zoom")
	assert_almost_eq(r.camera.zoom.y, _expected_zoom(r, r.camera_follow.size), 1e-6)


# --- Saved settings and the API for T-124. ---

func test_options_min_and_max_are_saved_and_loaded() -> void:
	var p := _prototype()
	p.camera_follow.set_smoothing(true)
	p.camera_follow.set_dynamic(true)
	p.set_zoom(7.5)
	assert_eq(p.camera_follow.set_dynamic_min_from_current(), 7.5)
	p.set_zoom(19.0)
	assert_eq(p.camera_follow.set_dynamic_max_from_current(), 19.0)
	assert_eq(p.camera_follow.get_dynamic_min(), 7.5)
	assert_eq(p.camera_follow.get_dynamic_max(), 19.0)
	assert_true(GameSettings.load_camera_smoothing())
	assert_true(GameSettings.load_dynamic_camera())
	assert_eq(GameSettings.load_dynamic_zoom_min(), 7.5)
	assert_eq(GameSettings.load_dynamic_zoom_max(), 19.0)
	assert_almost_eq(GameSettings.load_zoom(), 14.4, 1e-9, "the zoom itself is untouched")
	# A new scene reads them back.
	var q := _prototype()
	assert_true(q.camera_follow.is_smoothing())
	assert_true(q.camera_follow.is_dynamic())
	assert_eq(q.camera_follow.get_dynamic_min(), 7.5)
	assert_eq(q.camera_follow.get_dynamic_max(), 19.0)
	assert_eq(q.camera_follow.size, 7.5, "starts at the min at a standstill")
	# And off again is saved too.
	q.camera_follow.set_smoothing(false)
	q.camera_follow.set_dynamic(false)
	assert_false(GameSettings.load_camera_smoothing())
	assert_false(GameSettings.load_dynamic_camera())


func test_saving_keeps_the_other_settings() -> void:
	GameSettings.save_zoom(9.0)
	GameSettings.save_camera_smoothing(true)
	GameSettings.save_dynamic_zoom_min(8.0)
	GameSettings.save_dynamic_zoom_max(16.0)
	GameSettings.save_dynamic_camera(true)
	assert_almost_eq(GameSettings.load_zoom(), 9.0, 1e-9)
	assert_true(GameSettings.load_camera_smoothing())
	assert_true(GameSettings.load_dynamic_camera())
	assert_eq(GameSettings.load_dynamic_zoom_min(), 8.0)
	assert_eq(GameSettings.load_dynamic_zoom_max(), 16.0)


func test_bad_or_out_of_range_values_fall_back_or_clamp() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("camera", "smoothing", "yes")
	cfg.set_value("camera", "dynamic", 3)
	cfg.set_value("camera", "dynamic_min", 2.0)
	cfg.set_value("camera", "dynamic_max", "far")
	cfg.save(TEST_PATH)
	assert_false(GameSettings.load_camera_smoothing())
	assert_false(GameSettings.load_dynamic_camera())
	assert_eq(GameSettings.load_dynamic_zoom_min(), GameSettings.MIN_ZOOM, "clamped to 6")
	assert_eq(GameSettings.load_dynamic_zoom_max(), GameSettings.DEFAULT_DYNAMIC_ZOOM_MAX)


func test_the_saved_min_and_max_are_readable() -> void:
	GameSettings.save_dynamic_zoom_min(9.0)
	GameSettings.save_dynamic_zoom_max(18.5)
	var report := GameSettings.dynamic_zoom_report()
	assert_string_contains(report, "min 9.0")
	assert_string_contains(report, "max 18.5")
	assert_string_contains(report, "test_settings_t123.cfg")
	var text := FileAccess.get_file_as_string(TEST_PATH)
	assert_string_contains(text, "dynamic_min=9.0")
	assert_string_contains(text, "dynamic_max=18.5")


func test_a_run_from_the_main_menu_uses_the_saved_options() -> void:
	GameSettings.save_camera_smoothing(true)
	GameSettings.save_dynamic_camera(true)
	GameSettings.save_dynamic_zoom_min(9.0)
	var game: Node = GameScene.instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	assert_true(game.run.camera_follow.is_smoothing())
	assert_true(game.run.camera_follow.is_dynamic())
	assert_eq(game.run.camera_follow.size, 9.0, "the min at the start")
	assert_almost_eq(game.run.camera.zoom.y, _expected_zoom(game.run, 9.0), 1e-6)


func test_a_run_from_the_main_menu_with_both_off_is_as_before() -> void:
	GameSettings.save_zoom(11.0)
	var game: Node = GameScene.instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	assert_false(game.run.camera_follow.is_smoothing())
	assert_false(game.run.camera_follow.is_dynamic())
	game.run.car.use_keyboard = false
	game.run.car.scripted_input = [true, false, 0.0]
	await wait_physics_frames(20)
	assert_eq(game.run.camera.position, game.run.car_sprite.position)
	assert_almost_eq(game.run.camera.zoom.y, _expected_zoom(game.run, 11.0), 1e-6)
