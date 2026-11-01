extends GutTest
## Task T-467 (goal G-009): missions and driving power-ups through a whole run, in the real
## game scene. Complete mission 1, the power-up overlay pauses the run, take a card, the run
## resumes with mission 2 on the notebook page, a weapon level-up's gift pack opens the weapons
## gift screen; the two overlays are never open at once; Restart resets missions and power-ups.
## Test only: no game code is changed.

const GameScene := preload("res://scenes/game/game.tscn")
var TEST_PATH := RunPaths.file("test_settings_t467.cfg")
var PROGRESS_PATH := RunPaths.file("test_progress_t467.json")
var game: Node


func before_each() -> void:
	GameSettings.path = TEST_PATH
	PlayerProgress.path = PROGRESS_PATH
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	game = GameScene.instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	game.run.minions.enabled = false
	game.run.power_up_offers.rng.seed = 467


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()
	DirAccess.remove_absolute(PROGRESS_PATH)
	TestSave.restore_progress()


## Mission 1 is one unbroken drift of 4 seconds (data/missions.json).
func _complete_mission_one() -> void:
	game.run.state.missions.on_trick("extended_drift", 4.0)


## A level-up, its gift pack landed and picked up: opens the weapons gift screen.
func _weapon_level_up_and_pick_up() -> void:
	var run = game.run
	run.state.add_xp(run.state.xp_needed())
	run.gift_drops.land_all()
	run.gift_drops.pick_up_all()


func _both_open() -> bool:
	return game.run.power_up_screen.is_open() and game.run.level_up_screen.is_open()


func test_mission_one_to_power_up_to_mission_two_to_weapons_gift() -> void:
	var run = game.run
	var state: RunState = run.state
	var page = run.hud.mission_page
	assert_eq(state.missions.current_number(), 1)
	assert_true(page.visible)
	assert_false(run.power_up_screen.is_open())
	assert_false(get_tree().paused)

	_complete_mission_one()
	assert_true(run.power_up_screen.is_open(), "the power-up overlay opens")
	assert_true(run.power_up_offers.is_showing())
	assert_true(get_tree().paused, "the run is paused")
	assert_false(run.level_up_screen.is_open())
	var ids: Array = run.power_up_screen.cards.map(func(c): return c.id)
	assert_eq(ids.size(), 2, "two cards")

	run.power_up_screen.skip_animation()
	run.power_up_screen.take(ids[0])
	assert_eq(state.power_up_tier(ids[0]), 1, "the card's power-up is owned")
	assert_false(run.power_up_screen.is_open())
	assert_false(get_tree().paused, "the run resumes")
	assert_eq(state.missions.current_number(), 2)
	assert_eq(page.rows.size(), 1, "mission 2 is on the notebook page")
	assert_true(page.visible)

	_weapon_level_up_and_pick_up()
	assert_true(run.level_up_screen.is_open(), "the weapons gift screen opens")
	assert_true(get_tree().paused)
	assert_false(run.power_up_screen.is_open())
	run.level_up_screen.skip_animation()
	var wid: String = run.level_up_screen.cards[0].id
	run.level_up_screen.take(wid)
	assert_false(run.level_up_screen.is_open())
	assert_false(get_tree().paused)


func test_overlays_never_open_together_mission_during_weapon_choice() -> void:
	var run = game.run
	_weapon_level_up_and_pick_up()
	assert_true(run.level_up_screen.is_open())
	_complete_mission_one()
	assert_false(_both_open())
	assert_false(run.power_up_screen.is_open(), "the gift waits for the weapon choice")
	assert_eq(run.power_up_offers.pending, [0])
	run.level_up_screen.skip_animation()
	run.level_up_screen.take(run.level_up_screen.cards[0].id)
	await wait_process_frames(2)
	assert_true(run.power_up_screen.is_open(), "then the power-up overlay opens")
	assert_false(run.level_up_screen.is_open())
	assert_true(get_tree().paused)
	assert_false(_both_open())
	run.power_up_screen.skip_animation()
	run.power_up_screen.take(run.power_up_screen.cards[0].id)
	assert_false(get_tree().paused)


func test_overlays_never_open_together_weapon_choice_during_overlay() -> void:
	var run = game.run
	_complete_mission_one()
	assert_true(run.power_up_screen.is_open())
	_weapon_level_up_and_pick_up()
	assert_false(_both_open(), "the weapon choice is held")
	assert_true(run.power_up_screen.is_open())
	assert_false(run.level_up_screen.is_open())
	run.power_up_screen.skip_animation()
	run.power_up_screen.take(run.power_up_screen.cards[0].id)
	assert_true(run.level_up_screen.is_open(), "shown when the overlay closes")
	assert_false(run.power_up_screen.is_open())
	assert_false(_both_open())
	assert_true(get_tree().paused)
	run.level_up_screen.skip_animation()
	run.level_up_screen.take(run.level_up_screen.cards[0].id)
	assert_false(get_tree().paused)


func test_restart_resets_missions_and_clears_power_ups() -> void:
	var run = game.run
	_complete_mission_one()
	var id: String = run.power_up_screen.cards[0].id
	run.power_up_screen.skip_animation()
	run.power_up_screen.take(id)
	assert_eq(run.state.missions.current_number(), 2)
	assert_false(run.state.owned_power_ups().is_empty())

	game.pause_screen.pause()
	game.pause_screen.restart_button.pressed.emit()
	var fresh = game.run
	assert_ne(fresh, run)
	assert_eq(fresh.state.missions.current_number(), 1, "back to mission 1")
	assert_true(fresh.state.owned_power_ups().is_empty(), "power-ups cleared")
	assert_eq(fresh.state.power_up_tier(id), 0)
	assert_false(fresh.power_up_screen.is_open())
	assert_true(fresh.hud.mission_page.visible)
	assert_false(get_tree().paused)
