class_name TutorialSlides
extends Control
## The tutorial slides (tasks T-382, redrawn in T-485, made interactive in T-562; HUD and menus,
## Decisions, "Interactive tutorial slides"): six slides shown before the first run:
## 1 the content loop (four steps with the HUD's own pictures, then its closing line),
## 2 to 5 one slide per trick to practise (drift, alt drift, air spins, grind), each with its
## headline, its instruction and a practice window where the player drives the real car (T-561's
## practice session in a SubViewport) until the trick is done three times, and
## 6 survive the stream (the 4-minute timeline, Go live, Don't show again).
## A left and a right arrow move between them (slide 1 has no left arrow, slide 6 no right arrow),
## a Skip control at the top right jumps to slide 6 (slide 6 itself has none, T-568). It only shows the screen and sends
## start_pressed(dont_show_again); starting the run is the screen flow's job, counting the tricks
## is the practice session's.
##
## Keys (a proposal for the playtest; game/docs/hud-and-menus/tutorial-slides.md): on the trick
## slides W, A, S, D, Space and R belong to the practice window (it has the keyboard as soon as its
## slide shows) and the buttons can't take the focus there, so no key presses a button; only the
## Left and Right arrow keys change slides. On slides 1 and 6, Left/Right and A/D change slides and
## Enter or Space presses the focused button, as before.
##
## Every word comes from res://data/tutorial_text.json (TrickList.text; headlines and labels are
## stored in sentence case and shown in capitals here; T-559's `tutorial.*` keys). The slides are
## laid out on a 1280 x 720 stage that is scaled to fit the window.

signal start_pressed(dont_show_again: bool)

const SLIDE_COUNT := 6
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
const NIGHT := Color("0d0d1b")
const DOT_ON := BLUSH
const DOT_OFF := Color("4a4f6b")
## The arrows' triangle outline, in screen pixels (T-446: the shared button's outline colour).
const ARROW_OUTLINE := 3
## The "Don't show again" checkbox square, in screen pixels.
const CHECK_BOX_SIZE := 28
## The loop slide's first step's trick and last-but-one step's weapons (HudStyle.weapon_icon ids).
const STEP_TRICK := "extended_drift"
const STEP_WEAPONS: Array[String] = ["gun", "molotov", "bricks", "underglow"]
## The trick slides, in order: the text key's part (tutorial.trick.<key>) and the practice
## session's trick name (PracticeSession.TRICKS).
const TRICK_SLIDES: Array = [["drift", "drift"], ["altdrift", "alt_drift"], ["airspin", "air_spin"],
	["grind", "grind"]]
## The slide index of the first trick slide (the loop slide is 0, the last slide SLIDE_COUNT - 1).
const FIRST_TRICK_SLIDE := 1
## SEAM (T-561): the practice session's scene. A missing scene leaves the window an empty frame.
const PRACTICE_SCENE := "res://scenes/run/practice_session.tscn"
## The practice window on the stage and its frame. T-574 (the board, 2026-11-08): it spans the
## slide from side to side (the content width, between the arrows) at the same 400 height.
const WINDOW_POS := Vector2(SIDE, 214)
const WINDOW_SIZE := Vector2(CONTENT_W, 400)
const WINDOW_BORDER := 4
## T-574: the tutorial text (the instruction, and the grind's hint) is drawn in the game, along
## the window's bottom edge on a dark band, clear of the notebook (top left). Its side padding and the band's opacity (proposals for the playtest).
const CAPTION_PAD := 16.0
const CAPTION_BAND_ALPHA := 0.6
## Art the slides draw (all the game's own files).
const ART_SUBS := "res://art/hud/subs_icon.png"
const ART_PACKAGE := "res://art/gift_pack/package.png"
const ART_KAIJU := "res://art/kaiju/kaiju_s.png"
const ART_LIVE := "res://art/hud/live_badge.png"
const ART_TRICK := "res://art/tutorial/tricks/%s.png"
## The run's length in minutes and where the gift packs sit on the timeline (fractions).
const RUN_MINUTES := 4
## The kaiju's minute: the last one, from 3:00 (a fraction of the bar; T-521).
const KAIJU_FROM := 0.75
const GIFT_AT: Array[float] = [0.08, 0.25, 0.42, 0.60]

