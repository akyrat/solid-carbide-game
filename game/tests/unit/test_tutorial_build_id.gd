extends GutTest
## Task T-572: the tutorial comes back with each new itch.io build. The "Don't show again" tick
## saves the build id it was made on; in a build with an id the slides stay hidden only on that
## build. No id (the desktop game) keeps T-382's behaviour; an old tick with no id shows once.

var TEST_PATH := RunPaths.file("test_settings_t572.cfg")
var ID_PATH := RunPaths.file("test_build_id_t572.txt")


func before_each() -> void:
	GameSettings.path = TEST_PATH
	GameSettings.build_id_path = ID_PATH
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(ID_PATH)


func after_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(ID_PATH)
	TestSave.restore_settings()


func _set_build(id: String) -> void:
	var f := FileAccess.open(ID_PATH, FileAccess.WRITE)
	f.store_string(id + "\n")
	f.close()


func test_no_file_means_no_build_id() -> void:
	assert_eq(GameSettings.build_id(), "")


func test_build_id_is_read_and_trimmed() -> void:
	_set_build("  abc1234 ")
	assert_eq(GameSettings.build_id(), "abc1234")


func test_the_game_reads_res_build_id_txt() -> void:
	assert_eq(GameSettings.DEFAULT_BUILD_ID_PATH, "res://build_id.txt")


func test_tick_on_build_a_shows_again_on_build_b_and_retick_hides_on_b() -> void:
	_set_build("aaaaaaa")
	assert_false(GameSettings.load_tutorial_hidden(), "shown by default")
	GameSettings.save_tutorial_hidden(true)
	assert_true(GameSettings.load_tutorial_hidden(), "hidden on build A")
	_set_build("bbbbbbb")
	assert_false(GameSettings.load_tutorial_hidden(), "shown again on build B")
	GameSettings.save_tutorial_hidden(true)
	assert_true(GameSettings.load_tutorial_hidden(), "hidden again on build B")
	var cfg := ConfigFile.new()
	cfg.load(TEST_PATH)
	assert_eq(cfg.get_value("tutorial", "hidden_build"), "bbbbbbb")


func test_no_build_id_keeps_todays_behaviour() -> void:
	GameSettings.save_tutorial_hidden(true)
	assert_true(GameSettings.load_tutorial_hidden())
	GameSettings.save_tutorial_hidden(false)
	assert_false(GameSettings.load_tutorial_hidden())


func test_a_tick_made_on_a_build_still_hides_with_no_build_id() -> void:
	_set_build("aaaaaaa")
	GameSettings.save_tutorial_hidden(true)
	DirAccess.remove_absolute(ID_PATH)
	assert_true(GameSettings.load_tutorial_hidden(), "no id: the tick alone decides")


func test_an_old_tick_with_no_id_shows_once_in_the_first_build_with_an_id() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("tutorial", "hidden", true)  # a save from before T-572
	cfg.save(TEST_PATH)
	assert_true(GameSettings.load_tutorial_hidden(), "still hidden with no build id")
	_set_build("aaaaaaa")
	assert_false(GameSettings.load_tutorial_hidden(), "shown once in the first build with an id")
	GameSettings.save_tutorial_hidden(true)
	assert_true(GameSettings.load_tutorial_hidden(), "ticked again: hidden on that build")


func test_empty_build_id_file_means_no_id() -> void:
	_set_build("")
	GameSettings.save_tutorial_hidden(true)
	assert_true(GameSettings.load_tutorial_hidden())


func test_the_tests_never_read_the_real_build_id() -> void:
	TestSave.restore_settings()
	assert_ne(GameSettings.build_id_path, GameSettings.DEFAULT_BUILD_ID_PATH)
