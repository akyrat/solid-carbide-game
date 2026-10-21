extends GutTest
## Task T-207 (Enemies, Decisions, "Enemies follow the car up the ramps"): on
## the elevation map enemies treat rooftops as raised ground they reach only
## by the ramps, find their way there (enemy_navigation.gd, AStar2D), are
## stopped by every rooftop edge from below and from above, are drawn at
## their height in the depth order, and only hit the car at its level.
##
## The map (data/level/elevation_sample_map.json): roof-nw-3 (-96..-12,
## -96..-66, height 3) with roof-nw-6 (-42..-12, height 6) on its east end;
## ramp-nw-0-3 (-86..-76, -66..-54) climbs north from the street onto
## roof-nw-3, ramp-nw-3-6 (-54..-42, -86..-76) climbs east onto roof-nw-6.
## The south-east pair mirrors them (roof-se-3, roof-se-6, ramp-se-0-3,
## ramp-se-3-6).

const RunScene := preload("res://scenes/run/run.tscn")
const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")
const EnemyNavigationScript := preload("res://scripts/enemies/enemy_navigation.gd")
const FollowerScript := preload("res://scripts/enemies/enemy_path_follower.gd")
const MinionScript := preload("res://scripts/enemies/minion.gd")
const KaijuScript := preload("res://scripts/enemies/kaiju.gd")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const DT := 0.02  # one physics step (50 per second)
## The time limit for the climbs: about three times the longest way at the
## minion's 6 units a second (the longest way, round a rooftop block, is
## about 200 units).
const CLIMB_LIMIT_SECONDS := 40.0

var run: Node2D
var spawner: Node
var ground


func before_each() -> void:
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	run.car.set_physics_process(false)
	spawner = run.minions
	spawner.enabled = false
	spawner.clear()
	spawner.rng.seed = 207
	run.kaiju_boss.enabled = false
	ground = run.elevation.ground_height


func after_each() -> void:
	get_tree().paused = false


## Puts the car at rest at `units`, on the ground there (height included).
func _place_car(units: Vector2, rot: float = 0.0) -> void:
	var car = run.car
	car.model.set_position(units)
	car.model.rotation = rot
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = ground
	run.sync_view()


func _spawn(units: Vector2) -> Node:
	return spawner.spawn_minion_at(units)


func _touching_car(m: Node) -> bool:
	return m.touches_car(run.car.position / 16.0, run.car.rotation)


## Steps the minions (no spawning) until each one touches the car or the time
## limit runs out. Returns {"reached": per minion, "seconds": per minion,
## "ramps": per minion the ramp ids it walked on, "worst_step": the largest
## change of ground height in one step, any minion}.
func _chase(ms: Array, limit: float) -> Dictionary:
	var reached := []
	var secs := []
	var ramps := []
	var prev := []
	for m in ms:
		reached.append(false)
		secs.append(-1.0)
		ramps.append({})
		prev.append(m.ground_height())
	var worst := 0.0
	var t := 0.0
	while t < limit:
		spawner.move_step(DT)
		spawner.update_drawing()
		run.state.health = run.state.max_health
		t += DT
		var all := true
		for i in ms.size():
			var m = ms[i]
			var h: float = m.ground_height()
			worst = maxf(worst, absf(h - prev[i]))
			prev[i] = h
			var r: Dictionary = ground.ramp_at(m.position_units())
			if not r.is_empty():
				ramps[i][r.id] = true
			if not reached[i] and _touching_car(m):
				reached[i] = true
				secs[i] = t
			all = all and reached[i]
		if all:
			break
	return {"reached": reached, "seconds": secs, "ramps": ramps, "worst_step": worst}


# --- The navigation -------------------------------------------------------------

