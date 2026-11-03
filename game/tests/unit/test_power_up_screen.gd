extends GutTest
## Task T-459: the driving power-up overlay in the run: a completed mission pauses the run
## and shows the cards; choosing with the keys or the mouse grants the power-up and resumes;
## Escape doesn't pause over it; it never shows at once with the level-up screen.

const RunScene := preload("res://scenes/run/run.tscn")
const PauseScript := preload("res://scripts/ui/pause_screen.gd")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")

var run: Node2D
var state: RunState
var screen: PowerUpScreen
var offers: PowerUpOffers
var level_up: CanvasLayer
var pause: CanvasLayer
var data: PowerUpData


func before_each() -> void:
	FlameScript.playtest_override = -1
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	state = run.state
	screen = run.power_up_screen
	offers = run.power_up_offers
	level_up = run.level_up_screen
	data = offers.data
	offers.rng.seed = 3
	pause = PauseScript.new()
	run.add_child(pause)
	pause.setup(run)


func after_each() -> void:
	FlameScript.playtest_override = -1
	get_tree().paused = false


func _complete_mission(index := 0) -> void:
	state.missions.mission_completed.emit(index)


func _open() -> void:
	_complete_mission()
	screen.skip_animation()


func _key(code: int, pressed := true, echo := false) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code as Key
	e.pressed = pressed
	e.echo = echo
	screen._input(e)


func _texts() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/screen_texts.json"))["power_ups"]


func test_the_overlay_is_in_the_run_and_closed_at_the_start() -> void:
	assert_not_null(screen)
	assert_false(screen.visible)
	assert_false(get_tree().paused)


func test_a_completed_mission_pauses_the_run_and_shows_two_cards() -> void:
	_complete_mission()
	assert_true(get_tree().paused, "the run pauses")
	assert_true(screen.visible)
	assert_eq(screen.cards.size(), 2)
	assert_eq(screen.cards.map(func(c): return c.id), offers.current_offers)


func test_the_texts_are_t456s_word_for_word() -> void:
	_open()
	var t := _texts()
	assert_eq(screen.title_label.text, "Mission done: pimp your ride")
	assert_eq(screen.title_label.text, t["overlay_header"])
	for c in screen.cards:
		assert_false(c.has("button"), "T-475: no take button")
		assert_null(c.panel.find_child("TakeButton", true, false))
		assert_eq(c.name.text, t["names"][c.id])
		assert_eq(c.tier, 1)


func test_each_description_names_the_offered_tiers_numbers() -> void:
	assert_eq(PowerUpScreen.describe(data, "rev_charge", 1),
			"Hold Gas+Brake then release the Brake: speed boost.")
	assert_eq(PowerUpScreen.describe(data, "jump", 1),
			"Press Space to Jump.")
	# T-519: the last tier (tier 2 of 2 in the 4-minute run) has its own line, with its numbers.
	var last_jump := data.max_tier("jump")
	assert_eq(PowerUpScreen.describe(data, "jump", last_jump),
			"Press Space to Jump higher.")
	assert_eq(PowerUpScreen.describe(data, "bouncy_bumpers", data.max_tier("bouncy_bumpers")),
			"Bounce 2.6x farther off walls and obstacles.")
	assert_eq(PowerUpScreen.describe(data, "rev_charge", data.max_tier("rev_charge")),
			"Faster charge, bigger boost.")
	assert_eq(PowerUpScreen.describe(data, "rusty_overcoat", 1),
			"The car deals damage to minions it touches. Rust: now a feature.")
	assert_eq(PowerUpScreen.name_of("bouncy_bumpers"), "Bouncy Bumpers")


func test_an_owned_power_up_s_card_shows_its_next_tier() -> void:
	state.grant_power_up("jump")
	state.grant_power_up("rev_charge")
	for id in ["bouncy_bumpers", "rusty_overcoat", "polarized_steering_wheel"]:
		while state.power_up_tier(id) < data.max_tier(id):
			state.grant_power_up(id)
	_open()
	assert_eq(screen.cards.size(), 2)
	for c in screen.cards:
		assert_eq(c.tier, 2)
		assert_eq(c.desc.text, PowerUpScreen.describe(data, c.id, 2))
		var pips: Array = c.pips.get_children()
		assert_eq(pips.size(), data.max_tier(c.id))
		assert_eq(pips[0].color, PowerUpScreen.AMBER, "the tier owned")
		assert_eq(pips[1].color, PowerUpScreen.WHITE, "the tier offered")
		if pips.size() > 2:  # T-519: a power-up has 2 tiers in the 4-minute run
			assert_eq(pips[2].color, PowerUpScreen.PIP_EMPTY)


