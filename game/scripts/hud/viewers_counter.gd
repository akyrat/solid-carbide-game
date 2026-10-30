class_name ViewersCounter
extends Control
## The live viewers counter (T-336; HUD and menus, Decisions, "The HUD looks like a
## livestream" and "Tricks bring viewers, shown in one colour"). It takes the place of
## the old "Combo x2.00" counter: the combo multiplier is unchanged, the player sees it
## as the stream's live viewers (ViewersData, T-332).
##
## A dark panel (T-339's viewers_panel.png) at the bottom right, with the LIVE badge
## and the viewers' eye on its left and the number over the unit (Hud.TEXT_VIEWERS_UNIT) on its right. The
## number counts toward the target for the multiplier and wobbles a little all the
## time (ViewersData.count_toward, with_wobble). Its look heats up on T-332's steps,
## with the old combo counter's heat colours, glow and pulse (ComboHeat.STEPS), and
## from 1,000,000 the panel is on fire (viewers_fire frames). Amounts flying in from
## the trick popups (fly_in) bump it when they land; a crash (crash) flashes it red
## and drops "-{viewers lost}" away from it. It only shows: the HUD feeds it the
## multiplier. Pausable: everything stands still while the game is paused.
##
## Layout and timings: res://data/hud.json, viewers_counter.

const PANEL_PATH := "res://art/hud/viewers_panel.png"
const BADGE_PATH := "res://art/hud/live_badge.png"
const EYE_PATH := "res://art/hud/eye_icon.png"
const FIRE_PATH := "res://art/hud/viewers_fire_%02d.png"
const FIRE_FRAMES := 12
## T-339's art is drawn at 2x.
const ART_SCALE := 2
## Where the panel sits in each fire frame (art pixels): the fire is drawn round it.
const FIRE_PANEL_AT := Vector2(8, 24)
## Inside the panel (screen pixels at ART_SCALE): the badge and the eye on the left,
## the number and the unit right-aligned on the right.
const BADGE_AT := Vector2(14, 12)
const EYE_GAP := 4
const TEXT_RIGHT := 14
const TEXT_TOP := 6
const UNIT_FONT_SIZE := HudStyle.VIEWERS_UNIT_SIZE
## The look step from which the panel burns (ViewersData.step_for_viewers: 4 is fire).
const FIRE_STEP := 4
const DARK := HudStyle.DARK
const DEFAULT_LAYOUT := {"x": 896, "y": 560, "w": 240, "h": 72, "reference_w": 1152, "reference_h": 648}

## Sent when an amount flying in from a trick popup reaches the counter.
signal landed(viewers: float)

var viewers: ViewersData
## The viewers colour (hud.json), used for nothing else in the HUD.
var color := HudStyle.VIEWERS_COLOR
var crash_color := HudStyle.VIEWERS_CRASH_COLOR
var cfg: Dictionary = {}

var panel: TextureRect
var badge: TextureRect
var eye: TextureRect
var number_label: Label
var unit_label: Label
var fire: TextureRect
## The panel's flash (a bump's light flash or a crash's red one), over the panel.
var flash_rect: ColorRect

## The combo multiplier now and the one before the last change (for a crash's loss).
var multiplier := 1.0
var previous_multiplier := 1.0
## The number counting toward the target, without the wobble.
var shown := 0.0
## The number drawn: `shown` with the wobble on it.
var displayed := 0.0
## Viewers brought by trick popups whose amount is still on its way: held back from
## the count until it lands, so the number jumps up when the "+12K" arrives.
var pending := 0.0
## Seconds of animation; stands still while paused.
var time := 0.0
## The look step (0 base, 1 to 3 the heat steps, 4 on fire).
var step := 0
var fire_frame := 0
var bump_left := 0.0
var flash_left := 0.0
var flash_color := Color(1, 1, 1, 0)
var flash_seconds := 0.25
## Amounts in flight, and "-{viewers}" drops falling away.
var flights: Array = []
var drops: Array = []

static var _fire_textures: Array = []


