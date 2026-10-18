class_name LevelUpScreen
extends CanvasLayer
## The level-up (gift pack) screen (task T-052; HUD and menus, Decisions,
## 2026-10-15). When the run starts a level-up's weapon choice, the run is paused
## and T-043's offers emit `offers_ready`; this shows the offered choices as
## cards over the dimmed run. Taking one calls offers.choose(id), which applies
## it and resumes the run. It only shows the cards and collects input: what a
## choice does is the weapon rack's.
##
## Input: A/D or Left/Right move the highlight, Enter or Space takes the
## highlighted card, clicking a card's button takes that card. A key already down
## when the screen opens (or a key-repeat echo) takes nothing: it counts again
## once it has been let go. While the screen builds up (see below) nothing counts.
## Look (T-141, with T-140's art): red and gold cards (9-slice), a bright gold
## frame on the highlighted card, the red ribbon with the title, gold "Take it"
## plates, a sunburst behind and the gift box emblem; black Bangers text with
## hard pixel edges on the cream cards.
## Animation (T-141): the screen builds up in under a second in stepped (pixel)
## frames, running while the tree is paused: the dim fades in, the sunburst
## grows, the ribbon and the emblem drop in, the cards slide up one after the
## other. Nothing can be taken or moved while it runs (`is_animating()`).
## Texts: LevelUpTexts (approved in T-051 and T-171).
## Weapon image (T-173; HUD and menus, Decisions, 2026-10-18): every card shows
## its weapon's image in a 64 x 64 slot above the title. The image is
## `art/level_up/weapon_<weapon id>.png` once the art task adds it; until then a
## placeholder drawn in code (16 x 16 pixels, never Redgull red).

const Texts := preload("res://scripts/ui/level_up_texts.gd")
const HudScript := preload("res://scripts/hud/hud.gd")

## Over the HUD (layer 10), under the pause screen (layer 20).
const LAYER := 15
const DIM := Color(0, 0, 0, 0.6)
const INK := Color(0, 0, 0)
const HOVER_TINT := Color(1.15, 1.15, 1.15)
## T-173: 74 px taller than T-141's 360 x 300 to make room for the weapon image
## (64 px and its 10 px gap), so the texts keep the room they had.
const CARD_SIZE := Vector2(360, 374)
## The weapon image's slot on the card, in screen pixels.
const IMAGE_SIZE := Vector2(64, 64)
## The final images (art task), one per weapon id; missing ones use a placeholder.
const WEAPON_ART := "res://art/level_up/weapon_%s.png"
## Placeholder images (T-173): 16 x 16 pixel grids, one character per pixel
## ("." is transparent), shown 4 screen pixels per pixel. No Redgull red.
const PLACEHOLDER_COLORS := {
	"k": Color8(20, 20, 24), "g": Color8(120, 124, 132), "s": Color8(184, 188, 196),
	"b": Color8(72, 64, 58), "o": Color8(255, 170, 40), "y": Color8(255, 230, 90),
	"w": Color8(255, 250, 210), "c": Color8(60, 230, 240), "d": Color8(50, 60, 90),
	"v": Color8(150, 200, 230), "p": Color8(230, 220, 190), "e": Color8(60, 150, 70),
	"l": Color8(140, 210, 140),
}
const PLACEHOLDER_GRIDS := {
	# The starting gun: a small pistol (board, 2026-10-18).
	"gun": [
		"................", "................", "................",
		"..kkkkkkkkkkkk..", "..kssssssssssk..", "..kggggggggggk..",
		"..kkkkggkkkkkk..", "..kbbkk.k.......", "..kbbk.kk.......",
		"..kbbkkk........", "..kbbk..........", "..kbbk..........",
		"..kkkk..........", "................", "................", "................",
	],
	# The exhaust flamethrower: a tailpipe with a flame.
	"flamethrower": [
		"................", "................", "................", "................",
		"..........yy....", "kkkkkk...yoy....", "kssssk..yoooy...",
		"kggggkkyooyooy..", "kggggggoowwooy..", "kggggkkyooyooy..",
		"kssssk..yoooy...", "kkkkkk...yoy....", "..........yy....",
		"................", "................", "................",
	],
	# The neon underglow: a car inside a cyan ring.
	"underglow": [
		"................", "................", "................",
		"....cccccccc....", "..cc........cc..", ".c....kkkk....c.",
		"c....kddddk....c", "c...kddvvddk...c", "c...kddddddk...c",
		"c....kkkkkk....c", ".c............c.", "..cc........cc..",
		"....cccccccc....", "................", "................", "................",
	],
	# The molotovs: a green bottle with a lit rag.
	"molotov": [
		"......y.........", ".....yoy........", ".....yoy........",
		"......p.........", "......kpk.......", "......kek.......",
		"......kek.......", ".....kkekk......", "....keeeeek.....",
		"....keleeek.....", "....keleeek.....", "....keeeeek.....",
		"....keeeeek.....", "....kkkkkkk.....", "................", "................",
	],
	# The windshield wiper: a blade on its pivot.
	"wiper": [
		"................", "............kk..", "...........ksk..",
		"..........ksk...", ".........ksk....", "........ksk.....",
		".......ksk......", "......ksk.......", ".....ksk........",
		"....ksk.........", "...ksk..........", "..kggk..........",
		".kgggk..........", ".kkkk...........", "................", "................",
	],
}
static var _placeholder_cache := {}
## Margin between a card's edge and its text (the frame's border and studs are 20 px).
const CARD_MARGIN_X := 30
const CARD_MARGIN_Y := 26
## Width the wrapping texts get inside a card.
const TEXT_WIDTH := 360.0 - 2.0 * CARD_MARGIN_X
const CARD_GAP := 40
const TITLE_SIZE := 40
const CARD_TITLE_SIZE := 36
const CARD_DESC_SIZE := 24
const BUTTON_SIZE := 30
const BUTTON_PLATE_SIZE := Vector2(144, 44)
const KEYS_LEFT := [KEY_A, KEY_LEFT]
const KEYS_RIGHT := [KEY_D, KEY_RIGHT]
const KEYS_TAKE := [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]

