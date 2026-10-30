extends GutTest
## Task T-380 (Enemies, Decisions, "Minions don't get stuck on ramps"): minions
## chasing the car find their way round a ramp's sides, the pocket where a
## ramp's side meets its rooftop, and a building's corner, at the bigger size
## of T-379 (minion.size_scale 2), instead of standing against a wall.
##
## The cause: a minion on the car's surface walked straight at the car
## (enemy_path_follower.gd before T-380). On the street that took it head-on
## into a ramp's high side or a building; at a ramp's foot it went back and
## forth between the street (straight at the car, onto the ramp) and the ramp
## (another surface: a path back to the foot's point). The fix: minions walk
## straight only while the line to the car is clear on the navigation's grid
## (enemy_navigation.gd, line_clear), otherwise by a path, and take a path's
## points at SIGHT_REACH (0.5 units) so a bigger body does not cut a corner.
##
## Ramp ramp-nw-0-3: x -86..-76, y -66..-54, climbing north from the street
## (its foot at y -54) onto roof-nw-3 (y -96..-66, height 3).

const RunScene := preload("res://scenes/run/run.tscn")
const EnemyNavigationScript := preload("res://scripts/enemies/enemy_navigation.gd")
const FollowerScript := preload("res://scripts/enemies/enemy_path_follower.gd")
const DT := 0.02
## A minion that moved less than this (units) over STUCK_SECONDS, away from the car, is stuck.
const STUCK_MOVE := 1.0
const STUCK_SECONDS := 2.0
## Near the car a crowd stands still on purpose (it is at the car).
const AT_CAR := 4.0

var run: Node2D
var spawner: Node
var ground
var nav


func before_each() -> void:
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	run.car.set_physics_process(false)
	spawner = run.minions
	spawner.enabled = false
	spawner.clear()
	spawner.rng.seed = 380
	run.kaiju_boss.enabled = false
	ground = run.elevation.ground_height
	nav = spawner.navigation


func after_each() -> void:
	get_tree().paused = false


func _place_car(units: Vector2) -> void:
	var car = run.car
	car.model.set_position(units)
	car.model.rotation = 0.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = ground
	run.sync_view()


func _car_units() -> Vector2:
	return run.car.position / 16.0


## One minion at `start` with its detour side, chasing the parked car alone
## (no pushing apart) for `seconds`. Returns {"reached", "stuck_at" (null or
## where it stood still STUCK_SECONDS)}.
func _chase_one(start: Vector2, side: float, seconds: float, by_sight: bool) -> Dictionary:
	var m: Node = spawner.spawn_minion_at(start)
	m.detour_side = side
	m.follower.by_sight = by_sight
	var car := _car_units()
	var hist: Array = []
	var stuck_at = null
	var t := 0.0
	while t < seconds:
		nav.new_step()
		var target: Vector2 = m.follower.target(nav, m.position_units(), car, DT)
		m.may_drop = m.follower.dropping(nav, m.position_units(), m.body_height())
		m.walk(DT, target, Vector2.ZERO)
		t += DT
		if m.touches_car(car, run.car.rotation):
			return {"reached": true, "stuck_at": null}
		hist.append(m.position_units())
		var back := int(STUCK_SECONDS / DT)
		if stuck_at == null and hist.size() > back 				and (hist[-1] as Vector2).distance_to(hist[-1 - back]) < STUCK_MOVE:
			stuck_at = m.position_units()
	return {"reached": false, "stuck_at": stuck_at}


# --- The size this ticket is about ------------------------------------------------

func test_minions_are_the_bigger_size_of_t379() -> void:
	var m: Node = spawner.spawn_minion_at(Vector2(-100, -50))
	assert_eq(m.size_scale, 2.0, "tested with the bigger minions (enemies.json minion.size_scale)")
	assert_true(m.follower.by_sight, "the spawner's minions walk by sight")


