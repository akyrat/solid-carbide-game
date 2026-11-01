class_name TutorialSlides
extends Control
## The tutorial slides (tasks T-382, redrawn in T-485; HUD and menus, Decisions, "The tutorial
## slides are redrawn, with clips of the real car"): four slides shown before the first run:
## 1 Drive (the keys and the drift rule beside the drift clip), 2 Tricks bring gift packs (the
## loop as four steps, then three clips), 3 Missions (the notebook page and the four driving
## power-ups), 4 Survive the stream (the 8-minute timeline, Go live, Don't show again). A left
## and a right arrow move between them (slide 1 has no left arrow, slide 4 no right arrow), a
## Skip control at the top right jumps to slide 4, and slide 4 has the Go live button and the
## "Don't show again" checkbox. It only shows the screen and sends start_pressed(dont_show_again);
## starting the run is the screen flow's job.
##
## Every word comes from res://data/tutorial_text.json (TrickList.text; headlines, labels and
## captions are stored in sentence case and shown in capitals here) and, for the notebook sample
## and the power-up names, res://data/screen_texts.json. The slides are laid out on a 1280 x 720
## stage that is scaled to fit the window. Keys and focus order, and how it is built:
## game/docs/hud-and-menus/tutorial-slides.md.

signal start_pressed(dont_show_again: bool)

const SLIDE_COUNT := 4
const STAGE := Vector2(1280, 720)
const SIDE := 115.0  # the slides' left and right padding (9% of the stage's width)
const CONTENT_W := 1050.0
const PIXEL_FONT_PATH := "res://fonts/press_start_2p/PressStart2P-Regular.ttf"
const BG := Color("0d0d1b")
const PANEL := Color("171a2c")
const PLATE := Color("3f4659")
const LINE := Color("2a2f47")
const INK := Color("ecebf5")
const MUTED := Color("a3a6c2")
const PINK := Color("ff5fae")
const CYAN := Color("3fd2ff")
const BLUSH := Color("f6c9de")
const DANGER := Color("ff5a4f")
const GOLD := Color("ffd25a")
const KEY_FACE := Color("e9e8f2")
const KEY_EDGE := Color("8f93ab")
const KEY_HI_EDGE := Color("b77b98")
const NIGHT := Color("0d0d1b")
const DOT_ON := BLUSH
const DOT_OFF := Color("4a4f6b")
## The arrows' triangle outline, in screen pixels (T-446: the shared button's outline colour).
const ARROW_OUTLINE := 3
## The "Don't show again" checkbox square, in screen pixels.
const CHECK_BOX_SIZE := 28
## The trick on slide 2's first step, the weapons on its last step (HudStyle.weapon_icon ids).
const STEP_TRICK := "extended_drift"
const STEP_WEAPONS: Array[String] = ["gun", "molotov", "bricks", "underglow"]
## The clips: slide 1's, then slide 2's three with the key of each one's caption.
const CLIP_SLIDE1 := "drift"
const CLIPS_SLIDE2: Array = [
	["long_drift", "trick.extended_drift"],
	["alt_drift", "trick.alternate_drift"],
	["ramp_jump", "slide2.clip_ramp"],
]
## Art the slides draw (all the game's own files).
const ART_EYE := "res://art/hud/eye_icon.png"
const ART_SUBS := "res://art/hud/subs_icon.png"
const ART_PACKAGE := "res://art/gift_pack/package.png"
const ART_KAIJU := "res://art/kaiju/kaiju_s.png"
const ART_LIVE := "res://art/hud/live_badge.png"
const ART_TRICK := "res://art/tutorial/tricks/%s.png"
const ART_POWER_UP := "res://art/power_ups/%s.png"
const POWER_UPS: Array[String] = ["rev_charge", "jump", "bouncy_bumpers", "rusty_overcoat"]
const SCREEN_TEXTS := "res://data/screen_texts.json"
## The run's length in minutes and where the gift packs sit on the timeline (fractions).
const RUN_MINUTES := 8
const GIFT_AT: Array[float] = [0.14, 0.33, 0.52, 0.70]
## The numbers in the notebook sample and the viewer count; sample figures, not words.
const SAMPLE_VIEWERS := "1,284"
const SAMPLE_GOALS: Array = [
	{"trick": "extended_drift", "kind": "duration", "amount": 4.0, "done": 4.0, "completed": true},
	{"trick": "alternate_drift", "kind": "count", "amount": 10.0, "done": 2.0, "completed": false},
]

