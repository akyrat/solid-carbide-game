extends GutTest
## Task T-428 (goal G-008, "A consistent HUD"): the HUD reads its fonts, font
## sizes, font colours and outlines from one shared place, HudStyle
## (scripts/hud/hud_style.gd). These tests load the style, check the HUD's labels
## carry its values, pin the values to what the scripts had before T-428 (so the
## look is unchanged), and scan the HUD scripts for style literals left behind.

const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const WeaponsScript := preload("res://scripts/weapons/weapons.gd")
const PauseScript := preload("res://scripts/ui/pause_screen.gd")
const ART := preload("res://scripts/hud/trick_popup_art.gd")
const BROKEN := preload("res://scripts/hud/combo_broken_art.gd")
const HUD_DIR := "res://scripts/hud/"
const ROLE_KEYS := ["font", "size", "color", "outline_color", "outline", "caps"]


func _screen() -> SubViewport:
	var sv := SubViewport.new()
	sv.size = Vector2i(1152, 648)
	add_child_autofree(sv)
	return sv


func _hud() -> Hud:
	var hud: Hud = HUD_SCENE.instantiate()
	_screen().add_child(hud)
	return hud


## The label carries the role's font, size, colour and outline.
func _assert_role(control: Control, role_name: String, color: Variant = null) -> void:
	var r: Dictionary = HudStyle.role(role_name)
	var font := HudStyle.font_for(String(r.get("font", "")))
	if font != null:
		assert_eq(control.get_theme_font("font"), font, "%s: %s font" % [control.name, role_name])
	if r.has("size"):
		assert_eq(control.get_theme_font_size("font_size"), int(r["size"]), "%s: %s size" % [control.name, role_name])
	var c: Variant = color if color != null else r.get("color")
	if c != null:
		assert_eq(control.get_theme_color("font_color"), c as Color, "%s: %s colour" % [control.name, role_name])
	if r.has("outline_color"):
		assert_eq(control.get_theme_color("font_outline_color"), r["outline_color"] as Color,
			"%s: %s outline colour" % [control.name, role_name])
	if r.has("outline"):
		assert_eq(control.get_theme_constant("outline_size"), int(r["outline"]),
			"%s: %s outline width" % [control.name, role_name])


# ------------------------------------------------------------ the style itself

func test_style_loads_and_every_role_is_well_formed() -> void:
	assert_false(HudStyle.LABELS.is_empty())
	for role_name in HudStyle.LABELS:
		var r: Dictionary = HudStyle.LABELS[role_name]
		for k in r:
			assert_has(ROLE_KEYS, k, "%s: key %s" % [role_name, k])
		assert_has(["", "comic"], String(r.get("font", "")), "%s: font kind" % role_name)
		if r.has("color"):
			assert_true(r["color"] is Color, "%s: colour" % role_name)


func test_fonts_resolve() -> void:
	assert_not_null(HudStyle.comic_font())
	assert_eq(HudStyle.comic_font(), Hud.comic_font(), "the HUD's comic font is the style's")
	assert_eq(HudStyle.comic_font().antialiasing, TextServer.FONT_ANTIALIASING_NONE)
	assert_eq(HudStyle.comic_font().resource_path, "", "a copy, not the imported file")
	# T-429: no system font is left (the sheet's rule 6); every role is Bangers.
	var src := FileAccess.get_file_as_string("res://scripts/hud/hud_style.gd")
	assert_false(src.contains("Consolas") and src.contains("SystemFont"), "the Consolas clock font is gone")
	for role_name in HudStyle.LABELS:
		assert_eq(String(HudStyle.role(role_name).get("font", "")), "comic", role_name + " is in Bangers")
	assert_ne(HudStyle.new_comic_font(), HudStyle.comic_font(), "the popups bake from their own copy")


