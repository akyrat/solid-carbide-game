extends GutTest
## Task T-226 (Enemies, Decisions, "Enemies jump down off ledges"): going down,
## enemies drop off a rooftop's edge to chase the car instead of walking round
## to a ramp. The navigation (enemy_navigation.gd) has one-way drop links off
## every rooftop edge, an enemy whose path drops walks out over the edge and
## falls (enemy_fall.gd) under the car's gravity, drawn at its height in the
## air in the depth order, with the falling animation. Going up still needs a
## ramp, an edge still blocks from below, and no enemy ends up in a building.
##
## The map (data/level/elevation_sample_map.json): roof-nw-6 is -42..-12,
## -96..-66 at height 6; south of it (y > -66) is the street. roof-nw-3 is
## -96..-12, -96..-66 at height 3, with roof-nw-6 on its east end.

const RunScene := preload("res://scenes/run/run.tscn")
const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")
const EnemyNavigationScript := preload("res://scripts/enemies/enemy_navigation.gd")
const EnemyFallScript := preload("res://scripts/enemies/enemy_fall.gd")
const MinionScript := preload("res://scripts/enemies/minion.gd")
const MinionSpriteScript := preload("res://scripts/enemies/minion_sprite.gd")
const KaijuSpriteScript := preload("res://scripts/enemies/kaiju_sprite.gd")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const DT := 0.02
const LIMIT_SECONDS := 40.0
## The car on the street just south of roof-nw-6's south edge (y -66).
const STREET_CAR := Vector2(-20, -60)
const ROOF_6_STARTS := [Vector2(-27, -81), Vector2(-20, -72), Vector2(-35, -90), Vector2(-15, -85)]

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
	spawner.rng.seed = 226
	run.kaiju_boss.enabled = false
	ground = run.elevation.ground_height


func after_each() -> void:
	get_tree().paused = false


func _place_car(units: Vector2, rot: float = 0.0) -> void:
	var car = run.car
	car.model.set_position(units)
	car.model.rotation = rot
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = ground
	run.sync_view()


func _touching_car(m: Node) -> bool:
	return m.touches_car(run.car.position / 16.0, run.car.rotation)


func _buildings() -> Array:
	var out := []
	for b in run.map.layout.buildings:
		out.append(run.map.rect_of(b))
	return out


## Steps the minions until each touches the car or the limit runs out.
## Returns {"reached", "seconds", "ramps" (ids walked on), "falls" (falls
## landed or still falling: one may reach the car as it lands on it),
## "in_building" (steps any minion's centre was in a building),
## "climbed" (steps a minion's ground rose by more than a step)}.
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
	var blocks := _buildings()
	var in_building := 0
	var climbed := 0
	var t := 0.0
	while t < limit:
		spawner.move_step(DT)
		spawner.update_drawing()
		run.state.health = run.state.max_health
		t += DT
		var all := true
		for i in ms.size():
			var m = ms[i]
			var p: Vector2 = m.position_units()
			for r in blocks:
				if (r as Rect2).has_point(p):
					in_building += 1
			var h: float = m.ground_height()
			if h - prev[i] > EnemyHeightScript.MAX_STEP:
				climbed += 1
			prev[i] = h
			var rp: Dictionary = ground.ramp_at(p)
			if not rp.is_empty():
				ramps[i][rp.id] = true
			if not reached[i] and _touching_car(m):
				reached[i] = true
				secs[i] = t
			all = all and reached[i]
		if all:
			break
	var falls := []
	for m in ms:
		falls.append(m.fall.landings + (1 if m.is_falling() else 0))
	return {"reached": reached, "seconds": secs, "ramps": ramps, "falls": falls,
		"in_building": in_building, "climbed": climbed}


func _spawn_all(starts: Array) -> Array:
	var ms := []
	for p in starts:
		ms.append(spawner.spawn_minion_at(p))
	return ms


func _max(a: Array) -> float:
	var out := -INF
	for v in a:
		out = maxf(out, float(v))
	return out


# --- The navigation ----------------------------------------------------------------

func test_every_rooftop_edge_has_one_way_drop_links_down() -> void:
	var nav = spawner.navigation
	assert_true(nav.drops_enabled)
	assert_gt(nav.drop_links, 100, "drop links along the rooftops' edges")
	# roof-nw-6's south edge: the cell on it links down to the street, not back up.
	var top: int = nav.cell_at(Vector2(-27, -67))
	var below: int = nav.cell_at(Vector2(-27, -65))
	assert_almost_eq(nav.heights[top], 6.0, 0.001)
	assert_almost_eq(nav.heights[below], 0.0, 0.001)
	assert_true(nav.astar.are_points_connected(top, below, false), "down off the edge")
	assert_false(nav.astar.are_points_connected(below, top, false), "never up it")
	var flat = EnemyNavigationScript.build_for_map(run.map, false)
	assert_eq(flat.drop_links, 0, "drops can be left out (the T-207 grid)")
	assert_false(flat.astar.are_points_connected(top, below, false))


