extends GutTest
## Task T-431: the pause screen's HUD size slider. Laid out like the other sliders, its label
## read from data/pause_text.json (T-426's text); moving it scales the HUD at once while paused,
## it saves to GameSettings only when the drag ends (T-427's rule) and the saved value is
## applied at the next start.

const RunScene := preload("res://scenes/run/run.tscn")
const PauseScript := preload("res://scripts/ui/pause_screen.gd")
var TEST_PATH := RunPaths.file("test_settings_t431_slider.cfg")


func before_each() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	GameSettings.slider_writes = 0


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()


func _screen() -> CanvasLayer:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var screen: CanvasLayer = PauseScript.new()
	run.add_child(screen)
	screen.setup(run)
	GameSettings.slider_writes = 0  # building the screen is not a drag
	return screen


func _file_label() -> String:
	var f := FileAccess.open("res://data/pause_text.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	return data["hud_size_label"]


func test_label_is_the_files_text() -> void:
	var screen := _screen()
	assert_ne(_file_label(), "", "the file has the label")
	assert_eq(screen.hud_size_label.text, _file_label(), "the label is pause_text.json's")


func test_no_literal_of_the_label_in_the_scripts() -> void:
	var label := _file_label()
	var found: Array = []
	var stack: Array = ["res://scripts"]
	while not stack.is_empty():
		var dir: String = stack.pop_back()
		for sub in DirAccess.get_directories_at(dir):
			stack.append(dir + "/" + sub)
		for file in DirAccess.get_files_at(dir):
			if file.ends_with(".gd"):
				var text := FileAccess.get_file_as_string(dir + "/" + file)
				if text.contains("\"%s\"" % label) or text.contains("'%s'" % label):
					found.append(dir + "/" + file)
	assert_eq(found, [], "no script spells the label out")


func test_laid_out_like_the_other_sliders() -> void:
	var screen := _screen()
	var row: HBoxContainer = screen.hud_size_slider.get_parent()
	var music_row: HBoxContainer = screen.music_slider.get_parent()
	assert_eq(row.name, "HudSizeRow")
	assert_eq(row.get_parent(), music_row.get_parent(), "in the same column as the other sliders")
	assert_eq(row.get_index(), music_row.get_index() + 1, "directly under the music row")
	assert_eq(row.get_child_count(), music_row.get_child_count(), "label, slider, value")
	assert_eq(screen.hud_size_label.custom_minimum_size.x, screen.music_label.custom_minimum_size.x,
		"same label width, so the sliders line up")
	assert_eq(row.get_child(0), screen.hud_size_label, "label at the left")
	assert_eq(row.get_child(1), screen.hud_size_slider, "slider in the middle")
	var value: Label = row.get_child(2)
	assert_eq(value.horizontal_alignment, HORIZONTAL_ALIGNMENT_RIGHT, "value at the right end")
	assert_eq(value.text, "100", "a bare number")
	assert_eq(screen.hud_size_slider.min_value, GameSettings.MIN_HUD_SIZE)
	assert_eq(screen.hud_size_slider.max_value, GameSettings.MAX_HUD_SIZE)
	assert_eq(screen.hud_size_slider.value, GameSettings.DEFAULT_HUD_SIZE, "starts at the default")


func test_moving_it_scales_the_hud_at_once_while_paused() -> void:
	var screen := _screen()
	var run: Node = screen.target
	screen.pause()
	assert_true(get_tree().paused, "paused")
	var before: float = run.hud.hud_scale()
	screen.hud_size_slider.value = GameSettings.MAX_HUD_SIZE
	assert_almost_eq(run.hud.hud_scale(), before * GameSettings.MAX_HUD_SIZE / 100.0, 1e-5,
		"bigger at once, no frame needed")
	screen.hud_size_slider.value = GameSettings.MIN_HUD_SIZE
	assert_almost_eq(run.hud.hud_scale(), before * GameSettings.MIN_HUD_SIZE / 100.0, 1e-5,
		"smaller at once")
	screen.resume()


func test_saves_only_when_the_drag_ends() -> void:
	var screen := _screen()
	var sl: HSlider = screen.hud_size_slider
	sl.drag_started.emit()
	for v in [55.0, 70.0, 90.0, 110.0, 120.0]:
		sl.value = v
		assert_eq(GameSettings.slider_writes, 0, "no write during the drag")
		assert_eq(GameSettings.load_hud_size(), GameSettings.DEFAULT_HUD_SIZE, "nothing saved yet")
	sl.drag_ended.emit(true)
	assert_eq(GameSettings.slider_writes, 1, "one write when the drag ends")
	assert_eq(GameSettings.load_hud_size(), 120.0, "the value saved")


func test_a_click_change_is_saved_on_close() -> void:
	var screen := _screen()
	screen.pause()
	screen.hud_size_slider.value = 80.0
	assert_eq(GameSettings.slider_writes, 0)
	screen.resume()
	assert_eq(GameSettings.slider_writes, 1, "saved when the screen closes")
	assert_eq(GameSettings.load_hud_size(), 80.0)


func test_the_saved_value_applies_at_the_next_start() -> void:
	GameSettings.save_hud_size(75.0)
	var holder := Node.new()
	add_child_autofree(holder)
	var run: Node2D = GameFlow.add_run(holder, PlayerProgress.new())
	assert_eq(run.hud.hud_size, 75.0, "the HUD starts at the saved size")
	var view: Vector2 = run.hud.get_viewport().get_visible_rect().size
	assert_almost_eq(run.hud.hud_scale(), Hud.scale_for(view, 75.0), 1e-5, "and is drawn at it")
	var screen: CanvasLayer = run.get_node("PauseScreenLayer")
	assert_eq(screen.hud_size_slider.value, 75.0, "the slider starts there too")


func test_settings_round_trip_and_clamp() -> void:
	assert_eq(GameSettings.load_hud_size(), GameSettings.DEFAULT_HUD_SIZE, "default with no file")
	GameSettings.save_hud_size(500.0)
	assert_eq(GameSettings.load_hud_size(), GameSettings.MAX_HUD_SIZE, "clamped to the top")
	GameSettings.save_hud_size(1.0)
	assert_eq(GameSettings.load_hud_size(), GameSettings.MIN_HUD_SIZE, "clamped to the bottom")
