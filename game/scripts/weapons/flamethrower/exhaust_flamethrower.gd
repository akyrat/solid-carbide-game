extends "res://scripts/weapons/weapon.gd"
## The exhaust flamethrower (task T-042; Weapons, Decisions): flames out of the
## car's exhaust, only while the car is drifting, burning every enemy inside
## them. It copies the Unity prototype's Flame Exhaust (Unity weapons report,
## section 3) with the board's fixes (Weapons, Decisions): damage is never
## rounded, and the flame's area is the same size whichever way the car faces.
## Every number comes from res://data/weapons.json through WeaponData.flame_at().
##
## One of the run's weapons (weapon.gd, listed in weapons.gd's WEAPON_SCRIPTS):
## the rack (`run.weapons`) owns it, steps it while owned, and resets it at
## every new run, where it is not owned (tier 0). Get it or upgrade it with
## `run.weapons.upgrade("flamethrower")` (the level-up's call, T-043); the
## playtest switch (data/playtest.json "flamethrower_at_start") makes the rack
## make that call at the start of every run (weapons.gd).
##
## Each step while owned:
## - On: the car's drift state (CarModel.is_drifting: W, or S, held with A or
##   D) at `min_speed` or faster; then for `linger` seconds more; or always,
##   from tier 8.
## - Area: a rectangle behind the car in the flat world, lined up with the car,
##   from `inner_edge` behind its centre, `area_depth` deep and `area_width`
##   wide at full size. Each drift starts it at `ramp_start_fraction` of full
##   size, growing to full size over `ramp_seconds` of drifting (tier 8: always
##   full size). An enemy is inside when its centre is; one that reports its
##   body size with hit_radius_units() (the kaiju) when its body overlaps it.
## - Damage: an enemy entering takes one hit at once and flashes orange for
##   `burn_flash_seconds`; every `tick_interval` while the flame is on, every
##   enemy inside takes one hit. One hit = take_damage(`damage`). No push.
## - Targets: the rack's living_enemies() (the group "enemies": the minions
##   now, the kaiju when it joins the group).

## Flat world pixels per unit (Car.PX_PER_UNIT).
const PX_PER_UNIT := 16.0
## Where the drawn flame starts, in units behind the car's centre (Unity
## report, section 3, "The particles"). Drawing only; the damage area is
## the data's.
const EXHAUST_OFFSET_UNITS := 0.42
## The run's isometric projection (run.gd ISO_TRANSFORM).
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## Float tolerance for the timers (0.2 s is 10 steps of 0.02 s).
const EPS := 1e-6
## The placeholder flame drawing; the art task swaps it.
const FlameScene := preload("res://scenes/weapons/flamethrower/exhaust_flame.tscn")
## The playtest switch file (res://data/playtest.json), one key of several.
const PLAYTEST_FILE := "playtest"
const PLAYTEST_KEY := "flamethrower_at_start"

## Tests set this to 0 (off) or 1 (on) to override data/playtest.json; -1 reads the file.
static var playtest_override := -1

## Every hit, with the damage dealt.
signal enemy_hit(enemy: Node, amount: float)

## WeaponData.flame_at(tier) (tier 1's values while not owned).
var stats: Dictionary = {}
## The burn flash's tint (weapons.json, flamethrower.burn_flash_tint).
var burn_tint := Color(1, 0.62, 0.38, 1)
## The placeholder drawing (CPUParticles2D in the run's View), made the first
## time the flamethrower is owned in a run scene.
var flame_drawing: CPUParticles2D = null

## Whether the flame is on this step.
var active := false
## Seconds the flame stays on after the drift ends.
var linger_left := 0.0
## Seconds of drifting since the flame came on (for the size ramp).
var drift_time := 0.0
## The shared damage tick timer.
var tick_timer := 0.0
## Hits dealt so far (all enemies) this run.
var hits := 0
## Enemies inside the flame on the last step: instance id -> node.
var inside: Dictionary = {}
## Enemies flashing: instance id -> {"node": Node, "left": float}.
var burning: Dictionary = {}

## The turn speed multiplier already applied to `_turn_car` (tier 7).
var _applied_turn := 1.0
var _turn_car: Node = null


