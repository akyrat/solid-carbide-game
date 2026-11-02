class_name MultiplierTag
extends Control
## The combo multiplier beside the car (T-514; HUD and menus, Decisions, "The multiplier
## beside the car"; Game loop architecture, Decisions, "Back to the combo multiplier; tricks
## pay subs"). It replaces the live viewers counter (T-336): the combo shows as its
## multiplier number ("x2.50", T-512's text) next to the car, following it on screen. The
## number eases toward the multiplier. Its look heats up on ComboHeat's steps (colour, glow
## and pulse), with a fifth step at the cap. A trick popup's "+x0.5" flies into it (fly_in)
## and bumps it when it lands; a crash (crash) flashes it red and drops "-x{lost}" away from
## it. It only shows: the HUD feeds it the multiplier and its place. Pausable.
##
## All text comes from res://data/multiplier_text.json (T-512). Layout and timings:
## res://data/hud.json, multiplier_tag.

const TEXT_FILE := "multiplier_text"
const DARK := HudStyle.DARK
const SIZE := Vector2(140, 48)
const DEFAULT_OFFSET := Vector2(-130, -8)

## Sent when an amount flying in from a trick popup reaches the number.
signal landed(amount: float)

var color := HudStyle.MULTIPLIER_COLOR
var crash_color := HudStyle.MULTIPLIER_CRASH_COLOR
var cfg: Dictionary = {}
var number_label: Label
## Where the number's centre sits from the car's centre on screen (HUD pixels).
var offset := DEFAULT_OFFSET
## The multiplier now and before the last change (a crash's loss is the difference).
var multiplier := 1.0
var previous_multiplier := 1.0
## The number counting toward the target.
var shown := 1.0
## Multiplier brought by trick popups whose amount is still on its way: held back from the
## count until it lands, so the number jumps when the "+x0.5" arrives.
var pending := 0.0
var time := 0.0
## The look step (0 base, 1 to 3 the heat steps, 4 at the cap).
var step := 0
var bump_left := 0.0
var flash_left := 0.0
var flash_color := Color(1, 1, 1, 0)
var flash_seconds := 0.25
## The number's opacity: 0 while the combo is at x1.00 (the board, quick tuning 2026-11-02),
## fading in once it rises above x1 and out when it is back at x1.
var alpha := 0.0
var flights: Array = []
var drops: Array = []

static var _text: Dictionary = {}


func _init() -> void:
	name = "MultiplierTag"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var r := GameData.load_file("hud")
	cfg = r.data.get("multiplier_tag", {}) if r.ok else {}
	color = Color(String(cfg.get("color", HudStyle.MULTIPLIER_COLOR.to_html(false))))
	crash_color = Color(String(cfg.get("crash_color", HudStyle.MULTIPLIER_CRASH_COLOR.to_html(false))))
	var o: Dictionary = cfg.get("offset", {})
	offset = Vector2(float(o.get("x", DEFAULT_OFFSET.x)), float(o.get("y", DEFAULT_OFFSET.y)))
	size = SIZE
	custom_minimum_size = SIZE
	number_label = Label.new()
	number_label.name = "Number"
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number_label.size = SIZE
	number_label.pivot_offset = SIZE / 2.0
	HudStyle.apply(number_label, "multiplier_number")
	number_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(number_label)
	reset(1.0)


## One of T-512's texts (res://data/multiplier_text.json): "multiplier", "gain" or "loss".
static func text_for(key: String) -> String:
	if _text.is_empty():
		var r := GameData.load_file(TEXT_FILE)
		_text = r.data if r.ok else {}
	return String(_text.get(key, ""))


## A multiplier or an amount with two decimals, a trailing zero dropped from amounts
## ("x2.50" for the multiplier, "+x0.5" for a trick's add).
static func format_number(value: float, trim := false) -> String:
	var s := "%.2f" % snappedf(value, 0.01)
	if trim and s.contains(".") and s.ends_with("0"):
		s = s.substr(0, s.length() - 1)
	return s


static func multiplier_text(m: float) -> String:
	return text_for("multiplier").format({"multiplier": format_number(m)})


## The trick popup's amount, "+x0.5".
static func gain_text(amount: float) -> String:
	return text_for("gain").format({"amount": format_number(amount, true)})


## A crash's "-x1.5".
static func loss_text(amount: float) -> String:
	return text_for("loss").format({"amount": format_number(amount, true)})


## The look step for a multiplier: ComboHeat's steps 0 to 3, and 4 from the cap (fire_from).
func step_for(m: float) -> int:
	if m >= float(cfg.get("fire_from", 6.0)):
		return ComboHeat.STEPS.size()
	return ComboHeat.step_for(m)


## A new run: the number goes straight to the multiplier, nothing in flight.
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
	alpha = 1.0 if wants_show() else 0.0
	_show_number()
	_update_step()


## Follows the combo multiplier (the HUD's combo_changed).
func set_multiplier(m: float) -> void:
	if is_equal_approx(m, multiplier):
		return
	previous_multiplier = multiplier
	multiplier = m
	_update_step()


## What the number counts toward: the multiplier less the amounts still flying in.
func count_target() -> float:
	return maxf(multiplier - pending, 1.0)


func hold(gain: float) -> void:
	pending += maxf(gain, 0.0)
	_update_step()


## Gives back an amount held for a popup that will not fly (its popup went early).
func release(gain: float) -> void:
	pending = maxf(pending - maxf(gain, 0.0), 0.0)
	_update_step()


