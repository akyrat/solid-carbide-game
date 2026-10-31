extends Node
## The run's minions (task T-044; Enemies, Decisions): spawning them at the
## edges of the screen on a timer that speeds up over the run (T-443), walking
## them towards the car, their contact damage and knockback, and the coins
## they drop when they die. Numbers: res://data/enemies.json through
## EnemyData; nothing here changes them.
##
## The run scene (run.gd) adds it as its child "Minions" and binds it with
## bind(run). Everything moves in step(), called once per physics step from
## _physics_process, so pausing the tree stops the minions (and their contact
## damage), and they stand still once the run is over. A new run
## (run.world_rebuilt) clears every minion and coin.
##
## How often (T-443; Enemies, Decisions, "Minions spawn on a timer"): one
## minion every spawn_interval() seconds, however many are already around
## (EnemyData.spawn_interval(run seconds, spawn_multiplier): faster as the run
## goes on), at a random point spawn_margin_units beyond the edge of the visible
## screen, on the map and clear of buildings and boulders. Only the data's
## max_minions_alive (a safety ceiling for the frame rate) holds the timer.
## `spawn_multiplier` is the hook for the combo's extra spawning (T-085):
## spawn_interval() sets it from RunState.combo_spawn_multiplier() each time,
## or to 1.0 when `combo_raises_spawning` is false (the board's playtest switch).
##
## Minions that fall a whole screen behind the visible screen (the car has
## driven away from them) are removed without dropping coins; the timer keeps
## bringing new ones in at the screen's edge, so the minions stay around the car.
##
## Drawing: each minion's body is in the flat physics world (PhysicsWorld,
## hidden); its sprite is in `draw_root`, a node of the run drawn over the map
## and before the car's View. Every step each sprite is put at its body's
## place in the isometric view and given its place in the buildings' depth
## order (enemy_depth.gd, the map's rule for the car). At the same depth the
## car is drawn over a minion.
##
## Heights (task T-207; Enemies, Decisions, "Enemies follow the car up the
## ramps"): on a map with rooftops and ramps (map.elevation) each minion gets
## the map's ground (minion.ground: it stands on it, edges stop it, its
## contact damage only hits the car at its level) and a follower
## (enemy_path_follower.gd) that walks it straight at the car on the car's
## surface and otherwise along a path by the ramps (enemy_navigation.gd, one
## per map, shared with the kaiju). Minions spawn on the street only; they
## push apart only from minions at their level; their sprites and coins are
## drawn lifted by the ground's height, in the depth order at that height.
## T-226: a minion whose path drops off a rooftop's edge may walk out over it
## (minion.may_drop, from its follower) and falls; while it falls it is drawn
## at its height in the air, with the falling animation (minion_sprite.gd).
## `heights_enabled` false (tests, the soak's comparison) makes them ignore
## the heights, as before T-207.

const MinionScript := preload("res://scripts/enemies/minion.gd")
const MinionSpriteScript := preload("res://scripts/enemies/minion_sprite.gd")
const CoinScript := preload("res://scripts/enemies/coin.gd")
const CoinSpriteScript := preload("res://scripts/enemies/coin_sprite.gd")
const HealthPickupScript := preload("res://scripts/enemies/health_pickup.gd")
const HealthPickupSpriteScript := preload("res://scripts/enemies/health_pickup_sprite.gd")
const EnemyDepthScript := preload("res://scripts/enemies/enemy_depth.gd")
const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")
const EnemyNavigationScript := preload("res://scripts/enemies/enemy_navigation.gd")
const FollowerScript := preload("res://scripts/enemies/enemy_path_follower.gd")

const PX_PER_UNIT := 16.0
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## Seconds between spawns when the data's spawn intervals are missing or not above 0 (T-418, T-443).
const DEFAULT_SPAWN_INTERVAL := 0.5
## A pickup's circle radius, and the gap left between it and a boulder it was pushed out of (T-418).
const PICKUP_RADIUS_UNITS := 0.5
const PICKUP_CLEARANCE_UNITS := 0.1
## Spawn point tries per step; when none is free the spawn waits for the next step.
const SPAWN_TRIES := 12
## Coins from one drop are spread round the death point this far (units).
const COIN_SPREAD_UNITS := 0.6
## How strongly minions push apart (see Minion.SEPARATION_UNITS).
const SEPARATION_WEIGHT := 0.8
## T-207: how far from the car (units) a minion on its way to a ramp may be
## before it is removed (others: a screen beyond the visible one). Half the
## map: the farthest a rooftop is from its ramp's foot is about 80. A proposal.
const ON_PATH_KEEP_UNITS := 120.0