func test_one_navigation_per_map_shared_by_minions_and_kaiju() -> void:
	var nav = spawner.navigation
	assert_not_null(nav, "the elevation map has a navigation")
	assert_eq(run.kaiju_boss.navigation, nav, "the kaiju uses the same one")
	assert_eq(EnemyNavigationScript.for_map(run.map), nav, "kept on the map")
	assert_eq(spawner.ground, ground)
	gut.p("navigation build: %d points, %.1f ms" % [nav.astar.get_point_count(), nav.build_usec / 1000.0])
	assert_lt(nav.build_usec, 2000000, "built in under 2 s, once per run")
	run.start_run()
	assert_ne(spawner.navigation, nav, "a new run's map brings a new one")


func test_the_mvp_map_has_no_heights_for_enemies() -> void:
	run.use_elevation_map = false
	run.start_run()
	assert_null(spawner.navigation)
	assert_null(spawner.ground)
	assert_null(run.kaiju_boss.navigation)
	var m := _spawn(Vector2(54, 0))
	assert_null(m.ground, "minions walk as before T-207")
	assert_eq(m.ground_height(), 0.0)


## T-226 changed this: links more than a step apart now exist, but only as
## one-way drops (down), never up.
func test_no_link_climbs_more_than_a_step() -> void:
	var nav = spawner.navigation
	var bad := 0
	var two_way_drops := 0
	var links := 0
	for k in nav.heights.size():
		if not nav.astar.has_point(k):
			continue
		for other in nav.astar.get_point_connections(k):
			links += 1
			if nav.heights[other] - nav.heights[k] > EnemyHeightScript.MAX_STEP:
				bad += 1
			if nav.heights[k] - nav.heights[other] > EnemyHeightScript.MAX_STEP 					and nav.astar.are_points_connected(other, k, false):
				two_way_drops += 1
	assert_gt(links, 10000)
	assert_eq(bad, 0, "no link climbs by more than MAX_STEP")
	assert_eq(two_way_drops, 0, "every drop link is one-way, down")


func test_buildings_and_boulders_are_closed_cells() -> void:
	var nav = spawner.navigation
	for b in run.map.layout.buildings:
		var c: Vector2 = run.map.rect_of(b).get_center()
		assert_false(nav.astar.has_point(nav.cell_at(c)), "no path through the building at %s" % c)
	var boulders: Array = run.map.all_boulders()
	assert_gt(boulders.size(), 0)
	for b in boulders:
		var c := Vector2(float(b.x), float(b.y))
		assert_false(nav.astar.has_point(nav.cell_at(c)), "no path through the boulder at %s" % c)


## T-226 changed this: no link climbs a rooftop's edge from below (the drop
## links go down only; test_enemies_drop_off_ledges.gd checks they exist).
func test_no_link_climbs_a_rooftop_edge() -> void:
	var nav = spawner.navigation
	var crossings := 0
	for p in ground.platforms:
		var rect: Rect2 = p.rect
		# Each cell just inside an edge and its neighbour just outside.
		var x := rect.position.x + 1.0
		while x < rect.end.x:
			for pair in [[Vector2(x, rect.position.y + 1.0), Vector2(x, rect.position.y - 1.0)],
					[Vector2(x, rect.end.y - 1.0), Vector2(x, rect.end.y + 1.0)]]:
				crossings += _linked_across(nav, pair[0], pair[1])
			x += 2.0
		var y := rect.position.y + 1.0
		while y < rect.end.y:
			for pair in [[Vector2(rect.position.x + 1.0, y), Vector2(rect.position.x - 1.0, y)],
					[Vector2(rect.end.x - 1.0, y), Vector2(rect.end.x + 1.0, y)]]:
				crossings += _linked_across(nav, pair[0], pair[1])
			y += 2.0
	assert_eq(crossings, 0, "no link from lower ground up onto a rooftop beside it")


## 1 when the cell at b (outside, lower) links up to the cell at a although
## their ground differs by more than a step.
func _linked_across(nav, a: Vector2, b: Vector2) -> int:
	var ka: int = nav.cell_at(a)
	var kb: int = nav.cell_at(b)
	if ka < 0 or kb < 0 or not nav.astar.has_point(ka) or not nav.astar.has_point(kb):
		return 0
	if absf(nav.heights[ka] - nav.heights[kb]) <= EnemyHeightScript.MAX_STEP:
		return 0  # a ramp's top meets the rooftop here: level ground
	return 1 if nav.astar.are_points_connected(kb, ka, false) else 0


