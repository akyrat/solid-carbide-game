extends GutTest
## Task T-052: the level-up (gift pack) screen: two cards, take one.

const RunScene := preload("res://scenes/run/run.tscn")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const PauseScript := preload("res://scripts/ui/pause_screen.gd")
const Texts := preload("res://scripts/ui/level_up_texts.gd")

var run: Node2D
var state: Node
var screen: CanvasLayer
var offers: Node
var pause: CanvasLayer


func before_each() -> void:
	FlameScript.playtest_override = -1  # read data/playtest.json
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	state = run.state
	screen = run.level_up_screen
	offers = run.weapons.offers
	pause = PauseScript.new()
	run.add_child(pause)
	pause.setup(run)


func after_each() -> void:
	FlameScript.playtest_override = -1
	get_tree().paused = false


func _level_up() -> void:
	state.add_xp(state.xp_needed())


func _key(code: int, pressed := true, echo := false) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code as Key
	e.pressed = pressed
	e.echo = echo
	screen._input(e)


func _card(id: String) -> Dictionary:
	return screen.cards.filter(func(c): return c.id == id)[0]


func test_the_screen_is_in_the_run_and_the_level_up_pause_is_on() -> void:
	assert_not_null(screen)
	assert_true(state.pause_on_level_up)
	assert_false(screen.visible, "closed until a level-up")


func test_level_up_opens_two_cards_with_the_approved_text() -> void:
	_level_up()
	assert_true(get_tree().paused, "the run pauses")
	assert_true(screen.visible)
	assert_eq(screen.cards.size(), 2)
	var ids: Array = screen.cards.map(func(c): return c.id)
	assert_eq(ids, offers.current_offers)
	assert_true(ids.has("get_flamethrower") and ids.has("upgrade_gun"))
	for c in screen.cards:
		var key: String = "get_flamethrower" if c.id == "get_flamethrower" else "upgrade_gun.tier2"
		assert_eq(c.title.text, Texts.TEXTS[key + ".title"])
		assert_eq(c.desc.text, Texts.TEXTS[key + ".desc"])
		assert_eq(c.button.text, "Take it")
	assert_eq(screen.title_label.text, "Redgull Sent a Gift Pack!")


func test_exact_text_for_known_cards() -> void:
	assert_eq(Texts.TEXTS["get_flamethrower.title"], "Hot Take Exhaust")
	assert_eq(Texts.TEXTS["upgrade_gun.tier4.desc"], "Fires 20% faster again. Engagement waits for no one.")
	assert_eq(Texts.TEXTS["levelup.take"], "Take it")
	assert_eq(Texts.TEXTS.size(), 32)


func test_upgrade_card_shows_the_next_tier_text() -> void:
	run.weapons.gun.set_tier(3)
	_level_up()
	var c := _card("upgrade_gun")
	assert_eq(c.title.text, Texts.TEXTS["upgrade_gun.tier4.title"])
	assert_eq(c.desc.text, Texts.TEXTS["upgrade_gun.tier4.desc"])


func test_flamethrower_upgrade_card_shows_its_next_tier() -> void:
	run.weapons.flamethrower.set_tier(4)
	_level_up()
	var c := _card("upgrade_flamethrower")
	assert_eq(c.title.text, Texts.TEXTS["upgrade_flamethrower.tier5.title"])
	assert_eq(c.desc.text, Texts.TEXTS["upgrade_flamethrower.tier5.desc"])


func test_pressing_a_cards_button_takes_it_and_closes() -> void:
	_level_up()
	var taken: Array = []
	offers.offer_taken.connect(func(id): taken.append(id))
	_card("get_flamethrower").button.pressed.emit()
	assert_eq(taken, ["get_flamethrower"])
	assert_eq(run.weapons.flamethrower.tier, 1, "applied")
	assert_false(screen.visible)
	assert_false(get_tree().paused, "the run resumes")
	assert_false(state.is_waiting_for_choice())


func test_real_mouse_click_on_the_button_takes_the_card() -> void:
	var win := get_window()
	var old_size := win.size
	win.size = Vector2i(1152, 648)
	_level_up()
	await wait_process_frames(3)
	var b: Button = _card("upgrade_gun").button
	var pos := b.get_global_rect().get_center()
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = pos
		e.global_position = pos
		e.pressed = pressed
		get_viewport().push_input(e)
		await wait_process_frames(1)
	win.size = old_size
	assert_eq(run.weapons.gun.tier, 2, "the gun card was taken by the click")
	assert_false(get_tree().paused)


func test_first_card_starts_highlighted_and_keys_move_it() -> void:
	_level_up()
	assert_eq(screen.highlight, 0)
	_key(KEY_D)
	assert_eq(screen.highlight, 1)
	_key(KEY_D)
	assert_eq(screen.highlight, 1, "stops at the last card")
	_key(KEY_A)
	assert_eq(screen.highlight, 0)
	_key(KEY_RIGHT)
	assert_eq(screen.highlight, 1)
	_key(KEY_LEFT)
	assert_eq(screen.highlight, 0)


func test_highlighted_card_has_the_thicker_yellow_border() -> void:
	_level_up()
	var a: StyleBoxFlat = screen.cards[0].panel.get_theme_stylebox("panel")
	var b: StyleBoxFlat = screen.cards[1].panel.get_theme_stylebox("panel")
	assert_gt(a.border_width_left, b.border_width_left)
	assert_eq(a.border_color, screen.RING)
	assert_eq(b.border_color, Color.BLACK)
	_key(KEY_D)
	a = screen.cards[0].panel.get_theme_stylebox("panel")
	b = screen.cards[1].panel.get_theme_stylebox("panel")
	assert_gt(b.border_width_left, a.border_width_left, "the ring moved")


