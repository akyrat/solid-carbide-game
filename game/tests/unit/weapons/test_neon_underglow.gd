extends GutTest
## Task T-168: the neon underglow. A circle around the car; an enemy entering
## takes a hit at once and one staying inside takes one every tick interval,
## all from weapons.json, times the garage damage multiplier. Tiers 2 to 8,
## pause and end of run, a new run without it, the target rules, the playtest
## switch and the placeholder ring under the car.

const RunScene := preload("res://scenes/run/run.tscn")
const FakeEnemy := preload("res://tests/fixtures/weapons/fake_enemy.gd")
const FakeBigEnemy := preload("res://tests/fixtures/weapons/fake_big_enemy.gd")
const Glow := preload("res://scripts/weapons/neon_underglow.gd")
const Flame := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const DT := 0.02  # one physics step (50 per second)
## Redgull red (Hud.HEART_COLOR) and the logo's red: placeholders never use them.
const REDGULL_REDS := [Color(0.86, 0.1, 0.16), Color8(135, 17, 27)]

var run: Node2D
var rack: Node
var glow
var data: WeaponData


func before_each() -> void:
	Glow.playtest_override = 0
	Flame.playtest_override = 0
	data = WeaponData.new()
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	rack = run.weapons
	rack.gun.set_tier(0)  # the gun's bullets would hit the test enemies too
	glow = rack.underglow


func after_each() -> void:
	Glow.playtest_override = -1
	Flame.playtest_override = -1
	get_tree().paused = false


## Steps the rack (only the underglow is owned), the car standing still.
func _step(steps: int) -> void:
	for i in steps:
		rack.step(DT)


func _enemy_at(units: Vector2, big := false) -> Node2D:
	var e: Node2D = FakeBigEnemy.new() if big else FakeEnemy.new()
	e.position = units * 16.0
	run.add_child(e)
	return e


## A point `d` units to the right of the car's centre.
func _off(d: float) -> Vector2:
	return run.car.model.get_position() + Vector2(d, 0.0)


func _steps_for(seconds: float) -> int:
	return int(ceil(seconds / DT - 1e-6))  # the first whole step at or past `seconds`


# --- Owning it ---------------------------------------------------------------

func test_a_new_run_has_no_underglow_and_upgrade_gives_it() -> void:
	assert_true(Glow in rack.WEAPON_SCRIPTS, "listed in WEAPON_SCRIPTS")
	assert_eq(rack.get_weapon("underglow"), glow)
	assert_eq(glow.weapon_id, "underglow")
	assert_false(glow.starts_owned)
	assert_eq(glow.tier, 0, "not owned at the start of a run")
	assert_false("underglow" in rack.owned_ids())
	var e := _enemy_at(_off(1.0))
	_step(60)
	assert_eq(e.damage_taken.size(), 0, "not owned: no damage")
	assert_true(rack.upgrade("underglow"), "the level-up's call gives it")
	assert_eq(glow.tier, 1)
	assert_true("underglow" in rack.owned_ids())


# --- Damage --------------------------------------------------------------------

func test_entering_enemy_is_hit_on_that_step_and_again_every_tick() -> void:
	rack.set_damage_bonus(25.0)
	rack.upgrade("underglow")
	var s: Dictionary = data.underglow_at(1)
	var want: float = s["damage"] * rack.damage_multiplier()
	assert_almost_eq(want, 1.25, 1e-9, "1 x 1.25")
	var r: float = s["radius"]
	var e := _enemy_at(_off(r + 0.5))
	_step(5)
	assert_eq(e.damage_taken.size(), 0, "outside the circle: no damage")
	e.position = _off(r - 0.2) * 16.0  # walks in
	_step(1)
	assert_eq(e.damage_taken.size(), 1, "hit on the step it enters")
	assert_almost_eq(float(e.damage_taken[0]), want, 1e-9, "data damage x garage multiplier")
	var tick_steps := _steps_for(s["tick_interval"])
	_step(tick_steps - 1)
	assert_eq(e.damage_taken.size(), 1, "no second hit before the interval is over")
	_step(1)
	assert_eq(e.damage_taken.size(), 2, "second hit once the tick interval is over")
	_step(tick_steps * 3)
	assert_eq(e.damage_taken.size(), 5, "then one per tick interval")
	for a in e.damage_taken:
		assert_almost_eq(float(a), want, 1e-9)
	rack.set_damage_bonus(0.0)


