extends GutTest
## Task T-382: the tutorial_hidden setting, false by default, saved and loaded.

var TEST_PATH := RunPaths.file("test_settings_t382.cfg")


func before_each() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)


func after_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()


func test_default_is_false() -> void:
	assert_false(GameSettings.load_tutorial_hidden())


func test_round_trip() -> void:
	assert_true(GameSettings.save_tutorial_hidden(true))
	assert_true(GameSettings.load_tutorial_hidden())
	assert_true(GameSettings.save_tutorial_hidden(false))
	assert_false(GameSettings.load_tutorial_hidden())


func test_saved_with_the_other_settings() -> void:
	GameSettings.save_sfx_volume(55.0)
	GameSettings.save_tutorial_hidden(true)
	assert_eq(GameSettings.load_sfx_volume(), 55.0)
	assert_true(GameSettings.load_tutorial_hidden())
	GameSettings.save_sfx_volume(10.0)
	assert_true(GameSettings.load_tutorial_hidden())
