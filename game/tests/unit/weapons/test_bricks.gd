extends GutTest
## Task T-324: Bricks. Each time the car lands after at least min_air_seconds in
## the air, one impact wave: every enemy whose body is within the radius takes
## the damage once (the kaiju too), minions are pushed away, nothing outside is
## touched. A shorter hop sends none. The same wave whatever the height. Tiers,
## the garage bonus, the cooldown, a new run, the placeholder drawing, and the
## car's handling left alone.

const RunScene := preload("res://scenes/run/run.tscn")
const FakeEnemy := preload("res://tests/fixtures/weapons/fake_enemy.gd")
const FakeMinion := preload("res://tests/fixtures/weapons/fake_minion.gd")
const Bricks := preload("res://scripts/weapons/bricks.gd")
const Wiper := preload("res://scripts/weapons/windshield_wiper.gd")
const Flame := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const Glow := preload("res://scripts/weapons/neon_underglow.gd")
const Molotovs := preload("res://scripts/weapons/molotovs.gd")
const DT := 0.02  # one physics step (50 per second)
## Greenbull's three colours (Visual style, Content, "Rules", rule 6) and the
## check script's distance (game/tools/check_sprite_rules.py GREENBULL_MAX_DIST).
const GREENBULL := [Color8(12, 76, 44), Color8(104, 220, 96), Color8(247, 208, 52)]
const GREENBULL_MAX_DIST := 25.0

var run: Node2D
var rack: Node
var bricks
var data: WeaponData


func before_each() -> void:
	for s in [Bricks, Wiper, Flame, Glow, Molotovs]:
		s.playtest_override = 0
	data = WeaponData.new()
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
	rack = run.weapons
	rack.gun.set_tier(0)  # the gun's bullets would hit the test enemies too
	bricks = rack.bricks


func after_each() -> void:
	for s in [Bricks, Wiper, Flame, Glow, Molotovs]:
		s.playtest_override = -1
	rack.set_damage_bonus(0.0)
	get_tree().paused = false


## A test enemy at `units` (flat world).
func _place(e: Node2D, units: Vector2) -> Node2D:
	e.position = units * 16.0
	run.add_child(e)
	return e


func _car() -> Vector2:
	return run.car.model.get_position()


## A staged airtime: the car is marked in the air for `seconds`, the rack
## stepping, then put back on the ground for one more step (the landing).
func _air(seconds: float) -> void:
	run.car.height_model.airborne = true
	for i in roundi(seconds / DT):
		rack.step(DT)
	run.car.height_model.airborne = false
	rack.step(DT)


## A real drop: the car is lifted `lift` units over the ground where it stands
## and falls under the car's own gravity (car_height.gd), the car and the rack
## stepping together. Returns the steps it was in the air.
func _drop(lift: float) -> int:
	var car = run.car
	assert_not_null(car.ground, "the run's map gives the car a ground height")
	car.height_model.height = car.height + lift
	car.height_model.airborne = true
	var steps := 0
	while car.airborne and steps < 500:
		car.physics_step()
		rack.step(DT)
		steps += 1
	rack.step(DT)
	return steps


# --- Owning it ---------------------------------------------------------------------

func test_a_new_run_has_no_bricks_and_upgrade_gives_it() -> void:
	assert_true(Bricks in rack.WEAPON_SCRIPTS, "listed in WEAPON_SCRIPTS")
	assert_eq(rack.get_weapon("bricks"), bricks)
	assert_eq(bricks.weapon_id, "bricks")
	assert_false(bricks.starts_owned)
	assert_eq(bricks.tier, 0, "not owned at the start of a run")
	var e := _place(FakeMinion.new(), _car() + Vector2(1.0, 0.0))
	_air(1.0)
	assert_eq(e.damage_taken.size(), 0, "not owned: no wave")
	assert_eq(bricks.waves, 0)
	assert_true(rack.upgrade("bricks"), "the level-up's call gives it")
	assert_eq(bricks.tier, 1)
	assert_true("bricks" in rack.owned_ids())


func test_the_tiers_are_the_boards_numbers() -> void:
	for t in range(1, 8):
		bricks.set_tier(t)
		var want: Dictionary = data.bricks_at(t)
		for k in want:
			assert_eq(bricks.stats[k], want[k], "tier %d %s" % [t, k])
	assert_almost_eq(float(data.bricks_at(1)["radius"]), 4.0, 1e-9)
	assert_almost_eq(float(data.bricks_at(7)["damage"]), 13.5, 1e-9)


