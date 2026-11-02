extends Node2D
## The Drift Guide (task T-517; Drifting, Decisions, "The Drift Guide"; game/docs/driving/drift_guide.md):
## during a drift, a gray, semi-transparent arrow lies flat on the ground in front of the car and
## shows where the car goes in the next second (data "seconds") if the player keeps the steering
## and throttle held now.
##
## - Prediction: predict() steps a copy of the car's own model (CarModel.duplicate_state(), so
##   no side effects on the real car) with the input the car used on its last step
##   (Car.last_input). It is recomputed after every car step, so it bends the same frame the
##   steering changes.
## - Walls: with `blocked` set (the run gives it Car.test_move), the path ends where the next
##   step would hit something. Ramps and jumps: the path is flat, as the model is (height is
##   not predicted; a Space press is not predicted). The end of the drift: the held input
##   never ends it, so the arrow just fades out (alpha) when the real drift ends.
## - Setting: GameSettings drift_guide_enabled (off by default); its saves reach set_enabled()
##   through GameSettings.notifier at once. Off = nothing drawn, nothing computed.
## - Look: drawn in code in flat bands of opacity (hard edges, no gradient), fading towards the
##   tip, with an arrowhead; `alpha` fades in when a drift starts and out when it ends.
##   Numbers: data/drift_guide.json.

const PX_PER_UNIT := 16.0
const DATA_PATH := "res://data/drift_guide.json"
const DEFAULTS := {
	"seconds": 1.0, "sample_steps": 5, "width_units": 0.5, "head_length_units": 1.0,
	"head_width_units": 1.3, "colour": [150, 150, 155], "max_opacity": 0.55, "fade_bands": 6,
	"tip_opacity": 0.15, "fade_in_seconds": 0.15, "fade_out_seconds": 0.3,
}

var config := {}
var enabled := false
## 0 to 1: how much of the guide shows (fades in/out with the drift).
var alpha := 0.0
## The predicted path now, in units, from the car's place to the tip. Empty when nothing shows.
var path_units := PackedVector2Array()
## Optional Callable(from_units: Vector2, to_units: Vector2) -> bool: true when that step is blocked.
var blocked := Callable()
var view_transform := Transform2D.IDENTITY:
	set(value):
		view_transform = value
		queue_redraw()
var car: Node = null
var _drifting := false


func _init() -> void:
	name = "DriftGuide"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	load_config()


func _ready() -> void:
	GameSettings.notifier.drift_guide_enabled_changed.connect(set_enabled)
	set_enabled(GameSettings.load_drift_guide_enabled())


func load_config(path: String = DATA_PATH) -> void:
	config = DEFAULTS.duplicate(true)
	var data = GameData.unwrap(GameData.load_file(path)) if FileAccess.file_exists(path) else null
	if data is Dictionary:
		for k in DEFAULTS:
			if data.has(k) and typeof(data[k]) in [TYPE_INT, TYPE_FLOAT, TYPE_ARRAY]:
				config[k] = data[k]


## Switches the guide on or off at once (the pause screen's checkbox, through the setting).
func set_enabled(on: bool) -> void:
	enabled = on
	if not on:
		alpha = 0.0
		path_units = PackedVector2Array()
	elif car != null:
		refresh()
	queue_redraw()


func bind(c: Node) -> void:
	if is_instance_valid(car) and car.stepped.is_connected(refresh):
		car.stepped.disconnect(refresh)
	car = c
	car.stepped.connect(refresh)
	clear()


func clear() -> void:
	alpha = 0.0
	_drifting = false
	path_units = PackedVector2Array()
	queue_redraw()


## Whether the guide is on screen now.
func is_showing() -> bool:
	return enabled and alpha > 0.0 and path_units.size() >= 2


## After a car step: re-reads the drift state and predicts again while it shows or is fading.
func refresh() -> void:
	if not enabled or car == null:
		return
	_drifting = car.model.is_drifting
	if _drifting or alpha > 0.0:
		var inp: Array = car.last_input
		path_units = predict(car.model, inp[0], inp[1], inp[2], float(config.seconds),
				int(config.sample_steps), blocked)
	else:
		path_units = PackedVector2Array()
	queue_redraw()


