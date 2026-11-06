extends GutTest
## T-535: the Garage button pulses while the coins cover a garage upgrade that is not maxed.

var PATH := RunPaths.file("test_garage_pulse_t535.json")


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func _progress(coins: int) -> PlayerProgress:
	var p := PlayerProgress.new(null, PATH)
	p.coins = coins
	return p


func _menu(p: PlayerProgress) -> MainMenu:
	var m: MainMenu = load("res://scenes/menu/main_menu.tscn").instantiate()
	m.progress = p
	add_child_autofree(m)
	return m


func _cheapest(p: PlayerProgress) -> int:
	var best := 1000000
	for id in GarageData.UPGRADES:
		best = mini(best, p.next_price(id))
	return best


func test_pulses_with_enough_coins() -> void:
	var p := _progress(0)
	p.coins = _cheapest(p)
	var m := _menu(p)
	assert_true(m.is_garage_pulsing())


func test_no_pulse_with_too_few_coins() -> void:
	var p := _progress(0)
	p.coins = _cheapest(p) - 1
	var m := _menu(p)
	assert_false(m.is_garage_pulsing())
	assert_ne(m.garage_button.get_theme_color("font_color"), MainMenu.LETTER_BLUE)
	assert_eq(m.garage_button.modulate, Color.WHITE)


func test_no_pulse_when_everything_is_maxed() -> void:
	var p := _progress(1000000)
	for id in GarageData.UPGRADES:
		p.levels[id] = p.garage.max_level()
	var m := _menu(p)
	assert_false(m.is_garage_pulsing())


func test_no_pulse_without_progress() -> void:
	var m: MainMenu = load("res://scenes/menu/main_menu.tscn").instantiate()
	add_child_autofree(m)
	assert_false(m.is_garage_pulsing())


func test_letters_are_light_blue_and_button_not_tinted_or_scaled() -> void:
	var m := _menu(_progress(1000000))
	await wait_seconds(MainMenu.PULSE_SECONDS / 4.0)
	var c: Color = m.garage_button.get_theme_color("font_color")
	assert_gt(c.b, c.r, "blue letters")
	assert_gt(c.b, 0.9)
	assert_eq(m.garage_button.modulate, Color.WHITE, "no yellow tint")
	assert_eq(m.garage_button.scale, Vector2.ONE, "no scale pulse")


func test_letters_go_back_when_nothing_can_be_bought() -> void:
	var p := _progress(1000000)
	var m := _menu(p)
	p.coins = 0
	m.refresh_garage_pulse()
	assert_ne(m.garage_button.get_theme_color("font_color"), MainMenu.LETTER_BLUE)
	assert_eq(m.garage_button.get_theme_color("font_color"), m.start_button.get_theme_color("font_color"))


func test_state_updates_after_buying_when_the_menu_comes_back() -> void:
	GameSettings.path = RunPaths.file("test_settings_t535.cfg")
	PlayerProgress.path = PATH
	var flow: GameFlow = load("res://scenes/game/game.tscn").instantiate()
	add_child_autofree(flow)
	await wait_process_frames(2)
	flow.progress = _progress(0)
	flow.progress.coins = _cheapest(flow.progress)
	flow.show_menu()
	await wait_process_frames(1)
	assert_true(flow.menu.is_garage_pulsing())
	flow.show_garage()
	for id in GarageData.UPGRADES:
		while flow.progress.can_buy(id) == PlayerProgress.OK:
			flow.progress.buy(id)
	flow.show_menu()
	await wait_process_frames(1)
	assert_false(flow.menu.is_garage_pulsing(), "coins left cover nothing")
	await wait_process_frames(1)
	DirAccess.remove_absolute(GameSettings.path)
	TestSave.restore_settings()
	TestSave.restore_progress()


func test_buying_in_place_refreshes() -> void:
	var p := _progress(0)
	p.coins = _cheapest(p)
	var m := _menu(p)
	p.coins = 0
	m.refresh_garage_pulse()
	assert_false(m.is_garage_pulsing())
	p.coins = 1000000
	m.refresh_garage_pulse()
	assert_true(m.is_garage_pulsing())


func test_focus_and_chain_unchanged() -> void:
	var m := _menu(_progress(1000000))
	assert_eq(m.get_viewport().gui_get_focus_owner(), m.start_button)
	assert_eq(m.start_button.focus_neighbor_bottom, m.start_button.get_path_to(m.garage_button))
