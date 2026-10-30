extends GutTest
## Task T-407: a falling gift pack shows the car's air shadow at its landing
## spot, at the height of the ground it lands on; gone when it lands.

const RunScene := preload("res://scenes/run/run.tscn")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const CarShadowScript := preload("res://scripts/driving/car_shadow.gd")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const ROOF_6_CENTRE := Vector2(-27, -81)

var run: Node2D
var state: RunState
var drops: GiftDrops


func before_each() -> void:
	FlameScript.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	state = run.state
	drops = run.gift_drops


func after_each() -> void:
	FlameScript.playtest_override = -1
	get_tree().paused = false


func _place(units: Vector2, rot: float = 0.0) -> void:
	var car = run.car
	car.model.set_position(units)
	car.model.rotation = rot
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	run.sync_view()


## Sends a helicopter and drops its package (falling, not landed).
func _falling() -> GiftPackage:
	state.add_xp(state.xp_needed())
	var heli: GiftHelicopter = drops.helicopters[-1]
	drops._drop(heli)
	return drops.packages[-1]


func test_a_falling_package_has_the_cars_air_shadow_at_its_landing_spot_on_the_ground() -> void:
	_place(Vector2(0, 0))
	var pkg := _falling()
	assert_true(pkg.is_falling())
	assert_not_null(pkg.shadow, "a shadow while it falls")
	assert_eq(pkg.shadow.get_script(), CarShadowScript, "the car's own shadow")
	assert_true(pkg.shadow.get_parent() == drops)
	assert_almost_eq(pkg.shadow.surface_height, 0.0, 0.001)
	assert_almost_eq(pkg.shadow.position.x, pkg.drawn_ground.x, 0.01)
	assert_almost_eq(pkg.shadow.position.y, pkg.drawn_ground.y, 0.01)


func test_on_a_platform_the_shadow_is_at_the_platforms_height() -> void:
	_place(ROOF_6_CENTRE)
	var pkg := _falling()
	assert_almost_eq(pkg.ground_height, 6.0, 0.001)
	assert_almost_eq(pkg.shadow.surface_height, 6.0, 0.001)
	var expected := ISO * (pkg.ground_px) + Vector2(0, -6.0 * GiftDrops.PX_PER_UNIT)
	assert_almost_eq(pkg.shadow.position.y, expected.y, 0.01)
	assert_almost_eq(pkg.shadow.position.x, expected.x, 0.01)
	assert_eq(pkg.shadow.z_index, run.elevation.shadow_z_for(pkg.ground_units(), 0.0, 6.0, 6.0))
	assert_lt(pkg.shadow.z_index, pkg.z_index, "under the package in the air")


func test_the_shadow_stays_put_while_the_package_falls_and_goes_when_it_lands() -> void:
	_place(Vector2(0, 0))
	var pkg := _falling()
	var at: Vector2 = pkg.shadow.position
	drops.advance(0.3)
	assert_true(pkg.is_falling())
	assert_eq(pkg.shadow.position, at)
	var sh: Node2D = pkg.shadow
	drops.land_all()
	assert_true(pkg.is_landed())
	assert_null(pkg.shadow)
	await get_tree().process_frame
	assert_false(is_instance_valid(sh), "freed on landing")


func test_no_shadow_while_carried_and_none_left_after_pickup_or_clear() -> void:
	_place(Vector2(0, 0))
	state.add_xp(state.xp_needed())
	assert_null(drops.packages[-1].shadow, "carried: no shadow yet")
	var pkg := _falling()
	var sh: Node2D = pkg.shadow
	drops.clear()
	await get_tree().process_frame
	assert_false(is_instance_valid(sh), "a new run clears it")
