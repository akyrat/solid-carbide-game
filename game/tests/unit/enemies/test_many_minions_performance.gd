extends GutTest
## Task T-538 ("No slowdown from many minions"): every shortcut that made a big crowd cheaper
## gives the same answers as the work it replaced, on the game's map (Kaiju City):
## - a minion keeps its ground height while it stays on the same spot (minion.gd,
##   ground_height), the same number the ground gives, and reads it again after a move or a
##   rebuilt ground lookup;
## - a minion's move over flat street (minion.gd, _move's shortcut) ends where the old move
##   (enemy_height.gd limit_motion, then move_and_collide piece by piece) ends;
## - the depth order placed for the whole crowd at once (enemy_depth.gd, begin_batch, kept
##   outlines, empty cells) gives the z_index each minion gets when asked alone, checks the
##   map's lists once, and sees a meteor boulder added between two steps;
## - the follower given the car's surface (enemy_path_follower.gd, car_surface_now) walks the
##   same way as when it asks for it;
## - the minion's drawing is redrawn only when what it shows changes (minion_sprite.gd).
## Pushing apart (minion_spawner.gd, _separation, now each pair once) is checked bit for bit
## against every pair by test_minion_crowd_performance.gd.

const RunScene := preload("res://scenes/run/run.tscn")
const GAME_MAP := "res://data/level/kaiju_city_map.json"
const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")
const EnemyDepthScript := preload("res://scripts/enemies/enemy_depth.gd")
const GroundIndexScript := preload("res://scripts/enemies/enemy_ground_index.gd")
const FollowerScript := preload("res://scripts/enemies/enemy_path_follower.gd")
const SpriteScript := preload("res://scripts/enemies/minion_sprite.gd")

var run: Node2D
var spawner: Node
var ground
var map: Node2D
var rng := RandomNumberGenerator.new()


func before_all() -> void:
	run = RunScene.instantiate()
	run.layout_path = GAME_MAP
	add_child(run)
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	run.car.set_physics_process(false)
	spawner = run.minions
	spawner.enabled = false
	spawner.clear()
	run.kaiju_boss.enabled = false
	ground = run.elevation.ground_height
	map = run.map


func after_all() -> void:
	spawner.clear()
	remove_child(run)
	run.free()
	run = null


func before_each() -> void:
	rng.seed = 538
	spawner.clear()


## Free street spots round the car, `n` of them, `near` to `far` units away.
func _spots(n: int, near: float, far: float) -> Array:
	var car_units: Vector2 = run.car.position / 16.0
	var out := []
	var tries := 0
	while out.size() < n and tries < n * 300:
		tries += 1
		var p: Vector2 = car_units + Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(near, far)
		if spawner.is_free_spot(p):
			out.append(p)
	return out


## Spots next to rooftops and ramps (just off their edges), where moves are limited.
func _spots_by_areas(n: int) -> Array:
	var out := []
	var areas := []
	for p in ground.platforms:
		areas.append(p.rect)
	for q in ground.ramps:
		areas.append(q.rect)
	var tries := 0
	while out.size() < n and tries < n * 300:
		tries += 1
		var a: Rect2 = areas[rng.randi_range(0, areas.size() - 1)]
		var p := Vector2(rng.randf_range(a.position.x - 1.5, a.end.x + 1.5), rng.randf_range(a.position.y - 1.5, a.end.y + 1.5))
		if spawner.is_free_spot(p):
			out.append(p)
	return out


func test_a_minion_keeps_its_ground_height_only_on_the_same_spot() -> void:
	var spots := _spots(20, 4.0, 30.0) + _spots_by_areas(40)
	assert_gt(spots.size(), 40)
	var m = spawner.spawn_minion_at(spots[0])
	var wrong := 0
	for p in spots:
		m.set_position_units(p)
		var first: float = m.ground_height()
		if first != ground.height_at(p) or m.ground_height() != first:
			wrong += 1
		# Moved a little: read again.
		m.position += Vector2(3.0, -2.0)
		if m.ground_height() != ground.height_at(m.position_units()):
			wrong += 1
	assert_eq(wrong, 0, "the ground's own height at every spot, also after a move")


func test_a_minion_reads_its_height_again_after_the_ground_lookup_is_rebuilt() -> void:
	var g := GroundHeight.new()
	g.platforms = [{"id": "a", "rect": Rect2(0, 0, 10, 10), "height": 3.0, "on": ""}]
	var m = spawner.spawn_minion_at(_spots(1, 4.0, 10.0)[0])
	m.ground = g
	m.set_position_units(Vector2(25, 5))
	assert_eq(m.ground_height(), 0.0, "the street")
	var gen: int = GroundIndexScript.generation
	g.platforms.append({"id": "b", "rect": Rect2(20, 0, 10, 10), "height": 6.0, "on": ""})
	GroundIndexScript.of(g)  # what the spawner does once a step
	assert_gt(GroundIndexScript.generation, gen, "a rebuild moves the generation on")
	assert_eq(m.ground_height(), 6.0, "the platform added under it is seen")
	m.ground = ground
	m.set_position_units(Vector2(25, 5))
	assert_eq(m.ground_height(), ground.height_at(Vector2(25, 5)), "another ground: read again")


## The move as it was before T-538 (minion.gd _move): limit_motion's pieces, one after the other.
func _old_move(m, motion: Vector2) -> Array:
	var lim: Dictionary = EnemyHeightScript.limit_motion(m.ground, m.position_units(), motion / 16.0,
		m.BASE_RADIUS_UNITS, m.body_height(), false)
	var hit = null
	for seg in lim.segments:
		if (seg as Vector2).length() < 0.000001:
			continue
		hit = m.move_and_collide(seg * 16.0)
		if hit != null:
			break
	return [hit != null, lim.normal]


