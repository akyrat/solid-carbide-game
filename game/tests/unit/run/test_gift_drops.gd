extends GutTest
## Task T-144: the gift pack drop. A level-up sends a helicopter that crosses
## the screen and drops a package; the package lands ahead of the car on open
## road; driving over it opens the level-up screen (T-052) with T-043's
## offers. Also the board's five answers (2026-10-16), the placeholders' colours,
## the tuning data and the off-screen arrow.

const RunScene := preload("res://scenes/run/run.tscn")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const HudScript := preload("res://scripts/hud/hud.gd")
const HeliScene := preload("res://scenes/run/gift_helicopter.tscn")
const PackageScene := preload("res://scenes/run/gift_package.tscn")
const SIZES: Array[Vector2i] = [
	Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1024, 576)]
const STEP := 1.0 / 60.0

var run: Node2D
var state: RunState
var drops: GiftDrops
var data: GiftPackData


func before_each() -> void:
	FlameScript.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	_bind(run)


func after_each() -> void:
	FlameScript.playtest_override = -1
	get_tree().paused = false


func _bind(r: Node2D) -> void:
	run = r
	run.minions.enabled = false
	state = run.state
	drops = run.gift_drops
	data = drops.data


func _level_up() -> void:
	state.add_xp(state.xp_needed())


## Moves the gift pack on by hand until `done` is true or `seconds` pass.
func _advance_until(done: Callable, seconds := 10.0) -> float:
	var t := 0.0
	while t < seconds and not done.call():
		drops.advance(STEP)
		t += STEP
	return t


## Puts the car at `units`, nose along `rotation`, standing still.
func _place_car(units: Vector2, rotation: float) -> void:
	var car: Node2D = run.car
	car.model.x = units.x
	car.model.y = units.y
	car.model.rotation = rotation
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()


func _car_units() -> Vector2:
	return run.car.position / GiftDrops.PX_PER_UNIT


func _is_red(c: Color) -> bool:
	var red: Color = HudScript.HEART_COLOR
	var dist := Vector3(c.r - red.r, c.g - red.g, c.b - red.b).length()
	return dist <= 0.5 or (c.r > 0.5 and c.g < 0.4 and c.b < 0.4)


# ---- A level-up sends the helicopter instead of opening the screen ---------------------------

func test_a_level_up_no_longer_opens_the_screen_and_sends_a_helicopter() -> void:
	var levels: Array = []
	state.level_up.connect(func(l): levels.append(l))
	_level_up()
	assert_eq(levels, [2], "the level-up moment itself is unchanged")
	assert_false(run.level_up_screen.visible, "the screen does not open by itself")
	assert_false(get_tree().paused, "the run does not pause")
	assert_false(state.is_waiting_for_choice())
	assert_eq(drops.helicopters.size(), 1, "a helicopter comes")
	assert_eq(drops.packages.size(), 1, "carrying one package")
	assert_eq(drops.packages[0].phase, GiftPackage.CARRIED)
	assert_eq(drops.packages[0].level, 2)


