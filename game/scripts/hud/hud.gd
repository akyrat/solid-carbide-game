class_name Hud
extends CanvasLayer
## The run's HUD (task T-090). For now it shows only the run timer; the rest
## of the HUD (T-049) is added to this scene. The HUD only shows values: the
## run state owns the time (`time_left_changed`, `time_left_text()`).

const TIMER_FONT_SIZE := 56
const TIMER_COLOR := Color(0.3, 0.9, 1.0)

var timer_label: Label
var _state: RunState


func _ready() -> void:
	layer = 10
	timer_label = Label.new()
	timer_label.name = "Timer"
	timer_label.text = "8:00"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", TIMER_FONT_SIZE)
	timer_label.add_theme_color_override("font_color", TIMER_COLOR)
	timer_label.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.06))
	timer_label.add_theme_constant_override("outline_size", 12)
	timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	timer_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	timer_label.offset_top = 12
	add_child(timer_label)


## Shows the given run state's time, and follows it from now on.
func bind(state: RunState) -> void:
	if _state != null and _state.time_left_changed.is_connected(_on_time_left_changed):
		_state.time_left_changed.disconnect(_on_time_left_changed)
	_state = state
	_state.time_left_changed.connect(_on_time_left_changed)
	timer_label.text = _state.time_left_text()


func _on_time_left_changed(_seconds_left: float) -> void:
	timer_label.text = _state.time_left_text()