func test_enter_takes_the_highlighted_card() -> void:
	_level_up()
	_key(KEY_D)
	var id: String = screen.cards[1].id
	_key(KEY_ENTER)
	assert_eq(id, "get_flamethrower")
	assert_eq(run.weapons.flamethrower.tier, 1, "the second card, the flamethrower")
	assert_false(get_tree().paused)


func test_space_takes_the_highlighted_card() -> void:
	_level_up()
	_key(KEY_SPACE)
	assert_eq(run.weapons.gun.tier, 2)
	assert_false(screen.visible)


func test_key_repeat_echo_takes_nothing() -> void:
	_level_up()
	_key(KEY_SPACE, true, true)
	_key(KEY_D, true, true)
	assert_eq(screen.highlight, 0)
	assert_true(screen.visible)
	assert_eq(run.weapons.gun.tier, 1)


func test_a_key_held_when_the_screen_opens_takes_nothing_until_let_go() -> void:
	screen.key_down = func(k: int) -> bool: return k == KEY_SPACE or k == KEY_D
	_level_up()
	_key(KEY_SPACE)
	_key(KEY_D)
	assert_true(screen.visible, "nothing taken")
	assert_eq(screen.highlight, 0, "nothing moved")
	_key(KEY_SPACE, false)
	_key(KEY_D, false)
	_key(KEY_D)
	assert_eq(screen.highlight, 1, "a fresh press counts")
	_key(KEY_SPACE)
	assert_false(screen.visible, "taken")


func test_escape_does_not_resume_or_close_while_the_choice_is_open() -> void:
	_level_up()
	var press := InputEventAction.new()
	press.action = "pause"
	press.pressed = true
	pause._input(press)
	assert_true(get_tree().paused, "still paused")
	assert_true(screen.visible, "screen still open")
	assert_false(pause.visible, "no pause screen on top")
	assert_true(state.is_waiting_for_choice())
	pause.toggle()
	assert_true(get_tree().paused)
	assert_true(state.is_waiting_for_choice())


func test_escape_still_pauses_and_resumes_a_normal_run() -> void:
	pause.toggle()
	assert_true(get_tree().paused)
	pause.toggle()
	assert_false(get_tree().paused)


func test_two_waiting_level_ups_show_one_screen_after_the_other() -> void:
	state.add_xp(state.xp_needed() * 2.5)  # more than one level at once
	var waiting: int = state.pending_choices.size()
	assert_gte(waiting, 2)
	screen.take(screen.cards[0].id)
	assert_true(screen.visible, "the next level-up's cards show")
	assert_eq(state.pending_choices.size(), waiting - 1)
	assert_true(get_tree().paused)


func test_normal_run_first_level_up_offers_flamethrower_and_gun_upgrade() -> void:
	assert_false(FlameScript.playtest_switch_on(), "flamethrower_at_start is false")
	var r := GameData.load_file("playtest")
	assert_eq(r.data["flamethrower_at_start"], false)
	run.start_run()
	assert_eq(run.weapons.flamethrower.tier, 0)
	_level_up()
	var ids: Array = screen.cards.map(func(c): return c.id)
	assert_eq(ids, ["upgrade_gun", "get_flamethrower"])


func test_a_new_run_closes_the_screen() -> void:
	_level_up()
	run.start_run()
	assert_false(screen.visible)
	assert_false(get_tree().paused)


func test_look_is_comic_white_cards_black_text() -> void:
	_level_up()
	for c in screen.cards:
		var st: StyleBoxFlat = c.panel.get_theme_stylebox("panel")
		assert_eq(st.bg_color, Color.WHITE)
		assert_false(st.anti_aliasing, "hard edges")
		assert_eq(c.title.get_theme_color("font_color"), Color.BLACK)
		assert_eq(c.desc.get_theme_color("font_color"), Color.BLACK)
		var f: FontFile = c.title.get_theme_font("font")
		assert_true(f.get_font_name().to_lower().contains("bangers"), f.get_font_name())
		assert_eq(f.antialiasing, TextServer.FONT_ANTIALIASING_NONE)


func test_later_level_ups_show_laid_out_cards_without_a_resize() -> void:
	var win := get_window()
	var old_size := win.size
	win.size = Vector2i(1152, 648)
	await wait_process_frames(2)
	var vp := Rect2(Vector2.ZERO, Vector2(win.size))
	for n in 3:
		_level_up()
		await wait_process_frames(2)
		assert_true(screen.is_open(), "level-up %d: open" % (n + 1))
		for c in screen.cards:
			var r: Rect2 = c.panel.get_global_rect()
			assert_true(c.panel.is_visible_in_tree(), "level-up %d: visible" % (n + 1))
			assert_gte(r.size.x, screen.CARD_SIZE.x - 1.0, "level-up %d: real width" % (n + 1))
			assert_gte(r.size.y, screen.CARD_SIZE.y - 1.0, "level-up %d: real height" % (n + 1))
			assert_true(vp.encloses(r), "level-up %d: card %s inside the window: %s" % [n + 1, c.id, r])
			assert_gt(c.button.get_global_rect().size.x, 100.0, "button laid out")
		var a: Rect2 = screen.cards[0].panel.get_global_rect()
		var b: Rect2 = screen.cards[1].panel.get_global_rect() if screen.cards.size() > 1 else a
		if screen.cards.size() > 1:
			assert_gt(b.position.x, a.end.x - 1.0, "cards side by side, not stacked")
		screen.take_highlighted()
		await wait_process_frames(2)
		assert_false(screen.visible)
	win.size = old_size
