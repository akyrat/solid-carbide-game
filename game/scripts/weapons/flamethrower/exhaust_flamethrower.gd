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
## - Area (T-267; Weapons, Decisions, "A smaller exhaust flame that burns what
##   it touches"): the flame as it is drawn, at every moment: the outline of
##   the pixels of the flame art's current cell (exhaust_flame_drawing.gd,
##   cell_hull()), at the drawn size (`size_multiplier` times the drift ramp,
##   from `ramp_start_fraction` to full over `ramp_seconds` of drifting; tier 8:
##   always full size), from the exhaust, pointing back, laid on the flat world.
##   An enemy is hit when any part of its body (the rack's radius_of()) touches
##   it. Before T-267 the area was a separate rectangle in the data, about half
##   the drawn flame's length, and minions counted only by their centre.
## - Damage: an enemy entering takes one hit at once and flashes orange for
##   `burn_flash_seconds`; every `tick_interval` while the flame is on, every
##   enemy inside takes one hit. One hit = take_damage(`damage`). No push.
## - Targets: the rack's living_enemies() (the group "enemies": the minions
##   now, the kaiju when it joins the group).

## Flat world pixels per unit (Car.PX_PER_UNIT).
const PX_PER_UNIT := 16.0
## Where the flame starts, in units behind the car's centre: the tailpipes,
## at the car's rear bumper. It was 0.42 (the Unity prototype's, report section
## 3, "The particles"), under the car's body; with the flame a quarter of the
## size (T-267) the whole flame would have been hidden under the car, so it
## starts at the rear (a proposal for the board's playtest). The drawing and the
## hit area both start here.
const EXHAUST_OFFSET_UNITS := 1.2
## The run's isometric projection (run.gd ISO_TRANSFORM).
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## The drawing's z_index in the car's View: one step behind the car and the enemies.
const DRAW_Z_BEHIND := -1
## Float tolerance for the timers (0.2 s is 10 steps of 0.02 s).
const EPS := 1e-6
## The flame drawing (T-071: the final art, exhaust_flame_drawing.gd).
const FlameScene := preload("res://scenes/weapons/flamethrower/exhaust_flame.tscn")
const DrawingScript := preload("res://scripts/weapons/flamethrower/exhaust_flame_drawing.gd")
## The playtest switch file (res://data/playtest.json), one key of several.
const PLAYTEST_FILE := "playtest"
## The id the flamethrower burns an enemy under (burn_flames.gd).
const BURN_SOURCE := "flamethrower"
const PLAYTEST_KEY := "flamethrower_at_start"

## Tests set this to 0 (off) or 1 (on) to override data/playtest.json; -1 reads the file.
static var playtest_override := -1

## Every hit, with the damage dealt.
signal enemy_hit(enemy: Node, amount: float)

## WeaponData.flame_at(tier) (tier 1's values while not owned).
var stats: Dictionary = {}
## The burn flash's tint (weapons.json, flamethrower.burn_flash_tint).
var burn_tint := Color(1, 0.62, 0.38, 1)
## The drawing (exhaust_flame_drawing.gd in the run's View), made the first
## time the flamethrower is owned in a run scene.
var flame_drawing: Node2D = null

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


## The drawn flame's scale now: the tier's size times the drift ramp. The drawing's
## `scale` and the hit area both use it, so they cannot differ.
func drawn_scale() -> float:
	return float(stats["size_multiplier"]) * size_fraction()


## Where the flame starts (its base), in units on the flat world.
func exhaust_units() -> Vector2:
	var car := _car()
	if car == null:
		return Vector2.ZERO
	var rot: float = car.model.rotation
	return car_units() - Vector2(cos(rot), sin(rot)) * EXHAUST_OFFSET_UNITS


## The flame cell being drawn now: the direction its screen angle picks, and the
## drawing's flicker frame (0 when there is no drawing).
func current_cell() -> int:
	var car := _car()
	if car == null:
		return 0
	var rot: float = car.model.rotation
	var back := -Vector2(cos(rot), sin(rot))
	var d := DrawingScript.direction_index(ISO_TRANSFORM.basis_xform(back).angle())
	var frame := 0
	if flame_drawing != null and is_instance_valid(flame_drawing):
		frame = flame_drawing.frame()
	return DrawingScript.cell_index(d, frame)


