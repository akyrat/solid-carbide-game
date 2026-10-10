extends CanvasLayer
## The pause screen (task T-015): a title, a hint that Escape resumes and one
## setting, the camera zoom slider. Escape (the "pause" action) pauses and
## resumes. It only shows the screen and collects input; the zoom itself is set
## by the scene it belongs to (set_zoom) and saved by GameSettings.
## Texts are from task T-047.

const GameSettingsScript := preload("res://scripts/ui/game_settings.gd")

const ACTION_PAUSE := "pause"
const TEXT_TITLE := "Paused"
const TEXT_HINT := "Press Escape to get back to the stream."
const TEXT_ZOOM_LABEL := "Camera zoom, for the fans"

## The scene whose camera zoom this slider sets (needs `zoom` and set_zoom()).
var target: Node
var zoom_slider: HSlider
var title_label: Label
var hint_label: Label
var zoom_label: Label
var _value_label: Label
var _root: Control


func setup(t: Node) -> void:
	target = t
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "PauseScreen"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 420.0
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	title_label = Label.new()
	title_label.text = TEXT_TITLE
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	box.add_child(title_label)
	hint_label = Label.new()
	hint_label.text = TEXT_HINT
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 18)
	box.add_child(hint_label)
	zoom_label = Label.new()
	zoom_label.text = TEXT_ZOOM_LABEL
	zoom_label.add_theme_font_size_override("font_size", 16)
	box.add_child(zoom_label)
	var row := HBoxContainer.new()
	box.add_child(row)
	zoom_slider = HSlider.new()
	zoom_slider.name = "ZoomSlider"
	zoom_slider.min_value = GameSettingsScript.MIN_ZOOM
	zoom_slider.max_value = GameSettingsScript.MAX_ZOOM
	zoom_slider.step = 0.1
	zoom_slider.value = target.zoom
	zoom_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zoom_slider.focus_mode = Control.FOCUS_NONE
	zoom_slider.value_changed.connect(_on_zoom_changed)
	row.add_child(zoom_slider)
	_value_label = Label.new()
	_value_label.custom_minimum_size.x = 50.0
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_value_label)
	_update_value_label()
	visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_PAUSE):
		toggle()
		get_viewport().set_input_as_handled()


func is_paused() -> bool:
	return get_tree().paused


func toggle() -> void:
	if get_tree().paused:
		resume()
	else:
		pause()


func pause() -> void:
	zoom_slider.set_value_no_signal(target.zoom)
	_update_value_label()
	get_tree().paused = true
	visible = true


func resume() -> void:
	get_tree().paused = false
	visible = false


func _on_zoom_changed(v: float) -> void:
	target.set_zoom(v)
	GameSettingsScript.save_zoom(v)
	_update_value_label()
	if target.panel != null:
		target.panel.refresh()


func _update_value_label() -> void:
	_value_label.text = "%.1f" % zoom_slider.value


func _exit_tree() -> void:
	# Never leave the whole tree paused behind a removed screen.
	if get_tree() != null and get_tree().paused:
		get_tree().paused = false