## A minion spawned.
signal minion_spawned(minion: Node)
## A minion died (weapons killed it); `coins` is how many coins it dropped.
signal minion_killed(minion: Node, coins: int)

## False stops spawning and moving (the run scene's switch, for tests).
var enabled := true
## The combo's extra spawning: multiplies the spawn rate (divides the interval). Set by
## spawn_interval() (T-085, T-443); 1.0 with no combo or with the switch off.
var spawn_multiplier := 1.0
## The on/off switch for the combo's extra spawning (T-085; Enemies, Decisions).
## On by default. Set false in code (here, or run.minions.combo_raises_spawning
## from a test or a playtest scene) to judge the game without it.
var combo_raises_spawning := true
## Random numbers for spawn points and coin drops. Seed it for tests.
var rng := RandomNumberGenerator.new()
var data: EnemyData

## Bound by bind(): the run's state, car, map and camera.
var state: Node = null
var car: Node2D = null
var map: Node2D = null
var camera: Camera2D = null
## The flat physics world's node for the minions' and coins' bodies.
var bodies_root: Node2D = null
## The drawing's node for their sprites (isometric screen pixels).
var draw_root: Node2D = null
## The visible screen in the view's pixels; empty = use the camera.
var visible_rect_override := Rect2()
## T-207: false makes the minions ignore the map's heights (as before T-207).
## Read when a run's world is built (set it, then start a new run).
var heights_enabled := true
## T-226: how many times minions have dropped off an edge (the soak's count).
var drops_total := 0
## Microseconds the last step() took (T-207: the soak's frame time).
var last_step_usec := 0
## The map's ground heights (GroundHeight) and the enemies' navigation
## (enemy_navigation.gd); both null on a map without heights.
var ground = null
var navigation: RefCounted = null

var minions: Array = []
var coins: Array = []
## The health pickups on the ground (T-220), found the way the coins are
## (also the group "health_pickups").
var health_pickups: Array = []
var depth = EnemyDepthScript.new()

var _stats: Dictionary
var _spawning: Dictionary
var _coins: Dictionary
var _health_drops: Dictionary
## Seconds since the last spawn (starts full, so the first one is at once).
var _spawn_clock := 0.0
## How many minions the timer has spawned since the last clear() (T-443; tests and the soak).
var spawned_total := 0
var _run: Node = null


func _init() -> void:
	data = EnemyData.new()
	_stats = data.minion()
	_spawning = data.spawning()
	_coins = data.coins()
	_health_drops = data.health_drops()
	_spawn_clock = INF
	rng.randomize()


## Binds the spawner to a run scene (run.gd): its state, car, map, camera,
## PhysicsWorld, and a new draw root just before its View node. Follows
## world_rebuilt (a new run) to clear everything and pick up the new car and map.
func bind(run: Node) -> void:
	_run = run
	state = run.state
	camera = run.camera
	bodies_root = Node2D.new()
	bodies_root.name = "MinionBodies"
	run.physics_world.add_child(bodies_root)
	draw_root = Node2D.new()
	draw_root.name = "Enemies"
	draw_root.y_sort_enabled = true
	run.add_child(draw_root)
	run.move_child(draw_root, run.view_root.get_index())
	run.world_rebuilt.connect(_on_world_rebuilt)
	if run.car != null:
		_on_world_rebuilt()


func _on_world_rebuilt() -> void:
	car = _run.car
	map = _run.map
	depth.set_map(map)
	ground = null
	navigation = null
	var elevation = map.get("elevation") if map != null else null
	if heights_enabled and elevation != null:
		ground = elevation.ground_height
		navigation = EnemyNavigationScript.for_map(map)
	clear()


## Removes every minion and coin, and restarts the spawn clock.
func clear() -> void:
	for m in minions:
		if is_instance_valid(m):
			m.queue_free()
	for c in coins:
		if is_instance_valid(c):
			c.queue_free()
	for h in health_pickups:
		if is_instance_valid(h):
			h.queue_free()
	minions.clear()
	coins.clear()
	health_pickups.clear()
	_spawn_clock = INF
	spawned_total = 0


