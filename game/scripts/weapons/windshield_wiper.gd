extends "res://scripts/weapons/weapon.gd"
## The windshield wiper (task T-170; Weapons, Decisions, 2026-10-18): one wiper
## arm in front of the car that sweeps back and forth across a semicircle, all
## the time, turning with the car. An enemy the arm hits takes damage; a minion
## is also knocked back away from the car through its knockback call
## (minion.gd apply_knockback(), T-167); the kaiju is damaged but never pushed.
## It is the only weapon that pushes. Every number comes from
## res://data/weapons.json ("wiper") through WeaponData.wiper_at(); the garage
## damage bonus multiplies the damage (weapon.gd, boosted_damage()).
##
## One of the run's weapons (listed in weapons.gd's WEAPON_SCRIPTS, id
## "wiper"): a run starts without it (tier 0); `run.weapons.upgrade("wiper")`
## gives it (0 to 1) and applies tiers 2 to 8. The rack steps it once per
## physics step while it is owned and the run is going, so it stops while the
## run is paused or after it ends.
##
## The arm (the agent's proposal, T-170 result notes): it turns round a pivot
## on the car's nose (PIVOT_OFFSET_UNITS ahead of the car's centre) and reaches
## `length` units from it. Its angle is measured from the car's facing:
## 0 straight ahead, it sweeps between -arc/2 and +arc/2 (the semicircle, 180
## degrees) at `sweep_degrees_per_second`, turning back at each end. A run
## gets it at the -arc/2 end, sweeping towards +arc/2.
##
## Hits (proposal): each step the arm sweeps from its last angle to its new
## one; an enemy is hit when its body (the rack's radius_of()) touches the
## area swept this step. One enemy is hit at most once per pass (one sweep
## from one end to the other) and never twice within `hit_cooldown` seconds.
## The push goes straight away from the car's centre, `knockback_distance`
## units.
##
## Look: a placeholder wiper blade drawn in code (WiperDrawing, below) in the
## run's View: a dark arm with a pale grey rubber blade, never Redgull red.
## It is drawn over the car while the arm points down the screen and under it
## while it points up. The art task swaps the final art in.

## Flat world pixels per unit (Car.PX_PER_UNIT).
const PX_PER_UNIT := 16.0
## The run's isometric projection (run.gd ISO_TRANSFORM).
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## The arm's pivot: this far ahead of the car's centre (the car is 1 unit
## long, so this is its nose). A placement, not a balancing number.
const PIVOT_OFFSET_UNITS := 0.5
## Float tolerance.
const EPS := 1e-6
## The playtest switch file (res://data/playtest.json), one key of several.
const PLAYTEST_FILE := "playtest"
const PLAYTEST_KEY := "wiper_at_start"
## The group the kaiju is in (kaiju.gd): never pushed unless the data says so.
const KAIJU_GROUP := "kaiju"
## Placeholder colours (opaque, hard edged: Visual style). A dark steel arm
## and a pale grey rubber blade with a dark outline; never Redgull red.
const ARM_COLOUR := Color(0.18, 0.2, 0.26, 1.0)
const BLADE_COLOUR := Color(0.78, 0.82, 0.86, 1.0)
const OUTLINE_COLOUR := Color(0.05, 0.07, 0.16, 1.0)

## Tests set this to 0 (off) or 1 (on) to override data/playtest.json; -1 reads the file.
static var playtest_override := -1

## Every hit, with the damage dealt and whether the enemy was pushed.
signal enemy_hit(enemy: Node, amount: float, pushed: bool)

## WeaponData.wiper_at(tier) (tier 1's values while not owned), damage boosted.
var stats: Dictionary = {}
## The arm's angle from the car's facing, in degrees (-arc/2 to +arc/2).
var sweep_angle := 0.0
## +1 sweeping towards +arc/2, -1 back.
var sweep_dir := 1.0
## Passes started so far (one per turn at an end), for "once per pass".
var pass_index := 0
## Hits dealt so far (all enemies) this run.
var hits := 0
## Recently hit enemies: instance id -> [pass index, seconds since the hit].
var last_hit: Dictionary = {}
## The placeholder drawing (in the run's View), made the first time the wiper
## is owned in a run scene.
var drawing: Node2D = null
## True when the arm turned back at an end during the last step.
var _turned_this_step := false


func _init() -> void:
	weapon_id = "wiper"
	starts_owned = false
	stats = data.wiper_at(1)
	_reset_sweep()


