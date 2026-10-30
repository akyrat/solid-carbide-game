extends GutTest
## Task T-402: a gift pack that falls on a platform was drawn below it. On the
## elevation sample map (the run's default map): roof-nw-6 (height 6) is x
## -42..-12, y -96..-66, with its centre (-27, -81) more than the search's
## reach (land_ahead_units x 1.5 + clearance) from any street; roof-nw-3
## (height 3) is x -96..-12, y -96..-66.
##
## The rule (Level design, Content, "Elevation sample map"; Game loop
## architecture, Decisions, "Gift pack drop"): street spots first; only when
## none is open does the package land on the rooftop the car is on. Either way
## it is drawn at the height of what it lands on, in the car's depth order at
## that height, and picked up only by a car at that height or above.

const RunScene := preload("res://scenes/run/run.tscn")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const ROOF_6_CENTRE := Vector2(-27, -81)

var run: Node2D
var state: RunState
var drops: GiftDrops
var data: GiftPackData


func before_each() -> void:
	FlameScript.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	state = run.state
	drops = run.gift_drops
	data = drops.data


func after_each() -> void:
	FlameScript.playtest_override = -1
	get_tree().paused = false


func _area(id: String):
	for a in run.elevation.areas:
		if str(a.block.id) == id:
			return a
	return null


## Puts the car at rest at `units` with heading `rot`, on the ground there.
func _place(units: Vector2, rot: float = 0.0) -> void:
	var car = run.car
	car.model.set_position(units)
	car.model.rotation = rot
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	run.sync_view()


func _drop_one() -> GiftPackage:
	state.add_xp(state.xp_needed())
	drops.land_all()
	return drops.packages[-1]


func _height_at(units: Vector2) -> float:
	return run.elevation.ground_height.height_at(units)


## The board's case. Fails before the fix: the package fell back to the car's
## spot on the rooftop but was drawn at street level, 96 drawn pixels below
## the rooftop's top.
func test_a_package_that_lands_on_a_rooftop_is_drawn_at_the_rooftops_height() -> void:
	assert_true(run.elevation != null, "the run plays the elevation map")
	_place(ROOF_6_CENTRE)
	var pkg := _drop_one()
	var spot := pkg.ground_units()
	assert_almost_eq(_height_at(spot), 6.0, 0.001, "no street spot in reach: it lands on the rooftop")
	var expected := ISO * (spot * GiftDrops.PX_PER_UNIT) + Vector2(0, -6.0 * GiftDrops.PX_PER_UNIT)
	assert_almost_eq(pkg.position.x, expected.x, 0.01)
	assert_almost_eq(pkg.position.y, expected.y, 0.01, "drawn on the rooftop's top, not the street under it")
	assert_almost_eq(float(pkg.get("ground_height")) if pkg.get("ground_height") != null else 0.0, 6.0, 0.001)
	assert_gt(pkg.z_index, _area("roof-nw-6").z_index, "drawn over the rooftop it lies on")
	assert_eq(pkg.z_index, run.elevation.z_for(spot, 0.0, 6.0), "the car's depth order at that height")


func test_on_a_rooftop_it_lands_on_open_flat_ground_of_that_rooftop_not_the_cars_own_spot() -> void:
	_place(ROOF_6_CENTRE)
	var pkg := _drop_one()
	var spot := pkg.ground_units()
	assert_almost_eq(spot.distance_to(ROOF_6_CENTRE), data.land_ahead_units(), 0.01,
			"straight ahead, as on the street")
	assert_true(drops.is_open_rooftop(spot, 6.0))


func test_a_rooftop_spot_needs_flat_ground_of_the_same_height_all_round() -> void:
	assert_true(drops.is_open_rooftop(ROOF_6_CENTRE, 6.0))
	assert_false(drops.is_open_rooftop(ROOF_6_CENTRE, 3.0), "not the height asked for")
	assert_false(drops.is_open_rooftop(Vector2(-12.5, -81), 6.0), "across the rooftop's edge")
	assert_false(drops.is_open_rooftop(Vector2(-41.5, -81), 6.0), "by the step down to the 3")
	assert_false(drops.is_open_rooftop(Vector2(-48, -81), 3.0), "on the ramp up to the 6")
	assert_false(drops.is_open_rooftop(Vector2(0, 0), 0.0), "the street is not a rooftop")


