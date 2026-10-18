extends "res://scripts/weapons/weapon.gd"
## The neon underglow (task T-168; Weapons, Decisions, 2026-10-18): neon lights
## under the car make a circular area around it. An enemy takes one hit as soon
## as it enters the area, and every enemy inside takes one hit every
## `tick_interval` seconds. Every number comes from res://data/weapons.json
## ("underglow") through WeaponData.underglow_at(); the garage damage bonus
## multiplies the damage (weapon.gd, boosted_damage()).
##
## One of the run's weapons (listed in weapons.gd's WEAPON_SCRIPTS, id
## "underglow"): a run starts without it (tier 0); `run.weapons.upgrade("underglow")`
## gives it (0 to 1) and applies tiers 2 to 8. The rack steps it once per
## physics step while it is owned and the run is going, so it does nothing
## while the run is paused or after it ends.
##
## Who is inside: the rack's target rule, as the flamethrower's. A minion is
## inside when its centre is within `radius` of the car's centre; an enemy that
## reports its body size with hit_radius_units() (the kaiju) when its body
## overlaps the circle at all.
##
## Hit timing (the agent's proposal, T-168 result notes): each enemy has its
## own clock. An enemy inside is hit when it has not been hit by the underglow
## in the last `tick_interval` seconds. So an enemy entering is hit at once, one
## staying inside is hit again every `tick_interval`, and one that leaves and
## comes back before its interval is over is not hit again on entering: it is
## hit when its interval is over, if it is still inside.
##
## Look: a placeholder neon ring drawn in code (UnderglowDrawing, below) in the
## run's View, at the very bottom of the car's drawing (under the car sprite,
## the drift smoke and the flames), showing the damage circle in the isometric
## view. Cyan, never Redgull red. The art task swaps the final art in.

## Flat world pixels per unit (Car.PX_PER_UNIT).
const PX_PER_UNIT := 16.0
## The run's isometric projection (run.gd ISO_TRANSFORM).
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## Float tolerance for the timers.
const EPS := 1e-6
## The playtest switch file (res://data/playtest.json), one key of several.
const PLAYTEST_FILE := "playtest"
const PLAYTEST_KEY := "underglow_at_start"
## Placeholder ring colours (opaque, no anti-aliasing: Visual style). Cyan neon
## from the city's palette; never Redgull red.
const RING_COLOUR := Color(0.25, 0.95, 1.0, 1.0)
const RING_INNER_COLOUR := Color(0.1, 0.55, 0.75, 1.0)
const RING_OUTLINE_COLOUR := Color(0.05, 0.07, 0.16, 1.0)
## Points of the drawn ellipse.
const RING_POINTS := 64

## Tests set this to 0 (off) or 1 (on) to override data/playtest.json; -1 reads the file.
static var playtest_override := -1

## Every hit, with the damage dealt.
signal enemy_hit(enemy: Node, amount: float)

## WeaponData.underglow_at(tier) (tier 1's values while not owned), damage boosted.
var stats: Dictionary = {}
## Hits dealt so far (all enemies) this run.
var hits := 0
## Enemies inside the circle on the last step: instance id -> node.
var inside: Dictionary = {}
## Seconds since each recently hit enemy's last hit: instance id -> seconds.
## An entry is dropped once its interval is over and the enemy is outside.
var since_hit: Dictionary = {}
## The placeholder drawing (in the run's View), made the first time the
## underglow is owned in a run scene.
var drawing: Node2D = null


func _init() -> void:
	weapon_id = "underglow"
	starts_owned = false
	stats = data.underglow_at(1)


## The playtest switch: data/playtest.json "underglow_at_start" (or playtest_override).
static func playtest_switch_on() -> bool:
	if playtest_override >= 0:
		return playtest_override == 1
	var r := GameData.load_file(PLAYTEST_FILE)
	if not r.ok:
		return false
	var v := GameData.get_value(r.data, PLAYTEST_KEY)
	return v.ok and bool(v.data)


func _car() -> Node2D:
	if rack == null or rack.car == null or not is_instance_valid(rack.car):
		return null
	return rack.car


# --- Tiers and runs --------------------------------------------------------

func apply_tier() -> void:
	stats = data.underglow_at(maxi(tier, 1))
	stats["damage"] = boosted_damage(float(stats["damage"]))
	if is_owned():
		_ensure_drawing()
	else:
		inside.clear()
		since_hit.clear()
	_update_drawing()


func reset_for_run() -> void:
	hits = 0
	inside.clear()
	since_hit.clear()
	super.reset_for_run()


# --- Each step -------------------------------------------------------------

