class_name Hud
extends CanvasLayer
## The run's HUD (tasks T-090 and T-049): the timer at the top centre, the
## car's health bar, the likes bar with the heart and the level at the top
## left, and the coins at the top right. The HUD only shows values: the run
## state owns them (`time_left_changed`, `health_changed`, `xp_changed`,
## `coins_changed`). The texts are from T-048.

const TIMER_FONT_SIZE := 56
const TIMER_COLOR := Color(0.3, 0.9, 1.0)
const LABEL_FONT_SIZE := 20
const LABEL_COLOR := Color(0.92, 0.95, 1.0)
const OUTLINE_COLOR := Color(0.03, 0.03, 0.06)
const MARGIN := 16
const BAR_SIZE := Vector2(240, 22)
const HEALTH_COLOR := Color(0.25, 0.85, 0.45)
const LIKES_COLOR := Color(0.7, 0.45, 1.0)
const COINS_COLOR := Color(1.0, 0.82, 0.25)
## Redgull red: used only by the heart (a placeholder shape until T-086).
const HEART_COLOR := Color(0.86, 0.1, 0.16)
const HEART_SIZE := 26.0

# Text from T-048 (hud.health, hud.likes, hud.level, hud.coins).
const TEXT_HEALTH := "Car Health"
const TEXT_LIKES := "Likes"
const TEXT_LEVEL := "Hype Lv {level}"
const TEXT_COINS := "Coins"
# Text from T-082 (combo.label); {multiplier} is the current multiplier, e.g. "2.5".
const TEXT_COMBO := "Combo x{multiplier}"
## Combo counter placeholder look (not red: only the heart is). T-084 is the final art.
const COMBO_FONT_SIZE := 30
const COMBO_COLOR := Color(1.0, 0.25, 0.75)
const COMBO_GAP := 20

var timer_label: Label
var health_label: Label
var health_bar: ProgressBar
var likes_label: Label
var likes_bar: ProgressBar
var level_label: Label
var coins_label: Label
var coins_value_label: Label
var heart: Control
## The combo counter (T-083), to the right of the likes row.
var combo_label: Label
## The left column; the combo counter (T-083) goes next to the likes bar.
var left_column: VBoxContainer
var likes_row: HBoxContainer
var _state: RunState


func _ready() -> void:
	layer = 10
	_build_timer()
	_build_left()
	_build_coins()
	_build_combo()


func _build_timer() -> void:
	timer_label = Label.new()
	timer_label.name = "Timer"
	timer_label.text = "8:00"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", TIMER_FONT_SIZE)
	timer_label.add_theme_color_override("font_color", TIMER_COLOR)
	timer_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	timer_label.add_theme_constant_override("outline_size", 12)
	timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	timer_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	timer_label.offset_top = 12
	add_child(timer_label)


func _build_left() -> void:
	left_column = VBoxContainer.new()
	left_column.name = "Left"
	left_column.add_theme_constant_override("separation", 6)
	left_column.position = Vector2(MARGIN, MARGIN)
	add_child(left_column)

	health_label = _make_label("HealthLabel", TEXT_HEALTH)
	left_column.add_child(health_label)
	health_bar = _make_bar("HealthBar", HEALTH_COLOR)
	left_column.add_child(health_bar)

	likes_row = HBoxContainer.new()
	likes_row.name = "LikesRow"
	likes_row.add_theme_constant_override("separation", 8)
	likes_row.custom_minimum_size.x = BAR_SIZE.x
	left_column.add_child(likes_row)
	heart = Control.new()
	heart.name = "Heart"
	heart.custom_minimum_size = Vector2(HEART_SIZE, HEART_SIZE)
	var shape := Polygon2D.new()
	shape.polygon = _heart_points(HEART_SIZE)
	shape.color = HEART_COLOR
	heart.add_child(shape)
	likes_row.add_child(heart)
	likes_label = _make_label("LikesLabel", TEXT_LIKES)
	likes_row.add_child(likes_label)
	level_label = _make_label("LevelLabel", TEXT_LEVEL.format({"level": 1}))
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	likes_row.add_child(level_label)
	likes_bar = _make_bar("LikesBar", LIKES_COLOR)
	left_column.add_child(likes_bar)


