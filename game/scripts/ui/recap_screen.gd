class_name RecapScreen
extends Control
## The recap screen (task T-320; Game loop architecture, Decisions, "Recap screen in
## the MVP" and "The recap always closes a run"; HUD and menus, Content, "Recap
## screen"). Every run ends on it: it shows a run's stats (a RunState.recap()
## summary, T-319) with pictures, and the player leaves it with Continue or the X
## at the top right. Both send `closed`; what comes next is the screen flow's.
## It only shows a summary and collects input.
##
## Any summary can be shown (`show_summary`), also one read back from the run
## history's JSON (T-363, numbers as floats), so the runs list (T-364) can reopen a
## saved run here.
##
## What it shows (left out when its count is 0; a section with nothing to show is
## left out too, a proposal):
## - the title, by how the run ended (`title.win`, `title.time_up`, `title.wreck`);
## - Takedowns: each enemy type with its sprite (the first frame of its south-facing
##   sheet), its name and "x{count}";
## - Peak engagement: the run's peak live viewers (board, 2026-10-29, quick tuning),
##   written as the HUD's live viewers counter writes it (ViewersData.format: 236K,
##   1.02M) with the viewers' eye, in the counter's look for that number (the
##   viewers colour at the base, ComboHeat's heat colours, glow and pulse above);
## - Tricks landed: each trick as its trick popup (TrickPopupArt, the plain look)
##   with "x{count}";
## - Weapons used: each weapon with its level-up card image, its name and its tier (`tier`).
## "x{n}" is the HUD's approved count form (WeaponIcons.TEXT_COUNT). Every other
## word comes from res://data/recap_text.json (T-318); nothing is written here.
##
## Look: the game's comic look, white rounded panels with black borders, black
## Bangers lettering with hard pixel edges, nearest filtering, over the main menu's
## dark background. The sections pop in one after the other in stepped frames (a
## proposal); Continue and the X work at once. Enter also continues (a fresh press
## only); the buttons take no keyboard focus, so a drift key held from the run
## presses nothing.

## Sent once, by Continue, the X or Enter.
signal closed

const TEXT_PATH := "res://data/recap_text.json"
## The enemy sprite sheets: square frames in a row; the first frame is shown.
const ENEMY_ART := {
	"minion": "res://art/minion/minion_s.png",
	"kaiju": "res://art/kaiju/kaiju_s.png",
}

const BACKGROUND := Color(0.05, 0.05, 0.12)  # the main menu's
const PANEL_FILL := Color(1, 1, 1)
const INK := Color(0, 0, 0)
const BORDER := 3
const CORNER := 10
const MARGIN := 20
const GAP := 12
const TITLE_SIZE := 40
const HEADING_SIZE := 26
const NAME_SIZE := 20
const COUNT_SIZE := 28
## The picture slot of an enemy or a weapon, in screen pixels.
const SLOT := Vector2(64, 64)
const CONTINUE_SIZE := Vector2(220, 52)
const CLOSE_SIZE := Vector2(52, 52)
## The X, drawn in code: CLOSE_GRID pixels shown CLOSE_SCALE screen pixels each.
const CLOSE_SCALE := 3
## The X's outline (T-446) and the room round it inside the 52 px plate: (52 - 40) / 2.
const CLOSE_OUTLINE := 2
const CLOSE_PAD := 6
const CLOSE_GRID := [
	"kk........kk", "kkk......kkk", ".kkk....kkk.", "..kkk..kkk..",
	"...kkkkkk...", "....kkkk....", "....kkkk....", "...kkkkkk...",
	"..kkk..kkk..", ".kkk....kkk.", "kkk......kkk", "kk........kk",
]
## The trick popups' size style here.
const TRICK_STYLE := "normal"
## The viewers' eye beside the peak viewers (T-339's art, as on the HUD counter).
const EYE_PATH := "res://art/hud/eye_icon.png"
const EYE_SCALE := 3
## The pop-in: a section shows over these alpha steps, one per FRAME seconds,
## starting STAGGER seconds after the previous one.
const FRAME := 0.04
const POP_STEPS := [0.34, 0.67, 1.0]
const STAGGER := 0.12

static var _texts: Dictionary = {}
static var _enemy_cache := {}

## The summary on show.
var summary: Dictionary = {}
var title_label: Label
var continue_button: Button
var close_button: Button
## Section name ("enemies", "combo", "tricks", "weapons") to its panel, only those on show.
var sections: Dictionary = {}
## id to {image: TextureRect, name: Label, count: Label}.
var enemy_rows: Dictionary = {}
## id to {image: TextureRect, count: Label}.
var trick_rows: Dictionary = {}
## id to {image: TextureRect, name: Label, tier: Label}.
var weapon_rows: Dictionary = {}
## The peak viewers number (the "combo" section).
var peak_label: Label
var combo_heat: ComboHeat
var _content: Control
var _reveal: Array = []  # panels in the order they pop in
var _t := 0.0
var _animating := false
var _closed := false


