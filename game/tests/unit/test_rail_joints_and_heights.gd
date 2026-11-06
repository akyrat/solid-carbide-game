extends GutTest
## Task T-542 round 2 (Drifting, Content, "Rail joints and rails on raised ground (task T-542)"): a joint
## between connected rail pieces at an angle costs no speed, and a car on a platform or a ramp is caught
## by a rail as easily as one on the street (the lock-on compares the car's and the bar's real heights).

const Rails := preload("res://scripts/level/rails.gd")
const RailGrind := preload("res://scripts/driving/rail_grind.gd")
const CarHeight := preload("res://scripts/driving/car_height.gd")
const JumpPowerUp := preload("res://scripts/driving/jump_power_up.gd")
const RailDrawing := preload("res://scripts/level/rail_drawing.gd")
const DT := 1.0 / 60.0


func _rail(id: String, a: Vector2, b: Vector2, z := 1.0) -> Dictionary:
	return Rails.make(id, a, b, z, z)


## A grind started on rails[0] at its end a, along it, at `speed`.
func _start(rails: Array, speed: float) -> RailGrind:
	var g := RailGrind.new()
	g.rails = rails
	g.start({"index": 0, "s": 0.0, "speed_along": speed}, 0.0)
	return g


## Slides until `distance` units have been covered; returns the speed then (-1 when the grind ended first).
func _slide(g: RailGrind, distance: float) -> float:
	var steps := 0
	while g.length < distance and steps < 5000:
		steps += 1
		if g.step(DT) != "":
			return -1.0
	return g.speed


## Two pieces of 10 units, the second turned `deg` degrees from the first, joined end to end.
func _angled(deg: float) -> Array:
	var d := Vector2.RIGHT.rotated(deg_to_rad(deg))
	return [_rail("a", Vector2.ZERO, Vector2(10, 0)), _rail("b", Vector2(10, 0), Vector2(10, 0) + d * 10.0)]


func test_a_joint_at_30_degrees_costs_no_speed_against_a_straight_rail() -> void:
	var straight := _start(_angled(0.0), 11.0)
	var bent := _start(_angled(30.0), 11.0)
	var v_straight := _slide(straight, 15.0)
	var v_bent := _slide(bent, 15.0)
	gut.p("speed after 15 units: straight %.4f, 30 degree joint %.4f" % [v_straight, v_bent])
	assert_gt(v_bent, 0.0, "still grinding past the joint")
	assert_almost_eq(v_bent, v_straight, 0.02, "the same speed")
	assert_eq(bent.joints, 1)
	assert_eq(bent.rail_index, 1, "on the second piece")
	assert_almost_eq(bent.travel().angle(), deg_to_rad(30.0), 1e-6, "travelling along the new piece")
	assert_true(bent.active)


func test_a_right_angle_joint_costs_no_speed_either() -> void:
	var v := _slide(_start(_angled(90.0), 11.0), 15.0)
	assert_almost_eq(v, _slide(_start(_angled(0.0), 11.0), 15.0), 0.02)


func test_the_grind_goes_on_as_one_across_the_joint() -> void:
	var g := _start(_angled(45.0), 11.0)
	var ended: Array = []
	g.grind_ended.connect(func(reason: String, seconds: float, length: float) -> void: ended.append([reason, seconds, length]))
	var steps := 0
	while g.active and steps < 5000:
		steps += 1
		var why := g.step(DT)
		if why != "":
			g.stop(why)
	assert_eq(ended.size(), 1, "one grind, one GRIND! payment")
	assert_gt(float(ended[0][2]), 19.0, "its length counts both pieces (20 units)")


func test_a_piece_drawn_b_to_a_is_crossed_toward_its_far_end() -> void:
	var g := _start([_rail("a", Vector2.ZERO, Vector2(10, 0)), _rail("b", Vector2(10, 10), Vector2(10, 0))], 11.0)
	_slide(g, 12.0)
	assert_eq(g.rail_index, 1)
	assert_almost_eq(g.travel().y, 1.0, 1e-6, "south, from the joint toward (10, 10)")
	assert_eq(g.direction, -1.0)