## Seconds between spawns now (T-443): EnemyData.spawn_interval() at the run's time, with the
## combo's spawn multiplier (1.0 when the switch is off), which it also stores in spawn_multiplier.
## Intervals missing or not above 0 in the data are reported and replaced by DEFAULT_SPAWN_INTERVAL (T-418).
func spawn_interval() -> float:
	spawn_multiplier = state.combo_spawn_multiplier() if combo_raises_spawning and state != null else 1.0
	var t: float = state.time_elapsed() if state != null else 0.0
	var v: float = EnemyData.interval_from(_spawning, t, spawn_multiplier)
	if v <= 0.0:
		push_error("enemies.json spawning.spawn_interval_at_start_seconds and spawn_interval_at_boss_time_seconds must be above 0 (got %s, %s): using %s" % [
			_spawning.get("spawn_interval_at_start_seconds"), _spawning.get("spawn_interval_at_boss_time_seconds"), DEFAULT_SPAWN_INTERVAL])
		return DEFAULT_SPAWN_INTERVAL
	return v


## A meteor lands (T-418; Enemies, Decisions): every minion at the level of the ground at `units`
## whose body reaches within `radius` units of it takes `amount` damage. Returns how many were hit.
func damage_minions_at(units: Vector2, radius: float, amount: float) -> int:
	var level := EnemyHeightScript.height_at(ground, units)
	var n := 0
	for m in minions.duplicate():
		if not is_instance_valid(m) or m.is_dead():
			continue
		if m.position_units().distance_to(units) > radius + m.radius_units():
			continue
		if not EnemyHeightScript.at_car_level(m.body_height(), level):
			continue
		m.take_damage(amount, "meteor")
		n += 1
	return n


## A boulder appears at `centre` (T-418): every coin and health pickup within `radius` units of it
## (the boulder's radius) is moved just outside it, along the way out from the centre, to the
## nearest of 16 directions' spots that is free ground. Its sprite and height follow. Returns how many moved.
func push_pickups_out(centre: Vector2, radius: float) -> int:
	var n := 0
	for p in coins + health_pickups:
		if not is_instance_valid(p) or p.is_taken():
			continue
		var at: Vector2 = p.position_units()
		if at.distance_to(centre) >= radius + PICKUP_RADIUS_UNITS:
			continue
		var out := (at - centre)
		var base := out.angle() if out.length() > 0.001 else 0.0
		var dist := radius + PICKUP_RADIUS_UNITS + PICKUP_CLEARANCE_UNITS
		var best = null
		for i in 16:
			var a := base + (TAU * i / 16.0 if i % 2 == 0 else -TAU * (i + 1) / 16.0)
			var cand := centre + Vector2.RIGHT.rotated(a) * dist
			if _pickup_spot_free(cand):
				best = cand
				break
		if best == null:
			best = centre + Vector2.RIGHT.rotated(base) * dist
		_move_pickup(p, best)
		n += 1
	return n


func _pickup_spot_free(units: Vector2) -> bool:
	if map == null:
		return true
	if not map.rect_of(map.layout.map.rect).grow(-PICKUP_RADIUS_UNITS).has_point(units):
		return false
	for b in map.layout.buildings:
		if map.rect_of(b).grow(PICKUP_RADIUS_UNITS).has_point(units):
			return false
	for b in map.all_boulders():
		if Vector2(float(b.x), float(b.y)).distance_to(units) < float(b.diameter) / 2.0 + PICKUP_RADIUS_UNITS:
			return false
	return true


func _move_pickup(p: Node, units: Vector2) -> void:
	p.position = units * PX_PER_UNIT
	var h := EnemyHeightScript.height_at(ground, units)
	p.ground_height = h
	var s: Node2D = p.sprite
	if s != null and is_instance_valid(s):
		s.position = ISO_TRANSFORM * p.position + Vector2(0.0, -h * PX_PER_UNIT)
		s.z_index = depth.z_index_for(units, p.RADIUS_UNITS, 0.6, h)
		s.reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	Perf.begin(&"minions.step")
	step(delta)
	Perf.end(&"minions.step")


## The safety ceiling on minions alive at once (T-443): the data's max_minions_alive, 0 for none.
func max_minions_alive() -> int:
	return int(_spawning.get("max_minions_alive", 0.0))


