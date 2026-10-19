extends GutTest
## Task T-193: the ground-height query on three layers (the street, a height-3
## area and a height-6 area standing on it) with a ramp from the street to the
## height-3 area and a ramp on it up to the height-6 area.
##
## Fixture tests/fixtures/height/three_layers.json:
##   roof_low  x, y in [-20, 20], height 3 (index 0)
##   roof_high x, y in [-10, 6], height 6, on roof_low (index 1)
##   ramp_street_to_low  east of roof_low,  x in [20, 32], y in [-4, 4], 0 -> 3 (index 2)
##   ramp_low_to_high    east of roof_high, x in [6, 18],  y in [-4, 4], 3 -> 6 (index 3), on roof_low

const FIXTURE := "res://tests/fixtures/height/three_layers.json"
const CarHeight := preload("res://scripts/driving/car_height.gd")
const EPS := 0.0001

const STREET := Vector2(-30, 0)
const ON_LOW := Vector2(15, 15)
const ON_HIGH := Vector2(0, 0)
const HALF_UP_LOW := Vector2(26, 0)    # halfway up the 0-to-3 ramp
const HALF_UP_HIGH := Vector2(12, 0)   # halfway up the 3-to-6 ramp

var g: GroundHeight


func before_each() -> void:
	g = GroundHeight.from_file(FIXTURE)


func test_fixture_loads_with_the_stacking_field() -> void:
	assert_eq(g.platforms.size(), 2)
	assert_eq(g.ramps.size(), 2)
	assert_eq(g.platforms[0].on, "", "roof_low stands on the street")
	assert_eq(g.platforms[1].on, "roof_low")
	assert_eq(g.ramps[1].bottom_height, 3.0)
	assert_eq(g.ramps[1].top_height, 6.0)


func test_street() -> void:
	assert_eq(g.height_at(STREET), 0.0)
	assert_true(g.ramp_at(STREET).is_empty())
	assert_eq(g.area_index_at(STREET), -1)
	assert_eq(g.height_at(Vector2(26, 10)), 0.0, "beside the first ramp")


func test_height_3_area() -> void:
	assert_eq(g.height_at(ON_LOW), 3.0)
	assert_true(g.ramp_at(ON_LOW).is_empty())
	assert_eq(g.area_index_at(ON_LOW), 0)
	assert_eq(g.height_at(Vector2(12, 10)), 3.0, "beside the second ramp, on roof_low")
	assert_eq(g.height_at(Vector2(19, 0)), 3.0, "between the two ramps")


func test_height_6_area_is_the_highest_at_the_point() -> void:
	assert_eq(g.height_at(ON_HIGH), 6.0)
	assert_true(g.ramp_at(ON_HIGH).is_empty())
	assert_eq(g.area_index_at(ON_HIGH), 1)
	assert_eq(g.height_at(Vector2(-10, -10)), 6.0, "its corner")


func test_halfway_up_the_street_ramp() -> void:
	assert_almost_eq(g.height_at(HALF_UP_LOW), 1.5, EPS)
	assert_eq(g.ramp_at(HALF_UP_LOW).get("id"), "ramp_street_to_low")
	assert_eq(g.area_index_at(HALF_UP_LOW), 2)


func test_halfway_up_the_rooftop_ramp() -> void:
	assert_almost_eq(g.height_at(HALF_UP_HIGH), 4.5, EPS)
	assert_eq(g.ramp_at(HALF_UP_HIGH).get("id"), "ramp_low_to_high")
	assert_eq(g.area_index_at(HALF_UP_HIGH), 3)


func test_rooftop_ramp_foot_and_top() -> void:
	assert_almost_eq(g.height_at(Vector2(18, 0)), 3.0, EPS, "foot = roof_low's height")
	assert_almost_eq(g.height_at(Vector2(6, 0)), 6.0, EPS, "top = roof_high's height")
	var prev := g.height_at(Vector2(19, 0))
	var x := 19.0
	while x > 5.0:
		x -= 0.1
		var cur := g.height_at(Vector2(x, 0))
		assert_true(absf(cur - prev) <= 3.0 / 12.0 * 0.1 + EPS, "no jump at x=%s" % x)
		prev = cur


func test_side_normals() -> void:
	# Into the rooftop ramp's south side from roof_low beside it.
	assert_eq(g.side_normal(3, Vector2(12, 8), Vector2(12, 2)), Vector2.DOWN)
	# Into roof_high's west side from roof_low.
	assert_eq(g.side_normal(1, Vector2(-14, 0), Vector2(-8, 0)), Vector2.LEFT)
	# Into roof_high's north side.
	assert_eq(g.side_normal(1, Vector2(0, -14), Vector2(0, -8)), Vector2.UP)


func test_edges_between_layers() -> void:
	var e := g.edge_between(ON_HIGH, Vector2(-15, 0))
	assert_true(e.drop, "roof_high's west edge is a drop")
	assert_almost_eq(e.height, 3.0, EPS, "onto roof_low, not to the street")
	assert_false(e.up)
	var back := g.edge_between(Vector2(-15, 0), ON_HIGH)
	assert_true(back.drop)
	assert_true(back.up)
	e = g.edge_between(ON_LOW, Vector2(25, 15))
	assert_true(e.drop)
	assert_almost_eq(e.height, 3.0, EPS)


func test_street_to_second_floor_by_the_ramps_is_never_a_drop() -> void:
	assert_false(g.edge_between(Vector2(40, 0), ON_HIGH).drop)
	assert_false(g.edge_between(ON_HIGH, Vector2(40, 0)).drop)


func test_car_height_follows_both_ramps_up_and_falls_one_floor() -> void:
	var h = CarHeight.new()
	h.ground = g
	h.reset(Vector2(40, 0))
	var dt := 0.02
	var v := Vector2(-3.0, 0)  # slower than RAMP_TAKEOFF_MIN_SPEED: just follows the ground
	var p := Vector2(40, 0)
	while p.x > 0.0:
		var q := p + v * dt
		var r: Dictionary = h.step(p, q, v, dt)
		assert_false(r.wall, "no wall at x=%s" % q.x)
		assert_false(h.airborne, "on the ground at x=%s" % q.x)
		assert_almost_eq(h.height, g.height_at(q), EPS)
		p = q
	assert_almost_eq(h.height, 6.0, EPS)
	# Off roof_high's west edge: lands on roof_low (3), not on the street.
	v = Vector2(-5.0, 0)
	var steps := 0
	while steps < 400 and (steps == 0 or h.airborne or p.x > -10.0):
		var q := p + v * dt
		h.step(p, q, v, dt)
		p = q
		steps += 1
	assert_false(h.airborne)
	assert_almost_eq(h.height, 3.0, EPS)
