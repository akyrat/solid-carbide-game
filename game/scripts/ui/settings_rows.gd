class_name SettingsRows
extends RefCounted
## The settings' building blocks shared by the pause screen and the main menu's Settings screen
## (task T-571; HUD and menus, Decisions, "A Settings screen from the main menu"): one slider row
## (label, slider, bare value number), one checkbox, and the sliders' save rule (T-427). Both
## screens build their rows with these, so the two look and save alike.

## Width of the slider rows' labels, so every slider on a screen has the same width.
const LABEL_WIDTH := 170.0
## Width of the value number at the right end of a slider row.
const VALUE_WIDTH := 50.0
const CHECK_ICON_SIZE := 16


## A slider row added to `parent`: {row, label, slider, value}. The slider has no keyboard focus
## (like the pause screen's) and calls `on_change` with its value on every change; the value
## number is not set here (each screen formats its own).
static func slider_row(parent: Control, row_name: String, label_text: String, slider_name: String,
		min_value: float, max_value: float, step: float, value: float, on_change: Callable) -> Dictionary:
	var row := HBoxContainer.new()
	row.name = row_name
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	HudStyle.apply(label, "pause_text")
	label.custom_minimum_size.x = LABEL_WIDTH
	row.add_child(label)
	var slider := HSlider.new()
	slider.name = slider_name
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size.x = VALUE_WIDTH
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	return {"row": row, "label": label, "slider": slider, "value": value_label}


## A settings checkbox: the shared checkbox (T-446) in its small size.
static func check(node_name: String, text: String) -> CheckBox:
	var c := CheckBox.new()
	c.name = node_name
	c.text = text
	HudStyle.style_checkbox(c, CHECK_ICON_SIZE, true)
	return c


## The slider save rule (T-427): a slider applies its value live and only marks itself changed;
## it saves when the drag ends (drag_ended with value_changed true) and once more when the screen
## closes (save_pending), so a drag writes the settings file once, not once per value.
class SaveOnRelease:
	extends RefCounted
	## key -> the Callable that saves it.
	var _savers: Dictionary = {}
	## Keys changed since their last save.
	var dirty: Array = []

	## Saves `key` with `saver` when `slider`'s drag ends with a change.
	func wire(slider: HSlider, key: String, saver: Callable) -> void:
		_savers[key] = saver
		slider.drag_ended.connect(func(value_changed: bool):
			if value_changed:
				save(key))

	func mark(key: String) -> void:
		if not dirty.has(key):
			dirty.append(key)

	func save(key: String) -> void:
		dirty.erase(key)
		if _savers.has(key):
			_savers[key].call()

	## Saves every key changed since its last save.
	func save_pending() -> void:
		for key in dirty.duplicate():
			save(key)