## One physics step of `dt` seconds: spawn, walk, contact damage, remove the
## ones left far behind, place the drawings. Nothing happens once the run is over,
## except during the wreck (T-360, the board's quick tuning, 2026-10-29): the
## minions keep coming and swarm the wrecked car, with no contact (no damage, no
## knockback).
func step(dt: float) -> void:
	if not enabled or car == null or not is_instance_valid(car):
		return
	var swarming: bool = _wreck_swarm()
	if state != null and not state.is_running() and not swarming:
		return
	var t0 := Time.get_ticks_usec()
	Perf.begin(&"minions.prune")
	_prune()
	Perf.end(&"minions.prune")
	Perf.begin(&"minions.spawn")
	_spawn_step(dt)
	Perf.end(&"minions.spawn")
	Perf.begin(&"minions.move")
	move_step(dt, not swarming)
	Perf.end(&"minions.move")
	Perf.begin(&"minions.despawn")
	_despawn_far()
	Perf.end(&"minions.despawn")
	Perf.begin(&"minions.place_and_depth")
	update_drawing()
	Perf.end(&"minions.place_and_depth")
	last_step_usec = Time.get_ticks_usec() - t0


## One physics step of the minions already there: each walks (straight at the
## car, or by its follower's path on a map with heights) and deals its contact
## damage (only walking when `contacts` is false: the wreck, T-360). No
## spawning, no removing (step() does those).
func move_step(dt: float, contacts := true) -> void:
	if car == null or not is_instance_valid(car):
		return
	var car_units: Vector2 = car.position / PX_PER_UNIT
	if navigation != null:
		navigation.new_step()
	Perf.begin(&"minions.separation")
	var pushes := _separation()
	Perf.end(&"minions.separation")
	var i := 0
	for m in minions.duplicate():
		var target := car_units
		if Perf.on: Perf.each_begin(&"minions.path")
		if navigation != null and m.follower != null:
			target = m.follower.target(navigation, m.position_units(), car_units, dt)
			m.may_drop = m.follower.dropping(navigation, m.position_units(), m.body_height())
		if Perf.on: Perf.each_end(&"minions.path")
		var was_falling: bool = m.is_falling()
		if Perf.on: Perf.each_begin(&"minions.walk")
		m.walk(dt, target, pushes[i])
		if Perf.on: Perf.each_end(&"minions.walk")
		if not was_falling and m.is_falling():
			drops_total += 1
		i += 1
		if not contacts:
			continue
		m.contact_step(dt, car, state)
		if state != null and not state.is_running():
			break


## True during the wreck (T-360): the last heart is gone and the run has not ended yet.
func _wreck_swarm() -> bool:
	return state != null and state.has_method("is_wrecked") and state.is_wrecked()


func _prune() -> void:
	minions = minions.filter(func(m) -> bool: return is_instance_valid(m) and not m.is_dead())
	coins = coins.filter(func(c) -> bool: return is_instance_valid(c) and not c.is_taken())
	health_pickups = health_pickups.filter(func(h) -> bool: return is_instance_valid(h) and not h.is_taken())


func _spawn_step(dt: float) -> void:
	# T-443: a timer, however many are around; only the safety ceiling holds it.
	var interval: float = spawn_interval()
	_spawn_clock = minf(_spawn_clock + dt, interval)
	if _spawn_clock < interval - 0.000001:
		return
	var ceiling := max_minions_alive()
	if ceiling > 0 and minions.size() >= ceiling:
		return
	var p = pick_spawn_point()
	if p == null:
		return  # no free spot this step: try again next step
	_spawn_clock = 0.0
	spawned_total += 1
	spawn_minion_at(p)


## Separation pushes, one per minion in `minions` order. On a map with
## heights only minions at the same level push apart (T-207).
func _separation() -> Array:
	var out := []
	var sep: float = MinionScript.SEPARATION_UNITS * float(_stats.get("size_scale", 1.0))
	var pos := []
	var hs := []
	for m in minions:
		pos.append(m.position_units())
		hs.append(m.body_height() if ground != null else 0.0)
	for a in minions.size():
		var push := Vector2.ZERO
		for b in minions.size():
			if a == b:
				continue
			if absf(hs[a] - hs[b]) > EnemyHeightScript.LEVEL_TOLERANCE:
				continue
			var d: Vector2 = pos[a] - pos[b]
			var l := d.length()
			if l < sep and l > 0.0001:
				push += d / l * (1.0 - l / sep)
		out.append(push * SEPARATION_WEIGHT)
	return out


