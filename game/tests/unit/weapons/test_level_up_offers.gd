extends GutTest
## Tasks T-043 and T-172: the level-up's weapon choices (two different ones drawn
## at random from all five weapons) and applying the one taken.

const RunScene := preload("res://scenes/run/run.tscn")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const UnderglowScript := preload("res://scripts/weapons/neon_underglow.gd")
const MolotovScript := preload("res://scripts/weapons/molotovs.gd")
const WiperScript := preload("res://scripts/weapons/windshield_wiper.gd")
const RackScript := preload("res://scripts/weapons/weapons.gd")
const OffersScript := preload("res://scripts/weapons/level_up_offers.gd")

const WEAPONS := ["gun", "flamethrower", "underglow", "molotov", "wiper"]
const SEEDS := 40

var run: Node2D
var rack: Node
var state: Node
var offers: Node
var shown: Array = []


func before_each() -> void:
	_switches(0)
	RackScript.all_weapons_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	rack = run.weapons
	state = run.state
	offers = rack.offers
	state.pause_on_level_up = true
	shown = []
	offers.offers_ready.connect(func(level: int, ids: Array) -> void: shown.append([level, ids]))


func after_each() -> void:
	_switches(-1)
	RackScript.all_weapons_override = -1
	get_tree().paused = false


func _switches(v: int) -> void:
	FlameScript.playtest_override = v
	UnderglowScript.playtest_override = v
	MolotovScript.playtest_override = v
	WiperScript.playtest_override = v


func _level_up() -> void:
	state.add_xp(state.xp_needed())


## Opens a level-up's choice the way the gift pack does (no level-up, no package).
func _open_choice() -> void:
	state.open_choice(state.level)


func _new_run(seed_value: int) -> void:
	state.start_run()
	rack.reset_for_run()
	offers.rng.seed = seed_value
	shown = []


## Every id available for the weapons as they are now, worked out here on its own.
func _expected_available() -> Array:
	var out := []
	for id in WEAPONS:
		var w: Node = rack.get_weapon(id)
		if not w.is_owned():
			out.append("get_" + id)
		elif w.tier < 8:
			out.append("upgrade_" + id)
	return out


func _max_all_but(keep: Array) -> void:
	for id in WEAPONS:
		if not keep.has(id):
			rack.get_weapon(id).set_tier(rack.get_weapon(id).max_tier())


# ---- The first level-up ----------------------------------------------------------------------

func test_first_level_up_offers_the_gun_upgrade_and_the_flamethrower() -> void:
	for s in SEEDS:
		_new_run(s)
		_level_up()
		assert_eq(shown.size(), 1, "seed %d: one offer" % s)
		assert_eq(shown[0][0], 2, "the level reached")
		assert_eq(shown[0][1], ["upgrade_gun", "get_flamethrower"], "seed %d: exactly these two" % s)
		assert_true(get_tree().paused, "the run waits for the choice")
		offers.choose("upgrade_gun")


func test_the_second_level_up_after_taking_the_gun_upgrade_is_drawn() -> void:
	var seen := {}
	for s in SEEDS:
		_new_run(s)
		_level_up()
		offers.choose("upgrade_gun")
		_level_up()
		for id in shown[1][1]:
			seen[id] = true
	assert_gt(seen.size(), 2, "not always the same two")
	assert_true(seen.has("get_underglow") or seen.has("get_molotov") or seen.has("get_wiper"), "new weapons appear")


# ---- The random draw -------------------------------------------------------------------------

func test_seeded_level_ups_draw_two_different_available_ids_and_cover_them_all() -> void:
	var seen := {}
	var level_ups := 0
	for s in SEEDS:
		_new_run(1000 + s)
		var pick := RandomNumberGenerator.new()
		pick.seed = s
		while true:
			var before := shown.size()
			var expected := _expected_available()
			_open_choice()
			if shown.size() == before:
				assert_true(expected.is_empty(), "skipped only when nothing is left")
				break
			level_ups += 1
			var ids: Array = shown[-1][1]
			if expected.size() >= 2:
				assert_eq(ids.size(), 2, "seed %d: two choices" % s)
				assert_ne(ids[0], ids[1], "seed %d: two different ids" % s)
			else:
				assert_eq(ids.size(), 1, "seed %d: one left" % s)
			for id in ids:
				assert_true(expected.has(id), "seed %d: %s is available" % [s, id])
				seen[id] = true
			assert_true(offers.choose(ids[pick.randi_range(0, ids.size() - 1)]))
			assert_false(state.is_waiting_for_choice())
	# 7 gun tiers + 4 weapons x 8 tiers.
	assert_eq(level_ups, SEEDS * 39, "every run takes every tier before the choices run out")
	for id in OffersScript.ALL_IDS:
		assert_true(seen.has(id), "%s offered at least once" % id)