# --- The wave ------------------------------------------------------------------------

func test_a_landing_hits_every_enemy_in_the_radius_once_and_none_outside() -> void:
	rack.upgrade("bricks")
	var r: float = bricks.radius()
	var c := _car()
	var near := _place(FakeEnemy.new(), c + Vector2(1.0, 0.5))
	var at_edge := _place(FakeEnemy.new(), c + Vector2(0.0, -(r - 0.1)))
	var big := _place(FakeMinion.new(), c + Vector2(-(r + 2.5), 0.0))
	big.as_kaiju(3.0)  # its centre is outside, its body reaches in: hit
	var outside := _place(FakeEnemy.new(), c + Vector2(r + 1.0, 0.0))
	var far := _place(FakeEnemy.new(), c + Vector2(0.0, r * 3.0))
	var sent := []
	bricks.wave_sent.connect(func(at: Vector2, n: int) -> void: sent.append([at, n]))
	_air(0.5)
	assert_eq(sent.size(), 1, "one wave")
	assert_true(sent[0][0].is_equal_approx(c), "at the landing spot")
	assert_eq(sent[0][1], 3)
	for e in [near, at_edge, big]:
		assert_eq(e.damage_taken, [6.0], "hit once for T-323's damage")
	for e in [outside, far]:
		assert_eq(e.damage_taken.size(), 0, "outside the radius: untouched")
	# The steps after the landing send nothing more.
	for i in 100:
		rack.step(DT)
	assert_eq(sent.size(), 1)
	assert_eq(near.damage_taken.size(), 1)


func test_the_reach_counts_the_enemys_body() -> void:
	rack.upgrade("bricks")
	var r: float = bricks.radius()
	var c := _car()
	# FakeMinion's body is 0.5 units: its edge is inside at r + 0.4, outside at r + 0.6.
	var in_m := _place(FakeMinion.new(), c + Vector2(r + 0.4, 0.0))
	var out_m := _place(FakeMinion.new(), c + Vector2(-(r + 0.6), 0.0))
	_air(0.5)
	assert_eq(in_m.damage_taken.size(), 1)
	assert_eq(out_m.damage_taken.size(), 0)


func test_a_short_hop_sends_no_wave() -> void:
	rack.upgrade("bricks")
	var e := _place(FakeEnemy.new(), _car() + Vector2(1.0, 0.0))
	var min_air: float = bricks.stats["min_air_seconds"]
	assert_almost_eq(min_air, 0.3, 1e-9)
	_air(min_air - 2.0 * DT)
	assert_eq(bricks.waves, 0, "under the minimum: no wave")
	assert_eq(e.damage_taken.size(), 0)
	_air(min_air)
	assert_eq(bricks.waves, 1, "at the minimum: a wave")


func test_a_real_low_drop_sends_none_and_a_real_jump_sends_one() -> void:
	rack.upgrade("bricks")
	var e := _place(FakeEnemy.new(), _car() + Vector2(1.5, 0.0))
	var steps := _drop(0.3)  # about 0.22 s in the air under the car's gravity
	assert_lt(steps * DT, 0.3, "a hop shorter than the minimum")
	assert_eq(bricks.waves, 0)
	for i in 40:
		rack.step(DT)
	steps = _drop(2.0)  # about 0.58 s
	assert_gt(steps * DT, 0.3)
	assert_eq(bricks.waves, 1, "the landing sends one wave")
	assert_eq(e.damage_taken.size(), 1)