func test_the_helicopter_crosses_the_screen_and_drops_a_package_that_lands() -> void:
	var dropped: Array = []
	var landed: Array = []
	drops.package_dropped.connect(func(p): dropped.append([p, p.height()]))
	drops.package_landed.connect(func(p): landed.append(p))
	_place_car(Vector2.ZERO, PI / 2.0)  # ahead is down the screen: room for the full drop height
	_level_up()
	var heli: GiftHelicopter = drops.helicopters[0]
	var view := drops.visible_rect()
	assert_lt(heli.from_x, view.position.x, "starts beyond the screen's left edge")
	assert_gt(heli.to_x, view.end.x, "ends beyond the screen's right edge")
	assert_lt(heli.position.x, view.position.x, "enters from out of sight")
	var pkg: GiftPackage = drops.packages[0]
	var t_drop := _advance_until(func(): return not dropped.is_empty())
	assert_eq(dropped.size(), 1, "it drops the package")
	assert_almost_eq(heli.position.x, heli.drop_x, heli.speed * STEP + 0.01, "over the landing spot")
	assert_almost_eq(t_drop, (heli.drop_x - heli.from_x) / data.helicopter_speed(), STEP * 2.0,
			"flies at gift_pack.json's speed")
	assert_almost_eq(dropped[0][1], maxf(data.drop_height() - data.hang_below_px(), data.min_fall()), 0.01,
			"falls from under the helicopter, which flies drop_height_px above the ground")
	assert_almost_eq(pkg.drawn_ground.y - heli.position.y, data.drop_height(), 0.01)
	var t_fall := _advance_until(func(): return not landed.is_empty())
	assert_eq(landed, [pkg], "the package lands")
	assert_almost_eq(t_fall, data.fall_seconds(), STEP * 2.0, "after gift_pack.json's fall time")
	assert_true(pkg.is_landed())
	assert_eq(pkg.position, pkg.drawn_ground, "on the map at its landing spot")
	assert_eq(pkg.drawn_ground, GiftDrops.ISO_TRANSFORM * pkg.ground_px)
	_advance_until(func(): return drops.helicopters.is_empty())
	assert_true(drops.helicopters.is_empty(), "the helicopter flies on out of the screen and goes")
	assert_true(pkg.is_landed() and drops.packages.has(pkg), "the package stays")


func test_the_carried_package_hangs_under_the_helicopter_then_falls_straight_down() -> void:
	_level_up()
	var heli: GiftHelicopter = drops.helicopters[0]
	var pkg: GiftPackage = drops.packages[0]
	drops.advance(STEP)
	assert_eq(pkg.position, heli.position + drops.carry_offset())
	_advance_until(func(): return pkg.is_falling())
	var x := pkg.position.x
	var h := pkg.height()
	drops.advance(data.fall_seconds() * 0.5)
	assert_eq(pkg.position.x, x, "straight down")
	assert_lt(pkg.height(), h, "lower")
	assert_gt(pkg.height(), 0.0, "not yet down")


## The opaque part of a sprite's current frame, in its node's drawn pixels.
func _art_rect(s: Sprite2D) -> Rect2:
	var img := s.texture.get_image()
	var fw := img.get_width() / s.hframes
	var used := img.get_region(Rect2i(fw * s.frame, 0, fw, img.get_height())).get_used_rect()
	var frame := s.get_rect()  # the whole frame, centred plus offset
	return Rect2(s.position + (frame.position + Vector2(used.position)) * s.scale, Vector2(used.size) * s.scale)


## T-144 layout fix with the final art (T-145, T-146): at the default zoom and
## at the board's saved zoom (about 2.4), whichever way the car heads, the
## helicopter is fully on screen with screen_margin_px to spare while it
## carries the package, the package hangs clearly below its belly, and the
## package falls under its parachute for fall_seconds, at least min_fall_px
## when the screen has room for it, never with the parachute above the screen.
func test_drop_layout_with_the_final_art_at_the_default_and_the_boards_zoom() -> void:
	for zoom in [2.44, 0.0]:
		_run_at(SIZES[0])
		await wait_process_frames(2)
		if zoom > 0.0:
			run.set_zoom(648.0 / (2.0 * zoom * 16.0))  # Godot zoom 2.44, as the board's saved camera
		await wait_process_frames(1)
		for i in 8:
			var heading := TAU * i / 8.0
			_place_car(Vector2.ZERO, heading)
			drops.send_helicopter(2)
			var heli: GiftHelicopter = drops.helicopters.back()
			var pkg: GiftPackage = drops.packages.back()
			var where := "zoom %s heading %d" % [zoom, i]
			var heli_art := _art_rect(heli.sprite())
			var box := _art_rect(pkg.sprite())
			assert_gt(box.position.y + drops.carry_offset().y, heli_art.end.y + 4.0,
					where + ": the box hangs clearly below the belly")
			var steps := 0
			while not pkg.is_falling() and steps < 2000:
				var view := drops.visible_rect()
				if heli.position.x > view.position.x + heli_art.size.x and heli.position.x < view.end.x - heli_art.size.x:
					assert_gte(heli.position.y + heli_art.position.y, view.position.y + data.screen_margin() - 0.01,
							where + ": the helicopter's top is on screen")
				drops.advance(STEP)
				steps += 1
			assert_true(pkg.is_falling(), where + ": dropped")
			var view_now := drops.visible_rect()
			var canopy_top := pkg.position.y - drops.art_height(pkg.sprite())
			var room := pkg.drawn_ground.y - (view_now.position.y + data.screen_margin() + drops.art_height(pkg.sprite()))
			if room >= data.min_fall():
				assert_gte(pkg.drop_height, data.min_fall() - 0.01, where + ": a fall long enough to see")
			if room >= 0.0:
				assert_gte(canopy_top, view_now.position.y + data.screen_margin() - 0.01, where + ": the parachute's top on screen")
			else:
				assert_eq(pkg.drop_height, 0.0, where + ": no room above: lands in place, parachute still shown")
			assert_eq(pkg.sprite().texture.resource_path, GiftPackage.FALLING_ART, where + ": under the parachute")
			var t := 0.0
			while pkg.is_falling() and t < 10.0:
				drops.advance(STEP)
				t += STEP
			assert_almost_eq(t, data.fall_seconds(), STEP * 2.0, where + ": the parachute shows for fall_seconds")
			assert_true(pkg.is_landed())
			assert_eq(pkg.sprite().texture.resource_path, GiftPackage.GROUND_ART, where + ": the box on the ground")
			drops.clear()