func test_a_path_from_the_street_to_height_6_goes_by_both_ramps() -> void:
	var nav = spawner.navigation
	var path: PackedVector2Array = nav.find_path(Vector2(-81, -40), Vector2(-27, -81))
	assert_gt(path.size(), 2)
	var foot_0_3: Vector2 = nav.ramp_end(0, false)
	var top_0_3: Vector2 = nav.ramp_end(0, true)
	var foot_3_6: Vector2 = nav.ramp_end(1, false)
	var top_3_6: Vector2 = nav.ramp_end(1, true)
	var order := []
	for p in [foot_0_3, top_0_3, foot_3_6, top_3_6]:
		order.append(path.find(p))
	assert_true(order[0] >= 0 and order[1] > order[0] and order[2] > order[1] and order[3] > order[2],
		"up ramp-nw-0-3, then up ramp-nw-3-6: %s" % [order])
	assert_almost_eq(ground.height_at(foot_0_3), 0.0, 0.001, "the foot's point is on the street")
	assert_almost_eq(ground.height_at(top_0_3), 3.0, 0.001, "the top's point is on roof-nw-3")
	assert_almost_eq(ground.height_at(top_3_6), 6.0, 0.001, "and on roof-nw-6")
	# Between two path points that are not a ramp's ends, the ground is level.
	for i in path.size() - 1:
		var a := path[i]
		var b := path[i + 1]
		if [a, b] == [foot_0_3, top_0_3] or [a, b] == [foot_3_6, top_3_6]:
			continue
		assert_lt(absf(ground.height_at(a) - ground.height_at(b)), EnemyHeightScript.MAX_STEP + 0.001,
			"a level step from %s to %s" % [a, b])


func test_the_follower_walks_straight_on_the_cars_surface() -> void:
	var nav = spawner.navigation
	var f = FollowerScript.new()
	var car := Vector2(-70, -48)
	assert_eq(f.target(nav, Vector2(-100, -40), car, DT), car, "both on the street: straight at the car")
	assert_false(f.has_path())
	var t: Vector2 = f.target(nav, Vector2(-70, -80), car, DT)
	assert_true(f.has_path(), "on a rooftop with the car on the street: a path")
	assert_ne(t, car)
	assert_eq(f.paths_found, 1)
	for i in 10:
		f.target(nav, Vector2(-70, -80), car, DT)
	assert_eq(f.paths_found, 1, "no new path before REPATH_SECONDS")


func test_paths_are_spread_over_steps_when_many_need_one() -> void:
	_place_car(Vector2(-27, -81), PI / 2.0)
	var ms := []
	for i in 10:
		ms.append(_spawn(Vector2(-70 + i, -48)))
	spawner.move_step(DT)
	var with_path := ms.filter(func(m) -> bool: return m.follower.has_path())
	assert_eq(with_path.size(), EnemyNavigationScript.PATHS_PER_STEP, "at most PATHS_PER_STEP paths in one step")
	for _i in 3:
		spawner.move_step(DT)
	with_path = ms.filter(func(m) -> bool: return m.follower.has_path())
	assert_eq(with_path.size(), 10, "all of them a few steps later")


func test_a_minion_on_its_way_to_a_ramp_is_not_removed_off_screen() -> void:
	_place_car(Vector2(-27, -81), PI / 2.0)
	spawner.visible_rect_override = Rect2(ISO * (Vector2(-27, -81) * 16.0) - Vector2(200, 120), Vector2(400, 240))
	var climbing := _spawn(Vector2(-81, -45))  # far off screen, on its way to ramp-nw-0-3
	var idle := _spawn(Vector2(-81, -45))
	idle.follower = null  # no path: removed as before T-207
	spawner.move_step(DT)
	assert_true(climbing.follower.has_path())
	spawner._despawn_far()
	assert_true(spawner.minions.has(climbing), "kept: it is on its way by the ramps")
	assert_false(spawner.minions.has(idle), "removed: off screen with no path")
	var lost := _spawn(Vector2(100, 100))  # beyond ON_PATH_KEEP_UNITS from the car
	spawner.move_step(DT)
	assert_true(lost.follower.has_path())
	spawner._despawn_far()
	assert_false(spawner.minions.has(lost), "removed when farther than ON_PATH_KEEP_UNITS")