func test_the_wave_is_the_same_after_a_short_and_a_tall_drop() -> void:
	rack.upgrade("bricks")
	var results := []
	for lift in [1.0, 8.0]:
		var c := _car()
		var es := []
		for p in [Vector2(1.0, 0.0), Vector2(0.0, 2.5), Vector2(-3.5, 0.0), Vector2(0.0, -6.0)]:
			es.append(_place(FakeMinion.new(), c + p))
		var hit := []
		bricks.enemy_hit.connect(func(e: Node, amount: float, pushed: bool) -> void:
			hit.append([es.find(e), amount, pushed]))
		var steps := _drop(lift)
		var pushes := []
		for e in es:
			pushes.append(e.pushes.duplicate())
		results.append({"steps": steps, "hit": hit, "pushes": pushes, "radius": bricks.last_wave.radius})
		for e in es:
			e.queue_free()
		for conn in bricks.enemy_hit.get_connections():
			bricks.enemy_hit.disconnect(conn.callable)
		for i in 40:
			rack.step(DT)
		await wait_physics_frames(1)
	assert_gt(results[1].steps, results[0].steps * 2, "the tall drop is much longer in the air")
	assert_eq(results[0].hit, results[1].hit, "the same enemies, damage and pushes")
	assert_eq(results[0].hit.size(), 3)
	assert_eq(results[0].pushes, results[1].pushes)
	assert_eq(results[0].radius, results[1].radius, "the same wave drawn")


func test_minions_are_pushed_away_and_the_kaiju_never() -> void:
	rack.upgrade("bricks")
	var c := _car()
	var minion := _place(FakeMinion.new(), c + Vector2(2.0, 0.0))
	var kaiju := _place(FakeMinion.new(), c + Vector2(0.0, 3.0))
	kaiju.as_kaiju(2.0)
	var other := _place(FakeEnemy.new(), c + Vector2(-2.0, 0.0))
	_air(0.5)
	assert_eq(minion.pushes.size(), 1)
	assert_true(minion.pushes[0][0].is_equal_approx(Vector2(1.0, 0.0)), "straight away from the car")
	assert_almost_eq(float(minion.pushes[0][1]), 4.0, 1e-9, "T-323's knockback")
	assert_eq(kaiju.damage_taken.size(), 1, "the kaiju is hit")
	assert_eq(kaiju.pushes.size(), 0, "but never pushed")
	assert_eq(other.damage_taken.size(), 1)
	# A minion the wave kills is not pushed.
	var weak := _place(FakeMinion.new(), c + Vector2(1.0, 1.0))
	weak.health = 3.0
	for i in 40:
		rack.step(DT)
	_air(0.5)
	assert_true(weak.is_dead())
	assert_eq(weak.pushes.size(), 0)


func test_two_landings_within_the_cooldown_send_one_wave() -> void:
	rack.upgrade("bricks")
	var e := _place(FakeEnemy.new(), _car() + Vector2(1.0, 0.0))
	_air(0.4)
	assert_eq(bricks.waves, 1)
	# A bounce: any real airtime of 0.3 s or more is past the 0.5 s cooldown only
	# with time on the ground, so the landing right after the wave is staged.
	assert_false(bricks.on_landing(1.0), "a landing 0.02 s after the wave sends none")
	for i in 30:
		rack.step(DT)
	assert_true(bricks.on_landing(1.0), "past the cooldown it does")
	assert_eq(e.damage_taken.size(), 2)


func test_the_garage_bonus_multiplies_the_damage() -> void:
	rack.set_damage_bonus(50.0)
	rack.upgrade("bricks")
	var e := _place(FakeEnemy.new(), _car() + Vector2(1.0, 0.0))
	_air(0.5)
	assert_eq(e.damage_taken, [9.0])


func test_nothing_after_the_run() -> void:
	rack.upgrade("bricks")
	var e := _place(FakeEnemy.new(), _car() + Vector2(1.0, 0.0))
	run.state.kaiju_killed()  # the run is won and over (T-414: a wreck is not over)
	assert_false(run.state.is_running())
	_air(1.0)
	assert_eq(bricks.waves, 0, "no wave once the run is over")
	assert_eq(e.damage_taken.size(), 0)


func test_a_new_run_takes_it_away_and_forgets_the_air() -> void:
	rack.upgrade("bricks")
	run.car.height_model.airborne = true
	for i in 20:
		rack.step(DT)
	assert_gt(bricks.air_seconds, 0.0)
	rack.reset_for_run()
	assert_eq(bricks.tier, 0)
	assert_eq(bricks.air_seconds, 0.0)
	assert_false(bricks.was_airborne)
	assert_eq(bricks.waves, 0)
	run.car.height_model.airborne = false