## The playtest switch: data/playtest.json "wiper_at_start" (or playtest_override).
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
	stats = data.wiper_at(maxi(tier, 1))
	stats["damage"] = boosted_damage(float(stats["damage"]))
	if is_owned():
		_ensure_drawing()
	else:
		last_hit.clear()
		_reset_sweep()
	_update_drawing()


func reset_for_run() -> void:
	hits = 0
	last_hit.clear()
	_reset_sweep()
	super.reset_for_run()


func _reset_sweep() -> void:
	sweep_angle = -half_arc()
	sweep_dir = 1.0
	pass_index = 0


# --- Each step -------------------------------------------------------------

## One physics step of `dt` seconds (the rack calls it while owned and the run
## is going, after the car has moved).
func step(dt: float) -> void:
	if _car() == null:
		return
	var cooldown: float = float(stats["hit_cooldown"])
	for id in last_hit.keys():
		last_hit[id][1] += dt
	var from := sweep_angle
	_advance(dt)
	var lo := minf(from, sweep_angle)
	var hi := maxf(from, sweep_angle)
	if _turned_this_step:
		# The arm reached an end and came back: it swept up to that end.
		lo = minf(lo, -half_arc()) if sweep_dir > 0.0 else lo
		hi = maxf(hi, half_arc()) if sweep_dir < 0.0 else hi
	for e in targets():
		if not _touches_swept(e, lo, hi):
			continue
		var id: int = e.get_instance_id()
		if last_hit.has(id):
			var rec: Array = last_hit[id]
			if int(rec[0]) == pass_index or float(rec[1]) < cooldown - EPS:
				continue
		last_hit[id] = [pass_index, 0.0]
		_hit(e)
	# Forget enemies hit in an earlier pass whose cooldown is over.
	for id in last_hit.keys():
		if int(last_hit[id][0]) != pass_index and float(last_hit[id][1]) >= cooldown - EPS:
			last_hit.erase(id)
	_update_drawing()


## Moves the arm one step, turning back at the ends (a new pass each time).
func _advance(dt: float) -> void:
	_turned_this_step = false
	var half := half_arc()
	var move := float(stats["sweep_degrees_per_second"]) * dt
	var a := sweep_angle + sweep_dir * move
	# A loop, for very large steps (never in a 50 Hz game, cheap anyway).
	while a > half + EPS or a < -half - EPS:
		if a > half:
			a = half - (a - half)
		else:
			a = -half + (-half - a)
		sweep_dir = -sweep_dir
		pass_index += 1
		_turned_this_step = true
	sweep_angle = clampf(a, -half, half)


## Half the sweep, in degrees (90 for the semicircle).
func half_arc() -> float:
	return float(stats["sweep_arc_degrees"]) / 2.0


## The arm's length now, in units.
func length() -> float:
	return float(stats["length"])


## Every living, damageable enemy in the run (the rack's rule).
func targets() -> Array:
	return rack.living_enemies() if rack != null else []


## The car's centre in units (flat world), from its driving model.
func car_units() -> Vector2:
	var car := _car()
	return Vector2(car.model.x, car.model.y) if car != null else Vector2.ZERO


## The car's facing (radians, flat world).
func car_rotation() -> float:
	var car := _car()
	return float(car.model.rotation) if car != null else 0.0


## The car's forward direction (flat world, unit length).
func forward() -> Vector2:
	var r := car_rotation()
	return Vector2(cos(r), sin(r))


## The arm's pivot on the car's nose (flat world, units).
func pivot_units() -> Vector2:
	return car_units() + forward() * PIVOT_OFFSET_UNITS


## The arm's direction in the world at `angle_deg` from the car's facing.
func arm_direction(angle_deg: float = NAN) -> Vector2:
	var a := sweep_angle if is_nan(angle_deg) else angle_deg
	return forward().rotated(deg_to_rad(a))


## The arm's tip now (flat world, units).
func tip_units() -> Vector2:
	return pivot_units() + arm_direction() * length()


## Whether an enemy's body touches the area the arm swept between `lo` and
## `hi` degrees (from the car's facing) this step.
func _touches_swept(e: Node, lo: float, hi: float) -> bool:
	var c := enemy_units(e)
	var r: float = maxf(rack.radius_of(e), 0.0)
	var p := pivot_units()
	var rel := c - p
	var d := rel.length()
	if d > length() + r + EPS:
		return false
	if d <= r + EPS:
		return true
	# The swept wedge (out to the tip's path plus the body's radius).
	var a := rad_to_deg(forward().angle_to(rel))
	if a >= lo - EPS and a <= hi + EPS:
		return true
	# The arm where it started and ended this step: the body touching it.
	for edge in [lo, hi]:
		if _distance_to_arm(c, edge) <= r + EPS:
			return true
	return false