# ---- Driving over the package opens the level-up screen --------------------------------------

func test_driving_over_the_landed_package_removes_it_and_opens_the_screen() -> void:
	_level_up()
	drops.land_all()
	var pkg: GiftPackage = drops.packages[0]
	var expected: Array = run.weapons.offers.compute_offers()
	assert_eq(expected, ["upgrade_gun", "get_flamethrower"], "T-043's first offers")
	var picked: Array = []
	drops.package_picked_up.connect(func(p): picked.append(p))
	drops.check_pickups()
	assert_true(picked.is_empty(), "not picked up while the car is away from it")
	_place_car(pkg.ground_units() + Vector2(data.pickup_radius_units() * 0.5, 0.0), 0.0)
	drops.check_pickups()
	assert_eq(picked, [pkg], "picked up when the car overlaps it")
	assert_true(drops.packages.is_empty(), "removed")
	assert_true(pkg.is_queued_for_deletion(), "gone from the map")
	assert_true(run.level_up_screen.visible, "the level-up screen opens")
	var ids: Array = run.level_up_screen.cards.map(func(c): return c.id)
	assert_eq(ids, expected, "with the same offers as before")
	assert_true(get_tree().paused, "the run pauses")
	assert_eq(state.choice_level(), 2)
	run.level_up_screen.skip_animation()
	run.level_up_screen.take("get_flamethrower")
	assert_eq(run.weapons.flamethrower.tier, 1, "the choice works as before")
	assert_false(run.level_up_screen.visible)
	assert_false(get_tree().paused, "the run resumes")


func test_the_car_really_drives_over_it() -> void:
	_level_up()
	drops.land_all()
	var pkg: GiftPackage = drops.packages[0]
	assert_almost_eq(_car_units().distance_to(pkg.ground_units()), data.land_ahead_units(), 0.01,
			"straight ahead at the start (open gravel)")
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 0.0]  # straight ahead
	var frames := 0
	while frames < 600 and not run.level_up_screen.visible:
		await wait_physics_frames(1)
		frames += 1
	assert_true(run.level_up_screen.visible, "driving onto the package opens the screen")
	assert_true(get_tree().paused)
	assert_true(drops.packages.is_empty())


func test_pickup_needs_the_package_to_have_landed() -> void:
	_level_up()
	var pkg: GiftPackage = drops.packages[0]
	_place_car(pkg.ground_units(), 0.0)
	drops.check_pickups()
	assert_false(run.level_up_screen.visible, "a package in the air is not picked up")
	assert_eq(drops.packages.size(), 1)


# ---- Answer 1: the run keeps going until the screen opens ------------------------------------

