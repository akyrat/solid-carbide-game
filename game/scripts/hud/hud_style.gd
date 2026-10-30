class_name HudStyle
extends RefCounted
## The HUD's one shared style place (task T-428, goal G-008 "A consistent HUD";
## HUD and menus, Decisions): every font, font size, font colour, outline colour
## and width and panel colour the HUD and its two screens (pause, level-up) use.
## The HUD scripts read their look from here and keep no style literals of their
## own: a label gets its look with `HudStyle.apply(label, "<role>")`, and the
## drawn pieces (popups, flames, kaiju bar, clock panel, pause strip) read the
## constants below, which the scripts' own old constant names point at.
##
## The values are the ones each script had before T-428, so nothing on screen
## changed. The HUD style sheet in Visual style (the Asset Generation ticket
## after T-428) decides the new values; a later UI ticket sets them here.
##
## It refers to no other HUD script (every HUD script reads it), so it can be
## loaded first, by tests too.

# ---------------------------------------------------------------- fonts

## The comic font (Bangers, T-084): the popups, the counters and the level-up screen.
const COMIC_FONT_PATH := "res://fonts/bangers/Bangers-Regular.ttf"
## No system font any more (T-429, the HUD style sheet's rule 6): the clock's
## digits are the drawn seven-segment art below (ClockDigits), and its
## (undrawn) label keeps Bangers for its measures.

# ---------------------------------------------------------------- HUD art

## The HUD style sheet's pixel scale (rule 1): one art pixel is two screen pixels.
const HUD_ART_SCALE := 2
## The clock panel art (T-339): 100 x 36, shown at 2x = the layout's 200 x 72.
const CLOCK_PANEL_ART := "res://art/hud/clock_panel.png"
## Its content margin: the 3 screen pixels the old drawn border kept, so the
## label's rect inside the panel is unchanged.
const CLOCK_PANEL_CONTENT_MARGIN := 3
## The clock's digit frames (T-339): `%s` is 0 to 9, "colon" or "off" (the unlit 8).
const CLOCK_DIGIT_ART := "res://art/hud/clock_digit_%s.png"
const CLOCK_DIGIT_FRAME := Vector2i(16, 26)
## The unlit 8's shade: the time step's colour times this, fully opaque.
const CLOCK_DIGIT_OFF_SHADE := 0.22
## The weapon column's icons (T-429): one row sheet of 24 x 24 frames, shown at
## 2x in the 48 px slot, in this order.
const WEAPON_ICON_ART := "res://art/hud/weapon_icons.png"
const WEAPON_ICON_FRAME := 24
const WEAPON_ICON_ORDER: Array[String] = ["gun", "flamethrower", "molotov", "bricks", "wiper", "underglow"]

# ---------------------------------------------------------------- shared colours

## The HUD's label size (the coins, the sub goal), light label text and its near-black outline (T-090).
const LABEL_FONT_SIZE := 20
const LABEL_OUTLINE := 6
const LABEL_COLOR := Color(0.92, 0.95, 1.0)
const OUTLINE_COLOR := Color(0.03, 0.03, 0.06)
## The near-black of the heat steps' and the viewers counter's outlines (= OUTLINE_COLOR).
const DARK := OUTLINE_COLOR
const WHITE := Color(1.0, 1.0, 1.0)
const BLACK := Color(0.0, 0.0, 0.0)
## No glow: a fully transparent shadow.
const NO_GLOW := Color(0, 0, 0, 0)
## The coins counter (T-090).
const COINS_COLOR := Color(1.0, 0.82, 0.25)
## The HUD's green (the old health bar's, not Greenbull's light green): the sub goal's fill.
const HEALTH_COLOR := Color(0.25, 0.85, 0.45)
const HEALTH_TOP_COLOR := Color(0.62, 1.0, 0.72)
## The likes heart's red (Visual style, Decisions, "Red after the rebrand"): the heart only.
const HEART_COLOR := Color(0.86, 0.1, 0.16)
## The live viewers counter's colours (T-336). data/hud.json (viewers_counter.color,
## crash_color) can set them; these are the values when it doesn't.
const VIEWERS_COLOR := Color("#33e1ff")
const VIEWERS_CRASH_COLOR := Color("#ff5010")

# ---------------------------------------------------------------- label roles

