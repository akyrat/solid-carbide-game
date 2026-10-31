extends GutTest
## Task T-454 (Visual style, Decisions, "Shadows shrink with height"): the car
## in the air, a falling gift pack, falling enemies and thrown Molotov bottles
## size their shadows with the shared curve (shadow_size.gd) by their height
## above the surface under them (the street or a rooftop's top).
## Map (elevation_sample_map.json): roof-nw-6 (height 6) under (-27, -81),
## the street at (0, 0) and (-20, -60).

const RunScene := preload("res://scenes/run/run.tscn")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const CarShadowScript := preload("res://scripts/driving/car_shadow.gd")
const ShadowSizeScript := preload("res://scripts/driving/shadow_size.gd")
const MolotovsScript := preload("res://scripts/weapons/molotovs.gd")
const KaijuSpriteScript := preload("res://scripts/enemies/kaiju_sprite.gd")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const ROOF_6 := Vector2(-27, -81)
const STREET := Vector2(-20, -60)

var run: Node2D


func before_each() -> void:
	FlameScript.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.minions.clear()
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false


func after_each() -> void:
	FlameScript.playtest_override = -1
	get_tree().paused = false


## Width on screen of an outline (drawn pixels).
func _width(pts: PackedVector2Array) -> float:
	var lo := INF
	var hi := -INF
	for p in pts:
		lo = minf(lo, p.x)
		hi = maxf(hi, p.x)
	return hi - lo