var current := 0
var slides: Array[Control] = []
var left_arrow: Button
var right_arrow: Button
var skip_button: Button
var start_button: Button
var dont_show_checkbox: CheckBox
## The stage every slide is drawn on (1280 x 720, scaled to the window).
var stage: Control
## Slide 1's clip and slide 2's three, in order.
var clip_players: Array[ClipPlayer] = []
## Every label that shows one text from the file, key to the node (tests check each against
## the file; a Label shows it in capitals through `uppercase`, the text itself is the file's).
var text_labels: Dictionary = {}
## Each slide's kicker label, and the three parts of slide 1's drift rule.
var kickers: Array[Label] = []
var rule_labels: Array[Label] = []
var rule_keycap: Label
## Slide 2's four steps' pictures, slide 3's page and power-up names, slide 4's timeline labels.
var step_pictures: Array[Control] = []
var notebook_page: MissionPage
var power_up_labels: Dictionary = {}
var time_labels: Array[Label] = []
var gift_packs: Array[TextureRect] = []
var kaiju_picture: TextureRect
var kaiju_label: Label
var timeline_bar: TextureRect
## Every picture on slides 2 to 4: the texture's file path, for the tests.
var picture_paths: Array[String] = []
var _dots: Array[ColorRect] = []
var _pixel_font: FontFile
var _screen_texts: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true

	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	stage = Control.new()
	stage.name = "Stage"
	stage.size = STAGE
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	_add_glow(Vector2(640, 780), Vector2(1500, 700), PINK, 0.16)
	_add_glow(Vector2(130, -70), Vector2(1100, 560), CYAN, 0.12)

	for builder in [_build_slide1, _build_slide2, _build_slide3, _build_slide4]:
		stage.add_child(builder.call())
	_build_chrome()
	resized.connect(_fit)
	_fit()
	show_slide(0)


## Scales and centres the 1280 x 720 stage in the window, the way the other screens scale.
func _fit() -> void:
	if stage == null:
		return
	var s := minf(size.x / STAGE.x, size.y / STAGE.y)
	if s <= 0.0:
		s = 1.0
	stage.scale = Vector2(s, s)
	stage.position = ((size - STAGE * s) / 2.0).floor()


## Shows slide `index` (0 to 3), shows or hides the arrows and puts the focus where it belongs.
func show_slide(index: int) -> void:
	current = clampi(index, 0, SLIDE_COUNT - 1)
	for i in range(slides.size()):
		slides[i].visible = i == current
	for i in range(_dots.size()):
		_dots[i].color = DOT_ON if i == current else DOT_OFF
		_dots[i].custom_minimum_size.x = 46 if i == current else 15
	left_arrow.visible = current > 0
	right_arrow.visible = current < SLIDE_COUNT - 1
	if is_inside_tree():
		for p in clip_players:
			if slides[current].is_ancestor_of(p):
				p.ensure_loaded()  # a clip's sheet is read when its slide first shows
		if current == SLIDE_COUNT - 1:
			start_button.grab_focus()
		else:
			right_arrow.grab_focus()


func next_slide() -> void:
	if current < SLIDE_COUNT - 1:
		show_slide(current + 1)


func previous_slide() -> void:
	if current > 0:
		show_slide(current - 1)


## The Skip control: straight to the last slide.
func skip_to_last() -> void:
	show_slide(SLIDE_COUNT - 1)