func _init() -> void:
	name = "RecapScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## The recap's texts (T-318's data file), read once.
static func texts() -> Dictionary:
	if _texts.is_empty():
		var f := FileAccess.open(TEXT_PATH, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
		if typeof(parsed) == TYPE_DICTIONARY:
			_texts = parsed
		else:
			push_error("Could not read the recap texts %s" % TEXT_PATH)
	return _texts


## The text at a dotted key ("title.win", "button.continue"); "" when missing.
static func text(key: String) -> String:
	var node: Variant = texts()
	for part in key.split("."):
		if typeof(node) != TYPE_DICTIONARY or not node.has(part):
			return ""
		node = node[part]
	return node if typeof(node) == TYPE_STRING else ""


## Which title a summary gets: "win", "time_up" (lost on the clock) or "wreck"
## (lost on health; also any other summary that is not a win).
static func title_key(s: Dictionary) -> String:
	if str(s.get("result", "")) == "win":
		return "win"
	if str(s.get("loss_reason", "")) == "time":
		return "time_up"
	return "wreck"


## The HUD's count form, "x{n}".
static func count_text(n: Variant) -> String:
	return WeaponIcons.TEXT_COUNT.format({"tier": n})


## The enemy's picture: the first frame of its sheet, cropped to its pixels; null
## for an enemy without art.
static func enemy_image(enemy_id: String) -> Texture2D:
	if _enemy_cache.has(enemy_id):
		return _enemy_cache[enemy_id]
	var tex: Texture2D = null
	if ENEMY_ART.has(enemy_id) and ResourceLoader.exists(ENEMY_ART[enemy_id]):
		var sheet: Texture2D = load(ENEMY_ART[enemy_id])
		var img := sheet.get_image()
		if img.is_compressed():
			img.decompress()
		var side := mini(img.get_height(), img.get_width())
		var frame := img.get_region(Rect2i(0, 0, side, side))
		var used := frame.get_used_rect()
		if used.size.x > 0 and used.size.y > 0:
			frame = frame.get_region(used)
		tex = ImageTexture.create_from_image(frame)
	_enemy_cache[enemy_id] = tex
	return tex


## Shows `s` (a RunState.recap() summary), replacing anything on show.
func show_summary(s: Dictionary) -> void:
	summary = s.duplicate(true)
	_closed = false
	for c in get_children():
		remove_child(c)
		c.queue_free()
	sections = {}
	enemy_rows = {}
	trick_rows = {}
	weapon_rows = {}
	peak_label = null
	combo_heat = null
	_reveal = []
	_build()
	_t = 0.0
	_animating = true
	for p in _reveal:
		p.modulate.a = 0.0
	_animate()


## True while the sections are still popping in.
func is_animating() -> bool:
	return _animating


## Ends the pop-in at once (for tests and screenshots).
func finish_animation() -> void:
	_t = STAGGER * _reveal.size() + FRAME * POP_STEPS.size()
	_animate()


## Continue or the X: sends `closed` once.
func close() -> void:
	if _closed:
		return
	_closed = true
	closed.emit()


func _process(delta: float) -> void:
	Perf.begin(&"ui.recap")
	if _animating:
		_t += delta
		_animate()
	Perf.end(&"ui.recap")


func _animate() -> void:
	var done := true
	for i in _reveal.size():
		var local := _t - STAGGER * i
		var a := 0.0
		if local >= 0.0:
			var step := int(floorf(local / FRAME))
			a = POP_STEPS[mini(step, POP_STEPS.size() - 1)]
		if a < 1.0:
			done = false
		_reveal[i].modulate.a = a
	_animating = not done


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode in [KEY_ENTER, KEY_KP_ENTER] or k.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		close()


func _build() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = BACKGROUND
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, MARGIN)
	add_child(margin)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", GAP)
	margin.add_child(column)
	_content = column

	# The title.
	var title_row := CenterContainer.new()
	column.add_child(title_row)
	var title_panel := _panel("TitlePanel")
	title_row.add_child(title_panel)
	title_label = _label("Title", text("title." + title_key(summary)), TITLE_SIZE)
	title_panel.add_child(title_label)
	_reveal.append(title_panel)

	# Takedowns and peak engagement side by side.
	var top_row := HBoxContainer.new()
	top_row.name = "TopRow"
	top_row.add_theme_constant_override("separation", GAP)
	column.add_child(top_row)
	_build_enemies(top_row)
	_build_combo(top_row)
	_build_tricks(column)
	_build_weapons(column)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	var bottom := CenterContainer.new()
	column.add_child(bottom)
	continue_button = _button("ContinueButton", CONTINUE_SIZE)
	continue_button.text = text("button.continue")
	continue_button.pressed.connect(close)
	bottom.add_child(continue_button)

	# The X at the top right, outside the column.
	close_button = _button("CloseButton", CLOSE_SIZE)
	close_button.icon = _close_icon()
	close_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HudStyle.button_padding(close_button, CLOSE_PAD, CLOSE_PAD)
	close_button.tooltip_text = text("button.close")
	close_button.set("accessibility_name", text("button.close"))
	close_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_button.offset_left = -MARGIN - CLOSE_SIZE.x
	close_button.offset_right = -MARGIN
	close_button.offset_top = MARGIN
	close_button.offset_bottom = MARGIN + CLOSE_SIZE.y
	close_button.pressed.connect(close)
	add_child(close_button)


