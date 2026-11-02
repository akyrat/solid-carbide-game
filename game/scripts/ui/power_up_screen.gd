class_name PowerUpScreen
extends CanvasLayer
## The driving power-up overlay (task T-459; Game loop architecture, Decisions, "Mission
## packs"; HUD and menus, Content, "Power-up overlay"). When a completed mission's gift
## opens, PowerUpOffers pauses the run and emits `offers_ready`; this shows the offered
## power-ups as cards over the dimmed run. Taking one calls offers.choose(id), which grants
## it and resumes the run. It only shows the cards and collects input: what a power-up
## does is the car's.
##
## Input, as on the level-up screen: A/D or Left/Right move the highlight, Enter or Space
## takes the highlighted card, clicking anywhere on a card takes it (GiftCardClick, T-475: no button). A key already down
## when the overlay opens (or a key-repeat echo) takes nothing until it has been let go;
## nothing counts during the short build-up (`is_animating()`).
##
## Look (placeholder drawn in code, proposals for the playtest): its own look, so it reads
## as the car's tuning and not as Greenbull's weapons gift: no ribbon, sunburst, emblem or
## green. A workshop look: a hazard-striped header bar (amber and near-black) with the
## header in white, and dark steel cards with an amber frame; the highlighted card gets a
## thick white frame. Each card: the power-up's icon (its power_ups.json path once the art
## exists; until then an amber square with the name's initial), its name, a row of tier
## pips (owned tiers amber, the tier offered white, the rest dark) and the offered tier's
## description. No button: a hover brightens the card's frame.
## Texts: data/screen_texts.json's power_ups (T-456), word for word; a description's
## {slots} are the offered tier's numbers from power_ups.json.

const TEXTS_PATH := "res://data/screen_texts.json"
const FRAME_ART := "res://art/ui/power_up_frame.png"

## Over the HUD (layer 10), under the pause screen (layer 20); never shown together with
## the level-up screen (same layer).
const LAYER := 15
const DIM := Color(0.02, 0.03, 0.06, 0.7)
const INK := Color8(8, 8, 15)
const AMBER := Color8(255, 176, 32)
const AMBER_DARK := Color8(150, 96, 12)
const STEEL := Color8(46, 52, 64)
const STEEL_DARK := Color8(28, 32, 40)
const STEEL_LIGHT := Color8(92, 102, 118)
const WHITE := Color8(255, 255, 255)
const PIP_EMPTY := Color8(70, 76, 88)

const CARD_SIZE := Vector2(340, 340)
const CARD_GAP := 40
const CARD_BORDER := 6
const CARD_MARGIN_X := 24
const CARD_MARGIN_Y := 22
const TEXT_WIDTH := 340.0 - 2.0 * 24.0
const HIGHLIGHT_REACH := 10
const HIGHLIGHT_WIDTH := 6
const ICON_SIZE := Vector2(64, 64)
const PIP_SIZE := Vector2(18, 10)
const PIP_GAP := 6
const HEADER_SIZE := Vector2(820, 84)
const STRIPE_WIDTH := 24
const HEADER_PLATE_INSET := 48
const TITLE_SIZE := 40
const NAME_SIZE := 36
const DESC_SIZE := 22
const KEYS_LEFT := [KEY_A, KEY_LEFT]
const KEYS_RIGHT := [KEY_D, KEY_RIGHT]
const KEYS_TAKE := [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]

## The build-up (stepped, like the level-up screen's but shorter): one frame lasts FRAME
## seconds; each curve is one value per frame, then rests on its last value.
const FRAME := 0.04
const DIM_STEPS := [0.33, 0.66, 1.0]
const HEADER_DROP := [-90, -50, -14, 6, 0]
const CARD_SLIDE := [70, 36, 10, -6, 0]
const CARD_DELAY := 0.08
const CARD_STAGGER := 0.08

## The texts (screen_texts.json's power_ups), read once.
static var _texts: Dictionary = {}