## The sizes and outlines other scripts name too (their old constants point here).
const CLOCK_FONT_SIZE := 52
const WEAPON_COUNT_SIZE := 32
const WEAPON_COUNT_OUTLINE := 8
const AIR_COUNTER_SIZE := 30
const VIEWERS_UNIT_SIZE := 14
## The viewers number's size per heat step when data/hud.json (viewers_counter.number_sizes) has none.
const VIEWERS_NUMBER_SIZES := [28, 30, 32, 34]
const VIEWERS_FLIGHT_SIZE := 30
const VIEWERS_DROP_SIZE := 24
const LEVEL_UP_TITLE_SIZE := 40
const LEVEL_UP_CARD_TITLE_SIZE := 36
const LEVEL_UP_CARD_DESC_SIZE := 24
const LEVEL_UP_BUTTON_SIZE := 30
const LEVEL_UP_TITLE_CREAM := Color8(246, 250, 232)
const LEVEL_UP_TITLE_OUTLINE := Color8(14, 22, 18)
const LEVEL_UP_TITLE_OUTLINE_SIZE := 6

## Each label's look: `font` ("comic", or "" for the theme's default),
## `size` (font size), `color` (font colour), `outline_color` and `outline`
## (outline width), `caps` (a Label shown in capitals, the sheet's rule 5; the
## text itself is unchanged, and Bangers draws a Button's lowercase as capitals
## anyway). A key left out is not set (the script sets it as it changes:
## the clock's colour per time step, the viewers number's size per heat step).
const LABELS := {
	# The coins counter's two labels (T-090, T-341): the default font.
	"coins": {"font": "comic", "size": LABEL_FONT_SIZE, "color": COINS_COLOR, "outline_color": OUTLINE_COLOR, "outline": LABEL_OUTLINE},
	# The clock's label (T-335); the colour comes from data/hud.json, timer_clock.steps.
	# ClockDigits draws its text in the digit art (T-429); the label itself draws nothing.
	"clock_digits": {"font": "comic", "size": CLOCK_FONT_SIZE, "outline_color": Color(0, 0, 0, 0.6), "outline": 6},
	# The sub goal's "42 / 156 SUBS" (T-337).
	"sub_goal": {"font": "comic", "size": LABEL_FONT_SIZE, "color": LABEL_COLOR, "outline_color": OUTLINE_COLOR, "outline": LABEL_OUTLINE},
	# A weapon's "x3" (T-276).
	"weapon_count": {"font": "comic", "size": WEAPON_COUNT_SIZE, "color": WHITE, "outline_color": BLACK, "outline": WEAPON_COUNT_OUTLINE},
	# The airtime and drift counters' numbers (T-243, T-247).
	"air_counter": {"font": "comic", "size": AIR_COUNTER_SIZE, "color": WHITE, "outline_color": BLACK, "outline": 8},
	# The live viewers counter's number (T-336): its size and colour follow the heat step.
	"viewers_number": {"font": "comic", "outline_color": DARK, "outline": 8},
	# "WATCHING" under it, in the viewers colour.
	"viewers_unit": {"font": "comic", "size": VIEWERS_UNIT_SIZE, "color": VIEWERS_COLOR, "outline_color": DARK, "outline": 6},
	# A trick's "+12K" flying into the counter, in the viewers colour.
	"viewers_flight": {"font": "comic", "size": VIEWERS_FLIGHT_SIZE, "color": VIEWERS_COLOR, "outline_color": DARK, "outline": 6},
	# A crash's "-12K" dropping off the counter, in the crash colour.
	"viewers_drop": {"font": "comic", "size": VIEWERS_DROP_SIZE, "color": VIEWERS_CRASH_COLOR, "outline_color": DARK, "outline": 6},
	# The pause strip (T-015, T-124): Bangers in capitals (T-429), the theme's colours.
	"pause_title": {"font": "comic", "size": 28, "caps": true},
	"pause_text": {"font": "comic", "size": 16, "caps": true},
	# The level-up screen (T-141, T-310): black Bangers on the cream cards, the
	# ribbon title cream with the art's dark outline.
	"level_up_title": {"font": "comic", "size": LEVEL_UP_TITLE_SIZE, "color": LEVEL_UP_TITLE_CREAM,
		"outline_color": LEVEL_UP_TITLE_OUTLINE, "outline": LEVEL_UP_TITLE_OUTLINE_SIZE},
	"level_up_card_title": {"font": "comic", "size": LEVEL_UP_CARD_TITLE_SIZE, "color": BLACK},
	"level_up_card_desc": {"font": "comic", "size": LEVEL_UP_CARD_DESC_SIZE, "color": BLACK},
	"level_up_button": {"font": "comic", "size": LEVEL_UP_BUTTON_SIZE, "color": BLACK},
}

