extends Node2D
## The jump arrow (task T-551; HUD and menus, Decisions, "The jump arrow"; Drifting, Decisions,
## "The grind overhaul"): a small arrow around the car pointing where the car faces, so the player
## knows where letting go of Space will launch it off a rail.
##
## - When: while the car grinds (the proposal; car.grind.active), with the setting on. The launch
##   is the only thing it predicts, and it is only possible on a rail.
## - Setting: GameSettings jump_arrow_enabled (on by default, the proposal; T-553 puts its checkbox
##   in the pause screen); its saves reach set_enabled() through GameSettings.notifier at once.
## - Look: drawn in code in the pixel look of the Drift Guide (flat colour, hard edges): a flat
##   arrowhead lying at the car's height, just past the nose (`arrow_distance` units from the car's
##   centre along its heading), with a dark outline so it reads on the street and on the rail.
##   Numbers: data/rail_grind.json, arrow_*.
## It draws in the run's car view (view_root, iso pixels) at the car's place and height itself, so
## its own position stays at zero. Node-free logic: should_show(), points_units().

const PX_PER_UNIT := 16.0
const DATA_FILE := "rail_grind"
const DEFAULTS := {
	"arrow_distance": 2.0, "arrow_length": 0.9, "arrow_width": 1.0,
	"arrow_colour": [245, 240, 225], "arrow_outline_colour": [40, 36, 48], "arrow_opacity": 0.85,
}

var config := {}
var enabled := GameSettings.DEFAULT_JUMP_ARROW_ENABLED
var view_transform := Transform2D.IDENTITY
var car: Node = null
## True when the arrow is drawn now (refreshed after every car step).
var showing := false


func _init() -> void:
	name = "FacingArrow"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	load_config()


func _ready() -> void:
	GameSettings.notifier.jump_arrow_enabled_changed.connect(set_enabled)
	set_enabled(GameSettings.load_jump_arrow_enabled())


func load_config(file: String = DATA_FILE) -> void:
	config = DEFAULTS.duplicate(true)
	var r := GameData.load_file(file)
	var d: Dictionary = r.data if r.ok and r.data is Dictionary else {}
	for k in DEFAULTS:
		if d.has(k) and typeof(d[k]) in [TYPE_INT, TYPE_FLOAT, TYPE_ARRAY]:
			config[k] = d[k]


func set_enabled(on: bool) -> void:
	enabled = on
	refresh()


func bind(c: Node) -> void:
	if is_instance_valid(car) and car.stepped.is_connected(refresh):
		car.stepped.disconnect(refresh)
	car = c
	car.stepped.connect(refresh)
	refresh()


## The rule: shown while grinding, with the setting on.
static func should_show(is_enabled: bool, grinding: bool) -> bool:
	return is_enabled and grinding


func refresh() -> void:
	showing = car != null and should_show(enabled, bool(car.grind.active))
	queue_redraw()


## The arrowhead's three points (flat units) for a car at `center` facing `heading` (radians):
## [tip, left base corner, right base corner].
func points_units(center: Vector2, heading: float) -> PackedVector2Array:
	var f := Vector2(cos(heading), sin(heading))
	var side := Vector2(-f.y, f.x) * float(config.arrow_width) * 0.5
	var base := center + f * float(config.arrow_distance)
	var tip := base + f * float(config.arrow_length)
	return PackedVector2Array([tip, base + side, base - side])


func _draw() -> void:
	if not showing:
		return
	var lift := Vector2(0.0, -float(car.height) * PX_PER_UNIT)
	var pts := PackedVector2Array()
	for p in points_units(car.model.get_position(), car.model.rotation):
		pts.append((view_transform * (p * PX_PER_UNIT) + lift).round())
	var a := float(config.arrow_opacity)
	var c: Array = config.arrow_colour
	var o: Array = config.arrow_outline_colour
	var fill := Color8(int(c[0]), int(c[1]), int(c[2]), int(round(255.0 * a)))
	var line := Color8(int(o[0]), int(o[1]), int(o[2]), int(round(255.0 * a)))
	draw_polygon(pts, PackedColorArray([fill, fill, fill]))
	var loop := PackedVector2Array(pts)
	loop.append(pts[0])
	draw_polyline(loop, line, 1.0, false)
