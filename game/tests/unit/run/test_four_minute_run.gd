extends GutTest
## Task T-521 (Game loop architecture, Decisions, "A 4-minute run: 3 minutes to build, 1 minute
## of kaiju"): the kaiju at 3:00 and the end at 4:00, the 3-weapon and 3-power-up caps, a weapon's
## first pick at tier 2, the heal once every owned weapon is at its last tier, and max tiers read
## from the data (never a number in the code).

const RunScene := preload("res://scenes/run/run.tscn")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const UnderglowScript := preload("res://scripts/weapons/neon_underglow.gd")
const MolotovScript := preload("res://scripts/weapons/molotovs.gd")
const WiperScript := preload("res://scripts/weapons/windshield_wiper.gd")
const BricksScript := preload("res://scripts/weapons/bricks.gd")
const RackScript := preload("res://scripts/weapons/weapons.gd")
const TMP_POWER_UPS := "user://t521_power_ups.json"

var run: Node2D
var rack: Node
var state: RunState


func before_each() -> void:
	_switches(0)
	RackScript.all_weapons_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	rack = run.weapons
	state = run.state


func after_each() -> void:
	_switches(-1)
	RackScript.all_weapons_override = -1
	get_tree().paused = false
	DirAccess.remove_absolute(TMP_POWER_UPS)


func _switches(v: int) -> void:
	FlameScript.playtest_override = v
	UnderglowScript.playtest_override = v
	MolotovScript.playtest_override = v
	WiperScript.playtest_override = v
	BricksScript.playtest_override = v


func _max_out(weapon_id: String) -> void:
	var w: Node = rack.get_weapon(weapon_id)
	while not w.is_max_tier():
		rack.pick(weapon_id)


## Owns the gun, the flamethrower and the underglow (3 weapons), none maxed.
func _own_three() -> void:
	rack.pick("flamethrower")
	rack.pick("underglow")


func _max_three() -> void:
	_own_three()
	for id in ["gun", "flamethrower", "underglow"]:
		_max_out(id)


# --- The clock ---------------------------------------------------------------------------


func test_the_run_is_four_minutes_and_the_kaiju_comes_at_three() -> void:
	assert_eq(RunState.RUN_SECONDS, 240.0)
	assert_eq(RunState.RUN_SECONDS - RunState.BOSS_TIME_LEFT, 180.0, "the kaiju arrives at 3:00")
	var s := RunState.new()
	add_child_autofree(s)
	s.start_run()
	var boss := []
	var ended := []
	s.boss_time.connect(func() -> void: boss.append(s.time_elapsed()))
	s.run_ended.connect(func(r: String, _c: int) -> void: ended.append(r))
	s.advance(179.0)
	assert_eq(boss.size(), 0, "not before 3:00")
	s.advance(1.0)
	assert_eq(boss.size(), 1)
	assert_almost_eq(boss[0], 180.0, 0.01)
	s.advance(59.0)
	assert_eq(s.time_left_text(), "0:01")
	assert_eq(ended.size(), 0)
	s.advance(1.0)
	s.advance(s.time_up_seconds)
	assert_eq(ended, ["loss"], "the clock reaching 4:00 with the kaiju alive is the loss, as before")


func test_killing_the_kaiju_in_its_minute_still_wins() -> void:
	var s := RunState.new()
	add_child_autofree(s)
	s.start_run()
	var ended := []
	s.run_ended.connect(func(r: String, _c: int) -> void: ended.append(r))
	s.advance(200.0)
	s.kaiju_killed()
	assert_eq(ended, ["win"])


func test_the_clock_label_starts_at_the_runs_length() -> void:
	assert_eq(run.hud.timer_label.text, "4:00")


# --- Weapons: the cap of 3 and the first pick at tier 2 -----------------------------------


func test_a_weapon_picked_for_the_first_time_is_at_tier_2() -> void:
	var flame: Node = rack.get_weapon("flamethrower")
	assert_false(flame.is_owned())
	assert_true(rack.pick("flamethrower"))
	assert_eq(flame.tier, rack.slot_rules.first_pick_tier(), "tiers 1 and 2 applied in order")
	assert_eq(flame.tier, 2)
	rack.pick("flamethrower")
	assert_eq(flame.tier, 3, "an owned weapon goes up one tier a pick")
	assert_eq(rack.get_weapon("gun").tier, 1, "the gun starts at tier 1")


func test_the_choice_gives_a_new_weapon_at_tier_2() -> void:
	var offers: Node = rack.offers
	offers.current_offers = ["get_wiper"]
	state.pending_choices.append(2)
	assert_true(offers.choose("get_wiper"))
	assert_eq(rack.get_weapon("wiper").tier, 2)


func test_with_three_weapons_the_offers_are_only_their_upgrades() -> void:
	_own_three()
	assert_true(rack.slots_full())
	var expected := ["upgrade_gun", "upgrade_flamethrower", "upgrade_underglow"]
	assert_eq(rack.offers.available_offers(), expected)
	for seed_value in range(30):
		rack.offers.rng.seed = seed_value
		for id in rack.offers.compute_offers():
			assert_true(expected.has(id), "%s is an upgrade of an owned weapon (seed %d)" % [id, seed_value])


func test_a_maxed_weapon_leaves_the_offers_and_new_ones_stay_out() -> void:
	_own_three()
	_max_out("flamethrower")
	assert_eq(rack.offers.available_offers(), ["upgrade_gun", "upgrade_underglow"])


func test_with_fewer_than_three_weapons_new_ones_are_offered() -> void:
	rack.pick("flamethrower")
	assert_false(rack.slots_full())
	var ids: Array = rack.offers.available_offers()
	assert_true(ids.has("get_underglow"))
	assert_true(ids.has("upgrade_flamethrower"))