## Adds a minion with the data's stats at `units` (flat world), with its sprite.
func spawn_minion_at(units: Vector2) -> Node:
	var m: CharacterBody2D = MinionScript.new()
	m.name = "Minion"
	m.setup(_stats)
	m.set_position_units(units)
	m.detour_side = 1.0 if rng.randf() < 0.5 else -1.0
	m.ground = ground
	m.follower = FollowerScript.new(rng.randf() * FollowerScript.REPATH_SECONDS)
	m.follower.by_sight = true  # T-380: straight only while the way to the car is clear
	bodies_root.add_child(m, true)
	var s: Node2D = MinionSpriteScript.new()
	s.name = "MinionSprite"
	draw_root.add_child(s, true)
	m.sprite = s
	s.size_scale = m.size_scale
	m.died.connect(_on_minion_died)
	minions.append(m)
	_place_sprite(m)
	s.reset_physics_interpolation()
	minion_spawned.emit(m)
	return m


## Adds a coin worth `value` at `units`, with its sprite.
func spawn_coin_at(units: Vector2, value: int = 1) -> Node:
	var c: Area2D = CoinScript.new()
	c.name = "Coin"
	c.value = value
	c.state = state
	c.position = units * PX_PER_UNIT
	bodies_root.add_child(c, true)
	var s: Node2D = CoinSpriteScript.new()
	s.name = "CoinSprite"
	draw_root.add_child(s, true)
	c.sprite = s
	var h := EnemyHeightScript.height_at(ground, units)
	c.ground_height = h  # T-402: picked up only from this height
	s.position = ISO_TRANSFORM * c.position + Vector2(0.0, -h * PX_PER_UNIT)
	s.z_index = depth.z_index_for(units, CoinScript.RADIUS_UNITS, 0.6, h)
	s.reset_physics_interpolation()
	coins.append(c)
	return c


## Adds a health pickup at `units`, with its sprite. It restores `hearts` hearts
## (the data's restore_hearts unless given).
func spawn_health_pickup_at(units: Vector2, hearts: float = -1.0) -> Node:
	var p: Area2D = HealthPickupScript.new()
	p.name = "HealthPickup"
	p.restore_hearts = float(_health_drops["restore_hearts"]) if hearts < 0.0 else hearts
	p.state = state
	p.position = units * PX_PER_UNIT
	bodies_root.add_child(p, true)
	var s: Node2D = HealthPickupSpriteScript.new()
	s.name = "HealthPickupSprite"
	draw_root.add_child(s, true)
	p.sprite = s
	var h := EnemyHeightScript.height_at(ground, units)
	p.ground_height = h  # T-402: picked up only from this height
	s.position = ISO_TRANSFORM * p.position + Vector2(0.0, -h * PX_PER_UNIT)
	s.z_index = depth.z_index_for(units, HealthPickupScript.RADIUS_UNITS, 0.6, h)
	s.reset_physics_interpolation()
	health_pickups.append(p)
	return p


## Rolls the health drop's own chance (separate from the coins' roll).
func roll_health_drop() -> bool:
	return rng.randf() < float(_health_drops["drop_chance"])


## Rolls the data's drop chance; returns how many coins drop (0 or coins_per_drop).
func roll_coin_drop() -> int:
	if rng.randf() < float(_coins["drop_chance"]):
		return int(_coins["coins_per_drop"])
	return 0


func _on_minion_died(m: Node, at_units: Vector2) -> void:
	if Perf.on: Perf.each_begin(&"minions.death_drops")
	minions.erase(m)
	var n := roll_coin_drop()
	for k in n:
		var offset := Vector2.ZERO
		if n > 1:
			offset = Vector2.RIGHT.rotated(TAU * k / n + rng.randf() * TAU / n) * COIN_SPREAD_UNITS
			# T-207: a coin stays on the level the minion died on.
			if absf(EnemyHeightScript.height_at(ground, at_units + offset) - EnemyHeightScript.height_at(ground, at_units)) > EnemyHeightScript.MAX_STEP:
				offset = Vector2.ZERO
		spawn_coin_at(at_units + offset, 1)
	if roll_health_drop():
		spawn_health_pickup_at(at_units)
	if state != null:
		state.enemy_slain(m.ENEMY_TYPE, m.last_hit_by)
	minion_killed.emit(m, n)
	if Perf.on: Perf.each_end(&"minions.death_drops")


