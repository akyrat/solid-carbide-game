extends Node
## The run's kaiju (task T-045; Enemies, Decisions): it appears just off-screen
## when the run sends "boss time" (the boss time, RunState.boss_time), walks
## slowly towards the car, deals contact damage with knockback, can be damaged
## at any time, and its death adds its coins to the run (EnemyData.
## kaiju_coins_on_defeat(), T-119) and then calls RunState.kaiju_killed(),
## which ends the run as a win. Numbers: res://data/enemies.json's "kaiju"
## and "kaiju_coins"; nothing here changes them.
##
## The run scene (run.gd) adds it as its child "Kaiju" (`run.kaiju_boss`) and
## binds it with bind(run). Everything moves in step(), called once per
## physics step from _physics_process, so pausing the tree stops the kaiju
## and its damage, and it stands still once the run is over. A new run
## (run.world_rebuilt) removes it, and it appears again at that run's boss time.
##
## For the HUD (health) and the meteor attack (T-046): `kaiju` is the live
## kaiju (null before it appears and after it dies); the signals below relay
## its arrival, health and death.
##
## Playtest switch: res://data/playtest.json, "kaiju_early_arrival" (task
## T-045; one key of several). When it is enabled, the kaiju arrives
## `after_seconds` into the run instead of at the boss time.
## `early_arrival_seconds` holds it (-1 = off); `playtest_override` lets tests
## ignore the file.
##
## Heights (task T-207, a proposal for the playtest): on a map with rooftops
## and ramps the kaiju follows the minions' rules (minion_spawner.gd,
## enemy_height.gd): it arrives on the street, stands on the ground under it,
## rooftop edges stop it, it finds its way to the car by the ramps (the same
## navigation as the minions, enemy_navigation.gd, but planned for its own
## 2-unit body, T-419), it is drawn lifted by the
## ground's height, and its contact damage only hits the car at its level.

const KaijuScript := preload("res://scripts/enemies/kaiju.gd")
const KaijuSpriteScript := preload("res://scripts/enemies/kaiju_sprite.gd")
const EnemyDepthScript := preload("res://scripts/enemies/enemy_depth.gd")
const KaijuMeteorsScript := preload("res://scripts/enemies/kaiju_meteors.gd")
const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")
const EnemyNavigationScript := preload("res://scripts/enemies/enemy_navigation.gd")
const FollowerScript := preload("res://scripts/enemies/enemy_path_follower.gd")

const PX_PER_UNIT := 16.0
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## How far beyond the visible screen the whole drawn kaiju starts, in units:
## "just off-screen". A rule of the placeholder, not a balancing number.
const OFFSCREEN_MARGIN_UNITS := 1.0
## Spawn point tries per physics step before trying again on the next one.
const SPAWN_TRIES := 24
## The playtest switch file (res://data/playtest.json) and this task's key.
const PLAYTEST_FILE := "playtest"
const PLAYTEST_KEY := "kaiju_early_arrival"

## Tests set this to override data/playtest.json: -1 = off (the boss time
## only), 0 or more = arrive that many seconds into the run. -2 reads the file.
static var playtest_override := -2.0

## The kaiju appeared (just off-screen).
signal kaiju_appeared(kaiju: Node)
## The kaiju's health changed (weapons damaged it), and once when it appears.
signal kaiju_health_changed(health: float, max_health: float)
## The kaiju died; `coins` is how many coins it added to the run's coins.
signal kaiju_defeated(coins: int)

## False stops it appearing and moving (tests).
var enabled := true
## Playtest switch (data/playtest.json): seconds into the run when the kaiju
## arrives early; -1 = off (it arrives at the boss time).
var early_arrival_seconds := -1.0
## Random numbers for the arrival point. Seed it for tests.
var rng := RandomNumberGenerator.new()
var data: EnemyData

## Bound by bind(): the run's state, car, map and camera.
var state: Node = null
var car: Node2D = null
var map: Node2D = null
var camera: Camera2D = null
## The flat physics world's node for the kaiju's body.
var bodies_root: Node2D = null
## The drawing's node for its sprite: the minions' "Enemies" node (Y-sorted,
## just before the car's View) when the run has one, else its own.
var draw_root: Node2D = null
## The visible screen in the view's pixels; empty = use the camera.
var visible_rect_override := Rect2()