func _init() -> void:
	name = "ViewersCounter"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE
	viewers = ViewersData.new()
	var r := GameData.load_file("hud")
	cfg = r.data.get("viewers_counter", {}) if r.ok else {}
	color = Color(String(cfg.get("color", HudStyle.VIEWERS_COLOR.to_html(false))))
	crash_color = Color(String(cfg.get("crash_color", HudStyle.VIEWERS_CRASH_COLOR.to_html(false))))
	_anchor(cfg.get("layout", DEFAULT_LAYOUT))
	_build()
	reset(1.0)


## Anchored to the bottom-right corner, keeping its margins at other window sizes.
func _anchor(layout: Dictionary) -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	var ref_w := float(layout["reference_w"])
	var ref_h := float(layout["reference_h"])
	offset_left = float(layout["x"]) - ref_w
	offset_right = offset_left + float(layout["w"])
	offset_top = float(layout["y"]) - ref_h
	offset_bottom = offset_top + float(layout["h"])
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN


func _build() -> void:
	panel = _texture_rect("Panel", load(PANEL_PATH))
	add_child(panel)
	flash_rect = ColorRect.new()
	flash_rect.name = "Flash"
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1, 1, 1, 0)
	# Over the panel's screen only (inside the bezel and the rim, 5 art pixels).
	var inset := 5 * ART_SCALE
	flash_rect.position = Vector2(inset, inset)
	flash_rect.size = panel.size - Vector2(inset, inset) * 2.0
	add_child(flash_rect)
	# The fire is drawn in front of the panel: two rows lick its top edge, the
	# rest of the panel is left clear (T-339).
	fire = TextureRect.new()
	fire.name = "Fire"
	fire.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fire.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fire.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fire.stretch_mode = TextureRect.STRETCH_SCALE
	var f0: Texture2D = fire_textures()[0]
	fire.size = f0.get_size() * ART_SCALE
	fire.position = -FIRE_PANEL_AT * ART_SCALE
	fire.texture = f0
	fire.visible = false
	add_child(fire)
	badge = _texture_rect("LiveBadge", load(BADGE_PATH))
	# The badge's lettering is T-331's text, drawn into T-339's art.
	badge.tooltip_text = Hud.TEXT_LIVE_BADGE
	badge.position = BADGE_AT
	add_child(badge)
	eye = _texture_rect("Eye", load(EYE_PATH))
	eye.position = Vector2(
		BADGE_AT.x + floorf((badge.size.x - eye.size.x) / 2.0),
		BADGE_AT.y + badge.size.y + EYE_GAP)
	add_child(eye)
	number_label = Label.new()
	number_label.name = "Number"
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	HudStyle.apply(number_label, "viewers_number")
	number_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(number_label)
	unit_label = Label.new()
	unit_label.name = "Unit"
	unit_label.text = Hud.TEXT_VIEWERS_UNIT
	unit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	HudStyle.apply(unit_label, "viewers_unit", color)
	unit_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(unit_label)
	_apply_step()


func _texture_rect(node_name: String, tex: Texture2D) -> TextureRect:
	var t := TextureRect.new()
	t.name = node_name
	t.texture = tex
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.size = tex.get_size() * ART_SCALE
	return t


static func fire_textures() -> Array:
	if _fire_textures.is_empty():
		for i in FIRE_FRAMES:
			_fire_textures.append(load(FIRE_PATH % i))
	return _fire_textures


## Lays the number and the unit out on the panel's right; the number pulses from its centre.
func _layout_text() -> void:
	var w := 240.0 if panel == null else panel.size.x
	# Fixed boxes from the badge's right edge to the panel's right margin, the text
	# right-aligned in them: the place never depends on the text being measured yet.
	var left := BADGE_AT.x + badge.size.x + EYE_GAP
	var right := w - TEXT_RIGHT
	var nh := ceilf(Hud.comic_font().get_height(number_label.get_theme_font_size("font_size")))
	var uh := ceilf(Hud.comic_font().get_height(UNIT_FONT_SIZE))
	var h := panel.size.y
	# The number and the unit together, centred in the panel's height (the unit's
	# box overlaps the number's empty line space under the capitals by TEXT_TOP).
	var top := floorf((h - (nh + uh - TEXT_TOP)) / 2.0)
	number_label.position = Vector2(left, top)
	number_label.size = Vector2(right - left, nh)
	unit_label.position = Vector2(left, top + nh - TEXT_TOP)
	unit_label.size = Vector2(right - left, uh)
	# The pulse and the bump grow the number from the middle of its right-aligned text.
	number_label.pivot_offset = Vector2(right - left - 30.0, nh / 2.0)


