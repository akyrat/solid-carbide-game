extends GutTest
## Task T-176: the five weapons, the random offers and the card images together
## in a run started from the main menu (goal G-002's integration check).
## The all_weapons_at_start switch is set only here, through its override, never
## in data/playtest.json.

const GameScene := preload("res://scenes/game/game.tscn")
const RackScript := preload("res://scripts/weapons/weapons.gd")
const OffersScript := preload("res://scripts/weapons/level_up_offers.gd")

const WEAPONS := ["gun", "flamethrower", "underglow", "molotov", "wiper"]
const SWITCH_KEYS := ["flamethrower_at_start", "underglow_at_start", "molotov_at_start",
		"wiper_at_start", "all_weapons_at_start"]
const RUN_SECONDS := 60.0
const TIME_SCALE := 6.0

var game: Node
var PROGRESS_PATH := RunPaths.file("test_progress_t176.json")
var SETTINGS_PATH := RunPaths.file("test_settings_t176.cfg")


func before_each() -> void:
	GameSettings.path = SETTINGS_PATH
	PlayerProgress.path = PROGRESS_PATH
	DirAccess.remove_absolute(SETTINGS_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	RackScript.all_weapons_override = 1
	game = GameScene.instantiate()
	add_child_autofree(game)


func after_each() -> void:
	RackScript.all_weapons_override = -1
	Engine.time_scale = 1.0
	get_tree().paused = false
	await wait_process_frames(1)
	DirAccess.remove_absolute(SETTINGS_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	TestSave.restore_settings()
	TestSave.restore_progress()


func _start_run() -> Node:
	game.menu.start_button.pressed.emit()
	await wait_process_frames(2)
	return game.run


func test_run_from_the_main_menu_with_all_five_weapons_for_60_seconds() -> void:
	var run: Node = await _start_run()
	assert_not_null(run, "a run is on screen")
	assert_eq(run.weapons.owned_ids(), WEAPONS, "all five weapons owned at the start")
	# Level-ups pause the run; take any offer as they come, so the weapons keep firing.
	run.state.pause_on_level_up = true
	# Enemies must not end the run early: it is the weapons that are under test.
	run.state.max_health = 1.0e9
	run.state.health = 1.0e9
	var offers: Node = run.weapons.offers
	offers.offers_ready.connect(func(_level: int, ids: Array) -> void:
		offers.choose.call_deferred(ids[0]))
	Engine.time_scale = TIME_SCALE
	var waited := 0.0
	while waited < RUN_SECONDS and run.state.is_running():
		await wait_process_frames(1)
		waited += get_process_delta_time()
	Engine.time_scale = 1.0
	assert_true(is_instance_valid(run), "the run is still on screen")
	assert_gte(waited, RUN_SECONDS - 1.0, "about 60 seconds of run time passed")


func test_repeated_level_ups_take_three_weapons_to_tier_8_with_valid_offers() -> void:
	var run: Node = await _start_run()
	var rack: Node = run.weapons
	var state: Node = run.state
	var offers: Node = rack.offers
	state.pause_on_level_up = true
	var shown: Array = []
	offers.offers_ready.connect(func(_level: int, ids: Array) -> void: shown.append(ids))
	var pick := RandomNumberGenerator.new()
	pick.seed = 176
	offers.rng.seed = 176
	var level_ups := 0
	var at_tier_8 := func() -> int:
		var n := 0
		for id in WEAPONS:
			if rack.get_weapon(id).tier >= 8:
				n += 1
		return n
	while at_tier_8.call() < 3 and level_ups < 200:
		var before := shown.size()
		# run.json's max_level (12) allows only 11 real level-ups, fewer than the 21
		# upgrades three weapons need to reach tier 8. Past the cap the choices
		# open the way the gift pack opens them (RunState.open_choice).
		if state.is_max_level():
			state.open_choice(state.level)
		else:
			state.add_xp(state.xp_needed())
		level_ups += 1
		assert_eq(shown.size(), before + 1, "level-up %d showed one offer" % level_ups)
		var ids: Array = shown[-1]
		assert_gte(ids.size(), 1)
		assert_lte(ids.size(), 2)
		var seen := {}
		for id in ids:
			assert_false(seen.has(id), "no id twice in %s" % [ids])
			seen[id] = true
			var w: Node = rack.get_weapon(OffersScript.weapon_of(id))
			assert_not_null(w, id)
			assert_lt(w.tier, 8, "%s is not offered at tier 8" % id)
		assert_true(offers.choose(ids[pick.randi_range(0, ids.size() - 1)]))
		assert_false(get_tree().paused, "the run resumes after the choice")
	assert_gte(at_tier_8.call(), 3, "at least three weapons reached tier 8")
	assert_lt(level_ups, 200, "within a sane number of level-ups")


func test_playtest_json_as_committed_has_every_switch_false() -> void:
	var r := GameData.load_file(RackScript.PLAYTEST_FILE)
	assert_true(r.ok)
	for key in SWITCH_KEYS:
		var v := GameData.get_value(r.data, key)
		assert_true(v.ok, key + " is in the file")
		assert_false(bool(v.data), key + " is false")
	var k := GameData.get_value(r.data, "kaiju_early_arrival")
	assert_true(k.ok)
	assert_false(bool(k.data["enabled"]), "kaiju_early_arrival.enabled is false")