func test_the_playtest_switch_gives_it_at_the_start() -> void:
	Bricks.playtest_override = 1
	rack.reset_for_run()
	assert_eq(bricks.tier, 1)
	Bricks.playtest_override = 0
	rack.reset_for_run()
	assert_eq(bricks.tier, 0)
	var r := GameData.load_file("playtest")
	assert_true(r.ok)
	var v := GameData.get_value(r.data, Bricks.PLAYTEST_KEY)
	assert_true(v.ok, "the key is in data/playtest.json")
	assert_false(bool(v.data), "false as committed")


func test_the_cars_handling_does_not_change() -> void:
	# The same drive with and without Bricks ends at the same spot, speed and heading.
	var ends := []
	for owned in [false, true]:
		rack.reset_for_run()
		if owned:
			rack.upgrade("bricks")
		var car = run.car
		car.model.set_position(Vector2(0.0, 10.0))
		car.model.rotation = 0.0
		car.model.set_velocity(Vector2.ZERO)
		car._sync_from_model()
		car.height_model.reset(car.model.get_position())  # on the ground there
		car.scripted_input = [true, false, 0.0]
		for i in 60:
			if i == 30:
				car.scripted_input = [true, false, 1.0]
			car.physics_step()
			rack.step(DT)
		ends.append([car.model.get_position(), car.model.get_velocity(), car.model.rotation])
	assert_true(ends[0][0].is_equal_approx(ends[1][0]), "the same position")
	assert_true(ends[0][1].is_equal_approx(ends[1][1]), "the same velocity")
	assert_almost_eq(ends[0][2], ends[1][2], 1e-9, "the same heading")


# --- The drawing ---------------------------------------------------------------------

func test_the_wave_is_drawn_growing_to_the_radius_then_gone() -> void:
	rack.upgrade("bricks")
	_air(0.5)
	var w: Node2D = bricks.last_wave
	assert_not_null(w, "a wave drawing")
	assert_eq(w.get_parent(), rack.draw_root, "in the rack's draw root")
	assert_true(rack.projectiles.has(w))
	assert_almost_eq(w.radius, bricks.radius(), 1e-9, "it marks the damage radius")
	var last: float = w.ring_radius()
	assert_lt(last, w.radius)
	var reached := false
	while not w.is_done():
		rack.step(DT)
		if not is_instance_valid(w) or w.is_queued_for_deletion():
			break
		assert_gte(w.ring_radius(), last - 1e-9, "the ring only grows")
		last = w.ring_radius()
		if is_equal_approx(last, w.radius):
			reached = true
	assert_true(reached, "the ring reaches the radius")
	rack.step(DT)
	assert_false(rack.projectiles.has(w), "gone once done")


func test_a_wider_tier_draws_a_wider_ring() -> void:
	bricks.set_tier(7)
	_air(0.5)
	assert_almost_eq(bricks.last_wave.radius, 8.4, 1e-9)


func test_the_wave_is_drawn_at_the_grounds_height() -> void:
	rack.upgrade("bricks")
	bricks.send_wave(_car())
	var w: Node2D = bricks.last_wave
	var flat := Bricks.ISO_TRANSFORM * (_car() * 16.0)
	assert_almost_eq(w.position.y, flat.y - run.car.height * 16.0, 1e-4)


func test_the_waves_colours_are_opaque_and_none_of_greenbulls() -> void:
	rack.upgrade("bricks")
	bricks.send_wave(_car())
	for c in bricks.last_wave.colours():
		assert_eq(c.a, 1.0, "opaque")
		for g in GREENBULL:
			var d := Vector3(c.r - g.r, c.g - g.g, c.b - g.b).length() * 255.0
			assert_gt(d, GREENBULL_MAX_DIST, "%s is not Greenbull's %s" % [c, g])


# --- T-325's art -----------------------------------------------------------------------

func test_every_tiers_radius_has_its_wave_sheet() -> void:
	for t in range(1, data.max_tier("bricks") + 1):
		var r: float = data.bricks_at(t)["radius"]
		var path: String = Bricks.BricksWave.art_path(r)
		assert_true(ResourceLoader.exists(path), "tier %d (radius %.2f): %s" % [t, r, path])
		var tex: Texture2D = Bricks.BricksWave.sheet_for(r)
		assert_not_null(tex)
		if int(data.bricks_at(t)["rings"]) > 1:
			assert_false(Bricks.BricksWave.record_for(r).is_empty(), "tier %d: the widest wave's strip record" % t)
		else:
			assert_eq(tex.get_width() % Bricks.BricksWave.FRAMES, 0, "%s splits into the frames" % path)
	assert_null(Bricks.BricksWave.sheet_for(123.4), "no sheet for a radius no tier has")