func test_answer_1_the_run_keeps_going_while_the_helicopter_comes_and_the_package_waits() -> void:
	_level_up()
	state.add_xp(state.xp_needed() * 0.5)
	var before := state.time_left
	await wait_process_frames(10)
	assert_lt(state.time_left, before, "the clock runs while the helicopter comes")
	assert_true(drops.can_process(), "the gift pack moves with the run")
	drops.land_all()
	assert_true(state.has_no_combo())
	assert_true(state.is_likes_draining(), "the drain runs while the package waits")
	var xp := state.xp
	state.advance(0.5)
	assert_lt(state.xp, xp)
	var t := state.time_left
	await wait_process_frames(5)
	assert_lt(state.time_left, t, "the clock runs while the package waits")
	drops.pick_up_all()
	assert_true(get_tree().paused, "the run pauses only when the screen opens")
	assert_false(drops.can_process(), "the gift pack stands still while paused")


func test_paused_run_freezes_helicopters_and_packages() -> void:
	_level_up()
	get_tree().paused = true
	assert_false(drops.can_process(), "pause screen: nothing moves")
	get_tree().paused = false
	assert_true(drops.can_process())


# ---- Answer 2: a short way ahead of the car, on open road ------------------------------------

func test_answer_2_lands_a_short_way_ahead_of_the_car() -> void:
	_place_car(Vector2.ZERO, -PI / 2.0)
	var spot := drops.landing_spot()
	assert_almost_eq(spot.distance_to(Vector2.ZERO), data.land_ahead_units(), 0.001)
	assert_almost_eq(spot.angle(), -PI / 2.0, 0.001, "ahead of the nose")
	assert_true(run.map.is_open_spot(spot, data.clearance_units()))


func test_answer_2_ahead_follows_the_way_the_car_moves() -> void:
	_place_car(Vector2.ZERO, 0.0)
	run.car.velocity = Vector2(0, 100)  # sliding along +y, nose along +x
	var spot := drops.landing_spot()
	assert_almost_eq(spot.normalized().dot(Vector2(0, 1)), 1.0, 0.001, "along the motion")


func test_answer_2_never_inside_a_building() -> void:
	var b: Dictionary = run.map.layout.buildings[0]
	var r := Rect2(float(b.x), float(b.y), float(b.w), float(b.h))
	var car_at := Vector2(r.position.x - 3.0, r.get_center().y)
	_place_car(car_at, 0.0)  # facing the building
	var straight := car_at + Vector2(data.land_ahead_units(), 0)
	assert_true(r.has_point(straight), "straight ahead is inside the building")
	var spot := drops.landing_spot()
	assert_false(r.grow(data.clearance_units() - 0.001).has_point(spot), "not in or touching the building")
	assert_true(run.map.is_open_spot(spot, data.clearance_units()), "on open road")


func test_answer_2_never_inside_a_boulder() -> void:
	var boulder: Dictionary = run.map.all_boulders()[0]
	var c := Vector2(float(boulder.x), float(boulder.y))
	# Stand a landing distance behind the boulder, facing it.
	var dir := Vector2.RIGHT
	var car_at := c - dir * data.land_ahead_units()
	for k in 8:
		if run.map.is_open_spot(car_at, 1.0):
			break
		dir = dir.rotated(PI / 4.0)
		car_at = c - dir * data.land_ahead_units()
	_place_car(car_at, dir.angle())
	assert_false(run.map.is_open_spot(car_at + dir * data.land_ahead_units(), data.clearance_units()),
			"straight ahead is the boulder")
	var spot := drops.landing_spot()
	assert_gt(spot.distance_to(c), float(boulder.diameter) / 2.0 + data.clearance_units() - 0.001, "clear of the boulder")
	assert_true(run.map.is_open_spot(spot, data.clearance_units()))