## One physics step of `dt` seconds (the rack calls it while owned and the run
## is going, after the car has moved).
func step(dt: float) -> void:
	if _car() == null:
		return
	var interval: float = float(stats["tick_interval"])
	for id in since_hit.keys():
		since_hit[id] += dt
	var now_inside := {}
	for e in targets():
		if is_inside(e):
			now_inside[e.get_instance_id()] = e
	for id in now_inside:
		var e: Node = now_inside[id]
		var entering: bool = not inside.has(id)
		var due: bool = not since_hit.has(id) or since_hit[id] >= interval - EPS
		if entering and not bool(stats["damage_on_enter"]) and not since_hit.has(id):
			# Without damage on entering, the first hit waits one interval.
			since_hit[id] = 0.0
			continue
		if due:
			since_hit[id] = 0.0
			_hit(e)
	# Forget enemies that are outside and whose interval is over.
	for id in since_hit.keys():
		if not now_inside.has(id) and since_hit[id] >= interval - EPS:
			since_hit.erase(id)
	inside = now_inside
	_update_drawing()


## Every living, damageable enemy in the run (the rack's rule).
func targets() -> Array:
	return rack.living_enemies() if rack != null else []


## The damage circle's radius now, in units.
func radius() -> float:
	return float(stats["radius"])


## The car's centre in units (flat world), from its driving model.
func car_units() -> Vector2:
	var car := _car()
	return Vector2(car.model.x, car.model.y) if car != null else Vector2.ZERO


## Whether a point (flat world, units) is inside the circle now.
func contains_point(p: Vector2) -> bool:
	if _car() == null:
		return false
	return p.distance_to(car_units()) <= radius() + EPS


## Whether an enemy is inside the circle now: its body overlapping it when it
## reports its size (hit_radius_units(), the kaiju), its centre otherwise (the
## minions), as the flamethrower's rule (board, 2026-10-14).
func is_inside(e: Node) -> bool:
	if _car() == null:
		return false
	var c := enemy_units(e)
	if e.has_method("hit_radius_units"):
		return c.distance_to(car_units()) <= radius() + maxf(float(e.hit_radius_units()), 0.0) + EPS
	return contains_point(c)


static func enemy_units(e: Node) -> Vector2:
	if e.has_method("position_units"):
		return e.position_units()
	return (e as Node2D).position / PX_PER_UNIT


func _hit(e: Node) -> void:
	var amount: float = stats["damage"]
	hits += 1
	enemy_hit.emit(e, amount)
	e.take_damage(amount)


# --- Drawing (placeholder) -------------------------------------------------

## Makes the drawing in the run's View, at the bottom of the car's drawing, once.
func _ensure_drawing() -> void:
	if drawing != null and is_instance_valid(drawing):
		return
	if rack == null or rack.run == null:
		return
	var view = rack.run.get("view_root")
	if view == null:
		return
	drawing = UnderglowDrawing.new()
	drawing.name = "NeonUnderglow"
	drawing.visible = false
	view.add_child(drawing)
	view.move_child(drawing, 0)  # under the car sprite, the smoke and the flames


## Puts the ring on the car, sized to the damage circle, shown while owned.
func _update_drawing() -> void:
	if drawing == null or not is_instance_valid(drawing):
		return
	var was_visible := drawing.visible
	drawing.visible = is_owned()
	drawing.set_radius_px(radius() * PX_PER_UNIT)
	var car := _car()
	if car != null:
		drawing.position = ISO_TRANSFORM * (car_units() * PX_PER_UNIT)
		if drawing.visible and not was_visible:
			drawing.reset_physics_interpolation()  # no slide from the last run's spot


## The placeholder ring: the damage circle (flat world) seen in the isometric
## view, an ellipse twice as wide as tall, drawn as opaque hard-edged lines.
class UnderglowDrawing:
	extends Node2D

	var radius_px := 0.0

	func set_radius_px(r: float) -> void:
		if not is_equal_approx(r, radius_px):
			radius_px = r
			queue_redraw()

	## The ring's points in the drawing's own pixels (the circle through ISO_TRANSFORM).
	func ring_points(r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in RING_POINTS + 1:
			var a := TAU * float(i) / float(RING_POINTS)
			pts.append(ISO_TRANSFORM.basis_xform(Vector2(cos(a), sin(a)) * r))
		return pts

	## Every colour the ring draws with (tests check none is Redgull red).
	func colours() -> Array:
		return [RING_OUTLINE_COLOUR, RING_COLOUR, RING_INNER_COLOUR]

	func _draw() -> void:
		if radius_px <= 0.0:
			return
		draw_polyline(ring_points(radius_px + 1.0), RING_OUTLINE_COLOUR, 4.0, false)
		draw_polyline(ring_points(radius_px), RING_COLOUR, 2.0, false)
		draw_polyline(ring_points(radius_px - 3.0), RING_INNER_COLOUR, 1.0, false)