## T-140's art, shown at 2 screen pixels per art pixel unless noted.
const ART := "res://art/level_up/"
const ART_SCALE := 2
const RIBBON_SIZE := Vector2(760, 88)
## The title is lettered between art x 76 and 304 of the ribbon.
const TITLE_X0 := 76 * ART_SCALE
const TITLE_X1 := 304 * ART_SCALE
## The highlight frame reaches this far past the card on each side (6 art pixels).
const HIGHLIGHT_REACH := 12
const EMBLEM_SIZE := Vector2(128, 128)
const EMBLEM_OFFSET := Vector2(-110, -24)
const SUN_SCALE_FULL := 4.0
const SUN_ALPHA := 0.75
## Spin: this many degrees every SUN_SPIN_STEP seconds (stepped, never smooth).
const SUN_SPIN_DEGREES := 1.5
const SUN_SPIN_STEP := 0.1

## The build-up (T-141). One frame lasts FRAME seconds; every curve is one value
## per frame, then rests on its last value.
const FRAME := 0.04
const DIM_STEPS := [0.25, 0.5, 0.75, 1.0]
const SUN_STEPS := [0.3, 0.55, 0.8, 1.0, 1.08, 1.0]
const RIBBON_DROP := [-140, -84, -34, 10, -6, 0]
const RIBBON_DELAY := 0.05
const EMBLEM_DELAY := 0.12
const CARD_SLIDE := [90, 52, 20, -10, 4, 0]
const CARD_DELAY := 0.2
const CARD_STAGGER := 0.1

## The weapon rack (run.weapons), whose `offers` this screen shows.
var rack: Node
var offers: Node
## The cards on show, left to right: {id, panel, body, highlight_frame, image, title, desc, button}.
var cards: Array = []
## Index of the highlighted card.
var highlight := 0
## Tells whether a physical key is down right now; tests replace it.
var key_down: Callable = func(k: int) -> bool: return Input.is_physical_key_pressed(k)
var title_label: Label
var _root: Control
var _row: HBoxContainer
var _dim: ColorRect
var _sun: TextureRect
var _ribbon_holder: Control
var _ribbon: TextureRect
var _emblem: TextureRect
## Keys that were down when the screen opened and have not been let go since.
var _blocked: Array = []
## Seconds since the screen opened, and whether the build-up is still running.
var _t := 0.0
var _animating := false
var _anim_length := 0.0


