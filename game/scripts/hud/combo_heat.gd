class_name ComboHeat
extends Node
## The combo's heat steps (task T-131; decision: docs/hud-and-menus.md,
## Decisions, board 2026-10-14). As the combo multiplier climbs, the HUD's
## combo counter heats up in three steps on top of its base look:
##
## - step 0 (base): above x1.0 and below x2.00;
## - step 1 (from x2.00): bigger, yellow, a light pulse;
## - step 2 (from x3.00): bigger again, orange with a yellow glow ring, a
##   stronger and faster pulse;
## - step 3 (from x4.00 up to the cap): white-hot with a flickering orange and
##   yellow glow, the strongest pulse, and the likes bar on fire (LikesFire).
##
## The step is chosen from the multiplier as the counter shows it (two
## decimals), so x1.99 is the base look and x2.00 is step 1. When the combo
## drops, the look drops with it. Everything is drawn in code, in oranges,
## yellows and whites, never Redgull red. The node is pausable: the pulse and
## the flicker stop while the game is paused, like the rest of the HUD.

## The multipliers where steps 1, 2 and 3 start. Change them here only.
const THRESHOLDS: Array[float] = [2.0, 3.0, 4.0]
## The step from which the likes bar burns.
const FIRE_STEP := 3
## The animation advances in frames of this length, so the flicker looks like
## hand-drawn pixel-art frames rather than a smooth fade.
const FLICKER_FRAME := 1.0 / 12.0

const DARK := Color(0.03, 0.03, 0.06)
## The base look is the counter's look before T-131 (pink, Hud.COMBO_COLOR),
## now in the comic font.
const STEPS: Array[Dictionary] = [
	{"font_size": 30, "color": Color(1.0, 0.25, 0.75), "outline": 10,
		"glow": 0, "glow_colors": [], "pulse": 0.0, "pulse_hz": 0.0},
	{"font_size": 36, "color": Color(1.0, 0.86, 0.25), "outline": 10,
		"glow": 0, "glow_colors": [], "pulse": 0.06, "pulse_hz": 1.2},
	{"font_size": 42, "color": Color(1.0, 0.62, 0.12), "outline": 10,
		"glow": 18, "glow_colors": [Color(1.0, 0.86, 0.25)], "pulse": 0.10, "pulse_hz": 2.0},
	{"font_size": 50, "color": Color(1.0, 0.98, 0.82), "outline": 10,
		"glow": 22, "glow_colors": [Color(1.0, 0.6, 0.08), Color(1.0, 0.72, 0.16), Color(1.0, 0.86, 0.25)],
		"pulse": 0.14, "pulse_hz": 3.0},
]

## The current step, 0 to 3.
var step := 0
## Seconds of animation so far; stands still while the game is paused.
var time := 0.0
var label: Label
var fire: LikesFire


func _init() -> void:
	name = "ComboHeat"
	process_mode = Node.PROCESS_MODE_PAUSABLE


## Hooks the heat to the counter it styles and the fire it lights.
func setup(combo_label: Label, likes_fire: LikesFire) -> void:
	label = combo_label
	fire = likes_fire
	_apply_step()


## The step for a multiplier, compared at the two decimals the counter shows.
static func step_for(multiplier: float) -> int:
	var shown := snappedf(multiplier, 0.01)
	var s := 0
	for t in THRESHOLDS:
		if shown >= snappedf(t, 0.01):
			s += 1
	return s


## Follows the combo multiplier: picks the step and restyles the counter.
func set_multiplier(multiplier: float) -> void:
	var s := step_for(multiplier)
	if s == step:
		return
	step = s
	_apply_step()


func is_burning() -> bool:
	return step >= FIRE_STEP


## Every colour the heat can give the counter (for the not-red tests).
static func all_colors() -> Array[Color]:
	var out: Array[Color] = []
	for st in STEPS:
		out.append(st.color)
		for c: Color in st.glow_colors:
			out.append(c)
	return out


func _apply_step() -> void:
	if fire != null:
		fire.burning = is_burning()
	if label == null:
		return
	var st: Dictionary = STEPS[step]
	label.add_theme_font_size_override("font_size", st.font_size)
	label.add_theme_color_override("font_color", st.color)
	label.add_theme_color_override("font_outline_color", DARK)
	label.add_theme_constant_override("outline_size", st.outline)
	# The glow is the label's shadow, drawn as a wider ring round the outline.
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	label.add_theme_constant_override("shadow_outline_size", st.glow)
	label.add_theme_color_override("font_shadow_color",
		st.glow_colors[0] if st.glow > 0 else Color(0, 0, 0, 0))
	_animate()


func _process(delta: float) -> void:
	time += delta
	_animate()


## The counter's scale for this moment: a quick pop on every beat that eases
## back (1.0 at the base step, which does not pulse).
func pulse_scale() -> float:
	var st: Dictionary = STEPS[step]
	if st.pulse <= 0.0:
		return 1.0
	var t := floorf(time / FLICKER_FRAME) * FLICKER_FRAME
	var beat := fposmod(t * st.pulse_hz, 1.0)
	return 1.0 + st.pulse * pow(1.0 - beat, 3.0)


func _animate() -> void:
	if label == null:
		return
	var s := pulse_scale()
	label.scale = Vector2(s, s)
	var st: Dictionary = STEPS[step]
	var colors: Array = st.glow_colors
	if st.glow > 0 and colors.size() > 1:
		var frame := int(floorf(time / FLICKER_FRAME))
		# A jumpy, not cyclic, pick of the glow colour each frame.
		var pick := int(abs(sin(frame * 12.9898) * 43758.5453)) % colors.size()
		label.add_theme_color_override("font_shadow_color", colors[pick])