## A new run: the number goes straight to the multiplier's viewers, nothing in flight.
func reset(m: float) -> void:
	multiplier = m
	previous_multiplier = m
	pending = 0.0
	for f in flights:
		if is_instance_valid(f):
			f.queue_free()
	flights.clear()
	for d in drops:
		if is_instance_valid(d):
			d.queue_free()
	drops.clear()
	bump_left = 0.0
	flash_left = 0.0
	shown = count_target()
	_show_number()
	_update_step()


## Follows the combo multiplier (the HUD's combo_changed).
func set_multiplier(m: float) -> void:
	if is_equal_approx(m, multiplier):
		return
	previous_multiplier = multiplier
	multiplier = m
	_update_step()


## The viewers for the multiplier now (T-332's curve).
func target() -> float:
	return viewers.viewers_for(multiplier)


## What the number counts toward: the target less the viewers still flying in.
func count_target() -> float:
	return maxf(target() - pending, viewers.base_viewers())


## A trick popup brought `gain` viewers: held back until its amount lands.
func hold(gain: float) -> void:
	pending += maxf(gain, 0.0)
	_update_step()


## Gives back viewers held for an amount that will not fly (its popup went early).
func release(gain: float) -> void:
	pending = maxf(pending - maxf(gain, 0.0), 0.0)
	_update_step()


## An amount ("+12K" with the eye) flies from `from` (HUD pixels) into the number;
## on arrival the held viewers count in and the counter bumps.
func fly_in(text: String, gain: float, from: Vector2) -> ViewersFlight:
	var f := ViewersFlight.new()
	f.setup(text, color, from, Callable(self, "number_center"),
		float(cfg.get("flight_seconds", 0.55)), float(cfg.get("flight_arc", 90.0)))
	f.gain = gain
	f.arrived.connect(_on_flight_arrived.bind(f))
	add_child(f)
	flights.append(f)
	return f


func _on_flight_arrived(f: ViewersFlight) -> void:
	flights.erase(f)
	release(f.gain)
	bump()
	landed.emit(f.gain)


## Where amounts fly to: the number's centre, in HUD (canvas) pixels.
func number_center() -> Vector2:
	return number_label.get_global_transform() * number_label.pivot_offset


## A quick pop and a light flash (an amount landed).
func bump() -> void:
	bump_left = float(cfg.get("bump_seconds", 0.25))
	_flash(Color(color, 0.55), float(cfg.get("flash_seconds", 0.25)))


## A crash cut the combo: the counter flashes red, "-{viewers lost}" drops away from
## it and the number falls (counting down to the new target). Amounts still in the
## air land without holding anything back.
func crash(lost: float) -> void:
	pending = 0.0
	for f in flights:
		if is_instance_valid(f):
			f.gain = 0.0
	_flash(Color(crash_color, 0.7), float(cfg.get("crash_flash_seconds", 0.45)))
	_update_step()
	if lost <= 0.0:
		return
	var d := ViewersDrop.new()
	d.setup(TrickPopups.LOST_TEXT.format({"amount": viewers.format(lost)}), crash_color,
		number_label.position + Vector2(number_label.pivot_offset.x, 0.0),
		float(cfg.get("drop_seconds", 0.9)), float(cfg.get("drop_px", 70.0)))
	d.tree_exiting.connect(func() -> void: drops.erase(d))
	add_child(d)
	# Under the number, so the number stays readable as the drop falls across the panel.
	move_child(d, number_label.get_index())
	drops.append(d)


