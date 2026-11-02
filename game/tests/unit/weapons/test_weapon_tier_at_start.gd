extends GutTest
## Task T-500: the playtest switch weapon_tier_at_start (data/playtest.json), with
## all_weapons_at_start on, starts every weapon at that tier capped at its own max_tier.

const RunScene := preload("res://scenes/run/run.tscn")
const RackScript := preload("res://scripts/weapons/weapons.gd")
const OffersScript := preload("res://scripts/weapons/level_up_offers.gd")

var run: Node2D
var rack: Node


func before_each() -> void:
	RackScript.all_weapons_override = 1
	RackScript.weapon_tier_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	rack = run.weapons
	run.state.pause_on_level_up = true


func after_each() -> void:
	RackScript.all_weapons_override = -1
	RackScript.weapon_tier_override = -1


## The weapon's plain script variables (numbers, strings, bools, vectors), for comparing stats.
func _stats(w: Node) -> Dictionary:
	var out := {}
	for p in w.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.type in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING, TYPE_VECTOR2, TYPE_STRING_NAME]:
			out[p.name] = w.get(p.name)
	return out


func test_tier_8_puts_every_weapon_at_min_8_and_its_max_tier() -> void:
	RackScript.weapon_tier_override = 8
	rack.reset_for_run()
	var stats := {}
	for id in rack.weapons:
		var w: Node = rack.get_weapon(id)
		assert_eq(w.tier, mini(8, w.max_tier()), id + " at min(8, max_tier)")
		stats[id] = _stats(w)
	# The same weapons levelled up tier by tier from the tier-1 start.
	RackScript.weapon_tier_override = 0
	rack.reset_for_run()
	for id in rack.weapons:
		var w: Node = rack.get_weapon(id)
		assert_eq(w.tier, 1, id + " back at tier 1")
		while w.tier < mini(8, w.max_tier()):
			assert_true(rack.upgrade(id))
		assert_eq(_stats(w), stats[id], id + " same stats as levelling up in order")


func test_a_tier_above_a_max_tier_is_capped() -> void:
	RackScript.weapon_tier_override = 99
	rack.reset_for_run()
	for id in rack.weapons:
		var w: Node = rack.get_weapon(id)
		assert_eq(w.tier, w.max_tier(), id + " at its last tier")


func test_tier_2_gives_every_weapon_tier_2() -> void:
	RackScript.weapon_tier_override = 2
	rack.reset_for_run()
	for id in rack.weapons:
		assert_eq(rack.get_weapon(id).tier, mini(2, rack.get_weapon(id).max_tier()), id)


func test_tier_switch_alone_does_nothing_without_all_weapons() -> void:
	RackScript.all_weapons_override = 0
	RackScript.weapon_tier_override = 8
	rack.reset_for_run()
	assert_eq(rack.owned_ids(), ["gun"])
	assert_eq(rack.get_weapon("gun").tier, 1)


func test_tier_0_starts_as_before_gun_at_tier_1_only() -> void:
	RackScript.all_weapons_override = 0
	RackScript.weapon_tier_override = 0
	rack.reset_for_run()
	assert_eq(rack.owned_ids(), ["gun"])
	assert_eq(rack.get_weapon("gun").tier, 1)


func test_tier_0_with_all_weapons_gives_all_at_tier_1() -> void:
	rack.reset_for_run()
	for id in rack.weapons:
		assert_eq(rack.get_weapon(id).tier, 1, id)


func test_offers_never_offer_a_weapon_at_its_last_tier() -> void:
	RackScript.weapon_tier_override = 8
	rack.reset_for_run()
	var shown: Array = []
	rack.offers.offers_ready.connect(func(_l: int, ids: Array) -> void: shown.append(ids))
	for i in 20:
		var before := shown.size()
		run.state.add_xp(run.state.xp_needed())
		if shown.size() == before:
			break
		for id in shown[-1]:
			var w: Node = rack.get_weapon(OffersScript.weapon_of(id))
			assert_lt(w.tier, w.max_tier(), id + " is not offered at its last tier")
		rack.offers.choose(shown[-1][0])


func test_the_committed_file_has_the_switch_off() -> void:
	var r := GameData.load_file(RackScript.PLAYTEST_FILE)
	assert_true(r.ok)
	var v := GameData.get_value(r.data, RackScript.WEAPON_TIER_KEY)
	assert_true(v.ok, "the key is in data/playtest.json")
	assert_eq(int(v.data), 0)
	assert_false(bool(GameData.get_value(r.data, RackScript.ALL_WEAPONS_KEY).data))
	RackScript.weapon_tier_override = -1
	assert_eq(RackScript.weapon_tier_at_start(), 0)
