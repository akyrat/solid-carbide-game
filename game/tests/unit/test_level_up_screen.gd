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


## A level-up, then (T-144) the car picks up the gift pack's package, which opens the screen.
## Most tests want the finished screen, so this plays the build-up (T-141) to its end.
func _level_up() -> void:
	_level_up_animating()
	screen.skip_animation()


## The same, but leaves the build-up running (T-141's tests).
func _level_up_animating() -> void:
	state.add_xp(state.xp_needed())
	run.gift_drops.pick_up_all()


func _key(code: int, pressed := true, echo := false) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code as Key
	e.pressed = pressed
	e.echo = echo
	screen._input(e)


## Plays the screen's own clock in 1/60 s steps (the tree is paused, so test timers stand still).
func _play(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		screen.advance(1.0 / 60.0)
		t += 1.0 / 60.0


func _card(id: String) -> Dictionary:
	return screen.cards.filter(func(c): return c.id == id)[0]


func test_the_screen_is_in_the_run_and_opens_through_the_gift_pack() -> void:
	assert_not_null(screen)
	assert_false(state.pause_on_level_up, "T-144: the level-up itself does not pause; the package does")
	assert_false(screen.visible, "closed until a level-up's package is picked up")


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
	assert_eq(Texts.TEXTS.size(), 32 + 48, "T-051's 32 rows and T-171's 24 cards (T-173)")


func test_upgrade_card_shows_the_next_tier_text() -> void:
	run.weapons.gun.set_tier(3)
	_level_up()
	var c := _card("upgrade_gun")
	assert_eq(c.title.text, Texts.TEXTS["upgrade_gun.tier4.title"])
	assert_eq(c.desc.text, Texts.TEXTS["upgrade_gun.tier4.desc"])


func test_flamethrower_upgrade_card_shows_its_next_tier() -> void:
	run.weapons.flamethrower.set_tier(4)
	# T-172: the choices are drawn from all five weapons; with the three new ones
	# at their last tier the two left are the gun's and the flamethrower's upgrades.
	for id in ["underglow", "molotov", "wiper"]:
		run.weapons.get_weapon(id).set_tier(run.weapons.get_weapon(id).max_tier())
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


func test_highlighted_card_shows_the_gold_frame() -> void:
	_level_up()
	assert_true(screen.cards[0].highlight_frame.visible)
	assert_false(screen.cards[1].highlight_frame.visible)
	_key(KEY_D)
	assert_false(screen.cards[0].highlight_frame.visible)
	assert_true(screen.cards[1].highlight_frame.visible, "the frame moved")


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
	run.gift_drops.pick_up_all()  # T-144: both packages picked up together
	var waiting: int = state.pending_choices.size()
	assert_gte(waiting, 2)
	screen.skip_animation()
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


func test_look_is_t140s_art_with_black_text() -> void:
	_level_up()
	var frame: NinePatchRect = screen.cards[0].body.get_node("Frame")
	assert_eq(frame.texture.resource_path, "res://art/level_up/card_frame.png")
	assert_eq(frame.patch_margin_left, 10, "9-slice margin")
	assert_eq(frame.size * frame.scale, screen.CARD_SIZE, "2 screen pixels per art pixel")
	assert_eq(screen.cards[0].highlight_frame.texture.resource_path, "res://art/level_up/highlight_frame.png")
	assert_eq(screen._ribbon.texture.resource_path, "res://art/level_up/header_ribbon.png")
	assert_eq(screen._sun.texture.resource_path, "res://art/level_up/sunburst.png")
	assert_eq(screen._emblem.texture.resource_path, "res://art/level_up/gift_pack_emblem.png")
	var plate: StyleBoxTexture = screen.cards[0].button.get_theme_stylebox("normal")
	var pressed: StyleBoxTexture = screen.cards[0].button.get_theme_stylebox("pressed")
	assert_eq(plate.texture.resource_path, "res://art/level_up/button_plate.png")
	assert_eq(pressed.texture.resource_path, "res://art/level_up/button_plate_pressed.png")
	assert_eq(screen._root.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	for c in screen.cards:
		assert_eq(c.title.get_theme_color("font_color"), Color.BLACK)
		assert_eq(c.desc.get_theme_color("font_color"), Color.BLACK)
		var f: FontFile = c.title.get_theme_font("font")
		assert_true(f.get_font_name().to_lower().contains("bangers"), f.get_font_name())
		assert_eq(f.antialiasing, TextServer.FONT_ANTIALIASING_NONE)


func test_the_title_sits_between_art_x_76_and_304_of_the_ribbon() -> void:
	_level_up()
	var l: Label = screen.title_label
	assert_eq(l.position.x, 76.0 * 2.0)
	assert_eq(l.position.x + l.size.x, 304.0 * 2.0)
	var f: Font = l.get_theme_font("font")
	var w := f.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x
	assert_lt(w, l.size.x, "the whole title fits between the medallions")
	assert_eq(l.text, "Redgull Sent a Gift Pack!", "T-051's text unchanged")


func test_card_texts_wrap_at_word_boundaries_and_fit_the_card() -> void:
	# Every word of every text is narrower than the text width, so word-smart
	# wrapping never has to break inside a word ("M / ORE"), and the text fits the card.
	var font: Font = screen.HudScript.comic_font()
	for key in Texts.TEXTS:
		if key.begins_with("weapon.") or key.begins_with("levelup."):
			continue
		var size: int = screen.CARD_TITLE_SIZE if key.ends_with(".title") else screen.CARD_DESC_SIZE
		for word in String(Texts.TEXTS[key]).split(" "):
			var w := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			assert_lt(w, screen.TEXT_WIDTH, "%s: '%s' fits on a line" % [key, word])
	var checked := 0
	for key in Texts.TEXTS:
		if not key.ends_with(".desc"):
			continue
		var id: String = key.trim_suffix(".desc")
		var panel := Control.new()
		add_child_autofree(panel)
		var v := VBoxContainer.new()
		panel.add_child(v)
		var t := Label.new()
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size.x = screen.TEXT_WIDTH
		t.add_theme_font_override("font", font)
		t.add_theme_font_size_override("font_size", screen.CARD_TITLE_SIZE)
		t.text = Texts.TEXTS[id + ".title"]
		v.add_child(t)
		var d := Label.new()
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size.x = screen.TEXT_WIDTH
		d.add_theme_font_override("font", font)
		d.add_theme_font_size_override("font_size", screen.CARD_DESC_SIZE)
		d.text = Texts.TEXTS[key]
		v.add_child(d)
		var inner: float = screen.CARD_SIZE.y - 2.0 * screen.CARD_MARGIN_Y - 44.0 - 20.0
		assert_lte(v.get_combined_minimum_size().y, inner, "%s fits the card with its button" % key)
		checked += 1
	assert_gt(checked, 10)


func test_wrapped_card_lines_split_between_words() -> void:
	_level_up()
	await wait_process_frames(2)
	for c in screen.cards:
		var label: Label = c.desc
		assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "wraps at words")
		assert_lte(label.get_minimum_size().x, screen.TEXT_WIDTH + 1.0, "never wider than the card's text area")
		assert_gt(label.get_line_count(), 0)


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


# --- T-141: the build-up animation --------------------------------------------


func test_the_screen_animates_in_within_its_length_and_ends_in_the_layout() -> void:
	_level_up_animating()
	assert_true(screen.is_animating())
	assert_eq(screen.cards.size(), 2)
	var length: float = screen.animation_length(2)
	assert_lt(length, 1.0, "well under a second")
	assert_almost_eq(length, 0.54, 0.001, "the proposed length for two cards")
	assert_almost_eq(screen.animation_length(3), 0.64, 0.001)
	# At the start only the dim and the sunburst show: no ribbon, no cards.
	assert_false(screen._ribbon.visible)
	assert_false(screen.cards[0].body.visible)
	assert_lt(screen._sun.scale.x, screen.SUN_SCALE_FULL)
	# It keeps running while the tree is paused (the screen's own clock).
	assert_true(get_tree().paused)
	_play(length + 0.3)
	assert_false(screen.is_animating(), "done within its length")
	assert_true(get_tree().paused, "the run is still paused for the choice")
	assert_true(screen._ribbon.visible and screen._emblem.visible)
	assert_eq(screen._ribbon.position, Vector2.ZERO)
	assert_eq(screen._emblem.position, screen.EMBLEM_OFFSET)
	assert_almost_eq(screen._dim.modulate.a, 1.0, 0.001)
	assert_eq(screen._sun.scale, Vector2.ONE * screen.SUN_SCALE_FULL)
	for c in screen.cards:
		assert_true(c.body.visible)
		assert_eq(c.body.position, Vector2.ZERO, "T-052's layout")
		assert_eq(c.panel.size, screen.CARD_SIZE)


func test_the_frames_are_stepped_and_ordered() -> void:
	_level_up_animating()
	var seen_ribbon: Array = []
	var seen_cards: Array = [[], []]
	var t := 0.0
	var shown_at: Array = [-1.0, -1.0, -1.0]  # ribbon, card 0, card 1
	while screen.is_animating():
		screen.advance(0.01)
		t += 0.01
		if shown_at[0] < 0.0 and screen._ribbon.visible:
			shown_at[0] = t
		for i in 2:
			if shown_at[i + 1] < 0.0 and screen.cards[i].body.visible:
				shown_at[i + 1] = t
		if not seen_ribbon.has(screen._ribbon.position.y):
			seen_ribbon.append(screen._ribbon.position.y)
	assert_gt(shown_at[0], 0.0)
	assert_lt(shown_at[0], shown_at[1], "ribbon before the cards")
	assert_lt(shown_at[1], shown_at[2], "cards one after the other, left first")
	assert_lte(seen_ribbon.size(), screen.RIBBON_DROP.size(), "whole-pixel frames, no tweening")
	for y in seen_ribbon:
		assert_eq(y, floorf(y), "whole pixels")


func test_the_sunburst_spins_in_steps() -> void:
	_level_up()
	var t0: float = screen._t
	screen.advance(screen.SUN_SPIN_STEP * 3.0)
	var steps := floorf(screen._t / screen.SUN_SPIN_STEP)
	assert_almost_eq(screen._sun.rotation, deg_to_rad(steps * screen.SUN_SPIN_DEGREES), 0.0001, "a whole number of steps")
	assert_gt(screen._t, t0)
	assert_eq(screen._sun.modulate.a, screen.SUN_ALPHA)


func test_keys_during_the_animation_take_nothing_and_move_nothing() -> void:
	_level_up_animating()
	_key(KEY_SPACE)
	_key(KEY_ENTER)
	_key(KEY_D)
	screen.take_highlighted()
	screen.take("get_flamethrower")
	screen.move_highlight(1)
	assert_true(screen.is_open())
	assert_true(screen.is_animating())
	assert_eq(screen.highlight, 0, "nothing moved")
	assert_eq(run.weapons.gun.tier, 1)
	assert_eq(run.weapons.flamethrower.tier, 0)
	assert_true(state.is_waiting_for_choice())
	assert_true(get_tree().paused)


func test_buttons_ignore_the_mouse_during_the_animation() -> void:
	_level_up_animating()
	for c in screen.cards:
		assert_eq(c.button.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	screen.skip_animation()
	for c in screen.cards:
		assert_eq(c.button.mouse_filter, Control.MOUSE_FILTER_STOP)


func test_a_key_pressed_during_the_animation_does_not_take_a_card_when_it_ends() -> void:
	_level_up_animating()
	_key(KEY_SPACE)  # pressed while it animates, still held when it ends
	screen.skip_animation()
	_key(KEY_SPACE, true, true)  # its key-repeat
	assert_true(screen.is_open(), "the held press took nothing")
	_key(KEY_SPACE, false)
	_key(KEY_D)
	assert_eq(screen.highlight, 1, "fresh presses count once it ends")
	_key(KEY_SPACE)
	assert_false(screen.visible)
	assert_eq(run.weapons.flamethrower.tier, 1)


func test_keyboard_and_mouse_work_after_the_animation() -> void:
	_level_up_animating()
	_play(screen.animation_length(2) + 0.3)
	assert_false(screen.is_animating())
	_key(KEY_D)
	assert_eq(screen.highlight, 1)
	_key(KEY_ENTER)
	assert_false(screen.visible)
	assert_eq(run.weapons.flamethrower.tier, 1)
	_level_up()
	# T-172: the second level-up's cards are drawn at random; press the first.
	var id: String = screen.cards[0].id
	var weapon: Node = run.weapons.get_weapon(offers.weapon_of(id))
	var tier_before: int = weapon.tier
	screen.cards[0].button.pressed.emit()
	assert_eq(weapon.tier, tier_before + 1, "the button works")


func test_a_second_screen_animates_again() -> void:
	state.add_xp(state.xp_needed() * 2.5)
	run.gift_drops.pick_up_all()
	screen.skip_animation()
	screen.take(screen.cards[0].id)
	assert_true(screen.is_open(), "the next level-up's cards")
	assert_true(screen.is_animating(), "build up again")
	assert_false(screen.cards[0].body.visible)


func test_levelling_up_and_picking_up_in_one_frame_still_animates_cleanly() -> void:
	# T-139's likes bar animation (another branch) may play at the same moment:
	# this screen uses only its own nodes and clock, so the HUD below it cannot
	# interfere, and it stays closed to input until its own build-up ends.
	state.add_xp(state.xp_needed())
	run.gift_drops.pick_up_all()
	_play(0.05)
	assert_true(screen.is_animating())
	assert_true(screen.visible)
	_play(screen.animation_length(2) + 0.3)
	assert_false(screen.is_animating())
	assert_true(screen.is_open())
	assert_eq(screen.layer, screen.LAYER, "over the HUD")


func test_closing_during_the_animation_stops_it() -> void:
	_level_up_animating()
	screen.close()
	assert_false(screen.is_animating())
	assert_false(screen.visible)


# --- T-173: the new weapons' cards and the weapon image ------------------------


## Every choice the offers can produce, as [weapon id, tier now, choice id]: "get_<w>"
## at tier 0 (not the gun, which is always owned), "upgrade_<w>" at tiers 1 to 7.
func _every_choice() -> Array:
	var out := []
	for w in offers.WEAPON_ORDER:
		var weapon: Node = run.weapons.get_weapon(w)
		var first := 1 if w == "gun" else 0
		for tier in range(first, weapon.max_tier()):
			out.append([w, tier, ("upgrade_" if tier > 0 else "get_") + w])
	return out


func _set_tier(w: String, tier: int) -> void:
	run.weapons.get_weapon(w).set_tier(tier)


func test_every_choice_and_tier_the_offers_can_produce_has_text() -> void:
	var choices := _every_choice()
	assert_eq(choices.size(), 7 + 4 * 8, "gun tiers 1-7, the others 0-7")
	var seen_ids := {}
	for c in choices:
		_set_tier(c[0], c[1])
		assert_true(offers.available_offers().has(c[2]), "%s is offered at tier %d" % [c[2], c[1]])
		var text: Dictionary = screen.card_text(c[2])
		assert_ne(text.title, "", "%s at tier %d has a title" % [c[2], c[1]])
		assert_ne(text.desc, "", "%s at tier %d has a description" % [c[2], c[1]])
		seen_ids[c[2]] = true
	assert_eq(seen_ids.size(), offers.ALL_IDS.size(), "every choice id walked")
	for id in offers.ALL_IDS:
		assert_true(seen_ids.has(id), id)


func test_t171s_texts_word_for_word() -> void:
	assert_eq(Texts.TEXTS["get_underglow.title"], "Neon Underglow")
	assert_eq(Texts.TEXTS["upgrade_underglow.tier6.desc"], "Glow damage up another 50%, to 2.25. Peak aesthetic.")
	assert_eq(Texts.TEXTS["get_molotov.desc"], "Throws a molotov every 3 seconds. Fire lasts 3 seconds. Very shareable.")
	assert_eq(Texts.TEXTS["upgrade_molotov.tier8.title"], "Triple Drop")
	assert_eq(Texts.TEXTS["upgrade_wiper.tier5.desc"], "Knockback up 50%, from 1.5 to 2.25. Minions only, never the kaiju.")
	assert_eq(Texts.TEXTS["upgrade_wiper.tier8.title"], "Faster Sweep II")
	for w in ["underglow", "molotov", "wiper"]:
		for suffix in [".title", ".desc"]:
			assert_true(Texts.TEXTS.has("get_" + w + suffix))
			for tier in range(2, 9):
				assert_true(Texts.TEXTS.has("upgrade_%s.tier%d%s" % [w, tier, suffix]))


func test_a_new_weapons_upgrade_card_shows_its_next_tier() -> void:
	_set_tier("wiper", 4)
	screen.show_offers(["upgrade_wiper"])
	screen.skip_animation()
	assert_eq(screen.cards[0].title.text, Texts.TEXTS["upgrade_wiper.tier5.title"])
	assert_eq(screen.cards[0].desc.text, Texts.TEXTS["upgrade_wiper.tier5.desc"])
	_set_tier("underglow", 0)
	screen.show_offers(["get_underglow"])
	assert_eq(screen.cards[0].title.text, "Neon Underglow")


## Redgull red or anything that reads as a red (as game/tools/build_drift_mark.py's
## is_redgull_red): within 128 of (219, 26, 41), or a saturated red hue.
func _is_redgull_red(c: Color) -> bool:
	var red := Color8(219, 26, 41)
	var dist := Vector3(c.r - red.r, c.g - red.g, c.b - red.b).length() * 255.0
	if dist < 128.0:
		return true
	var hue := c.h * 360.0
	return minf(hue, 360.0 - hue) < 25.0 and c.s > 0.4 and c.v > 0.25


func test_each_card_shows_its_weapons_image_a_different_one_per_weapon() -> void:
	var images := {}
	for w in offers.WEAPON_ORDER:
		var id: String = "upgrade_gun" if w == "gun" else "get_" + w
		screen.show_offers([id])
		screen.skip_animation()
		var image: TextureRect = screen.cards[0].image
		assert_not_null(image, "%s: an image node" % id)
		assert_eq(image.name, "WeaponImage")
		assert_eq(image.texture, screen.weapon_image(w), "%s shows the %s image" % [id, w])
		assert_eq(image.custom_minimum_size, screen.IMAGE_SIZE)
		assert_true(image.is_visible_in_tree())
		images[w] = image.texture.get_image().get_data()
	for a in images:
		for b in images:
			if a < b:
				assert_ne(images[a], images[b], "%s and %s look different" % [a, b])
	# An upgrade card shows the same weapon's image.
	_set_tier("molotov", 3)
	screen.show_offers(["upgrade_molotov"])
	assert_eq(screen.cards[0].image.texture, screen.weapon_image("molotov"))


func test_final_weapon_art_replaces_the_placeholders() -> void:
	# T-174: the five PixelLab images, 64 x 64, hard edged, shown instead of the 16 x 16 placeholders.
	for w in offers.WEAPON_ORDER:
		var path: String = screen.WEAPON_ART % w
		assert_true(ResourceLoader.exists(path), "%s: %s is there" % [w, path])
		var tex: Texture2D = screen.weapon_image(w)
		assert_eq(tex.get_size(), Vector2(64, 64), "%s: 64 x 64, not the placeholder" % w)
		assert_ne(tex, screen.placeholder_image(w))
		var img: Image = tex.get_image()
		var opaque := 0
		for y in img.get_height():
			for x in img.get_width():
				var a := img.get_pixel(x, y).a
				assert_true(a == 0.0 or a == 1.0, "%s (%d, %d): no semi-transparent pixels" % [w, x, y])
				if a > 0.0:
					opaque += 1
		assert_gt(opaque, 300, "%s: something is drawn" % w)
		assert_eq(img.get_pixel(0, 0).a, 0.0, "%s: transparent background" % w)


func test_placeholder_images_are_hard_edged_and_never_redgull_red() -> void:
	for w in offers.WEAPON_ORDER:
		var tex: Texture2D = screen.placeholder_image(w)
		assert_not_null(tex, w)
		var img: Image = tex.get_image()
		assert_eq(img.get_size(), Vector2i(16, 16))
		var opaque := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				assert_true(c.a == 0.0 or c.a == 1.0, "%s (%d, %d): no semi-transparent pixels" % [w, x, y])
				if c.a > 0.0:
					opaque += 1
					assert_false(_is_redgull_red(c), "%s (%d, %d): %s is not Redgull red" % [w, x, y, c])
		assert_gt(opaque, 20, "%s: something is drawn" % w)
		assert_eq(img.get_pixel(0, 15).a, 0.0, "%s: transparent background" % w)
	for row in screen.PLACEHOLDER_GRIDS.values():
		assert_eq(row.size(), 16)
		for line in row:
			assert_eq(String(line).length(), 16, line)
	assert_null(screen.placeholder_image("nothing"))


func test_every_card_lays_out_its_image_and_text_inside_the_card() -> void:
	var win := get_window()
	var old_size := win.size
	win.size = Vector2i(1152, 648)
	var vp := Rect2(Vector2.ZERO, Vector2(win.size))
	for c in _every_choice():
		_set_tier(c[0], c[1])
		screen.show_offers([c[2]])
		screen.skip_animation()
		await wait_process_frames(2)
		var card: Dictionary = screen.cards[0]
		var label := "%s at tier %d" % [c[2], c[1]]
		var frame: Rect2 = card.body.get_node("Frame").get_global_rect()
		var inner := frame.grow(-20.0)  # inside the frame's border and studs
		var img: Rect2 = card.image.get_global_rect()
		var title: Rect2 = card.title.get_global_rect()
		var desc: Rect2 = card.desc.get_global_rect()
		var button: Rect2 = card.button.get_global_rect()
		assert_eq(frame.size, screen.CARD_SIZE, label)
		assert_true(vp.encloses(frame), "%s: the card is inside the window" % label)
		for r in [img, title, desc, button]:
			assert_true(inner.encloses(r), "%s: %s inside the card %s" % [label, r, inner])
		assert_eq(img.size, screen.IMAGE_SIZE, label)
		assert_gte(title.position.y, img.end.y, "%s: the title is under the image" % label)
		assert_gte(desc.position.y, title.end.y, "%s: the description is under the title" % label)
		var text_end: float = desc.position.y + card.desc.get_minimum_size().y
		assert_lte(text_end, button.position.y, "%s: the description ends above the button" % label)
		assert_eq(card.panel.size, screen.CARD_SIZE, "%s: the card did not grow" % label)
	win.size = old_size


func test_the_highlight_frame_still_reaches_12_px_past_the_taller_card() -> void:
	_level_up()
	var glow: NinePatchRect = screen.cards[0].highlight_frame
	assert_eq(glow.position, Vector2(-12, -12))
	assert_eq(glow.size * glow.scale, screen.CARD_SIZE + Vector2(24, 24))