## The combo's heat looks (T-131), base step first: font size, colour, outline
## width, the glow ring (width and colours, flickering when several) and the pulse.
## The viewers counter's number and the popups' rings follow the same steps.
const HEAT_STEPS: Array[Dictionary] = [
	{"font_size": 30, "color": Color(1.0, 0.25, 0.75), "outline": 8,
		"glow": 0, "glow_colors": [], "pulse": 0.0, "pulse_hz": 0.0},
	{"font_size": 36, "color": Color(1.0, 0.86, 0.25), "outline": 8,
		"glow": 0, "glow_colors": [], "pulse": 0.06, "pulse_hz": 1.2},
	{"font_size": 42, "color": Color(1.0, 0.62, 0.12), "outline": 8,
		"glow": 18, "glow_colors": [Color(1.0, 0.86, 0.25)], "pulse": 0.10, "pulse_hz": 2.0},
	{"font_size": 50, "color": Color(1.0, 0.98, 0.82), "outline": 8,
		"glow": 22, "glow_colors": [Color(1.0, 0.6, 0.08), Color(1.0, 0.72, 0.16), Color(1.0, 0.86, 0.25)],
		"pulse": 0.14, "pulse_hz": 3.0},
]

# ---------------------------------------------------------------- drawn pieces

## The sub goal square's flames and the fire's colours (T-131), hottest first.
const FIRE_PALETTE: Array[Color] = [
	Color(1.0, 0.98, 0.82),  # white-hot
	Color(1.0, 0.88, 0.3),   # yellow
	Color(1.0, 0.72, 0.16),  # orange-yellow
	Color(1.0, 0.6, 0.08),   # orange
]
## The sub goal's celebration glow (T-337): white, pale mint, the fill's green.
const SUB_GOAL_GLOW: Array[Color] = [WHITE, HEALTH_TOP_COLOR, HEALTH_COLOR]

## The trick popups' baked palette (T-084, T-133, T-336), by index: transparent,
## letters, the white fill, its border, the heat rings, the hot amount, the four
## flame colours, the plain amount, the viewers amount.
const POPUP_PALETTE := [
	Color(0, 0, 0, 0),
	Color8(8, 8, 15),       # letters (the sheet's outline colour)
	Color8(255, 255, 255),  # burst fill
	Color8(8, 8, 15),       # burst border
	Color8(255, 224, 77),   # step 1 ring: yellow (LikesFire; the HUD counter is yellow at step 1)
	Color8(255, 153, 20),   # step 2 and 3 ring: orange (LikesFire)
	Color8(255, 224, 77),   # step 2 and 3 inner ring: yellow (LikesFire)
	Color8(255, 153, 20),   # step 2 and 3 "+amount": orange
	Color8(255, 250, 209),  # flame: white-hot (LikesFire.PALETTE)
	Color8(255, 224, 77),   # flame: yellow
	Color8(255, 184, 41),   # flame: orange-yellow
	Color8(255, 153, 20),   # flame: orange
	Color8(8, 8, 15),       # "+amount" at heat 0 and 1
	Color8(51, 225, 255),   # the viewers amount: the viewers colour (hud.json viewers_counter.color)
]
## The popups' lettering per size style: font pixel size, text outline and shadow
## (none: black letters on white need none).
const POPUP_TEXT := {
	"normal": {"font_px": 32, "outline": 0, "shadow": 0},
	"small": {"font_px": 20, "outline": 0, "shadow": 0},
}
## The combo broken popup's baked palette (T-245): transparent, white letters,
## their black outline, the warning red-orange card, its black border.
const BROKEN_PALETTE := [
	Color(0, 0, 0, 0),
	Color8(255, 255, 255),  # letters
	Color8(8, 8, 15),       # letter outline
	Color8(255, 80, 16),    # card: warning red-orange
	Color8(8, 8, 15),       # border and crack edges
]

## The kaiju's health bar (T-050): neon purple on white, black outline and dividers.
const KAIJU_FILL := Color(0.72, 0.18, 1.0)
const KAIJU_BACK := Color.WHITE
const KAIJU_LINE := OUTLINE_COLOR
const KAIJU_OUTLINE := 2.0

## The pause strip (T-015, T-124): its background, the dim over the run, and
## the placeholder controls' frame and fills.
const PAUSE_STRIP_COLOR := Color(0, 0, 0, 0.85)
const PAUSE_DIM := Color(0, 0, 0, 0.2)
const PAUSE_CONTROL_FRAME := Color(0.85, 0.85, 0.85)
const PAUSE_CONTROL_FILL := Color(0.16, 0.16, 0.16)
const PAUSE_CONTROL_FILL_HOVER := Color(0.28, 0.28, 0.28)
const PAUSE_CONTROL_FILL_PRESSED := Color(0.08, 0.08, 0.08)
const PAUSE_FOCUS := Color(1, 1, 1)
## The trick list's names in the pause screen's panel (T-386).
const PAUSE_TRICK_NAME_SIZE := 18