## Keys: Left or A go back, Right or D go forward (the arrows do nothing at the ends). Enter and
## Space press the focused control; Tab and Shift+Tab move the focus. Only a fresh key press
## counts (a held key's echo does not).
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := event as InputEventKey
	var code := key.keycode
	if code == KEY_LEFT or code == KEY_A:
		previous_slide()
		get_viewport().set_input_as_handled()
	elif code == KEY_RIGHT or code == KEY_D:
		next_slide()
		get_viewport().set_input_as_handled()


# --- The arrows, Skip and the dots (on every slide) ---------------------------------------------

func _build_chrome() -> void:
	left_arrow = _make_arrow("LeftArrow", -1, "arrow.left")
	left_arrow.position = Vector2(20, 302)
	stage.add_child(left_arrow)
	right_arrow = _make_arrow("RightArrow", 1, "arrow.right")
	right_arrow.position = Vector2(STAGE.x - 20 - right_arrow.custom_minimum_size.x, 302)
	stage.add_child(right_arrow)

	skip_button = Button.new()
	skip_button.name = "SkipButton"
	skip_button.text = TrickList.text("button.skip").to_upper()
	skip_button.custom_minimum_size = Vector2(96, 40)
	HudStyle.style_button(skip_button, true)  # the shared button, the small size
	skip_button.size = skip_button.custom_minimum_size
	skip_button.position = Vector2(STAGE.x - 28 - 96, 24)
	text_labels["button.skip"] = skip_button
	stage.add_child(skip_button)

	var dots := HBoxContainer.new()
	dots.name = "Dots"
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 13)
	dots.position = Vector2(0, STAGE.y - 28 - 15)
	dots.size = Vector2(STAGE.x, 15)
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(dots)
	for i in range(SLIDE_COUNT):
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(15, 15)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots.add_child(dot)
		_dots.append(dot)

	left_arrow.pressed.connect(previous_slide)
	right_arrow.pressed.connect(next_slide)
	skip_button.pressed.connect(skip_to_last)
	start_button.pressed.connect(func(): start_pressed.emit(dont_show_checkbox.button_pressed))


