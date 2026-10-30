extends GutTest
## Task T-419 (Enemies, Decisions, "The kaiju only takes paths it fits
## through"): the navigation plans for each enemy's own body radius
## (enemy_navigation.gd, for_map(map, radius)). The kaiju's paths keep its
## 2-unit radius off every building, a gap narrower than its 4-unit body is
## never on its path while the minions still use it, and in a scripted run it
## walks round two buildings to the car without stalling.
##
## The board's level (data/levels/kaiju_city.json) is an untracked, read-only
## copy: the tests that use it skip with a message when it is missing.

const RunScene := preload("res://scenes/run/run.tscn")
const NavScript := preload("res://scripts/enemies/enemy_navigation.gd")
const KaijuScript := preload("res://scripts/enemies/kaiju.gd")
const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const LEVEL := "res://data/levels/kaiju_city.json"
const DT := 0.02
const PAIRS := 50
## Tolerance (units) for "at least its radius": float noise only.
const EPS := 0.001
## The scripted runs: a stop is staying within this many units of one spot.
const STOP_RADIUS := 1.0
## A spot on roof-1 (height 3) of Kaiju City, the car's for the board's review.
const ROOF_CAR := Vector2(-32, 36)
## The scripted runs' longest path, units: 26 s at the kaiju's 3 units a second.
const MAX_PATH := 78.0

var run: Node2D


func after_each() -> void:
	get_tree().paused = false


## A run on the board's level, or null (and the test is skipped) without it.
func _board_run() -> Node2D:
	if not FileAccess.file_exists(LEVEL):
		pass_test("skipped: %s is missing (the board's level is an untracked copy)" % LEVEL)
		return null
	run = RunScene.instantiate()
	run.layout_path = LEVEL
	add_child_autofree(run)
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	run.car.set_physics_process(false)
	run.minions.enabled = false
	run.minions.clear()
	run.kaiju_boss.enabled = false
	return run


## Every rectangle that blocks the enemies on `map`: the buildings that stay
## walls (short_platforms.gd) and the props' rectangles.
func _block_rects(map: Node) -> Array:
	var out: Array = []
	for w in load("res://scripts/level/short_platforms.gd").wall_rects(map.layout):
		out.append(w.rect)
	out.append_array(LevelProps.obstacles(map.layout).rects)
	return out


func _dist_to_rect(p: Vector2, r: Rect2) -> float:
	var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	return p.distance_to(q)


## The round obstacles of `map`: its boulders and the round props, [centre, radius].
func _block_circles(map: Node) -> Array:
	var out: Array = []
	for b in map.all_boulders():
		out.append([Vector2(float(b.x), float(b.y)), float(b.diameter) / 2.0])
	out.append_array(LevelProps.obstacles(map.layout).circles)
	return out


func _nearest_block(p: Vector2, rects: Array, circles: Array = []) -> float:
	var best := INF
	for r in rects:
		best = minf(best, _dist_to_rect(p, r))
	for c in circles:
		best = minf(best, p.distance_to(c[0]) - float(c[1]))
	return best


func _place_car(units: Vector2) -> void:
	var car = run.car
	car.model.set_position(units)
	car.model.rotation = 0.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	run.sync_view()


# --- Each enemy plans for its own size -------------------------------------------------

func test_the_kaiju_and_the_minions_each_have_a_navigation_for_their_size() -> void:
	if _board_run() == null:
		return
	var minion_nav = run.minions.navigation
	var kaiju_nav = run.kaiju_boss.navigation
	assert_not_null(minion_nav)
	assert_not_null(kaiju_nav)
	assert_ne(kaiju_nav, minion_nav, "the kaiju has its own")
	assert_almost_eq(kaiju_nav.building_margin, KaijuScript.RADIUS_UNITS, EPS, "planned for the kaiju's radius")
	var m: Node = run.minions.spawn_minion_at(Vector2(1, 9))
	assert_almost_eq(minion_nav.building_margin, m.radius_units(), EPS, "planned for the minion's radius")
	assert_almost_eq(NavScript.minion_radius(), m.radius_units(), EPS)
	assert_eq(NavScript.for_map(run.map, KaijuScript.RADIUS_UNITS, true), kaiju_nav, "kept on the map")
	assert_almost_eq(kaiju_nav.edge_radius, KaijuScript.RADIUS_UNITS, EPS, "kept off the edges by its radius")
	assert_eq(minion_nav.edge_radius, 0.0, "the minions' grid as before")
	assert_eq(kaiju_nav.drop_span, 3, "its drops span the cells it hangs over the edge in")
	assert_gt(kaiju_nav.drop_links, 0, "it still drops off rooftops")
	assert_eq(NavScript.for_map(run.map), minion_nav, "the default is the minions'")
	gut.p("builds: minions %.1f ms, kaiju %.1f ms" % [minion_nav.build_usec / 1000.0, kaiju_nav.build_usec / 1000.0])