## The live kaiju, or null.
var kaiju: Node = null
## True once the kaiju has been asked to appear this run (boss time, or the
## playtest switch) and has not found a free spot yet (it tries again each step).
var arrival_due := false
var depth = EnemyDepthScript.new()
## T-207: false makes the kaiju ignore the map's heights (as before T-207).
## Read when a run's world is built.
var heights_enabled := true
## The map's ground heights (GroundHeight) and the enemies' navigation; null
## on a map without heights.
var ground = null
var navigation: RefCounted = null
## The kaiju's meteor attack (task T-046, kaiju_meteors.gd): child "Meteors".
var meteors: Node = null

## T-612: the killed kaiju while its death plays (null otherwise), and the
## seconds of it left. Its coins and the win come when they are over.
var dying_kaiju: Node = null
var death_left := 0.0

var _stats: Dictionary
var _appeared_this_run := false
var _run: Node = null


func _init() -> void:
	data = EnemyData.new()
	_stats = data.kaiju()
	rng.randomize()
	early_arrival_seconds = read_early_arrival_seconds()


## The playtest switch: `after_seconds` from data/playtest.json's
## "kaiju_early_arrival" when it is enabled, otherwise -1 (off). A missing
## file or value also means off. playtest_override, when not -2, wins.
static func read_early_arrival_seconds(file: String = PLAYTEST_FILE) -> float:
	if playtest_override > -2.0:
		return maxf(playtest_override, -1.0)
	var r := GameData.load_file(file)
	if not r.ok or typeof(r.data) != TYPE_DICTIONARY:
		return -1.0
	var setting = r.data.get(PLAYTEST_KEY, {})
	if typeof(setting) != TYPE_DICTIONARY or not bool(setting.get("enabled", false)):
		return -1.0
	return maxf(float(setting.get("after_seconds", -1.0)), -1.0)


## Binds the boss to a run scene (run.gd): its state, car, map, camera and
## PhysicsWorld; follows world_rebuilt (a new run) and the state's boss_time.
func bind(run: Node) -> void:
	_run = run
	state = run.state
	camera = run.camera
	bodies_root = Node2D.new()
	bodies_root.name = "KaijuBody"
	run.physics_world.add_child(bodies_root)
	var minions = run.get("minions")
	if minions != null and minions.get("draw_root") != null:
		draw_root = minions.draw_root
	else:
		draw_root = Node2D.new()
		draw_root.name = "Boss"
		draw_root.y_sort_enabled = true
		run.add_child(draw_root)
		run.move_child(draw_root, run.view_root.get_index())
	run.world_rebuilt.connect(_on_world_rebuilt)
	state.boss_time.connect(_on_boss_time)
	meteors = KaijuMeteorsScript.new()
	meteors.name = "Meteors"
	add_child(meteors)
	meteors.bind(run, self)
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
		# T-419: planned for its own body, off buildings and edges, so it never heads where it does not fit.
		navigation = EnemyNavigationScript.for_map(map, KaijuScript.RADIUS_UNITS, true)
	clear()


## Removes the kaiju; it can appear again (a new run).
func clear() -> void:
	if kaiju != null and is_instance_valid(kaiju):
		kaiju.queue_free()
	kaiju = null
	if dying_kaiju != null and is_instance_valid(dying_kaiju):
		dying_kaiju.queue_free()
	dying_kaiju = null
	death_left = 0.0
	arrival_due = false
	_appeared_this_run = false


## T-612 (HUD and menus, Decisions, "God mode can spawn the boss"): God mode's
## button makes the kaiju arrive now, by the boss time's own arrival (just
## off-screen, the same placing rules; if no spot is free now, on the next step
## it can), the run's timer untouched. Once per run: false, and nothing happens,
## when the kaiju has already arrived or is due. The boss time coming later then
## brings no second kaiju (once per run, as always).
func spawn_now() -> bool:
	if not can_spawn_now():
		return false
	arrival_due = true
	try_appear()
	return true