func test_a_path_down_drops_off_the_nearest_edge_and_a_path_up_still_uses_the_ramps() -> void:
	var nav = spawner.navigation
	var down: PackedVector2Array = nav.find_path(Vector2(-27, -81), STREET_CAR)
	var drops := 0
	for i in down.size() - 1:
		if nav.is_drop(down[i], down[i + 1]):
			drops += 1
			assert_almost_eq(ground.height_at(down[i]), 6.0, 0.001, "drops from the height-6 roof")
			assert_almost_eq(ground.height_at(down[i + 1]), 0.0, 0.001, "to the street")
	assert_eq(drops, 1, "one drop, straight off roof-nw-6's edge")
	var flat = EnemyNavigationScript.build_for_map(run.map, false)
	var round: PackedVector2Array = flat.find_path(Vector2(-27, -81), STREET_CAR)
	assert_lt(down.size() * 3, round.size(), "much shorter than the way round by the ramps: %d points, not %d" 		% [down.size(), round.size()])
	var up: PackedVector2Array = nav.find_path(STREET_CAR, Vector2(-27, -81))
	assert_true(up.find(nav.ramp_end(0, false)) >= 0 and up.find(nav.ramp_end(1, true)) >= 0,
		"going up still by ramp-nw-0-3 and ramp-nw-3-6")
	for i in up.size() - 1:
		assert_false(nav.is_drop(up[i], up[i + 1]), "no drop on the way up")
		if up[i].distance_to(up[i + 1]) <= EnemyNavigationScript.CELL * 1.5:
			assert_lt(ground.height_at(up[i + 1]) - ground.height_at(up[i]), EnemyHeightScript.MAX_STEP + 0.001,
				"no climb between two neighbouring cells (only along a ramp, between its two ends)")


# --- AC 1: they drop off the edge and reach the car sooner ----------------------------

func test_minions_on_a_height_6_rooftop_drop_off_the_edge_to_a_car_below_sooner_than_by_the_ramps() -> void:
	_place_car(STREET_CAR, 0.0)
	assert_almost_eq(run.car.height, 0.0, 0.001, "the car is on the street")
	# Before T-226: the same minions with the drop links left out (T-207's grid).
	var with_drops = spawner.navigation
	spawner.navigation = EnemyNavigationScript.build_for_map(run.map, false)
	var before := _chase(_spawn_all(ROOF_6_STARTS), LIMIT_SECONDS)
	spawner.clear()
	spawner.navigation = with_drops
	var ms := _spawn_all(ROOF_6_STARTS)
	for m in ms:
		assert_almost_eq(m.ground_height(), 6.0, 0.001, "starts on roof-nw-6")
	var after := _chase(ms, LIMIT_SECONDS)
	gut.p("T-226 AC 1, height-6 roof to the street car: before (by the ramps) %s s, after (dropping) %s s" \
		% [before.seconds, after.seconds])
	gut.p("falls %s" % [after.falls])
	for i in ms.size():
		assert_true(before.reached[i], "before: minion from %s reached the car by the ramps" % ROOF_6_STARTS[i])
		assert_true(after.reached[i], "after: minion from %s reached the car" % ROOF_6_STARTS[i])
		assert_lt(after.seconds[i], before.seconds[i], "sooner by dropping: %.2f s < %.2f s" \
			% [after.seconds[i], before.seconds[i]])
		assert_eq(after.ramps[i].size(), 0, "did not walk to a ramp: %s" % [after.ramps[i].keys()])
		assert_gt(after.falls[i], 0, "dropped off the edge")
		assert_true(before.ramps[i].has("ramp-nw-3-6"), "before, it went by the ramps")
		assert_almost_eq(ms[i].ground_height(), 0.0, 0.001, "now on the street")
	assert_lt(_max(after.seconds), _max(before.seconds), "the slowest is sooner too")
	assert_eq(after.in_building, 0, "never inside a building")
	assert_eq(after.climbed, 0, "never climbed an edge")


# --- AC 2: no climbing, ramps up, never in a building --------------------------------

func test_a_minion_allowed_to_drop_still_cannot_climb_an_edge_from_below() -> void:
	# On the street south of roof-nw-3 (edge y -66), walking north into it with may_drop on.
	var m = spawner.spawn_minion_at(Vector2(-60, -63))
	for _i in int(3.0 / DT):
		m.may_drop = true
		m.walk(DT, Vector2(-60, -90))
	assert_almost_eq(m.ground_height(), 0.0, 0.001, "still on the street")
	assert_false(m.is_falling())
	assert_gt(m.position_units().y, -66.0, "stopped at the edge")