func test_each_card_shows_the_icon_or_a_placeholder_with_the_initial() -> void:
	_open()
	for c in screen.cards:
		if ResourceLoader.exists(data.icon(c.id)):
			assert_not_null(c.icon, "the art from power_ups.json's path")
			assert_eq(c.icon.texture.resource_path, data.icon(c.id))
		else:
			assert_null(c.icon)
			assert_not_null(c.placeholder)
			var initial: Label = c.placeholder.get_node("Initial")
			assert_eq(initial.text, PowerUpScreen.name_of(c.id).left(1))


func test_the_look_differs_from_the_weapons_gift_screen() -> void:
	_open()
	assert_eq(screen.find_children("*", "TextureRect", true, false).filter(
			func(n): return n.name in ["Sunburst", "Ribbon", "Emblem"]).size(), 0,
			"none of the Greenbull gift screen's art")
	assert_ne(screen.title_label.text, level_up.title_label.text)
	var frame: Panel = screen.cards[0].body.get_node("Frame")
	var box: StyleBox = frame.get_theme_stylebox("panel")
	if box is StyleBoxTexture:
		# The final art (T-464): the steel plate with its amber frame, at exactly 2x.
		assert_eq((box as StyleBoxTexture).texture.resource_path, PowerUpScreen.FRAME_ART)
		assert_eq((box as StyleBoxTexture).texture.get_size() * 2.0, PowerUpScreen.CARD_SIZE)
	else:
		assert_eq((box as StyleBoxFlat).bg_color, PowerUpScreen.STEEL)
		assert_eq((box as StyleBoxFlat).border_color, PowerUpScreen.AMBER)


func test_keys_move_the_highlight_and_enter_takes_it() -> void:
	_open()
	assert_eq(screen.highlight, 0)
	_key(KEY_D)
	assert_eq(screen.highlight, 1)
	_key(KEY_A)
	assert_eq(screen.highlight, 0)
	_key(KEY_RIGHT)
	assert_eq(screen.highlight, 1)
	_key(KEY_RIGHT)
	assert_eq(screen.highlight, 1, "held at the last card")
	_key(KEY_LEFT)
	_key(KEY_RIGHT)
	var id: String = screen.cards[1].id
	_key(KEY_ENTER)
	assert_eq(state.power_up_tier(id), 1, "the power-up's tier went up")
	assert_false(screen.visible)
	assert_false(get_tree().paused, "the run resumes")


func test_space_takes_the_highlighted_card() -> void:
	_open()
	var id: String = screen.cards[0].id
	_key(KEY_SPACE)
	assert_eq(state.power_up_tier(id), 1)
	assert_false(get_tree().paused)


func test_clicking_a_card_takes_it() -> void:
	_open()
	var id: String = screen.cards[1].id
	var other: String = screen.cards[0].id
	screen.cards[1].click.pressed.emit()
	assert_eq(state.power_up_tier(id), 1)
	assert_eq(state.power_up_tier(other), 0, "only the clicked card is taken")
	assert_false(screen.visible)
	assert_false(get_tree().paused)


func test_taking_an_owned_one_raises_its_tier() -> void:
	for id in data.ids():
		state.grant_power_up(id)
	_open()
	var id: String = screen.cards[0].id
	_key(KEY_ENTER)
	assert_eq(state.power_up_tier(id), 2)


func test_a_key_held_when_it_opens_takes_nothing_until_let_go() -> void:
	screen.key_down = func(k: int) -> bool: return k == KEY_SPACE
	_open()
	_key(KEY_SPACE)
	assert_true(screen.visible, "the held Space took nothing")
	_key(KEY_SPACE, false)
	_key(KEY_SPACE)
	assert_false(screen.visible)


func test_echoes_and_the_build_up_take_nothing() -> void:
	_complete_mission()
	assert_true(screen.is_animating())
	_key(KEY_ENTER)
	assert_true(screen.visible, "nothing is taken during the build-up")
	screen.skip_animation()
	_key(KEY_ENTER, true, true)
	assert_true(screen.visible, "an echo takes nothing")
	_key(KEY_ENTER)
	assert_false(screen.visible)


func test_escape_does_not_open_the_pause_screen_over_it() -> void:
	_open()
	pause.toggle()
	assert_false(pause.visible)
	assert_true(get_tree().paused, "still paused for the choice")
	assert_true(screen.visible)


func test_a_weapon_choice_that_starts_while_it_is_open_waits() -> void:
	_open()
	state.open_choice(2)  # the gift pack picked up in the same step
	assert_true(state.is_waiting_for_choice())
	assert_false(level_up.visible, "the level-up screen waits")
	assert_true(level_up.is_holding())
	_key(KEY_ENTER)
	assert_false(screen.visible)
	assert_true(level_up.visible, "the level-up screen shows once the overlay closes")
	assert_true(get_tree().paused, "the run stays paused for it")
	level_up.skip_animation()
	level_up.take_highlighted()
	assert_false(get_tree().paused)