func test_enemy_outside_is_never_hit() -> void:
	rack.upgrade("underglow")
	var e := _enemy_at(_off(data.underglow_at(1)["radius"] + 0.3))
	_step(200)
	assert_eq(e.damage_taken.size(), 0)


## The proposal: leaving and coming back before the interval is over is not a new entering hit.
func test_leaving_and_reentering_within_the_interval_is_not_hit_again_at_once() -> void:
	rack.upgrade("underglow")
	var s: Dictionary = data.underglow_at(1)
	var r: float = s["radius"]
	var e := _enemy_at(_off(r - 0.5))
	_step(1)
	assert_eq(e.damage_taken.size(), 1)
	e.position = _off(r + 0.5) * 16.0
	_step(10)
	e.position = _off(r - 0.5) * 16.0
	_step(1)
	assert_eq(e.damage_taken.size(), 1, "back within the interval: no extra hit")
	_step(_steps_for(s["tick_interval"]) - 11)  # 10 + 1 + this = one interval after the first hit
	assert_eq(e.damage_taken.size(), 2, "hit when its interval is over")
	# Out for longer than the interval: a new entering hit at once.
	e.position = _off(r + 0.5) * 16.0
	_step(_steps_for(s["tick_interval"]) + 5)
	e.position = _off(r - 0.5) * 16.0
	_step(1)
	assert_eq(e.damage_taken.size(), 3, "re-entering after its interval: hit at once")


func test_each_enemy_has_its_own_clock() -> void:
	rack.upgrade("underglow")
	var s: Dictionary = data.underglow_at(1)
	var a := _enemy_at(_off(1.0))
	_step(10)
	var b := _enemy_at(_off(-1.0))
	_step(1)
	assert_eq(a.damage_taken.size(), 1)
	assert_eq(b.damage_taken.size(), 1, "the late one is hit as it enters")
	_step(_steps_for(s["tick_interval"]) - 10)  # 10 + 1 + this = one interval after a's first hit
	assert_eq(a.damage_taken.size(), 2, "a's tick")
	assert_eq(b.damage_taken.size(), 1, "b's tick not yet")


## Target rules (board, 2026-10-14): minions by centre, the kaiju by body overlap.
func test_big_enemy_is_hit_when_its_body_overlaps_the_circle() -> void:
	rack.upgrade("underglow")
	var r: float = data.underglow_at(1)["radius"]
	var big := _enemy_at(_off(r + 2.0), true)
	big.radius_units = 3.0
	var small := _enemy_at(_off(-(r + 2.0)))
	var too_far := _enemy_at(run.car.model.get_position() + Vector2(0.0, r + 3.5), true)
	too_far.radius_units = 3.0
	_step(1)
	assert_eq(big.damage_taken.size(), 1, "body overlapping: hit")
	assert_eq(small.damage_taken.size(), 0, "centre outside, no size: not hit")
	assert_eq(too_far.damage_taken.size(), 0, "body short of the circle: not hit")


func test_it_kills_a_real_minion() -> void:
	rack.upgrade("underglow")
	var m: Node = run.minions.spawn_minion_at(_off(1.0))
	var health: float = m.health
	_step(1)
	assert_almost_eq(m.health, health - data.underglow_at(1)["damage"], 1e-9, "entering hit")


# --- Pause, end of run, new run ----------------------------------------------

func test_no_damage_while_paused() -> void:
	rack.upgrade("underglow")
	var e := _enemy_at(_off(1.0))
	get_tree().paused = true
	await wait_physics_frames(10)
	assert_eq(e.damage_taken.size(), 0, "no damage while paused")
	get_tree().paused = false
	await wait_physics_frames(2)
	assert_gt(e.damage_taken.size(), 0, "hits once the run goes on")


func test_no_damage_after_the_run_ends() -> void:
	rack.upgrade("underglow")
	run.state.damage_car(1e9)  # the car is destroyed: the run is lost
	assert_false(run.state.is_running())
	var e := _enemy_at(_off(1.0))
	_step(60)
	assert_eq(e.damage_taken.size(), 0, "no damage once the run is over")