func test_answer_2_always_open_road_all_over_the_map() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 144
	var checked := 0
	while checked < 150:
		var p := Vector2(rng.randf_range(-118, 118), rng.randf_range(-118, 118))
		if not run.map.is_open_spot(p, 1.5):
			continue  # the car is never inside a building
		_place_car(p, rng.randf_range(-PI, PI))
		var spot := drops.landing_spot()
		assert_true(run.map.is_open_spot(spot, data.clearance_units()), "open road at %s from %s" % [spot, p])
		assert_lte(spot.distance_to(p), data.land_ahead_units() * 1.5 + 0.001, "a short way from the car")
		checked += 1


func test_map_open_spot_check() -> void:
	assert_true(run.map.is_open_spot(Vector2.ZERO, 1.0), "the gravel square")
	var b: Dictionary = run.map.layout.buildings[0]
	assert_false(run.map.is_open_spot(Vector2(float(b.x) + 5.0, float(b.y) + 5.0), 1.0), "inside a building")
	assert_false(run.map.is_open_spot(Vector2(119.5, 0.0), 1.0), "over the map's edge")


# ---- Answer 3: one package per level-up ------------------------------------------------------

func test_answer_3_several_level_ups_give_several_packages_each_with_its_own_screen() -> void:
	state.add_xp(state.xp_needed() + RunData.new().xp_needed(2) + 1.0)  # two level-ups at once
	assert_eq(state.level, 3)
	assert_eq(drops.helicopters.size(), 2, "one helicopter per level-up")
	assert_eq(drops.packages.size(), 2, "one package per level-up")
	assert_eq(drops.packages.map(func(p): return p.level), [2, 3])
	drops.land_all()
	var first: GiftPackage = drops.packages[0]
	var second: GiftPackage = drops.packages[1]
	drops.pick_up(first)
	assert_true(run.level_up_screen.visible, "the first package opens a screen")
	assert_eq(state.choice_level(), 2)
	run.level_up_screen.skip_animation()
	run.level_up_screen.take_highlighted()
	assert_false(run.level_up_screen.visible, "one screen for one package")
	assert_false(get_tree().paused)
	assert_eq(drops.packages, [second], "the other package still waits")
	drops.pick_up(second)
	assert_true(run.level_up_screen.visible, "the second package opens its own screen")
	assert_eq(state.choice_level(), 3)
	run.level_up_screen.skip_animation()
	run.level_up_screen.take_highlighted()
	assert_false(get_tree().paused)


func test_answer_3_two_packages_picked_up_together_show_two_screens_in_turn() -> void:
	state.add_xp(state.xp_needed() + RunData.new().xp_needed(2) + 1.0)
	drops.pick_up_all()
	assert_eq(state.pending_choices.size(), 2)
	run.level_up_screen.skip_animation()
	run.level_up_screen.take_highlighted()
	assert_true(run.level_up_screen.visible, "the next screen")
	assert_true(get_tree().paused)
	run.level_up_screen.skip_animation()
	run.level_up_screen.take_highlighted()
	assert_false(get_tree().paused)


# ---- Answer 4: the package stays until picked up ---------------------------------------------

func test_answer_4_the_package_stays_until_picked_up() -> void:
	_level_up()
	drops.land_all()
	var pkg: GiftPackage = drops.packages[0]
	for i in 120:
		drops.advance(1.0)
		state.advance(1.0)
	assert_true(is_instance_valid(pkg) and pkg.is_landed(), "still there two minutes later")
	assert_eq(drops.landed_packages(), [pkg])


func test_a_new_run_clears_helicopters_and_packages() -> void:
	_level_up()
	_level_up()
	drops.land_all()
	assert_gt(drops.packages.size(), 0)
	run.start_run()
	assert_true(drops.packages.is_empty())
	assert_true(drops.helicopters.is_empty())


func test_nothing_moves_or_is_picked_up_after_the_run_ends() -> void:
	_level_up()
	drops.land_all()
	var pkg: GiftPackage = drops.packages[0]
	state.damage_car(state.health)
	assert_false(state.is_running())
	_place_car(pkg.ground_units(), 0.0)
	drops.advance(STEP)
	assert_false(run.level_up_screen.visible)