# --- AC 1: up the ramps to a car on a height-6 rooftop -------------------------------

func test_minions_on_the_street_reach_a_car_on_the_nw_height_6_rooftop_by_the_ramps() -> void:
	_place_car(Vector2(-27, -81), PI / 2.0)
	assert_almost_eq(run.car.height, 6.0, 0.001, "the car is parked on roof-nw-6")
	var starts := [Vector2(-70, -48), Vector2(-108, -108), Vector2(0, -81), Vector2(-40, -50)]
	var ms := []
	for p in starts:
		var m := _spawn(p)
		assert_almost_eq(m.ground_height(), 0.0, 0.001, "starts on the street")
		ms.append(m)
	var r := _chase(ms, CLIMB_LIMIT_SECONDS)
	gut.p("reached the height-6 car after %s s" % [r.seconds])
	for i in ms.size():
		assert_true(r.reached[i], "minion from %s reached the car within %.0f s" % [starts[i], CLIMB_LIMIT_SECONDS])
		assert_true(r.ramps[i].has("ramp-nw-0-3") and r.ramps[i].has("ramp-nw-3-6"),
			"minion from %s went up both ramps: %s" % [starts[i], r.ramps[i].keys()])
		assert_almost_eq(ms[i].ground_height(), 6.0, 0.001, "and stands on the car's rooftop")
	assert_lt(r.worst_step, EnemyHeightScript.MAX_STEP + 0.001,
		"never a jump in height in one step (no rooftop edge crossed): %.2f" % r.worst_step)


func test_minions_on_the_street_reach_a_car_on_the_se_height_6_rooftop_by_the_ramps() -> void:
	_place_car(Vector2(27, 81), 0.0)
	assert_almost_eq(run.car.height, 6.0, 0.001)
	var starts := [Vector2(70, 48), Vector2(108, 108), Vector2(0, 81), Vector2(40, 50)]
	var ms := []
	for p in starts:
		ms.append(_spawn(p))
	var r := _chase(ms, CLIMB_LIMIT_SECONDS)
	gut.p("reached the south-east height-6 car after %s s" % [r.seconds])
	for i in ms.size():
		assert_true(r.reached[i], "minion from %s reached the car within %.0f s" % [starts[i], CLIMB_LIMIT_SECONDS])
		assert_true(r.ramps[i].has("ramp-se-0-3") and r.ramps[i].has("ramp-se-3-6"),
			"by both ramps: %s" % [r.ramps[i].keys()])
	assert_lt(r.worst_step, EnemyHeightScript.MAX_STEP + 0.001)


# --- AC 2: down the ramps, and no edge crossed ------------------------------------

## T-207's way down, kept with the drop links left out (T-226: with them the
## minions drop off the edges; test_enemies_drop_off_ledges.gd).
func test_without_drops_minions_on_the_rooftops_come_down_by_a_ramp() -> void:
	spawner.navigation = EnemyNavigationScript.build_for_map(run.map, false)
	_place_car(Vector2(-70, -48), -PI / 2.0)
	assert_almost_eq(run.car.height, 0.0, 0.001)
	var starts := [Vector2(-27, -81), Vector2(-70, -80), Vector2(-90, -70), Vector2(-20, -70)]
	var ms := []
	for p in starts:
		ms.append(_spawn(p))
	var r := _chase(ms, CLIMB_LIMIT_SECONDS)
	gut.p("came down to the street car after %s s" % [r.seconds])
	for i in ms.size():
		assert_true(r.reached[i], "minion from %s reached the car" % starts[i])
		assert_true(r.ramps[i].has("ramp-nw-0-3"), "came down ramp-nw-0-3: %s" % [r.ramps[i].keys()])
		assert_almost_eq(ms[i].ground_height(), 0.0, 0.001, "now on the street")
	assert_true(r.ramps[0].has("ramp-nw-3-6"), "the one from height 6 came down ramp-nw-3-6 first")
	assert_lt(r.worst_step, EnemyHeightScript.MAX_STEP + 0.001, "never dropped off an edge")