func _centre(pts: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for p in pts:
		sum += p
	return sum / pts.size()


## The car at rest over `units`, `above` units over the ground there.
func _fly(units: Vector2, above: float) -> void:
	var car = run.car
	car.model.set_position(units)
	car.model.rotation = 0.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	var g: float = run.elevation.ground_height.height_at(units)
	car.height_model.height = g + above
	car.height_model.airborne = above > 0.0
	run.sync_view()


# --- The car ----------------------------------------------------------------

func test_the_cars_shadow_is_its_full_size_on_the_ground_and_shrinks_as_it_rises() -> void:
	_fly(Vector2(0, 0), 0.0)
	var full: float = run.shadow.diameter_units()
	assert_almost_eq(full, CarShadowScript.DIAMETER_UNITS, 1e-6, "the car's width on the ground")
	assert_almost_eq(_width(run.shadow.outline()), full * 16.0 * sqrt(2.0), 0.01)
	var prev := full
	for above in [0.5, 1.5, 3.0, 6.0]:
		_fly(Vector2(0, 0), above)
		var d: float = run.shadow.diameter_units()
		assert_almost_eq(d, ShadowSizeScript.size_for_height(CarShadowScript.DIAMETER_UNITS, above), 1e-6,
			"the shared curve at %s" % above)
		assert_lt(d, prev, "smaller at %s than lower" % above)
		assert_almost_eq(_width(run.shadow.outline()), d * 16.0 * sqrt(2.0), 0.01, "drawn at that size")
		prev = d
	# Coming down: it grows back.
	_fly(Vector2(0, 0), 1.0)
	assert_gt(run.shadow.diameter_units(), prev, "grows as the car comes down")


func test_over_a_rooftop_the_cars_shadow_lies_on_the_top_and_sizes_by_the_height_above_it() -> void:
	_fly(ROOF_6, 2.0)
	assert_almost_eq(run.shadow.surface_height, 6.0, 1e-6, "on the rooftop's top")
	assert_almost_eq(run.shadow.position.y, (ISO * (ROOF_6 * 16.0)).y - 6.0 * 16.0, 0.01, "drawn on the top")
	assert_almost_eq(run.shadow.height_above, 2.0, 1e-6, "2 units above the rooftop, not 8 above the street")
	var on_roof: float = run.shadow.diameter_units()
	_fly(Vector2(0, 0), 2.0)
	assert_almost_eq(on_roof, run.shadow.diameter_units(), 1e-6, "the same size as 2 above the street")
	_fly(ROOF_6, 0.0)
	assert_almost_eq(run.shadow.diameter_units(), CarShadowScript.DIAMETER_UNITS, 1e-6, "full size on the rooftop")


# --- The gift pack ----------------------------------------------------------

func _falling_package(at: Vector2) -> GiftPackage:
	_fly(at, 0.0)
	var drops: GiftDrops = run.gift_drops
	run.state.add_xp(run.state.xp_needed())
	drops._drop(drops.helicopters[-1])
	return drops.packages[-1]


func test_a_falling_gift_packs_shadow_grows_as_it_comes_down_to_the_packages_size() -> void:
	var pkg := _falling_package(Vector2(0, 0))
	var drops: GiftDrops = run.gift_drops
	var full := GiftDrops.shadow_full_diameter_units()
	assert_almost_eq(pkg.shadow.full_diameter_units, full, 1e-6)
	assert_gt(pkg.height(), 0.0, "in the air")
	assert_almost_eq(pkg.shadow.height_above, pkg.height() / 16.0, 1e-4, "its height above the landing spot")
	var prev: float = pkg.shadow.diameter_units()
	assert_lt(prev, full, "smaller while high")
	for i in 6:
		drops.advance(pkg.fall_seconds / 8.0)
		assert_true(pkg.is_falling())
		var d: float = pkg.shadow.diameter_units()
		assert_almost_eq(d, ShadowSizeScript.size_for_height(full, pkg.height() / 16.0), 1e-4, "the shared curve")
		assert_gt(d, prev, "grows as it comes down")
		assert_true(d <= full, "never larger than the package")
		prev = d


func test_the_gift_packs_full_shadow_is_the_packages_width() -> void:
	var img: Image = (load("res://art/gift_pack/package.png") as Texture2D).get_image()
	assert_eq(float(img.get_used_rect().size.x), GiftDrops.PACKAGE_WIDTH_PX, "the package art's width")
	assert_almost_eq(GiftDrops.shadow_full_diameter_units() * 16.0 * sqrt(2.0), GiftDrops.PACKAGE_WIDTH_PX, 1e-4)


func test_a_gift_pack_falling_onto_a_rooftop_sizes_its_shadow_by_the_height_above_the_top() -> void:
	var pkg := _falling_package(ROOF_6)
	assert_almost_eq(pkg.shadow.surface_height, 6.0, 1e-6, "on the rooftop's top")
	assert_almost_eq(pkg.shadow.height_above, pkg.height() / 16.0, 1e-4, "above the top, not the street")


# --- Falling enemies --------------------------------------------------------

func test_a_falling_minions_shadow_sits_on_the_ground_under_it_and_grows_as_it_falls() -> void:
	_fly(STREET, 0.0)
	var m = run.minions.spawn_minion_at(STREET + Vector2(4, 0))
	var s = m.sprite
	m.fall.start(5.0)
	run.minions.update_drawing()
	assert_true(s.shows_shadow(), "a shadow while it falls")
	assert_almost_eq(s.air_height, 5.0, 1e-6)
	var pts: PackedVector2Array = s.shadow_outline()
	assert_almost_eq(_centre(pts).y, 5.0 * 16.0, 0.01, "on the ground, 5 units under the body")
	var full: float = m.radius_units() * 2.0 * 16.0 * sqrt(2.0)
	assert_almost_eq(_width(pts), ShadowSizeScript.size_for_height(full, 5.0), 0.05, "the shared curve")
	var high := _width(pts)
	m.fall.height = 1.0
	run.minions.update_drawing()
	assert_gt(_width(s.shadow_outline()), high, "larger lower down")
	assert_true(_width(s.shadow_outline()) <= full + 0.01, "never larger than its body")
	m.fall.reset()
	run.minions.update_drawing()
	assert_false(s.shows_shadow(), "none on the ground (board, 2026-10-15)")


func test_a_falling_kaijus_shadow_sits_on_the_ground_under_it_and_grows_as_it_falls() -> void:
	_fly(STREET, 0.0)
	run.kaiju_boss.enabled = true
	var k = run.kaiju_boss.appear_at(Vector2(0, 0))
	var s = k.sprite
	var full := KaijuSpriteScript.RADIUS_UNITS * 16.0 * sqrt(2.0) * 2.0
	run.kaiju_boss.update_drawing()
	assert_almost_eq(_width(s.shadow_outline()), full, 0.05, "full size standing")
	k.fall.start(6.0)
	run.kaiju_boss.update_drawing()
	assert_almost_eq(s.air_height, 6.0, 1e-6)
	var pts: PackedVector2Array = s.shadow_outline()
	assert_almost_eq(_centre(pts).y, 6.0 * 16.0, 0.01, "on the ground under its feet")
	assert_almost_eq(_width(pts), ShadowSizeScript.size_for_height(full, 6.0), 0.05, "the shared curve")
	var high := _width(pts)
	k.fall.height = 2.0
	run.kaiju_boss.update_drawing()
	assert_gt(_width(s.shadow_outline()), high, "larger lower down")


# --- Molotov bottles ------------------------------------------------------------

func test_a_thrown_bottles_shadow_lies_under_it_and_follows_its_height() -> void:
	var b = MolotovsScript.MolotovBottle.new()
	autofree(b)
	b.setup(null, Vector2.ZERO, Vector2(4, 0))
	b.age = MolotovsScript.FLIGHT_SECONDS / 2.0
	var h: float = b.height_units()
	var pts: PackedVector2Array = b.shadow_outline()
	assert_almost_eq(_centre(pts).y, h * 16.0, 0.01, "on the ground under it")
	assert_almost_eq(_width(pts),
		ShadowSizeScript.size_for_height(MolotovsScript.BOTTLE_SHADOW_DIAMETER_UNITS, h) * 16.0 * sqrt(2.0), 0.05)
	b.rotation = 1.3
	var turned: PackedVector2Array = b.shadow_outline()
	for i in pts.size():
		assert_almost_eq(turned[i].rotated(b.rotation).distance_to(pts[i]), 0.0, 1e-3, "does not spin with the bottle")