func test_a_move_ends_where_the_old_move_ended() -> void:
	var spots := _spots(60, 2.0, 40.0) + _spots_by_areas(140)
	var a = spawner.spawn_minion_at(spots[0])
	var b = spawner.spawn_minion_at(spots[0])
	var idx = GroundIndexScript.of(ground)
	var flat := 0
	var wrong := []
	for p in spots:
		for k in 3:
			var motion: Vector2 = Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(0.05, 2.5) * 16.0
			a.set_position_units(p)
			b.set_position_units(p)
			if EnemyHeightScript._flat_move(idx, p, motion / 16.0, a.BASE_RADIUS_UNITS, a.body_height(), false):
				flat += 1
			var hit_new: bool = a._move(motion) != null
			var old: Array = _old_move(b, motion)
			if a.position != b.position or hit_new != old[0] or a._edge_normal != old[1]:
				wrong.append("%s by %s: %s against %s" % [p, motion, a.position_units(), b.position_units()])
	assert_eq(wrong.size(), 0, "the same end of every move: %s" % [wrong.slice(0, 3)])
	assert_gt(flat, 50, "the shortcut was taken (%d moves)" % flat)
	assert_lt(flat, spots.size() * 3, "and not by the areas")


func test_the_crowd_placed_at_once_gets_each_ones_own_depth() -> void:
	for p in _spots(150, 2.0, 30.0) + _spots_by_areas(150):
		spawner.spawn_minion_at(p)
	spawner.update_drawing()
	var alone = EnemyDepthScript.new(map)
	var wrong := 0
	var covered := 0
	var top: int = map.top_z_index()
	for m in spawner.minions:
		var z: int = alone.z_index_for(m.position_units(), m.radius_units(), m.height_units(), m.body_height())
		if m.sprite.z_index != z:
			wrong += 1
		if z != top:
			covered += 1
	assert_eq(wrong, 0, "every minion's z_index the same as asked alone")
	assert_gt(covered, 20, "many are covered by something (%d)" % covered)


func test_the_crowd_checks_the_maps_lists_once_and_sees_a_new_boulder() -> void:
	var spots := _spots(80, 2.0, 30.0)
	for p in spots:
		spawner.spawn_minion_at(p)
	spawner.update_drawing()
	var builds: int = spawner.depth.builds
	spawner.update_drawing()
	assert_eq(spawner.depth.builds, builds, "the same lists: not built again")
	assert_false(spawner.depth._batch, "the batch is closed after the crowd")
	# A boulder between two steps, just in front of a minion: it is covered at the next step.
	var placed = null
	for m in spawner.minions:
		var c: Vector2 = m.position_units() + Vector2(1.4, 1.4)
		if map.can_place_meteor_boulder(c) and m.position_units().distance_to(c) > 1.0:
			map.add_meteor_boulder(c)
			placed = m
			break
	assert_not_null(placed, "a spot for a boulder in front of a minion")
	var before_z: int = placed.sprite.z_index
	spawner.update_drawing()
	assert_eq(spawner.depth.builds, builds + 1, "rebuilt once for the boulder")
	var alone = EnemyDepthScript.new(map)
	assert_eq(placed.sprite.z_index, alone.z_index_for(placed.position_units(), placed.radius_units(),
		placed.height_units(), placed.body_height()), "the boulder is in its order")
	assert_true(placed.sprite.z_index <= before_z, "not drawn over the boulder in front of it")


func test_the_follower_given_the_cars_surface_walks_the_same_way() -> void:
	var nav = spawner.navigation
	assert_not_null(nav)
	var car_units: Vector2 = run.car.position / 16.0
	var spots := _spots_by_areas(60) + _spots(20, 10.0, 40.0)
	var wrong := 0
	for p in spots:
		var a = FollowerScript.new(0.0)
		var b = FollowerScript.new(0.0)
		a.by_sight = true
		b.by_sight = true
		for step in 8:
			var ta: Vector2 = a.target(nav, p, car_units, 0.02)
			nav.new_step()
			var tb: Vector2 = b.target(nav, p, car_units, 0.02, true, nav.surface_at(car_units))
			nav.new_step()
			if ta != tb or a.has_path() != b.has_path():
				wrong += 1
	assert_eq(wrong, 0, "the same targets")


func test_the_drawing_is_redrawn_only_when_it_changes() -> void:
	var s: Node2D = SpriteScript.new()
	add_child_autofree(s)
	s._walk = 0.0
	s.facing = Vector2.RIGHT
	var calls := 0
	for i in 60:  # one second at 60 frames a second: 10 walk frames
		s._process(1.0 / 60.0)
		calls += 1
	assert_between(s.redraws, 9, 12, "about one redraw a walk frame (%d for %d frames)" % [s.redraws, calls])
	var n: int = s.redraws
	s._process(0.0)
	assert_eq(s.redraws, n, "nothing changed: no redraw")
	s.face(Vector2(0.0, 1.0))
	s._process(0.0)
	assert_eq(s.redraws, n + 1, "a new direction: redrawn")
	s.set_falling(true)
	s.air_height = 1.0
	n = s.redraws
	for i in 5:
		s._process(1.0 / 60.0)
	assert_eq(s.redraws, n + 5, "falling: redrawn every frame, as before")
	s.set_falling(false)
	s.air_height = 0.0
	n = s.redraws
	for i in 3:
		s._process(1.0 / 60.0)
	assert_eq(s.redraws, n + 3, "landing squash: every frame")
	assert_null(s.draw_key(), "still squashing")
	for i in 30:
		s._process(1.0 / 60.0)
	assert_not_null(s.draw_key(), "walking again: drawn from its key")
