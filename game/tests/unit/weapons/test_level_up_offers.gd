extends GutTest
## Task T-043: the level-up's weapon choices and applying the one taken.

const RunScene := preload("res://scenes/run/run.tscn")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")

var run: Node2D
var rack: Node
var state: Node
var offers: Node
var shown: Array = []


func before_each() -> void:
	FlameScript.playtest_override = 0
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
	FlameScript.playtest_override = -1
	get_tree().paused = false


func _level_up() -> void:
	state.add_xp(state.xp_needed())


func test_first_level_up_offers_flamethrower_and_gun_upgrade() -> void:
	_level_up()
	assert_eq(shown.size(), 1)
	assert_eq(shown[0][0], 2, "the level reached")
	assert_eq(shown[0][1].size(), 2)
	assert_true(shown[0][1].has("get_flamethrower"))
	assert_true(shown[0][1].has("upgrade_gun"))
	assert_true(get_tree().paused, "the run waits for the choice")


func test_after_taking_the_flamethrower_offers_both_upgrades() -> void:
	_level_up()
	assert_true(offers.choose("get_flamethrower"))
	_level_up()
	assert_eq(shown.size(), 2)
	assert_eq(shown[1][1].size(), 2)
	assert_true(shown[1][1].has("upgrade_gun"))
	assert_true(shown[1][1].has("upgrade_flamethrower"))
	assert_false(shown[1][1].has("get_flamethrower"))


func test_taking_each_choice_applies_it_and_resumes() -> void:
	_level_up()
	assert_true(offers.choose("upgrade_gun"))
	assert_eq(rack.gun.tier, 2)
	assert_false(rack.flamethrower.is_owned())
	assert_false(get_tree().paused, "the run resumes")
	assert_false(state.is_waiting_for_choice())
	assert_false(offers.has_offers())
	_level_up()
	assert_true(offers.choose("get_flamethrower"))
	assert_eq(rack.flamethrower.tier, 1)
	assert_false(get_tree().paused)
	_level_up()
	assert_true(offers.choose("upgrade_flamethrower"))
	assert_eq(rack.flamethrower.tier, 2)
	assert_eq(rack.gun.tier, 2, "the gun was not touched")
	assert_false(get_tree().paused)


func test_a_choice_not_on_offer_is_refused() -> void:
	_level_up()
	assert_false(offers.choose("upgrade_flamethrower"), "not owned yet, so not offered")
	assert_false(offers.choose("nonsense"))
	assert_eq(rack.gun.tier, 1)
	assert_true(get_tree().paused, "still waiting")
	assert_false(offers.choose("") )


func test_choosing_with_no_choice_waiting_does_nothing() -> void:
	assert_false(offers.choose("upgrade_gun"))
	assert_eq(rack.gun.tier, 1)


func test_a_weapon_at_its_last_tier_is_not_offered() -> void:
	rack.gun.set_tier(rack.gun.max_tier())
	_level_up()
	assert_eq(shown[0][1], ["get_flamethrower"], "only the flamethrower is left")
	offers.choose("get_flamethrower")
	rack.flamethrower.set_tier(rack.flamethrower.max_tier() - 1)
	_level_up()
	assert_eq(shown[1][1], ["upgrade_flamethrower"], "the gun is maxed, the flamethrower one tier short")
	offers.choose("upgrade_flamethrower")
	assert_true(rack.flamethrower.is_max_tier())


func test_nothing_to_offer_skips_the_choice_and_resumes() -> void:
	rack.gun.set_tier(rack.gun.max_tier())
	rack.flamethrower.set_tier(rack.flamethrower.max_tier())
	_level_up()
	assert_eq(shown.size(), 0, "no offer is shown")
	assert_false(state.is_waiting_for_choice())
	assert_false(get_tree().paused, "the run goes on")
	assert_eq(state.level, 2)


func test_flamethrower_at_the_start_offers_both_upgrades() -> void:
	FlameScript.playtest_override = 1
	rack.reset_for_run()
	assert_true(rack.flamethrower.is_owned())
	_level_up()
	assert_eq(shown[0][1].size(), 2)
	assert_true(shown[0][1].has("upgrade_gun"))
	assert_true(shown[0][1].has("upgrade_flamethrower"))
	assert_false(shown[0][1].has("get_flamethrower"))


func test_two_level_ups_at_once_offer_in_turn() -> void:
	state.add_xp(state.xp_needed() + RunData.new().xp_needed(2) + 0.5)
	assert_eq(state.level, 3)
	assert_eq(shown.size(), 1, "the first level's choice is on show")
	assert_true(offers.choose("upgrade_gun"))
	assert_eq(shown.size(), 2, "then the second level's")
	assert_eq(shown[1][0], 3)
	assert_true(get_tree().paused)
	assert_true(offers.choose("get_flamethrower"))
	assert_false(get_tree().paused)


func test_a_new_run_clears_the_offer() -> void:
	_level_up()
	state.start_run()
	assert_false(offers.has_offers())
	assert_false(offers.choose("upgrade_gun"))
	assert_false(get_tree().paused)