## The level-up screen (T-141): the dim, and the "Take it" plate's hover tint.
const LEVEL_UP_DIM := Color(0, 0, 0, 0.6)
const LEVEL_UP_HOVER_TINT := Color(1.15, 1.15, 1.15)

# ---------------------------------------------------------------- reading it

static var _comic_font: FontFile = null


## The comic font (Bangers) with smoothing off: hard pixel edges (T-131).
## Shared by every HUD label.
static func comic_font() -> FontFile:
	if _comic_font == null:
		_comic_font = new_comic_font()
	return _comic_font


## A new copy of the comic font with smoothing off (the popups bake from their own).
static func new_comic_font() -> FontFile:
	var f := (load(COMIC_FONT_PATH) as FontFile).duplicate() as FontFile
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false
	return f


## The clock's panel: the panel art at 2x (StyleBoxTexture, stretched exactly
## 2x into the 200 x 72 layout), with the old border's 3 px content margin.
static func clock_panel_box() -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(CLOCK_PANEL_ART) as Texture2D
	box.set_content_margin_all(CLOCK_PANEL_CONTENT_MARGIN)
	return box


## The weapon column's 24 x 24 icon for a weapon id, cut from the icon sheet;
## null when the sheet or the id is missing (the caller falls back).
static func weapon_icon(weapon_id: String) -> Texture2D:
	var i := WEAPON_ICON_ORDER.find(weapon_id)
	if i < 0 or not ResourceLoader.exists(WEAPON_ICON_ART):
		return null
	var sheet := load(WEAPON_ICON_ART) as Texture2D
	if sheet == null or sheet.get_width() < (i + 1) * WEAPON_ICON_FRAME:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(i * WEAPON_ICON_FRAME, 0, WEAPON_ICON_FRAME, WEAPON_ICON_FRAME)
	return atlas


## The font of a role's `font` key ("comic"); null for the theme's default.
static func font_for(kind: String) -> Font:
	match kind:
		"comic":
			return comic_font()
	return null


## A role's look (LABELS); refuses an unknown role so a typo can't pass silently.
static func role(name: String) -> Dictionary:
	assert(LABELS.has(name), "HudStyle: no label role '%s'" % name)
	return LABELS.get(name, {})


## Gives a Label or Button the role's font, size, colour and outline. `color`
## replaces the role's colour (the viewers colours from hud.json). On a Button
## the colour is set for all four of its states.
static func apply(control: Control, role_name: String, color: Variant = null) -> void:
	var r := role(role_name)
	var font := font_for(String(r.get("font", "")))
	if font != null:
		control.add_theme_font_override("font", font)
	if r.has("size"):
		control.add_theme_font_size_override("font_size", int(r["size"]))
	var c: Variant = color if color != null else r.get("color")
	if c != null:
		var names := ["font_color"]
		if control is Button:
			names = ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]
		for n in names:
			control.add_theme_color_override(n, c as Color)
	if r.has("outline_color"):
		control.add_theme_color_override("font_outline_color", r["outline_color"] as Color)
	if r.has("outline"):
		control.add_theme_constant_override("outline_size", int(r["outline"]))
	if bool(r.get("caps", false)) and control is Label:
		(control as Label).uppercase = true


## A role's font size (for layouts that measure the font before a label exists).
static func size_of(role_name: String) -> int:
	return int(role(role_name).get("size", 0))


## Sets a heat step's look (HEAT_STEPS) on a label: size, colour, outline and
## the glow drawn as a zero-offset shadow ring. `size`, `color` and `glow`
## replace the step's own (the viewers number has its own sizes, its base
## colour and half the glow); pass -1 or null to keep the step's. With
## `with_outline` false the label keeps its own outline (the viewers number's
## role sets it).
static func apply_heat(label: Label, step: Dictionary, size := -1, color: Variant = null, glow := -1,
		with_outline := true) -> void:
	label.add_theme_font_size_override("font_size", size if size >= 0 else int(step["font_size"]))
	label.add_theme_color_override("font_color", (color if color != null else step["color"]) as Color)
	if with_outline:
		label.add_theme_color_override("font_outline_color", DARK)
		label.add_theme_constant_override("outline_size", int(step["outline"]))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	var g := glow if glow >= 0 else int(step["glow"])
	label.add_theme_constant_override("shadow_outline_size", g)
	label.add_theme_color_override("font_shadow_color", glow_color(step, 0))


## A heat step's glow colour for a flicker pick; no glow below the glowing steps.
static func glow_color(step: Dictionary, pick: int) -> Color:
	var colors: Array = step["glow_colors"]
	if int(step["glow"]) <= 0 or colors.is_empty():
		return NO_GLOW
	return colors[posmod(pick, colors.size())]