# --- The stuck cases, before and after ---------------------------------------------

## The board's case: the car on the street east of ramp-nw-0-3, a minion on the
## street west of it. Before T-380 (the surface rule) it ended at the ramp's
## bottom end, going back and forth between the street and the ramp's foot.
func test_reproduced_stuck_at_the_bottom_end_of_a_ramp_before_the_fix() -> void:
	_place_car(Vector2(-66, -58))
	var r := _chase_one(Vector2(-92, -58), 1.0, 10.0, false)
	assert_false(r.reached, "the old rule never reaches the car")
	assert_not_null(r.stuck_at, "and stands still")
	if r.stuck_at != null:
		var p: Vector2 = r.stuck_at
		assert_almost_eq(p.y, -54.0, 1.0, "at the ramp's bottom end (y -54): %s" % p)
		assert_true(p.x > -86.0 and p.x < -76.0, "across the ramp's foot: %s" % p)


func test_no_longer_stuck_at_the_bottom_end_of_a_ramp() -> void:
	_place_car(Vector2(-66, -58))
	for side in [1.0, -1.0]:
		var r := _chase_one(Vector2(-92, -58), side, 10.0, true)
		assert_true(r.reached, "detour side %s: reached the car round the ramp's foot" % side)
		assert_null(r.stuck_at, "never stood still %.0f s" % STUCK_SECONDS)


## Before: a minion that detoured north along the ramp's west side stood in the
## pocket where the side meets roof-nw-3's south edge.
func test_reproduced_stuck_in_the_pocket_of_a_ramp_side_and_its_rooftop_before_the_fix() -> void:
	_place_car(Vector2(-66, -58))
	var r := _chase_one(Vector2(-91.1, -64.7), -1.0, 10.0, false)
	assert_false(r.reached)
	assert_not_null(r.stuck_at)
	if r.stuck_at != null:
		var p: Vector2 = r.stuck_at
		assert_lt(p.distance_to(Vector2(-86, -66)), 1.5, "in the corner of the ramp's side and the rooftop: %s" % p)


func test_no_longer_stuck_in_the_pocket() -> void:
	_place_car(Vector2(-66, -58))
	for side in [1.0, -1.0]:
		var r := _chase_one(Vector2(-91.1, -64.7), side, 10.0, true)
		assert_true(r.reached, "detour side %s: reached the car" % side)
		assert_null(r.stuck_at)


## Before: walking straight at the car into a building's side just short of
## its corner, the minion went back and forth on the spot.
func test_reproduced_stuck_on_a_building_side_before_the_fix() -> void:
	_place_car(Vector2(-81, -46))
	var r := _chase_one(Vector2(-58.5, -33.0), -1.0, 10.0, false)
	assert_false(r.reached)
	assert_not_null(r.stuck_at)


func test_no_longer_stuck_on_a_building_side_or_its_corner() -> void:
	_place_car(Vector2(-81, -46))
	for side in [1.0, -1.0]:
		var r := _chase_one(Vector2(-58.5, -33.0), side, 10.0, true)
		assert_true(r.reached, "detour side %s" % side)
	# The corner the 1-unit body cut with the path points taken at 1 unit.
	_place_car(Vector2(81, 46))
	var c := _chase_one(Vector2(99.4, 27.6), 1.0, 10.0, true)
	assert_true(c.reached, "round the south-east building's corner")
	assert_null(c.stuck_at)


# --- line_clear --------------------------------------------------------------------

