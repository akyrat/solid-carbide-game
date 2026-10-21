extends GutTest
## Task T-210: the pause screen's "Music volume" slider. 0 to 100, starts from the saved
## music setting (T-209), changes the Music bus at once and never the SFX bus, and is saved.

const RunScene := preload("res://scenes/run/run.tscn")
var TEST_PATH := RunPaths.file("test_settings_t210.cfg")


func before_each() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()
	GameSettings.apply_sfx_volume(GameSettings.load_sfx_volume())
	GameSettings.apply_music_volume(GameSettings.load_music_volume())


func _heard(bus_name: String) -> float:
	var i := AudioServer.get_bus_index(bus_name)
	return 0.0 if AudioServer.is_bus_mute(i) else db_to_linear(AudioServer.get_bus_volume_db(i))


func _screen() -> CanvasLayer:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var screen: CanvasLayer = preload("res://scripts/ui/pause_screen.gd").new()
	run.add_child(screen)
	screen.setup(run)
	return screen


func test_label_range_and_start_value() -> void:
	var screen := _screen()
	assert_eq(screen.music_label.text, "Music volume")
	assert_eq(screen.music_slider.min_value, 0.0)
	assert_eq(screen.music_slider.max_value, 100.0)
	assert_eq(screen.music_slider.value, GameSettings.DEFAULT_MUSIC_VOLUME)


func test_it_starts_from_the_saved_value() -> void:
	GameSettings.save_music_volume(65.0)
	var screen := _screen()
	assert_eq(screen.music_slider.value, 65.0)
	assert_eq(screen._music_value_label.text, "65")


func test_moving_it_changes_the_music_only_and_saves() -> void:
	var screen := _screen()
	GameSettings.apply_sfx_volume(30.0)
	screen.music_slider.value = 80.0
	assert_almost_eq(_heard(GameSettings.MUSIC_BUS), 0.8, 0.001)
	assert_almost_eq(_heard(GameSettings.SFX_BUS), 0.3, 0.001, "sound effects untouched")
	assert_eq(GameSettings.load_music_volume(), 80.0, "saved")
	assert_eq(screen._music_value_label.text, "80")
	screen.music_slider.value = 0.0
	assert_eq(_heard(GameSettings.MUSIC_BUS), 0.0)
	assert_eq(GameSettings.load_music_volume(), 0.0)


func test_the_sfx_slider_does_not_move_the_music() -> void:
	var screen := _screen()
	screen.music_slider.value = 55.0
	screen.sfx_slider.value = 20.0
	assert_almost_eq(_heard(GameSettings.MUSIC_BUS), 0.55, 0.001)
	assert_eq(GameSettings.load_music_volume(), 55.0)


func test_it_sits_directly_under_sfx_laid_out_like_it() -> void:
	var screen := _screen()
	screen.pause()
	await wait_process_frames(3)
	assert_almost_eq(screen.music_slider.size.x, screen.sfx_slider.size.x, 1.0, "same width")
	assert_ne(screen.music_slider.get_parent(), screen.sfx_slider.get_parent(), "its own row")
	assert_gt(screen.music_slider.get_global_rect().position.y, screen.sfx_slider.get_global_rect().end.y - 1.0, "under SFX")
	assert_lt(screen.music_slider.get_global_rect().end.y, screen.smoothing_check.get_global_rect().position.y + 1.0, "above the checkboxes")
	assert_eq(screen.music_slider.get_parent().get_child(0), screen.music_label, "label first")
	assert_eq(screen.music_slider.get_parent().get_child(2), screen._music_value_label, "number at the right end")
	assert_eq(screen.music_slider.get_parent().get_index(), screen.sfx_slider.get_parent().get_index() + 1)
