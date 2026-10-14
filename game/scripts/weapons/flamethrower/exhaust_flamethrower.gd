class_name ExhaustFlamethrower
extends Node
## The exhaust flamethrower (task T-042; Weapons, Decisions): flames out of the
## car's exhaust, only while the car is drifting, burning every enemy inside
## them. It copies the Unity prototype's Flame Exhaust (Unity weapons report,
## section 3) with the board's fixes (Weapons, Decisions): damage is never
## rounded, and the flame's area is the same size whichever way the car faces.
## Every number comes from res://data/weapons.json through WeaponData.flame_at().
##
## Self-contained: it is one node under the run, named NODE_NAME, plus its
## placeholder drawing in the run's View. It does not depend on any other
## weapon's code.
##
## Attaching (game/README.md, "The exhaust flamethrower"):
##   ExhaustFlamethrower.attach_to_run(run)   # gives the car the flamethrower (tier 1)
##   ExhaustFlamethrower.find_on(run)          # the run's flamethrower, or null
##   flame.upgrade() / flame.set_tier(t)       # applies the upgrade tiers 2 to 8
##   ExhaustFlamethrower.detach_from(run)      # takes it away
## A new run (run.world_rebuilt) detaches it: every run starts without it.
## run.gd calls give_if_playtest_switch(run) once per run, which attaches it
## when data/playtest.json's "flamethrower_at_start" is true (for playtests
## until the level-up offer, T-043, exists).
##
## Each car physics step (the car's `stepped` signal, so it stops while the
## game is paused):
## - On: the car's drift state (CarModel.is_drifting: W, or S, held with A or
##   D) at `min_speed` or faster; then for `linger` seconds more; or always,
##   from tier 8.
## - Area: a rectangle behind the car in the flat world, lined up with the car,
##   from `inner_edge` behind its centre, `area_depth` deep and `area_width`
##   wide at full size. Each drift starts it at `ramp_start_fraction` of full
##   size, growing to full size over `ramp_seconds` of drifting (tier 8: always
##   full size). An enemy is inside when its centre is.
## - Damage: an enemy entering takes one hit at once and flashes orange for
##   `burn_flash_seconds`; every `tick_interval` while the flame is on, every
##   enemy inside takes one hit. One hit = take_damage(`damage`). No push.
## - Targets: every node in the group "enemies" that has take_damage() (the
##   minions now, the kaiju when it joins the group), not run.minions alone.

const NODE_NAME := "ExhaustFlamethrower"
## Flat world pixels per unit (Car.PX_PER_UNIT).
const PX_PER_UNIT := 16.0
## The group every enemy is in (game/README.md, "Minions").
const ENEMY_GROUP := "enemies"
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
## The playtest switch file (res://data/playtest.json).
const PLAYTEST_FILE := "playtest"
const PLAYTEST_KEY := "flamethrower_at_start"

## Tests set this to 0 (off) or 1 (on) to override data/playtest.json; -1 reads the file.
static var playtest_override := -1

## Every hit, with the damage dealt.
signal enemy_hit(enemy: Node, amount: float)

var data := WeaponData.new()
## 1 = just got it, up to data.max_tier() (8).
var tier := 1
## WeaponData.flame_at(tier).
var stats: Dictionary = {}
## The burn flash's tint (weapons.json, flamethrower.burn_flash_tint).
var burn_tint := Color(1, 0.62, 0.38, 1)
## The car it is on (a node with `model`, a CarModel, and the `stepped` signal).
var car: Node2D = null
## The run it is attached to, or null when bound to a car only (tests).
var run: Node = null
## The placeholder drawing (CPUParticles2D in the run's View), or null.
var flame_drawing: CPUParticles2D = null

## Whether the flame is on this step.
var active := false
## Seconds the flame stays on after the drift ends.
var linger_left := 0.0
## Seconds of drifting since the flame came on (for the size ramp).
var drift_time := 0.0
## The shared damage tick timer.
var tick_timer := 0.0
## Hits dealt so far (all enemies).
var hits := 0
## Enemies inside the flame on the last step: instance id -> node.
var inside: Dictionary = {}
## Enemies flashing: instance id -> {"node": Node, "left": float}.
var burning: Dictionary = {}

## The turn speed multiplier already applied to the car (tier 7).
var _applied_turn := 1.0


func _init() -> void:
	name = NODE_NAME
	var tint = GameData.get_value(GameData.unwrap(GameData.load_file("weapons")), "flamethrower.burn_flash_tint")
	if tint.ok and tint.data is Array and tint.data.size() >= 3:
		var a: Array = tint.data
		burn_tint = Color(float(a[0]), float(a[1]), float(a[2]), float(a[3]) if a.size() > 3 else 1.0)
	stats = data.flame_at(tier)


# --- Attaching -----------------------------------------------------------

## Gives the run's car the flamethrower at tier 1 (or returns the one it has).
static func attach_to_run(the_run: Node) -> ExhaustFlamethrower:
	var existing := find_on(the_run)
	if existing != null:
		return existing
	var f := ExhaustFlamethrower.new()
	the_run.add_child(f)
	f.bind_run(the_run)
	return f


## The run's flamethrower, or null.
static func find_on(the_run: Node) -> ExhaustFlamethrower:
	if the_run == null:
		return null
	return the_run.get_node_or_null(NODE_NAME) as ExhaustFlamethrower


## Takes the flamethrower off the run, if it has one.
static func detach_from(the_run: Node) -> void:
	var f := find_on(the_run)
	if f != null:
		f.detach()


## The playtest switch: data/playtest.json "flamethrower_at_start" (or playtest_override).
static func playtest_switch_on() -> bool:
	if playtest_override >= 0:
		return playtest_override == 1
	var r := GameData.load_file(PLAYTEST_FILE)
	if not r.ok:
		return false
	var v := GameData.get_value(r.data, PLAYTEST_KEY)
	return v.ok and bool(v.data)