## The values every script had before T-428 (read from master's code): nothing the player sees changed.
func test_values_are_the_ones_before_t428() -> void:
	var old := {
		"coins": [20, Color(1.0, 0.82, 0.25), Color(0.03, 0.03, 0.06), 6],
		"sub_goal": [20, Color(0.92, 0.95, 1.0), Color(0.03, 0.03, 0.06), 6],
		"weapon_count": [32, Color(1, 1, 1), Color(0, 0, 0), 8],
		"air_counter": [30, Color(1, 1, 1), Color(0, 0, 0), 8],
		"multiplier_flight": [30, Color("#33e1ff"), Color(0.03, 0.03, 0.06), 6],
		"multiplier_drop": [24, Color("#ff5010"), Color(0.03, 0.03, 0.06), 6],
		"level_up_title": [40, Color8(246, 250, 232), Color8(14, 22, 18), 6],
	}
	for role_name in old:
		var r: Dictionary = HudStyle.role(role_name)
		var o: Array = old[role_name]
		assert_eq(int(r["size"]), o[0], role_name)
		assert_eq(r["color"], o[1], role_name)
		assert_eq(r["outline_color"], o[2], role_name)
		assert_eq(int(r["outline"]), o[3], role_name)
	assert_eq(HudStyle.size_of("clock_digits"), 52)
	assert_eq(HudStyle.role("clock_digits")["outline_color"], Color(0, 0, 0, 0.6))
	assert_eq(HudStyle.size_of("pause_title"), 28)
	assert_eq(HudStyle.size_of("pause_text"), 16)
	assert_eq(HudStyle.size_of("level_up_card_title"), 36)
	assert_eq(HudStyle.size_of("level_up_card_desc"), 24)
	assert_eq(HudStyle.size_of("level_up_button"), 30)
	assert_eq(HudStyle.HEAT_STEPS[0].color, Color(1.0, 0.25, 0.75))
	assert_eq(HudStyle.HEAT_STEPS[3].font_size, 50)
	assert_eq(HudStyle.KAIJU_FILL, Color(0.72, 0.18, 1.0))
	assert_eq(HudStyle.PAUSE_STRIP_COLOR, Color(0, 0, 0, 0.85))
	# T-429: the HUD style sheet's values.
	for role_name in ["coins", "pause_title", "pause_text"]:
		assert_eq(HudStyle.role(role_name)["font"], "comic", role_name + " is in Bangers")
	for step in HudStyle.HEAT_STEPS:
		assert_eq(int(step["outline"]), 8)
	var sheet_outline := Color8(8, 8, 15)
	assert_eq(HudStyle.KAIJU_LINE, HudStyle.OUTLINE_COLOR)
	for i in [1, 3, 12]:
		assert_eq(HudStyle.POPUP_PALETTE[i], sheet_outline)
	for i in [2, 4]:
		assert_eq(HudStyle.BROKEN_PALETTE[i], sheet_outline)
	assert_eq(HudStyle.POPUP_PALETTE[13], Color8(51, 225, 255))
	assert_eq(HudStyle.BROKEN_PALETTE[3], Color8(255, 80, 16))
	assert_eq(HudStyle.POPUP_TEXT["normal"]["font_px"], 32)
	# T-429, round 2: the clock art, the weapon icon sheet, the pause strip's capitals.
	assert_eq(HudStyle.HUD_ART_SCALE, 2)
	assert_eq(HudStyle.CLOCK_PANEL_ART, "res://art/hud/clock_panel.png")
	assert_eq(HudStyle.CLOCK_DIGIT_FRAME, Vector2i(16, 26))
	assert_eq(HudStyle.CLOCK_PANEL_CONTENT_MARGIN, 3)
	assert_eq(HudStyle.WEAPON_ICON_FRAME * HudStyle.HUD_ART_SCALE, 48, "the same 48 px slot")
	assert_eq(WeaponIcons.ICON_SIZE, 48)
	assert_true(HudStyle.role("pause_title")["caps"])
	assert_true(HudStyle.role("pause_text")["caps"])


