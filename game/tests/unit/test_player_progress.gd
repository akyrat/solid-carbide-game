extends GutTest
## Task T-057: saving coins and upgrade levels, banking a run, buying.

var PATH := RunPaths.file("test_progress_t057.json")


func before_each() -> void:
	DirAccess.remove_absolute(PATH)


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func _new() -> PlayerProgress:
	return PlayerProgress.new(null, PATH)


func _rich(coins: int) -> PlayerProgress:
	var p := _new()
	p.coins = coins
	return p


func test_no_file_is_a_new_player() -> void:
	var p := _new()
	assert_eq(p.get_coins(), 0)
	for id in GarageData.UPGRADES:
		assert_eq(p.level(id), 0, id)


func test_run_end_banks_coins_and_saves() -> void:
	var state := RunState.new()
	var p := _new()
	p.connect_run(state)
	state.run_ended.emit("loss", 120)
	assert_eq(p.get_coins(), 120)
	assert_eq(_new().get_coins(), 120, "saved to disk")
	state.run_ended.emit("win", 30)
	assert_eq(_new().get_coins(), 150, "adds up")


func test_buy_spends_raises_and_saves() -> void:
	var p := _rich(100)
	var price := p.next_price("acceleration")
	var r := p.buy("acceleration")
	assert_true(r.ok)
	assert_eq(p.get_coins(), 100 - price)
	assert_eq(p.level("acceleration"), 1)
	var q := _new()
	assert_eq(q.get_coins(), 100 - price)
	assert_eq(q.level("acceleration"), 1)


func test_buy_refused_with_too_few_coins() -> void:
	var p := _rich(10)
	var r := p.buy("car_health")
	assert_false(r.ok)
	assert_eq(r.reason, PlayerProgress.NOT_ENOUGH_COINS)
	assert_eq(p.get_coins(), 10)
	assert_eq(p.level("car_health"), 0)
	assert_false(FileAccess.file_exists(PATH), "nothing saved")


func test_buy_refused_at_last_level() -> void:
	var p := _rich(100000)
	var g := GarageData.new()
	for i in g.max_level():
		assert_true(p.buy("damage_bonus").ok)
	assert_true(p.is_maxed("damage_bonus"))
	var coins := p.get_coins()
	var r := p.buy("damage_bonus")
	assert_false(r.ok)
	assert_eq(r.reason, PlayerProgress.MAXED)
	assert_eq(p.get_coins(), coins)
	assert_eq(p.level("damage_bonus"), g.max_level())
	assert_eq(p.next_price("damage_bonus"), -1)


func test_unknown_upgrade_refused() -> void:
	var p := _rich(100)
	assert_eq(p.buy("nope").reason, PlayerProgress.UNKNOWN_UPGRADE)
	assert_eq(p.get_coins(), 100)


func test_save_and_reload_same_state() -> void:
	var p := _rich(500)
	p.buy("acceleration")
	p.buy("acceleration")
	p.buy("damage_bonus")
	p.bank_run("win", 77)
	var q := _new()
	assert_eq(q.get_coins(), p.get_coins())
	for id in GarageData.UPGRADES:
		assert_eq(q.level(id), p.level(id), id)


func test_info_and_values() -> void:
	var p := _rich(1000)
	var g := GarageData.new()
	var i := p.info("car_health")
	assert_eq(i.level, 0)
	assert_eq(i.next_price, g.price("car_health", 1))
	assert_eq(i.current_value, g.value("car_health", 0))
	assert_eq(i.next_value, g.value("car_health", 1))
	assert_true(i.can_buy)
	p.buy("car_health")
	assert_eq(p.current_value("car_health"), g.value("car_health", 1))


func test_broken_file_is_a_new_player() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("not json")
	f.close()
	assert_eq(_new().get_coins(), 0)
