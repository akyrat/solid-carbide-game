extends GutTest
## Task T-239: Play on a listed level in the level creator starts a full run on that level's file
## (the game's own run: 8:00, minions, the kaiju at boss time, pause screen, garage upgrades), and
## when the run ends, win or loss, the creator shows its level list again. The level is the
## elevation sample map with its first building and the rooftop roof-se-6 (and its ramp) removed,
## saved only into a per-run temporary levels folder (RunPaths). It keeps roof-nw-3 and its ramp.

const NavScript := preload("res://scripts/enemies/enemy_navigation.gd")
const GameScene := preload("res://scenes/game/game.tscn")
const SAMPLE := "res://data/level/elevation_sample_map.json"
const LEVEL_NAME := "T-239 test level"
const REMOVED_PLATFORM := "roof-se-6"
const REMOVED_RAMP := "ramp-se-3-6"

var dir: String
var level_path: String
var level_data: Dictionary


func before_each() -> void:
	TestSave.isolate()
	dir = RunPaths.file("t239_levels_" + str(randi()))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAMPLE))
	data.buildings.remove_at(0)
	data.platforms = data.platforms.filter(func(p): return str(p.id) != REMOVED_PLATFORM)
	data.ramps = data.ramps.filter(func(r): return str(r.id) != REMOVED_RAMP)
	data.name = LEVEL_NAME
	level_data = data
	level_path = dir.path_join("t239_level.json")
	assert_eq(LevelStore.save_level(level_path, data), OK)


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	TestSave.restore()


func _creator() -> LevelCreator:
	var c: LevelCreator = load("res://scenes/level_creator/level_creator.tscn").instantiate()
	c.levels_dir = dir
	add_child_autofree(c)
	return c


func _play(c: LevelCreator) -> Node2D:
	assert_eq(c.list_screen.rows.size(), 1, "the level is listed")
	assert_eq(c.list_screen.rows[0].play.text, CreatorTexts.get_text("play_action"))
	c.list_screen.rows[0].play.pressed.emit()
	return c.run


func _ids(items: Array) -> Array:
	return items.map(func(p): return str(p.id))


# --- Play starts a run on the level ---------------------------------------------

func test_the_level_is_saved_in_a_temporary_folder_and_has_a_ramp() -> void:
	assert_true(level_path.begins_with("user://"), level_path)
	assert_gt(level_data.ramps.size(), 0)


func test_play_starts_a_run_on_the_level_file() -> void:
	var c := _creator()
	watch_signals(c)
	var run := _play(c)
	assert_not_null(run, "a run is on screen")
	assert_signal_emitted_with_parameters(c, "play_requested", [level_path])
	assert_signal_emitted(c, "run_shown")
	assert_null(c.list_screen, "the list is gone")
	assert_null(c.editor)
	assert_eq(run.get_parent(), c)
	assert_eq(run.layout_path, level_path, "the run's layout path is the level's path")
	assert_eq(run.map.layout_path, level_path)
	assert_eq(str(run.map.layout.name), LEVEL_NAME)
	var s: RunState = run.state
	assert_true(s.is_running())
	assert_eq(s.time_left_text(), "8:00")
	assert_eq(s.health, s.max_health)
	assert_eq(s.coins, 0)


func test_the_run_map_holds_the_level_buildings_platforms_and_ramps() -> void:
	var run := _play(_creator())
	assert_eq(run.map.buildings.size(), level_data.buildings.size(), "the level's buildings")
	var gh = run.elevation.ground_height
	# T-405: the level's rooftops, then the platforms of its short buildings.
	var rooftops: Array = gh.platforms.filter(func(p): return not bool(p.get("short", false)))
	assert_eq(_ids(rooftops), _ids(level_data.platforms), "the level's rooftops")
	assert_eq(_ids(gh.ramps), _ids(level_data.ramps), "the level's ramps")
	assert_false(_ids(gh.platforms).has(REMOVED_PLATFORM))
	assert_eq(run.car.ground, gh, "the car drives on the level's heights")


func test_minions_spawn_on_the_level() -> void:
	var run := _play(_creator())
	for i in 40:
		run.minions.step(0.25)
		if run.minions.minions.size() > 0:
			break
	assert_gt(run.minions.minions.size(), 0, "minions spawned")


func test_the_kaiju_appears_at_boss_time() -> void:
	var run := _play(_creator())
	assert_false(run.kaiju_boss.has_appeared())
	run.state.advance(RunState.RUN_SECONDS - RunState.BOSS_TIME_LEFT + 0.5)
	for i in 20:
		if run.kaiju_boss.has_appeared():
			break
		run.kaiju_boss.step(1.0 / 60.0)
	assert_true(run.state.is_running())
	assert_true(run.kaiju_boss.has_appeared(), "the kaiju appeared")
	assert_not_null(run.kaiju_boss.kaiju)


func test_the_run_is_set_up_as_the_game_run() -> void:
	var c := _creator()
	var run := _play(c)
	assert_not_null(c.pause_screen, "the pause screen")
	assert_eq(c.pause_screen.get_parent(), run)
	assert_not_null(run.weapons, "the weapons")
	assert_eq(run.progress, c.progress, "the garage upgrades from the saved progress")
	assert_eq(run.state.progress, c.progress)