func test_near_a_rooftop_it_keeps_to_the_street() -> void:
	# On roof-nw-6 by its south edge, facing south: the street is 8 units ahead.
	_place(Vector2(-17, -72), PI / 2.0)
	var pkg := _drop_one()
	assert_almost_eq(pkg.ground_height, 0.0, 0.001)
	assert_almost_eq(_height_at(pkg.ground_units()), 0.0, 0.001, "street first")
	assert_true(run.elevation.is_street(pkg.ground_units(), data.clearance_units()))
	assert_eq(pkg.position, ISO * pkg.ground_px, "drawn on the street")


func test_never_drawn_below_what_it_lands_on_all_over_the_map() -> void:
	var checked := 0
	var on_roofs := 0
	for x in range(-114, 115, 6):
		for y in range(-114, 115, 6):
			var at := Vector2(x, y)
			if not run.map.is_open_spot(at, 0.5, false):
				continue
			_place(at)
			var spot := drops.landing_spot()
			var h := _height_at(spot)
			var pkg: GiftPackage = drops.PackageScene.instantiate()
			pkg.set_ground(spot * GiftDrops.PX_PER_UNIT, drops.ground_height_at(spot))
			assert_almost_eq(pkg.ground_height, h, 0.001, "at the ground's height (car at %s)" % at)
			assert_almost_eq(pkg.drawn_ground.y,
					(ISO * (spot * GiftDrops.PX_PER_UNIT)).y - h * GiftDrops.PX_PER_UNIT, 0.01)
			if h > 0.0:
				on_roofs += 1
				assert_true(drops.is_open_rooftop(spot, h) or spot == at,
						"on a rooftop only on open flat ground (car at %s)" % at)
				var z: int = run.elevation.z_for(spot, 0.0, h)
				var a = run.elevation.areas[run.elevation.ground_height.area_index_at(spot)]
				assert_gt(z, a.z_index, "drawn over the rooftop it lies on (car at %s)" % at)
			pkg.free()
			checked += 1
	assert_gt(checked, 200, "most of the map checked")
	assert_gt(on_roofs, 0, "some cars are well inside a rooftop")


func test_the_car_picks_it_up_on_the_rooftop() -> void:
	_place(ROOF_6_CENTRE)
	var pkg := _drop_one()
	assert_eq(drops.packages.size(), 1)
	_place(pkg.ground_units() + Vector2(data.pickup_radius_units() * 0.5, 0.0))
	assert_almost_eq(run.car.height, 6.0, 0.001, "the car is up on the rooftop")
	drops.check_pickups()
	assert_true(drops.packages.is_empty(), "picked up there")
	assert_true(run.level_up_screen.visible, "its level-up screen opens")


func test_a_car_below_the_rooftop_does_not_pick_it_up() -> void:
	_place(ROOF_6_CENTRE)
	var pkg := _drop_one()
	_place(pkg.ground_units())
	run.car.height_model.height = 0.0  # as if under it, at street level
	drops.check_pickups()
	assert_eq(drops.packages.size(), 1, "not picked up from below")
	run.car.height_model.height = 6.0
	drops.check_pickups()
	assert_true(drops.packages.is_empty(), "picked up from its height")


func test_a_car_jumping_over_a_street_package_still_picks_it_up() -> void:
	_place(Vector2(0, 0))
	var pkg := _drop_one()
	assert_almost_eq(pkg.ground_height, 0.0, 0.001)
	_place(pkg.ground_units())
	run.car.height_model.height = 3.0
	run.car.height_model.airborne = true
	drops.check_pickups()
	assert_true(drops.packages.is_empty())


func test_a_package_moved_by_the_magnet_follows_the_ground_and_depth() -> void:
	_place(ROOF_6_CENTRE)
	var pkg := _drop_one()
	drops.move_package(pkg, Vector2(0, 0))
	assert_almost_eq(pkg.ground_height, 0.0, 0.001)
	assert_eq(pkg.position, Vector2.ZERO, "back on the street")
	assert_eq(pkg.z_index, run.elevation.z_for(Vector2.ZERO, 0.0, 0.0))
	drops.move_package(pkg, ROOF_6_CENTRE * GiftDrops.PX_PER_UNIT)
	assert_almost_eq(pkg.ground_height, 6.0, 0.001)
	assert_eq(pkg.z_index, run.elevation.z_for(ROOF_6_CENTRE, 0.0, 6.0))
