extends Node2D
## The jump effect (task T-551; Drifting, Decisions, "A jump effect around the car"): when the car
## jumps (Car.jump_started: the Jump power-up's jump from the ground, "hop", and the launch off a
## rail, "rail_launch"; a ramp's take-off is not a jump, the proposal), the equipped jump effect
## (JumpEffectChoice.equipped_id(): the saved cosmetic, T-552; the dash cloud until then) plays
## around the place the car left from.
##
## The look is art per effect id (T-556: pixel sheets in art/effects/jump/, drawn by
## draw_placeholder(), whose name stays so the Cosmetics previews keep working). The Cosmetics
## menu (T-553) can preview an effect with the same static draw_placeholder() on any CanvasItem.
##  - dash_cloud: grey-white puffs spreading out on the ground and breaking up.
##  - spring: a steel coil standing up from a base plate, stretching, then collapsing.
##  - jet_thrust: a flame hanging under the car down to the ground, flickering and shrinking.
##  - stunt_sparks: orange and white sparks bursting out from under the car and dropping.
##  - shockwave_ring: a pale blue ring rippling out flat on the ground, a second one behind it.
## Each lasts `jump_effect_seconds` (data/rail_grind.json). Several can play at once.
## It draws in the run's car view (view_root, iso pixels) at the stored place and height itself, so
## its own position stays at zero.

const JumpEffectChoice := preload("res://scripts/driving/jump_effect_choice.gd")
const PX_PER_UNIT := 16.0
const ART_SCALE := 0.5
const FRAMES := 8
const FRAME_PX := Vector2(96, 96)
const ANCHOR_PX := Vector2i(48, 68)
const SHEETS := {
	"dash_cloud": preload("res://art/effects/jump/dash_cloud.png"),
	"spring": preload("res://art/effects/jump/spring.png"),
	"jet_thrust": preload("res://art/effects/jump/jet_thrust.png"),
	"stunt_sparks": preload("res://art/effects/jump/stunt_sparks.png"),
	"shockwave_ring": preload("res://art/effects/jump/shockwave_ring.png"),
}
const DATA_FILE := "rail_grind"
const DEFAULT_SECONDS := 0.4

var seconds := DEFAULT_SECONDS
var view_transform := Transform2D.IDENTITY
var car: Node = null
## The effects playing: {id, kind, units, height, heading, t (seconds)}.
var playing: Array = []
## Every effect started (tests, readouts): [id, kind].
var started: Array = []


func _init() -> void:
	name = "JumpEffect"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var r := GameData.load_file(DATA_FILE)
	var d: Dictionary = r.data if r.ok and r.data is Dictionary else {}
	seconds = maxf(float(d.get("jump_effect_seconds", DEFAULT_SECONDS)), 0.05)


func bind(c: Node) -> void:
	if is_instance_valid(car) and car.jump_started.is_connected(_on_jump_started):
		car.jump_started.disconnect(_on_jump_started)
	car = c
	car.jump_started.connect(_on_jump_started)
	clear()


func clear() -> void:
	playing.clear()
	queue_redraw()


func _on_jump_started(kind: String, at_units: Vector2, at_height: float) -> void:
	play(JumpEffectChoice.equipped_id(), kind, at_units, at_height, float(car.model.rotation))


## Starts effect `id` at `units` (flat) and `height`, the car facing `heading` (radians).
func play(id: String, kind: String, units: Vector2, height: float, heading: float) -> void:
	playing.append({"id": id, "kind": kind, "units": units, "height": height, "heading": heading, "t": 0.0})
	started.append([id, kind])
	queue_redraw()


func is_playing() -> bool:
	return not playing.is_empty()


func advance(delta: float) -> void:
	if playing.is_empty():
		return
	for e in playing:
		e.t += delta
	playing = playing.filter(func(e: Dictionary) -> bool: return e.t < seconds)
	queue_redraw()


func _process(delta: float) -> void:
	advance(delta)


func _draw() -> void:
	var basis := Transform2D(view_transform.x * PX_PER_UNIT, view_transform.y * PX_PER_UNIT, Vector2.ZERO)
	for e in playing:
		var origin: Vector2 = view_transform * (Vector2(e.units) * PX_PER_UNIT) \
				+ Vector2(0.0, -float(e.height) * PX_PER_UNIT)
		draw_placeholder(self, str(e.id), clampf(float(e.t) / seconds, 0.0, 1.0), origin, basis, float(e.heading))


## Draws effect `id` at progress t (0 start, 1 end) on `ci`, around `origin` (pixels: the ground
## point the car left from). The art (task T-556, game/tools/build_jump_effects.py): one sheet per id
## in res://art/effects/jump/, FRAMES frames of FRAME_PX in a row, the ground point at ANCHOR_PX,
## drawn at ART_SCALE (0.5, the game's art scale). No effect has per-direction art (the dash cloud,
## sparks and ring are round, the spring and the jet thrust stand straight under the car), so
## `basis` and `heading` are unused. `height_px` is the pixels per unit (the game's PX_PER_UNIT; a
## scaled preview, the Cosmetics menu, passes its own, and the art scales with it). An unknown id
## draws the dash cloud.
static func draw_placeholder(ci: CanvasItem, id: String, t: float, origin: Vector2, _basis: Transform2D,
		_heading: float, height_px: float = PX_PER_UNIT) -> void:
	var sheet: Texture2D = SHEETS.get(id, SHEETS["dash_cloud"])
	var frame := clampi(int(t * FRAMES), 0, FRAMES - 1)
	var k := ART_SCALE * height_px / PX_PER_UNIT
	var src := Rect2(Vector2(frame * FRAME_PX.x, 0.0), FRAME_PX)
	var dst := Rect2((origin - Vector2(ANCHOR_PX) * k).round(), FRAME_PX * k)
	ci.draw_texture_rect_region(sheet, dst, src)
