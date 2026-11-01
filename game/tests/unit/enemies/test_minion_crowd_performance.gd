extends GutTest
## Task T-444 ("The game stays fast with a crowd of minions"): every shortcut of the minions'
## step gives the same answers as the work it replaced, on the game's map (Kaiju City):
## - the ground's quick lookup (enemy_ground_index.gd) answers height_at and area_index_at
##   exactly as GroundHeight does, and is rebuilt when the ground's lists change;
## - a move over flat street (enemy_height.gd, limit_motion's shortcut) is limited exactly as
##   the piece-by-piece check limits it;
## - the depth order's screen grid (enemy_depth.gd) gives the z_index the old test of every
##   building, boulder, prop and raised area gave, also after a meteor boulder is added;
## - pushing apart by grid cells (minion_spawner.gd, _separation) gives the same pushes as
##   comparing every pair;
## - the car's surface kept by the navigation (surface_at) follows the car when it moves.

const RunScene := preload("res://scenes/run/run.tscn")
const GAME_MAP := "res://data/level/kaiju_city_map.json"
const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")
const EnemyDepthScript := preload("res://scripts/enemies/enemy_depth.gd")
const GroundIndexScript := preload("res://scripts/enemies/enemy_ground_index.gd")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)

var run: Node2D
var spawner: Node
var ground
var map: Node2D
var rng := RandomNumberGenerator.new()


## A ground that answers only height_at (no quick lookup): enemy_height.gd then checks a move
## piece by piece, as before T-444.
class PlainGround extends RefCounted:
	var g

	func _init(the_ground) -> void:
		g = the_ground

	func height_at(p: Vector2) -> float:
		return g.height_at(p)


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
	get_tree().paused = false
	remove_child(run)
	run.free()
	run = null


func before_each() -> void:
	rng.seed = 444


## Random points over the map and its areas' edges, corners and just off them.
func _sample_points(n: int) -> Array:
	var out := []
	var r: Rect2 = map.rect_of(map.layout.map.rect)
	for i in n:
		out.append(r.position + Vector2(rng.randf(), rng.randf()) * r.size)
	var areas: Array = []
	for p in ground.platforms:
		areas.append(p.rect)
	for q in ground.ramps:
		areas.append(q.rect)
	for i in mini(areas.size(), 300):
		var a: Rect2 = areas[rng.randi_range(0, areas.size() - 1)]
		for c in [a.position, a.end, Vector2(a.end.x, a.position.y), Vector2(a.position.x, a.end.y), a.get_center()]:
			out.append(c)
			out.append(c + Vector2(0.001, -0.001))
			out.append(c - Vector2(0.25, 0.25))
		out.append(Vector2(a.position.x + rng.randf() * a.size.x, a.position.y))
		out.append(Vector2(a.end.x, a.position.y + rng.randf() * a.size.y))
	return out


func test_the_map_is_kaiju_city_with_heights() -> void:
	assert_eq(run.current_layout_path(), GAME_MAP)
	assert_not_null(ground)
	assert_gt(ground.platforms.size() + ground.ramps.size(), 20, "the map has rooftops, short buildings and ramps")


func test_the_ground_lookup_answers_like_the_ground() -> void:
	var idx = GroundIndexScript.of(ground)
	assert_same(GroundIndexScript.of(ground), idx, "one lookup per ground, kept")
	assert_same(GroundIndexScript.of(idx), idx, "a lookup given in place of a ground is used as it is")
	var pts := _sample_points(4000)
	var wrong_h := 0
	var wrong_a := 0
	for p in pts:
		if idx.height_at(p) != ground.height_at(p):
			wrong_h += 1
		if idx.area_index_at(p) != ground.area_index_at(p):
			wrong_a += 1
	assert_eq(wrong_h, 0, "heights the same at %d points" % pts.size())
	assert_eq(wrong_a, 0, "surfaces the same at %d points" % pts.size())
	assert_eq(EnemyHeightScript.height_at(ground, Vector2(9999, 9999)), 0.0, "off the map: the street")


