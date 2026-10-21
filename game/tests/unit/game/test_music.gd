extends GutTest
## Task T-209: the board's two tracks play through the whole game, alternating, on their
## own Music bus with their own saved volume setting.

const GameScene := preload("res://scenes/game/game.tscn")
var TEST_PATH := RunPaths.file("test_settings_t209.cfg")
var PROGRESS_PATH := RunPaths.file("test_progress_t209.json")
var game: Node


func before_each() -> void:
	GameSettings.path = TEST_PATH
	PlayerProgress.path = PROGRESS_PATH
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	game = GameScene.instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	TestSave.restore_settings()
	TestSave.restore_progress()
	GameSettings.apply_music_volume(GameSettings.load_music_volume())


func _name_of(m: MusicPlayer) -> String:
	return m.player.stream.resource_path.get_file()


func test_the_files_are_there_and_load() -> void:
	for t in MusicPlayer.TRACKS:
		assert_not_null(load(t), t)


func test_plays_track_1_then_2_then_1_again() -> void:
	var m: MusicPlayer = game.music
	assert_true(m.player.playing)
	assert_eq(_name_of(m), "demo_beat_1.mp3")
	m.player.finished.emit()
	assert_eq(_name_of(m), "demo_beat_2.mp3")
	assert_true(m.player.playing)
	m.player.finished.emit()
	assert_eq(_name_of(m), "demo_beat_1.mp3")
	m.player.finished.emit()
	assert_eq(_name_of(m), "demo_beat_2.mp3")
	assert_eq(m.tracks_started, 4)


func test_one_player_kept_across_screen_changes() -> void:
	var m: MusicPlayer = game.music
	var p := m.player
	game.start_run()
	assert_same(game.music, m)
	assert_same(m.player, p)
	game.show_garage()
	game.show_menu()
	assert_same(game.music, m)
	assert_same(m.player, p)
	assert_eq(m.tracks_started, 1, "never restarted")
	var players := 0
	for n in game.find_children("*", "AudioStreamPlayer", true, false):
		if n.get_parent() == m:
			players += 1
	assert_eq(players, 1)


func test_keeps_playing_without_restarting_through_menu_run_pause_menu() -> void:
	var m: MusicPlayer = game.music
	await get_tree().create_timer(0.4).timeout
	var pos := m.position_s()
	assert_gt(pos, 0.1, "playing from the main menu")
	game.start_run()
	await get_tree().create_timer(0.2).timeout
	var pos_run := m.position_s()
	assert_gt(pos_run, pos, "the run did not restart it")
	game.pause_screen.pause()
	assert_true(get_tree().paused)
	await get_tree().create_timer(0.3).timeout
	var pos_paused := m.position_s()
	assert_true(m.player.playing, "pausing does not stop it")
	assert_gt(pos_paused, pos_run, "still advancing while paused")
	game.pause_screen.resume()
	game.show_menu()
	await get_tree().create_timer(0.2).timeout
	assert_gt(m.position_s(), pos_paused, "back at the menu, still the same playback")
	assert_eq(m.tracks_started, 1)


func test_music_setting_default_range_save_and_load() -> void:
	assert_eq(GameSettings.load_music_volume(), GameSettings.DEFAULT_MUSIC_VOLUME)
	assert_true(GameSettings.save_music_volume(65.0))
	assert_eq(GameSettings.load_music_volume(), 65.0)
	GameSettings.save_music_volume(500.0)
	assert_eq(GameSettings.load_music_volume(), 100.0)
	GameSettings.save_music_volume(-5.0)
	assert_eq(GameSettings.load_music_volume(), 0.0)


func test_music_setting_does_not_touch_the_sfx_volume() -> void:
	GameSettings.save_sfx_volume(30.0)
	GameSettings.save_music_volume(80.0)
	assert_eq(GameSettings.load_sfx_volume(), 30.0)
	assert_eq(GameSettings.load_music_volume(), 80.0)


func test_music_bus_is_separate_and_moves_only_the_music() -> void:
	GameSettings.apply_sfx_volume(100.0)
	var sfx := AudioServer.get_bus_index(GameSettings.SFX_BUS)
	var music := AudioServer.get_bus_index(GameSettings.MUSIC_BUS)
	assert_ne(music, sfx)
	assert_eq(game.music.player.bus, GameSettings.MUSIC_BUS)
	var sfx_db := AudioServer.get_bus_volume_db(sfx)
	GameSettings.apply_music_volume(50.0)
	assert_almost_eq(db_to_linear(AudioServer.get_bus_volume_db(music)), 0.5, 0.01)
	assert_false(AudioServer.is_bus_mute(music))
	GameSettings.apply_music_volume(0.0)
	assert_true(AudioServer.is_bus_mute(music))
	assert_eq(AudioServer.get_bus_volume_db(sfx), sfx_db, "SFX untouched")
	assert_false(AudioServer.is_bus_mute(sfx))
	GameSettings.apply_sfx_volume(0.0)
	GameSettings.apply_music_volume(70.0)
	assert_false(AudioServer.is_bus_mute(music), "muting the SFX leaves the music")


func test_the_saved_volume_is_applied_at_launch() -> void:
	GameSettings.save_music_volume(25.0)
	var g := GameScene.instantiate()
	add_child_autofree(g)
	var i := AudioServer.get_bus_index(GameSettings.MUSIC_BUS)
	assert_almost_eq(db_to_linear(AudioServer.get_bus_volume_db(i)), 0.25, 0.01)
	GameSettings.apply_sfx_volume(0.0)
