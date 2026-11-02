extends GutTest
## T-492: the main menu and the garage work with the arrow keys alone.

var PATH := RunPaths.file("test_menu_arrow_keys_t492.json")


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func _key(code: Key, pressed := true, echo := false) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = pressed
	e.echo = echo
	return e


## Sends the key to the viewport the way the engine does, so focus movement and button presses run.
func _press(code: Key) -> void:
	get_viewport().push_input(_key(code, true))
	get_viewport().push_input(_key(code, false))


func _menu() -> MainMenu:
	var m: MainMenu = load("res://scenes/menu/main_menu.tscn").instantiate()
	add_child_autofree(m)
	return m


func _garage(coins: int) -> GarageScreen:
	var p := PlayerProgress.new(null, PATH)
	p.coins = coins
	var g: GarageScreen = load("res://scenes/menu/garage_screen.tscn").instantiate()
	g.progress = p
	add_child_autofree(g)
	return g


func _focus() -> Control:
	return get_viewport().gui_get_focus_owner()


func test_menu_opens_on_start_and_arrows_walk_every_button() -> void:
	var m := _menu()
	assert_eq(_focus(), m.start_button)
	_press(KEY_DOWN)
	assert_eq(_focus(), m.garage_button)
	_press(KEY_DOWN)
	assert_eq(_focus(), m.exit_button)
	_press(KEY_DOWN)
	assert_eq(_focus(), m.start_button, "down wraps round")
	_press(KEY_UP)
	assert_eq(_focus(), m.exit_button, "up wraps round")
	_press(KEY_UP)
	assert_eq(_focus(), m.garage_button)


func test_menu_left_and_right_keep_the_selection() -> void:
	var m := _menu()
	_press(KEY_RIGHT)
	assert_eq(_focus(), m.start_button)
	_press(KEY_LEFT)
	assert_eq(_focus(), m.start_button)


func test_menu_enter_and_space_press_the_selected_button() -> void:
	var m := _menu()
	watch_signals(m)
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_signal_emitted(m, "garage_pressed")
	_press(KEY_DOWN)
	_press(KEY_SPACE)
	assert_signal_emitted(m, "exit_pressed")
	assert_signal_not_emitted(m, "start_pressed")


func test_menu_a_held_key_opening_the_screen_does_nothing() -> void:
	var m := _menu()
	watch_signals(m)
	# the key went down on the screen before: only its repeats arrive
	get_viewport().push_input(_key(KEY_ENTER, true, true))
	get_viewport().push_input(_key(KEY_ENTER, false))
	assert_signal_not_emitted(m, "start_pressed")


func test_garage_opens_on_the_first_upgrade_and_arrows_walk_all_buttons() -> void:
	var g := _garage(100000)
	var ids: Array = GarageData.UPGRADES
	assert_eq(_focus(), g.rows[ids[0]].buy)
	for i in range(1, ids.size()):
		_press(KEY_DOWN)
		assert_eq(_focus(), g.rows[ids[i]].buy, "down reaches upgrade %d" % i)
	_press(KEY_DOWN)
	assert_eq(_focus(), g.back_button)
	_press(KEY_DOWN)
	assert_eq(_focus(), g.rows[ids[0]].buy, "wraps to the top")
	_press(KEY_UP)
	assert_eq(_focus(), g.back_button, "up wraps to Back")
	_press(KEY_UP)
	assert_eq(_focus(), g.rows[ids[ids.size() - 1]].buy)
	_press(KEY_LEFT)
	_press(KEY_RIGHT)
	assert_eq(_focus(), g.rows[ids[ids.size() - 1]].buy, "left and right stay put")


func test_garage_enter_buys_and_space_buys_the_selected_upgrade() -> void:
	var g := _garage(100000)
	var ids: Array = GarageData.UPGRADES
	var b0: int = g.progress.info(ids[0]).level
	var b1: int = g.progress.info(ids[1]).level
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_eq(g.progress.info(ids[1]).level, b1 + 1)
	assert_eq(g.progress.info(ids[0]).level, b0)
	_press(KEY_SPACE)
	assert_eq(g.progress.info(ids[1]).level, b1 + 2)