func test_the_wave_shows_its_sheet_frame_by_frame() -> void:
	rack.upgrade("bricks")
	bricks.send_wave(_car())
	var w: Node2D = bricks.last_wave
	assert_not_null(w.sheet, "the art, not the placeholder")
	assert_eq(w.sheet, Bricks.BricksWave.sheet_for(bricks.radius()))
	assert_eq(w.frame_size.x * Bricks.BricksWave.FRAMES, float(w.sheet.get_width()))
	# The ring's centre in the frame: half the width, below the room left for the dust.
	assert_almost_eq(w.art_centre.x, w.frame_size.x / 2.0, 1e-6)
	assert_gt(w.art_centre.y, float(Bricks.BricksWave.ART_TOP))
	# The ellipse of the radius fits the frame: half-width radius * sqrt(2) * 32 art px.
	assert_gte(w.art_centre.x, bricks.radius() * sqrt(2.0) * 32.0, "the ring fits at full radius")
	var seen := []
	while is_instance_valid(w) and not w.is_done():
		var f: int = w.frame_index()
		if seen.is_empty() or seen[-1] != f:
			seen.append(f)
		rack.step(DT)
	assert_eq(seen[0], 0, "starts on the first frame")
	assert_eq(seen[-1], Bricks.BricksWave.FRAMES - 1, "ends on the last frame")
	for i in range(1, seen.size()):
		assert_eq(seen[i], seen[i - 1] + 1, "frames in order, none skipped")


func test_a_wider_tier_shows_a_wider_sheet() -> void:
	rack.upgrade("bricks")
	bricks.send_wave(_car())
	var small: Vector2 = bricks.last_wave.frame_size
	bricks.set_tier(7)
	bricks.send_wave(_car() + Vector2(20, 0))
	assert_gt(bricks.last_wave.frame_size.x, small.x)
	assert_eq(bricks.last_wave.sheet, Bricks.BricksWave.sheet_for(8.4))


# --- T-498: tier 8, Widest Wave ----------------------------------------------------------

func test_tier_8_is_the_widest_wave_three_times_tier_7() -> void:
	assert_eq(data.max_tier("bricks"), 8)
	bricks.set_tier(7)
	var r7: float = bricks.radius()
	assert_eq(bricks.rings(), 1)
	bricks.set_tier(8)
	assert_eq(bricks.tier, 8)
	assert_almost_eq(bricks.radius(), r7 * 3.0, 1e-9, "the radius x3")
	assert_almost_eq(bricks.radius(), 25.2, 1e-9)
	assert_eq(bricks.rings(), 3, "three crash rings")
	for k in [1, 2, 3]:
		assert_almost_eq(bricks.ring_radius(k), r7 * k, 1e-9, "ring %d at the tier 7 radius x%d" % [k, k])
	assert_eq(bricks.ring_reach_seconds(1), 0.0, "the inner ring on the landing")
	assert_lt(bricks.ring_reach_seconds(2), bricks.ring_reach_seconds(3))


## The step (after the landing step) at which each enemy was first hit; -1: never.
func _hit_steps(enemies: Array, steps: int) -> Array:
	var out := []
	for e in enemies:
		out.append(0 if e.damage_taken.size() > 0 else -1)
	for i in steps:
		rack.step(DT)
		for j in enemies.size():
			if out[j] < 0 and enemies[j].damage_taken.size() > 0:
				out[j] = i + 1
	return out