func test_without_a_drop_on_its_path_a_minion_does_not_step_off() -> void:
	var m = spawner.spawn_minion_at(Vector2(-27, -69))
	for _i in int(2.0 / DT):
		m.walk(DT, Vector2(-27, -50))  # may_drop stays false
	assert_almost_eq(m.ground_height(), 6.0, 0.001, "still on the roof")
	assert_eq(m.fall.landings, 0)


func test_minions_on_the_street_still_go_up_by_the_ramps() -> void:
	_place_car(Vector2(-27, -81), PI / 2.0)
	assert_almost_eq(run.car.height, 6.0, 0.001)
	var ms := _spawn_all([Vector2(-70, -48), Vector2(-40, -50)])
	var r := _chase(ms, LIMIT_SECONDS)
	gut.p("up to the height-6 car (drops on): %s s" % [r.seconds])
	for i in ms.size():
		assert_true(r.reached[i])
		assert_true(r.ramps[i].has("ramp-nw-0-3") and r.ramps[i].has("ramp-nw-3-6"), "by both ramps")
		assert_eq(r.falls[i], 0, "no fall on the way up")
	assert_eq(r.climbed, 0, "no edge climbed")
	assert_eq(r.in_building, 0)


func test_minions_dropping_from_every_rooftop_never_end_up_in_a_building() -> void:
	# From points on every rooftop to cars on the street round them, including
	# beside the buildings (-96..-66, -42..-12 is a building south of roof-nw-3).
	var cases := [
		[Vector2(-81, -60), [Vector2(-90, -80), Vector2(-70, -70), Vector2(-60, -90)]],
		[Vector2(-60, -30), [Vector2(-60, -70), Vector2(-50, -90), Vector2(-27, -70)]],
		[Vector2(81, 60), [Vector2(90, 80), Vector2(70, 70), Vector2(27, 81)]],
		[Vector2(5, -81), [Vector2(-15, -81), Vector2(-15, -70), Vector2(-15, -92)]],
	]
	var total_falls := 0
	for c in cases:
		spawner.clear()
		_place_car(c[0], 0.0)
		var ms := _spawn_all(c[1])
		var r := _chase(ms, LIMIT_SECONDS)
		gut.p("car at %s: %s s, falls %s" % [c[0], r.seconds, r.falls])
		assert_eq(r.in_building, 0, "never in a building (car at %s)" % c[0])
		assert_eq(r.climbed, 0, "never climbed an edge (car at %s)" % c[0])
		for i in ms.size():
			assert_true(r.reached[i], "from %s reached the car at %s" % [c[1][i], c[0]])
			total_falls += int(r.falls[i])
	assert_gt(total_falls, 5, "they dropped off the edges where no ramp was nearer")


# --- AC 3: height, depth order and the falling animation follow the fall --------------

func test_a_falling_minion_is_drawn_at_its_height_in_the_air_with_the_falling_animation() -> void:
	_place_car(STREET_CAR, 0.0)
	var m = spawner.spawn_minion_at(Vector2(-20, -72))
	var s = m.sprite
	var heights := []
	var anims := {}
	var bad_draw := 0
	var bad_anim := 0
	var bad_depth := 0
	var landed_at := -1
	var after_land := []
	for step in int(6.0 / DT):
		spawner.move_step(DT)
		spawner.update_drawing()
		s.advance(DT)
		run.state.health = run.state.max_health
		var h: float = m.body_height()
		if m.is_falling():
			heights.append(h)
		var want: Vector2 = ISO * m.position + Vector2(0.0, -h * 16.0)
		if s.position.distance_to(want) > 0.01:
			bad_draw += 1
		if s.z_index != spawner.depth.z_index_for(m.position_units(), MinionScript.RADIUS_UNITS, MinionScript.HEIGHT_UNITS, h):
			bad_depth += 1
		var a: String = s.animation()
		anims[a] = true
		if (a == "fall") != m.is_falling():
			bad_anim += 1
		if landed_at < 0 and m.fall.landings > 0:
			landed_at = step
		if landed_at >= 0 and after_land.size() < 3:
			after_land.append(a)
		if _touching_car(m) and landed_at >= 0 and step > landed_at + 20:
			break
	gut.p("fall heights: %d steps from %.2f to %.2f" % [heights.size(), heights.front(), heights.back()])
	assert_gt(heights.size(), 20, "a fall of 6 units takes a while (about 1 s)")
	assert_gt(heights.front(), 5.5, "starts at the roof's height")
	assert_lt(heights.back(), 1.0, "ends near the street")
	for i in heights.size() - 1:
		assert_true(heights[i + 1] <= heights[i] + 0.0001, "only ever down")
	assert_eq(bad_draw, 0, "drawn lifted by its height in the air at every step")
	assert_eq(bad_depth, 0, "in the depth order at its height in the air at every step")
	assert_eq(bad_anim, 0, "the falling animation plays exactly while it falls")
	assert_true(anims.has("fall") and anims.has("walk") and anims.has("land"), "walk, fall, land: %s" % [anims.keys()])
	assert_eq(after_land[0], "land", "the landing squash right after landing")
	assert_almost_eq(m.ground_height(), 0.0, 0.001)