func test_the_ground_lookup_is_rebuilt_when_the_ground_changes() -> void:
	var g := GroundHeight.new()
	g.platforms = [{"id": "a", "rect": Rect2(0, 0, 10, 10), "height": 3.0, "on": ""}]
	var idx = GroundIndexScript.of(g)
	assert_eq(idx.height_at(Vector2(5, 5)), 3.0)
	assert_eq(idx.height_at(Vector2(25, 5)), 0.0)
	var builds: int = idx.builds
	g.platforms.append({"id": "b", "rect": Rect2(20, 0, 10, 10), "height": 6.0, "on": ""})
	assert_eq(EnemyHeightScript.height_at(g, Vector2(25, 5)), 6.0, "a platform added later is seen")
	assert_eq(idx.builds, builds + 1, "rebuilt once")
	g.load_data({"platforms": [{"id": "c", "x": 0, "y": 0, "w": 4, "h": 4, "height": 3}], "ramps": []})
	assert_eq(EnemyHeightScript.height_at(g, Vector2(25, 5)), 0.0, "a ground loaded again is seen")
	assert_eq(EnemyHeightScript.height_at(g, Vector2(2, 2)), 3.0)
	assert_eq(EnemyHeightScript.height_at(null, Vector2(2, 2)), 0.0, "no ground: 0 as before")


func test_flat_street_moves_are_limited_as_piece_by_piece() -> void:
	var plain := PlainGround.new(ground)
	var pts := _sample_points(1500)
	var checked := 0
	var flat := 0
	var idx = GroundIndexScript.of(ground)
	for p in pts:
		var motion := Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(0.02, 1.2)
		for body_h in [NAN, ground.height_at(p), ground.height_at(p) + 2.0]:
			for drop in [false, true]:
				var fast: Dictionary = EnemyHeightScript.limit_motion(ground, p, motion, 0.5, body_h, drop)
				var slow: Dictionary = EnemyHeightScript.limit_motion(plain, p, motion, 0.5, body_h, drop)
				checked += 1
				if EnemyHeightScript._flat_move(idx, p, motion, 0.5, body_h, drop):
					flat += 1
				if fast.normal != slow.normal or fast.segments.size() != slow.segments.size():
					fail_test("different limit at %s by %s (h %s, drop %s): %s against %s" % [p, motion, body_h, drop, fast, slow])
					return
				for k in fast.segments.size():
					if not (fast.segments[k] as Vector2).is_equal_approx(slow.segments[k]):
						fail_test("different segment at %s by %s: %s against %s" % [p, motion, fast, slow])
						return
	assert_gt(flat, 100, "the shortcut was taken (%d of %d moves)" % [flat, checked])
	assert_lt(flat, checked, "and not taken near the areas")


## The depth order as before T-444: every building, boulder and prop sprite and raised area tested.
func _z_all_items(centre: Vector2, radius: float, height: float, ground_h: float) -> int:
	var z: int = map.top_z_index()
	var shape := EnemyDepthScript.screen_shape(centre, radius, height)
	if ground_h != 0.0:
		shape = Transform2D(0.0, Vector2(0.0, -ground_h * 16.0)) * shape
	var box := EnemyDepthScript._bounds(shape)
	for b in map.fade_items():
		if b.z_index - 1 < z and b.is_behind(centre) and EnemyDepthScript._bounds(b.iso_silhouette()).intersects(box) \
				and b.overlaps_on_screen(shape):
			z = b.z_index - 1
	for s in map.depth_sprites():
		if s.z_index - 1 < z and s.covers(centre, shape, box):
			z = s.z_index - 1
	return run.elevation.z_under_areas(z, centre, radius, ground_h, shape)


func _depth_mismatches(depth, pts: Array) -> int:
	var wrong := 0
	for p in pts:
		var gh: float = ground.height_at(p)
		if depth.z_index_for(p, 1.0, 1.6, gh) != _z_all_items(p, 1.0, 1.6, gh):
			wrong += 1
		if depth.z_index_for(p, 0.3, 0.6, 0.0) != _z_all_items(p, 0.3, 0.6, 0.0):
			wrong += 1
	return wrong


func test_the_depth_grid_gives_the_same_order_as_testing_every_item() -> void:
	var depth = EnemyDepthScript.new(map)
	var pts := _sample_points(1200)
	var differing := 0
	var top: int = map.top_z_index()
	for p in pts:
		if _z_all_items(p, 1.0, 1.6, ground.height_at(p)) != top:
			differing += 1
	assert_gt(differing, 50, "many points are covered by something (%d of %d)" % [differing, pts.size()])
	assert_eq(_depth_mismatches(depth, pts), 0, "the same z_index at every point")
	assert_eq(depth.builds, 1, "the grid is built once for many questions")


