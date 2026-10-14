class_name LevelUpScreen
extends CanvasLayer
## The level-up (gift pack) screen (task T-052; HUD and menus, Decisions,
## 2026-10-15). When the run starts a level-up's weapon choice, the run is paused
## (RunState.pause_on_level_up) and T-043's offers emit `offers_ready`; this
## shows the offered choices as comic cards over the dimmed run. Taking one
## calls offers.choose(id), which applies it and resumes the run. It only shows
## the cards and collects input: what a choice does is the weapon rack's.
##
## Input: A/D or Left/Right move the highlight, Enter or Space takes the
## highlighted card, clicking a card's button takes that card. A key already down
## when the screen opens (or a key-repeat echo) takes nothing: it counts again
## once it has been let go.
## Look: the trick popups' comic look: white rounded cards with black borders,
## black Bangers text with hard pixel edges, no Redgull red; the highlighted card
## has a thick yellow ring (the combo counter's yellow) with a black outline.
## Texts: LevelUpTexts (approved in T-051).

const Texts := preload("res://scripts/ui/level_up_texts.gd")
const HudScript := preload("res://scripts/hud/hud.gd")

## Over the HUD (layer 10), under the pause screen (layer 20).
const LAYER := 15
const DIM := Color(0, 0, 0, 0.6)
const INK := Color(0, 0, 0)
const PAPER := Color(1, 1, 1)
const RING := Color8(255, 224, 77)
const PRESSED := Color8(255, 190, 40)
const CARD_SIZE := Vector2(360, 300)
## Width the wrapping texts get inside a card (card width less margins and the thickest border).
const TEXT_WIDTH := 360.0 - 2.0 * 18.0 - 2.0 * 8.0
const CARD_GAP := 40
const BORDER := 4
const BORDER_HIGHLIGHT := 8
const OUTLINE_HIGHLIGHT := 4
const CORNER := 14
const TITLE_SIZE := 40
const CARD_TITLE_SIZE := 36
const CARD_DESC_SIZE := 24
const BUTTON_SIZE := 30
const KEYS_LEFT := [KEY_A, KEY_LEFT]
const KEYS_RIGHT := [KEY_D, KEY_RIGHT]
const KEYS_TAKE := [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]

## The weapon rack (run.weapons), whose `offers` this screen shows.
var rack: Node
var offers: Node
## The cards on show, left to right: {id, panel, title, desc, button}.
var cards: Array = []
## Index of the highlighted card.
var highlight := 0
## Tells whether a physical key is down right now; tests replace it.
var key_down: Callable = func(k: int) -> bool: return Input.is_physical_key_pressed(k)
var title_label: Label
var _root: Control
var _row: HBoxContainer
## Keys that were down when the screen opened and have not been let go since.
var _blocked: Array = []


func setup(the_rack: Node) -> void:
	rack = the_rack
	offers = rack.offers
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "LevelUpScreen"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	center.add_child(box)
	var banner := PanelContainer.new()
	banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	banner.add_theme_stylebox_override("panel", _style(BORDER, INK, CORNER))
	box.add_child(banner)
	title_label = _label(Texts.TEXTS["levelup.title"], TITLE_SIZE)
	title_label.name = "TitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(title_label)
	_row = HBoxContainer.new()
	_row.name = "Cards"
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", CARD_GAP)
	box.add_child(_row)
	offers.offers_ready.connect(_on_offers_ready)
	offers.offer_taken.connect(_on_offer_taken)
	rack.state.run_started.connect(close)
	visible = false


## The approved text for a choice's card: {title, desc}. An upgrade shows the
## tier it would give (the weapon's tier now + 1).
func card_text(id: String) -> Dictionary:
	var key := id
	if id == offers.UPGRADE_GUN:
		key = "%s.tier%d" % [id, rack.gun.tier + 1]
	elif id == offers.UPGRADE_FLAMETHROWER:
		key = "%s.tier%d" % [id, rack.flamethrower.tier + 1]
	return {"title": Texts.TEXTS.get(key + ".title", ""), "desc": Texts.TEXTS.get(key + ".desc", "")}