## run.gd calls this at the start of every run: attaches the flamethrower when
## the playtest switch is on. Off, the run starts without it (the game's rule).
static func give_if_playtest_switch(the_run: Node) -> void:
	if playtest_switch_on():
		attach_to_run(the_run)


## Binds to a run: its car, its View for the drawing, and its new runs.
func bind_run(the_run: Node) -> void:
	run = the_run
	if run.has_signal("world_rebuilt") and not run.world_rebuilt.is_connected(_on_world_rebuilt):
		run.world_rebuilt.connect(_on_world_rebuilt)
	var view = run.get("view_root")
	if view != null:
		flame_drawing = FlameScene.instantiate()
		flame_drawing.name = "ExhaustFlame"
		view.add_child(flame_drawing)
		var sprite = run.get("car_sprite")
		if sprite != null and sprite.get_parent() == view:
			view.move_child(flame_drawing, sprite.get_index())  # just under the car
	bind_car(run.car)


## Binds to a car: steps after each of its physics steps.
func bind_car(the_car: Node2D) -> void:
	if car != null and is_instance_valid(car) and car.stepped.is_connected(_on_car_stepped):
		car.stepped.disconnect(_on_car_stepped)
	car = the_car
	_applied_turn = 1.0
	_reset_flame()
	if car != null:
		car.stepped.connect(_on_car_stepped)
		_apply_turn_speed()
		_update_drawing()


## Takes the flamethrower off: stops it, clears flashes, removes the drawing.
func detach() -> void:
	if car != null and is_instance_valid(car) and car.stepped.is_connected(_on_car_stepped):
		car.stepped.disconnect(_on_car_stepped)
	if run != null and is_instance_valid(run) and run.has_signal("world_rebuilt") \
			and run.world_rebuilt.is_connected(_on_world_rebuilt):
		run.world_rebuilt.disconnect(_on_world_rebuilt)
	_clear_burns()
	if flame_drawing != null and is_instance_valid(flame_drawing):
		flame_drawing.get_parent().remove_child(flame_drawing)
		flame_drawing.queue_free()
	flame_drawing = null
	if get_parent() != null:
		get_parent().remove_child(self)
	queue_free()


## A new run: every run starts without the flamethrower.
func _on_world_rebuilt() -> void:
	detach()


# --- Tiers ---------------------------------------------------------------

## Sets the tier (1 to max_tier) and its values from the data. Tier 7's
## steering is applied to the car's turn speed (and undone when going back).
func set_tier(new_tier: int) -> void:
	tier = clampi(new_tier, 1, data.max_tier())
	stats = data.flame_at(tier)
	_apply_turn_speed()


## The next upgrade tier; false at the last tier.
func upgrade() -> bool:
	if tier >= data.max_tier():
		return false
	set_tier(tier + 1)
	return true


func is_max_tier() -> bool:
	return tier >= data.max_tier()


func _apply_turn_speed() -> void:
	if car == null or not is_instance_valid(car):
		return
	var want: float = stats["turn_speed_multiplier"]
	if not is_equal_approx(want, _applied_turn):
		car.model.tuning.turn_speed *= want / _applied_turn
		_applied_turn = want


# --- Each step -----------------------------------------------------------

func _on_car_stepped() -> void:
	step(car.model.dt)


## One physics step of `dt` seconds, after the car has moved.
func step(dt: float) -> void:
	if car == null or not is_instance_valid(car):
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
			if _alive(e):
				_hit(e)
	inside = now_inside
	_update_drawing()


func _reset_flame() -> void:
	drift_time = 0.0
	tick_timer = 0.0
	inside.clear()


## Every live enemy that can be damaged: the group "enemies" (minions now, the kaiju too).
func targets() -> Array:
	var out: Array = []
	if not is_inside_tree():
		return out
	for e in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if _alive(e):
			out.append(e)
	return out


func _alive(e) -> bool:
	if e == null or not is_instance_valid(e) or not e.has_method("take_damage"):
		return false
	if e.has_method("is_dead") and e.is_dead():
		return false
	return true


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


## The car's centre in units (flat world).
func car_units() -> Vector2:
	return Vector2(car.model.x, car.model.y)


## Whether a point (flat world, units) is inside the damage area now.
func contains_point(p: Vector2) -> bool:
	var a := area()
	var rot: float = car.model.rotation
	var forward := Vector2(cos(rot), sin(rot))
	var right := Vector2(-sin(rot), cos(rot))
	var d := p - car_units()
	var back := -d.dot(forward)
	return back >= a["inner"] and back <= a["inner"] + a["depth"] and absf(d.dot(right)) <= a["half_width"]


## Whether an enemy's centre is inside the damage area now.
func is_inside(e: Node) -> bool:
	return contains_point(enemy_units(e))


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
	if not _alive(e):
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

## Puts the drawn flame on the car's exhaust, pointing back, sized like the
## damage area's size multiplier, emitting while the flame is on.
func _update_drawing() -> void:
	if flame_drawing == null or not is_instance_valid(flame_drawing) or car == null:
		return
	var rot: float = car.model.rotation
	var back := -Vector2(cos(rot), sin(rot))
	var exhaust_px := (car_units() + back * EXHAUST_OFFSET_UNITS) * PX_PER_UNIT
	flame_drawing.position = ISO_TRANSFORM * exhaust_px
	flame_drawing.rotation = ISO_TRANSFORM.basis_xform(back).angle()
	var s: float = float(stats["size_multiplier"]) * size_fraction()
	flame_drawing.scale = Vector2(s, s)
	flame_drawing.emitting = active