## An arrow button with no text: the shared button (T-446) with a triangle drawn in code
## in its text colour and outline, which drops with the press like a button's text; its
## tooltip is the label from the file.
func _make_arrow(node_name: String, direction: int, key: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.custom_minimum_size = Vector2(70, 116)
	b.size = b.custom_minimum_size
	b.tooltip_text = TrickList.text(key)
	HudStyle.style_button(b)
	text_labels[key] = b
	b.draw.connect(func(): _draw_arrow(b, direction))
	return b


func _draw_arrow(b: Button, direction: int) -> void:
	var mode := b.get_draw_mode()
	var pressed := mode == BaseButton.DRAW_PRESSED or mode == BaseButton.DRAW_HOVER_PRESSED
	var c := (b.size / 2.0).floor() + Vector2(0, HudStyle.BUTTON_PRESS_DROP if pressed else 0)
	var color := b.get_theme_color("font_color")
	if mode == BaseButton.DRAW_DISABLED:
		color = b.get_theme_color("font_disabled_color")
	elif mode == BaseButton.DRAW_HOVER or b.has_focus():
		color = b.get_theme_color("font_hover_color")
	var d := float(direction)
	var o := float(ARROW_OUTLINE)
	b.draw_colored_polygon(PackedVector2Array([
		c + Vector2((14 + o * 2) * d, 0), c + Vector2((-14 - o) * d, -26 - o * 2),
		c + Vector2((-14 - o) * d, 26 + o * 2)]), b.get_theme_color("font_outline_color"))
	b.draw_colored_polygon(PackedVector2Array([
		c + Vector2(14 * d, 0), c + Vector2(-14 * d, -26), c + Vector2(-14 * d, 26)]), color)


# --- Slide 1: Drive --------------------------------------------------------------------------------

func _build_slide1() -> Control:
	var s := _slide("Slide1", 0, "slide1.title", "kicker.controls")
	# The keys in their WASD shape, each with its label, W highlighted.
	var left := VBoxContainer.new()
	left.name = "Keys"
	left.add_theme_constant_override("separation", 34)
	left.position = Vector2(SIDE, 262)
	s.add_child(left)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 12)
	left.add_child(grid)
	var cells := [["", ""], ["W", "w"], ["", ""], ["A", "a"], ["S", "s"], ["D", "d"]]
	for c in cells:
		if c[0] == "":
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(92, 92)
			grid.add_child(gap)
		else:
			grid.add_child(_keycap(c[0], "slide1.key_" + c[1], c[0] == "W"))
	# The drift rule: "W + turn = drift", the W drawn as a keycap.
	var rule := HBoxContainer.new()
	rule.name = "DriftRule"
	rule.add_theme_constant_override("separation", 18)
	left.add_child(rule)
	var parts := _split_rule(TrickList.text("slide1.drift_rule"))
	var items := [parts[0], "+", parts[1], "=", parts[2]]
	for i in range(items.size()):
		if i == 0:
			var cap := PanelContainer.new()
			cap.add_theme_stylebox_override("panel", _box(BLUSH, 5, 0, Color(0, 0, 0, 0), 14, 9))
			rule_keycap = _label(items[i], true, 22, NIGHT, false)
			cap.add_child(rule_keycap)
			cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			rule.add_child(cap)
			rule_labels.append(rule_keycap)
		else:
			var is_sign := i == 1 or i == 3
			var l := _label(items[i], is_sign, 28 if is_sign else 46, MUTED if i == 1 else (PINK if i == 3 else INK), not is_sign)
			rule.add_child(l)
			if not is_sign:
				rule_labels.append(l)
	# Beside them: the drift clip.
	s.add_child(_clip_box(CLIP_SLIDE1, Vector2(619, 232), Vector2(546, 364), 4))
	return s


## "W + turn = drift" split on "+" and "=": ["W", "turn", "drift"].
static func _split_rule(rule: String) -> PackedStringArray:
	var out := PackedStringArray()
	for chunk in rule.replace("=", "+").split("+"):
		out.append(chunk.strip_edges())
	while out.size() < 3:
		out.append("")
	return out


## One keycap (92 x 92): the letter big, its label small under it.
func _keycap(letter: String, key: String, highlight: bool) -> Control:
	var cap := PanelContainer.new()
	cap.name = "Key" + letter
	cap.custom_minimum_size = Vector2(92, 92)
	var face := BLUSH if highlight else KEY_FACE
	var edge := KEY_HI_EDGE if highlight else KEY_EDGE
	cap.add_theme_stylebox_override("panel", _box(face, 8, 0, Color(0, 0, 0, 0), 4, 4, edge, 9))
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	cap.add_child(col)
	var big := _label(letter, true, 32, NIGHT, false)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(big)
	var small := _text_label(key, true, 8, NIGHT, true)
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(small)
	return cap


# --- Slide 2: Tricks bring gift packs --------------------------------------------------------------