func test_a_mission_completed_during_the_weapon_choice_waits() -> void:
	state.open_choice(2)
	assert_true(level_up.visible)
	_complete_mission()
	assert_false(screen.visible, "the overlay waits")
	level_up.skip_animation()
	level_up.take_highlighted()
	await get_tree().process_frame
	assert_true(screen.visible, "it opens at the start of the next frame")
	assert_true(get_tree().paused)
	assert_false(level_up.visible)


func test_a_weapon_choice_with_nothing_to_offer_keeps_the_overlay_paused() -> void:
	for id in ["gun", "flamethrower", "underglow", "molotov", "wiper", "bricks"]:
		var wpn: Node = run.weapons.get_weapon(id)
		if wpn != null:
			wpn.set_tier(wpn.max_tier())
	_open()
	state.open_choice(2)  # nothing to offer: the choice is made at once and the tree resumed
	await get_tree().process_frame
	assert_true(screen.visible)
	assert_true(get_tree().paused, "paused again before anything moves")


func test_a_new_run_closes_it() -> void:
	_open()
	run.start_run()
	assert_false(screen.visible)
	assert_false(get_tree().paused)


func test_a_real_mouse_click_anywhere_on_a_card_takes_it() -> void:
	var win := get_window()
	var old_size := win.size
	win.size = Vector2i(1152, 648)
	_open()
	await wait_process_frames(3)
	var card: Dictionary = screen.cards[1]
	var rect: Rect2 = card.click.get_global_rect()
	assert_gte(rect.size.x, PowerUpScreen.CARD_SIZE.x - 1.0, "click area covers the card")
	# Anywhere on the card, here near the top left of its frame, not a button spot.
	var pos := rect.position + Vector2(60, 50)
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = pos
		e.global_position = pos
		e.pressed = pressed
		get_viewport().push_input(e)
		await wait_process_frames(1)
	win.size = old_size
	assert_eq(state.power_up_tier(card.id), 1)
	assert_false(screen.visible)


func test_the_cards_ignore_the_mouse_during_the_build_up() -> void:
	_complete_mission()
	for c in screen.cards:
		assert_eq(c.click.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	screen.skip_animation()
	for c in screen.cards:
		assert_eq(c.click.mouse_filter, Control.MOUSE_FILTER_STOP)


func test_hover_brightens_the_frame_and_press_drops_the_card() -> void:
	_open()
	var c: Dictionary = screen.cards[0]
	var frame: Panel = c.body.get_node("Frame")
	c.click.mouse_entered.emit()
	assert_eq(frame.modulate, GiftCardClick.HOVER_TINT)
	assert_eq(screen.highlight, 0, "hovering does not move the highlight")
	c.click.button_down.emit()
	assert_eq(c.body.position.y, float(HudStyle.BUTTON_PRESS_DROP))
	c.click.button_up.emit()
	c.click.mouse_exited.emit()
	assert_eq(frame.modulate, Color.WHITE)
	assert_eq(c.body.position.y, float(0))


## T-502: the Polarized Steering Wheel's card uses T-501's texts, its burst as a whole
## percent from the tier's numbers, and (T-519) the last tier's line (the shock).
func test_the_polarized_steering_wheel_card_texts() -> void:
	assert_eq(PowerUpScreen.name_of("polarized_steering_wheel"), "Polarized Steering Wheel")
	var pct := roundi((float(data.at("polarized_steering_wheel", 1)["burst_speed_multiplier"]) - 1.0) * 100.0)
	assert_eq(pct, 20, "tier 1 is the proposal")
	assert_eq(PowerUpScreen.describe(data, "polarized_steering_wheel", 1),
			"(while coasting) Steer, then Accelerate: +20% speed burst.")
	var last := data.max_tier("polarized_steering_wheel")
	assert_eq(PowerUpScreen.describe(data, "polarized_steering_wheel", last),
			"+45% speed, shock hits and shoves minions.")
	for tier in range(1, last + 1):
		var text := PowerUpScreen.describe(data, "polarized_steering_wheel", tier)
		assert_false(text.contains("{"), "no slot left unfilled at tier %d" % tier)
	# The other power-ups have a last-tier line too, with its slots filled.
	assert_eq(PowerUpScreen.describe(data, "rusty_overcoat", data.max_tier("rusty_overcoat")),
			"Deals 5 damage kaijus now too. Tetanus is content.")
