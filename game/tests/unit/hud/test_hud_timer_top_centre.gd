extends GutTest
## Task T-611 (HUD and menus, Decisions, "The timer sits at the top centre"): the timer clock's
## default place is the top centre, centred at any window size and HUD size, and nothing placed
## by default overlaps it. A saved place for the timer is kept; Reset layout returns it to the
## top centre.

const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const WeaponsScript := preload("res://scripts/weapons/weapons.gd")
## Screen pixels of slack (pieces round to whole pixels).
const EPS := 2.0
## The clock's margin from the top edge (hud.json, timer_clock.layout.top; a proposal).
const TOP_MARGIN := 16.0


## A HUD in a window of `size` at `hud_size`, all five weapons (the tallest column).
func _hud_at(size: Vector2i, hud_size := 100.0, layout := {}) -> Hud:
	var sv := SubViewport.new()
	sv.size = size
	add_child_autofree(sv)
	var hud: Hud = HUD_SCENE.instantiate()
	sv.add_child(hud)
	hud.set_hud_size(hud_size)
	hud.set_layout(layout)
	hud.sub_goal.set_numbers(9999, 9999)
	hud.coins_value_label.text = "99999"
	var rack: Node = WeaponsScript.new()
	add_child_autofree(rack)
	for i in 5:
		rack.get_weapon(rack.weapons.keys()[i]).set_tier(1 + i)
	hud.bind_weapons(rack)
	return hud


func _screen_rect(hud: Hud, id: String) -> Rect2:
	var r := hud.piece_rect(id)
	var t := hud.root.get_global_transform()
	return Rect2(t * r.position, r.size * hud.hud_scale())


func test_clock_is_centred_at_the_top_margin_at_the_default_size() -> void:
	var hud := _hud_at(Vector2i(1152, 648))
	await get_tree().process_frame
	var c := hud.timer_clock.get_global_rect()
	assert_almost_eq(c.get_center().x, 576.0, EPS, "on the vertical centre line")
	assert_almost_eq(c.position.y, TOP_MARGIN, EPS, "16 px below the top edge")
	assert_almost_eq(c.size, Vector2(200, 72), Vector2(EPS, EPS))


func test_clock_is_centred_and_on_screen_at_other_window_and_hud_sizes() -> void:
	for size in [Vector2i(1920, 1080), Vector2i(960, 540), Vector2i(2560, 1080)]:
		for pct in [GameSettings.MIN_HUD_SIZE, 100.0, GameSettings.MAX_HUD_SIZE]:
			var hud := _hud_at(size, pct)
			await get_tree().process_frame
			var where := "%dx%d at %d" % [size.x, size.y, int(pct)]
			var c := hud.timer_clock.get_global_rect()
			assert_almost_eq(c.get_center().x, size.x / 2.0, EPS, "%s: centred" % where)
			assert_almost_eq(c.position.y, TOP_MARGIN * hud.hud_scale(), EPS, "%s: top margin scales" % where)
			assert_true(Rect2(Vector2.ZERO, Vector2(size)).grow(0.5).encloses(c), "%s: fully on screen (%s)" % [where, c])


func test_no_hud_piece_at_its_default_place_overlaps_the_clock() -> void:
	var hud := _hud_at(Vector2i(1152, 648))
	await get_tree().process_frame
	var clock := _screen_rect(hud, "clock")
	for id in HudLayout.PIECES:
		if id != "clock":
			assert_false(_screen_rect(hud, id).intersects(clock), "%s clear of the clock (%s)" % [id, clock])
	# The counters next to the car sit under the centre of the screen, far below the clock.
	assert_gt(hud.airtime_counter.position.y, clock.end.y, "airtime counter below the clock")
	assert_gt(hud.drift_counter.position.y, clock.end.y, "drift counter below the clock")


func test_the_popups_stay_below_the_clock_and_the_pause_strip_starts_under_it() -> void:
	var clock_bottom := TOP_MARGIN + 72.0
	var popup_top := 648.0 * (0.5 - TrickPopups.MAX_REACH)
	assert_gt(popup_top, clock_bottom, "a trick popup never reaches higher than a quarter of the height above the car")
	const PauseScript := preload("res://scripts/ui/pause_screen.gd")
	assert_gt(PauseScript.STRIP_TOP, clock_bottom, "the pause strip and the trick list panel start under the clock")


func test_a_saved_place_for_the_clock_is_kept() -> void:
	var hud := _hud_at(Vector2i(1152, 648), 100.0, {"clock": {"ax": 1.0, "ay": 1.0, "dx": -16.0, "dy": -16.0}})
	await get_tree().process_frame
	var r := hud.piece_rect("clock")
	assert_almost_eq(r.end, hud.root.size - Vector2(16, 16), Vector2(EPS, EPS), "at the saved bottom right")


func test_reset_layout_puts_the_clock_at_the_top_centre() -> void:
	var hud := _hud_at(Vector2i(1152, 648))
	await get_tree().process_frame
	var home := hud.piece_rect("clock")
	hud.move_piece("clock", Vector2(40, 400))
	assert_false(hud.piece_rect("clock").position.is_equal_approx(home.position), "moved")
	hud.reset_layout()
	var back := hud.piece_rect("clock")
	assert_almost_eq(back.position, home.position, Vector2(EPS, EPS))
	assert_almost_eq(back.get_center().x, 576.0, EPS, "centred again")
	assert_almost_eq(back.position.y, TOP_MARGIN, EPS)