func test_a_new_run_removes_the_underglow() -> void:
	rack.upgrade("underglow")
	glow.set_tier(6)
	_enemy_at(_off(1.0))
	_step(5)
	assert_true(glow.drawing.visible)
	run.start_run()
	await get_tree().process_frame
	assert_eq(rack.underglow, glow, "the same node, kept by the rack")
	assert_eq(glow.tier, 0, "not owned in the new run")
	assert_eq(rack.owned_ids(), ["gun"])
	assert_eq(glow.hits, 0)
	assert_false(glow.drawing.visible, "no ring drawn")
	rack.gun.set_tier(0)
	var e := _enemy_at(_off(1.0))
	_step(60)
	assert_eq(e.damage_taken.size(), 0, "the new run's car hurts nothing")


func test_playtest_switch_gives_it_at_the_start_of_every_run() -> void:
	Glow.playtest_override = 1
	run.start_run()
	await get_tree().process_frame
	assert_eq(glow.tier, 1, "switch on: the run starts with it at tier 1")
	Glow.playtest_override = 0
	run.start_run()
	await get_tree().process_frame
	assert_eq(glow.tier, 0, "switch off: without it")


func test_playtest_switch_is_read_from_the_data_file() -> void:
	Glow.playtest_override = -1
	var r := GameData.load_file("playtest")
	assert_true(r.ok)
	assert_true(r.data.has("underglow_at_start"))
	assert_eq(Glow.playtest_switch_on(), bool(r.data["underglow_at_start"]))


# --- Tiers -------------------------------------------------------------------------

func test_each_tier_sets_the_datas_values() -> void:
	rack.upgrade("underglow")
	for t in range(1, data.max_tier() + 1):
		glow.set_tier(t)
		assert_eq(glow.stats, data.underglow_at(t), "tier %d values" % t)
	glow.set_tier(1)
	for t in range(2, data.max_tier() + 1):
		assert_true(rack.upgrade("underglow"), "upgrade to tier %d" % t)
	assert_false(rack.upgrade("underglow"), "no upgrade past the last tier")


func test_tier_2_changes_what_weapons_json_says() -> void:
	_check_tier(2)


func test_tier_3_changes_what_weapons_json_says() -> void:
	_check_tier(3)


func test_tier_4_changes_what_weapons_json_says() -> void:
	_check_tier(4)


func test_tier_5_changes_what_weapons_json_says() -> void:
	_check_tier(5)


func test_tier_6_changes_what_weapons_json_says() -> void:
	_check_tier(6)


func test_tier_7_changes_what_weapons_json_says() -> void:
	_check_tier(7)


func test_tier_8_changes_what_weapons_json_says() -> void:
	_check_tier(8)


## Applies tier `want` from code and checks the change weapons.json's tier list
## gives it (read from the file, not hard-coded), then plays it.
func _check_tier(want: int) -> void:
	var found := false
	for entry in data.tiers("underglow"):
		var t := int(entry["tier"])
		if t != want:
			continue
		found = true
		var effect := String(entry["effect"])
		var value := float(entry["value"])
		var key: String = {
			"radius_multiplier": "radius",
			"damage_multiplier": "damage",
			"tick_interval_multiplier": "tick_interval",
		}.get(effect, "")
		assert_ne(key, "", "tier %d effect %s is known" % [t, effect])
		glow.set_tier(t - 1)
		var before: Dictionary = glow.stats.duplicate()
		glow.set_tier(t)
		assert_eq(glow.tier, t)
		assert_almost_eq(float(glow.stats[key]), float(before[key]) * value, 1e-9,
			"tier %d: %s x %s" % [t, key, value])
		for other in ["radius", "damage", "tick_interval"]:
			if other != key:
				assert_almost_eq(float(glow.stats[other]), float(before[other]), 1e-9,
					"tier %d leaves %s alone" % [t, other])
		_check_tier_in_play(t, key, before)
	assert_true(found, "weapons.json has an underglow tier %d" % want)


