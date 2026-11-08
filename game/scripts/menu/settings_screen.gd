class_name SettingsScreen
extends Control
## The Settings screen opened from the main menu (task T-571; HUD and menus, Decisions, "A Settings
## screen from the main menu"): the pause screen's settings that make sense outside a run, the
## camera zoom, the SFX volume (only while the sound effects are switched on), the music volume,
## Camera smoothing, Dynamic camera, Rain, the Drift Guide and the jump arrow, plus a Back button.
## Left out (they need a run): HUD size, the HUD layout editor, the trick list, Restart and Exit,
## Set min/max zoom and God mode.
##
## The values are the pause screen's saved settings (GameSettings): read when the screen opens,
## saved like the pause screen's (sliders on release and on closing, T-427; checkboxes at once),
## and applied at the next run. The music volume is applied to the Music bus at once, so the
## menu's music follows the slider. The rows, their look and the save rule are SettingsRows',
## the same as the pause screen's; the labels are the pause screen's own texts.
## Back and Escape (the "pause" action) save what is pending and send back_pressed.

signal back_pressed

const PauseScreenScript := preload("res://scripts/ui/pause_screen.gd")
const TITLE_FONT := preload("res://fonts/press_start_2p/PressStart2P-Regular.ttf")
const TITLE_KEY := "settings_title"
const BACK_KEY := "settings_back"
## The settings panel's width, the pause strip's settings column (proposal for the playtest).
const PANEL_WIDTH := 620.0

var title_label: Label
var panel: PanelContainer
var zoom_slider: HSlider
var zoom_label: Label
var zoom_value_label: Label
var sfx_row: Control
var sfx_slider: HSlider
var sfx_value_label: Label
var music_slider: HSlider
var music_value_label: Label
var smoothing_check: CheckBox
var dynamic_check: CheckBox
var rain_check: CheckBox
var drift_guide_check: CheckBox
var jump_arrow_check: CheckBox
var trick_popups_check: CheckBox
var back_button: Button
var _saves := SettingsRows.SaveOnRelease.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiScale.keep(self)  # scales with the window like the other menus (T-494)

	var background := ColorRect.new()
	background.name = "Background"
	background.color = MainMenu.PLACEHOLDER_COLOR
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)

	title_label = Label.new()
	title_label.name = "Title"
	title_label.text = PauseScreenScript.pause_text(TITLE_KEY)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", TITLE_FONT)
	title_label.add_theme_font_size_override("font_size", 40)
	title_label.add_theme_color_override("font_color", MainMenu.TITLE_COLOR)
	title_label.add_theme_color_override("font_outline_color", MainMenu.OUTLINE_COLOR)
	title_label.add_theme_constant_override("outline_size", 8)
	title_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.add_child(title_label)

	# The settings sit on a panel in the pause strip's look.
	panel = PanelContainer.new()
	panel.name = "SettingsPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = HudStyle.PAUSE_STRIP_COLOR
	style.set_content_margin_all(16.0)
	panel.add_theme_stylebox_override("panel", style)
	column.add_child(panel)
	var box := VBoxContainer.new()
	box.name = "Rows"
	box.custom_minimum_size.x = PANEL_WIDTH
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_build_sliders(box)
	_build_checks(box)

	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = PauseScreenScript.pause_text(BACK_KEY)
	back_button.custom_minimum_size = Vector2(280, 56)
	HudStyle.style_button(back_button)  # the shared button, like the main menu's
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(go_back)
	column.add_child(back_button)
	_link_focus()


## A text from data/pause_text.json by its key (T-570's settings_button, settings_title,
## settings_back live there with the pause screen's labels); empty if missing.
static func text(key: String) -> String:
	return PauseScreenScript.pause_text(key)


func _build_sliders(box: VBoxContainer) -> void:
	var z := SettingsRows.slider_row(box, "ZoomRow", PauseScreenScript.TEXT_ZOOM_LABEL, "ZoomSlider",
		GameSettings.MIN_ZOOM, GameSettings.MAX_ZOOM, 0.1, GameSettings.load_zoom(), _on_zoom_changed)
	zoom_label = z.label
	zoom_slider = z.slider
	zoom_value_label = z.value
	_saves.wire(zoom_slider, "zoom", func(): GameSettings.save_zoom(zoom_slider.value))
	zoom_value_label.text = "%.1f" % zoom_slider.value

	var s := SettingsRows.slider_row(box, "SfxRow", PauseScreenScript.TEXT_SFX_LABEL, "SfxSlider",
		0.0, 100.0, 1.0, GameSettings.load_sfx_volume(), _on_sfx_changed)
	sfx_row = s.row
	sfx_row.visible = GameSettings.sfx_enabled()  # like the pause screen's row (T-389)
	sfx_slider = s.slider
	sfx_value_label = s.value
	_saves.wire(sfx_slider, "sfx", func(): GameSettings.save_sfx_volume(sfx_slider.value))
	sfx_value_label.text = "%d" % int(sfx_slider.value)

	var m := SettingsRows.slider_row(box, "MusicRow", PauseScreenScript.TEXT_MUSIC_LABEL, "MusicSlider",
		0.0, 100.0, 1.0, GameSettings.load_music_volume(), _on_music_changed)
	music_slider = m.slider
	music_value_label = m.value
	_saves.wire(music_slider, "music", func(): GameSettings.save_music_volume(music_slider.value))
	music_value_label.text = "%d" % int(music_slider.value)


