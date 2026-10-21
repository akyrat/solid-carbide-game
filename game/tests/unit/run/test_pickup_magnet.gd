extends GutTest
## Task T-222: coins, landed gift packs and health drops within the magnet's
## reach are pulled to the car and picked up; ones outside stay put. The reach
## is one value (run.json's pickup_magnet, RunState.pickup_magnet_radius_units).

const RunScene := preload("res://scenes/run/run.tscn")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const STEP := 1.0 / 60.0
const P := 16.0

var run: Node2D
var state: RunState
var magnet: PickupMagnet


func before_each() -> void:
	FlameScript.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	state = run.state
	magnet = run.pickup_magnet
	run.car.model.x = 0.0
	run.car.model.y = 0.0
	run.car.model.set_velocity(Vector2.ZERO)
	run.car._sync_from_model()


func after_each() -> void:
	FlameScript.playtest_override = -1
	get_tree().paused = false


func _car() -> Vector2:
	return run.car.position / P


func _coin(offset: Vector2) -> Node:
	return run.minions.spawn_coin_at(_car() + offset, 1)


func _steps(n: int) -> void:
	for i in n:
		magnet.step(STEP)
		run.gift_drops.check_pickups()


func _landed_package(offset: Vector2) -> GiftPackage:
	state.add_xp(state.xp_needed())
	var heli: GiftHelicopter = run.gift_drops.helicopters[0]
	var pkg: GiftPackage = heli.package
	run.gift_drops.land_all()
	pkg.ground_px = (_car() + offset) * P
	pkg.drawn_ground = GiftDrops.ISO_TRANSFORM * pkg.ground_px
	pkg.position = pkg.drawn_ground
	return pkg


func _health_drop(offset: Vector2) -> Node:
	var d := HealthDropStub.new()
	d.position = (_car() + offset) * P
	d.add_to_group("health_drops")
	run.add_child(d)
	return d


class HealthDropStub extends Node2D:
	var taken := false
	var sprite = null

	func is_taken() -> bool:
		return taken

	func collect() -> void:
		taken = true
		remove_from_group("health_drops")


func test_the_reach_is_one_car_length_from_run_json() -> void:
	assert_eq(state.pickup_magnet_radius_units, 3.0)
	assert_eq(RunData.new().pickup_magnet_radius_units(), 3.0)


func test_a_coin_inside_the_reach_flies_to_the_car_and_is_picked_up() -> void:
	var c := _coin(Vector2(2.5, 0))
	var before: float = c.position_units().distance_to(_car())
	_steps(3)
	assert_lt(c.position_units().distance_to(_car()), before, "moved towards the car")
	_steps(60)
	assert_true(c.is_taken(), "picked up")
	assert_eq(state.coins, 1)


func test_a_coin_outside_the_reach_stays_where_it_is() -> void:
	var c := _coin(Vector2(3.5, 0))
	var at: Vector2 = c.position
	_steps(60)
	assert_eq(c.position, at)
	assert_false(c.is_taken())


func test_a_coin_drawing_moves_with_it() -> void:
	var c := _coin(Vector2(0, 2.5))
	var s: Node2D = c.sprite
	var from := s.position
	_steps(5)
	assert_ne(s.position, from)


func test_a_landed_gift_pack_inside_the_reach_is_pulled_and_picked_up() -> void:
	run.state.pause_on_level_up = false
	var pkg := _landed_package(Vector2(2.9, 0))
	var picked := []
	run.gift_drops.package_picked_up.connect(func(p): picked.append(p))
	_steps(1)
	assert_lt(pkg.ground_units().distance_to(_car()), 2.9, "moved towards the car")
	_steps(60)
	assert_eq(picked.size(), 1, "picked up")


func test_a_landed_gift_pack_outside_the_reach_stays() -> void:
	var pkg := _landed_package(Vector2(0, 3.5))
	var at := pkg.ground_px
	_steps(60)
	assert_eq(pkg.ground_px, at)
	assert_true(run.gift_drops.packages.has(pkg))


func test_a_falling_gift_pack_is_not_pulled() -> void:
	state.add_xp(state.xp_needed())
	var heli: GiftHelicopter = run.gift_drops.helicopters[0]
	var pkg: GiftPackage = heli.package
	var at := pkg.ground_px
	_steps(10)
	assert_eq(pkg.ground_px, at)


func test_a_health_drop_inside_the_reach_is_pulled_and_outside_stays() -> void:
	var near := _health_drop(Vector2(-2.5, 0))
	var far := _health_drop(Vector2(-4.0, 0))
	var far_at: Vector2 = far.position
	_steps(60)
	assert_true(near.is_taken(), "picked up")
	assert_eq(far.position, far_at)


func test_changing_the_one_value_changes_the_reach() -> void:
	var c := _coin(Vector2(5, 0))
	_steps(10)
	assert_false(c.is_taken())
	var at: Vector2 = c.position
	state.pickup_magnet_radius_units = 6.0
	_steps(5)
	assert_ne(c.position, at, "now inside the reach")
	state.pickup_magnet_radius_units = 0.0
	var at2: Vector2 = c.position
	_steps(5)
	assert_eq(c.position, at2)


func test_nothing_is_pulled_while_paused() -> void:
	var c := _coin(Vector2(2.5, 0))
	var at: Vector2 = c.position
	magnet.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().paused = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(c.position, at)
