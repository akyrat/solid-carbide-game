extends GutTest
## T-552: the cosmetics data, buying and equipping jump effects, the saved choice.

var PATH := RunPaths.file("test_cosmetics_t552.json")


func before_each() -> void:
	SafeSave.remove_all(PATH)


func after_each() -> void:
	SafeSave.remove_all(PATH)


func _new(coins: int = 0) -> PlayerProgress:
	var p := PlayerProgress.new(null, PATH)
	p.coins = coins
	return p


func test_data_lists_five_effects_dash_cloud_free() -> void:
	var c := CosmeticsData.new()
	assert_true(c.is_ok(), c.error)
	assert_eq(c.jump_effect_ids(), ["dash_cloud", "spring", "jet_thrust", "stunt_sparks", "shockwave_ring"])
	assert_eq(c.price("dash_cloud"), 0)
	for id in c.jump_effect_ids().slice(1):
		assert_gt(c.price(id), 0, id)
	assert_eq(c.price("nope"), -1)


func test_new_player_has_dash_cloud_unlocked_and_picked() -> void:
	var p := _new()
	assert_true(p.is_unlocked("dash_cloud"))
	assert_false(p.is_unlocked("spring"))
	assert_eq(p.equipped_jump_effect(), "dash_cloud")
	assert_eq(p.cosmetics_list().size(), 5)


func test_buy_spends_and_unlocks() -> void:
	var p := _new(200)
	assert_true(p.can_afford("spring"))
	var r := p.buy_cosmetic("spring")
	assert_true(r.ok)
	assert_eq(p.get_coins(), 200 - p.cosmetics.price("spring"))
	assert_true(p.is_unlocked("spring"))
	assert_eq(p.equipped_jump_effect(), "dash_cloud", "buying does not equip")


func test_buy_refused_without_coins_or_twice_or_unknown() -> void:
	var p := _new(10)
	assert_false(p.can_afford("spring"))
	var r := p.buy_cosmetic("spring")
	assert_false(r.ok)
	assert_eq(r.reason, PlayerProgress.NOT_ENOUGH_COINS)
	assert_eq(p.get_coins(), 10)
	assert_false(p.is_unlocked("spring"))
	assert_eq(p.buy_cosmetic("dash_cloud").reason, PlayerProgress.ALREADY_UNLOCKED)
	assert_eq(p.buy_cosmetic("nope").reason, PlayerProgress.UNKNOWN_COSMETIC)
	assert_false(p.can_afford("nope"))


func test_equip_needs_unlock_and_survives_reload() -> void:
	var p := _new(1000)
	assert_false(p.equip("jet_thrust"))
	assert_eq(p.equipped_jump_effect(), "dash_cloud")
	p.buy_cosmetic("jet_thrust")
	assert_true(p.equip("jet_thrust"))
	var q := PlayerProgress.new(null, PATH)
	assert_true(q.is_unlocked("jet_thrust"))
	assert_eq(q.equipped_jump_effect(), "jet_thrust")
	assert_eq(q.get_coins(), 1000 - q.cosmetics.price("jet_thrust"))


func test_old_save_without_cosmetics_keeps_everything() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"coins": 77, "levels": {"acceleration": 3}, "version": 1}))
	f.close()
	var p := PlayerProgress.new(null, PATH)
	assert_eq(p.get_coins(), 77)
	assert_eq(p.level("acceleration"), 3)
	assert_true(p.is_unlocked("dash_cloud"))
	assert_eq(p.equipped_jump_effect(), "dash_cloud")


func test_odd_saved_choice_falls_back() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"coins": 5, "levels": {}, "cosmetics": {"unlocked": ["ghost"], "jump_effect": "spring"}}))
	f.close()
	var p := PlayerProgress.new(null, PATH)
	assert_false(p.is_unlocked("ghost"))
	assert_eq(p.equipped_jump_effect(), "dash_cloud", "a locked pick is not kept")
