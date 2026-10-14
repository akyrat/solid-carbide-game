class_name Hud
extends CanvasLayer
## The run's HUD (tasks T-090, T-049 and T-113): the timer at the top centre,
## the car's health bar upright at the top left under "Car Health", the coins
## at the top right, and the likes bar lying across the bottom centre with the
## likes row (heart, "Likes", "Hype Lv") and the combo counter above it
## (hidden at no combo, T-116). The HUD only shows values: the run
## state owns them (`time_left_changed`, `health_changed`, `xp_changed`,
## `coins_changed`). The texts are from T-048. Since T-131 the combo counter,
## "Likes" and "Hype Lv" are in the comic font (Bangers, hard pixel edges),
## and the counter heats up in steps as the combo climbs (ComboHeat), with
## the likes bar on fire at the top step (LikesFire).

const TIMER_FONT_SIZE := 56
const TIMER_COLOR := Color(0.3, 0.9, 1.0)
const LABEL_FONT_SIZE := 20
const LABEL_COLOR := Color(0.92, 0.95, 1.0)
const OUTLINE_COLOR := Color(0.03, 0.03, 0.06)
const MARGIN := 16
## The health bar (T-113): upright, filling from the bottom up.
const HEALTH_BAR_SIZE := Vector2(24, 160)
## The likes bar (T-113): horizontal, this share of the screen's width.
const LIKES_BAR_WIDTH := 0.5
const LIKES_BAR_HEIGHT := 16.0
## Space between a bar and the text line next to it.
const LABEL_GAP := 6
const HEALTH_COLOR := Color(0.25, 0.85, 0.45)
const LIKES_COLOR := Color(0.7, 0.45, 1.0)
const COINS_COLOR := Color(1.0, 0.82, 0.25)
## Redgull red: used only by the heart (its art, T-086, is drawn in this red).
const HEART_COLOR := Color(0.86, 0.1, 0.16)
## The heart's art (T-086, drawn by tools/build_heart_icon.py): 11 x 10 art
## pixels shown at 2x, about the height of "Likes" with its outline.
const HEART_PATH := "res://art/hud/likes_heart.png"
const HEART_SCALE := 2

# Text from T-048 (hud.health, hud.likes, hud.level, hud.coins).
const TEXT_HEALTH := "Car Health"
const TEXT_LIKES := "Likes"
const TEXT_LEVEL := "Hype Lv {level}"
const TEXT_COINS := "Coins"
# Text from T-082 (combo.label); {multiplier} is the current multiplier, e.g. "2.5".
const TEXT_COMBO := "Combo x{multiplier}"
## Combo counter base look (not red: only the heart is); the hotter steps are
## in ComboHeat.STEPS (T-131).
const COMBO_FONT_SIZE := 30
const COMBO_COLOR := Color(1.0, 0.25, 0.75)
## The comic font of the trick popups (T-084), used since T-131 by the combo
## counter, "Likes" and "Hype Lv". It has capitals only.
const COMIC_FONT_PATH := "res://fonts/bangers/Bangers-Regular.ttf"
## Space between the combo counter and the likes row under it.
const COMBO_GAP := 4

var timer_label: Label
var health_label: Label
var health_bar: ProgressBar
var likes_label: Label
var likes_bar: ProgressBar
var level_label: Label
var coins_label: Label
var coins_value_label: Label
var heart: TextureRect
## The combo counter (T-083), centred above the likes row. Hidden at no
## combo (T-116): see show_combo().
var combo_label: Label
## The top-left area: "Car Health" and the health bar (T-113).
var left_column: Control
## A full-screen area holding the likes bar, its row and the combo counter.
var bottom_area: Control
## The heart and "Likes", at the left end of the row above the likes bar.
var likes_row: HBoxContainer
## The combo's heat steps (T-131): restyles combo_label, lights likes_fire.
var combo_heat: ComboHeat
## The flames along the likes bar at the top heat step (T-131).
var likes_fire: LikesFire
var _state: RunState
static var _comic_font: FontFile = null
## The combo's numbers (combo.json): its start value is "no combo" (T-116).
var _combo_data: ComboData


func _ready() -> void:
	layer = 10
	_combo_data = ComboData.new()
	_build_timer()
	_build_left()
	_build_bottom()
	_build_coins()


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
	left_column = Control.new()
	left_column.name = "Left"
	left_column.position = Vector2(MARGIN, MARGIN)
	left_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left_column)
	health_label = _make_label("HealthLabel", TEXT_HEALTH)
	left_column.add_child(health_label)
	health_bar = _make_bar("HealthBar", HEALTH_COLOR, ProgressBar.FILL_BOTTOM_TO_TOP)
	left_column.add_child(health_bar)
	_layout_left()
	health_label.resized.connect(_layout_left)


## "Car Health" on one line, then the upright health bar directly under it,
## both starting at the same left edge.
func _layout_left() -> void:
	health_label.size = health_label.get_combined_minimum_size()
	health_label.position = Vector2.ZERO
	health_bar.size = HEALTH_BAR_SIZE
	health_bar.position = Vector2(0.0, health_label.size.y + LABEL_GAP)