func test_the_old_switch_still_opens_the_screen_at_once_without_a_helicopter() -> void:
	state.pause_on_level_up = true
	_level_up()
	assert_true(drops.helicopters.is_empty())
	assert_true(run.level_up_screen.visible)


# ---- Answer 5: an arrow points to an off-screen package --------------------------------------

func _screen(size: Vector2i) -> SubViewport:
	var sv := SubViewport.new()
	sv.size = size
	add_child_autofree(sv)
	return sv


func _run_at(size: Vector2i) -> void:
	var r: Node2D = RunScene.instantiate()
	_screen(size).add_child(r)
	_bind(r)


## A landed package whose drawing sits `drawn_offset` drawn pixels from the camera.
func _package_at_drawn(drawn_offset: Vector2) -> GiftPackage:
	drops.send_helicopter(2)
	drops.land_all()
	var pkg: GiftPackage = drops.packages.back()
	var drawn: Vector2 = run.camera.get_screen_center_position() + drawn_offset
	pkg.drawn_ground = drawn
	pkg.ground_px = GiftDrops.ISO_TRANSFORM.affine_inverse() * drawn
	pkg.position = drawn
	return pkg


func _hud_parts(hud: Hud) -> Dictionary:
	return {
		"health bar": hud.health_bar.get_global_rect(),
		"likes bar": hud.likes_bar.get_global_rect(),
		"health heart": hud.health_heart.get_global_rect(),
		"weapon icons": hud.weapon_icons.get_global_rect(),
		"heart": hud.heart.get_global_rect(),
		"Likes": hud.likes_label.get_global_rect(),
		"Hype Lv": hud.level_label.get_global_rect(),
		"combo": hud.combo_label.get_global_rect(),
		"timer": hud.timer_label.get_global_rect(),
		"coins": hud.coins_label.get_parent().get_global_rect(),
		"fire": hud.likes_fire.get_global_rect(),
	}


func test_answer_5_an_arrow_shows_only_while_the_landed_package_is_off_screen() -> void:
	_run_at(SIZES[0])
	await wait_process_frames(2)
	_level_up()
	var arrows: GiftArrows = drops.arrows
	arrows.refresh()
	assert_true(arrows.shown.is_empty(), "no arrow for a package still in the air")
	drops.land_all()
	var pkg: GiftPackage = drops.packages[0]
	arrows.refresh()
	assert_true(arrows.shown.is_empty(), "no arrow while the package is on screen")
	pkg.position = run.camera.get_screen_center_position() + Vector2(3000, 0)
	arrows.refresh()
	assert_eq(arrows.shown.size(), 1, "an arrow once it is off screen")
	var a: Dictionary = arrows.shown[0]
	var screen := Vector2(SIZES[0])
	assert_true(Rect2(Vector2.ZERO, screen).encloses(GiftArrows.arrow_rect(a.position)), "at the screen's edge, inside it")
	assert_gt(a.position.x, screen.x * 0.75, "at the right edge for a package to the right")
	var target: Vector2 = pkg.get_global_transform_with_canvas().origin
	assert_almost_eq(Vector2.from_angle(a.angle).dot((target - a.position).normalized()), 1.0, 0.001, "points to it")
	drops.pick_up(pkg)
	arrows.refresh()
	assert_true(arrows.shown.is_empty(), "gone once picked up")


func test_answer_5_one_arrow_per_off_screen_package() -> void:
	_run_at(SIZES[0])
	await wait_process_frames(2)
	_package_at_drawn(Vector2(4000, 0))
	_package_at_drawn(Vector2(-4000, 0))
	drops.arrows.refresh()
	assert_eq(drops.arrows.shown.size(), 2)


func test_answer_5_arrows_stay_clear_of_the_hud_at_every_window_size() -> void:
	for size in SIZES:
		_run_at(size)
		await wait_process_frames(2)
		var parts := _hud_parts(run.hud)
		var screen := Vector2(size)
		for i in 32:
			var dir := Vector2.from_angle(TAU * i / 32.0)
			var pkg := _package_at_drawn(dir * 5000.0)
			drops.arrows.refresh()
			var mine: Array = drops.arrows.shown.filter(func(a): return a.package == pkg)
			assert_eq(mine.size(), 1, "%s dir %d: an arrow" % [size, i])
			var box := GiftArrows.arrow_rect(mine[0].position)
			assert_true(Rect2(Vector2.ZERO, screen).encloses(box), "%s dir %d: on screen" % [size, i])
			for n in parts:
				assert_false(box.intersects(parts[n]), "%s dir %d: clear of %s" % [size, i, n])
			drops.packages.erase(pkg)
			pkg.free()