## T-612: true while the kaiju has neither arrived this run nor is due to.
func can_spawn_now() -> bool:
	return not _appeared_this_run and not arrival_due


## The run's "boss time": the kaiju appears (on the next step it can, just
## off-screen). Once per run.
func _on_boss_time() -> void:
	if not _appeared_this_run:
		arrival_due = true
		try_appear()


func _physics_process(delta: float) -> void:
	Perf.begin(&"kaiju.step")
	step(delta)
	Perf.end(&"kaiju.step")


func has_appeared() -> bool:
	return _appeared_this_run


## The live kaiju's health, or 0 when there is none.
func kaiju_health() -> float:
	return kaiju.health if _live() else 0.0


func kaiju_max_health() -> float:
	return kaiju.max_health if _live() else float(_stats.get("health", 0.0))


func _live() -> bool:
	return kaiju != null and is_instance_valid(kaiju) and not kaiju.is_dead()


## One physics step of `dt` seconds: the arrival (boss time, or the playtest
## switch), walking towards the car, contact damage, the drawing.
## Nothing happens once the run is over, except during the wreck (T-360, the
## board's quick tuning, 2026-10-29): a kaiju already there keeps walking to
## the wrecked car, with no contact (no damage, no knockback).
func step(dt: float) -> void:
	if dying_kaiju != null:
		_death_step(dt)
	if not enabled or car == null or not is_instance_valid(car):
		return
	var swarming: bool = state != null and state.has_method("is_wrecked") and state.is_wrecked()
	if swarming:
		if _live():
			_walk_to_car(dt)
			update_drawing()
		return
	if state != null and not state.is_running():
		return
	if not _appeared_this_run:
		if early_arrival_seconds >= 0.0 and state != null and state.time_elapsed() >= early_arrival_seconds:
			arrival_due = true
		if arrival_due:
			try_appear()
	if not _live():
		return
	_walk_to_car(dt)
	kaiju.contact_step(dt, car, state)
	update_drawing()


func _walk_to_car(dt: float) -> void:
	var car_units: Vector2 = car.position / PX_PER_UNIT
	var target := car_units
	if navigation != null and kaiju.follower != null:
		target = kaiju.follower.target(navigation, kaiju.position_units(), car_units, dt, false)
		kaiju.may_drop = kaiju.follower.dropping(navigation, kaiju.position_units(), kaiju.body_height())
	kaiju.walk(dt, target)


## Makes the kaiju appear just off-screen, if a free spot is found now.
## Returns the kaiju, or null (it tries again on the next step).
func try_appear() -> Node:
	if _appeared_this_run or car == null:
		return kaiju
	var p = pick_arrival_point()
	if p == null:
		return null
	return appear_at(p)


## Adds the kaiju with the data's stats at `units` (flat world), with its sprite.
func appear_at(units: Vector2) -> Node:
	if _live():
		kaiju.queue_free()
	var k: CharacterBody2D = KaijuScript.new()
	k.name = "Kaiju"
	k.setup(_stats)
	k.set_position_units(units)
	k.detour_side = 1.0 if rng.randf() < 0.5 else -1.0
	k.ground = ground
	k.follower = FollowerScript.new()
	if car != null:
		var to_car: Vector2 = car.position / PX_PER_UNIT - units
		if to_car.length() > 0.001:
			k.heading = to_car.normalized()
	bodies_root.add_child(k, true)
	var s: Node2D = KaijuSpriteScript.new()
	s.name = "KaijuSprite"
	draw_root.add_child(s, true)
	k.sprite = s
	k.health_changed.connect(_on_kaiju_health_changed)
	k.died.connect(_on_kaiju_died)
	kaiju = k
	_appeared_this_run = true
	arrival_due = false
	_place_sprite()
	s.reset_physics_interpolation()
	kaiju_appeared.emit(k)
	kaiju_health_changed.emit(k.health, k.max_health)
	return k


func _on_kaiju_health_changed(health: float, max_health: float) -> void:
	kaiju_health_changed.emit(health, max_health)