func setup(the_rack: Node) -> void:
	rack = the_rack
	offers = rack.offers
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "LevelUpScreen"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_root)
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = DIM
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_dim)
	_sun = TextureRect.new()
	_sun.name = "Sunburst"
	_sun.texture = load(ART + "sunburst.png")
	_sun.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sun.custom_minimum_size = _sun.texture.get_size()
	_sun.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_sun.pivot_offset = _sun.texture.get_size() / 2.0
	_sun.modulate = Color(1, 1, 1, SUN_ALPHA)
	_root.add_child(_sun)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(box)
	_ribbon_holder = Control.new()
	_ribbon_holder.name = "Banner"
	_ribbon_holder.custom_minimum_size = RIBBON_SIZE
	_ribbon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_ribbon_holder)
	_ribbon = _art_rect("header_ribbon.png", "Ribbon", RIBBON_SIZE)
	_ribbon_holder.add_child(_ribbon)
	title_label = _label(Texts.TEXTS["levelup.title"], TITLE_SIZE)
	title_label.name = "TitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.position = Vector2(TITLE_X0, 0)
	title_label.size = Vector2(TITLE_X1 - TITLE_X0, RIBBON_SIZE.y)
	title_label.clip_text = true
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ribbon.add_child(title_label)
	_emblem = _art_rect("gift_pack_emblem.png", "Emblem", EMBLEM_SIZE)
	_emblem.position = EMBLEM_OFFSET
	_ribbon_holder.add_child(_emblem)
	_row = HBoxContainer.new()
	_row.name = "Cards"
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", CARD_GAP)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_row)
	offers.offers_ready.connect(_on_offers_ready)
	offers.offer_taken.connect(_on_offer_taken)
	rack.state.run_started.connect(close)
	visible = false


## The approved text for a choice's card: {title, desc}. An upgrade shows the
## tier it would give (the weapon's tier now + 1).
func card_text(id: String) -> Dictionary:
	var key := id
	if id.begins_with("upgrade_"):
		var weapon: Node = rack.get_weapon(offers.weapon_of(id))
		if weapon != null:
			key = "%s.tier%d" % [id, weapon.tier + 1]
	return {"title": Texts.TEXTS.get(key + ".title", ""), "desc": Texts.TEXTS.get(key + ".desc", "")}


## The image a weapon's card shows: the art task's file once it is there,
## otherwise the placeholder drawn in code.
static func weapon_image(weapon_id: String) -> Texture2D:
	var path := WEAPON_ART % weapon_id
	if ResourceLoader.exists(path):
		return load(path)
	return placeholder_image(weapon_id)


## The placeholder image for a weapon (16 x 16, transparent background), or
## null for an id without one.
static func placeholder_image(weapon_id: String) -> Texture2D:
	if _placeholder_cache.has(weapon_id):
		return _placeholder_cache[weapon_id]
	if not PLACEHOLDER_GRIDS.has(weapon_id):
		return null
	var grid: Array = PLACEHOLDER_GRIDS[weapon_id]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in grid.size():
		var row: String = grid[y]
		for x in row.length():
			var ch := row[x]
			if ch != ".":
				img.set_pixel(x, y, PLACEHOLDER_COLORS[ch])
	var tex := ImageTexture.create_from_image(img)
	_placeholder_cache[weapon_id] = tex
	return tex


## Shows the cards for these choice ids and starts the build-up.
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


## True while the screen builds up: no card can be taken or highlighted.
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


## Takes the choice `id`: T-043 applies it and the run resumes. Refused while
## the screen is still building up.
func take(id: String) -> void:
	if is_open() and not _animating:
		offers.choose(id)


## How long the build-up lasts for this many cards, in seconds.
func animation_length(card_count: int) -> float:
	var cards_end := CARD_DELAY + CARD_STAGGER * maxf(card_count - 1, 0) + FRAME * CARD_SLIDE.size()
	var ribbon_end := EMBLEM_DELAY + FRAME * RIBBON_DROP.size()
	return maxf(cards_end, ribbon_end)


## Plays the build-up to its end at once (tests, fixtures).
func skip_animation() -> void:
	if _animating:
		advance(_anim_length + 1.0)