func _build_coins() -> void:
	var box := HBoxContainer.new()
	box.name = "Coins"
	box.add_theme_constant_override("separation", 10)
	box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.offset_top = MARGIN
	box.offset_right = -MARGIN
	add_child(box)
	coins_label = _make_label("CoinsLabel", TEXT_COINS)
	coins_label.add_theme_color_override("font_color", COINS_COLOR)
	box.add_child(coins_label)
	coins_value_label = _make_label("CoinsValue", "0")
	coins_value_label.add_theme_color_override("font_color", COINS_COLOR)
	box.add_child(coins_value_label)


func _build_combo() -> void:
	combo_label = _make_label("ComboLabel", combo_text(1.0))
	combo_label.add_theme_font_size_override("font_size", COMBO_FONT_SIZE)
	combo_label.add_theme_color_override("font_color", COMBO_COLOR)
	combo_label.add_theme_constant_override("outline_size", 10)
	add_child(combo_label)
	_place_combo()
	likes_row.resized.connect(_place_combo)
	combo_label.resized.connect(_place_combo)


## Puts the counter right of the likes row, centred on the row's height.
func _place_combo() -> void:
	var row_rect := likes_row.get_global_rect()
	combo_label.position = Vector2(
		row_rect.end.x + COMBO_GAP,
		row_rect.position.y + (row_rect.size.y - combo_label.size.y) / 2.0)


## "Combo x2.5": the multiplier without trailing zeros.
static func combo_text(multiplier: float) -> String:
	return TEXT_COMBO.format({"multiplier": String.num(multiplier, 2)})


func _make_label(label_name: String, text: String) -> Label:
	var l := Label.new()
	l.name = label_name
	l.text = text
	l.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	l.add_theme_color_override("font_color", LABEL_COLOR)
	l.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	l.add_theme_constant_override("outline_size", 6)
	return l


func _make_bar(bar_name: String, fill: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.name = bar_name
	b.custom_minimum_size = BAR_SIZE
	b.show_percentage = false
	b.min_value = 0.0
	b.max_value = 1.0
	b.value = 0.0
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.05, 0.06, 0.12, 0.85)
	back.set_border_width_all(2)
	back.border_color = Color(0.3, 0.9, 1.0, 0.8)
	var front := StyleBoxFlat.new()
	front.bg_color = fill
	b.add_theme_stylebox_override("background", back)
	b.add_theme_stylebox_override("fill", front)
	return b


static func _heart_points(size: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 40
	for i in steps:
		var t := TAU * i / steps
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(Vector2(x, y) * (size / 34.0) + Vector2(size / 2.0, size / 2.0 + 1.0))
	return pts


## Shows the given run state's values, and follows them from now on.
func bind(state: RunState) -> void:
	if _state != null:
		_state.time_left_changed.disconnect(_on_time_left_changed)
		_state.health_changed.disconnect(_on_health_changed)
		_state.xp_changed.disconnect(_on_xp_changed)
		_state.coins_changed.disconnect(_on_coins_changed)
		_state.combo_changed.disconnect(_on_combo_changed)
	_state = state
	_state.time_left_changed.connect(_on_time_left_changed)
	_state.health_changed.connect(_on_health_changed)
	_state.xp_changed.connect(_on_xp_changed)
	_state.coins_changed.connect(_on_coins_changed)
	_state.combo_changed.connect(_on_combo_changed)
	timer_label.text = _state.time_left_text()
	_on_health_changed(_state.health, _state.max_health)
	_on_xp_changed(_state.xp, _state.xp_needed(), _state.level)
	_on_coins_changed(_state.coins)
	_on_combo_changed(_state.combo)


func _on_time_left_changed(_seconds_left: float) -> void:
	timer_label.text = _state.time_left_text()


func _on_health_changed(health: float, max_health: float) -> void:
	health_bar.max_value = maxf(max_health, 1.0)
	health_bar.value = health


func _on_xp_changed(xp: float, xp_needed: float, level: int) -> void:
	# At the top level xp_needed is 0: the bar stays full.
	if xp_needed > 0.0:
		likes_bar.max_value = xp_needed
		likes_bar.value = xp
	else:
		likes_bar.max_value = 1.0
		likes_bar.value = 1.0
	level_label.text = TEXT_LEVEL.format({"level": level})


func _on_coins_changed(coins: int) -> void:
	coins_value_label.text = str(coins)


func _on_combo_changed(multiplier: float) -> void:
	combo_label.text = combo_text(multiplier)