func _build_slide2() -> Control:
	var s := _slide("Slide2", 1, "slide2.title", "kicker.loop")
	var column := VBoxContainer.new()
	column.name = "Column"
	column.position = Vector2(SIDE, 192)
	column.size = Vector2(CONTENT_W, 440)
	column.add_theme_constant_override("separation", 14)
	s.add_child(column)

	# The chain: four steps with arrows between.
	var chain := HBoxContainer.new()
	chain.name = "Chain"
	chain.add_theme_constant_override("separation", 12)
	column.add_child(chain)
	var pics: Array[Control] = [_pic_trick(), _pic_viewers(), _pic_subs(), _pic_gift()]
	for i in range(4):
		step_pictures.append(pics[i])
		chain.add_child(_step(i + 1, pics[i]))
		if i < 3:
			chain.add_child(_chevron())

	# Under it, a dashed rule and the three clips with their captions.
	var rule := Control.new()
	rule.custom_minimum_size = Vector2(CONTENT_W, 6)
	rule.draw.connect(func():
		var x := 0.0
		while x < CONTENT_W:
			rule.draw_line(Vector2(x, 3), Vector2(minf(x + 6, CONTENT_W), 3), LINE, 2.0)
			x += 12.0)
	column.add_child(rule)
	var clips := HBoxContainer.new()
	clips.name = "Clips"
	clips.alignment = BoxContainer.ALIGNMENT_CENTER
	clips.add_theme_constant_override("separation", 38)
	column.add_child(clips)
	for c in CLIPS_SLIDE2:
		var fig := VBoxContainer.new()
		fig.add_theme_constant_override("separation", 8)
		fig.add_child(_clip_box(c[0], Vector2.ZERO, Vector2(256, 171), 3, 20.0))
		var cap := _text_label(c[1], false, 21, INK, true)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fig.add_child(cap)
		clips.add_child(fig)
	return s


