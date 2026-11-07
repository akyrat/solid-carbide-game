class_name CosmeticsScreen
extends Control
## The Cosmetics submenu (task T-553; HUD and menus, Decisions, "A Cosmetics button on the main
## menu"; Garage design, Decisions, "Cosmetics"): the jump effects in a list, each with a preview,
## name, description and its price, a pick button once unlocked or the Equipped label when picked,
## plus the coins and a Back button. It shows state and passes buying and picking on to
## PlayerProgress (T-552); it holds no rule. Every text is read from data/cosmetics_text.json
## (T-550), except the coin count and the Back button, which reuse the garage's approved texts.

signal back_pressed

const TEXT_FILE := "cosmetics_text"
const JumpEffectScript := preload("res://scripts/driving/jump_effect.gd")
const MIN_COLUMN_WIDTH := 900
const DESCRIPTION_WIDTH := 360
const PREVIEW_SIZE := Vector2(96, 96)
## One preview loop, in seconds, and the pause at its end (proposals for the playtest).
const PREVIEW_SECONDS := 1.0
const PREVIEW_HOLD := 0.4

var progress: PlayerProgress
var column: VBoxContainer
var title_label: Label
var coins_label: Label
var message_label: Label
var back_button: Button
## effect id -> {price: Label, state: Label, button: Button, preview: Control}
var rows: Dictionary = {}
var _texts: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UiScale.keep(self)
	_texts = load_texts()
	if progress == null:
		progress = PlayerProgress.new()
	progress.changed.connect(refresh)

	var background := ColorRect.new()
	background.color = Color(0.05, 0.05, 0.12)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	column = VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 12)
	column.custom_minimum_size = Vector2(MIN_COLUMN_WIDTH, 0)
	column.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(column)

	title_label = _label("Title", text("title"), 56, Color(0.3, 0.9, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)
	coins_label = _label("Coins", "", 32, Color(1.0, 0.85, 0.3))
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(coins_label)

	for e in progress.cosmetics_list():
		column.add_child(_build_row(str(e.id)))

	message_label = _label("Message", "", 22, Color(1.0, 0.5, 0.5))
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.custom_minimum_size = Vector2(0, 30)
	column.add_child(message_label)

	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = GarageScreen.BACK_TEXT
	back_button.custom_minimum_size = Vector2(280, 56)
	HudStyle.style_button(back_button)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(func(): back_pressed.emit())
	column.add_child(back_button)

	resized.connect(func(): fit())
	refresh()
	fit()
	_first_focus()


## The texts file (data/cosmetics_text.json) as a Dictionary.
static func load_texts() -> Dictionary:
	var data = GameData.unwrap(GameData.load_file(TEXT_FILE))
	return data if data is Dictionary else {}


func text(key: String) -> String:
	return str(_texts.get(key, ""))


func effect_name(id: String) -> String:
	return str(_texts.get("effects", {}).get(id, {}).get("name", ""))


func effect_description(id: String) -> String:
	return str(_texts.get("effects", {}).get(id, {}).get("description", ""))


## Scales and centres the column so all of it is on screen at any window size (like the garage).
func fit(view: Vector2 = Vector2.ZERO) -> void:
	if column == null:
		return
	if view == Vector2.ZERO:
		view = size
	column.scale = Vector2.ONE
	column.size = Vector2.ZERO
	var natural := column.get_combined_minimum_size()
	column.size = natural
	var s := maxf(UiScale.fit(view, natural.max(Vector2.ONE)), 0.05)
	column.scale = Vector2(s, s)
	column.position = (view - natural * s) / 2.0


func _label(node_name: String, t: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.name = node_name
	l.text = t
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _build_row(id: String) -> Control:
	var panel := PanelContainer.new()
	panel.name = "Row_" + id
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 20)
	panel.add_child(line)

	var preview := EffectPreview.new()
	preview.name = "Preview"
	preview.effect_id = id
	preview.custom_minimum_size = PREVIEW_SIZE
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(preview)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(text_col)
	text_col.add_child(_label("Name", effect_name(id), 28, Color(1, 1, 1)))
	var desc := _label("Description", effect_description(id), 16, Color(0.6, 0.6, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(DESCRIPTION_WIDTH, 0)
	text_col.add_child(desc)

	var price := _label("Price", "", 22, Color(1.0, 0.85, 0.3))
	price.custom_minimum_size = Vector2(250, 0)
	price.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_child(price)

	var state := _label("State", "", 22, Color(0.5, 1.0, 0.6))
	state.custom_minimum_size = Vector2(130, 0)
	line.add_child(state)

	var button := Button.new()
	button.name = "ActionButton"
	button.custom_minimum_size = Vector2(150, 48)
	HudStyle.style_button(button)
	button.pressed.connect(_on_action.bind(id))
	line.add_child(button)

	rows[id] = {"price": price, "state": state, "button": button, "preview": preview}
	return panel


## Buys a locked effect or picks an unlocked one. A refused purchase shows the message.
func _on_action(id: String) -> void:
	message_label.text = ""
	if progress.is_unlocked(id):
		progress.equip(id)
	else:
		var r := progress.buy_cosmetic(id)
		if not r.ok and r.reason == PlayerProgress.NOT_ENOUGH_COINS:
			message_label.text = text("not_enough_coins")
	refresh()


func _first_focus() -> void:
	focus_order()[0].grab_focus()


## The buttons the arrow keys walk, top to bottom: every action button that is shown, then Back.
func focus_order() -> Array:
	var order: Array = []
	for e in progress.cosmetics_list():
		var b: Button = rows[e.id].button
		if b.visible:
			order.append(b)
	order.append(back_button)
	return order


## Redraws every label and button from the save state.
func refresh() -> void:
	coins_label.text = GarageScreen.COINS_TEXT.replace("{n}", str(progress.get_coins()))
	var focused: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var focused_row := ""
	for id in rows:
		if rows[id].button == focused:
			focused_row = id
	for e in progress.cosmetics_list():
		var row: Dictionary = rows[e.id]
		var b: Button = row.button
		row.price.text = ""
		row.state.text = ""
		if e.equipped:
			row.state.text = text("equipped")
			b.visible = false
		elif e.unlocked:
			b.visible = true
			b.text = text("pick")
		else:
			row.price.text = text("locked").replace("{price}", str(e.price))
			b.visible = true
			b.text = text("buy")
		b.focus_mode = Control.FOCUS_ALL if b.visible else Control.FOCUS_NONE
	KeyNav.chain_column(focus_order())
	# the button that was focused may just have been hidden (the picked one): hand the focus to Back
	if focused_row != "" and not rows[focused_row].button.visible:
		back_button.grab_focus()


## W, A, S, D move the selection like the arrow keys (T-492).
func _unhandled_key_input(event: InputEvent) -> void:
	KeyNav.handle_wasd(event, self)


## The animated preview of one effect: the jump effect's own placeholder drawing (T-551; T-556's art
## replaces it in the same function) on a loop, over a small stand-in for the car.
class EffectPreview extends Control:
	var effect_id := ""
	var _clock := 0.0

	func _process(delta: float) -> void:
		_clock += delta
		queue_redraw()

	## Progress of the loop, 0 to 1, then held at 1 for a moment.
	func progress_t() -> float:
		var loop := CosmeticsScreen.PREVIEW_SECONDS + CosmeticsScreen.PREVIEW_HOLD
		return clampf(fmod(_clock, loop) / CosmeticsScreen.PREVIEW_SECONDS, 0.0, 1.0)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.13, 0.2))
		var origin := Vector2(size.x * 0.5, size.y * 0.72)
		var basis := Transform2D(Vector2(1.0, 0.5) * 12.0, Vector2(-1.0, 0.5) * 12.0, Vector2.ZERO)
		draw_rect(Rect2(origin - Vector2(5, 3), Vector2(10, 6)), Color(0.35, 0.37, 0.42))  # the car stand-in
		CosmeticsScreen.JumpEffectScript.draw_placeholder(self, effect_id, progress_t(), origin, basis, 0.0, 22.0)