## Plays the tier's change: a bigger circle reaches an enemy the last tier did
## not, more damage per hit, a shorter interval between hits.
func _check_tier_in_play(t: int, key: String, before: Dictionary) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.remove_from_group("enemies")
	glow.reset_for_run()
	glow.set_tier(t)
	match key:
		"radius":
			var d: float = (float(before["radius"]) + float(glow.stats["radius"])) / 2.0
			glow.set_tier(t - 1)
			var e := _enemy_at(_off(d))
			_step(1)
			assert_eq(e.damage_taken.size(), 0, "tier %d does not reach %.2f" % [t - 1, d])
			glow.set_tier(t)
			_step(1)
			assert_eq(e.damage_taken.size(), 1, "tier %d reaches %.2f" % [t, d])
		"damage":
			var e := _enemy_at(_off(0.5))
			_step(1)
			assert_almost_eq(float(e.damage_taken[0]), float(glow.stats["damage"]), 1e-9, "tier %d damage" % t)
			assert_gt(float(e.damage_taken[0]), float(before["damage"]))
		"tick_interval":
			var e := _enemy_at(_off(0.5))
			_step(1 + _steps_for(glow.stats["tick_interval"]))
			assert_eq(e.damage_taken.size(), 2, "tier %d hits again after %.3f s" % [t, glow.stats["tick_interval"]])
			assert_lt(float(glow.stats["tick_interval"]), float(before["tick_interval"]))


func test_damage_bonus_multiplies_every_tier() -> void:
	rack.upgrade("underglow")
	rack.set_damage_bonus(50.0)
	for t in range(1, data.max_tier() + 1):
		glow.set_tier(t)
		assert_almost_eq(float(glow.stats["damage"]), data.underglow_at(t)["damage"] * 1.5, 1e-9)
	rack.set_damage_bonus(0.0)


# --- The zone drawn in code (T-274) ------------------------------------------------

const Look := preload("res://scripts/weapons/underglow_look.gd")


## A copy of the scene's look with the shimmer off, so the ring's colours are steady.
func _steady_look() -> Resource:
	var l: Resource = load("res://scenes/weapons/neon_underglow_look.tres").duplicate()
	l.shimmer_arc = 0.0
	return l


## The flat distance of image pixel (x, y) from the circle's centre, for an image of w x h.
func _flat_dist(x: int, y: int, w: int, h: int) -> float:
	var sx := float(x - w / 2) + 0.5
	var sy := float(y - h / 2) + 0.5
	var fx := sx / 2.0 + sy
	var fy := sy - sx / 2.0
	return sqrt(fx * fx + fy * fy)


func test_zone_is_drawn_under_the_car_while_owned() -> void:
	assert_true(glow.drawing == null or not glow.drawing.visible, "not owned: no zone")
	rack.upgrade("underglow")
	var d: Node2D = glow.drawing
	assert_not_null(d)
	assert_eq(d.get_parent(), run.view_root, "in the car's drawing")
	assert_lt(d.get_index(), run.car_sprite.get_index(), "drawn below the car sprite")
	assert_true(d.visible)
	assert_almost_eq(d.radius_px, data.underglow_at(1)["radius"] * 16.0, 1e-6, "the damage circle's size")
	run.car.scripted_input = [true, false, 0.0]
	for i in 20:
		run.car.physics_step()
		rack.step(DT)
	var want: Vector2 = Glow.ISO_TRANSFORM * (run.car.model.get_position() * 16.0)
	assert_almost_eq(d.position.x, want.x, 0.01, "follows the car")
	assert_almost_eq(d.position.y, want.y, 0.01)
	glow.set_tier(8)
	assert_almost_eq(d.radius_px, data.underglow_at(8)["radius"] * 16.0, 1e-6, "grows with the radius tiers")


## The ring's bright pixels sit exactly inside the damage circle's edge at every tier.
func test_the_ring_marks_the_damage_circle_at_every_tier() -> void:
	rack.upgrade("underglow")
	var d = glow.drawing
	var l: Resource = _steady_look()
	d.set_look(l)
	var core_w: float = l.ring_core_px
	var mid_w: float = core_w + l.ring_mid_px
	for t in range(1, data.max_tier() + 1):
		glow.set_tier(t)
		var r: float = glow.radius() * 16.0
		var img: Image = d.build_image(0)
		var w := img.get_width()
		var h := img.get_height()
		var core := 0
		var halo := 0
		var inner := 0
		for y in h:
			for x in w:
				var c := img.get_pixel(x, y)
				if c.a == 0.0:
					continue
				var dist := _flat_dist(x, y, w, h)
				if _same(c, l.ring_core_colour):
					core += 1
					assert_true(dist <= r + 1e-3 and dist > r - core_w - 1e-3, "tier %d core pixel at %.2f, edge %.2f" % [t, dist, r])
				elif _same(c, l.ring_mid_colour):
					assert_true(dist <= r - core_w + 1e-3 and dist > r - mid_w - 1e-3, "tier %d mid pixel" % t)
				elif _same(c, l.halo_near_colour) or _same(c, l.halo_far_colour):
					if dist > r:
						halo += 1
					else:
						inner += 1
		assert_gt(core, 20, "tier %d: the ring is drawn" % t)
		assert_gt(halo, 20, "tier %d: the halo is outside the edge" % t)
		# The image is the circle seen from above: wider than tall by 2 (the isometric view).
		assert_almost_eq(float(w) / float(h), 2.0, 0.1, "tier %d: an ellipse twice as wide as tall" % t)
		assert_gt(float(w), r * 2.0, "tier %d: the circle fits" % t)