func _build_enemies(parent: Control) -> void:
	var slain: Dictionary = _dict(summary.get("enemies_slain", {}))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	for id in _dict(texts().get("enemy", {})):
		var n := int(slain.get(id, 0))
		if n <= 0:
			continue
		var item := HBoxContainer.new()
		item.name = "Enemy_" + id
		item.add_theme_constant_override("separation", 10)
		var image := _image("Image", enemy_image(id))
		item.add_child(image)
		var words := VBoxContainer.new()
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.add_theme_constant_override("separation", 0)
		item.add_child(words)
		var name_label := _label("Name", text("enemy." + id), NAME_SIZE)
		var count_label := _label("Count", count_text(n), COUNT_SIZE)
		words.add_child(name_label)
		words.add_child(count_label)
		row.add_child(item)
		enemy_rows[id] = {"image": image, "name": name_label, "count": count_label}
	if enemy_rows.is_empty():
		row.free()
		return
	_section(parent, "enemies", row, true)


func _build_combo(parent: Control) -> void:
	var peak := peak_viewers(summary)
	var curve := ViewersData.new()
	# The live viewers counter's look for that number (T-336): its heat step (the fire
	# step takes the top heat look), the viewers colour at the base step.
	var heat := mini(curve.step_for_viewers(peak), ComboHeat.STEPS.size() - 1)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var eye := TextureRect.new()
	eye.name = "Eye"
	eye.texture = load(EYE_PATH)
	eye.custom_minimum_size = eye.texture.get_size() * EYE_SCALE
	eye.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	eye.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	eye.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(eye)
	# A holder of fixed size, so the pulse's scale is never reset by a container.
	var holder := Control.new()
	holder.name = "PeakHolder"
	holder.custom_minimum_size = Vector2(170, 70)
	row.add_child(holder)
	peak_label = Label.new()
	peak_label.name = "PeakViewers"
	peak_label.text = curve.format(peak)
	peak_label.add_theme_font_override("font", Hud.comic_font())
	peak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	peak_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	peak_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	peak_label.resized.connect(func(): peak_label.pivot_offset = Vector2(0.0, peak_label.size.y / 2.0))
	holder.add_child(peak_label)
	combo_heat = ComboHeat.new()
	combo_heat.process_mode = Node.PROCESS_MODE_INHERIT
	holder.add_child(combo_heat)
	combo_heat.setup(peak_label, null)
	if heat > 0:
		combo_heat.set_multiplier(ComboHeat.THRESHOLDS[heat - 1])
	else:
		peak_label.add_theme_color_override("font_color", viewers_color())
	var wrap := CenterContainer.new()
	wrap.add_child(row)
	_section(parent, "combo", wrap, true)


## The run's peak live viewers: `peak_viewers` (T-320 quick tuning), or, for a summary
## saved before it existed, the viewers for its `highest_combo` on the same curve
## (RunState.peak_viewers_for), so an older run shows the same kind of number.
static func peak_viewers(s: Dictionary) -> float:
	if s.has("peak_viewers"):
		return float(s.peak_viewers)
	return RunState.peak_viewers_for(float(s.get("highest_combo", 1.0)))


## The live viewers counter's colour (hud.json viewers_counter.color).
static func viewers_color() -> Color:
	var r := GameData.load_file("hud")
	var cfg: Dictionary = r.data.get("viewers_counter", {}) if r.ok else {}
	return Color(String(cfg.get("color", "#33e1ff")))


