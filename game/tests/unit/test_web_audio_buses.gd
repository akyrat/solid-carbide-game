extends GutTest
## Task T-476: the browser build was silent because the SFX and Music buses were added while
## the game ran, and Godot's web "sample" playback does not route a bus added at runtime to
## the Master bus. They now exist from the start, in res://default_bus_layout.tres.


func test_layout_has_sfx_and_music_buses_sending_to_master() -> void:
	var layout := load("res://default_bus_layout.tres") as AudioBusLayout
	assert_not_null(layout, "default_bus_layout.tres loads as an AudioBusLayout")
	var text := FileAccess.get_file_as_string("res://default_bus_layout.tres")
	for bus_name in [GameSettings.SFX_BUS, GameSettings.MUSIC_BUS]:
		assert_true(text.contains('&"%s"' % bus_name), "%s bus is in the layout" % bus_name)
	assert_eq(text.count('/send = &"Master"'), 2, "both send to Master")


func test_buses_exist_at_start_with_master_first() -> void:
	assert_eq(AudioServer.get_bus_name(0), "Master")
	assert_gt(AudioServer.get_bus_index(GameSettings.SFX_BUS), 0)
	assert_gt(AudioServer.get_bus_index(GameSettings.MUSIC_BUS), 0)
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(GameSettings.MUSIC_BUS)), &"Master")


func test_ensure_bus_reuses_the_layout_bus() -> void:
	var count := AudioServer.bus_count
	GameSettings.ensure_sfx_bus()
	GameSettings.ensure_music_bus()
	assert_eq(AudioServer.bus_count, count, "no extra bus is added at runtime")


func test_web_audio_log_line() -> void:
	assert_eq(WebAudioLog.line("music playing=true"), "[audio] music playing=true")
