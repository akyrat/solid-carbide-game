extends GutTest
## Task T-388: every sound effect is off for the MVP with one switch ("sfx_enabled" in
## data/sfx.json); the music keeps playing; the files and the saved SFX volume stay.

const RunScene := preload("res://scenes/run/run.tscn")
const GameScene := preload("res://scenes/game/game.tscn")
var TEST_PATH := RunPaths.file("test_settings_t388.cfg")
var PROGRESS_PATH := RunPaths.file("test_progress_t388.json")


func before_each() -> void:
	GameSettings.sfx_enabled_override = -1  # read the real switch from the data file
	GameSettings.path = TEST_PATH
	PlayerProgress.path = PROGRESS_PATH
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	TestSave.restore_settings()
	TestSave.restore_progress()
	GameSettings.apply_sfx_volume(GameSettings.load_sfx_volume())
	GameSettings.apply_music_volume(GameSettings.load_music_volume())


func _sfx_bus() -> int:
	return AudioServer.get_bus_index(GameSettings.SFX_BUS)


func test_the_switch_in_the_data_file_is_off() -> void:
	var raw = GameData.unwrap(GameData.load_file("sfx"))
	assert_eq(raw["sfx_enabled"], false)
	assert_false(GameSettings.sfx_enabled())


func test_the_bus_is_muted_at_volume_100() -> void:
	GameSettings.save_sfx_volume(100.0)
	GameSettings.apply_sfx_volume(GameSettings.load_sfx_volume())
	assert_true(AudioServer.is_bus_mute(_sfx_bus()), "muted whatever the saved volume")
	assert_eq(GameSettings.load_sfx_volume(), 100.0, "the saved volume setting is kept")


func test_no_sound_effect_id_is_audible_at_volume_100() -> void:
	GameSettings.save_sfx_volume(100.0)
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var snd: Node = run.sounds
	var raw = GameData.unwrap(GameData.load_file("sfx"))
	assert_gt(raw["sounds"].size(), 0)
	for id in raw["sounds"]:
		assert_true(snd.has_sound(id), "%s is still loaded (code kept)" % id)
		assert_false(snd.play(id), "%s does not start" % id)
		assert_false(snd.is_playing(id), "%s has no playing player" % id)
		assert_eq(snd.play_counts[id], 0, id)
	assert_true(AudioServer.is_bus_mute(_sfx_bus()), "and the bus is muted")


func test_a_run_starts_no_loops() -> void:
	GameSettings.save_sfx_volume(100.0)
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.sounds.sync_loops()
	run.car.model.is_drifting = true
	run.sounds.sync_loops()
	for id in ["engine", "drift", "flames"]:
		assert_false(run.sounds.is_playing(id), id)


func test_turning_the_switch_on_brings_the_sounds_back() -> void:
	GameSettings.sfx_enabled_override = 1
	GameSettings.save_sfx_volume(100.0)
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	assert_false(AudioServer.is_bus_mute(_sfx_bus()))
	run.sounds.sync_loops()
	assert_true(run.sounds.is_playing("engine"))
	GameSettings.sfx_enabled_override = -1


func test_the_music_plays_in_the_menu_and_during_a_run_at_the_saved_volume() -> void:
	GameSettings.save_music_volume(65.0)
	var game: Node = GameScene.instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)
	var music_bus := AudioServer.get_bus_index(GameSettings.MUSIC_BUS)
	assert_true(game.music.player.playing, "playing in the main menu")
	assert_almost_eq(db_to_linear(AudioServer.get_bus_volume_db(music_bus)), 0.65, 0.01)
	game.start_run()
	assert_true(game.music.player.playing, "and during a run")
	assert_false(AudioServer.is_bus_mute(music_bus))
	assert_almost_eq(db_to_linear(AudioServer.get_bus_volume_db(music_bus)), 0.65, 0.01)


func test_nothing_was_deleted() -> void:
	for f in ["res://scripts/run/run_sounds.gd", "res://data/sfx.json"]:
		assert_true(FileAccess.file_exists(f), f)
	assert_true(GameSettings.save_sfx_volume(42.0))
	assert_eq(GameSettings.load_sfx_volume(), 42.0)
