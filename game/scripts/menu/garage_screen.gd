class_name GarageScreen
extends Control
## The MVP garage screen (task T-058): a plain list of the three upgrades, each with its
## level, the price of the next level and a buy button, plus the player's coins and a back
## button. It only shows the state and passes buying on to PlayerProgress (T-057); the back
## button sends a signal (the screen flow connects it). Garage design, Decisions.

signal back_pressed

## Text approved in T-059 ({n} is where the number goes).
const TITLE := "Redgull Pit Stop"
const LEVEL_TEXT := "Level {n}"
const PRICE_TEXT := "Price: {n}"
const COINS_TEXT := "Coins: {n}"
const BUY_TEXT := "Buy"
const MAXED_TEXT := "Fully Funded"
const TOO_POOR_TEXT := "Not enough coins"
const BACK_TEXT := "Back"
const NAMES := {
	"acceleration": "Sponsored Throttle",
	"car_health": "Reinforced Chassis",
	"damage_bonus": "Brand Impact",
}
const DESCRIPTIONS := {
	"acceleration": "Top speed 0.1 s sooner per level. More drifting, more content.",
	"car_health": "+10 car health per level. Redgull says you'll be fine.",
	"damage_bonus": "+5% weapon damage per level. Redgull calls it synergy.",
}

## The save/buy object. When null at _ready, the game's own (GameFlow.progress is passed in by
## the flow) or, standalone, one read from the save file.
var progress: PlayerProgress

var title_label: Label
var coins_label: Label
var back_button: Button
## upgrade id -> {level: Label, price: Label, buy: Button, status: Label}
var rows: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if progress == null:
		progress = PlayerProgress.new()
	progress.changed.connect(refresh)

	var background := ColorRect.new()
	background.color = Color(0.05, 0.05, 0.12)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.custom_minimum_size = Vector2(900, 0)
	center.add_child(column)

	title_label = _label("Title", TITLE, 56, Color(0.3, 0.9, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)

	coins_label = _label("Coins", "", 32, Color(1.0, 0.85, 0.3))
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(coins_label)

	for id in GarageData.UPGRADES:
		column.add_child(_build_row(id))

	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = BACK_TEXT
	back_button.custom_minimum_size = Vector2(280, 56)
	back_button.add_theme_font_size_override("font_size", 28)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(func(): back_pressed.emit())
	column.add_child(back_button)

	refresh()


func _label(node_name: String, text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.name = node_name
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _build_row(id: String) -> Control:
	var panel := PanelContainer.new()
	panel.name = "Row_" + id
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 20)
	panel.add_child(line)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(text_col)
	var name_label := _label("Name", NAMES.get(id, id), 28, Color(1, 1, 1))
	text_col.add_child(name_label)
	var desc := _label("Description", DESCRIPTIONS.get(id, ""), 16, Color(0.6, 0.6, 0.7))
	text_col.add_child(desc)

	var level_label := _label("Level", "", 24, Color(1, 1, 1))
	level_label.custom_minimum_size = Vector2(120, 0)
	line.add_child(level_label)

	var price_label := _label("Price", "", 24, Color(1.0, 0.85, 0.3))
	price_label.custom_minimum_size = Vector2(130, 0)
	line.add_child(price_label)

	var status_label := _label("Status", "", 18, Color(1.0, 0.5, 0.5))
	status_label.custom_minimum_size = Vector2(190, 0)
	line.add_child(status_label)

	var buy := Button.new()
	buy.name = "BuyButton"
	buy.text = BUY_TEXT
	buy.custom_minimum_size = Vector2(110, 48)
	buy.add_theme_font_size_override("font_size", 24)
	buy.pressed.connect(_on_buy.bind(id))
	line.add_child(buy)

	rows[id] = {"level": level_label, "price": price_label, "buy": buy, "status": status_label}
	return panel


func _on_buy(id: String) -> void:
	progress.buy(id)
	refresh()  # also when refused, so the message is up to date


## Redraws every label and button from the save/buy state.
func refresh() -> void:
	coins_label.text = COINS_TEXT.replace("{n}", str(progress.get_coins()))
	for id in rows:
		var info: Dictionary = progress.info(id)
		var row: Dictionary = rows[id]
		row.level.text = LEVEL_TEXT.replace("{n}", str(info.level))
		if info.maxed:
			row.price.text = ""
			row.status.text = MAXED_TEXT
			row.buy.disabled = true
			row.buy.modulate.a = 0.0  # hidden but keeps the row's layout
			row.status.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
		else:
			row.price.text = PRICE_TEXT.replace("{n}", str(info.next_price))
			row.buy.modulate.a = 1.0
			row.status.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
			row.buy.disabled = not info.can_buy
			row.status.text = "" if info.can_buy else TOO_POOR_TEXT