## One step panel: its picture, its title and its caption (slide2.step<n>_*).
func _step(n: int, pic: Control) -> Control:
	var panel := PanelContainer.new()
	panel.name = "Step%d" % n
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(PANEL, 8, 2, LINE, 12, 14))
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(0, 100)
	holder.add_child(pic)
	col.add_child(holder)
	var title := _text_label("slide2.step%d_title" % n, false, 29, INK, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var caption := _text_label("slide2.step%d_caption" % n, false, 17, MUTED, false, true)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.custom_minimum_size = Vector2(150, 0)
	col.add_child(caption)
	return panel


func _chevron() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(22, 0)
	c.size_flags_vertical = Control.SIZE_FILL
	c.draw.connect(func():
		var m := Vector2(11, c.size.y / 2.0)
		c.draw_polyline(PackedVector2Array([m + Vector2(-5, -14), m + Vector2(5, 0), m + Vector2(-5, 14)]), PINK, 5.0))
	return c


func _pic_trick() -> Control:
	return _picture(ART_TRICK % STEP_TRICK, Vector2(128, 96))


func _pic_viewers() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var eye := _picture(ART_EYE, Vector2(48, 33))
	eye.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(eye)
	row.add_child(_label(SAMPLE_VIEWERS, true, 16, INK, false))
	return row


## The sub goal ring (a gold arc round the subs icon), drawn in code with the HUD's own icon.
func _pic_subs() -> Control:
	var ring := Control.new()
	ring.custom_minimum_size = Vector2(92, 92)
	var icon := _picture(ART_SUBS, Vector2(44, 44))
	icon.position = Vector2(24, 24)
	ring.add_child(icon)
	ring.draw.connect(func():
		var c := Vector2(46, 46)
		ring.draw_arc(c, 39, 0, TAU, 48, Color("2f3450"), 9.0, false)
		ring.draw_arc(c, 39, -PI / 2.0, -PI / 2.0 + TAU * 0.78, 48, GOLD, 9.0, false))
	return ring


## The gift pack: the package and the four weapons it can hold.
func _pic_gift() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(_picture(ART_PACKAGE, Vector2(96, 96)))
	var weapons := GridContainer.new()
	weapons.columns = 2
	weapons.add_theme_constant_override("h_separation", 3)
	weapons.add_theme_constant_override("v_separation", 3)
	weapons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for id in STEP_WEAPONS:
		var r := TextureRect.new()
		r.texture = HudStyle.weapon_icon(id)
		r.custom_minimum_size = Vector2(36, 36)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		weapons.add_child(r)
		picture_paths.append(HudStyle.WEAPON_ICON_ART)
	row.add_child(weapons)
	return row


# --- Slide 3: Missions -----------------------------------------------------------------------------

func _build_slide3() -> Control:
	var s := _slide("Slide3", 2, "slide3.title", "kicker.missions")
	# The HUD's own notebook page (MissionPage) with a ticked and an open mission line, at 3x.
	notebook_page = _sample_page()
	var holder := Control.new()
	holder.name = "NotebookHolder"
	holder.position = Vector2(SIDE, 214)
	holder.custom_minimum_size = Vector2(264, 270)
	s.add_child(holder)
	notebook_page.position = Vector2.ZERO
	notebook_page.scale = Vector2(1.5, 1.5)
	holder.add_child(notebook_page)
	picture_paths.append(MissionPage.PAGE_ART)

	var right := VBoxContainer.new()
	right.name = "PowerUps"
	right.position = Vector2(SIDE + 264 + 52, 252)
	right.size = Vector2(CONTENT_W - 264 - 52, 300)
	right.add_theme_constant_override("separation", 30)
	s.add_child(right)
	right.add_child(_text_label("slide3.missions", false, 23, INK, false, true))
	var icons := HBoxContainer.new()
	icons.add_theme_constant_override("separation", 22)
	right.add_child(icons)
	var names: Dictionary = screen_texts().get("power_ups", {}).get("names", {})
	for id in POWER_UPS:
		var fig := VBoxContainer.new()
		fig.add_theme_constant_override("separation", 8)
		fig.add_child(_picture(ART_POWER_UP % id, Vector2(96, 96)))
		var l := _label(String(names.get(id, "")), false, 19, INK, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fig.add_child(l)
		power_up_labels[id] = l
		icons.add_child(fig)
	return s


## The notebook page of the HUD, with the sample goals (their lines come from screen_texts.json).
func _sample_page() -> MissionPage:
	var page := MissionPage.new()
	page.visible = true
	page.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var y := MissionPage.PAD.y + MissionPage.HEADER_H
	for i in range(SAMPLE_GOALS.size()):
		var row := page._make_row(i, SAMPLE_GOALS[i])
		row.position = Vector2(MissionPage.MARGIN_X, y)
		page.add_child(row)
		page.rows.append(row)
		y += row.size.y + MissionPage.ROW_GAP
	return page


# --- Slide 4: Survive the stream -------------------------------------------------------------------

func _build_slide4() -> Control:
	var s := _slide("Slide4", 3, "slide4.title", "kicker.goal")
	var tl := Control.new()
	tl.name = "Timeline"
	tl.position = Vector2(SIDE, 218)
	tl.size = Vector2(CONTENT_W, 170)
	s.add_child(tl)
	var bar_y := 92.0
	# The bar: cyan to pink, red in the last minute (the last eighth).
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.85, 0.875, 1.0])
	grad.colors = PackedColorArray([CYAN, PINK, DANGER, DANGER])
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	gt.width = int(CONTENT_W)
	timeline_bar = TextureRect.new()
	timeline_bar.name = "Bar"
	timeline_bar.texture = gt
	timeline_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	timeline_bar.stretch_mode = TextureRect.STRETCH_SCALE
	timeline_bar.position = Vector2(0, bar_y)
	timeline_bar.size = Vector2(CONTENT_W, 18)
	tl.add_child(timeline_bar)
	# The last minute's dashed red box, and the gift packs above the bar.
	var zone := Control.new()
	zone.name = "LastMinute"
	zone.position = Vector2(CONTENT_W * 0.875, bar_y - 8)
	zone.size = Vector2(CONTENT_W * 0.125, 34)
	zone.draw.connect(func(): _draw_dashed_rect(zone, Rect2(Vector2.ZERO, zone.size), DANGER))
	tl.add_child(zone)
	for f in GIFT_AT:
		var p := _picture(ART_PACKAGE, Vector2(64, 64))
		p.position = Vector2(CONTENT_W * f - 32, bar_y - 66)
		tl.add_child(p)
		gift_packs.append(p)
	# The kaiju standing on the bar in the last minute, and its label.
	kaiju_picture = _picture(ART_KAIJU, Vector2(168, 168))
	var atlas := AtlasTexture.new()
	atlas.atlas = load(ART_KAIJU) as Texture2D
	atlas.region = Rect2(0, 0, 224, 224)
	kaiju_picture.texture = atlas
	kaiju_picture.size = Vector2(168, 168)  # a new texture resets the size
	kaiju_picture.position = Vector2(CONTENT_W - 168 + 18, bar_y - 160)
	tl.add_child(kaiju_picture)
	# The times: the run's minutes, built from numbers.
	for t in [[0.015, RUN_MINUTES], [0.5, RUN_MINUTES / 2], [0.875, 1]]:
		var l := _label("%d:00" % t[1], true, 16, MUTED, false)
		l.position = Vector2(CONTENT_W * t[0], bar_y + 28)
		tl.add_child(l)
		time_labels.append(l)
	kaiju_label = _text_label("slide4.kaiju", false, 29, DANGER, true)
	kaiju_label.position = Vector2(CONTENT_W * 0.875, bar_y + 56)
	tl.add_child(kaiju_label)

	# Go live (with the HUD's LIVE badge) and Don't show again, under it.
	var live := VBoxContainer.new()
	live.name = "GoLive"
	live.alignment = BoxContainer.ALIGNMENT_CENTER
	live.add_theme_constant_override("separation", 16)
	live.position = Vector2(SIDE, 478)
	live.size = Vector2(CONTENT_W, 150)
	s.add_child(live)
	start_button = Button.new()
	start_button.name = "StartButton"
	start_button.text = TrickList.text("button.start")
	start_button.custom_minimum_size = Vector2(340, 76)
	HudStyle.style_button(start_button)  # the shared button (T-446)
	start_button.add_theme_font_size_override("font_size", 44)
	var badge := (load(ART_LIVE) as Texture2D).get_image()
	badge.resize(badge.get_width() * 2, badge.get_height() * 2, Image.INTERPOLATE_NEAREST)
	start_button.icon = ImageTexture.create_from_image(badge)  # the LIVE badge at 2x
	start_button.add_theme_constant_override("h_separation", 18)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	text_labels["button.start"] = start_button
	picture_paths.append(ART_LIVE)
	live.add_child(start_button)
	dont_show_checkbox = CheckBox.new()
	dont_show_checkbox.name = "DontShowCheckbox"
	dont_show_checkbox.text = TrickList.text("checkbox.dont_show")
	dont_show_checkbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	HudStyle.style_checkbox(dont_show_checkbox, CHECK_BOX_SIZE)  # matches the shared button (T-446)
	dont_show_checkbox.add_theme_font_size_override("font_size", 24)
	text_labels["checkbox.dont_show"] = dont_show_checkbox
	live.add_child(dont_show_checkbox)
	return s