# --- Criterion 1: every waypoint at least its radius from every building ----------------

func test_kaiju_waypoints_keep_its_radius_off_every_building_on_the_board_level() -> void:
	if _board_run() == null:
		return
	var nav = run.kaiju_boss.navigation
	var ground = run.elevation.ground_height
	var rects := _block_rects(run.map)
	var circles := _block_circles(run.map)
	var r: float = KaijuScript.RADIUS_UNITS
	var unfit := 0
	var street: Array = []
	var anywhere: Array = []
	for k in nav.open.size():
		if nav.open[k] == 1:
			anywhere.append(k)
			if nav.surface_at(nav.cell_centre(k)) == -1:
				street.append(k)
	var rng := RandomNumberGenerator.new()
	rng.seed = 419
	var paths := 0
	var points := 0
	var worst := INF
	var rooftop_targets := 0
	var tries := 0
	var bad: Array = []
	while paths < PAIRS and tries < PAIRS * 20:
		tries += 1
		# Jittered inside the cell, as an enemy and the car stand anywhere.
		var jitter := Vector2(rng.randf_range(-0.9, 0.9), rng.randf_range(-0.9, 0.9))
		var a: Vector2 = nav.cell_centre(street[rng.randi() % street.size()]) + jitter
		var b: Vector2 = nav.cell_centre(anywhere[rng.randi() % anywhere.size()])
		if a.distance_to(b) < 20.0:
			continue
		var path: PackedVector2Array = nav.find_path(a, b)
		if path.is_empty():
			continue
		paths += 1
		if ground.height_at(b) > 0.5:
			rooftop_targets += 1
		for p in path:
			points += 1
			var d := _nearest_block(p, rects, circles)
			worst = minf(worst, d)
			if d < r - EPS:
				bad.append([p, d])
			if not EnemyHeightScript.fits(ground, p, r):
				unfit += 1
	gut.p("%d paths (%d to rooftops), %d waypoints, nearest to a building %.2f units" % [paths, rooftop_targets, points, worst])
	gut.p("waypoints where its body hangs over a rooftop's or ramp's edge: %d" % unfit)
	assert_eq(unfit, 0, "no waypoint where its body hangs over a rooftop's or ramp's edge")
	assert_eq(paths, PAIRS, "50 start/target pairs with a path")
	assert_gt(rooftop_targets, 0, "some targets on rooftops")
	assert_eq(bad.size(), 0, "waypoints nearer than the kaiju's radius: %s" % str(bad.slice(0, 5)))


# --- Criterion 2: a gap narrower than the kaiju is never on its path ----------------------

## Two navigations (the minion's and the kaiju's) over a flat 80 x 80 map with
## a wall across it at y 0..4 from x -40 to 30, a gap of `gap` units in it at
## x 0..gap, and the way round at its east end (x 30..40).
func _gap_navs(gap: float) -> Array:
	var ground = GroundHeightScript.new()
	var blocks: Array = [Rect2(-40, 0, 40, 4), Rect2(gap, 0, 30.0 - gap, 4)]
	var out: Array = []
	for radius in [NavScript.minion_radius(), KaijuScript.RADIUS_UNITS]:
		var nav = NavScript.new()
		nav.building_margin = radius
		nav.build(Rect2(-40, -40, 80, 80), blocks, ground)
		out.append(nav)
	return out