## Points along every side of every rooftop, `inside` and `outside` it,
## leaving out the stretches where a ramp meets the side and points whose two
## sides are level (a rooftop's side on a higher rooftop).
func _edge_points(offset: float) -> Array:
	var out := []
	for p in ground.platforms:
		var rect: Rect2 = p.rect
		var sides := [
			[Vector2(1, 0), Vector2(0, -1), rect.position, rect.size.x],  # north
			[Vector2(1, 0), Vector2(0, 1), Vector2(rect.position.x, rect.end.y), rect.size.x],  # south
			[Vector2(0, 1), Vector2(-1, 0), rect.position, rect.size.y],  # west
			[Vector2(0, 1), Vector2(1, 0), Vector2(rect.end.x, rect.position.y), rect.size.y],  # east
		]
		for s in sides:
			var along: Vector2 = s[0]
			var outward: Vector2 = s[1]
			var d := 1.5
			while d < float(s[3]) - 1.0:
				var on_edge: Vector2 = s[2] + along * d
				var inside := on_edge - outward * offset
				var outside := on_edge + outward * offset
				d += 3.0
				if _near_ramp(inside) or _near_ramp(outside):
					continue
				if ground.height_at(inside) - ground.height_at(outside) <= EnemyHeightScript.MAX_STEP:
					continue
				if not run.map.rect_of(run.map.layout.map.rect).grow(-1.0).has_point(outside):
					continue
				out.append({"platform": p.id, "inside": inside, "outside": outside, "outward": outward})
	return out


func _near_ramp(units: Vector2) -> bool:
	for r in ground.ramps:
		if (r.rect as Rect2).grow(3.0).has_point(units):
			return true
	return false


func test_no_minion_climbs_any_rooftop_edge_from_below() -> void:
	var pts := _edge_points(1.5)
	assert_gt(pts.size(), 100, "points along every rooftop edge")
	var ms := []
	for p in pts:
		ms.append(_spawn(p.outside))
	var start_h := []
	for m in ms:
		start_h.append(m.ground_height())
	var crossed := []
	for _i in int(2.0 / DT):
		for k in ms.size():
			# Each walks straight at the rooftop, into its edge.
			ms[k].walk(DT, pts[k].inside - pts[k].outward * 10.0)
			if ms[k].ground_height() > start_h[k] + 0.001 and not crossed.has(k):
				crossed.append(k)
	var where := []
	for k in crossed:
		where.append("%s at %s" % [pts[k].platform, pts[k].outside])
	assert_eq(crossed.size(), 0, "no minion got onto a rooftop over its edge: %s" % [where])
	var inside := 0
	for k in ms.size():
		for p in ground.platforms:
			if p.id == pts[k].platform and (p.rect as Rect2).has_point(ms[k].position_units()):
				inside += 1
	assert_eq(inside, 0, "every one stopped at the edge (or slid along it), none is on the rooftop")


func test_no_minion_steps_off_any_rooftop_edge_from_above() -> void:
	var pts := _edge_points(1.5)
	var ms := []
	for p in pts:
		ms.append(_spawn(p.inside))
	var start_h := []
	for m in ms:
		start_h.append(m.ground_height())
	var dropped := []
	for _i in int(2.0 / DT):
		for k in ms.size():
			ms[k].walk(DT, pts[k].outside + pts[k].outward * 10.0)
			if ms[k].ground_height() < start_h[k] - 0.001 and not dropped.has(k):
				dropped.append(k)
	assert_eq(dropped.size(), 0, "no minion left a rooftop except by a ramp")