func test_connected_means_an_end_within_join_distance_and_join_height() -> void:
	var g := RailGrind.new()
	g.rails = [_rail("a", Vector2.ZERO, Vector2(10, 0)), _rail("b", Vector2(10.0 + g.join_distance * 0.9, 0.0), Vector2(20, 5))]
	g.start({"index": 0, "s": 10.0, "speed_along": 11.0}, 0.0)
	assert_eq(g.joint_at_end().get("index", -1), 1, "a gap just under join_distance joins")
	g.rails = [_rail("a", Vector2.ZERO, Vector2(10, 0)), _rail("b", Vector2(10.0 + g.join_distance * 1.2, 0.0), Vector2(20, 5))]
	g.start({"index": 0, "s": 10.0, "speed_along": 11.0}, 0.0)
	assert_true(g.joint_at_end().is_empty(), "a gap over join_distance does not")
	g.rails = [_rail("a", Vector2.ZERO, Vector2(10, 0), 1.0), _rail("b", Vector2(10, 0), Vector2(20, 5), 1.0 + g.join_height + 0.2)]
	g.start({"index": 0, "s": 10.0, "speed_along": 11.0}, 0.0)
	assert_true(g.joint_at_end().is_empty(), "a height gap over join_height does not")


func test_a_fold_back_is_not_a_joint() -> void:
	var g := _start(_angled(150.0), 11.0)
	assert_eq(_slide(g, 11.0), -1.0, "the grind ends at the rail's end as before")
	assert_eq(g.joints, 0)


func test_the_smallest_turn_wins_at_a_fork() -> void:
	var g := _start([_rail("a", Vector2.ZERO, Vector2(10, 0)), _rail("sharp", Vector2(10, 0), Vector2(10, 10)),
		_rail("gentle", Vector2(10, 0), Vector2(20, 3))], 11.0)
	_slide(g, 11.0)
	assert_eq(g.rail_index, 2)


func test_the_numbers_for_joints_are_in_the_data_file() -> void:
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/rail_grind.json"))
	for k in ["join_distance", "join_height", "join_max_angle_deg", "catch_above"]:
		assert_true(json.has(k), k)
	assert_almost_eq(RailGrind.new().join_distance, float(json.join_distance), 1e-9)


# --- A platform or a ramp is as easy as the street ----------------------------------------------

## The steps of a first-tier Jump hop (flat speed 11, along a rail on the x axis, 1 unit to its side), from
## ground height `ground` with the bar at `bar` (its real height), in which the lock-on finds the rail.
func _catchable_steps(ground: float, bar: float) -> int:
	var g := RailGrind.new()
	g.rails = [Rails.make("r", Vector2(0, 0), Vector2(80, 0), bar, bar)]
	var jump := JumpPowerUp.new()
	jump.set_tier(1)
	var h := CarHeight.new()
	h.height = ground
	h.hop(jump.takeoff_speed)
	var x := 2.0
	var n := 0
	for i in 200:
		x += 11.0 * DT
		h.vertical_speed -= CarHeight.GRAVITY * DT
		h.height += h.vertical_speed * DT
		if h.height <= ground:
			break
		if not g.find(Vector2(x, 1.0), Vector2(11, 0), h.height, h.vertical_speed).is_empty():
			n += 1
	return n


func test_a_hop_from_a_platform_is_caught_by_a_rail_as_long_as_one_from_the_street() -> void:
	var street := _catchable_steps(0.0, 1.0)
	var platform := _catchable_steps(3.0, 4.0)
	var roof6 := _catchable_steps(6.0, 7.0)
	gut.p("steps in the lock-on window: street %d, 3 platform %d, 6 platform %d" % [street, platform, roof6])
	assert_gt(street, 5)
	assert_eq(platform, street, "the same window from a 3 platform (the bar 1 over it, the creator's auto height)")
	assert_eq(roof6, street)