## Fades alpha towards 1 while drifting and 0 otherwise.
func advance(delta: float) -> void:
	if not enabled:
		return
	var up := _drifting
	var secs: float = float(config.fade_in_seconds) if up else float(config.fade_out_seconds)
	alpha = move_toward(alpha, 1.0 if up else 0.0, delta / maxf(0.001, secs))
	if alpha <= 0.0 and not up and path_units.size() > 0:
		path_units = PackedVector2Array()
	queue_redraw()


func _process(delta: float) -> void:
	advance(delta)


## The path the model would take in `seconds` with w, s, steer held, as points in units: the
## start, then one point every `sample_steps` steps. Works on a copy: `model` is not changed.
## `blocked_check` (Callable(from, to) -> bool) ends the path at the first blocked step.
static func predict(model, w: bool, s: bool, steer: float, seconds: float, sample_steps: int,
		blocked_check: Callable = Callable()) -> PackedVector2Array:
	var m = model.duplicate_state()
	var out := PackedVector2Array([m.get_position()])
	var steps := roundi(seconds / m.dt)
	var every := maxi(1, sample_steps)
	for i in range(1, steps + 1):
		var before: Vector2 = m.get_position()
		m.step(w, s, steer)
		var after: Vector2 = m.get_position()
		if blocked_check.is_valid() and blocked_check.call(before, after):
			if before != out[out.size() - 1]:
				out.append(before)
			break
		if i % every == 0 or i == steps:
			out.append(after)
	return out


func _draw() -> void:
	if not is_showing():
		return
	var pts := path_units
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i].distance_to(pts[i - 1])
	if total < 0.05:
		return
	var head_len := minf(float(config.head_length_units), total * 0.5)
	var shaft_len := total - head_len
	var bands := maxi(1, int(config.fade_bands))
	var half_w := float(config.width_units) * 0.5
	var col: Array = config.colour
	var travelled := 0.0
	var tip_dir := Vector2.RIGHT
	for i in range(1, pts.size()):
		var a: Vector2 = pts[i - 1]
		var b: Vector2 = pts[i]
		var seg := b - a
		var seg_len := seg.length()
		if seg_len < 0.0001:
			continue
		var dir := seg / seg_len
		tip_dir = dir
		if travelled < shaft_len:
			var end_len := minf(seg_len, shaft_len - travelled)
			var b2 := a + dir * end_len
			var n := Vector2(-dir.y, dir.x) * half_w
			var mid := (travelled + end_len * 0.5) / total
			_quad(a - n, a + n, b2 + n, b2 - n, _band_colour(col, mid, bands))
		travelled += seg_len
	var tip: Vector2 = pts[pts.size() - 1]
	var base := tip - tip_dir * head_len
	var hn := Vector2(-tip_dir.y, tip_dir.x) * float(config.head_width_units) * 0.5
	var tip_col := _band_colour(col, 1.0, bands)
	draw_polygon(PackedVector2Array([_px(base - hn), _px(tip), _px(base + hn)]),
			PackedColorArray([tip_col, tip_col, tip_col]))


## The colour of the band at `t` (0 at the car, 1 at the tip): flat steps from max_opacity down
## to tip_opacity x max_opacity, all times alpha.
func _band_colour(col: Array, t: float, bands: int) -> Color:
	var band := mini(int(t * bands), bands - 1)
	var k := float(band) / float(maxi(1, bands - 1))
	var o := float(config.max_opacity) * lerpf(1.0, float(config.tip_opacity), k) * alpha
	return Color(float(col[0]) / 255.0, float(col[1]) / 255.0, float(col[2]) / 255.0, o)


## The arrow's opacity at `t` (0 at the car, 1 at the tip), with the fade-in/out applied.
func band_opacity(t: float) -> float:
	return _band_colour(config.colour, t, maxi(1, int(config.fade_bands))).a


func _px(units: Vector2) -> Vector2:
	return view_transform * (units * PX_PER_UNIT)


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, colour: Color) -> void:
	draw_polygon(PackedVector2Array([_px(a), _px(b), _px(c), _px(d)]),
			PackedColorArray([colour, colour, colour, colour]))