func test_drawn_pixels_are_opaque_and_from_the_look() -> void:
	rack.upgrade("underglow")
	var d = glow.drawing
	var allowed: Array = d.look.colours()
	for frame in [0, 5, 12, 19]:
		var img: Image = d.build_image(frame)
		var seen := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				assert_true(c.a == 0.0 or c.a == 1.0, "no semi-transparent pixel")
				if c.a == 1.0:
					seen += 1
					var ok := false
					for a in allowed:
						if _same(c, a):
							ok = true
					if not ok:
						fail_test("pixel colour %s is not one of the look's" % c)
						return
		assert_gt(seen, 100)
	assert_eq(d.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "no engine smoothing")


func test_look_colours_are_opaque_purples_and_pinks_not_redgull_red() -> void:
	rack.upgrade("underglow")
	for c in glow.drawing.look.colours():
		assert_eq(c.a, 1.0, "no see-through colour")
		for red in REDGULL_REDS:
			var dh := absf(c.h - red.h)
			assert_gt(minf(dh, 1.0 - dh) * 360.0, 30.0, "colour %s hue far from Redgull red" % c)
		assert_false(c.r > c.g + 0.2 and c.r > c.b + 0.2, "colour %s is not a red" % c)
		assert_gt(c.b, c.g, "colour %s leans purple or pink" % c)


func test_the_pulse_and_the_shimmer_move_and_loop() -> void:
	rack.upgrade("underglow")
	var d = glow.drawing
	var l: Resource = d.look
	var frames := int(l.cycle_frames)
	var imgs := {}
	for f in frames:
		imgs[f] = d.build_image(f).get_data()
	assert_ne(imgs[0], imgs[3], "the look changes between frames")
	assert_eq(imgs[0], d.build_image(frames).get_data(), "and loops after one cycle")
	var levels := {}
	for f in frames:
		levels[d.pulse_level(f)] = true
	assert_eq(levels.keys().size(), 3, "the pulse steps through 0, 1 and 2")
	# The shimmer arc travels once round the circle in a cycle.
	assert_almost_eq(d.shimmer_angle(frames / 2), PI, 1e-6)


func test_the_zone_stops_animating_while_paused() -> void:
	rack.upgrade("underglow")
	var d = glow.drawing
	d.set_time(0.0)
	await wait_physics_frames(3)
	await get_tree().process_frame
	assert_gt(d.time, 0.0, "it animates while the game runs")
	get_tree().paused = true
	var frozen: float = d.time
	await wait_physics_frames(10)
	assert_eq(d.time, frozen, "frozen while paused")
	get_tree().paused = false


func test_the_t175_sprite_is_kept_with_a_switch_back_to_it() -> void:
	assert_true(FileAccess.file_exists(Glow.ART_PATH) or ResourceLoader.exists(Glow.ART_PATH), "the sprite is still in game/art")
	rack.upgrade("underglow")
	var d = glow.drawing
	assert_false(d.look.use_sprite, "the drawn zone is the default")
	var l: Resource = d.look.duplicate()
	l.use_sprite = true
	d.set_look(l)
	await get_tree().process_frame
	assert_true(d.look.use_sprite)
	d.set_radius_px(Glow.PX_PER_UNIT * 2.5)
	assert_almost_eq(d.art_scale(), 0.5, 0.001, "the sprite is drawn at its scale")
	d.set_look(Look.new())


## Colours match to the 8 bits an image keeps.
func _same(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.005 and absf(a.g - b.g) < 0.005 and absf(a.b - b.b) < 0.005