var current := 0
var slides: Array[Control] = []
var left_arrow: Button
var right_arrow: Button
var skip_button: Button
var start_button: Button
var dont_show_checkbox: CheckBox
## The stage every slide is drawn on (1280 x 720, scaled to the window).
var stage: Control
## Every label that shows one text from the file, key to the node (tests check each against
## the file; a Label shows it in capitals through `uppercase`, the text itself is the file's).
var text_labels: Dictionary = {}
## Each slide's kicker label.
var kickers: Array[Label] = []
## The loop slide's four steps' pictures; the last slide's timeline pieces.
var step_pictures: Array[Control] = []
var time_labels: Array[Label] = []
var gift_packs: Array[TextureRect] = []
var kaiju_picture: TextureRect
var kaiju_label: Label
var timeline_bar: TextureRect
## Every picture on the slides: the texture's file path, for the tests.
var picture_paths: Array[String] = []
## The practice scene to embed; tests point it at a stand-in before a trick slide first shows.
var practice_scene_path := PRACTICE_SCENE
## Per trick slide (index 0 to 3): the window's frame, its SubViewportContainer, the session
## (null until its slide first shows, and when the scene is missing). T-574 (the board): no
## success message over the window any more; the goal done, the practice session stamps a green
## check on its own notebook page (PracticeSession._show_stamp).
var practice_frames: Array[Control] = []
var practice_containers: Array[SubViewportContainer] = []
var practices: Array = [null, null, null, null]
var _dots: Array[ColorRect] = []
var _pixel_font: FontFile
var _missing_warned := false


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

	stage.add_child(_build_loop())
	for i in range(TRICK_SLIDES.size()):
		stage.add_child(_build_trick(i))
	stage.add_child(_build_last())
	_build_chrome()
	resized.connect(_fit)
	visibility_changed.connect(_apply_practice_state)
	_fit()
	show_slide(0)


## Scales and centres the 1280 x 720 stage in the window, the way the other screens scale. The
## practice windows render at the window's own pixels: each container is scaled back by 1/s and
## sized s times bigger, so the car is drawn sharp and framed as in the run at that height.
func _fit() -> void:
	if stage == null:
		return
	var s := UiScale.fit(size, STAGE) if size.x > 0.0 and size.y > 0.0 else 1.0  # the shared rule (T-494)
	stage.scale = Vector2(s, s)
	stage.position = ((size - STAGE * s) / 2.0).floor()
	var inner := WINDOW_SIZE - Vector2(WINDOW_BORDER, WINDOW_BORDER) * 2.0
	for c in practice_containers:
		c.scale = Vector2(1.0 / s, 1.0 / s)
		c.size = (inner * s).round()


## Shows slide `index` (0 to 5), shows or hides the arrows, runs only the showing slide's practice
## and puts the focus where it belongs.
func show_slide(index: int) -> void:
	current = clampi(index, 0, SLIDE_COUNT - 1)
	for i in range(slides.size()):
		slides[i].visible = i == current
	for i in range(_dots.size()):
		_dots[i].color = DOT_ON if i == current else DOT_OFF
		_dots[i].custom_minimum_size.x = 46 if i == current else 15
	left_arrow.visible = current > 0
	right_arrow.visible = current < SLIDE_COUNT - 1
	skip_button.visible = current < SLIDE_COUNT - 1  # Go live already starts the run (T-568)
	var on_trick := is_trick_slide()
	for b in [left_arrow, right_arrow, skip_button]:
		# On a trick slide the buttons are clicked only: none takes the focus, so Space never presses one.
		(b as Control).focus_mode = Control.FOCUS_NONE if on_trick else Control.FOCUS_ALL
	if on_trick:
		_ensure_practice(current - FIRST_TRICK_SLIDE)
	_apply_practice_state()
	if is_inside_tree():
		if on_trick:
			var owner_focus := get_viewport().gui_get_focus_owner()
			if owner_focus != null:
				owner_focus.release_focus()
		elif current == SLIDE_COUNT - 1:
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


## True while a trick slide (one with a practice window) shows.
func is_trick_slide(index: int = -1) -> bool:
	var i := current if index < 0 else index
	return i >= FIRST_TRICK_SLIDE and i < FIRST_TRICK_SLIDE + TRICK_SLIDES.size()


## Keys: Left and Right go back and forward on every slide. A and D do too on the loop slide and
## the last slide, but not on the trick slides, where they steer the practice car (as Space jumps
## and W and S drive). Only a fresh key press counts (a held key's echo does not).
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var code := (event as InputEventKey).keycode
	var letters := not is_trick_slide()
	if code == KEY_LEFT or (letters and code == KEY_A):
		previous_slide()
		get_viewport().set_input_as_handled()
	elif code == KEY_RIGHT or (letters and code == KEY_D):
		next_slide()
		get_viewport().set_input_as_handled()


# --- The practice windows -------------------------------------------------------------------------