func _build_checks(box: VBoxContainer) -> void:
	var checks := HBoxContainer.new()
	checks.name = "Checks"
	checks.alignment = BoxContainer.ALIGNMENT_CENTER
	checks.add_theme_constant_override("separation", 14)  # the pause screen's row
	box.add_child(checks)
	smoothing_check = _check(checks, "SmoothingCheck", PauseScreenScript.TEXT_SMOOTHING,
		GameSettings.load_camera_smoothing(), GameSettings.save_camera_smoothing)
	dynamic_check = _check(checks, "DynamicCheck", PauseScreenScript.TEXT_DYNAMIC,
		GameSettings.load_dynamic_camera(), GameSettings.save_dynamic_camera)
	rain_check = _check(checks, "RainCheck", PauseScreenScript.pause_text("rain_label"),
		GameSettings.load_rain_enabled(), GameSettings.save_rain_enabled)
	drift_guide_check = _check(checks, "DriftGuideCheck", PauseScreenScript.pause_text("drift_guide_label"),
		GameSettings.load_drift_guide_enabled(), GameSettings.save_drift_guide_enabled)
	jump_arrow_check = _check(checks, "JumpArrowCheck", PauseScreenScript.pause_text("jump_arrow_label"),
		GameSettings.load_jump_arrow_enabled(), GameSettings.save_jump_arrow_enabled)
	trick_popups_check = _check(checks, "TrickPopupsCheck", PauseScreenScript.pause_text("trick_popups_label"),
		GameSettings.load_trick_popups_enabled(), GameSettings.save_trick_popups_enabled)


## A checkbox showing the saved value; ticking it saves at once with `saver`.
func _check(parent: Control, node_name: String, text: String, on: bool, saver: Callable) -> CheckBox:
	var c := SettingsRows.check(node_name, text)
	c.set_pressed_no_signal(on)
	c.toggled.connect(func(pressed: bool): saver.call(pressed))
	parent.add_child(c)
	return c


## Keyboard order: Left and Right walk the checkboxes, Down from any of them goes to Back, Up from
## Back to the first checkbox. The sliders take no focus, like the pause screen's.
func _link_focus() -> void:
	var checks := checkboxes()
	var n := checks.size()
	for i in n:
		var c: CheckBox = checks[i]
		c.focus_neighbor_left = c.get_path_to(checks[(i - 1 + n) % n])
		c.focus_neighbor_right = c.get_path_to(checks[(i + 1) % n])
		c.focus_neighbor_bottom = c.get_path_to(back_button)
		c.focus_neighbor_top = c.get_path_to(back_button)
		c.focus_next = c.get_path_to(checks[i + 1] if i + 1 < n else back_button)
		c.focus_previous = c.get_path_to(checks[i - 1] if i > 0 else back_button)
	back_button.focus_neighbor_top = back_button.get_path_to(checks[0])
	back_button.focus_neighbor_bottom = back_button.get_path_to(checks[0])
	back_button.focus_next = back_button.get_path_to(checks[0])
	back_button.focus_previous = back_button.get_path_to(checks[n - 1])


## The six checkboxes, left to right.
func checkboxes() -> Array:
	return [smoothing_check, dynamic_check, rain_check, drift_guide_check, jump_arrow_check, trick_popups_check]


func _on_zoom_changed(v: float) -> void:
	_saves.mark("zoom")  # no camera here: the next run reads the saved zoom
	zoom_value_label.text = "%.1f" % v


func _on_sfx_changed(v: float) -> void:
	_saves.mark("sfx")
	GameSettings.apply_sfx_volume(v)
	sfx_value_label.text = "%d" % int(v)


func _on_music_changed(v: float) -> void:
	_saves.mark("music")
	GameSettings.apply_music_volume(v)  # the menu's music follows at once
	music_value_label.text = "%d" % int(v)


## Saves every slider changed since its last save (Back and Escape call it).
func save_pending() -> void:
	_saves.save_pending()


## Back and Escape: saves what is pending, then back to the main menu.
func go_back() -> void:
	save_pending()
	back_pressed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(PauseScreenScript.ACTION_PAUSE):
		get_viewport().set_input_as_handled()
		go_back()


## W, A, S, D move the selection like the arrow keys (T-492). T-573: nothing is selected on opening;
## the first arrow or Tab selects Back.
func _unhandled_key_input(event: InputEvent) -> void:
	KeyNav.handle_keys(event, self, back_button)