# --- Enemy navigation on the level ------------------------------------------------

## True when the segment a-b passes over `rect` (sampled every quarter unit).
func _segment_over(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	var steps := maxi(1, int(ceil(a.distance_to(b) * 4.0)))
	for i in steps + 1:
		if rect.has_point(a.lerp(b, float(i) / steps)):
			return true
	return false


func test_enemy_navigation_climbs_the_level_ramp_to_a_rooftop() -> void:
	var run := _play(_creator())
	var nav = NavScript.for_map(run.map)
	assert_not_null(nav, "navigation builds for the run's map")
	var gh = run.elevation.ground_height
	assert_eq(nav.ground, gh)
	var street := Vector2(-60, -48)  # the street south-east of roof-nw-3's ramp
	var rooftop := Vector2(-80, -80)  # on roof-nw-3, height 3
	assert_almost_eq(gh.height_at(street), 0.0, 0.001)
	assert_almost_eq(gh.height_at(rooftop), 3.0, 0.001)
	var path: PackedVector2Array = nav.find_path(street, rooftop)
	assert_gt(path.size(), 0, "a path from the street to the rooftop")
	var over_ramp := false
	for r in gh.ramps:
		for i in path.size() - 1:
			if _segment_over(path[i], path[i + 1], r.rect):
				over_ramp = true
	assert_true(over_ramp, "the path goes over the level's ramp")
	assert_eq(gh.area_index_at(path[path.size() - 1]), gh.area_index_at(rooftop), "it ends on the rooftop")


# --- The run ends: back to the list ---------------------------------------------

func _end_and_check_list(end: Callable, expected: String) -> void:
	var c := _creator()
	var run := _play(c)
	end.call(run.state)
	assert_eq(run.state.result, expected)
	await wait_process_frames(2)
	assert_not_null(c.list_screen, "the level list is shown again")
	assert_null(c.run)
	assert_null(c.pause_screen)
	assert_false(is_instance_valid(run), "the run is freed")
	assert_eq(c.get_children().filter(func(n): return n is Control or n is Node2D), [c.list_screen],
		"only the list on screen")
	assert_eq(c.list_screen.rows.size(), 1, "the level is listed again")
	assert_false(get_tree().paused)


func test_a_won_run_returns_to_the_level_list() -> void:
	await _end_and_check_list(func(s): s.kaiju_killed(), "win")


func test_a_run_lost_on_health_returns_to_the_level_list() -> void:
	await _end_and_check_list(_lose_on_health, "loss")


## Takes the last heart and lets the wreck (T-360) play out.
func _lose_on_health(s: RunState) -> void:
	s.damage_car(s.max_health)
	s.advance(s.wreck_seconds)


func test_a_run_lost_on_the_clock_returns_to_the_level_list() -> void:
	await _end_and_check_list(func(s):
		s.advance(RunState.RUN_SECONDS + 1.0)
		s.advance(s.time_up_seconds), "loss")  # the time's up screen first (T-317)


func test_a_run_ending_while_paused_returns_unpaused() -> void:
	var c := _creator()
	_play(c)
	c.pause_screen.pause()
	c.run.state.kaiju_killed()
	await wait_process_frames(2)
	assert_not_null(c.list_screen)
	assert_false(get_tree().paused)


func test_play_again_after_a_run_starts_a_fresh_run() -> void:
	var c := _creator()
	_play(c).state.kaiju_killed()
	await wait_process_frames(2)
	var run := _play(c)
	assert_true(run.state.is_running())
	assert_eq(run.state.time_left_text(), "8:00")
	assert_eq(get_tree().get_nodes_in_group("run_state").size(), 1, "only one run state")


# --- The game's own flow is unchanged ---------------------------------------------

func test_a_run_from_the_main_menu_still_plays_the_sample_map() -> void:
	var game: GameFlow = GameScene.instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	assert_not_null(game.run)
	assert_eq(game.run.layout_path, SAMPLE)
	assert_eq(game.run.map.layout_path, SAMPLE)
	assert_not_null(game.pause_screen)
	assert_eq(game.pause_screen.get_parent(), game.run)


# --- Restart and Exit on the pause screen (T-327) ---------------------------------

func test_pause_restart_replays_the_same_level_and_cancels_the_run() -> void:
	var c := _creator()
	var run := _play(c)
	var before: int = c.progress.coins
	run.state.add_coins(7)
	c.pause_screen.pause()
	c.pause_screen.restart_button.pressed.emit()
	assert_ne(c.run, run, "a fresh run")
	assert_eq(c.run.layout_path, level_path)
	assert_eq(c.progress.coins, before, "the cancelled run's coins are lost (board, 2026-10-30)")
	assert_false(get_tree().paused)
	assert_null(c.list_screen, "no list while replaying")


func test_pause_exit_returns_to_the_creator_list_and_cancels_the_run() -> void:
	var c := _creator()
	var run := _play(c)
	var before: int = c.progress.coins
	run.state.add_coins(5)
	c.pause_screen.pause()
	c.pause_screen.exit_button.pressed.emit()
	assert_null(c.run)
	assert_not_null(c.list_screen)
	assert_eq(c.progress.coins, before, "the cancelled run's coins are lost (board, 2026-10-30)")
	assert_false(get_tree().paused)
