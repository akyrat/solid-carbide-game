extends GutTest
## Task T-504: God mode's logic (scripts/run/god_mode.gd): the N unlock and the tier API.

const RunScene := preload("res://scenes/run/run.tscn")

var run: Node2D
var god: Node


func before_each() -> void:
	GodMode.unlocked = false
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.state.pause_on_level_up = true
	god = run.god_mode


func after_each() -> void:
	GodMode.unlocked = false


func _stats(w: Node) -> Dictionary:
	var out := {}
	for p in w.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.type in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING, TYPE_VECTOR2, TYPE_STRING_NAME]:
			out[p.name] = w.get(p.name)
	return out


func test_n_unlocks_for_the_session_and_a_new_run_keeps_it() -> void:
	assert_false(GodMode.unlocked)
	var ev := InputEventAction.new()
	ev.action = "god_mode_unlock"
	ev.pressed = true
	god._unhandled_input(ev)
	assert_true(GodMode.unlocked)
	run.start_run()
	assert_true(GodMode.unlocked)
	assert_true(InputMap.has_action("god_mode_unlock"))
	var key: InputEventKey = InputMap.action_get_events("god_mode_unlock")[0]
	assert_eq(key.physical_keycode, KEY_N)


func test_unlock_is_not_saved_to_disk() -> void:
	assert_false(FileAccess.file_exists("user://god_mode.json"))
	god.unlock()
	assert_false(FileAccess.file_exists("user://god_mode.json"))


func test_entries_list_every_weapon_and_power_up_from_the_data() -> void:
	var es: Array = god.entries()
	var weapons := es.filter(func(e): return e.kind == "weapon")
	var pups := es.filter(func(e): return e.kind == "power_up")
	assert_eq(weapons.size(), 6)
	assert_eq(pups.size(), PowerUpData.new().ids().size())
	for e in es:
		assert_eq(e.last_tier, god.last_tier(e.kind, e.id))
	assert_eq(god.current_tier("weapon", "gun"), 1)
	assert_eq(god.current_tier("weapon", "nope"), -1)
	assert_eq(god.set_tier("power_up", "nope", 3), -1)


func test_weapon_set_to_5_equals_levelling_1_to_5() -> void:
	var w: Node = run.weapons.get_weapon("flamethrower")
	run.weapons.upgrade("flamethrower")
	for i in 4:
		run.weapons.upgrade("flamethrower")
	var expected := _stats(w)
	god.set_tier("weapon", "flamethrower", 0)
	assert_false(w.is_owned())
	assert_eq(god.set_tier("weapon", "flamethrower", 5), 5)
	assert_eq(_stats(w), expected)
	# Lower, then higher again.
	god.set_tier("weapon", "flamethrower", 2)
	assert_eq(w.tier, 2)
	var at2 := _stats(w)
	god.set_tier("weapon", "flamethrower", 0)
	god.set_tier("weapon", "flamethrower", 2)
	assert_eq(_stats(w), at2)
	god.set_tier("weapon", "flamethrower", 5)
	assert_eq(_stats(w), expected)


func test_zero_removes_a_weapon_but_the_gun_stays_at_1() -> void:
	god.set_tier("weapon", "wiper", 3)
	assert_true(run.weapons.get_weapon("wiper").is_owned())
	god.set_tier("weapon", "wiper", 0)
	assert_false(run.weapons.get_weapon("wiper").is_owned())
	god.set_tier("weapon", "gun", 4)
	assert_eq(run.weapons.gun.tier, 4)
	assert_eq(god.set_tier("weapon", "gun", 0), 1)
	assert_eq(run.weapons.gun.tier, 1)


func test_power_up_tier_matches_gifts_and_zero_removes_it() -> void:
	var data := PowerUpData.new()
	for id in data.ids():
		var last: int = data.max_tier(id)
		for i in last:
			run.state.grant_power_up(id)
		assert_eq(run.state.power_up_tier(id), last)
		god.set_tier("power_up", id, 0)
		assert_eq(run.state.power_up_tier(id), 0)
		assert_eq(god.set_tier("power_up", id, 2), mini(2, last))
		assert_eq(run.state.power_up_tier(id), mini(2, last))
		assert_eq(god.set_tier("power_up", id, 99), last)
	# The car follows (jump / rev charge tiers).
	assert_eq(run.car.jump.tier, run.state.power_up_tier("jump"))


func test_level_up_offers_never_offer_a_weapon_at_its_last_tier() -> void:
	var last: int = god.last_tier("weapon", "gun")
	god.set_tier("weapon", "gun", last)
	assert_false(run.weapons.offers.available_offers().has("upgrade_gun"))
	god.set_tier("weapon", "bricks", god.last_tier("weapon", "bricks"))
	var offers: Array = run.weapons.offers.available_offers()
	assert_false(offers.has("upgrade_bricks"))
	assert_false(offers.has("get_bricks"))


func test_gifts_offer_only_what_is_left() -> void:
	var first: String = PowerUpData.new().ids()[0]
	god.set_tier("power_up", first, god.last_tier("power_up", first))
	assert_false(run.power_up_offers.available_offers().has(first))


func test_a_new_run_starts_with_the_gun_at_tier_1_only() -> void:
	for e in god.entries():
		god.set_tier(e.kind, e.id, e.last_tier)
	run.start_run()
	assert_eq(run.weapons.owned_tiers(), {"gun": 1})
	assert_true(run.state.owned_power_ups().is_empty())
