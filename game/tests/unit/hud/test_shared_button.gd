extends GutTest
## Task T-446: one button style and feel across every player-facing screen (HUD and
## menus, Decisions, "One button style across the game"). The shared button is
## defined once in HudStyle (style_button, style_checkbox); every button on the six
## screens is it, its five states each look different, and its colours, font and
## outline are the HUD style sheet's.

const RunScene := preload("res://scenes/run/run.tscn")
const PauseScript := preload("res://scripts/ui/pause_screen.gd")
const STATES := ["normal", "hover", "focus", "pressed", "disabled"]
## The board's tools on the pause strip keep their own look (T-446 leaves them out).
const BOARD_TOOL_BUTTONS := ["SetMinButton", "SetMaxButton"]
var GARAGE_SAVE := RunPaths.file("test_shared_button_t446.json")


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(GARAGE_SAVE)


func _buttons(n: Node, out: Array = []) -> Array:
	if n is BaseButton:
		out.append(n)
	for c in n.get_children():
		_buttons(c, out)
	return out


## Every button of `root` is the shared one (board tools aside); returns how many there are.
func _all_shared(root: Node, screen_name: String) -> int:
	var count := 0
	for b in _buttons(root):
		if b.name in BOARD_TOOL_BUTTONS:
			continue
		if b is GiftCardClick:  # T-474: a gift card's see-through click area is no button plate
			continue
		assert_true(HudStyle.is_shared_button(b), "%s: %s is the shared button" % [screen_name, b.name])
		if b is CheckBox:
			assert_eq(b.get_meta("hud_button"), "checkbox", "%s: %s" % [screen_name, b.name])
		else:
			assert_eq(b.get_meta("hud_button"), "button", "%s: %s" % [screen_name, b.name])
			var normal := b.get_theme_stylebox("normal") as StyleBoxTexture
			assert_not_null(normal, "%s: %s has the plate" % [screen_name, b.name])
			if normal != null:
				assert_eq(normal.texture, HudStyle.button_plate("normal"), "%s: %s plate" % [screen_name, b.name])
		assert_eq(b.get_theme_font("font"), HudStyle.comic_font(), "%s: %s is in Bangers" % [screen_name, b.name])
		count += 1
	gut.p("%s: %d shared buttons" % [screen_name, count])
	return count