func _init() -> void:
	weapon_id = "flamethrower"
	starts_owned = false
	var tint = GameData.get_value(GameData.unwrap(GameData.load_file("weapons")), "flamethrower.burn_flash_tint")
	if tint.ok and tint.data is Array and tint.data.size() >= 3:
		var a: Array = tint.data
		burn_tint = Color(float(a[0]), float(a[1]), float(a[2]), float(a[3]) if a.size() > 3 else 1.0)
	stats = data.flame_at(1)


## The playtest switch: data/playtest.json "flamethrower_at_start" (or playtest_override).
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
	stats = data.flame_at(maxi(tier, 1))
	stats["damage"] = boosted_damage(float(stats["damage"]))
	_apply_turn_speed()
	if is_owned():
		_ensure_drawing()
	else:
		_stop()
	_update_drawing()


func reset_for_run() -> void:
	hits = 0
	_clear_burns()
	_stop()
	super.reset_for_run()


## Tier 7's steering: multiplies the car's turn speed (once per car; undone
## when the tier goes back below 7). A new run's car starts at its own speed.
func _apply_turn_speed() -> void:
	var car := _car()
	if car == null:
		return
	if car != _turn_car:
		_turn_car = car
		_applied_turn = 1.0
	var want: float = stats["turn_speed_multiplier"] if is_owned() else 1.0
	if not is_equal_approx(want, _applied_turn):
		car.model.tuning.turn_speed *= want / _applied_turn
		_applied_turn = want


func _stop() -> void:
	active = false
	linger_left = 0.0
	_reset_flame()


func _reset_flame() -> void:
	drift_time = 0.0
	tick_timer = 0.0
	inside.clear()


# --- Each step -----------------------------------------------------------

## One physics step of `dt` seconds (the rack calls it while owned, after the car has moved).
func step(dt: float) -> void:
	var car := _car()
	if car == null:
		return
	var m = car.model
	var gate: bool = m.is_drifting and m.total_speed() >= float(stats["min_speed"])
	if gate:
		linger_left = float(stats["linger"])
	else:
		linger_left = maxf(0.0, linger_left - dt)
	active = bool(stats["always_on"]) or gate or linger_left > EPS
	_age_burns(dt)
	if not active:
		_reset_flame()
		_update_drawing()
		return
	if gate:
		drift_time += dt
	var now_inside := {}
	for e in targets():
		if is_inside(e):
			now_inside[e.get_instance_id()] = e
	for id in now_inside:
		if not inside.has(id):
			var e: Node = now_inside[id]
			_hit(e)
			_start_burn(e)
	tick_timer += dt
	if tick_timer >= float(stats["tick_interval"]) - EPS:
		tick_timer = 0.0
		for id in now_inside:
			var e: Node = now_inside[id]
			if rack.is_target(e):
				_hit(e)
	inside = now_inside
	_update_drawing()


## Every living, damageable enemy in the run (the rack's rule).
func targets() -> Array:
	return rack.living_enemies() if rack != null else []


## The flame's size now, as a fraction of full size (the drift ramp; 1 when always on).
func size_fraction() -> float:
	if bool(stats["always_on"]):
		return 1.0
	var start: float = stats["ramp_start_fraction"]
	var ramp: float = maxf(float(stats["ramp_seconds"]), EPS)
	return lerpf(start, 1.0, clampf(drift_time / ramp, 0.0, 1.0))


## The damage area now, in the car's frame and units: {inner, depth, half_width}.
func area() -> Dictionary:
	var f := size_fraction()
	return {
		"inner": float(stats["inner_edge"]),
		"depth": float(stats["area_depth"]) * f,
		"half_width": float(stats["area_width"]) * 0.5 * f,
	}


## The car's centre in units (flat world), from its driving model.
func car_units() -> Vector2:
	var car := _car()
	return Vector2(car.model.x, car.model.y) if car != null else Vector2.ZERO


## Whether a point (flat world, units) is inside the damage area now.
func contains_point(p: Vector2) -> bool:
	var car := _car()
	if car == null:
		return false
	var a := area()
	var rot: float = car.model.rotation
	var forward := Vector2(cos(rot), sin(rot))
	var right := Vector2(-sin(rot), cos(rot))
	var d := p - car_units()
	var back := -d.dot(forward)
	return back >= a["inner"] and back <= a["inner"] + a["depth"] and absf(d.dot(right)) <= a["half_width"]