## Shows the cards for these choice ids.
func show_offers(ids: Array) -> void:
	_clear_cards()
	for id in ids:
		_add_card(str(id))
	highlight = 0
	_blocked = []
	for k in KEYS_LEFT + KEYS_RIGHT + KEYS_TAKE:
		if key_down.call(k):
			_blocked.append(k)
	_refresh()
	visible = true


func close() -> void:
	visible = false
	_clear_cards()


func is_open() -> bool:
	return visible and not cards.is_empty()


func move_highlight(step: int) -> void:
	if cards.is_empty():
		return
	highlight = clampi(highlight + step, 0, cards.size() - 1)
	_refresh()


func take_highlighted() -> void:
	if not cards.is_empty():
		take(cards[highlight].id)


## Takes the choice `id`: T-043 applies it and the run resumes.
func take(id: String) -> void:
	if is_open():
		offers.choose(id)


func _input(event: InputEvent) -> void:
	if not is_open() or not (event is InputEventKey):
		return
	var k: int = event.physical_keycode
	if not event.pressed:
		_blocked.erase(k)
		return
	if event.echo or _blocked.has(k):
		return
	if KEYS_LEFT.has(k):
		move_highlight(-1)
	elif KEYS_RIGHT.has(k):
		move_highlight(1)
	elif KEYS_TAKE.has(k):
		take_highlighted()
	else:
		return
	get_viewport().set_input_as_handled()


func _on_offers_ready(_level: int, ids: Array) -> void:
	show_offers(ids)


func _on_offer_taken(_id: String) -> void:
	close()


func _clear_cards() -> void:
	for c in cards:
		_row.remove_child(c.panel)
		c.panel.queue_free()
	cards = []


func _add_card(id: String) -> void:
	var text := card_text(id)
	var panel := PanelContainer.new()
	panel.name = "Card_" + id
	panel.custom_minimum_size = CARD_SIZE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var title := _label(text.title, CARD_TITLE_SIZE)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = TEXT_WIDTH
	v.add_child(title)
	var desc := _label(text.desc, CARD_DESC_SIZE)
	desc.name = "Description"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = TEXT_WIDTH
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	var button := Button.new()
	button.name = "TakeButton"
	button.text = Texts.TEXTS["levelup.take"]
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", HudScript.comic_font())
	button.add_theme_font_size_override("font_size", BUTTON_SIZE)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(c, INK)
	button.add_theme_stylebox_override("normal", _style(BORDER, INK, 6, PAPER))
	button.add_theme_stylebox_override("hover", _style(BORDER, INK, 6, RING))
	button.add_theme_stylebox_override("pressed", _style(BORDER, INK, 6, PRESSED))
	button.add_theme_stylebox_override("hover_pressed", _style(BORDER, INK, 6, PRESSED))
	button.pressed.connect(take.bind(id))
	v.add_child(button)
	_row.add_child(panel)
	cards.append({"id": id, "panel": panel, "title": title, "desc": desc, "button": button})


## The highlighted card: a thick yellow ring with a black outline round it.
func _refresh() -> void:
	for i in cards.size():
		var panel: PanelContainer = cards[i].panel
		if i == highlight:
			panel.add_theme_stylebox_override("panel", _style(BORDER_HIGHLIGHT, RING, CORNER, PAPER, OUTLINE_HIGHLIGHT))
		else:
			panel.add_theme_stylebox_override("panel", _style(BORDER, INK, CORNER, PAPER))


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", HudScript.comic_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", INK)
	return l


## A hard-edged (not smoothed) rounded box. `outline` > 0 draws a black ring of
## that width outside the border (as a shadow).
static func _style(border: int, border_color: Color, corner: int, fill: Color = PAPER, outline := 0) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = fill
	st.border_color = border_color
	st.set_border_width_all(border)
	st.set_corner_radius_all(corner)
	st.anti_aliasing = false
	st.content_margin_left = 18.0
	st.content_margin_right = 18.0
	st.content_margin_top = 14.0
	st.content_margin_bottom = 14.0
	if outline > 0:
		st.shadow_color = INK
		st.shadow_size = outline
		st.shadow_offset = Vector2.ZERO
	return st