## Distance from point `c` to the arm at `angle_deg`.
func _distance_to_arm(c: Vector2, angle_deg: float) -> float:
	var p := pivot_units()
	var tip := p + arm_direction(angle_deg) * length()
	return c.distance_to(Geometry2D.get_closest_point_to_segment(c, p, tip))


static func enemy_units(e: Node) -> Vector2:
	if e.has_method("position_units"):
		return e.position_units()
	return (e as Node2D).position / PX_PER_UNIT


## True when the wiper pushes this enemy: it has the knockback call (only
## minions have it, T-167) and is not the kaiju (unless the data allows it).
func pushes(e: Node) -> bool:
	if not e.has_method("apply_knockback"):
		return false
	return bool(stats["knockback_kaiju"]) or not e.is_in_group(KAIJU_GROUP)


func _hit(e: Node) -> void:
	var amount: float = stats["damage"]
	var push := pushes(e)
	hits += 1
	var away := enemy_units(e) - car_units()
	if away.length() < 0.001:
		away = forward()
	e.take_damage(amount)
	if push and is_instance_valid(e) and not (e.has_method("is_dead") and e.is_dead()):
		e.apply_knockback(away, float(stats["knockback_distance"]))
	enemy_hit.emit(e, amount, push)


# --- Drawing (placeholder) -------------------------------------------------

## Makes the drawing in the run's View, once.
func _ensure_drawing() -> void:
	if drawing != null and is_instance_valid(drawing):
		return
	if rack == null or rack.run == null:
		return
	var view = rack.run.get("view_root")
	if view == null:
		return
	drawing = WiperDrawing.new()
	drawing.name = "WindshieldWiper"
	drawing.visible = false
	view.add_child(drawing)


## Puts the blade on the car's nose at the arm's angle, over or under the car
## sprite by which way it points on screen, shown while owned.
func _update_drawing() -> void:
	if drawing == null or not is_instance_valid(drawing):
		return
	var was_visible := drawing.visible
	drawing.visible = is_owned()
	var car := _car()
	if car == null:
		return
	var pivot_px := pivot_units() * PX_PER_UNIT
	var tip_px := tip_units() * PX_PER_UNIT
	drawing.position = ISO_TRANSFORM * pivot_px
	drawing.set_arm(ISO_TRANSFORM.basis_xform(tip_px - pivot_px))
	if drawing.visible and not was_visible:
		drawing.reset_physics_interpolation()  # no slide from the last run's spot
	var sprite = rack.run.get("car_sprite") if rack.run != null else null
	if sprite != null and sprite.get_parent() == drawing.get_parent():
		var view: Node = drawing.get_parent()
		var is_over: bool = drawing.get_index() > sprite.get_index()
		if drawn_over_car() and not is_over:
			view.move_child(drawing, sprite.get_index())  # just over the car
		elif not drawn_over_car() and is_over:
			view.move_child(drawing, sprite.get_index())  # just under the car


## True when the arm's middle is lower on screen than the car's centre (closer
## to the viewer), so the blade is drawn over the car.
func drawn_over_car() -> bool:
	var mid := (pivot_units() + tip_units()) / 2.0 - car_units()
	return ISO_TRANSFORM.basis_xform(mid).y >= 0.0


## The placeholder blade: a line from the pivot to the tip (isometric screen
## pixels, relative to the pivot), drawn as opaque hard-edged lines.
class WiperDrawing:
	extends Node2D

	var arm_px := Vector2.ZERO

	func set_arm(v: Vector2) -> void:
		if not v.is_equal_approx(arm_px):
			arm_px = v
			queue_redraw()

	## Every colour the blade draws with (tests check none is Redgull red).
	func colours() -> Array:
		return [OUTLINE_COLOUR, ARM_COLOUR, BLADE_COLOUR]

	func _draw() -> void:
		if arm_px.length() < 0.5:
			return
		var blade_start := arm_px * 0.2
		draw_line(Vector2.ZERO, arm_px, OUTLINE_COLOUR, 5.0, false)
		draw_line(Vector2.ZERO, arm_px, ARM_COLOUR, 3.0, false)
		draw_line(blade_start, arm_px, BLADE_COLOUR, 3.0, false)
		draw_rect(Rect2(-3.0, -3.0, 6.0, 6.0), OUTLINE_COLOUR, true)
		draw_rect(Rect2(-2.0, -2.0, 4.0, 4.0), ARM_COLOUR, true)