## T-429: the clock is the panel art and the digit art at 2x, in the same 200 x 72 rect.
func test_clock_uses_the_panel_and_digit_art() -> void:
	var hud := _hud()
	var c := hud.timer_clock
	var box := c.get_theme_stylebox("panel") as StyleBoxTexture
	assert_not_null(box, "the panel is the art, not a drawn box")
	assert_eq(box.texture.resource_path, HudStyle.CLOCK_PANEL_ART)
	assert_eq(Vector2(box.texture.get_size()) * 2.0, Vector2(200, 72), "the art at exactly 2x fills the layout")
	assert_eq(box.get_content_margin(SIDE_LEFT), 3.0)
	assert_eq(c.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_eq(c.label.self_modulate.a, 0.0, "the label draws nothing")
	assert_true(c.digits is ClockDigits)
	assert_eq(c.digits.source, c.label)
	for ch in "0123456789:":
		var t := ClockDigits.frame_for(ch)
		assert_not_null(t, ch)
		assert_eq(Vector2i(t.get_size()), HudStyle.CLOCK_DIGIT_FRAME, ch)
	assert_null(ClockDigits.frame_for("x"))
	assert_eq(ClockDigits.text_size("4:00"), Vector2(128, 52), "four frames at 2x")
	c.set_time_left(10.0)
	assert_eq(c.digits.digit_color(), c.color_for(10.0), "the digits take the step's colour")
	var off := ClockDigits.off_color(Color(1, 0.5, 0))
	assert_almost_eq(off.r, 0.22, 0.001)
	assert_eq(off.a, 1.0)


func test_clock_digits_are_centred_on_whole_pixels() -> void:
	var d := ClockDigits.new()
	add_child_autofree(d)
	d.size = Vector2(194, 66)
	assert_eq(d.text_origin("4:00"), Vector2(33, 7))
	assert_eq(d.text_origin("10:00"), Vector2(17, 7))
	var l := Label.new()
	add_child_autofree(l)
	l.text = "7:42"
	l.add_theme_color_override("font_color", Color(1, 0, 0))
	d.source = l
	d.refresh()
	# 3 digits with their unlit 8 behind, and the colon: 7 frames, each 32 x 52.
	assert_eq(d.glyphs.size(), 7)
	assert_eq(d.glyphs[1].texture, ClockDigits.frame_for("7"))
	assert_eq(d.glyphs[1].self_modulate, Color(1, 0, 0))
	assert_eq(d.glyphs[0].self_modulate, ClockDigits.off_color(Color(1, 0, 0)), "the unlit 8 behind")
	assert_eq(d.glyphs[2].texture, ClockDigits.frame_for(":"))
	assert_eq(d.glyphs[1].size, Vector2(32, 52))
	assert_eq(d.glyphs[2].position, Vector2(33 + 32, 7))


## T-429: the pause strip's labels show in capitals; the text itself is the file's.
func test_pause_labels_are_in_capitals() -> void:
	var l := Label.new()
	add_child_autofree(l)
	l.text = "Paused"
	HudStyle.apply(l, "pause_title")
	assert_true(l.uppercase)
	assert_eq(l.text, "Paused", "the text is unchanged")
	var b := Button.new()
	add_child_autofree(b)
	HudStyle.apply(b, "pause_text")
	assert_eq(b.get_theme_font("font"), HudStyle.comic_font())
	var f := HudStyle.comic_font()
	assert_eq(f.get_string_size("Restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 16),
		f.get_string_size("RESTART", HORIZONTAL_ALIGNMENT_LEFT, -1, 16),
		"Bangers draws lowercase as capitals, so a button is in capitals too")


## The scripts' old constant names point at the style.
func test_script_constants_are_the_styles() -> void:
	assert_eq(ComboHeat.STEPS, HudStyle.HEAT_STEPS)
	assert_eq(LikesFire.PALETTE, HudStyle.FIRE_PALETTE)
	assert_eq(ART.PALETTE, HudStyle.POPUP_PALETTE)
	assert_eq(ART.STYLES, HudStyle.POPUP_TEXT)
	assert_eq(BROKEN.PALETTE, HudStyle.BROKEN_PALETTE)
	assert_eq(KaijuHealthBar.FILL_COLOR, HudStyle.KAIJU_FILL)
	assert_eq(KaijuHealthBar.OUTLINE, HudStyle.KAIJU_OUTLINE)
	assert_eq(TimerClock.DIGIT_FONT_SIZE, HudStyle.CLOCK_FONT_SIZE)
	assert_eq(SubGoal.FILL_COLOR, HudStyle.HEALTH_COLOR)
	assert_eq(SubGoal.GLOW_COLORS, HudStyle.SUB_GOAL_GLOW)
	assert_eq(PauseScript.STRIP_COLOR, HudStyle.PAUSE_STRIP_COLOR)
	assert_eq(PauseScript.CONTROL_FRAME, HudStyle.PAUSE_CONTROL_FRAME)
	assert_eq(LevelUpScreen.TITLE_SIZE, HudStyle.LEVEL_UP_TITLE_SIZE)
	assert_eq(LevelUpScreen.DIM, HudStyle.LEVEL_UP_DIM)


# ------------------------------------------------------------ the HUD's labels use it

func test_hud_labels_use_the_style() -> void:
	var hud := _hud()
	_assert_role(hud.coins_label, "coins")
	_assert_role(hud.coins_value_label, "coins")
	_assert_role(hud.timer_label, "clock_digits")
	_assert_role(hud.sub_goal.label, "sub_goal")
	_assert_role(hud.airtime_counter.number_label, "air_counter")
	_assert_role(hud.drift_counter.number_label, "air_counter")
	_assert_role(hud.multiplier_tag.number_label, "multiplier_number")


func test_weapon_counts_use_the_style() -> void:
	var hud := _hud()
	var rack: Node = WeaponsScript.new()
	add_child_autofree(rack)
	rack.get_weapon(rack.weapons.keys()[0]).set_tier(3)
	hud.bind_weapons(rack)
	assert_false(hud.weapon_icons.rows.is_empty())
	for id in hud.weapon_icons.rows:
		_assert_role(hud.weapon_icons.rows[id].count, "weapon_count")


func test_multiplier_number_follows_the_heat_steps() -> void:
	var hud := _hud()
	var vc := hud.multiplier_tag
	var sizes: Array = vc.cfg.get("number_sizes", HudStyle.MULTIPLIER_NUMBER_SIZES)
	assert_eq(vc.number_label.get_theme_font_size("font_size"), int(sizes[0]))
	assert_eq(vc.number_label.get_theme_color("font_color"), vc.color)
	assert_eq(vc.number_label.get_theme_constant("outline_size"), int(HudStyle.role("multiplier_number")["outline"]))


func test_flight_and_drop_use_the_style() -> void:
	var f := MultiplierFlight.new()
	add_child_autofree(f)
	f.setup("+12K", HudStyle.MULTIPLIER_COLOR, Vector2.ZERO, func() -> Vector2: return Vector2.ZERO, 0.5, 90.0)
	_assert_role(f.label, "multiplier_flight")
	var d := MultiplierDrop.new()
	add_child_autofree(d)
	d.setup("-12K", HudStyle.MULTIPLIER_CRASH_COLOR, Vector2.ZERO, 0.9, 70.0)
	_assert_role(d, "multiplier_drop")


func test_heat_look_on_a_label() -> void:
	var l := Label.new()
	add_child_autofree(l)
	for st in HudStyle.HEAT_STEPS:
		HudStyle.apply_heat(l, st)
		assert_eq(l.get_theme_font_size("font_size"), int(st.font_size))
		assert_eq(l.get_theme_color("font_color"), st.color as Color)
		assert_eq(l.get_theme_color("font_outline_color"), HudStyle.DARK)
		assert_eq(l.get_theme_constant("outline_size"), int(st.outline))
		assert_eq(l.get_theme_constant("shadow_outline_size"), int(st.glow))
		assert_eq(l.get_theme_color("font_shadow_color"), HudStyle.glow_color(st, 0))
	assert_eq(HudStyle.glow_color(HudStyle.HEAT_STEPS[0], 0), HudStyle.NO_GLOW)


func test_button_colour_covers_its_states() -> void:
	var b := Button.new()
	add_child_autofree(b)
	HudStyle.apply(b, "level_up_button")
	for n in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		assert_eq(b.get_theme_color(n), HudStyle.BLACK, n)
	assert_eq(b.get_theme_font("font"), HudStyle.comic_font())


# ------------------------------------------------------------ no literals left

## No HUD script outside HudStyle sets a font size, font or outline colour, or an
## outline width from a literal number or colour.
func test_no_style_literals_in_hud_scripts() -> void:
	var re := RegEx.new()
	re.compile("add_theme_(color_override|font_size_override)\\(\"[a-z_]+\",\\s*(Color8?\\(|-?[0-9])"
		+ "|add_theme_constant_override\\(\"(outline_size|shadow_outline_size)\",\\s*-?[0-9]")
	var files: Array[String] = []
	for f in DirAccess.get_files_at(HUD_DIR):
		if f.ends_with(".gd") and f != "hud_style.gd":
			files.append(HUD_DIR + f)
	files.append("res://scripts/ui/pause_screen.gd")
	files.append("res://scripts/ui/level_up_screen.gd")
	assert_gt(files.size(), 10)
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		var lines := text.split("\n")
		for i in lines.size():
			assert_null(re.search(lines[i]), "%s:%d %s" % [path, i + 1, lines[i].strip_edges()])