func test_the_same_seed_draws_the_same_offers() -> void:
	var runs := []
	for i in 2:
		_new_run(77)
		rack.gun.set_tier(2)  # not the fixed first offer
		var ids := []
		for n in 6:
			_open_choice()
			ids.append(shown[-1][1])
			offers.choose(shown[-1][1][0])
		runs.append(ids)
	assert_eq(runs[0], runs[1])


func test_compute_offers_matches_the_next_draw_and_changes_nothing() -> void:
	rack.gun.set_tier(2)
	offers.rng.seed = 5
	var state_before: int = offers.rng.state
	var expected: Array = offers.compute_offers()
	assert_eq(offers.rng.state, state_before, "the generator is untouched")
	assert_eq(offers.compute_offers(), expected, "asking again gives the same")
	_open_choice()
	assert_eq(shown[0][1], expected, "the choice shows what compute_offers said")


func test_choices_are_shown_in_the_weapons_order() -> void:
	for s in SEEDS:
		_new_run(s)
		rack.gun.set_tier(2)
		_open_choice()
		var ids: Array = shown[0][1]
		assert_lt(OffersScript.ALL_IDS.find(ids[0]), OffersScript.ALL_IDS.find(ids[1]))
		offers.choose(ids[0])


func test_a_weapon_at_tier_8_is_never_offered() -> void:
	for s in SEEDS:
		_new_run(s)
		rack.gun.set_tier(8)
		rack.molotov.set_tier(8)
		_open_choice()
		var ids: Array = shown[0][1]
		assert_eq(ids.size(), 2)
		assert_false(ids.has("upgrade_gun"), "seed %d" % s)
		assert_false(ids.has("upgrade_molotov") or ids.has("get_molotov"), "seed %d" % s)
		offers.choose(ids[0])


# ---- One left, none left ---------------------------------------------------------------------

func test_one_choice_when_only_one_is_left() -> void:
	_max_all_but(["wiper"])
	rack.wiper.set_tier(7)
	_level_up()
	assert_eq(shown[0][1], ["upgrade_wiper"])
	assert_true(offers.choose("upgrade_wiper"))
	assert_true(rack.wiper.is_max_tier())
	assert_false(get_tree().paused)


func test_one_get_when_only_one_weapon_is_missing_and_the_rest_maxed() -> void:
	_max_all_but(["underglow"])
	_level_up()
	assert_eq(shown[0][1], ["get_underglow"])


func test_nothing_to_offer_skips_the_choice_and_resumes() -> void:
	_max_all_but([])
	_level_up()
	assert_eq(shown.size(), 0, "no offer is shown")
	assert_false(state.is_waiting_for_choice())
	assert_false(get_tree().paused, "the run goes on")
	assert_eq(state.level, 2)
	assert_false(offers.has_offers())


# ---- Taking a choice -------------------------------------------------------------------------

func test_taking_the_gun_and_flamethrower_choices_applies_them_and_resumes() -> void:
	_level_up()
	assert_true(offers.choose("upgrade_gun"))
	assert_eq(rack.gun.tier, 2)
	assert_false(rack.flamethrower.is_owned())
	assert_false(get_tree().paused, "the run resumes")
	assert_false(state.is_waiting_for_choice())
	assert_false(offers.has_offers())
	_max_all_but(["flamethrower"])
	_level_up()
	assert_eq(shown[-1][1], ["get_flamethrower"])
	assert_true(offers.choose("get_flamethrower"))
	assert_eq(rack.flamethrower.tier, 1)
	_level_up()
	assert_true(offers.choose("upgrade_flamethrower"))
	assert_eq(rack.flamethrower.tier, 2)
	assert_false(get_tree().paused)


func _check_get_and_upgrade(weapon_id: String) -> void:
	_new_run(1)
	_max_all_but([weapon_id])
	var w: Node = rack.get_weapon(weapon_id)
	assert_false(w.is_owned(), weapon_id + " not owned at the start")
	_level_up()
	assert_eq(shown[-1][1], ["get_" + weapon_id])
	var taken := []
	offers.offer_taken.connect(func(id: String) -> void: taken.append(id))
	assert_true(offers.choose("get_" + weapon_id))
	assert_eq(w.tier, 1, weapon_id + " given at tier 1")
	assert_false(get_tree().paused, "the run resumes")
	assert_false(state.is_waiting_for_choice())
	_level_up()
	assert_eq(shown[-1][1], ["upgrade_" + weapon_id])
	assert_true(offers.choose("upgrade_" + weapon_id))
	assert_eq(w.tier, 2, weapon_id + " at its next tier")
	assert_false(get_tree().paused)
	assert_eq(taken, ["get_" + weapon_id, "upgrade_" + weapon_id])