func _crosses_gap(path: PackedVector2Array, gap: float) -> bool:
	for p in path:
		if p.y > -1.0 and p.y < 5.0 and p.x > -2.0 and p.x < gap + 2.0:
			return true
	return false


func test_a_gap_narrower_than_the_kaiju_is_never_on_its_path_but_minions_use_it() -> void:
	var from := Vector2(1.5, -20)
	var to := Vector2(1.5, 24)
	for gap in [3.0, 3.5]:
		var navs := _gap_navs(gap)
		var minion_path: PackedVector2Array = navs[0].find_path(from, to)
		var kaiju_path: PackedVector2Array = navs[1].find_path(from, to)
		assert_gt(minion_path.size(), 0)
		assert_gt(kaiju_path.size(), 0, "the kaiju has a way round")
		assert_true(_crosses_gap(minion_path, gap), "a minion goes through the %.1f-unit gap" % gap)
		assert_false(_crosses_gap(kaiju_path, gap), "the kaiju does not take the %.1f-unit gap" % gap)
		var east_end := false
		for p in kaiju_path:
			if p.x > 30.0 and p.y > -1.0 and p.y < 5.0:
				east_end = true
		assert_true(east_end, "it goes round the wall's end")


func test_a_gap_wider_than_the_kaiju_is_still_used() -> void:
	var navs := _gap_navs(6.0)
	var path: PackedVector2Array = navs[1].find_path(Vector2(3, -20), Vector2(3, 24))
	assert_true(_crosses_gap(path, 6.0), "a 6-unit gap fits its 4-unit body")
	for p in path:
		if p.y > -1.0 and p.y < 5.0:
			assert_almost_eq(p.x, 3.0, EPS, "through the gap's middle")


# --- Criterion 3: a scripted run round two buildings ------------------------------------

## The buildings on `run`'s map: those that stay walls and the short ones, whose
## rooftops are platforms (from the street their edges stop it like a wall).
func _building_rects() -> Array:
	var rects: Array = []
	for w in load("res://scripts/level/short_platforms.gd").wall_rects(run.map.layout):
		rects.append(w.rect)
	for pf in run.elevation.ground_height.platforms:
		rects.append(pf.rect)
	return rects


## How many of `rects` the straight line from `a` to `b` passes over, not
## counting the one `b` stands in (a car on a rooftop).
func _buildings_between(a: Vector2, b: Vector2, rects: Array) -> int:
	var crossed := {}
	for s in 201:
		var p := a.lerp(b, s / 200.0)
		for i in rects.size():
			var r: Rect2 = rects[i]
			if r.has_point(p) and not r.has_point(b):
				crossed[i] = true
	return crossed.size()


## A street spot for the kaiju and a rooftop spot for the car (the bug showed
## mostly with the car on a rooftop) on the board's level with two buildings
## on the straight line between them and the kaiju's path under MAX_PATH units
## (it walks 3 units a second, so 26 s). Searched on the kaiju's own
## navigation, seeded, so the test follows the level as it is. (Kaiju City
## has no street-to-street pair with two buildings between and a path that
## short: its buildings stand apart or against the map's edge.)
func _two_buildings_apart(nav) -> Array:
	var rects := _building_rects()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4190
	var street: Array = []
	var roofs: Array = []
	for k in nav.open.size():
		if nav.open[k] == 1 and nav.ramp_of[k] < 0:
			if nav.surface_at(nav.cell_centre(k)) == -1:
				street.append(k)
			elif nav.heights[k] > 0.5:
				roofs.append(k)
	var targets: Array = roofs
	for _i in 4000:
		var a: Vector2 = nav.cell_centre(street[rng.randi() % street.size()])
		var b: Vector2 = nav.cell_centre(targets[rng.randi() % targets.size()])
		var dist := a.distance_to(b)
		if dist < 20.0 or dist > 50.0 or _buildings_between(a, b, rects) < 2:
			continue
		var path: PackedVector2Array = nav.find_path(a, b)
		if path.is_empty():
			continue
		var length := 0.0
		for i in path.size() - 1:
			length += path[i].distance_to(path[i + 1])
		if length < MAX_PATH:
			return [a, b]
	return []


