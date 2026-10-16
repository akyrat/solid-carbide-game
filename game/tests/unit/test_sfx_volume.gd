extends GutTest
## Task T-077 (board's tweak, 2026-10-16): the pause screen's "SFX volume" slider.
## 0 to 100, default 0 (silent), applied to the SFX bus at once, saved and loaded.

const RunScene := preload("res://scenes/run/run.tscn")
var TEST_PATH := RunPaths.file("test_settings_t077.cfg")


func before_each() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()
	GameSettings.apply_sfx_volume(GameSettings.load_sfx_volume())


func _bus() -> int:
	return AudioServer.get_bus_index(GameSettings.SFX_BUS)


func _heard() -> float:
	var i := _bus()
	return 0.0 if AudioServer.is_bus_mute(i) else db_to_linear(AudioServer.get_bus_volume_db(i))


func _run() -> Node2D:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	return run


func _screen(run: Node2D) -> CanvasLayer:
	var screen: CanvasLayer = preload("res://scripts/ui/pause_screen.gd").new()
	run.add_child(screen)
	screen.setup(run)
	return screen


func test_slider_exists_with_the_boards_label_and_range() -> void:
	var screen := _screen(_run())
	assert_eq(screen.sfx_label.text, "SFX volume")
	assert_eq(screen.sfx_slider.min_value, 0.0)
	assert_eq(screen.sfx_slider.max_value, 100.0)
	assert_eq(screen.sfx_slider.value, 0.0, "default 0")
	assert_true(AudioServer.is_bus_mute(_bus()), "so nothing is heard")


func test_moving_the_slider_applies_at_once_and_saves() -> void:
	var screen := _screen(_run())
	screen.sfx_slider.value = 100.0
	assert_almost_eq(_heard(), 1.0, 0.001)
	assert_eq(GameSettings.load_sfx_volume(), 100.0, "saved")
	screen.sfx_slider.value = 40.0
	assert_almost_eq(_heard(), 0.4, 0.001)
	screen.sfx_slider.value = 0.0
	assert_eq(_heard(), 0.0)
	assert_eq(GameSettings.load_sfx_volume(), 0.0)


func test_a_new_pause_screen_shows_the_saved_value() -> void:
	GameSettings.save_sfx_volume(65.0)
	var screen := _screen(_run())
	assert_eq(screen.sfx_slider.value, 65.0)


func test_default_is_zero_and_silent() -> void:
	assert_eq(GameSettings.load_sfx_volume(), 0.0)
	var run := _run()
	assert_gt(_bus(), -1, "the SFX bus exists")
	assert_eq(run.sounds.sounds["gun"]["players"][0].bus, "SFX", "sounds play on it")
	assert_true(AudioServer.is_bus_mute(_bus()), "nothing is heard at 0")


func test_a_change_applies_at_once() -> void:
	GameSettings.apply_sfx_volume(0.0)
	GameSettings.apply_sfx_volume(100.0)
	assert_almost_eq(_heard(), 1.0, 0.001, "100 = the per-sound volumes as they are")
	GameSettings.apply_sfx_volume(50.0)
	assert_almost_eq(_heard(), 0.5, 0.001)
	GameSettings.apply_sfx_volume(0.0)
	assert_eq(_heard(), 0.0)


func test_the_value_is_saved_and_loaded_back() -> void:
	assert_true(GameSettings.save_sfx_volume(37.0))
	assert_eq(GameSettings.load_sfx_volume(), 37.0)
	GameSettings.save_sfx_volume(250.0)
	assert_eq(GameSettings.load_sfx_volume(), 100.0, "clamped")
	var cfg := ConfigFile.new()
	cfg.load(TEST_PATH)
	cfg.set_value("audio", "sfx_volume", "loud")
	cfg.save(TEST_PATH)
	assert_eq(GameSettings.load_sfx_volume(), 0.0, "a bad value gives the default")


func test_saving_keeps_the_zoom_setting() -> void:
	GameSettings.save_zoom(10.0)
	GameSettings.save_sfx_volume(20.0)
	assert_eq(GameSettings.load_zoom(), 10.0)


func test_a_saved_value_counts_from_the_start_of_a_run() -> void:
	GameSettings.save_sfx_volume(100.0)
	_run()
	assert_almost_eq(_heard(), 1.0, 0.001)