var offers: PowerUpOffers
var data: PowerUpData
## The cards on show, left to right: {id, tier, panel, body, highlight_frame, icon,
## placeholder, name, desc, pips, click}.
var cards: Array = []
var highlight := 0
## Tells whether a physical key is down right now; tests replace it.
var key_down: Callable = func(k: int) -> bool: return Input.is_physical_key_pressed(k)
var title_label: Label
var header: Control
var _root: Control
var _dim: ColorRect
var _row: HBoxContainer
var _blocked: Array = []
var _t := 0.0
var _animating := false
var _anim_length := 0.0


## The overlay's texts: {"overlay_header", "take_button", "names": {}, "descriptions": {}}.
static func texts() -> Dictionary:
	if _texts.is_empty():
		var f := FileAccess.open(TEXTS_PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and (parsed as Dictionary).has("power_ups"):
				_texts = parsed["power_ups"]
	return _texts


## A tier number as the card shows it: whole numbers without decimals ("2"), others
## with as few as they need ("1.6", "0.75").
static func format_number(v: Variant) -> String:
	if v is bool:
		return str(v)
	var x := float(v)
	if is_equal_approx(x, roundf(x)):
		return str(int(roundf(x)))
	var s := "%.2f" % x
	while s.ends_with("0"):
		s = s.left(s.length() - 1)
	return s


## A power-up's description at `tier`: the template with its slots filled from that
## tier's numbers (`bounce_multiplier` is bounce_distance_multiplier, T-456).
static func describe(the_data: PowerUpData, id: String, tier: int) -> String:
	var template := String(texts().get("descriptions", {}).get(id, ""))
	var values := {}
	var numbers := the_data.at(id, tier)
	for k in numbers:
		values[k] = format_number(numbers[k])
	if numbers.has("bounce_distance_multiplier"):
		values["bounce_multiplier"] = format_number(numbers["bounce_distance_multiplier"])
	return template.format(values)


## A power-up's name on its card (T-456).
static func name_of(id: String) -> String:
	return String(texts().get("names", {}).get(id, ""))


## The icon for a power-up: its power_ups.json file once the art exists, else null
## (the card shows the placeholder square).
static func icon_texture(the_data: PowerUpData, id: String) -> Texture2D:
	var path := the_data.icon(id)
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null


func setup(the_offers: PowerUpOffers) -> void:
	offers = the_offers
	data = offers.data
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "PowerUpScreen"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	UiScale.keep(_root)  # scales with the window like the HUD (T-494)
	_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_root)
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = DIM
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 30)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(box)
	var header_holder := Control.new()
	header_holder.name = "HeaderHolder"
	header_holder.custom_minimum_size = HEADER_SIZE
	header_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(header_holder)
	header = HazardHeader.new()
	header.name = "Header"
	header.size = HEADER_SIZE
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_holder.add_child(header)
	title_label = _label(String(texts().get("overlay_header", "")), TITLE_SIZE, WHITE, 6)
	title_label.name = "TitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.position = Vector2(HEADER_PLATE_INSET, 0)
	title_label.size = Vector2(HEADER_SIZE.x - 2 * HEADER_PLATE_INSET, HEADER_SIZE.y)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(title_label)
	_row = HBoxContainer.new()
	_row.name = "Cards"
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", CARD_GAP)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_row)
	offers.offers_ready.connect(_on_offers_ready)
	offers.offer_taken.connect(_on_offer_taken)
	offers.state.run_started.connect(close)
	visible = false


## Shows the cards for these power-up ids and starts the build-up.
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
	_start_animation()


func close() -> void:
	visible = false
	_animating = false
	_clear_cards()


func is_open() -> bool:
	return visible and not cards.is_empty()


func is_animating() -> bool:
	return _animating


func move_highlight(step: int) -> void:
	if cards.is_empty() or _animating:
		return
	highlight = clampi(highlight + step, 0, cards.size() - 1)
	_refresh()


func take_highlighted() -> void:
	if not cards.is_empty():
		take(cards[highlight].id)


## Takes power-up `id`: PowerUpOffers grants it and the run resumes. Refused while the
## overlay is still building up.
func take(id: String) -> void:
	if is_open() and not _animating:
		offers.choose(id)