## The visible screen, in the view's pixels (the camera's), or the override.
func visible_rect() -> Rect2:
	if visible_rect_override.has_area():
		return visible_rect_override
	if camera == null or not camera.is_inside_tree():
		var c: Vector2 = ISO_TRANSFORM * car.position
		return Rect2(c - Vector2(400, 230), Vector2(800, 460))
	var size: Vector2 = camera.get_viewport_rect().size / camera.zoom
	var centre: Vector2 = camera.get_screen_center_position()
	return Rect2(centre - size / 2.0, size)


## A random spawn point (flat world units) on the ring spawn_margin_units
## beyond the visible screen's edge, on the map and clear of buildings and
## boulders; null when none of SPAWN_TRIES tries is free.
func pick_spawn_point():
	var r := visible_rect().grow(float(_spawning["spawn_margin_units"]) * PX_PER_UNIT)
	var inv := ISO_TRANSFORM.affine_inverse()
	var perimeter := 2.0 * (r.size.x + r.size.y)
	for _t in SPAWN_TRIES:
		var d := rng.randf() * perimeter
		var p: Vector2
		if d < r.size.x:
			p = r.position + Vector2(d, 0)
		elif d < r.size.x + r.size.y:
			p = r.position + Vector2(r.size.x, d - r.size.x)
		elif d < 2.0 * r.size.x + r.size.y:
			p = r.end - Vector2(d - r.size.x - r.size.y, 0)
		else:
			p = r.end - Vector2(r.size.x, d - 2.0 * r.size.x - r.size.y)
		var units: Vector2 = (inv * p) / PX_PER_UNIT
		if is_free_spot(units):
			return units
	return null


## True when a minion fits at `units`: inside the map, not on a building or a
## boulder, and on a map with heights on the street (T-207), clear of every
## rooftop and ramp.
func is_free_spot(units: Vector2) -> bool:
	if map == null:
		return true
	var rad: float = MinionScript.BASE_RADIUS_UNITS * float(_stats.get("size_scale", 1.0))
	var m: Rect2 = map.rect_of(map.layout.map.rect)
	if not m.grow(-rad).has_point(units):
		return false
	var elevation = map.get("elevation")
	if elevation != null and not elevation.is_street(units, rad):
		return false
	for b in map.layout.buildings:
		if map.rect_of(b).grow(rad).has_point(units):
			return false
	for b in map.all_boulders():
		var c := Vector2(float(b.x), float(b.y))
		if c.distance_to(units) < float(b.diameter) / 2.0 + rad:
			return false
	if map.prop_blocks_spot(units, rad):
		return false
	return true


## Removes minions a whole screen beyond the visible screen (no coins).
## A minion on its way to the car by the ramps (T-207: its follower has a
## path) is removed only when it is more than ON_PATH_KEEP_UNITS from the car,
## so it is not removed while it walks round to a ramp far from the car (a
## proposal). T-380: a minion walking by sight also has a path when it only goes
## round something on the car's own surface (a building, or a short building's
## platform of T-405); that one is removed as before, so the rule is "has a path
## and is on another surface than the car" (before T-380 a path meant just that).
func _despawn_far() -> void:
	var v := visible_rect()
	var keep := v.grow_individual(v.size.x, v.size.y, v.size.x, v.size.y)
	var car_units: Vector2 = car.position / PX_PER_UNIT
	var car_surface: int = navigation.surface_at(car_units) if navigation != null else -1
	for m in minions.duplicate():
		if keep.has_point(ISO_TRANSFORM * m.position):
			continue
		if m.follower != null and m.follower.has_path() 				and navigation != null and navigation.surface_at(m.position_units()) != car_surface 				and m.position_units().distance_to(car_units) <= ON_PATH_KEEP_UNITS:
			continue
		minions.erase(m)
		m.queue_free()


## Puts every sprite at its body's place in the view and in the depth order.
func update_drawing() -> void:
	for m in minions:
		_place_sprite(m)


func _place_sprite(m: Node) -> void:
	var s: Node2D = m.sprite
	if s == null:
		return
	var h: float = m.body_height()
	s.position = ISO_TRANSFORM * m.position + Vector2(0.0, -h * PX_PER_UNIT)
	s.face(m.heading)
	s.set_falling(m.is_falling())
	s.z_index = depth.z_index_for(m.position_units(), m.radius_units(), m.height_units(), h)