func test_answer_5_arrow_placement_slides_off_a_hud_part() -> void:
	var screen := Vector2(1000, 600)
	var straight := GiftArrows.place(screen, Vector2(2000, 300), [])
	assert_almost_eq(straight.position.y, 300.0, 0.01, "straight right, mid-height")
	var blocker := Rect2(Vector2(900, 250), Vector2(100, 100))
	var slid := GiftArrows.place(screen, Vector2(2000, 300), [blocker])
	assert_false(GiftArrows.arrow_rect(slid.position).intersects(blocker.grow(GiftArrows.GAP)))
	assert_gt(slid.position.x, 900.0, "still on the right edge")
	assert_true(GiftArrows.place(screen, Vector2(500, 300), []).is_empty(), "on screen: no arrow")


func test_answer_5_arrow_colours_are_not_red() -> void:
	assert_false(_is_red(GiftArrows.FILL))
	assert_false(_is_red(GiftArrows.OUTLINE))
	assert_gt(GiftArrows.LAYER, 10, "over the HUD (layer 10)")
	assert_lt(GiftArrows.LAYER, LevelUpScreen.LAYER, "under the level-up screen")


# ---- Placeholders and data -------------------------------------------------------------------

func _assert_not_red(tex: Texture2D, what: String) -> void:
	var img := tex.get_image()
	var opaque := 0
	var reds := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			opaque += 1
			if _is_red(c):
				reds += 1
	assert_gt(opaque, 0, what + " has pixels")
	assert_eq(reds, 0, what + ": no Redgull red, no red")


func test_final_art_sprites_are_not_tinted() -> void:
	var heli: GiftHelicopter = HeliScene.instantiate()
	var pkg: GiftPackage = PackageScene.instantiate()
	autofree(heli)
	autofree(pkg)
	# T-145 and T-146: both are final Redgull art now, so red is allowed on them;
	# the placeholders keep their no-red check (build_gift_placeholders.py).
	_assert_not_red(load("res://art/gift_pack/helicopter_placeholder.png"), "helicopter placeholder")
	_assert_not_red(load("res://art/gift_pack/package_placeholder.png"), "package placeholder")
	assert_eq(heli.sprite().modulate, Color.WHITE)
	assert_eq(pkg.sprite().modulate, Color.WHITE)