## The damage area now (T-267): the outline of the flame as it is drawn (the
## current cell's pixels, at the drawn scale, from the exhaust), in the flat
## world's units. The drawn pixels are at ART_SCALE screen pixels each times
## the drawing's scale, and the screen is the isometric projection of the flat
## world, so each outline point is taken back through the projection.
func hit_polygon() -> PackedVector2Array:
	var out := PackedVector2Array()
	if _car() == null:
		return out
	var inv := ISO_TRANSFORM.affine_inverse()
	var k: float = DrawingScript.ART_SCALE * drawn_scale() / PX_PER_UNIT
	var base := exhaust_units()
	for p in DrawingScript.cell_hull(current_cell()):
		out.append(base + inv.basis_xform(p) * k)
	return out


## The car's centre in units (flat world), from its driving model.
func car_units() -> Vector2:
	var car := _car()
	return Vector2(car.model.x, car.model.y) if car != null else Vector2.ZERO


## The car's height in units (car_height.gd): 0 on the street and for a car without one.
func car_height() -> float:
	var car := _car()
	if car == null:
		return 0.0
	var h = car.get("height")
	return float(h) if h != null else 0.0


## Whether a point (flat world, units) is inside the damage area now.
func contains_point(p: Vector2) -> bool:
	var poly := hit_polygon()
	return poly.size() >= 3 and Geometry2D.is_point_in_polygon(p, poly)


## Whether an enemy is hit now: any part of its body touches the drawn flame
## (T-267, replacing "its centre" for the minions; the kaiju as before).
func is_inside(e: Node) -> bool:
	return overlaps_circle(enemy_units(e), rack.radius_of(e) if rack != null else 0.5)


## Whether a circle (flat world, units) touches the damage area now.
func overlaps_circle(centre: Vector2, radius: float) -> bool:
	var poly := hit_polygon()
	if poly.size() < 3:
		return false
	if Geometry2D.is_point_in_polygon(centre, poly):
		return true
	var r := maxf(radius, 0.0)
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if a == b:
			continue
		if Geometry2D.get_closest_point_to_segment(centre, a, b).distance_to(centre) <= r:
			return true
	return false


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
	BurnFlames.add_source(e, BURN_SOURCE)  # T-071: the flames on the enemy (drawing only)


func _age_burns(dt: float) -> void:
	for id in burning.keys():
		var b: Dictionary = burning[id]
		b["left"] -= dt
		if b["left"] <= EPS or not is_instance_valid(b["node"]):
			if is_instance_valid(b["node"]):
				_tint(b["node"], Color.WHITE)
				BurnFlames.remove_source(b["node"], BURN_SOURCE)
			burning.erase(id)


func _clear_burns() -> void:
	for id in burning:
		var n = burning[id]["node"]
		if is_instance_valid(n):
			_tint(n, Color.WHITE)
			BurnFlames.remove_source(n, BURN_SOURCE)
	burning.clear()


## Whether an enemy is flashing now.
func is_burning(e: Node) -> bool:
	return e != null and burning.has(e.get_instance_id())


func _tint(e: Node, c: Color) -> void:
	var s = e.get("sprite")
	if s != null and is_instance_valid(s) and s is CanvasItem:
		s.modulate = c


# --- Drawing (the final art, T-071) --------------------------------------

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
	# T-267: one step behind the car's depth (z is relative to the View's). The car
	# and the enemies not covered by a building sit at the same depth, so a flame
	# at the car's depth drew over the enemies that came before the View in the
	# tree; one step down it is behind them and the car, over the ground, the
	# rooftops and the buildings (their depths are all at least 2 steps lower).
	flame_drawing.z_index = DRAW_Z_BEHIND
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
	var exhaust_px := exhaust_units() * PX_PER_UNIT
	# At the car's height (Weapons, Decisions, "The flamethrower at height",
	# task T-206): lifted as the car sprite is, so on a rooftop or in the air
	# the flame comes out of the exhaust where the car is drawn.
	flame_drawing.position = ISO_TRANSFORM * exhaust_px + Vector2(0.0, -car_height() * PX_PER_UNIT)
	flame_drawing.rotation = ISO_TRANSFORM.basis_xform(back).angle()
	var s := drawn_scale()
	flame_drawing.scale = Vector2(s, s)
	flame_drawing.emitting = active and is_owned()
