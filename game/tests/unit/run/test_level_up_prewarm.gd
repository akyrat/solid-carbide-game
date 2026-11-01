extends GutTest
## Task T-482: the level-up screen loads what a gift pack pickup needs with the
## run, so the first pickup does not stall on first-time loads.

const RunScene := preload("res://scenes/run/run.tscn")

var run: Node2D


func before_each() -> void:
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false


func test_prewarmed_with_the_run_and_left_clean() -> void:
	var s = run.level_up_screen
	assert_true(s.prewarmed, "prewarm ran when the run was set up")
	assert_eq(s.cards.size(), 0, "no card left over")
	assert_false(s.visible)
	assert_false(s.is_open())


func test_card_art_is_loaded_before_the_first_pickup() -> void:
	var files := ["card_frame.png", "highlight_frame.png"]
	for f in files:
		assert_true(ResourceLoader.has_cached("res://art/level_up/" + f), f)
	for w in run.weapons.offers.WEAPON_ORDER:
		var path: String = LevelUpScreen_path(w)
		if ResourceLoader.exists(path):
			assert_true(ResourceLoader.has_cached(path), path)


func LevelUpScreen_path(w: String) -> String:
	return "res://art/level_up/weapon_%s.png" % w


func test_first_pickup_still_opens_the_screen_with_cards() -> void:
	var st: RunState = run.state
	st.add_xp(st.xp_needed())
	run.gift_drops.pick_up_all()
	assert_true(run.level_up_screen.is_open())
	assert_eq(run.level_up_screen.cards.size(), 2)