func test_a_knockback_does_not_push_a_minion_over_an_edge() -> void:
	# On the street just south of roof-nw-3's south edge (y -66), pushed north at it.
	var m := _spawn(Vector2(-60, -64.0))
	m.apply_knockback(Vector2.UP, 8.0)
	for _i in 20:
		m.walk(DT, m.position_units())
	assert_almost_eq(m.ground_height(), 0.0, 0.001, "still on the street")
	# On roof-nw-3, pushed south off it.
	var up := _spawn(Vector2(-60, -68.0))
	up.apply_knockback(Vector2.DOWN, 8.0)
	for _i in 20:
		up.walk(DT, up.position_units())
	assert_almost_eq(up.ground_height(), 3.0, 0.001, "still on the rooftop")


func test_minions_spawn_on_the_street() -> void:
	_place_car(Vector2(-27, -81), PI / 2.0)
	spawner.enabled = true
	var at := []
	spawner.minion_spawned.connect(func(m) -> void: at.append(m.position_units()))
	for _i in int(8.0 / DT):
		spawner.step(DT)
		run.state.health = run.state.max_health
	assert_gt(at.size(), 5)
	for p in at:
		assert_true(run.elevation.is_street(p, MinionScript.RADIUS_UNITS), "spawned on the street: %s" % p)


# --- AC 3: drawn at their height, damage at the car's level --------------------------

func _area(id: String):
	for a in run.elevation.areas:
		if str(a.block.id) == id:
			return a
	return null


func test_minions_are_drawn_lifted_by_their_height() -> void:
	for p in [Vector2(-70, -80), Vector2(-27, -81), Vector2(-81, -60), Vector2(-81, -40)]:
		var m := _spawn(p)
		var h: float = ground.height_at(p)
		spawner.update_drawing()
		assert_almost_eq(m.sprite.position, ISO * (p * 16.0) + Vector2(0, -h * 16.0), Vector2(0.01, 0.01),
			"at %s drawn %.2f units up" % [p, h])


func test_a_minion_on_a_rooftop_is_drawn_over_it_and_one_behind_it_under_it() -> void:
	var roof = _area("roof-nw-3")
	var on_roof := _spawn(Vector2(-70, -80))
	var behind := _spawn(Vector2(-70, -98))  # the street north of it, hidden behind it
	spawner.update_drawing()
	assert_gt(on_roof.sprite.z_index, roof.z_index, "on the roof: over the roof's drawing")
	assert_lt(behind.sprite.z_index, roof.z_index, "behind it on the street: under it")
	# On roof-nw-3 just west of roof-nw-6: under the higher rooftop's drawing.
	var high = _area("roof-nw-6")
	var west_of_high := _spawn(Vector2(-44, -92))
	spawner.update_drawing()
	assert_lt(west_of_high.sprite.z_index, high.z_index, "under roof-nw-6, which stands higher in front")
	assert_gt(west_of_high.sprite.z_index, roof.z_index, "over the roof it stands on")
	# On the ramp: over the ramp it stands on.
	var ramp = _area("ramp-nw-0-3")
	var on_ramp := _spawn(Vector2(-81, -60))
	spawner.update_drawing()
	assert_gt(on_ramp.sprite.z_index, ramp.z_index, "on the ramp: over the ramp")


func test_the_car_and_a_minion_on_the_same_rooftop_share_its_depth() -> void:
	_place_car(Vector2(-70, -80), 0.0)
	var m := _spawn(Vector2(-68, -80))
	spawner.update_drawing()
	var roof = _area("roof-nw-3")
	assert_gt(run.view_root.z_index, roof.z_index, "the car over its roof")
	assert_gt(m.sprite.z_index, roof.z_index, "the minion over the same roof")