func animation_length(card_count: int) -> float:
	var cards_end := CARD_DELAY + CARD_STAGGER * maxf(card_count - 1, 0) + FRAME * CARD_SLIDE.size()
	return maxf(cards_end, FRAME * HEADER_DROP.size())


## Plays the build-up to its end at once (tests, fixtures).
func skip_animation() -> void:
	if _animating:
		advance(_anim_length + 1.0)


## Moves the overlay's clock on; `_process` calls it with real time (it runs while the
## tree is paused), tests by hand.
func advance(delta: float) -> void:
	if not visible or not _animating:
		return
	_t += delta
	if _t >= _anim_length:
		_finish_animation()
	else:
		_apply_frame(_t)


func _process(delta: float) -> void:
	advance(delta)


func _input(event: InputEvent) -> void:
	if not is_open() or not (event is InputEventKey):
		return
	var k: int = event.physical_keycode
	if not event.pressed:
		_blocked.erase(k)
		return
	if event.echo or _blocked.has(k):
		return
	var is_ours: bool = KEYS_LEFT.has(k) or KEYS_RIGHT.has(k) or KEYS_TAKE.has(k)
	if _animating:
		if is_ours:
			get_viewport().set_input_as_handled()
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


func _on_offers_ready(_mission_index: int, ids: Array) -> void:
	show_offers(ids)


func _on_offer_taken(_id: String) -> void:
	close()


func _start_animation() -> void:
	_t = 0.0
	_animating = true
	_anim_length = animation_length(cards.size())
	for c in cards:
		c.click.set_active(false)
	_apply_frame(0.0)


func _finish_animation() -> void:
	_animating = false
	_t = _anim_length
	for c in cards:
		c.click.set_active(true)
	_apply_frame(_anim_length + 1.0)


static func _curve(curve: Array, t: float, delay: float) -> Variant:
	if t < delay:
		return null
	return curve[mini(int((t - delay) / FRAME), curve.size() - 1)]


func _apply_frame(t: float) -> void:
	var d: Variant = _curve(DIM_STEPS, t, 0.0)
	_dim.modulate.a = 0.0 if d == null else d
	var h: Variant = _curve(HEADER_DROP, t, 0.0)
	header.position = Vector2(0, 0 if h == null else h)
	for i in cards.size():
		var c: Variant = _curve(CARD_SLIDE, t, CARD_DELAY + CARD_STAGGER * i)
		cards[i].body.visible = c != null
		cards[i].body.position = Vector2(0, 0 if c == null else c)


func _clear_cards() -> void:
	for c in cards:
		_row.remove_child(c.panel)
		c.panel.queue_free()
	cards = []


func _add_card(id: String) -> void:
	var tier := offers.offered_tier(id)
	var panel := Control.new()
	panel.name = "Card_" + id
	panel.custom_minimum_size = CARD_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body := Control.new()
	body.name = "Body"
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(body)
	var glow := Panel.new()
	glow.name = "HighlightFrame"
	glow.add_theme_stylebox_override("panel", _box(Color(0, 0, 0, 0), WHITE, HIGHLIGHT_WIDTH, false))
	glow.position = -Vector2.ONE * HIGHLIGHT_REACH
	glow.size = CARD_SIZE + Vector2.ONE * 2.0 * HIGHLIGHT_REACH
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(glow)
	var frame := Panel.new()
	frame.name = "Frame"
	frame.add_theme_stylebox_override("panel", frame_box())
	frame.size = CARD_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(frame)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", CARD_MARGIN_X)
	margin.add_theme_constant_override("margin_right", CARD_MARGIN_X)
	margin.add_theme_constant_override("margin_top", CARD_MARGIN_Y)
	margin.add_theme_constant_override("margin_bottom", CARD_MARGIN_Y)
	body.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(v)
	var icon: TextureRect = null
	var placeholder: Panel = null
	var tex := icon_texture(data, id)
	if tex != null:
		icon = TextureRect.new()
		icon.name = "Icon"
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = ICON_SIZE
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(icon)
	else:
		placeholder = _placeholder_icon(id)
		v.add_child(placeholder)
	var name_label := _label(name_of(id), NAME_SIZE, AMBER, 6)
	name_label.name = "Name"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = TEXT_WIDTH
	v.add_child(name_label)
	var pips := _tier_pips(id, tier)
	v.add_child(pips)
	var desc := _label(describe(data, id, tier), DESC_SIZE, WHITE, 4)
	desc.name = "Description"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = TEXT_WIDTH
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	# T-475: no button: the whole card is the control (the shared GiftCardClick, T-474).
	var click := GiftCardClick.attach(panel, body, frame, take.bind(id))
	click.set_active(not _animating)
	_row.add_child(panel)
	cards.append({"id": id, "tier": tier, "panel": panel, "body": body, "highlight_frame": glow,
			"icon": icon, "placeholder": placeholder, "name": name_label, "desc": desc,
			"pips": pips, "click": click})


