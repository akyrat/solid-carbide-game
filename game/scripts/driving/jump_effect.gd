extends Node2D
## The jump effect (task T-551; Drifting, Decisions, "A jump effect around the car"): when the car
## jumps (Car.jump_started: the Jump power-up's jump from the ground, "hop", and the launch off a
## rail, "rail_launch"; a ramp's take-off is not a jump, the proposal), the equipped jump effect
## (JumpEffectChoice.equipped_id(): the saved cosmetic, T-552; the dash cloud until then) plays
## around the place the car left from.
##
## The look is a code-drawn PLACEHOLDER per effect id, in the pixel look (flat colours, hard
## edges), that T-556 replaces with art: draw_placeholder() is the one place to swap. The Cosmetics
## menu (T-553) can preview an effect with the same static draw_placeholder() on any CanvasItem.
##  - dash_cloud: six grey puffs spreading out on the ground and fading.
##  - spring: a steel zigzag coil standing up from the ground, stretching and fading.
##  - jet_thrust: an orange and yellow flame from the ground up under the car, shrinking.
##  - stunt_sparks: yellow and orange sparks bursting out from under the car and dropping.
##  - shockwave_ring: a pale ring rippling out flat on the ground.
## Each lasts `jump_effect_seconds` (data/rail_grind.json). Several can play at once.
## It draws in the run's car view (view_root, iso pixels) at the stored place and height itself, so
## its own position stays at zero.

const JumpEffectChoice := preload("res://scripts/driving/jump_effect_choice.gd")
const PX_PER_UNIT := 16.0
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
## point the car left from). `basis` maps flat ground units to pixels (the view's projection times
## the pixels per unit; no translation); one unit of height is `height_px` pixels up the screen (the
## game's PX_PER_UNIT; a scaled preview passes its own). `heading` is the car's (radians). T-556
## swaps its art in here.
static func draw_placeholder(ci: CanvasItem, id: String, t: float, origin: Vector2, basis: Transform2D,
		heading: float, height_px: float = PX_PER_UNIT) -> void:
	var up := Vector2(0.0, -height_px)
	var fade := 1.0 - t
	match id:
		"spring":
			var h := 0.3 + 1.0 * sin(minf(t * 2.0, 1.0) * PI * 0.5)
			var pts := PackedVector2Array()
			var coils := 6
			for i in coils * 2 + 1:
				var k := float(i) / float(coils * 2)
				var side := 0.0 if i == 0 or i == coils * 2 else (0.35 if i % 2 == 1 else -0.35)
				pts.append((origin + basis.basis_xform(Vector2(side, -side) * 0.7) + up * h * k).round())
			ci.draw_polyline(pts, Color8(185, 195, 205, int(255 * fade)), 2.0, false)
		"jet_thrust":
			var flame := 1.2 * fade
			var w := 0.35 * fade + 0.05
			var side := basis.basis_xform(Vector2(w, -w))
			var tip := origin + up * flame
			ci.draw_polygon(PackedVector2Array([(origin - side).round(), (origin + side).round(), tip.round()]),
				PackedColorArray([Color8(255, 120, 30, int(230 * fade))]))
			ci.draw_polygon(PackedVector2Array([(origin - side * 0.5).round(), (origin + side * 0.5).round(),
				(origin + up * flame * 0.6).round()]), PackedColorArray([Color8(255, 230, 90, int(255 * fade))]))
		"stunt_sparks":
			for i in 10:
				var a := heading + TAU * float(i) / 10.0 + 0.3
				var r := 0.3 + 1.8 * t
				var p := origin + basis.basis_xform(Vector2(cos(a), sin(a)) * r) + up * (0.6 * t - 0.9 * t * t)
				var col := Color8(255, 220, 60, int(255 * fade)) if i % 2 == 0 else Color8(255, 140, 40, int(255 * fade))
				ci.draw_rect(Rect2(p.round() - Vector2(1, 1), Vector2(2, 2)), col)
		"shockwave_ring":
			var r := 0.5 + 2.0 * t
			var ring := PackedVector2Array()
			for i in 25:
				var a := TAU * float(i) / 24.0
				ring.append((origin + basis.basis_xform(Vector2(cos(a), sin(a)) * r)).round())
			ci.draw_polyline(ring, Color8(205, 230, 255, int(230 * fade)), 2.0, false)
		_:  # dash_cloud, the default
			for i in 6:
				var a := heading + TAU * float(i) / 6.0
				var r := 0.6 + 1.2 * t
				var p := origin + basis.basis_xform(Vector2(cos(a), sin(a)) * r) + up * 0.15
				var size := roundf(6.0 * (1.0 - 0.5 * t))
				ci.draw_rect(Rect2(p.round() - Vector2(size, size) * 0.5, Vector2(size, size)),
					Color8(232, 232, 226, int(220 * fade)))