func test_line_clear_follows_the_grids_links() -> void:
	assert_true(nav.line_clear(Vector2(-100, -50), Vector2(-60, -50), 0.5), "along the street past the ramp's foot")
	assert_false(nav.line_clear(Vector2(-92, -60), Vector2(-66, -60), 0.5), "across the ramp's high part")
	assert_true(nav.line_clear(Vector2(-92, -54.8), Vector2(-66, -54.8)), "across the ramp's low foot")
	assert_true(nav.line_clear(Vector2(-81, -50), Vector2(-81, -80), 0.5), "up the ramp onto its rooftop")
	assert_false(nav.line_clear(Vector2(-60, -60), Vector2(-60, -80)), "up a rooftop's edge")
	assert_false(nav.line_clear(Vector2(-60, -27), Vector2(-100, -27)), "through a building")
	assert_true(nav.line_clear(Vector2(-60, -27), Vector2(-60, -27)), "no line at all")


func test_a_minion_with_a_clear_line_walks_straight_on_any_surface() -> void:
	var f = FollowerScript.new()
	f.by_sight = true
	var car := Vector2(-81, -80)  # on roof-nw-3, straight up ramp-nw-0-3
	var from := Vector2(-81, -50)  # on the street below its foot
	assert_eq(f.target(nav, from, car, DT), car, "straight up the ramp: nothing in the way")
	assert_false(f.has_path())
	f = FollowerScript.new()
	f.by_sight = true
	var t: Vector2 = f.target(nav, Vector2(-66, -58), Vector2(-96, -58), DT)
	assert_true(f.has_path(), "the ramp in the way on the street: a path")
	assert_ne(t, Vector2(-96, -58))
	var checks: int = f.sight_checks
	for i in 4:
		f.target(nav, Vector2(-66, -58), Vector2(-96, -58), DT)
	assert_eq(f.sight_checks, checks, "one sight check per SIGHT_SECONDS")


# --- The scripted chase (AC 2) -----------------------------------------------------

## A run's chase on the elevation map: the car stops in turn beside, at the foot
## of, on and behind both ramp pairs and by the buildings near them, 6 s each,
## with a ring of 16 minions on the street round it walking as in a run
## (spawner.move_step: pushing apart and the navigation's path budget). No
## minion away from the car stands still for more than STUCK_SECONDS.
func test_scripted_chase_no_minion_stuck_against_a_wall_over_2_seconds() -> void:
	var stops := [Vector2(-66, -58), Vector2(-96, -58), Vector2(-81, -46), Vector2(-81, -80),
		Vector2(-60, -81), Vector2(-27, -81), Vector2(-48, -60), Vector2(-81, -46),
		Vector2(66, 58), Vector2(96, 58), Vector2(81, 46), Vector2(81, 80), Vector2(27, 81), Vector2(81, 46)]
	var hist := {}
	var stuck := []
	var ids := {}
	var seen := 0
	for stop in stops:
		_place_car(stop)
		hist.clear()
		# Place a ring of minions at the stop, on the car's level or the street.
		spawner.clear()
		for i in 16:
			var p: Vector2 = stop + Vector2.from_angle(TAU * i / 16.0) * (14.0 + 6.0 * (i % 2))
			if spawner.is_free_spot(p):
				spawner.spawn_minion_at(p)
		var t := 0.0
		while t < 6.0:
			run.state.health = run.state.max_health
			spawner.move_step(DT, false)
			t += DT
			for m in spawner.minions:
				var id: int = m.get_instance_id()
				if not ids.has(id):
					ids[id] = true
					seen += 1
				if not hist.has(id):
					hist[id] = []
				var h: Array = hist[id]
				h.append(m.position_units())
				var back := int(STUCK_SECONDS / DT)
				if h.size() > back and (h[-1] as Vector2).distance_to(h[-1 - back]) < STUCK_MOVE 						and (m.position_units() as Vector2).distance_to(stop) > AT_CAR + m.radius_units() 						and not m.is_falling():
					stuck.append("car %s: minion stuck at %s" % [stop, m.position_units()])
					h.clear()
	gut.p("scripted chase: %d minions over %d stops, %d stuck" % [seen, stops.size(), stuck.size()])
	assert_gt(seen, 100, "a real crowd took part")
	assert_eq(stuck.size(), 0, "no minion stood still against a wall: %s" % [stuck])