## The placeholder icon (until the art exists): an amber square with a dark frame and
## the power-up's initial.
func _placeholder_icon(id: String) -> Panel:
	var p := Panel.new()
	p.name = "IconPlaceholder"
	p.custom_minimum_size = ICON_SIZE
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _box(AMBER, INK, 4))
	var initial := _label(name_of(id).left(1).to_upper(), 44, INK, 0)
	initial.name = "Initial"
	initial.set_anchors_preset(Control.PRESET_FULL_RECT)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(initial)
	return p


## One pip per tier (no text): the tiers owned amber, the tier offered white, the rest dark.
func _tier_pips(id: String, tier: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "TierPips"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", PIP_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for t in range(1, data.max_tier(id) + 1):
		var pip := ColorRect.new()
		pip.name = "Pip%d" % t
		pip.custom_minimum_size = PIP_SIZE
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.color = AMBER if t < tier else (WHITE if t == tier else PIP_EMPTY)
		row.add_child(pip)
	return row


func _refresh() -> void:
	for i in cards.size():
		cards[i].highlight_frame.visible = i == highlight


## The card's frame: the art (T-464, 170 x 170 shown at exactly 2x = CARD_SIZE, hard pixel
## edges), or the code-drawn steel box with its amber border when the file is missing.
static func frame_box() -> StyleBox:
	if ResourceLoader.exists(FRAME_ART):
		var b := StyleBoxTexture.new()
		b.texture = load(FRAME_ART) as Texture2D
		return b
	return _box(STEEL, AMBER, CARD_BORDER)


## A flat box with hard corners (pixel look): fill, border colour and width.
static func _box(fill: Color, border: Color, width: int, draw_center := true) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.draw_center = draw_center
	b.border_color = border
	b.set_border_width_all(width)
	b.anti_aliasing = false
	b.set_corner_radius_all(0)
	return b


func _label(text: String, font_size: int, color: Color, outline: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", HudStyle.comic_font())
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", INK)
		l.add_theme_constant_override("outline_size", outline)
	return l


## The header bar, drawn in code: amber and near-black hazard stripes with a dark steel
## plate in the middle for the header text, framed in near-black.
class HazardHeader:
	extends Control

	func _ready() -> void:
		clip_contents = true  # the stripes run past the edges; the frame is drawn over them

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(Vector2.ZERO, size), AMBER)
		var sw := float(STRIPE_WIDTH)
		var x := -h
		while x < w:
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, h), Vector2(x + sw, h), Vector2(x + sw + h, 0), Vector2(x + h, 0)]), INK)
			x += sw * 2.0
		for r in [Rect2(0, 0, w, 4), Rect2(0, h - 4, w, 4), Rect2(0, 0, 4, h), Rect2(w - 4, 0, 4, h)]:
			draw_rect(r, INK)
		var plate := Rect2(Vector2(HEADER_PLATE_INSET, 10), Vector2(w - 2 * HEADER_PLATE_INSET, h - 20))
		draw_rect(plate.grow(4), INK)
		draw_rect(plate, STEEL_DARK)
		draw_rect(Rect2(plate.position, Vector2(plate.size.x, 4)), STEEL_LIGHT)