func _draw_dashed_rect(c: Control, r: Rect2, color: Color) -> void:
	var a := r.position
	var b := r.position + Vector2(r.size.x, 0)
	var d := r.position + r.size
	var e := r.position + Vector2(0, r.size.y)
	for seg in [[a, b], [b, d], [d, e], [e, a]]:
		c.draw_dashed_line(seg[0], seg[1], color, 2.0, 7.0)


# --- Shared pieces -----------------------------------------------------------------------------------

## A slide: its kicker ("2 / 4 · How you get stronger", in capitals) and headline.
func _slide(slide_name: String, index: int, title_key: String, kicker_key: String) -> Control:
	var s := Control.new()
	s.name = slide_name
	s.size = STAGE
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slides.append(s)
	var kicker_text := TrickList.text("kicker.pattern").replace("{n}", str(index + 1)) \
		.replace("{total}", str(SLIDE_COUNT)).replace("{topic}", TrickList.text(kicker_key))
	var kicker := _label(kicker_text, true, 14, CYAN, true)
	kicker.name = "Kicker"
	kicker.position = Vector2(SIDE, 56)
	s.add_child(kicker)
	kickers.append(kicker)
	var title := _text_label(title_key, false, 82, INK, true)
	title.name = "Title"
	title.add_theme_color_override("font_shadow_color", PINK)
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	title.position = Vector2(SIDE, 80)
	s.add_child(title)
	return s