## Builds trick slide `i`'s practice the first time its slide shows: T-561's scene in the window's
## SubViewport, set to its trick. Kept (paused) when the slide hides, so its count stays.
func _ensure_practice(i: int) -> void:
	if practices[i] != null:
		return
	if not ResourceLoader.exists(practice_scene_path):
		if not _missing_warned:
			_missing_warned = true
			push_warning("TutorialSlides: no practice scene at %s; the windows stay empty" % practice_scene_path)
		return
	var packed := load(practice_scene_path) as PackedScene
	if packed == null:
		return
	var session := packed.instantiate()
	session.name = "Practice"
	var viewport := practice_containers[i].get_child(0) as SubViewport
	viewport.add_child(session)
	practices[i] = session
	if session.has_method("setup"):
		session.setup(String(TRICK_SLIDES[i][1]))


## Runs the showing slide's practice with the keyboard, and pauses every other one (and all of them
## when the slides are hidden).
func _apply_practice_state() -> void:
	for i in range(practices.size()):
		var session = practices[i]
		if session == null or not is_instance_valid(session):
			continue
		var on := is_visible_in_tree() and current == FIRST_TRICK_SLIDE + i
		if session.has_method("set_focused"):
			session.set_focused(on)
		if on and session.has_method("start"):
			session.start()
		elif not on and session.has_method("pause"):
			session.pause()


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


# --- Slide 1: the content loop ---------------------------------------------------------------------

func _build_loop() -> Control:
	var s := _slide("Slide1", 0, "tutorial.loop.title", "")
	var column := VBoxContainer.new()
	column.name = "Column"
	column.position = Vector2(SIDE, 232)
	column.size = Vector2(CONTENT_W, 400)
	column.add_theme_constant_override("separation", 40)
	s.add_child(column)

	# The chain: four steps with chevrons between, the HUD's own pictures.
	var chain := HBoxContainer.new()
	chain.name = "Chain"
	chain.add_theme_constant_override("separation", 12)
	column.add_child(chain)
	var pics: Array[Control] = [_pic_trick(), _pic_subs(), _pic_gift(), _pic_repeat()]
	for i in range(4):
		step_pictures.append(pics[i])
		chain.add_child(_step(i + 1, pics[i]))
		if i < 3:
			chain.add_child(_chevron())

	var point := _text_label("tutorial.loop.point", false, 34, INK, false)
	point.name = "Point"
	point.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	point.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	point.custom_minimum_size = Vector2(CONTENT_W, 0)
	column.add_child(point)
	return s


## One step panel: its picture and its label (tutorial.loop.step<n>).
func _step(n: int, pic: Control) -> Control:
	var panel := PanelContainer.new()
	panel.name = "Step%d" % n
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(PANEL, 8, 2, LINE, 12, 18))
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(0, 104)
	holder.add_child(pic)
	col.add_child(holder)
	var title := _text_label("tutorial.loop.step%d" % n, false, 29, INK, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(180, 0)
	col.add_child(title)
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


## "Repeat": a loop arrow drawn in code, in the slides' pink (no picture of its own).
func _pic_repeat() -> Control:
	var c := Control.new()
	c.name = "Repeat"
	c.custom_minimum_size = Vector2(92, 92)
	c.draw.connect(func():
		var m := Vector2(46, 46)
		var r := 32.0
		var a0 := -PI * 0.35
		var a1 := a0 + TAU * 0.82
		c.draw_arc(m, r, a0, a1, 48, PINK, 9.0, false)
		var tip := m + Vector2(cos(a1), sin(a1)) * r
		var along := Vector2(-sin(a1), cos(a1))
		var out := Vector2(cos(a1), sin(a1))
		c.draw_colored_polygon(PackedVector2Array([tip + along * 16.0, tip + out * 14.0 - along * 4.0,
			tip - out * 14.0 - along * 4.0]), PINK))
	return c


# --- Slides 2 to 5: the tricks ----------------------------------------------------------------------

## Trick slide `i` (0 to 3): its headline, its instruction (and on the grind slide the Jump hint)
## on the left, the practice window on the right with the success message over it.
func _build_trick(i: int) -> Control:
	var key := String(TRICK_SLIDES[i][0])
	var s := _slide("Slide%d" % (FIRST_TRICK_SLIDE + i + 1), FIRST_TRICK_SLIDE + i,
		"tutorial.trick.%s.title" % key, "")
	# The practice window: a framed box, its SubViewport (the session goes in when the slide shows).
	var frame := Panel.new()
	frame.name = "PracticeWindow"
	frame.position = WINDOW_POS
	frame.size = WINDOW_SIZE
	frame.add_theme_stylebox_override("panel", _box(Color("15172a"), 4, WINDOW_BORDER, PLATE, 0, 0))
	s.add_child(frame)
	practice_frames.append(frame)
	var container := SubViewportContainer.new()
	container.name = "View"
	container.stretch = true
	container.position = Vector2(WINDOW_BORDER, WINDOW_BORDER)
	container.size = WINDOW_SIZE - Vector2(WINDOW_BORDER, WINDOW_BORDER) * 2.0
	frame.add_child(container)
	var viewport := SubViewport.new()
	viewport.name = "Viewport"
	viewport.handle_input_locally = true
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	container.add_child(viewport)
	practice_containers.append(container)

	# T-574: the tutorial text in the game: a dark band along the window's bottom edge, the
	# instruction (and the grind's hint) on it, outlined so it reads over the playground.
	var inner_w := WINDOW_SIZE.x - WINDOW_BORDER * 2.0
	var band := PanelContainer.new()
	band.name = "Instructions"
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_theme_stylebox_override("panel", _box(Color(BG, CAPTION_BAND_ALPHA), 0, 0, LINE,
		int(CAPTION_PAD), 10))
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 4)
	band.add_child(col)
	var text_w := inner_w - CAPTION_PAD * 2.0
	var instruction := _caption("tutorial.trick.%s.instruction" % key, 30, INK, text_w)
	instruction.name = "Instruction"
	col.add_child(instruction)
	if key == "grind":
		var hint := _caption("tutorial.grind_hint", 22, BLUSH, text_w)
		hint.name = "Hint"
		col.add_child(hint)
	# Anchored to the frame's bottom and growing upwards, so its height follows the wrapped lines.
	band.anchor_left = 0.0
	band.anchor_right = 1.0
	band.anchor_top = 1.0
	band.anchor_bottom = 1.0
	band.offset_left = WINDOW_BORDER
	band.offset_right = -WINDOW_BORDER
	band.offset_top = -WINDOW_BORDER
	band.offset_bottom = -WINDOW_BORDER
	band.grow_vertical = Control.GROW_DIRECTION_BEGIN
	frame.add_child(band)

	return s