## The kaiju was killed (T-612): it plays its death for EnemyData.
## kaiju_death_seconds() (the death animation's frames / fps), standing still,
## harmless and no longer a target; the run is told the win is due
## (RunState.kaiju_dying(): the timer reaching 0:00 or a wreck meanwhile no
## longer loses it). The kill counts in the recap now. With no death length the
## death ends at once, as before T-612.
func _on_kaiju_died(k: Node, _at_units: Vector2) -> void:
	kaiju = null
	dying_kaiju = k
	death_left = data.kaiju_death_seconds()
	if state != null and state.has_method("kaiju_dying"):
		state.kaiju_dying()
	if state != null and state.has_method("enemy_slain"):
		state.enemy_slain(k.ENEMY_TYPE, k.last_hit_by)  # recap (T-319)
	if death_left <= 0.0:
		_finish_death()


## True while the killed kaiju's death plays.
func is_kaiju_dying() -> bool:
	return dying_kaiju != null


## One physics step of the death: the kaiju stays where it died (a fall in
## progress still comes down), drawn in its place and depth, until the death's
## seconds are over.
func _death_step(dt: float) -> void:
	if not is_instance_valid(dying_kaiju):
		dying_kaiju = null
		return
	var h0: float = dying_kaiju.body_height()
	dying_kaiju._fall_step(dt, h0)
	_place_sprite(dying_kaiju)
	death_left -= dt
	if death_left <= 0.000001:
		_finish_death()


## The death has played: the kaiju goes, its coins go into the run's coins
## first (the run ends now, and the coins must count in the coins saved), then
## the run's kaiju_killed() ends the run as a win.
func _finish_death() -> void:
	var k := dying_kaiju
	dying_kaiju = null
	death_left = 0.0
	if k != null and is_instance_valid(k):
		k.queue_free()
	var n := data.kaiju_coins_on_defeat()
	if state != null:
		state.add_coins(n)
	kaiju_defeated.emit(n)
	if state != null:
		state.kaiju_killed()


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


## The ring of arrival points, in the view's pixels: the visible screen grown
## so that the whole drawn kaiju (its ground circle, and its height above its
## feet) is OFFSCREEN_MARGIN_UNITS beyond the screen's edge.
func arrival_ring() -> Rect2:
	var px := PX_PER_UNIT
	var r: float = KaijuScript.RADIUS_UNITS
	var m := OFFSCREEN_MARGIN_UNITS * px
	var half_w := r * sqrt(2.0) * px  # the ground circle's half width on screen
	var half_h := r * sqrt(2.0) * 0.5 * px
	return visible_rect().grow_individual(half_w + m, half_h + m, half_w + m,
		KaijuScript.HEIGHT_UNITS * px + half_h + m)


## A random arrival point (flat world units) on arrival_ring(), on the map and
## clear of buildings and boulders; null when none of SPAWN_TRIES tries is free.
func pick_arrival_point():
	var r := arrival_ring()
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


## True when the kaiju fits at `units`: inside the map, not on a building or
## a boulder, and on a map with heights on the street (T-207).
func is_free_spot(units: Vector2) -> bool:
	if map == null:
		return true
	var rad: float = KaijuScript.RADIUS_UNITS
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


## Puts the kaiju's sprite at its body's place in the view and in the depth order.
func update_drawing() -> void:
	_place_sprite()


## Places the live kaiju's sprite, or `k`'s (the dying one, T-612).
func _place_sprite(k: Node = null) -> void:
	if k == null:
		if not _live():
			return
		k = kaiju
	if k.sprite == null or not is_instance_valid(k.sprite):
		return
	var s: Node2D = k.sprite
	var h: float = k.body_height()
	s.position = ISO_TRANSFORM * k.position + Vector2(0.0, -h * PX_PER_UNIT)
	s.face(k.heading)
	s.set_falling(k.is_falling())
	# T-612: the windup animation plays while the meteor attack winds up.
	if s.has_method("set_winding_up"):
		s.set_winding_up(not k.is_dead() and meteors != null and meteors.is_winding_up())
	s.air_height = h - k.ground_height()  # T-454: its shadow stays on the ground under it
	s.z_index = depth.z_index_for(k.position_units(), KaijuScript.RADIUS_UNITS, KaijuScript.HEIGHT_UNITS, h)