func test_contact_damage_only_hits_the_car_at_its_level() -> void:
	# A minion on the street right under roof-nw-3's south edge (y -66).
	var m := _spawn(Vector2(-60, -65.45))
	assert_almost_eq(m.ground_height(), 0.0, 0.001)
	# The car on the rooftop just over the edge: close enough to touch, 3 units up.
	_place_car(Vector2(-60, -66.3), 0.0)
	assert_almost_eq(run.car.height, 3.0, 0.001)
	assert_true(_touching_car(m), "they touch on the flat map")
	var health: float = run.state.health
	assert_false(m.contact_step(DT, run.car, run.state), "no hit from below the rooftop")
	assert_eq(run.state.health, health, "no damage")
	# The car on the street there: hit.
	_place_car(Vector2(-60, -65.5), 0.0)
	assert_almost_eq(run.car.height, 0.0, 0.001)
	assert_true(m.contact_step(DT, run.car, run.state), "at its level: hit")
	assert_lt(run.state.health, health)
	# The car high in the air over it: no hit.
	m.contact_cooldown = 0.0
	run.car.height_model.height = 2.5
	run.car.height_model.airborne = true
	assert_false(m.contact_step(DT, run.car, run.state), "the car jumps over it")
	# A minion on the rooftop and the car on the street under its edge: no hit.
	var up := _spawn(Vector2(-60, -66.45))
	assert_almost_eq(up.ground_height(), 3.0, 0.001)
	run.car.height_model.height = 0.0
	run.car.height_model.airborne = false
	assert_true(_touching_car(up))
	assert_false(up.contact_step(DT, run.car, run.state), "no hit from above")


# --- The kaiju (a proposal: the minions' rules) -------------------------------------

func _kaiju_at(units: Vector2) -> Node:
	run.kaiju_boss.enabled = true
	return run.kaiju_boss.appear_at(units)


func test_the_kaiju_climbs_the_ramp_to_a_car_on_a_height_3_rooftop() -> void:
	_place_car(Vector2(-81, -80), 0.0)
	assert_almost_eq(run.car.height, 3.0, 0.001)
	var k := _kaiju_at(Vector2(-70, -46))
	assert_eq(k.ground, ground)
	var ramp_seen := false
	var worst := 0.0
	var prev: float = k.ground_height()
	var t := 0.0
	var reached := false
	while t < 60.0:
		run.kaiju_boss.step(DT)
		run.state.health = run.state.max_health
		t += DT
		var h: float = k.ground_height()
		worst = maxf(worst, absf(h - prev))
		prev = h
		if ground.is_ramp(k.position_units()):
			ramp_seen = true
		if k.touches_car(run.car.position / 16.0, run.car.rotation):
			reached = true
			break
	gut.p("the kaiju reached the height-3 car after %.1f s" % t)
	assert_true(reached, "the kaiju reached the car on the rooftop within 60 s")
	assert_true(ramp_seen, "by the ramp")
	assert_almost_eq(k.ground_height(), 3.0, 0.001)
	assert_lt(worst, EnemyHeightScript.MAX_STEP + 0.001)
	assert_almost_eq(k.sprite.position, ISO * k.position + Vector2(0, -3.0 * 16.0), Vector2(0.01, 0.01),
		"drawn on the rooftop")


func test_the_kaiju_is_stopped_by_a_rooftop_edge_and_hits_only_at_its_level() -> void:
	# On the street south of roof-nw-3, walking north into its edge (y -66).
	var k := _kaiju_at(Vector2(-60, -60))
	for _i in int(3.0 / DT):
		k.walk(DT, Vector2(-60, -90))
	assert_almost_eq(k.ground_height(), 0.0, 0.001, "still on the street")
	assert_gt(k.position_units().y, -66.0 + KaijuScript.RADIUS_UNITS - 0.01, "its whole body off the edge")
	_place_car(Vector2(-60, -66.3), 0.0)
	k.set_position_units(Vector2(-60, -64.0))
	assert_true(k.touches_car(run.car.position / 16.0, run.car.rotation))
	assert_false(k.contact_step(DT, run.car, run.state), "the car on the rooftop is not hit from the street")
	assert_true(run.kaiju_boss.is_free_spot(Vector2(-60, -48)), "the street is an arrival spot")
	assert_false(run.kaiju_boss.is_free_spot(Vector2(-70, -80)), "a rooftop is not")
