extends GutTest
## Task T-427: the pause screen's sliders (zoom, SFX volume, music volume) apply their value live
## and write the settings file once, when the drag ends, plus once when the screen closes.

const RunScene := preload("res://scenes/run/run.tscn")
var TEST_PATH := RunPaths.file("test_settings_t427.cfg")


func before_each() -> void:
	GameSettings.sfx_enabled_override = 1
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	GameSettings.slider_writes = 0


func after_each() -> void:
	GameSettings.sfx_enabled_override = -1
	get_tree().paused = false
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()
	GameSettings.apply_sfx_volume(GameSettings.load_sfx_volume())
	GameSettings.apply_music_volume(GameSettings.load_music_volume())


func _screen() -> CanvasLayer:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var screen: CanvasLayer = preload("res://scripts/ui/pause_screen.gd").new()
	run.add_child(screen)
	screen.setup(run)
	GameSettings.slider_writes = 0  # building the screen is not a drag
	return screen


func _heard(bus_name: String) -> float:
	var i := AudioServer.get_bus_index(bus_name)
	return 0.0 if AudioServer.is_bus_mute(i) else db_to_linear(AudioServer.get_bus_volume_db(i))


## 20 values from the slider's low end towards its high end, none equal to the start value.
func _values(sl: HSlider) -> Array:
	var out: Array = []
	var span := sl.max_value - sl.min_value
	for i in 20:
		out.append(sl.min_value + span * (float(i) + 1.0) / 21.0)
	return out


func _drag(sl: HSlider, check: Callable = Callable()) -> void:
	sl.drag_started.emit()
	for v in _values(sl):
		sl.value = v
		if check.is_valid():
			check.call(sl)
		assert_eq(GameSettings.slider_writes, 0, "no write during the drag")
	sl.drag_ended.emit(true)


func test_zoom_drag_writes_once_at_the_end_and_applies_live() -> void:
	var screen := _screen()
	var run: Node = screen.target
	_drag(screen.zoom_slider, func(sl: HSlider):
		assert_almost_eq(run.zoom, sl.value, 1e-6, "zoom applied live"))
	assert_eq(GameSettings.slider_writes, 1, "one write for the drag")
	assert_almost_eq(GameSettings.load_zoom(), screen.zoom_slider.value, 1e-6)


func test_sfx_drag_writes_once_at_the_end_and_applies_live() -> void:
	var screen := _screen()
	_drag(screen.sfx_slider, func(sl: HSlider):
		assert_almost_eq(_heard(GameSettings.SFX_BUS), sl.value / 100.0, 0.001, "bus follows"))
	assert_eq(GameSettings.slider_writes, 1)
	assert_eq(GameSettings.load_sfx_volume(), screen.sfx_slider.value)


func test_music_drag_writes_once_at_the_end_and_applies_live() -> void:
	var screen := _screen()
	_drag(screen.music_slider, func(sl: HSlider):
		assert_almost_eq(_heard(GameSettings.MUSIC_BUS), sl.value / 100.0, 0.001, "bus follows"))
	assert_eq(GameSettings.slider_writes, 1)
	assert_eq(GameSettings.load_music_volume(), screen.music_slider.value)


func test_a_drag_that_changed_nothing_does_not_write() -> void:
	var screen := _screen()
	screen.music_slider.drag_started.emit()
	screen.music_slider.drag_ended.emit(false)
	assert_eq(GameSettings.slider_writes, 0)


func test_a_saved_drag_is_not_saved_again_when_the_screen_closes() -> void:
	var screen := _screen()
	_drag(screen.music_slider)
	screen.pause()
	screen.resume()
	assert_eq(GameSettings.slider_writes, 1, "nothing left to save on close")


func test_escape_closing_saves_a_change_made_without_a_drag() -> void:
	var screen := _screen()
	screen.pause()
	screen.zoom_slider.value = 9.0
	screen.sfx_slider.value = 35.0
	screen.music_slider.value = 77.0  # keyboard or click: no drag_ended
	assert_eq(GameSettings.slider_writes, 0)
	var press := InputEventAction.new()
	press.action = "pause"
	press.pressed = true
	screen._input(press)  # Escape
	assert_false(screen.visible)
	assert_eq(GameSettings.load_zoom(), 9.0)
	assert_eq(GameSettings.load_sfx_volume(), 35.0)
	assert_eq(GameSettings.load_music_volume(), 77.0)
	assert_eq(GameSettings.slider_writes, 3, "one write per changed slider")


func test_restart_saves_the_sliders() -> void:
	var screen := _screen()
	screen.pause()
	screen.music_slider.value = 12.0
	screen.zoom_slider.value = 7.0
	screen.restart_button.pressed.emit()
	assert_eq(GameSettings.load_music_volume(), 12.0)
	assert_eq(GameSettings.load_zoom(), 7.0)


func test_exit_saves_the_sliders() -> void:
	var screen := _screen()
	screen.pause()
	screen.sfx_slider.value = 64.0
	screen.exit_button.pressed.emit()
	assert_eq(GameSettings.load_sfx_volume(), 64.0)