func pixel_font() -> FontFile:
	if _pixel_font == null:
		_pixel_font = (load(PIXEL_FONT_PATH) as FontFile).duplicate() as FontFile
		_pixel_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_pixel_font.hinting = TextServer.HINTING_NONE
		_pixel_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return _pixel_font


## A label in the game's display font (Bangers) or the pixel font; `upper` shows it in capitals.
func _label(text: String, pixel: bool, size: int, color: Color, upper: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", pixel_font() if pixel else HudStyle.comic_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.uppercase = upper
	return l


## A label showing one text of the file (a dotted key), registered in text_labels.
## `pixel` picks the pixel font; a body paragraph (`body`) uses the default font, wrapped.
func _text_label(key: String, pixel: bool, size: int, color: Color, upper: bool, body := false) -> Label:
	var l: Label
	if body:
		l = Label.new()
		l.text = TrickList.text(key)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_size_override("font_size", size)
		l.add_theme_color_override("font_color", color)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.uppercase = upper
	else:
		l = _label(TrickList.text(key), pixel, size, color, upper)
	l.name = key.replace(".", "_")
	text_labels[key] = l
	return l


## A picture from the game's own art, at `size`, nearest-neighbour; its file is noted.
func _picture(path: String, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # before the texture, or its size is the minimum
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.texture = load(path) as Texture2D
	r.custom_minimum_size = size
	r.size = size
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture_paths.append(path)
	return r


## A clip in its framed box (the clip's sheet is loaded when the slide is first shown).
func _clip_box(clip_name: String, pos: Vector2, box_size: Vector2, border: int, pad_px := 0.0) -> Control:
	var box := Panel.new()
	box.name = "Clip_" + clip_name
	box.position = pos
	box.custom_minimum_size = box_size
	box.size = box_size
	box.add_theme_stylebox_override("panel", _box(Color("15172a"), 4, border, PLATE if border > 3 else LINE, 0, 0))
	var player := ClipPlayer.new()
	player.name = "Player"
	player.position = Vector2(border, border)
	player.size = box_size - Vector2(border, border) * 2.0
	player.set_clip(clip_name)
	box.add_child(player)
	if pad_px > 0.0:
		KeyPad.attach(player, pad_px)  # T-491: slide 2's clips show the live key pad
	clip_players.append(player)
	return box


## A flat panel: fill, corner radius, border, content margins and an optional solid drop edge.
func _box(fill: Color, radius: int, border: int, border_color: Color, margin_x: int, margin_y: int,
		edge := Color(0, 0, 0, 0), edge_h := 0) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.set_corner_radius_all(radius)
	b.set_border_width_all(border)
	b.border_color = border_color
	b.content_margin_left = margin_x
	b.content_margin_right = margin_x
	b.content_margin_top = margin_y
	b.content_margin_bottom = margin_y
	if edge_h > 0:
		b.shadow_color = edge
		b.shadow_offset = Vector2(0, edge_h)
		b.shadow_size = 0
	return b


## A soft coloured glow behind the slides (the draft's two radial gradients).
func _add_glow(centre: Vector2, glow_size: Vector2, color: Color, alpha: float) -> void:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(color, alpha), Color(color, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 128
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.size = glow_size
	r.position = centre - glow_size / 2.0
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(r)


## The screen texts file (the power-up names), read once.
func screen_texts() -> Dictionary:
	if _screen_texts.is_empty():
		var f := FileAccess.open(SCREEN_TEXTS, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
		if typeof(parsed) == TYPE_DICTIONARY:
			_screen_texts = parsed
	return _screen_texts