## Puts the car at `car_at` and the kaiju at `start` and steps the kaiju for up
## to `limit` seconds. Returns {reached, seconds, longest_stop: the longest
## time it stayed within STOP_RADIUS units of one spot (standing, or jammed
## and jittering against a wall), stop_at}.
func _chase(start: Vector2, car_at: Vector2, limit: float) -> Dictionary:
	_place_car(car_at)
	run.kaiju_boss.enabled = true
	run.kaiju_boss.clear()
	var k: Node = run.kaiju_boss.appear_at(start)
	assert_not_null(k)
	var t := 0.0
	var anchor: Vector2 = k.position_units()
	var anchor_t := 0.0
	var longest := 0.0
	var stop_at := anchor
	var reached := false
	while t < limit:
		run.kaiju_boss.step(DT)
		run.state.health = run.state.max_health
		t += DT
		if k.touches_car(run.car.position / 16.0, run.car.rotation):
			reached = true
			break
		var p: Vector2 = k.position_units()
		if p.distance_to(anchor) > STOP_RADIUS:
			anchor = p
			anchor_t = t
		elif t - anchor_t > longest:
			longest = t - anchor_t
			stop_at = anchor
	return {"reached": reached, "seconds": t, "longest_stop": longest, "stop_at": stop_at}


func test_the_kaiju_walks_round_two_buildings_to_a_car_on_a_rooftop_without_stalling() -> void:
	if _board_run() == null:
		return
	var spots := _two_buildings_apart(run.kaiju_boss.navigation)
	assert_eq(spots.size(), 2, "found a kaiju spot and a car spot with two buildings between them")
	if spots.size() < 2:
		return
	assert_gt(run.elevation.ground_height.height_at(spots[1]), 0.5, "the car is on a rooftop")
	var r := _chase(spots[0], spots[1], 30.0)
	gut.p("kaiju %s to car %s: reached %s after %.1f s, longest stop %.2f s at %s" % [
		spots[0], spots[1], r.reached, r.seconds, r.longest_stop, r.stop_at])
	assert_true(r.reached, "the kaiju reached the car within 30 s")
	assert_lt(r.longest_stop, 2.0, "it never stopped (stayed within %.1f units) for 2 s" % STOP_RADIUS)


## The board's review: the car on roof-1 (Kaiju City), the kaiju from ten
## street spots 30 to 60 units away; it reaches the car from each without
## stalling, within the time its path takes plus a margin.
func test_the_kaiju_reaches_a_car_on_a_rooftop_from_ten_street_spots() -> void:
	if _board_run() == null:
		return
	var nav = run.kaiju_boss.navigation
	var gh = run.elevation.ground_height
	if not gh.height_at(ROOF_CAR) > 0.5:
		pass_test("skipped: %s is not on a rooftop on this copy of the level" % ROOF_CAR)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var street: Array = []
	for k in nav.open.size():
		var c: Vector2 = nav.cell_centre(k)
		if nav.open[k] == 1 and nav.surface_at(c) == -1:
			var d := c.distance_to(ROOF_CAR)
			if d > 30.0 and d < 60.0:
				street.append(k)
	for _trial in 10:
		var start: Vector2 = nav.cell_centre(street[rng.randi() % street.size()])
		var path: PackedVector2Array = nav.find_path(start, ROOF_CAR)
		assert_gt(path.size(), 0, "a path from %s" % start)
		var length := 0.0
		for i in path.size() - 1:
			length += path[i].distance_to(path[i + 1])
		var limit := length / float(EnemyData.new().kaiju().move_speed) * 1.25 + 5.0
		var r := _chase(start, ROOF_CAR, limit)
		gut.p("from %s (path %.0f units): reached %s after %.1f s, longest stop %.2f s" % [
			start, length, r.reached, r.seconds, r.longest_stop])
		assert_true(r.reached, "reached the car from %s within %.0f s" % [start, limit])
		assert_lt(r.longest_stop, 2.0, "no stop of 2 s from %s (at %s)" % [start, r.stop_at])