func test_a_bar_only_a_tenth_over_the_platform_is_caught_all_along_the_arc_too() -> void:
	# The creator's old auto height (3.1 over a 3 platform) and the fixed 3.1 pick.
	var street := _catchable_steps(0.0, 1.0)
	var low := _catchable_steps(3.0, 3.1)
	gut.p("steps: street %d, bar 0.1 over a platform %d" % [street, low])
	assert_gte(low, street - 1, "no harder than the street")


func test_the_lock_on_distance_and_angle_are_the_same_on_a_platform() -> void:
	var plat := RailGrind.new()
	plat.rails = [Rails.make("r", Vector2(0, 0), Vector2(60, 0), 4.0, 4.0)]
	var street := RailGrind.new()
	street.rails = [Rails.make("r", Vector2(0, 0), Vector2(60, 0), 1.0, 1.0)]
	for side in [0.5, 1.9, 2.1]:
		for deg in [0.0, 55.0, 65.0]:
			var vel := Vector2(11, 0).rotated(deg_to_rad(deg))
			var on_plat := not plat.find(Vector2(10, side), vel, 4.0, -1.0).is_empty()
			var on_street := not street.find(Vector2(10, side), vel, 1.0, -1.0).is_empty()
			assert_eq(on_plat, on_street, "side %s, angle %s" % [side, deg])


func test_the_lock_on_compares_real_heights() -> void:
	# The car's height is absolute (4.2 on a 3 platform's jump): the bar at 4.0 is in reach, a street rail's
	# bar at 1.0 under the platform is not.
	var g := RailGrind.new()
	g.rails = [Rails.make("r", Vector2(0, 0), Vector2(60, 0), 4.0, 4.0), Rails.make("s", Vector2(0, 8), Vector2(60, 8), 1.0, 1.0)]
	assert_false(g.find(Vector2(10, 0.0), Vector2(11, 0), 4.2, -1.0).is_empty())
	assert_true(g.find(Vector2(10, 8.0), Vector2(11, 0), 4.2, -1.0).is_empty(), "a street rail under the platform is out of reach")


# --- Drawing on raised ground --------------------------------------------------------------------

class _MapStub extends Node2D:
	var view_root := Node2D.new()

	func _init() -> void:
		add_child(view_root)


func test_a_piece_over_raised_ground_draws_its_own_shadow_on_that_ground() -> void:
	var map := _MapStub.new()
	add_child_autofree(map)
	var rails := [_rail("on", Vector2(0, 0), Vector2(10, 0), 4.0)]
	var d := RailDrawing.new()
	d.build(map, rails, func(_u: Vector2) -> float: return 3.0)
	assert_eq(d.pieces.size(), 5)
	for p in d.pieces:
		assert_eq(p.shadow.size(), 2, "a shadow on the rooftop")
		assert_almost_eq((p.shadow[0] as Vector2).y - (p.from as Vector2).y, 1.0 * RailDrawing.PX_PER_UNIT, 1e-6, "one unit under the bar")
	assert_eq(d.shadows.lines.size(), 0, "none on the street under it")
	var d2 := RailDrawing.new()
	d2.build(map, rails)
	for p in d2.pieces:
		assert_eq(p.shadow.size(), 0)
	assert_eq(d2.shadows.lines.size(), 1, "one line on the street")


func test_a_rail_from_the_street_onto_a_rooftop_shadows_the_street_part_on_the_street() -> void:
	var map := _MapStub.new()
	add_child_autofree(map)
	var d := RailDrawing.new()
	d.build(map, [Rails.make("r", Vector2(0, 0), Vector2(20, 0), 1.0, 4.0)],
		func(u: Vector2) -> float: return 3.0 if u.x > 10.0 else 0.0)
	assert_eq(d.shadows.lines.size(), 1, "the street part")
	var raised := d.pieces.filter(func(p) -> bool: return p.shadow.size() == 2).size()
	assert_gt(raised, 3)
	assert_lt(raised, d.pieces.size())