func test_garage_back_is_pressed_by_enter() -> void:
	var g := _garage(0)
	watch_signals(g)
	_press(KEY_UP)  # from the first Buy, wraps to Back
	assert_eq(_focus(), g.back_button)
	_press(KEY_ENTER)
	assert_signal_emitted(g, "back_pressed")


func test_garage_too_poor_buys_stay_selectable_but_do_nothing() -> void:
	var g := _garage(0)
	var ids: Array = GarageData.UPGRADES
	assert_eq(_focus(), g.rows[ids[0]].buy, "the selection rests on a disabled Buy")
	_press(KEY_DOWN)
	assert_eq(_focus(), g.rows[ids[1]].buy)
	var before: int = g.progress.info(ids[1]).level
	_press(KEY_ENTER)
	assert_eq(g.progress.info(ids[1]).level, before)


func test_garage_held_key_on_open_buys_nothing() -> void:
	var g := _garage(100000)
	var before := {}
	for id in g.rows:
		before[id] = g.progress.info(id).level
	get_viewport().push_input(_key(KEY_ENTER, true, true))
	get_viewport().push_input(_key(KEY_ENTER, false))
	for id in g.rows:
		assert_eq(g.progress.info(id).level, before[id])


func test_garage_a_maxed_upgrade_is_skipped_and_hands_on_the_selection() -> void:
	var g := _garage(100000000)
	var ids: Array = GarageData.UPGRADES
	var first: String = ids[0]
	var guard := 0
	while not g.progress.info(first).maxed and guard < 100:
		_press(KEY_ENTER)
		guard += 1
	assert_true(g.progress.info(first).maxed)
	assert_eq(_focus(), g.rows[ids[1]].buy, "selection moved on from the maxed upgrade")
	_press(KEY_UP)
	assert_eq(_focus(), g.back_button, "up from the second goes past the maxed first to Back")


func test_wasd_menu_moves_like_the_arrows() -> void:
	var m := _menu()
	_press(KEY_S)
	assert_eq(_focus(), m.garage_button)
	_press(KEY_S)
	assert_eq(_focus(), m.exit_button)
	_press(KEY_S)
	assert_eq(_focus(), m.start_button, "S wraps round")
	_press(KEY_W)
	assert_eq(_focus(), m.exit_button, "W wraps round")
	_press(KEY_A)
	_press(KEY_D)
	assert_eq(_focus(), m.exit_button, "A and D keep the selection")


func test_wasd_menu_space_and_enter_still_press() -> void:
	var m := _menu()
	watch_signals(m)
	_press(KEY_S)
	_press(KEY_SPACE)
	assert_signal_emitted(m, "garage_pressed")


func test_wasd_garage_walks_every_button() -> void:
	var g := _garage(100000)
	var ids: Array = GarageData.UPGRADES
	for i in range(1, ids.size()):
		_press(KEY_S)
		assert_eq(_focus(), g.rows[ids[i]].buy)
	_press(KEY_S)
	assert_eq(_focus(), g.back_button)
	_press(KEY_S)
	assert_eq(_focus(), g.rows[ids[0]].buy, "wraps to the top")
	_press(KEY_W)
	assert_eq(_focus(), g.back_button)
	_press(KEY_A)
	_press(KEY_D)
	assert_eq(_focus(), g.back_button)


func test_wasd_a_held_key_repeat_does_nothing() -> void:
	var m := _menu()
	get_viewport().push_input(_key(KEY_S, true, true))
	assert_eq(_focus(), m.start_button)
	var g := _garage(100000)
	get_viewport().push_input(_key(KEY_S, true, true))
	assert_eq(_focus(), g.rows[GarageData.UPGRADES[0]].buy)