func test_the_depth_grid_is_rebuilt_for_a_meteor_boulder() -> void:
	var depth = EnemyDepthScript.new(map)
	var car_units: Vector2 = run.car.position / 16.0
	depth.z_index_for(car_units, 1.0, 1.6)
	var builds: int = depth.builds
	# A boulder where one can go, then the spots just behind it (where it covers a minion).
	var centre := Vector2.INF
	for i in 400:
		var c: Vector2 = car_units + Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40))
		if map.can_place_meteor_boulder(c):
			centre = c
			break
	assert_ne(centre, Vector2.INF, "a free spot for a boulder")
	var behind := []
	for i in 40:
		behind.append(centre - Vector2(1.2, 1.2) + Vector2(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.8, 0.8)))
	var before := []
	for p in behind:
		before.append(depth.z_index_for(p, 0.3, 0.6, 0.0))
	map.add_meteor_boulder(centre)
	assert_eq(_depth_mismatches(depth, behind), 0, "the new boulder is in the order at once")
	assert_eq(depth.builds, builds + 1, "rebuilt once for it")
	var lowered := 0
	for i in behind.size():
		if depth.z_index_for(behind[i], 0.3, 0.6, 0.0) < before[i]:
			lowered += 1
	assert_gt(lowered, 0, "the boulder covers spots behind it")


func test_pushing_apart_by_grid_cells_gives_the_same_pushes_as_every_pair() -> void:
	spawner.clear()
	var car_units: Vector2 = run.car.position / 16.0
	var placed := 0
	while placed < 250:
		var p: Vector2 = car_units + Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(0.0, 9.0)
		if spawner.is_free_spot(p):
			spawner.spawn_minion_at(p)
			placed += 1
	# A few on the very same spot and a few on a cell's border.
	for i in 3:
		spawner.spawn_minion_at(spawner.minions[0].position_units())
	var a: Array = spawner._separation()
	var b: Array = spawner._separation_all_pairs()
	assert_eq(a.size(), b.size())
	var pushed := 0
	var wrong := 0
	for i in a.size():
		if a[i] != b[i]:
			wrong += 1
		if (a[i] as Vector2).length() > 0.0:
			pushed += 1
	assert_eq(wrong, 0, "every push the same")
	assert_gt(pushed, 200, "a crowd pushes apart (%d of %d)" % [pushed, a.size()])
	spawner.clear()


func test_the_kept_car_surface_follows_the_car() -> void:
	var nav = spawner.navigation
	assert_not_null(nav)
	var on_roof := Vector2.INF
	for p in ground.platforms:
		if not p.short:
			on_roof = (p.rect as Rect2).get_center()
			break
	var street := Vector2.INF
	var r: Rect2 = map.rect_of(map.layout.map.rect)
	for i in 500:
		var q: Vector2 = r.position + Vector2(rng.randf(), rng.randf()) * r.size
		if ground.area_index_at(q) == -1:
			street = q
			break
	assert_eq(nav.surface_at(on_roof), ground.area_index_at(on_roof))
	assert_eq(nav.surface_at(on_roof), ground.area_index_at(on_roof), "asked again: kept")
	assert_eq(nav.surface_at(street), -1, "the car moved to the street")
	assert_eq(nav.surface_at(on_roof), ground.area_index_at(on_roof), "and back onto the rooftop")
	assert_ne(ground.area_index_at(on_roof), -1)


func test_crowded_minions_still_walk_to_the_car() -> void:
	# The same step as the game's, with the shortcuts: a crowd round the parked car closes in.
	spawner.clear()
	spawner.enabled = true
	var car_units: Vector2 = run.car.position / 16.0
	spawner._spawning["max_minions_alive"] = 0.0
	var start_dist := 0.0
	while spawner.minions.size() < 120:
		var p: Vector2 = car_units + Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(10.0, 14.0)
		if spawner.is_free_spot(p):
			spawner.spawn_minion_at(p).max_health = 1000000.0
	for m in spawner.minions:
		start_dist += m.position_units().distance_to(car_units)
	spawner.visible_rect_override = Rect2(ISO * run.car.position - Vector2(800, 450), Vector2(1600, 900))
	for i in 150:
		spawner.move_step(0.02, false)
		spawner.update_drawing()
	var end_dist := 0.0
	for m in spawner.minions:
		end_dist += m.position_units().distance_to(car_units)
	spawner.enabled = false
	spawner._spawning = spawner.data.spawning()
	assert_lt(end_dist / spawner.minions.size(), start_dist / spawner.minions.size() - 4.0,
		"the crowd closed in on the car (%.1f to %.1f units on average)" % [start_dist / 120.0, end_dist / spawner.minions.size()])
	spawner.clear()
