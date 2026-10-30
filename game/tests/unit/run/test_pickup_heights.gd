extends GutTest
## Task T-402, widened by the board (2026-10-30): "when I go to pick up the gift on a platform,
## its hitbox is in the wrong place." Every pickup (gift package, coin, health pickup) is drawn
## and picked up at the height it lies at: on a rooftop the car picks it up there, not from the
## street below. The pickup magnet pulls only pickups on the car's level, and a pulled pickup
## follows the ground's height. On the elevation sample map (the run's default): roof-nw-6
## (height 6) is x -42..-12, y -96..-66; the street is south of y -66 there.

const RunScene := preload("res://scenes/run/run.tscn")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const PickupHeightScript := preload("res://scripts/run/pickup_height.gd")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const P := 16.0
const STEP := 1.0 / 60.0
const ROOF_6_CENTRE := Vector2(-27, -81)
## On roof-nw-6, just inside its south edge, and the street just outside it.
const ROOF_EDGE := Vector2(-27, -66.4)
const STREET_BY_EDGE := Vector2(-27, -65.4)

var run: Node2D
var state: RunState


func before_each() -> void:
	FlameScript.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	state = run.state


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


func test_the_rule() -> void:
	assert_true(PickupHeightScript.car_reaches(6.0, 6.0))
	assert_true(PickupHeightScript.car_reaches(3.0, 0.0), "jumping over a street pickup")
	assert_false(PickupHeightScript.car_reaches(0.0, 6.0), "from the street below a rooftop")
	assert_false(PickupHeightScript.car_reaches(3.0, 6.0), "from a lower rooftop")
	assert_true(PickupHeightScript.same_level(6.0, 6.2))
	assert_false(PickupHeightScript.same_level(0.0, 3.0))


# ---- The gift package: its hitbox is where it is drawn ----------------------------------------

func test_the_gift_on_a_rooftop_is_picked_up_where_it_is_drawn() -> void:
	_place(ROOF_6_CENTRE)
	state.add_xp(state.xp_needed())
	run.gift_drops.land_all()
	var pkg: GiftPackage = run.gift_drops.packages[0]
	assert_almost_eq(pkg.ground_height, 6.0, 0.001)
	_place(pkg.ground_units())
	assert_almost_eq(run.car.height, 6.0, 0.001)
	assert_almost_eq(run.car_sprite.position.x, pkg.position.x, 0.01, "the car drawn on the package")
	assert_almost_eq(run.car_sprite.position.y, pkg.position.y, 0.01, "at the same height")
	run.gift_drops.check_pickups()
	assert_true(run.gift_drops.packages.is_empty(), "picked up where it is drawn")


# ---- Coins and health pickups -----------------------------------------------------------------

func test_a_coin_on_a_rooftop_is_drawn_at_its_height() -> void:
	var c = run.minions.spawn_coin_at(ROOF_6_CENTRE)
	assert_almost_eq(c.ground_height, 6.0, 0.001)
	var expected := ISO * (ROOF_6_CENTRE * P) + Vector2(0, -6.0 * P)
	assert_almost_eq(c.sprite.position.y, expected.y, 0.01)
	var h = run.minions.spawn_health_pickup_at(ROOF_6_CENTRE + Vector2(3, 0))
	assert_almost_eq(h.ground_height, 6.0, 0.001)
	var s = run.minions.spawn_coin_at(Vector2(0, 0))
	assert_almost_eq(s.ground_height, 0.0, 0.001, "street")


func test_a_coin_and_a_health_pickup_on_a_rooftop_are_not_picked_up_from_below() -> void:
	var c = run.minions.spawn_coin_at(ROOF_EDGE)
	var hp = run.minions.spawn_health_pickup_at(ROOF_EDGE)
	_place(ROOF_EDGE)
	run.car.height_model.height = 0.0  # as from the street below, at the wall
	c._on_body_entered(run.car)
	hp._on_body_entered(run.car)
	assert_false(c.is_taken(), "coin not picked up from below")
	assert_false(hp.is_taken(), "health pickup not picked up from below")
	run.car.height_model.height = 6.0
	c._on_body_entered(run.car)
	hp._on_body_entered(run.car)
	assert_true(c.is_taken(), "coin picked up on the rooftop")
	assert_true(hp.is_taken(), "health pickup picked up on the rooftop")


