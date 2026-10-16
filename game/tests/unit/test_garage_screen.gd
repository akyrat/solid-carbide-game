extends GutTest
## Task T-058: the plain garage screen.

var PATH := RunPaths.file("test_garage_screen_t058.json")
var screen: GarageScreen
var progress: PlayerProgress


func before_each() -> void:
	DirAccess.remove_absolute(PATH)


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func _open(coins: int) -> void:
	progress = PlayerProgress.new(null, PATH)
	progress.coins = coins
	screen = load("res://scenes/menu/garage_screen.tscn").instantiate()
	screen.progress = progress
	add_child_autofree(screen)


func test_every_label_is_the_approved_text() -> void:
	_open(10000)
	assert_eq(screen.title_label.text, "Redgull Pit Stop")
	assert_eq(screen.back_button.text, "Back")
	assert_eq(screen.coins_label.text, "Coins: 10000")
	var names := {"acceleration": "Energy Throttle", "car_health": "Reinforced Chassis", "damage_bonus": "Brand Impact"}
	var descs := {
		"acceleration": "Top speed 0.1 s sooner per level. More drifting, more content.",
		"car_health": "+10 car health per level. Redgull says you'll be fine.",
		"damage_bonus": "+5% weapon damage per level. Redgull calls it synergy.",
	}
	assert_eq(screen.rows.size(), 3)
	for id in names:
		var panel: Node = _find(screen, "Row_" + id)
		assert_eq(panel.find_child("Name", true, false).text, names[id])
		assert_eq(panel.find_child("Description", true, false).text, descs[id])
		var row: Dictionary = screen.rows[id]
		assert_eq(row.level.text, "Level 0")
		assert_eq(row.price.text, "Price: %d" % progress.next_price(id))
		assert_eq(row.buy.text, "Buy")
		assert_eq(row.status.text, "")


func _find(root: Node, node_name: String) -> Node:
	return root.find_child(node_name, true, false)


func test_buying_updates_level_price_and_coins() -> void:
	_open(10000)
	var price := progress.next_price("acceleration")
	screen.rows["acceleration"].buy.pressed.emit()
	assert_eq(progress.level("acceleration"), 1)
	assert_eq(screen.rows["acceleration"].level.text, "Level 1")
	assert_eq(screen.rows["acceleration"].price.text, "Price: %d" % progress.next_price("acceleration"))
	assert_eq(screen.coins_label.text, "Coins: %d" % (10000 - price))
	assert_eq(screen.rows["car_health"].level.text, "Level 0", "other rows unchanged")


func test_unaffordable_shows_message_and_cannot_be_bought() -> void:
	_open(0)
	var row: Dictionary = screen.rows["car_health"]
	assert_eq(row.status.text, "Not enough coins")
	assert_true(row.buy.disabled)
	row.buy.pressed.emit()
	assert_eq(progress.level("car_health"), 0)
	assert_eq(progress.get_coins(), 0)
	assert_eq(row.status.text, "Not enough coins")


func test_becomes_unaffordable_after_spending() -> void:
	_open(0)
	progress.coins = progress.next_price("acceleration")
	screen.refresh()
	assert_false(screen.rows["acceleration"].buy.disabled)
	screen.rows["acceleration"].buy.pressed.emit()
	assert_eq(screen.rows["acceleration"].status.text, "Not enough coins")
	assert_true(screen.rows["acceleration"].buy.disabled)


func test_maxed_shows_message_and_cannot_be_bought() -> void:
	_open(1000000)
	var max_level := progress.garage.max_level()
	for i in max_level:
		screen.rows["damage_bonus"].buy.pressed.emit()
	assert_true(progress.is_maxed("damage_bonus"))
	var row: Dictionary = screen.rows["damage_bonus"]
	assert_eq(row.level.text, "Level %d" % max_level)
	assert_eq(row.status.text, "Fully Funded")
	assert_eq(row.price.text, "")
	assert_true(row.buy.disabled)
	assert_eq(row.buy.modulate.a, 0.0, "the buy button is hidden")
	var coins := progress.get_coins()
	row.buy.pressed.emit()
	assert_eq(progress.get_coins(), coins, "a maxed upgrade is never charged")
	assert_eq(progress.level("damage_bonus"), max_level)


func test_back_button_sends_signal() -> void:
	_open(0)
	watch_signals(screen)
	screen.back_button.pressed.emit()
	assert_signal_emitted(screen, "back_pressed")


func test_follows_changes_made_elsewhere() -> void:
	_open(0)
	progress.bank_run("win", 55)
	assert_eq(screen.coins_label.text, "Coins: 55")