func _build_tricks(parent: Control) -> void:
	var done: Dictionary = _dict(summary.get("tricks", {}))
	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 22)
	flow.add_theme_constant_override("v_separation", 8)
	for id in _dict(texts().get("trick", {})):
		var n := int(done.get(id, 0))
		if n <= 0:
			continue
		var item := HBoxContainer.new()
		item.name = "Trick_" + id
		item.add_theme_constant_override("separation", 6)
		var tex := TrickPopupArt.texture(text("trick." + id), TRICK_STYLE, 0)
		var image := TextureRect.new()
		image.name = "Image"
		image.texture = tex
		image.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(image)
		var count_label := _label("Count", count_text(n), COUNT_SIZE)
		item.add_child(count_label)
		flow.add_child(item)
		trick_rows[id] = {"image": image, "count": count_label}
	if trick_rows.is_empty():
		flow.free()
		return
	_section(parent, "tricks", flow, false)


func _build_weapons(parent: Control) -> void:
	var used: Dictionary = _dict(summary.get("weapons", {}))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	for id in used:
		var info: Dictionary = _dict(used[id])
		var tier := int(info.get("tier", 0))
		var weapon_name := text("weapon." + str(id))
		if tier <= 0 or weapon_name == "":
			continue
		var item := VBoxContainer.new()
		item.name = "Weapon_" + str(id)
		item.add_theme_constant_override("separation", 0)
		var image := _image("Image", LevelUpScreen.weapon_image(str(id)))
		image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		item.add_child(image)
		var name_label := _label("Name", weapon_name, NAME_SIZE)
		var tier_label := _label("Tier", text("tier").format({"tier": tier}), NAME_SIZE)
		item.add_child(name_label)
		item.add_child(tier_label)
		row.add_child(item)
		weapon_rows[str(id)] = {"image": image, "name": name_label, "tier": tier_label}
	if weapon_rows.is_empty():
		row.free()
		return
	_section(parent, "weapons", row, false)


## A section: a panel with its heading and its content, added to `parent`.
func _section(parent: Control, key: String, content: Control, expand: bool) -> void:
	var panel := _panel("Section_" + key)
	if expand:
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_child(_label("Heading", text("heading." + key), HEADING_SIZE))
	content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if not content is FlowContainer else Control.SIZE_EXPAND_FILL
	box.add_child(content)
	parent.add_child(panel)
	sections[key] = panel
	_reveal.append(panel)


func _panel(node_name: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = node_name
	p.add_theme_stylebox_override("panel", _style(PANEL_FILL, 14, 6))
	return p


func _style(fill: Color, pad_x: int, pad_y: int) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = fill
	st.border_color = INK
	st.set_border_width_all(BORDER)
	st.set_corner_radius_all(CORNER)
	st.anti_aliasing = false
	st.content_margin_left = pad_x
	st.content_margin_right = pad_x
	st.content_margin_top = pad_y
	st.content_margin_bottom = pad_y
	return st


func _label(node_name: String, words: String, font_size: int) -> Label:
	var l := Label.new()
	l.name = node_name
	l.text = words
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", Hud.comic_font())
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", INK)
	return l


func _image(node_name: String, tex: Texture2D) -> TextureRect:
	var r := TextureRect.new()
	r.name = node_name
	r.texture = tex
	r.custom_minimum_size = SLOT
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r


func _button(node_name: String, min_size: Vector2) -> Button:
	var b := Button.new()
	b.name = node_name
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	HudStyle.style_button(b)  # the shared button (T-446)
	return b


static func _close_icon() -> Texture2D:
	var h := CLOSE_GRID.size()
	var w: int = CLOSE_GRID[0].length()
	var img := Image.create(w * CLOSE_SCALE, h * CLOSE_SCALE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			if CLOSE_GRID[y][x] == "k":
				img.fill_rect(Rect2i(x * CLOSE_SCALE, y * CLOSE_SCALE, CLOSE_SCALE, CLOSE_SCALE), Color.WHITE)
	# T-446: the X is white, tinted by the shared button's icon colours, with the
	# sheet's near-black outline (CLOSE_OUTLINE pixels) round it so it reads on the plate.
	var o := CLOSE_OUTLINE
	var out := Image.create(img.get_width() + 2 * o, img.get_height() + 2 * o, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				out.fill_rect(Rect2i(x, y, 2 * o + 1, 2 * o + 1), HudStyle.OUTLINE_COLOR)
	out.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(o, o))
	return ImageTexture.create_from_image(out)


static func _dict(v: Variant) -> Dictionary:
	return v if typeof(v) == TYPE_DICTIONARY else {}