func test_a_car_on_the_street_by_the_wall_does_not_collect_a_coin_on_the_rooftop() -> void:
	var c = run.minions.spawn_coin_at(ROOF_EDGE)
	var coins := state.coins
	_place(STREET_BY_EDGE, PI / 2.0)
	assert_almost_eq(run.car.height, 0.0, 0.001, "on the street")
	await wait_physics_frames(4)
	assert_true(is_instance_valid(c) and not c.is_taken(), "the car's body overlaps it, but from below")
	assert_eq(state.coins, coins)


func test_a_car_on_the_rooftop_collects_a_coin_there() -> void:
	var c = run.minions.spawn_coin_at(ROOF_6_CENTRE)
	var coins := state.coins
	_place(ROOF_6_CENTRE)
	await wait_physics_frames(4)
	assert_true(not is_instance_valid(c) or c.is_taken(), "collected (and freed)")
	assert_eq(state.coins, coins + 1)


func test_a_car_jumping_over_a_street_coin_still_collects_it() -> void:
	var c = run.minions.spawn_coin_at(Vector2(0, 0))
	_place(Vector2(0, 0))
	run.car.height_model.height = 3.0
	c._on_body_entered(run.car)
	assert_true(c.is_taken())


# ---- The pickup magnet ------------------------------------------------------------------------

func test_the_magnet_pulls_only_pickups_on_the_cars_level() -> void:
	_place(ROOF_6_CENTRE)
	var reach: float = state.pickup_magnet_radius_units
	if reach <= 0.0:
		state.pickup_magnet_radius_units = 6.0
	var on_roof = run.minions.spawn_coin_at(ROOF_6_CENTRE + Vector2(0, 3))
	var below = run.minions.spawn_coin_at(Vector2(-27, -62))
	state.pickup_magnet_radius_units = 20.0
	var below_at: Vector2 = below.position
	var roof_at: Vector2 = on_roof.position
	run.pickup_magnet.step(STEP)
	assert_eq(below.position, below_at, "a street coin is not pulled up to a car on the rooftop")
	assert_ne(on_roof.position, roof_at, "a coin on the rooftop is pulled")


func test_a_pulled_pickup_follows_the_grounds_height() -> void:
	# A coin on the street pulled along the street towards a car on the street: stays at 0.
	_place(Vector2(0, 0))
	state.pickup_magnet_radius_units = 20.0
	var c = run.minions.spawn_coin_at(Vector2(5, 0))
	run.pickup_magnet.step(STEP)
	assert_almost_eq(c.ground_height, 0.0, 0.001)
	assert_almost_eq(c.sprite.position.y, (ISO * c.position).y, 0.01)
	# On the rooftop: pulled across it, drawn at 6.
	_place(ROOF_6_CENTRE)
	var r = run.minions.spawn_coin_at(ROOF_6_CENTRE + Vector2(4, 0))
	run.pickup_magnet.step(STEP)
	assert_almost_eq(r.ground_height, 6.0, 0.001)
	assert_almost_eq(r.sprite.position.y, (ISO * r.position).y - 6.0 * P, 0.01)


func test_the_magnet_leaves_a_gift_on_another_level() -> void:
	_place(ROOF_6_CENTRE)
	state.add_xp(state.xp_needed())
	run.gift_drops.land_all()
	var pkg: GiftPackage = run.gift_drops.packages[0]
	run.gift_drops.move_package(pkg, Vector2(-27, -60) * P)  # on the street below
	assert_almost_eq(pkg.ground_height, 0.0, 0.001)
	state.pickup_magnet_radius_units = 30.0
	var at := pkg.ground_px
	run.pickup_magnet.step(STEP)
	assert_eq(pkg.ground_px, at, "not pulled up the wall")