## Whether an enemy is inside the damage area now. An enemy that reports its
## body size (hit_radius_units(), the kaiju) is inside when its body overlaps
## the area at all (board, 2026-10-14); any other enemy (the minions) when its
## centre is inside, as in the Unity prototype.
func is_inside(e: Node) -> bool:
	if e.has_method("hit_radius_units"):
		return overlaps_circle(enemy_units(e), float(e.hit_radius_units()))
	return contains_point(enemy_units(e))


## Whether a circle (flat world, units) overlaps the damage area now.
func overlaps_circle(centre: Vector2, radius: float) -> bool:
	var car := _car()
	if car == null:
		return false
	var a := area()
	var rot: float = car.model.rotation
	var forward := Vector2(cos(rot), sin(rot))
	var right := Vector2(-sin(rot), cos(rot))
	var d := centre - car_units()
	var back := -d.dot(forward)
	var side := d.dot(right)
	# Closest point of the rectangle to the centre, in the car's frame.
	var cb := clampf(back, a["inner"], a["inner"] + a["depth"])
	var cs := clampf(side, -a["half_width"], a["half_width"])
	return Vector2(back - cb, side - cs).length() <= maxf(radius, 0.0)


static func enemy_units(e: Node) -> Vector2:
	if e.has_method("position_units"):
		return e.position_units()
	return (e as Node2D).position / PX_PER_UNIT


func _hit(e: Node) -> void:
	var amount: float = stats["damage"]
	hits += 1
	enemy_hit.emit(e, amount)
	e.take_damage(amount)


# --- Burn flash (looks only) ---------------------------------------------

func _start_burn(e: Node) -> void:
	if not rack.is_target(e):
		return
	burning[e.get_instance_id()] = {"node": e, "left": float(stats["burn_flash_seconds"])}
	_tint(e, burn_tint)


func _age_burns(dt: float) -> void:
	for id in burning.keys():
		var b: Dictionary = burning[id]
		b["left"] -= dt
		if b["left"] <= EPS or not is_instance_valid(b["node"]):
			if is_instance_valid(b["node"]):
				_tint(b["node"], Color.WHITE)
			burning.erase(id)


func _clear_burns() -> void:
	for id in burning:
		var n = burning[id]["node"]
		if is_instance_valid(n):
			_tint(n, Color.WHITE)
	burning.clear()


## Whether an enemy is flashing now.
func is_burning(e: Node) -> bool:
	return e != null and burning.has(e.get_instance_id())


func _tint(e: Node, c: Color) -> void:
	var s = e.get("sprite")
	if s != null and is_instance_valid(s) and s is CanvasItem:
		s.modulate = c


# --- Drawing (placeholder) -----------------------------------------------

## Makes the drawing in the run's View, just under the car sprite, once.
func _ensure_drawing() -> void:
	if flame_drawing != null and is_instance_valid(flame_drawing):
		return
	if rack == null or rack.run == null:
		return
	var view = rack.run.get("view_root")
	if view == null:
		return
	flame_drawing = FlameScene.instantiate()
	flame_drawing.name = "ExhaustFlame"
	view.add_child(flame_drawing)
	var sprite = rack.run.get("car_sprite")
	if sprite != null and sprite.get_parent() == view:
		view.move_child(flame_drawing, sprite.get_index())  # just under the car


## Puts the drawn flame on the car's exhaust, pointing back, sized like the
## damage area's size multiplier, emitting while the flame is on.
func _update_drawing() -> void:
	var car := _car()
	if flame_drawing == null or not is_instance_valid(flame_drawing) or car == null:
		return
	var rot: float = car.model.rotation
	var back := -Vector2(cos(rot), sin(rot))
	var exhaust_px := (car_units() + back * EXHAUST_OFFSET_UNITS) * PX_PER_UNIT
	flame_drawing.position = ISO_TRANSFORM * exhaust_px
	flame_drawing.rotation = ISO_TRANSFORM.basis_xform(back).angle()
	var s: float = float(stats["size_multiplier"]) * size_fraction()
	flame_drawing.scale = Vector2(s, s)
	flame_drawing.emitting = active and is_owned()