func test_the_falling_animation_plays_only_while_falling() -> void:
	var s = MinionSpriteScript.new()
	add_child_autofree(s)
	assert_eq(s.animation(), "walk")
	assert_eq(s.anim_transform(Vector2(0, -5)), Transform2D.IDENTITY, "walking: drawn as before")
	s.set_falling(true)
	s.advance(0.05)
	assert_eq(s.animation(), "fall")
	assert_ne(s.anim_transform(Vector2(0, -5)), Transform2D.IDENTITY, "falling: tilted and stretched")
	s.set_falling(false)
	assert_eq(s.animation(), "land", "landing squash")
	s.advance(MinionSpriteScript.LAND_SECONDS + 0.01)
	assert_eq(s.animation(), "walk", "then walking again")
	assert_eq(s.anim_transform(Vector2(0, -5)), Transform2D.IDENTITY)
	assert_null(MinionSpriteScript.fall_sheet("e"), "no falling art yet (T-227): the placeholder")
	var k = KaijuSpriteScript.new()
	add_child_autofree(k)
	assert_eq(k.animation(), "walk")
	k.set_falling(true)
	k.advance(0.1)
	assert_eq(k.animation(), "fall")
	k.set_falling(false)
	assert_eq(k.animation(), "land")
	k.advance(KaijuSpriteScript.LAND_SECONDS + 0.01)
	assert_eq(k.animation(), "walk")


func test_the_fall_uses_the_cars_gravity() -> void:
	var f = EnemyFallScript.new()
	f.start(6.0)
	var t := 0.0
	while not f.step(DT, 0.0):
		t += DT
	assert_almost_eq(t, 1.0, 0.05, "6 units at the car's 12 units/s^2: about 1 s")
	assert_false(f.falling)
	assert_eq(f.landings, 1)


func test_a_falling_minion_hits_the_car_only_at_its_height_in_the_air() -> void:
	_place_car(STREET_CAR, 0.0)
	var m = spawner.spawn_minion_at(STREET_CAR + Vector2(0.9, 0))
	assert_true(_touching_car(m))
	m.fall.start(5.0)
	assert_false(m.contact_step(DT, run.car, run.state), "5 units over the car: no hit")
	m.fall.height = 0.5
	assert_true(m.contact_step(DT, run.car, run.state), "landing on it: a hit")


func test_a_knockback_never_takes_a_minion_over_an_edge() -> void:
	var m = spawner.spawn_minion_at(Vector2(-27, -68))
	m.may_drop = true  # even on its way to a drop: the push is not a drop
	m.apply_knockback(Vector2.DOWN, 8.0)
	for _i in 20:
		m.walk(DT, m.position_units())
	assert_almost_eq(m.ground_height(), 6.0, 0.001, "still on the roof")


# --- The kaiju (a proposal: it drops too) ------------------------------------------

func test_the_kaiju_drops_off_a_rooftop_edge_to_the_car_below() -> void:
	_place_car(STREET_CAR, 0.0)
	run.kaiju_boss.enabled = true
	var k = run.kaiju_boss.appear_at(Vector2(-27, -80))
	assert_almost_eq(k.ground_height(), 6.0, 0.001, "on roof-nw-6")
	var t := 0.0
	var reached := false
	var ramp := false
	var bad_anim := 0
	while t < 40.0:
		run.kaiju_boss.step(DT)
		run.state.health = run.state.max_health
		t += DT
		if ground.is_ramp(k.position_units()):
			ramp = true
		if (k.sprite.animation() == "fall") != k.is_falling():
			bad_anim += 1
		if k.touches_car(run.car.position / 16.0, run.car.rotation) and not k.is_falling():
			reached = true
			break
	gut.p("the kaiju reached the street car from roof-nw-6 in %.1f s" % t)
	assert_true(reached, "the kaiju reached the car below")
	assert_false(ramp, "without a ramp")
	assert_gt(k.fall.landings, 0, "by dropping")
	assert_eq(bad_anim, 0, "its falling animation only while it falls")
	assert_almost_eq(k.ground_height(), 0.0, 0.001)
