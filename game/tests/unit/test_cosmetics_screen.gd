extends GutTest
## Task T-553: the Cosmetics submenu, its main menu button, the wiring of the picked effect to the car,
## and the pause screen's jump arrow checkbox.

const PAUSE_SCENE := preload("res://scenes/drift_prototype/drift_prototype.tscn")
var PATH := RunPaths.file("test_cosmetics_t553.json")
var SETTINGS_PATH := RunPaths.file("test_settings_t553.cfg")
const JumpEffectChoice := preload("res://scripts/driving/jump_effect_choice.gd")


func before_each() -> void:
	SafeSave.remove_all(PATH)
	GameSettings.path = SETTINGS_PATH
	DirAccess.remove_absolute(SETTINGS_PATH)


func after_each() -> void:
	SafeSave.remove_all(PATH)
	DirAccess.remove_absolute(SETTINGS_PATH)
	JumpEffectChoice.provider = Callable()
	TestSave.restore_settings()


func _progress(coins: int) -> PlayerProgress:
	var p := PlayerProgress.new(null, PATH)
	p.coins = coins
	return p


func _screen(p: PlayerProgress) -> CosmeticsScreen:
	var s: CosmeticsScreen = load("res://scenes/menu/cosmetics_screen.tscn").instantiate()
	s.progress = p
	add_child_autofree(s)
	return s


func _flow() -> GameFlow:
	var f := GameFlow.new()
	add_child_autofree(f)
	return f


func test_main_menu_button_opens_the_submenu_and_back_returns() -> void:
	var f := _flow()
	assert_not_null(f.menu.cosmetics_button)
	assert_eq(f.menu.cosmetics_button.text, "Cosmetics", "from T-550's menu_button key")
	f.menu.cosmetics_button.pressed.emit()
	assert_null(f.menu)
	assert_not_null(f.cosmetics)
	assert_true(f.cosmetics is CosmeticsScreen)
	f.cosmetics.back_button.pressed.emit()
	assert_null(f.cosmetics)
	assert_not_null(f.menu, "Back returns to the main menu")


func test_lists_five_effects_with_their_texts_and_prices() -> void:
	var p := _progress(0)
	var s := _screen(p)
	var texts := CosmeticsScreen.load_texts()
	assert_eq(s.rows.size(), 5)
	assert_eq(s.title_label.text, texts.title)
	for e in p.cosmetics_list():
		var row = s.get_node("Column/Row_%s" % e.id)
		assert_eq(row.find_child("Name", true, false).text, texts.effects[e.id].name)
		assert_eq(row.find_child("Description", true, false).text, texts.effects[e.id].description)
		if not e.unlocked:
			assert_eq(s.rows[e.id].price.text, texts.locked.replace("{price}", str(e.price)))
			assert_eq(s.rows[e.id].button.text, texts.buy)
	assert_eq(s.coins_label.text, "Coins: 0")
	assert_eq(s.rows["dash_cloud"].state.text, texts.equipped, "the free default is picked at the start")


func test_buy_spends_coins_then_pick_equips() -> void:
	var p := _progress(10000)
	var s := _screen(p)
	var texts := CosmeticsScreen.load_texts()
	var price := p.cosmetics.price("spring")
	s.rows["spring"].button.pressed.emit()
	assert_true(p.is_unlocked("spring"))
	assert_eq(p.get_coins(), 10000 - price)
	assert_eq(s.coins_label.text, "Coins: %d" % (10000 - price))
	assert_eq(s.rows["spring"].button.text, texts.pick, "unlocked now shows the pick button")
	assert_ne(p.equipped_jump_effect(), "spring", "buying does not equip")
	s.rows["spring"].button.pressed.emit()
	assert_eq(p.equipped_jump_effect(), "spring")
	assert_eq(s.rows["spring"].state.text, texts.equipped)
	assert_eq(s.rows["dash_cloud"].button.text, texts.pick, "the old one can be picked again")
	assert_eq(s.message_label.text, "")


func test_refuses_without_enough_coins_with_the_text() -> void:
	var p := _progress(0)
	var s := _screen(p)
	s.rows["jet_thrust"].button.pressed.emit()
	assert_false(p.is_unlocked("jet_thrust"))
	assert_eq(p.get_coins(), 0)
	assert_eq(s.message_label.text, CosmeticsScreen.load_texts().not_enough_coins)


func test_keyboard_order_ends_on_back() -> void:
	var s := _screen(_progress(0))
	var order := s.focus_order()
	assert_eq(order[order.size() - 1], s.back_button)
	assert_eq(order.size(), 5, "four action buttons (the picked one is hidden) and Back")


func test_no_hard_coded_label_in_the_screen() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/menu/cosmetics_screen.gd")
	for key in ["Unlock", "Flex it", "Equipped", "Not enough coins", "Dash cloud"]:
		assert_false(src.contains('"%s' % key), key)


# T-553 (a): the car plays the picked effect.
func test_the_car_plays_the_equipped_effect() -> void:
	var f := _flow()
	assert_eq(JumpEffectChoice.equipped_id(), "dash_cloud")
	f.progress.coins = 100000
	f.progress.buy_cosmetic("shockwave_ring")
	f.progress.equip("shockwave_ring")
	assert_eq(JumpEffectChoice.equipped_id(), "shockwave_ring", "JumpEffectChoice reads T-552's pick")


# T-553 (b): the pause checkbox saves through GameSettings.
func _ps():
	var p: Node2D = PAUSE_SCENE.instantiate()
	add_child_autofree(p)
	p.car.use_keyboard = false
	return p.pause_screen


func test_checkbox_label_default_and_saving() -> void:
	var ps = _ps()
	assert_eq(ps.jump_arrow_check.text, ps.pause_text("jump_arrow_label"))
	assert_eq(ps.jump_arrow_check.text, "Facing arrow")
	assert_true(ps.jump_arrow_check.button_pressed, "on by default")
	assert_eq(ps.jump_arrow_check.get_parent(), ps.drift_guide_check.get_parent(), "next to Drift Guide")
	watch_signals(GameSettings.notifier)
	ps.jump_arrow_check.button_pressed = false
	assert_false(GameSettings.load_jump_arrow_enabled())
	assert_signal_emitted_with_parameters(GameSettings.notifier, "jump_arrow_enabled_changed", [false])
	assert_false(_ps().jump_arrow_check.button_pressed, "a new screen reads the saved choice")
	ps.jump_arrow_check.button_pressed = true
	assert_true(GameSettings.load_jump_arrow_enabled())