## Moves the screen's clock on (the sunburst spin and the build-up). `_process`
## calls it with real time (it runs while the tree is paused); tests call it by hand.
func advance(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_sun.rotation = deg_to_rad(floorf(_t / SUN_SPIN_STEP) * SUN_SPIN_DEGREES)
	if _animating:
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
		# A press during the build-up is used up: nothing is taken or moved.
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


func _on_offers_ready(_level: int, ids: Array) -> void:
	show_offers(ids)


func _on_offer_taken(_id: String) -> void:
	close()


func _start_animation() -> void:
	_t = 0.0
	_animating = true
	_anim_length = animation_length(cards.size())
	for c in cards:
		c.button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_frame(0.0)


func _finish_animation() -> void:
	_animating = false
	_t = _anim_length
	for c in cards:
		c.button.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_frame(_anim_length + 1.0)


## The value of a one-per-frame curve `t` seconds in, for something that starts
## at `delay`: the frame's value, the last one once it is over, null before it starts.
static func _curve(curve: Array, t: float, delay: float) -> Variant:
	if t < delay:
		return null
	var i := int((t - delay) / FRAME)
	return curve[mini(i, curve.size() - 1)]


func _apply_frame(t: float) -> void:
	var d: Variant = _curve(DIM_STEPS, t, 0.0)
	_dim.modulate.a = 0.0 if d == null else d
	var s: Variant = _curve(SUN_STEPS, t, 0.0)
	_sun.scale = Vector2.ONE * SUN_SCALE_FULL * (0.0 if s == null else s)
	var r: Variant = _curve(RIBBON_DROP, t, RIBBON_DELAY)
	_ribbon.visible = r != null
	_ribbon.position = Vector2(0, 0 if r == null else r)
	var e: Variant = _curve(RIBBON_DROP, t, EMBLEM_DELAY)
	_emblem.visible = e != null
	_emblem.position = EMBLEM_OFFSET + Vector2(0, 0 if e == null else e)
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
	var text := card_text(id)
	var panel := Control.new()
	panel.name = "Card_" + id
	panel.custom_minimum_size = CARD_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# `body` is what slides in; the panel keeps its place in the row.
	var body := Control.new()
	body.name = "Body"
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(body)
	# T-173: a 9-slice, so the 6-art-pixel frame keeps its thickness on the taller card.
	var glow := NinePatchRect.new()
	glow.name = "HighlightFrame"
	glow.texture = load(ART + "highlight_frame.png")
	glow.patch_margin_left = 10
	glow.patch_margin_top = 10
	glow.patch_margin_right = 10
	glow.patch_margin_bottom = 10
	glow.size = (CARD_SIZE + Vector2.ONE * 2.0 * HIGHLIGHT_REACH) / ART_SCALE
	glow.scale = Vector2.ONE * ART_SCALE
	glow.position = Vector2(-HIGHLIGHT_REACH, -HIGHLIGHT_REACH)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(glow)
	var frame := NinePatchRect.new()
	frame.name = "Frame"
	frame.texture = load(ART + "card_frame.png")
	frame.patch_margin_left = 10
	frame.patch_margin_top = 10
	frame.patch_margin_right = 10
	frame.patch_margin_bottom = 10
	frame.size = CARD_SIZE / ART_SCALE
	frame.scale = Vector2.ONE * ART_SCALE
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
	var image := TextureRect.new()
	image.name = "WeaponImage"
	image.texture = weapon_image(offers.weapon_of(id))
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = IMAGE_SIZE
	image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(image)
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
	button.custom_minimum_size = BUTTON_PLATE_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_override("font", HudScript.comic_font())
	button.add_theme_font_size_override("font_size", BUTTON_SIZE)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(c, INK)
	button.add_theme_stylebox_override("normal", _plate("button_plate.png"))
	button.add_theme_stylebox_override("hover", _plate("button_plate.png", HOVER_TINT))
	button.add_theme_stylebox_override("pressed", _plate("button_plate_pressed.png"))
	button.add_theme_stylebox_override("hover_pressed", _plate("button_plate_pressed.png"))
	button.pressed.connect(take.bind(id))
	v.add_child(button)
	_row.add_child(panel)
	cards.append({"id": id, "panel": panel, "body": body, "highlight_frame": glow, "image": image,
			"title": title, "desc": desc, "button": button})


## The highlighted card shows T-140's bright gold frame.
func _refresh() -> void:
	for i in cards.size():
		cards[i].highlight_frame.visible = i == highlight


## A texture shown `size` big (screen pixels).
func _art_rect(file: String, node_name: String, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.name = node_name
	r.texture = load(ART + file)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _plate(file: String, tint := Color.WHITE) -> StyleBoxTexture:
	var st := StyleBoxTexture.new()
	st.texture = load(ART + file)
	st.modulate_color = tint
	return st


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", HudScript.comic_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", INK)
	return l
