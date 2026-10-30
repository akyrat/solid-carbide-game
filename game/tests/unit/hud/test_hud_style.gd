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
const ROLE_KEYS := ["font", "size", "color", "outline_color", "outline"]


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
		assert_has(["", "comic", "clock"], String(r.get("font", "")), "%s: font kind" % role_name)
		if r.has("color"):
			assert_true(r["color"] is Color, "%s: colour" % role_name)


func test_fonts_resolve() -> void:
	assert_not_null(HudStyle.comic_font())
	assert_eq(HudStyle.comic_font(), Hud.comic_font(), "the HUD's comic font is the style's")
	assert_eq(HudStyle.comic_font().antialiasing, TextServer.FONT_ANTIALIASING_NONE)
	assert_eq(HudStyle.comic_font().resource_path, "", "a copy, not the imported file")
	assert_eq(Array(HudStyle.clock_font().font_names), ["Consolas", "Courier New", "monospace"])
	assert_eq(HudStyle.clock_font().antialiasing, TextServer.FONT_ANTIALIASING_NONE)
	assert_ne(HudStyle.new_comic_font(), HudStyle.comic_font(), "the popups bake from their own copy")


## The values every script had before T-428 (read from master's code): nothing the player sees changed.
func test_values_are_the_ones_before_t428() -> void:
	var old := {
		"coins": [20, Color(1.0, 0.82, 0.25), Color(0.03, 0.03, 0.06), 6],
		"sub_goal": [20, Color(0.92, 0.95, 1.0), Color(0.03, 0.03, 0.06), 6],
		"weapon_count": [32, Color(1, 1, 1), Color(0, 0, 0), 8],
		"air_counter": [30, Color(1, 1, 1), Color(0, 0, 0), 8],
		"viewers_unit": [14, Color("#33e1ff"), Color(0.03, 0.03, 0.06), 6],
		"viewers_flight": [30, Color("#33e1ff"), Color(0.03, 0.03, 0.06), 6],
		"viewers_drop": [24, Color("#ff5010"), Color(0.03, 0.03, 0.06), 6],
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
	assert_eq(HudStyle.CLOCK_PANEL_COLOR, Color(0.04, 0.05, 0.08, 0.92))
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


## The scripts' old constant names point at the style.
func test_script_constants_are_the_styles() -> void:
	assert_eq(ComboHeat.STEPS, HudStyle.HEAT_STEPS)
	assert_eq(LikesFire.PALETTE, HudStyle.FIRE_PALETTE)
	assert_eq(ART.PALETTE, HudStyle.POPUP_PALETTE)
	assert_eq(ART.STYLES, HudStyle.POPUP_TEXT)
	assert_eq(BROKEN.PALETTE, HudStyle.BROKEN_PALETTE)
	assert_eq(KaijuHealthBar.FILL_COLOR, HudStyle.KAIJU_FILL)
	assert_eq(KaijuHealthBar.OUTLINE, HudStyle.KAIJU_OUTLINE)
	assert_eq(TimerClock.PANEL_COLOR, HudStyle.CLOCK_PANEL_COLOR)
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
	_assert_role(hud.viewers_counter.unit_label, "viewers_unit", hud.viewers_counter.color)
	_assert_role(hud.viewers_counter.number_label, "viewers_number")


func test_weapon_counts_use_the_style() -> void:
	var hud := _hud()
	var rack: Node = WeaponsScript.new()
	add_child_autofree(rack)
	rack.get_weapon(rack.weapons.keys()[0]).set_tier(3)
	hud.bind_weapons(rack)
	assert_false(hud.weapon_icons.rows.is_empty())
	for id in hud.weapon_icons.rows:
		_assert_role(hud.weapon_icons.rows[id].count, "weapon_count")


func test_viewers_number_follows_the_heat_steps() -> void:
	var hud := _hud()
	var vc := hud.viewers_counter
	var sizes: Array = vc.cfg.get("number_sizes", HudStyle.VIEWERS_NUMBER_SIZES)
	assert_eq(vc.number_label.get_theme_font_size("font_size"), int(sizes[0]))
	assert_eq(vc.number_label.get_theme_color("font_color"), vc.color)
	assert_eq(vc.number_label.get_theme_constant("outline_size"), int(HudStyle.role("viewers_number")["outline"]))


func test_flight_and_drop_use_the_style() -> void:
	var f := ViewersFlight.new()
	add_child_autofree(f)
	f.setup("+12K", HudStyle.VIEWERS_COLOR, Vector2.ZERO, func() -> Vector2: return Vector2.ZERO, 0.5, 90.0)
	_assert_role(f.label, "viewers_flight")
	var d := ViewersDrop.new()
	add_child_autofree(d)
	d.setup("-12K", HudStyle.VIEWERS_CRASH_COLOR, Vector2.ZERO, 0.9, 70.0)
	_assert_role(d, "viewers_drop")


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