## An amount ("+x0.5") flies from `from` (HUD pixels) into the number; on arrival the held
## amount counts in and the number bumps.
func fly_in(text: String, gain: float, from: Vector2) -> MultiplierFlight:
	var f := MultiplierFlight.new()
	if is_inside_tree():
		f.base_scale = get_global_transform().get_scale().x  # the HUD's scale (T-431)
	f.setup(text, color, from, Callable(self, "number_center"),
		float(cfg.get("flight_seconds", 0.55)), float(cfg.get("flight_arc", 90.0)))
	f.gain = gain
	f.arrived.connect(_on_flight_arrived.bind(f))
	add_child(f)
	flights.append(f)
	return f


func _on_flight_arrived(f: MultiplierFlight) -> void:
	flights.erase(f)
	release(f.gain)
	bump()
	landed.emit(f.gain)


## Where amounts fly to: the number's centre, in HUD (canvas) pixels.
func number_center() -> Vector2:
	return number_label.get_global_transform() * number_label.pivot_offset


func bump() -> void:
	bump_left = float(cfg.get("bump_seconds", 0.25))


## A crash cut the combo: the number flashes red, "-x{lost}" drops away from it and the
## number falls. Amounts still in the air land without holding anything back.
func crash(lost: float) -> void:
	pending = 0.0
	for f in flights:
		if is_instance_valid(f):
			f.gain = 0.0
	flash_color = Color(crash_color, 1.0)
	flash_seconds = maxf(float(cfg.get("crash_flash_seconds", 0.45)), 0.01)
	flash_left = flash_seconds
	_update_step()
	_animate()
	if lost <= 0.0:
		return
	var d := MultiplierDrop.new()
	d.setup(loss_text(lost), crash_color,
		number_label.position + Vector2(number_label.pivot_offset.x, number_label.size.y * 0.75),
		float(cfg.get("drop_seconds", 0.9)), float(cfg.get("drop_px", 70.0)))
	d.tree_exiting.connect(func() -> void: drops.erase(d))
	add_child(d)
	drops.append(d)


## What the last change cut from the multiplier (0 when it did not fall).
func last_loss() -> float:
	return maxf(previous_multiplier - multiplier, 0.0)


## True while the number should be seen: the combo is above x1 (or the shown number has not
## drained back to it yet), a crash is flashing or dropping its loss, or an amount is on its way.
func wants_show() -> bool:
	return multiplier > 1.0005 or shown > 1.005 or pending > 0.0 or flash_left > 0.0 or not drops.is_empty()


func is_visible_now() -> bool:
	return alpha > 0.0


func is_flashing_red() -> bool:
	return flash_left > 0.0


func _update_step() -> void:
	var s := step_for(count_target())
	if s == step and number_label.has_theme_font_size_override("font_size"):
		return
	step = s
	_apply_step()


## The heat look: ComboHeat's colours, glow and pulse for steps 1 to 3 (the top step's at
## the cap), the multiplier colour at the base, with the tag's own sizes.
func _apply_step() -> void:
	var heat := mini(step, ComboHeat.STEPS.size() - 1)
	var st: Dictionary = ComboHeat.STEPS[heat]
	var sizes: Array = cfg.get("number_sizes", HudStyle.MULTIPLIER_NUMBER_SIZES)
	HudStyle.apply_heat(number_label, st, int(sizes[mini(step, sizes.size() - 1)]),
		color if heat == 0 else st.color, int(st.glow) / 2, false)
	_animate()


func _process(delta: float) -> void:
	Perf.begin(&"hud.multiplier")
	advance(delta)
	Perf.end(&"hud.multiplier")


## Moves everything on by `dt` seconds (the frame's delta; tests call it directly).
func advance(dt: float) -> void:
	time += dt
	var rate := float(cfg.get("count_rate_per_second", 10.0))
	var target := count_target()
	if absf(target - shown) < 0.005:
		shown = target
	else:
		shown += (target - shown) * (1.0 - exp(-rate * maxf(dt, 0.0)))
	_show_number()
	var fade := maxf(float(cfg.get("fade_seconds", 0.2)), 0.01)
	var was := alpha
	alpha = move_toward(alpha, 1.0 if wants_show() else 0.0, dt / fade)
	if was <= 0.0 and alpha > 0.0:
		bump_left = float(cfg.get("bump_seconds", 0.25))  # a pop as it appears
	bump_left = maxf(bump_left - dt, 0.0)
	flash_left = maxf(flash_left - dt, 0.0)
	_animate()


func _show_number() -> void:
	var text := multiplier_text(shown)
	if number_label.text != text:
		number_label.text = text


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
		s += float(cfg.get("bump_scale", 0.3)) * k
	return s


func _animate() -> void:
	if number_label == null:
		return
	var s := number_scale()
	number_label.scale = Vector2(s, s)
	number_label.modulate.a = alpha
	var heat := mini(step, ComboHeat.STEPS.size() - 1)
	var st: Dictionary = ComboHeat.STEPS[heat]
	var frame := int(floorf(time / ComboHeat.FLICKER_FRAME))
	var colors: Array = st.glow_colors
	if st.glow > 0 and colors.size() > 1:
		var pick := int(abs(sin(frame * 12.9898) * 43758.5453)) % colors.size()
		number_label.add_theme_color_override("font_shadow_color", HudStyle.glow_color(st, pick))
	if is_flashing_red():
		number_label.add_theme_color_override("font_color", crash_color)
	else:
		number_label.add_theme_color_override("font_color",
			color if heat == 0 else (st.color as Color))


## Puts the number beside the car: `car_screen` is the car's centre in HUD pixels.
func follow(car_screen: Vector2) -> void:
	position = (car_screen + offset - SIZE / 2.0).round()