func test_one_named_sprite_each_for_the_art_swap() -> void:
	var heli: GiftHelicopter = HeliScene.instantiate()
	var pkg: GiftPackage = PackageScene.instantiate()
	autofree(heli)
	autofree(pkg)
	assert_eq(heli.sprite().texture.resource_path, "res://art/gift_pack/helicopter_sheet.png")
	assert_eq(pkg.sprite().texture.resource_path, "res://art/gift_pack/package.png")
	assert_eq(heli.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_eq(pkg.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	var sprites := 0
	for n in heli.get_children() + pkg.get_children():
		if n is Sprite2D:
			sprites += 1
	assert_eq(sprites, 2, "one sprite in each scene")


func test_tuning_numbers_come_from_the_data_file() -> void:
	var r := GameData.load_file("gift_pack")
	assert_true(r.ok, r.error)
	var d := GiftPackData.new()
	assert_true(d.is_ok(), d.error)
	assert_eq(d.helicopter_speed(), float(r.data.helicopter.speed_px_per_second))
	assert_eq(d.drop_height(), float(r.data.helicopter.drop_height_px))
	assert_eq(d.offscreen_margin(), float(r.data.helicopter.offscreen_margin_px))
	assert_eq(d.screen_margin(), float(r.data.helicopter.screen_margin_px))
	assert_eq(d.hang_below_px(), float(r.data.package.hang_below_px))
	assert_eq(d.min_fall(), float(r.data.package.min_fall_px))
	assert_eq(d.fall_seconds(), float(r.data.package.fall_seconds))
	assert_eq(d.land_ahead_units(), float(r.data.package.land_ahead_units))
	assert_eq(d.clearance_units(), float(r.data.package.clearance_units))
	assert_eq(d.pickup_radius_units(), float(r.data.package.pickup_radius_units))
	for v in [d.helicopter_speed(), d.drop_height(), d.fall_seconds(), d.land_ahead_units(), d.pickup_radius_units()]:
		assert_gt(v, 0.0)


func test_the_run_uses_whatever_the_data_file_says() -> void:
	var path := RunPaths.file("gift_pack_t144.json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"helicopter": {"speed_px_per_second": 300, "drop_height_px": 77, "screen_margin_px": 5, "offscreen_margin_px": 33},
		"package": {"hang_below_px": 20, "fall_seconds": 1.25, "min_fall_px": 10, "land_ahead_units": 9, "clearance_units": 0.5, "pickup_radius_units": 3}}))
	f.close()
	drops.data = GiftPackData.new(path)
	assert_true(drops.data.is_ok(), drops.data.error)
	_place_car(Vector2.ZERO, -PI / 2.0)
	_level_up()
	var heli: GiftHelicopter = drops.helicopters[0]
	var pkg: GiftPackage = drops.packages[0]
	assert_eq(heli.speed, 300.0)
	assert_almost_eq(pkg.drawn_ground.y - heli.position.y, 77.0, 0.001)
	assert_almost_eq(drops.visible_rect().position.x - heli.from_x, 33.0 + maxf(0.0, drops.visible_rect().get_center().x - pkg.drawn_ground.x), 0.01)
	assert_eq(pkg.fall_seconds, 1.25)
	assert_eq(pkg.position, heli.position + Vector2(0, 20), "hangs hang_below_px under it")
	_advance_until(func(): return pkg.is_falling())
	assert_almost_eq(pkg.drop_height, 57.0, 0.001, "drop_height_px - hang_below_px")
	assert_almost_eq(pkg.ground_units().distance_to(Vector2.ZERO), 9.0, 0.001)
	drops.land_all()
	_place_car(pkg.ground_units() + Vector2(2.9, 0), 0.0)
	drops.check_pickups()
	assert_true(run.level_up_screen.visible, "picked up within the file's radius")
	DirAccess.remove_absolute(path)


func test_helicopter_art_is_redgull_red_with_rotor_frames() -> void:
	var heli: GiftHelicopter = HeliScene.instantiate()
	autofree(heli)
	var s := heli.sprite()
	assert_eq(s.hframes, 4, "four rotor frames")
	var img := s.texture.get_image()
	assert_eq(img.get_width(), 192 * 4)
	var logo_red := 0
	for y in img.get_height():
		for x in 192:
			var c := img.get_pixel(x, y)
			if c.a > 0 and absf(c.r8 - 135) + absf(c.g8 - 17) + absf(c.b8 - 27) < 3:
				logo_red += 1
	assert_gt(logo_red, 100, "the Redgull red and the logo are on the helicopter")
	var before := s.frame
	heli._process(0.1)
	assert_ne(s.frame, before, "the rotor turns")


func test_package_uses_the_parachute_look_only_while_falling() -> void:
	var pkg: GiftPackage = PackageScene.instantiate()
	add_child_autofree(pkg)
	pkg.phase = GiftPackage.CARRIED
	pkg.refresh_look()
	assert_eq(pkg.sprite().texture.resource_path, GiftPackage.GROUND_ART)
	pkg.phase = GiftPackage.FALLING
	pkg.refresh_look()
	assert_eq(pkg.sprite().texture.resource_path, GiftPackage.FALLING_ART)
	pkg.phase = GiftPackage.LANDED
	pkg.refresh_look()
	assert_eq(pkg.sprite().texture.resource_path, GiftPackage.GROUND_ART)