func test_the_widest_wave_reaches_the_outer_rings_later_and_hits_each_enemy_once() -> void:
	bricks.set_tier(8)
	var c := _car()
	var near := _place(FakeMinion.new(), c + Vector2(3.0, 0.0))     # ring 1, pushed 9 units out into ring 2
	var mid := _place(FakeEnemy.new(), c + Vector2(0.0, -12.0))      # ring 2
	var far := _place(FakeEnemy.new(), c + Vector2(-23.0, 0.0))      # ring 3, near the outer edge
	var kaiju := _place(FakeMinion.new(), c + Vector2(0.0, 26.0))    # its body reaches into ring 3
	kaiju.as_kaiju(2.0)
	var outside := _place(FakeEnemy.new(), c + Vector2(28.0, 0.0))
	var rings := []
	bricks.ring_hit.connect(func(_at: Vector2, k: int, n: int) -> void: rings.append([k, n]))
	_air(0.5)
	assert_eq(near.damage_taken.size(), 1, "the inner ring hits on the landing")
	assert_eq(mid.damage_taken.size(), 0, "the middle ring has not got there yet")
	var steps := _hit_steps([near, mid, far, kaiju], 60)
	assert_eq(steps[0], 0)
	assert_gt(steps[1], steps[0], "the middle ring later than the inner")
	assert_gt(steps[2], steps[1], "the outer ring later still")
	assert_eq(steps[3], steps[2], "the kaiju with the outer ring")
	assert_almost_eq(steps[1] * DT, bricks.ring_reach_seconds(2), DT + 1e-6, "when the drawn wave reaches ring 2")
	assert_almost_eq(steps[2] * DT, bricks.ring_reach_seconds(3), DT + 1e-6, "when the drawn wave reaches ring 3")
	for e in [near, mid, far, kaiju]:
		assert_eq(e.damage_taken.size(), 1, "hit exactly once per landing")
		assert_almost_eq(float(e.damage_taken[0]), 13.5, 1e-9)
	assert_eq(outside.damage_taken.size(), 0, "outside the widest radius: untouched")
	assert_eq(near.pushes.size(), 1, "the minion pushed once, by the ring that hit it")
	assert_lt((near.position / 16.0 - c).length(), bricks.ring_radius(2), "pushed into ring 2's reach, and not hit again")
	assert_eq(kaiju.pushes.size(), 0, "the kaiju is never pushed")
	assert_eq(rings, [[1, 1], [2, 1], [3, 2]], "each ring reports its own hits")
	assert_true(bricks.pending_rings.is_empty())


func test_a_new_run_drops_the_rings_still_to_come() -> void:
	bricks.set_tier(8)
	var far := _place(FakeEnemy.new(), _car() + Vector2(-20.0, 0.0))
	_air(0.5)
	assert_eq(bricks.pending_rings.size(), 2)
	rack.reset_for_run()
	assert_true(bricks.pending_rings.is_empty())
	for i in 50:
		rack.step(DT)
	assert_eq(far.damage_taken.size(), 0)


func test_the_widest_wave_shows_its_three_ring_sheet_strip_by_strip() -> void:
	bricks.set_tier(8)
	bricks.send_wave(_car())
	var w: Node2D = bricks.last_wave
	assert_eq(w.sheet, Bricks.BricksWave.sheet_for(25.2))
	var rec: Dictionary = Bricks.BricksWave.record_for(25.2)
	assert_eq(w.frames, rec["frames"])
	assert_gt(w.frames, Bricks.BricksWave.FRAMES, "longer than one ring: the wave travels out")
	assert_eq(w.runs.size(), w.frames)
	assert_gte(w.art_centre.x, 25.2 * sqrt(2.0) * 32.0, "the outer ring fits the frame")
	# Every strip lies inside the atlas and the frame.
	for a in w.runs:
		for i in range(0, a.size(), 5):
			assert_true(a[i] + a[i + 4] <= w.sheet.get_width() and a[i + 1] + w.cell <= w.sheet.get_height())
			assert_true(a[i + 2] + a[i + 4] <= int(w.frame_size.x))
	var seen := []
	var steps := 0
	while is_instance_valid(w) and not w.is_done():
		var f: int = w.frame_index()
		if seen.is_empty() or seen[-1] != f:
			seen.append(f)
		rack.step(DT)
		steps += 1
	assert_eq(seen, range(w.frames), "every frame in order")
	assert_almost_eq(steps * DT, w.frames * Bricks.BricksWave.FRAME_SECONDS, DT + 1e-6)
	# The ring timing the game hits by is the sheet's (build_bricks_wave.py).
	var json = JSON.parse_string(FileAccess.get_file_as_string("res://art/weapons/bricks_wave_r25_2.json"))
	for k in [1, 2, 3]:
		var reach := float(json["ring_reach_seconds"][k - 1])
		if k > 1:
			assert_almost_eq(bricks.ring_reach_seconds(k), reach, 1e-6, "ring %d" % k)