# --- Slide 6: Survive the stream -------------------------------------------------------------------

func _build_last() -> Control:
	var s := _slide("Slide%d" % SLIDE_COUNT, SLIDE_COUNT - 1, "slide4.title", "kicker.goal")
	var tl := Control.new()
	tl.name = "Timeline"
	tl.position = Vector2(SIDE, 218)
	tl.size = Vector2(CONTENT_W, 170)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(tl)
	var bar_y := 92.0
	# The bar: cyan to pink, red in the last minute (the last quarter).
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, KAIJU_FROM - 0.03, KAIJU_FROM, 1.0])
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
	zone.position = Vector2(CONTENT_W * KAIJU_FROM, bar_y - 8)
	zone.size = Vector2(CONTENT_W * (1.0 - KAIJU_FROM), 34)
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
	for t in [[0.015, RUN_MINUTES], [0.5, RUN_MINUTES / 2], [KAIJU_FROM, 1]]:
		var l := _label("%d:00" % t[1], true, 16, MUTED, false)
		l.position = Vector2(CONTENT_W * t[0], bar_y + 28)
		tl.add_child(l)
		time_labels.append(l)
	kaiju_label = _text_label("slide4.kaiju", false, 29, DANGER, true)
	kaiju_label.position = Vector2(CONTENT_W * KAIJU_FROM, bar_y + 56)
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

## The kicker for slide `index`: kicker.pattern with its number, the total and the topic's text.
## A slide with no topic of its own (`topic_key` "", T-559 wrote topics for the last slide only)
## shows the pattern's number part alone ("2 / 6").
static func kicker_text(index: int, topic_key: String) -> String:
	var pattern := TrickList.text("kicker.pattern").replace("{n}", str(index + 1)) \
		.replace("{total}", str(SLIDE_COUNT))
	if topic_key != "":
		return pattern.replace("{topic}", TrickList.text(topic_key))
	var head := pattern.split("{topic}")[0].strip_edges()
	while head != "" and not (head.right(1) >= "0" and head.right(1) <= "9"):
		head = head.left(head.length() - 1).strip_edges()  # drop the separator before the topic
	return head


## A slide: its kicker ("6 / 6 · The goal", in capitals) and headline.
func _slide(slide_name: String, index: int, title_key: String, kicker_key: String) -> Control:
	var s := Control.new()
	s.name = slide_name
	s.size = STAGE
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slides.append(s)
	var kicker := _label(kicker_text(index, kicker_key), true, 14, CYAN, true)
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
func _text_label(key: String, pixel: bool, size: int, color: Color, upper: bool) -> Label:
	var l := _label(TrickList.text(key), pixel, size, color, upper)
	l.name = key.replace(".", "_")
	text_labels[key] = l
	return l


## A centred, outlined line of the file's text for the window's caption band (T-574), wrapped
## to `width`.
func _caption(key: String, font_size: int, color: Color, width: float) -> Label:
	var l := _text_label(key, false, font_size, color, false)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	l.add_theme_color_override("font_outline_color", HudStyle.DARK)
	l.add_theme_constant_override("outline_size", 8)
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
