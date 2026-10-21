extends Node
## The run's minions (task T-044; Enemies, Decisions): spawning them at the
## edges of the screen in numbers that grow slightly over the run, walking
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
## How many: EnemyData.minions_wanted(run seconds, spawn_multiplier). While
## fewer are around, one spawns every spawn_interval_seconds, at a random
## point spawn_margin_units beyond the edge of the visible screen, on the map
## and clear of buildings and boulders. `spawn_multiplier` is the hook for the
## combo's extra spawning (T-085): minions_wanted_now() sets it from
## RunState.combo_spawn_multiplier() each time, or to 1.0 when
## `combo_raises_spawning` is false (the board's playtest switch).
##
## Minions that fall a whole screen behind the visible screen (the car has
## driven away from them) are removed without dropping coins, and the spawner
## refills at the screen's edge, so the minions stay around the car.
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
## `heights_enabled` false (tests, the soak's comparison) makes them ignore
## the heights, as before T-207.

const MinionScript := preload("res://scripts/enemies/minion.gd")
const MinionSpriteScript := preload("res://scripts/enemies/minion_sprite.gd")
const CoinScript := preload("res://scripts/enemies/coin.gd")
const CoinSpriteScript := preload("res://scripts/enemies/coin_sprite.gd")
const EnemyDepthScript := preload("res://scripts/enemies/enemy_depth.gd")
const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")
const EnemyNavigationScript := preload("res://scripts/enemies/enemy_navigation.gd")
const FollowerScript := preload("res://scripts/enemies/enemy_path_follower.gd")

const PX_PER_UNIT := 16.0
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## Spawn point tries per spawn before giving up until the next interval.
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
## The combo's extra spawning: multiplies minions_wanted. Set by
## minions_wanted_now() (T-085); 1.0 with no combo or with the switch off.
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
## Microseconds the last step() took (T-207: the soak's frame time).
var last_step_usec := 0
## The map's ground heights (GroundHeight) and the enemies' navigation
## (enemy_navigation.gd); both null on a map without heights.
var ground = null
var navigation: RefCounted = null

var minions: Array = []
var coins: Array = []
var depth = EnemyDepthScript.new()

var _stats: Dictionary
var _spawning: Dictionary
var _coins: Dictionary
## Seconds since the last spawn (starts full, so the first one is at once).
var _spawn_clock := 0.0
var _run: Node = null


func _init() -> void:
	data = EnemyData.new()
	_stats = data.minion()
	_spawning = data.spawning()
	_coins = data.coins()
	_spawn_clock = _spawning.get("spawn_interval_seconds", 0.5)
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
	minions.clear()
	coins.clear()
	_spawn_clock = _spawning.get("spawn_interval_seconds", 0.5)


func _physics_process(delta: float) -> void:
	step(delta)


## How many minions are wanted now: EnemyData.minions_wanted() at the run's
## time, times the combo's spawn multiplier (1.0 when the switch is off).
func minions_wanted_now() -> int:
	spawn_multiplier = state.combo_spawn_multiplier() if combo_raises_spawning and state != null else 1.0
	var t: float = state.time_elapsed() if state != null else 0.0
	return data.minions_wanted(t, spawn_multiplier)


## One physics step of `dt` seconds: spawn, walk, contact damage, remove the
## ones left far behind, place the drawings. Nothing happens once the run is over.
func step(dt: float) -> void:
	if not enabled or car == null or not is_instance_valid(car):
		return
	if state != null and not state.is_running():
		return
	var t0 := Time.get_ticks_usec()
	_prune()
	_spawn_step(dt)
	move_step(dt)
	_despawn_far()
	update_drawing()
	last_step_usec = Time.get_ticks_usec() - t0


## One physics step of the minions already there: each walks (straight at the
## car, or by its follower's path on a map with heights) and deals its contact
## damage. No spawning, no removing (step() does those).
func move_step(dt: float) -> void:
	if car == null or not is_instance_valid(car):
		return
	var car_units: Vector2 = car.position / PX_PER_UNIT
	if navigation != null:
		navigation.new_step()
	var pushes := _separation()
	var i := 0
	for m in minions.duplicate():
		var target := car_units
		if navigation != null and m.follower != null:
			target = m.follower.target(navigation, m.position_units(), car_units, dt)
		m.walk(dt, target, pushes[i])
		i += 1
		m.contact_step(dt, car, state)
		if state != null and not state.is_running():
			break


func _prune() -> void:
	minions = minions.filter(func(m) -> bool: return is_instance_valid(m) and not m.is_dead())
	coins = coins.filter(func(c) -> bool: return is_instance_valid(c) and not c.is_taken())


func _spawn_step(dt: float) -> void:
	var interval: float = _spawning["spawn_interval_seconds"]
	_spawn_clock = minf(_spawn_clock + dt, interval)
	if minions.size() >= minions_wanted_now():
		return
	if _spawn_clock < interval - 0.000001:
		return
	var p = pick_spawn_point()
	if p == null:
		return
	_spawn_clock = 0.0
	spawn_minion_at(p)


## Separation pushes, one per minion in `minions` order. On a map with
## heights only minions at the same level push apart (T-207).
func _separation() -> Array:
	var out := []
	var sep: float = MinionScript.SEPARATION_UNITS
	var pos := []
	var hs := []
	for m in minions:
		pos.append(m.position_units())
		hs.append(m.ground_height() if ground != null else 0.0)
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
	bodies_root.add_child(m, true)
	var s: Node2D = MinionSpriteScript.new()
	s.name = "MinionSprite"
	draw_root.add_child(s, true)
	m.sprite = s
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
	s.position = ISO_TRANSFORM * c.position + Vector2(0.0, -h * PX_PER_UNIT)
	s.z_index = depth.z_index_for(units, CoinScript.RADIUS_UNITS, 0.6, h)
	s.reset_physics_interpolation()
	coins.append(c)
	return c


## Rolls the data's drop chance; returns how many coins drop (0 or coins_per_drop).
func roll_coin_drop() -> int:
	if rng.randf() < float(_coins["drop_chance"]):
		return int(_coins["coins_per_drop"])
	return 0


func _on_minion_died(m: Node, at_units: Vector2) -> void:
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
	minion_killed.emit(m, n)


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
	var rad: float = MinionScript.RADIUS_UNITS
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
	return true


## Removes minions a whole screen beyond the visible screen (no coins).
## A minion on its way to the car by the ramps (T-207: its follower has a
## path) is removed only when it is more than ON_PATH_KEEP_UNITS from the car,
## so it is not removed while it walks round to a ramp far from the car (a
## proposal).
func _despawn_far() -> void:
	var v := visible_rect()
	var keep := v.grow_individual(v.size.x, v.size.y, v.size.x, v.size.y)
	var car_units: Vector2 = car.position / PX_PER_UNIT
	for m in minions.duplicate():
		if keep.has_point(ISO_TRANSFORM * m.position):
			continue
		if m.follower != null and m.follower.has_path() 				and m.position_units().distance_to(car_units) <= ON_PATH_KEEP_UNITS:
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
	var h: float = m.ground_height()
	s.position = ISO_TRANSFORM * m.position + Vector2(0.0, -h * PX_PER_UNIT)
	s.face(m.heading)
	s.z_index = depth.z_index_for(m.position_units(), MinionScript.RADIUS_UNITS, MinionScript.HEIGHT_UNITS, h)