## The viewers lost when the combo went from the last multiplier to this one.
func last_loss() -> float:
	return viewers.crash_loss(previous_multiplier, multiplier)


func _flash(c: Color, seconds: float) -> void:
	flash_color = c
	flash_seconds = maxf(seconds, 0.01)
	flash_left = flash_seconds
	_animate()


func is_burning() -> bool:
	return step >= FIRE_STEP


func is_flashing_red() -> bool:
	return flash_left > 0.0 and flash_color.r > 0.9 and flash_color.b < 0.3


func _update_step() -> void:
	var s := viewers.step_for_viewers(count_target())
	if s == step and number_label.has_theme_font_size_override("font_size"):
		return
	step = s
	_apply_step()


## The heat look: the old combo counter's colours, glow and pulse (ComboHeat.STEPS)
## for steps 1 to 3, the viewers colour at the base, and the top step's look with the
## fire from 1,000,000.
func _apply_step() -> void:
	var heat := mini(step, ComboHeat.STEPS.size() - 1)
	var st: Dictionary = ComboHeat.STEPS[heat]
	var sizes: Array = cfg.get("number_sizes", HudStyle.VIEWERS_NUMBER_SIZES)
	# The heat step's look with the counter's own sizes, base colour, half the glow
	# and its own outline (HudStyle "viewers_number").
	HudStyle.apply_heat(number_label, st, int(sizes[mini(heat, sizes.size() - 1)]),
		color if heat == 0 else st.color, int(st.glow) / 2, false)
	fire.visible = is_burning()
	_layout_text()
	_animate()


func _process(delta: float) -> void:
	advance(delta)


## Moves everything on by `dt` seconds (the frame's delta; tests call it directly).
func advance(dt: float) -> void:
	time += dt
	shown = viewers.count_toward(shown, count_target(), dt)
	_show_number()
	bump_left = maxf(bump_left - dt, 0.0)
	flash_left = maxf(flash_left - dt, 0.0)
	_animate()


func _show_number() -> void:
	displayed = viewers.with_wobble(shown, time)
	var text := viewers.format(displayed)
	if number_label.text != text:
		number_label.text = text
		_layout_text()


## The number's scale now: the heat pulse (ComboHeat's beat) and the bump's pop.
func number_scale() -> float:
	var heat := mini(step, ComboHeat.STEPS.size() - 1)
	var st: Dictionary = ComboHeat.STEPS[heat]
	var s := 1.0
	if st.pulse > 0.0:
		var t := floorf(time / ComboHeat.FLICKER_FRAME) * ComboHeat.FLICKER_FRAME
		var beat := fposmod(t * st.pulse_hz, 1.0)
		s += st.pulse * pow(1.0 - beat, 3.0)
	if bump_left > 0.0:
		var k := bump_left / maxf(float(cfg.get("bump_seconds", 0.25)), 0.01)
		s += float(cfg.get("bump_scale", 0.18)) * k
	return s


func _animate() -> void:
	if number_label == null:
		return
	var s := number_scale()
	number_label.scale = Vector2(s, s)
	var heat := mini(step, ComboHeat.STEPS.size() - 1)
	var st: Dictionary = ComboHeat.STEPS[heat]
	var frame := int(floorf(time / ComboHeat.FLICKER_FRAME))
	var colors: Array = st.glow_colors
	if st.glow > 0 and colors.size() > 1:
		var pick := int(abs(sin(frame * 12.9898) * 43758.5453)) % colors.size()
		number_label.add_theme_color_override("font_shadow_color", HudStyle.glow_color(st, pick))
	if fire.visible:
		fire_frame = posmod(frame, FIRE_FRAMES)
		fire.texture = fire_textures()[fire_frame]
	var k := flash_left / flash_seconds if flash_left > 0.0 else 0.0
	flash_rect.color = Color(flash_color, flash_color.a * k)
	if is_flashing_red():
		number_label.add_theme_color_override("font_color", crash_color)
	else:
		number_label.add_theme_color_override("font_color",
			color if heat == 0 else (st.color as Color))