func test_taking_get_and_upgrade_underglow() -> void:
	_check_get_and_upgrade("underglow")


func test_taking_get_and_upgrade_molotov() -> void:
	_check_get_and_upgrade("molotov")


func test_taking_get_and_upgrade_wiper() -> void:
	_check_get_and_upgrade("wiper")


func test_a_choice_not_on_offer_is_refused() -> void:
	_level_up()
	assert_false(offers.choose("upgrade_flamethrower"), "not owned yet, so not offered")
	assert_false(offers.choose("get_wiper"), "available but not drawn")
	assert_false(offers.choose("nonsense"))
	assert_false(offers.choose(""))
	assert_eq(rack.gun.tier, 1)
	assert_false(rack.wiper.is_owned())
	assert_true(get_tree().paused, "still waiting")


func test_choosing_with_no_choice_waiting_does_nothing() -> void:
	assert_false(offers.choose("upgrade_gun"))
	assert_eq(rack.gun.tier, 1)


func test_weapon_of_maps_ids_to_weapons() -> void:
	assert_eq(OffersScript.weapon_of("upgrade_gun"), "gun")
	assert_eq(OffersScript.weapon_of("get_molotov"), "molotov")
	assert_eq(OffersScript.weapon_of("upgrade_wiper"), "wiper")
	assert_eq(OffersScript.weapon_of("get_underglow"), "underglow")
	assert_eq(OffersScript.weapon_of("get_rocket"), "")
	assert_eq(OffersScript.weapon_of("nonsense"), "")


func test_two_level_ups_at_once_offer_in_turn() -> void:
	state.add_xp(state.xp_needed() + RunData.new().xp_needed(2) + 0.5)
	assert_eq(state.level, 3)
	assert_eq(shown.size(), 1, "the first level's choice is on show")
	assert_true(offers.choose("upgrade_gun"))
	assert_eq(shown.size(), 2, "then the second level's")
	assert_eq(shown[1][0], 3)
	assert_eq(shown[1][1].size(), 2)
	assert_true(get_tree().paused)
	assert_true(offers.choose(shown[1][1][1]))
	assert_false(get_tree().paused)


func test_a_new_run_clears_the_offer_and_brings_back_the_first_offer() -> void:
	_level_up()
	offers.choose("upgrade_gun")
	_level_up()
	_new_run(3)
	assert_false(offers.has_offers())
	assert_false(offers.choose("upgrade_gun"))
	assert_false(get_tree().paused)
	_level_up()
	assert_eq(shown[-1][1], ["upgrade_gun", "get_flamethrower"])


# ---- Playtest switches -----------------------------------------------------------------------

func test_flamethrower_at_the_start_leads_to_its_upgrades() -> void:
	var seen := {}
	for s in SEEDS:
		FlameScript.playtest_override = 1
		_new_run(s)
		assert_true(rack.flamethrower.is_owned())
		assert_eq(rack.flamethrower.tier, 1)
		_level_up()
		var ids: Array = shown[0][1]
		assert_eq(ids.size(), 2)
		assert_false(ids.has("get_flamethrower"), "already owned")
		for id in ids:
			seen[id] = true
		offers.choose(ids[0])
	assert_true(seen.has("upgrade_flamethrower"), "its upgrades are offered")


func test_all_weapons_at_start_gives_all_five_at_tier_1() -> void:
	RackScript.all_weapons_override = 1
	rack.reset_for_run()
	for id in WEAPONS:
		assert_true(rack.get_weapon(id).is_owned(), id + " owned")
		assert_eq(rack.get_weapon(id).tier, 1, id + " at tier 1")
	_level_up()
	for id in shown[0][1]:
		assert_true(id.begins_with("upgrade_"), "only upgrades are left")


func test_all_weapons_at_start_with_the_flamethrower_switch_too_stays_at_tier_1() -> void:
	RackScript.all_weapons_override = 1
	FlameScript.playtest_override = 1
	rack.reset_for_run()
	assert_eq(rack.flamethrower.tier, 1)
	assert_eq(rack.wiper.tier, 1)


func test_all_weapons_at_start_off_gives_only_the_gun() -> void:
	RackScript.all_weapons_override = 0
	rack.reset_for_run()
	assert_eq(rack.owned_ids(), ["gun"])


func test_all_weapons_at_start_is_false_in_the_committed_file() -> void:
	var r := GameData.load_file(RackScript.PLAYTEST_FILE)
	assert_true(r.ok)
	var v := GameData.get_value(r.data, RackScript.ALL_WEAPONS_KEY)
	assert_true(v.ok, "the key is in data/playtest.json")
	assert_false(bool(v.data))
	RackScript.all_weapons_override = -1
	assert_false(RackScript.all_weapons_switch_on())
