extends Node2D
## The charged jump's cue (task T-590, a playtest; Drifting, Content, "The charged jump (task
## T-590)"): while the Jump power-up's charge grows (Space held on the ground, car.jump.charging),
## a small bar drawn in code above the car fills left to right with the charge, and turns the full
## colour once the charge is full. No text. Gone as soon as the car jumps (or the charge drops).
## The look is the Driving & Drift Agent's proposal for the playtest; its numbers are in
## data/power_ups.json, jump.charge, cue_*.
## It draws in the run's car view (view_root, iso pixels) at the car's place and height itself, so
## its own position stays at zero. Node-free logic: bar_rects().

const PX_PER_UNIT := 16.0
const DEFAULTS := {
	"cue_width_px": 20.0, "cue_height_px": 4.0, "cue_above_px": 26.0,
	"cue_fill_colour": [245, 240, 225], "cue_full_colour": [255, 196, 64],
	"cue_outline_colour": [40, 36, 48], "cue_opacity": 0.9,
}

var config := {}
var view_transform := Transform2D.IDENTITY
var car: Node = null
## True when the cue is drawn now (refreshed after every car step).
var showing := false
## The charge shown, 0 to 1.
var fraction := 0.0


func _init() -> void:
	name = "JumpChargeCue"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	load_config()


func load_config() -> void:
	config = DEFAULTS.duplicate(true)
	var d: Dictionary = PowerUpData.new().jump_charge()
	for k in DEFAULTS:
		if d.has(k) and typeof(d[k]) in [TYPE_INT, TYPE_FLOAT, TYPE_ARRAY]:
			config[k] = d[k]


func bind(c: Node) -> void:
	if is_instance_valid(car) and car.stepped.is_connected(refresh):
		car.stepped.disconnect(refresh)
	car = c
	car.stepped.connect(refresh)
	refresh()


func refresh() -> void:
	showing = car != null and is_instance_valid(car) and car.jump.is_owned() and bool(car.jump.charging)
	fraction = float(car.jump.charge_fraction()) if showing else 0.0
	queue_redraw()


## The bar's rectangles in view px for a car drawn at `centre_px` (its drawn centre, height
## included) and a charge `f` (0 to 1): [outline, fill]. The fill is empty at 0.
func bar_rects(centre_px: Vector2, f: float) -> Array:
	var w := float(config.cue_width_px)
	var h := float(config.cue_height_px)
	var top_left := (centre_px + Vector2(-w * 0.5, -float(config.cue_above_px) - h * 0.5)).round()
	var outline := Rect2(top_left - Vector2.ONE, Vector2(w, h) + Vector2(2, 2))
	var fill := Rect2(top_left, Vector2(roundf(w * clampf(f, 0.0, 1.0)), h))
	return [outline, fill]


func _colour(key: String) -> Color:
	var c: Array = config[key]
	return Color8(int(c[0]), int(c[1]), int(c[2]), int(round(255.0 * float(config.cue_opacity))))


func _draw() -> void:
	if not showing:
		return
	var lift := Vector2(0.0, -float(car.height) * PX_PER_UNIT)
	var centre: Vector2 = view_transform * (car.model.get_position() * PX_PER_UNIT) + lift
	var r := bar_rects(centre, fraction)
	draw_rect(r[0], _colour("cue_outline_colour"))
	if r[1].size.x > 0.0:
		draw_rect(r[1], _colour("cue_full_colour" if fraction >= 1.0 else "cue_fill_colour"))