# --- The heal ------------------------------------------------------------------------------


func test_all_three_maxed_means_a_full_sub_goal_heals_and_opens_no_screen() -> void:
	_max_three()
	assert_true(rack.all_owned_maxed())
	assert_true(state.sub_goal_heals())
	state.damage_car(3.0)
	var hurt := state.health
	var healed := []
	state.sub_goal_healed.connect(func(h: float) -> void: healed.append(h))
	var gifts_before: int = run.gift_drops.helicopters.size() + run.gift_drops.packages.size()
	var popups_before: int = run.trick_popups.popups().size()
	state.add_xp(state.xp_needed())
	assert_eq(healed.size(), 1)
	assert_almost_eq(state.health, hurt + rack.slot_rules.heal_hearts(), 0.001, "the data's hearts")
	assert_false(state.is_waiting_for_choice(), "no level-up screen")
	assert_false(get_tree().paused)
	assert_eq(run.gift_drops.helicopters.size() + run.gift_drops.packages.size(), gifts_before, "no helicopter")
	var texts := []
	for p in run.trick_popups.popups():
		texts.append(p.text)
	assert_eq(run.trick_popups.popups().size(), popups_before + 1)
	assert_true(texts.has(TrickPopups.heal_text()), "the heal message is shown")
	var file_text: String = GameData.get_value(GameData.load_file("screen_texts").data, "heal.popup").data
	assert_eq(TrickPopups.heal_text(), file_text, "the text is the file's")


func test_the_heal_never_goes_above_the_maximum() -> void:
	_max_three()
	state.add_xp(state.xp_needed())
	assert_eq(state.health, state.max_health)


func test_one_weapon_below_its_last_tier_still_drops_a_gift_pack() -> void:
	_own_three()
	_max_out("gun")
	_max_out("flamethrower")
	assert_false(state.sub_goal_heals())
	var before: int = run.gift_drops.helicopters.size()
	state.add_xp(state.xp_needed())
	assert_eq(run.gift_drops.helicopters.size(), before + 1, "the helicopter comes as before")


func test_two_maxed_weapons_with_a_free_slot_do_not_heal() -> void:
	rack.pick("flamethrower")
	_max_out("gun")
	_max_out("flamethrower")
	assert_false(state.sub_goal_heals(), "a third weapon can still be taken")


func test_a_sub_goal_during_the_wreck_does_not_heal() -> void:
	_max_three()
	state.damage_car(state.max_health)
	assert_true(state.wrecked)
	assert_eq(state.heal_for_sub_goal(), 0.0)
	assert_true(state.wrecked)


# --- Power-ups: the cap of 3 -----------------------------------------------------------------


func _power_up_offers(data: PowerUpData = null) -> PowerUpOffers:
	var o := PowerUpOffers.new()
	o.bind(state, data)
	add_child_autofree(o)
	o.rng.seed = 5
	return o


func test_with_three_power_ups_the_gifts_offer_only_those() -> void:
	var o := _power_up_offers()
	var owned := ["rev_charge", "jump", "bouncy_bumpers"]
	for id in owned:
		state.grant_power_up(id)
	assert_eq(o.available_offers(), owned)
	for seed_value in range(20):
		o.rng.seed = seed_value
		for id in o.compute_offers():
			assert_true(owned.has(id))


func test_with_two_power_ups_a_new_one_can_still_be_offered() -> void:
	var o := _power_up_offers()
	state.grant_power_up("rev_charge")
	state.grant_power_up("jump")
	assert_true(o.available_offers().has("rusty_overcoat"))


func test_once_all_three_are_maxed_the_gift_is_skipped() -> void:
	var o := _power_up_offers()
	for id in ["rev_charge", "jump", "bouncy_bumpers"]:
		while state.power_up_tier(id) < o.data.max_tier(id):
			state.grant_power_up(id)
	assert_eq(o.available_offers(), [])
	var skipped := []
	o.gift_skipped.connect(func(i: int) -> void: skipped.append(i))
	state.missions.mission_completed.emit(0)
	assert_eq(skipped, [0], "power_ups.json's offer_when_exhausted, skip_gift: no overlay, no pause")
	assert_false(o.is_showing())
	assert_false(get_tree().paused)


# --- Max tiers come from the data --------------------------------------------------------------


func test_power_up_max_tiers_are_read_from_the_data_file() -> void:
	var raw: Dictionary = GameData.load_file("power_ups").data.duplicate(true)
	# A data file whose power-ups all have a single tier.
	for id in raw["power_ups"]:
		raw["power_ups"][id]["tiers"] = [raw["power_ups"][id]["tiers"][0]]
	raw["max_tier"] = 1
	var f := FileAccess.open(TMP_POWER_UPS, FileAccess.WRITE)
	f.store_string(JSON.stringify(raw))
	f.close()
	var one := PowerUpData.new(TMP_POWER_UPS)
	assert_true(one.is_ok())
	var o := _power_up_offers(one)
	state.grant_power_up("jump")
	assert_false(o.available_offers().has("jump"), "tier 1 is its last tier in this file")
	assert_eq(one.max_tier("jump"), 1)


func test_the_weapons_last_tier_is_the_datas() -> void:
	var data := WeaponData.new()
	for id in ["flamethrower", "underglow"]:
		var w: Node = rack.get_weapon(id)
		assert_eq(w.max_tier(), data.max_tier(id), "%s: the rack takes its last tier from weapons.json" % id)
		_max_out(id)
		assert_true(w.is_max_tier())
		assert_eq(w.tier, data.max_tier(id))