## Two colours equal to 8 bits (an image stores 0 to 255 per channel).
func _close(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.005 and absf(a.g - b.g) < 0.005 and absf(a.b - b.b) < 0.005 and absf(a.a - b.a) < 0.005


# ------------------------------------------------------------ every screen

func test_main_menu_buttons_are_shared() -> void:
	var menu: MainMenu = load("res://scenes/menu/main_menu.tscn").instantiate()
	add_child_autofree(menu)
	assert_eq(_all_shared(menu, "main menu"), 3)


func test_garage_buttons_are_shared() -> void:
	DirAccess.remove_absolute(GARAGE_SAVE)
	var progress := PlayerProgress.new(null, GARAGE_SAVE)
	var screen: GarageScreen = load("res://scenes/menu/garage_screen.tscn").instantiate()
	screen.progress = progress
	add_child_autofree(screen)
	assert_eq(_all_shared(screen, "garage"), GarageData.UPGRADES.size() + 1, "a Buy per upgrade and Back")


func test_tutorial_slide_buttons_are_shared() -> void:
	var slides: TutorialSlides = load("res://scenes/menu/tutorial_slides.tscn").instantiate()
	add_child_autofree(slides)
	assert_eq(_all_shared(slides, "tutorial slides"), 5, "two arrows, Skip, Go live and the checkbox")
	assert_eq(slides.dont_show_checkbox.get_meta("hud_button"), "checkbox")


func test_level_up_and_pause_buttons_are_shared() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	var pause: CanvasLayer = PauseScript.new()
	run.add_child(pause)
	pause.setup(run)
	run.state.add_xp(run.state.xp_needed())
	run.gift_drops.pick_up_all()
	var screen: CanvasLayer = run.level_up_screen
	screen.skip_animation()
	assert_gt(screen.cards.size(), 0)
	assert_eq(_all_shared(screen, "level-up"), 0, "T-474: no Take it buttons, the cards are clicked")
	# Pause: Trick list, Edit HUD layout (T-453), Restart, Exit, the trick list's Back, the two
	# camera checkboxes, T-508's Rain checkbox, T-518's Drift Guide checkbox, and the HUD layout editor's Reset layout and Done (T-453).
	# T-505: and the God mode page's Back and a - and + on each of its rows (the entry itself
	# only exists once God mode is unlocked). Combined count: 11 (9 plus T-508's Rain and T-518's Drift Guide checkboxes)
	# plus T-505's God mode page buttons.
	var god_page_buttons: int = 1 + 2 * pause.god_mode_page.rows.size()
	assert_eq(_all_shared(pause, "pause"), 11 + god_page_buttons)


func test_recap_buttons_are_shared() -> void:
	var screen: RecapScreen = load("res://scenes/menu/recap_screen.tscn").instantiate()
	add_child_autofree(screen)
	screen.show_summary({"result": "win", "loss_reason": "", "time_survived": 300.0, "coins": 4,
		"likes": 9, "level": 2, "enemies_slain": {"minion": 3}, "tricks": {}, "highest_combo": 1.0,
		"weapons": {}})
	assert_eq(_all_shared(screen, "recap"), 2, "Continue and the X")


# ------------------------------------------------------------ the five states

func _styled() -> Button:
	var b := Button.new()
	b.text = "Start"
	add_child_autofree(b)
	HudStyle.style_button(b)
	return b


## A state's look, as one comparable value: its box (texture, tint, text offset or
## ring) and its text colour.
func _look(b: Button, state: String) -> Array:
	var box := b.get_theme_stylebox(state)
	var font_key: String = {"normal": "font_color", "hover": "font_hover_color", "focus": "font_focus_color",
		"pressed": "font_pressed_color", "disabled": "font_disabled_color"}[state]
	var look := [b.get_theme_color(font_key)]
	if box is StyleBoxTexture:
		look += [box.texture, box.content_margin_top]
	return look


func test_the_five_states_each_look_different() -> void:
	var b := _styled()
	var looks := {}
	for s in STATES:
		looks[s] = _look(b, s)
	for i in STATES.size():
		for j in range(i + 1, STATES.size()):
			assert_ne(looks[STATES[i]], looks[STATES[j]], "%s differs from %s" % [STATES[i], STATES[j]])
	# The feel: pressed is the sunk plate with the text 2 px lower; hovered lights the plate up.
	var normal := b.get_theme_stylebox("normal") as StyleBoxTexture
	var pressed := b.get_theme_stylebox("pressed") as StyleBoxTexture
	var hover := b.get_theme_stylebox("hover") as StyleBoxTexture
	var disabled := b.get_theme_stylebox("disabled") as StyleBoxTexture
	assert_eq(pressed.texture, HudStyle.button_plate("pressed"))
	assert_eq(pressed.content_margin_top - normal.content_margin_top, float(HudStyle.BUTTON_PRESS_DROP))
	assert_eq(pressed.content_margin_bottom - normal.content_margin_bottom, -float(HudStyle.BUTTON_PRESS_DROP))
	# T-447: every state is its own plate picture, no tint.
	for s in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := b.get_theme_stylebox(s) as StyleBoxTexture
		assert_eq(box.texture, HudStyle.button_plate(s), "%s plate" % s)
		assert_eq(box.modulate_color, Color.WHITE, "%s: no tint" % s)
	assert_eq(hover.texture, HudStyle.button_plate("hover"))
	assert_eq(disabled.texture, HudStyle.button_plate("disabled"))
	var h := hover.texture.get_image().get_pixelv(hover.texture.get_size() / 2)
	var n0 := normal.texture.get_image().get_pixelv(normal.texture.get_size() / 2)
	var d := disabled.texture.get_image().get_pixelv(disabled.texture.get_size() / 2)
	assert_gt(h.get_luminance(), n0.get_luminance(), "hovered is brighter")
	assert_lt(d.get_luminance(), n0.get_luminance(), "disabled is darker")
	var ring := b.get_theme_stylebox("focus") as StyleBoxTexture
	assert_not_null(ring, "keyboard selection is a ring plate over the state's plate")
	assert_eq(ring.texture.get_image().get_pixelv(ring.texture.get_size() / 2).a, 0.0, "open in the middle")


func test_the_states_render_differently() -> void:
	# The plate's pixels: normal against pressed, and the tints applied.
	var n := HudStyle.button_plate("normal").get_image()
	var p := HudStyle.button_plate("pressed").get_image()
	assert_eq(n.get_size(), Vector2i(72, 22) * HudStyle.HUD_ART_SCALE, "the plate at 2x")
	var mid := n.get_size() / 2
	assert_ne(n.get_pixelv(mid), p.get_pixelv(mid), "the pressed face is darker")
	assert_lt(p.get_pixelv(mid).get_luminance(), n.get_pixelv(mid).get_luminance())


func test_colours_font_and_outline_come_from_the_hud_style_sheet() -> void:
	var b := _styled()
	assert_eq(b.get_theme_font("font"), HudStyle.comic_font(), "Bangers")
	assert_eq(b.get_theme_font_size("font_size"), HudStyle.BUTTON_SIZE)
	assert_eq(b.get_theme_color("font_color"), HudStyle.LABEL_COLOR)
	assert_eq(b.get_theme_color("font_hover_color"), HudStyle.WHITE)
	assert_eq(b.get_theme_color("font_focus_color"), HudStyle.WHITE)
	assert_eq(b.get_theme_color("font_outline_color"), HudStyle.OUTLINE_COLOR)
	assert_eq(b.get_theme_constant("outline_size"), 6, "the sheet's text outline (rule 2)")
	assert_eq(HudStyle.BUTTON_SIZE % 2, 0, "even text size (rule 1)")
	assert_eq(HudStyle.BUTTON_SMALL_SIZE % 2, 0)
	# The plate's colours are the sheet's: its outline near-black and no Greenbull green (rule 6).
	var img := HudStyle.button_plate("normal").get_image()
	var greenbull := [Color8(104, 220, 96), Color8(247, 208, 52), Color8(12, 76, 44)]
	var has_outline := false
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			assert_false(c in greenbull, "no Greenbull colour at %d, %d" % [x, y])
			if _close(c, HudStyle.OUTLINE_COLOR):
				has_outline = true
	assert_true(has_outline, "the plate has the sheet's near-black outline")


func test_the_plate_is_a_9_slice_at_2x() -> void:
	var box := HudStyle.button_box("normal")
	assert_eq(box.texture_margin_left, 6.0)
	assert_eq(box.texture_margin_top, 6.0)
	assert_eq(box.texture_margin_bottom, 6.0)
	assert_eq(box.axis_stretch_horizontal, StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH)


func test_text_and_actions_are_unchanged() -> void:
	var b := _styled()
	var hits := [0]
	b.pressed.connect(func(): hits[0] += 1)
	assert_eq(b.text, "Start")
	b.pressed.emit()
	assert_eq(hits[0], 1)
	assert_eq(b.focus_mode, Control.FOCUS_ALL, "the focus mode is left as it was")
	assert_eq(b.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND)


func test_checkbox_matches_the_button() -> void:
	var c := CheckBox.new()
	c.text = "Don't show again"
	add_child_autofree(c)
	HudStyle.style_checkbox(c, 28)
	assert_eq(c.get_theme_font("font"), HudStyle.comic_font())
	assert_eq(c.get_theme_color("font_color"), HudStyle.LABEL_COLOR)
	assert_eq(c.get_theme_color("font_hover_color"), HudStyle.WHITE)
	assert_eq((c.get_theme_stylebox("focus") as StyleBoxTexture).texture, HudStyle.button_plate("focus"), "the same keyboard ring")
	var off := c.get_theme_icon("unchecked").get_image()
	var on := c.get_theme_icon("checked").get_image()
	assert_eq(off.get_size(), Vector2i(28, 28))
	assert_true(_close(off.get_pixel(0, 0), HudStyle.CHECK_FRAME), "CHECK_FRAME")
	assert_true(_close(off.get_pixel(14, 14), HudStyle.CHECK_FILL), "CHECK_FILL")
	assert_true(_close(on.get_pixel(14, 14), HudStyle.CHECK_MARK), "CHECK_MARK")


func test_recap_close_padding_keeps_the_press_down() -> void:
	var b := _styled()
	HudStyle.button_padding(b, 6, 6)
	var normal := b.get_theme_stylebox("normal") as StyleBoxTexture
	var pressed := b.get_theme_stylebox("pressed") as StyleBoxTexture
	assert_eq(normal.content_margin_left, 6.0)
	assert_eq(pressed.content_margin_top - normal.content_margin_top, float(HudStyle.BUTTON_PRESS_DROP))
	# The shared boxes are not changed for the other buttons.
	var other := _styled()
	assert_eq((other.get_theme_stylebox("normal") as StyleBoxTexture).content_margin_left, float(HudStyle.BUTTON_CONTENT.x))