func _build_bottom() -> void:
	bottom_area = Control.new()
	bottom_area.name = "Bottom"
	bottom_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bottom_area)
	likes_bar = _make_bar("LikesBar", LIKES_COLOR, ProgressBar.FILL_BEGIN_TO_END)
	bottom_area.add_child(likes_bar)
	# Over the bar, under the texts, so the texts stay on top of the flames.
	likes_fire = LikesFire.new()
	bottom_area.add_child(likes_fire)
	likes_bar.value_changed.connect(func(_v: float) -> void: _update_fire_fill())
	likes_row = HBoxContainer.new()
	likes_row.name = "LikesRow"
	likes_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	likes_row.add_theme_constant_override("separation", 6)
	bottom_area.add_child(likes_row)
	heart = _make_heart()
	likes_row.add_child(heart)
	likes_label = _make_label("LikesLabel", TEXT_LIKES)
	likes_label.add_theme_font_override("font", comic_font())
	# The row's full height, like "Hype Lv", so both share a baseline.
	likes_label.size_flags_vertical = Control.SIZE_FILL
	likes_row.add_child(likes_label)
	level_label = _make_label("LevelLabel", TEXT_LEVEL.format({"level": 1}))
	level_label.add_theme_font_override("font", comic_font())
	bottom_area.add_child(level_label)
	combo_label = _make_label("ComboLabel", combo_text(1.0))
	combo_label.add_theme_font_override("font", comic_font())
	combo_label.add_theme_font_size_override("font_size", COMBO_FONT_SIZE)
	combo_label.add_theme_color_override("font_color", COMBO_COLOR)
	combo_label.add_theme_constant_override("outline_size", 10)
	combo_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# A run starts with no combo: hidden until a trick raises it (T-116).
	combo_label.visible = false
	bottom_area.add_child(combo_label)
	combo_heat = ComboHeat.new()
	add_child(combo_heat)
	combo_heat.setup(combo_label, likes_fire)
	_layout_bottom()
	for c: Control in [bottom_area, likes_row, level_label, combo_label]:
		c.resized.connect(_layout_bottom)


## The likes bar centred at the bottom, half the screen wide; the likes row
## directly above it (heart and "Likes" from its left edge, "Hype Lv" ending
## at its right edge, both labels on the same line); the combo counter
## centred above the row.
func _layout_bottom() -> void:
	var view := bottom_area.size
	var bar_w := roundf(view.x * LIKES_BAR_WIDTH)
	likes_bar.size = Vector2(bar_w, LIKES_BAR_HEIGHT)
	likes_bar.position = Vector2(
		roundf((view.x - bar_w) / 2.0), view.y - MARGIN - LIKES_BAR_HEIGHT)
	var row_h := maxf(likes_row.get_combined_minimum_size().y,
		level_label.get_combined_minimum_size().y)
	var row_y := likes_bar.position.y - LABEL_GAP - row_h
	likes_row.size = Vector2(likes_row.get_combined_minimum_size().x, row_h)
	likes_row.position = Vector2(likes_bar.position.x, row_y)
	level_label.size = Vector2(level_label.get_combined_minimum_size().x, row_h)
	level_label.position = Vector2(likes_bar.position.x + bar_w - level_label.size.x, row_y)
	combo_label.size = combo_label.get_combined_minimum_size()
	combo_label.position = Vector2(
		roundf(likes_bar.position.x + (bar_w - combo_label.size.x) / 2.0),
		row_y - COMBO_GAP - combo_label.size.y)
	# The heat's pulse grows the counter from its bottom centre: up and to
	# both sides, never down into the row, and it stays centred (T-131).
	combo_label.pivot_offset = Vector2(combo_label.size.x / 2.0, combo_label.size.y)
	likes_fire.place(likes_bar.get_rect())
	var spans: Array[Vector2] = []
	for l: Control in [likes_row, level_label]:
		spans.append(Vector2(l.position.x - likes_bar.position.x,
			l.position.x + l.size.x - likes_bar.position.x))
	likes_fire.low_spans = spans
	_update_fire_fill()


func _update_fire_fill() -> void:
	var span := likes_bar.max_value - likes_bar.min_value
	likes_fire.fill_ratio = (likes_bar.value - likes_bar.min_value) / span if span > 0.0 else 0.0


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


## The comic font (Bangers) with smoothing off: hard pixel edges (T-131).
static func comic_font() -> FontFile:
	if _comic_font == null:
		_comic_font = (load(COMIC_FONT_PATH) as FontFile).duplicate()
		_comic_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_comic_font.hinting = TextServer.HINTING_NONE
		_comic_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		_comic_font.generate_mipmaps = false
	return _comic_font


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


func _make_bar(bar_name: String, fill: Color, fill_mode: int) -> ProgressBar:
	var b := ProgressBar.new()
	b.name = bar_name
	b.fill_mode = fill_mode
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


## The heart icon (T-086): the art at HEART_SCALE, hard pixel edges.
static func _make_heart() -> TextureRect:
	var tex: Texture2D = load(HEART_PATH)
	var h := TextureRect.new()
	h.name = "Heart"
	h.texture = tex
	h.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	h.stretch_mode = TextureRect.STRETCH_SCALE
	h.custom_minimum_size = tex.get_size() * HEART_SCALE
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


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
	combo_label.visible = show_combo(multiplier)
	combo_heat.set_multiplier(multiplier)


## The combo's heat step now (0 base, 1 from x2, 2 from x3, 3 from x4; T-131).
func combo_step() -> int:
	return combo_heat.step


## Whether the likes bar is on fire now (the top heat step, T-131).
func fire_on() -> bool:
	return likes_fire.burning and likes_fire.visible


## Whether the combo counter shows at this multiplier (T-116): only above "no
## combo", combo.json's start_multiplier. Compared at the two decimals the
## counter shows, so a combo that would read "x1.0" stays hidden. Hiding it
## moves nothing else: every HUD element has its own fixed place.
func show_combo(multiplier: float) -> bool:
	var no_combo := _combo_data.start_multiplier() if _combo_data != null else 1.0
	return snappedf(multiplier, 0.01) > snappedf(no_combo, 0.01)
