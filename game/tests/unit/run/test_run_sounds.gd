extends GutTest
## Task T-077: the MVP's sound effects. Each moment (a signal or a function of
## the run) plays its sound, the drift and flame loops stop when their moment
## ends, the volumes and files are in data/sfx.json, and every file in it is a
## sound that has a licence record.

const RunScene := preload("res://scenes/run/run.tscn")
const FakeEnemy := preload("res://tests/fixtures/weapons/fake_enemy.gd")
const Flame := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")

var run: Node2D
var snd: Node


func before_each() -> void:
	Flame.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	run.weapons.gun.set_tier(0)
	snd = run.sounds
	snd.stop_all()


func after_each() -> void:
	Flame.playtest_override = -1
	get_tree().paused = false


func _enemy() -> Node2D:
	var e: Node2D = FakeEnemy.new()
	e.position = Vector2(40.0, 0.0) * 16.0
	run.add_child(e)
	return e


func test_every_sound_in_the_data_loads_and_has_a_player() -> void:
	for id in ["engine", "drift", "gun", "flames", "hit", "coin", "meteor_warning", "meteor_impact"]:
		assert_true(snd.has_sound(id), "%s is loaded" % id)
		assert_not_null(snd.sounds[id]["stream"], "%s has a stream" % id)
		assert_gt(snd.sounds[id]["players"].size(), 0)


func test_volumes_come_from_the_data_file() -> void:
	var raw = GameData.unwrap(GameData.load_file("sfx"))
	for id in raw["sounds"]:
		if id == "engine":
			continue  # its volume follows the speed
		assert_eq(snd.sounds[id]["players"][0].volume_db, float(raw["sounds"][id]["volume_db"]), id)


func test_the_engine_plays_while_the_run_runs_and_follows_the_speed() -> void:
	snd.sync_loops()
	assert_true(snd.is_playing("engine"), "engine on")
	run.car.model.vx = 0.0
	run.car.model.vy = 0.0
	snd.sync_loops()
	var slow_pitch: float = snd.sounds["engine"]["players"][0].pitch_scale
	var slow_db: float = snd.sounds["engine"]["players"][0].volume_db
	run.car.model.vx = 0.0
	run.car.model.vy = -run.car.model.tuning.top_speed()
	snd.sync_loops()
	var fast: AudioStreamPlayer = snd.sounds["engine"]["players"][0]
	assert_gt(fast.pitch_scale, slow_pitch, "higher pitch when faster")
	assert_gt(fast.volume_db, slow_db, "louder when faster")


func test_the_engine_stops_when_the_run_ends() -> void:
	snd.sync_loops()
	assert_true(snd.is_playing("engine"))
	run.state.damage_car(100000.0)
	assert_false(run.state.is_running())
	assert_false(snd.is_playing("engine"), "silent after the run ended")


func test_drift_sound_plays_while_drifting_and_stops_when_it_stops() -> void:
	run.car.model.is_drifting = false
	snd.sync_loops()
	assert_false(snd.is_playing("drift"), "not drifting: no drift sound")
	run.car.model.is_drifting = true
	snd.sync_loops()
	assert_true(snd.is_playing("drift"), "drifting: drift sound")
	assert_eq(snd.play_counts["drift"], 1)
	snd.sync_loops()
	assert_eq(snd.play_counts["drift"], 1, "a running loop is not restarted")
	run.car.model.is_drifting = false
	snd.sync_loops()
	assert_false(snd.is_playing("drift"), "stopped with the drift")


func test_flame_sound_plays_while_the_flames_are_on_and_stops_after() -> void:
	var rack: Node = run.weapons
	rack.upgrade("flamethrower")
	var flame = rack.flamethrower
	run.car.model.is_drifting = true
	run.car.model.vx = 5.0
	flame.step(0.02)
	assert_true(flame.active)
	snd.sync_loops()
	assert_true(snd.is_playing("flames"), "flames on: flame sound")
	run.car.model.is_drifting = false
	run.car.model.vx = 0.0
	flame.step(10.0)  # past the linger
	assert_false(flame.active)
	snd.sync_loops()
	assert_false(snd.is_playing("flames"), "flames off: flame sound stops")


func test_no_flame_sound_without_the_flamethrower() -> void:
	run.car.model.is_drifting = true
	run.car.model.vx = 5.0
	snd.sync_loops()
	assert_false(snd.is_playing("flames"))


func test_gun_sound_plays_once_per_volley() -> void:
	var gun = run.weapons.gun
	gun.volleys = 1
	gun.fire_at(Vector2(10.0, 0.0))
	assert_eq(snd.play_counts["gun"], 1, "the volley's first bullet plays it")
	gun.fire_at(Vector2(10.0, 0.0))
	assert_eq(snd.play_counts["gun"], 1, "the same volley's next bullet does not")
	gun.volleys = 2
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < 150:  # past the minimum interval, in real time
		await get_tree().process_frame
	gun.fire_at(Vector2(10.0, 0.0))
	assert_eq(snd.play_counts["gun"], 2, "the next volley plays it again")
	assert_true(snd.is_playing("gun"))


func test_a_bullet_hit_plays_the_hit_sound() -> void:
	var gun = run.weapons.gun
	var b: Node = gun.fire_at(Vector2(10.0, 0.0))
	b.hit.emit(_enemy(), 1.0)
	assert_eq(snd.play_counts["hit"], 1)
	assert_true(snd.is_playing("hit"))


func test_a_flame_hit_plays_the_hit_sound() -> void:
	run.weapons.upgrade("flamethrower")
	run.weapons.flamethrower.enemy_hit.emit(_enemy(), 1.0)
	assert_eq(snd.play_counts["hit"], 1)


func test_hits_closer_than_the_minimum_interval_play_once() -> void:
	snd.play("hit")
	snd.play("hit")
	assert_eq(snd.play_counts["hit"], 1, "min_interval keeps a burst from becoming noise")


func test_a_coin_pickup_plays_the_coin_sound() -> void:
	run.state.add_coins(1)
	assert_eq(snd.play_counts["coin"], 1)
	assert_true(snd.is_playing("coin"))


func test_every_sound_file_has_a_licence_record() -> void:
	var raw = GameData.unwrap(GameData.load_file("sfx"))
	for id in raw["sounds"]:
		var file: String = raw["sounds"][id]["file"]
		var meta := "res://audio/sfx/" + file.get_basename() + ".json"
		assert_true(FileAccess.file_exists(meta), "%s has its metadata JSON" % file)
		var info = JSON.parse_string(FileAccess.get_file_as_string(meta))
		assert_true(String(info["license_name"]).begins_with("CC0") or String(info["license_name"]).begins_with("CC BY"), "%s: CC0 or CC BY" % file)


func test_meteor_warning_and_impact_play() -> void:
	var meteors: Node = run.kaiju_boss.meteors
	meteors.warnings_shown.emit([Vector2(3.0, 3.0)])
	assert_eq(snd.play_counts["meteor_warning"], 1)
	assert_true(snd.is_playing("meteor_warning"))
	var p: AudioStreamPlayer = snd.sounds["meteor_warning"]["players"][0]
	var length: float = snd.sounds["meteor_warning"]["stream"].get_length()
	assert_almost_eq(p.get_playback_position(), length - float(meteors.stat("warning_seconds")), 0.3, "starts so that it ends at the landing")
	meteors.meteor_landed.emit(Vector2(3.0, 3.0), false)
	assert_eq(snd.play_counts["meteor_impact"], 1)
	assert_true(snd.is_playing("meteor_impact"))
	assert_gt(length, float(meteors.stat("warning_seconds")), "the whistle is longer than the warning, so it starts part way in")


func test_no_warning_sound_when_no_spot_was_found() -> void:
	run.kaiju_boss.meteors.warnings_shown.emit([])
	assert_eq(snd.play_counts["meteor_warning"], 0)


func test_pausing_the_tree_pauses_the_sounds() -> void:
	assert_eq(snd.process_mode, Node.PROCESS_MODE_INHERIT)
	for p in snd.sounds["engine"]["players"]:
		assert_eq(p.process_mode, Node.PROCESS_MODE_INHERIT)


func test_a_second_run_silences_and_restarts_the_sounds() -> void:
	snd.play("coin")
	run.car.model.is_drifting = true
	snd.sync_loops()
	assert_true(snd.is_playing("drift"))
	run.start_run()
	assert_false(snd.is_playing("drift"), "a new run starts quiet")
	assert_false(snd.is_playing("coin"))
	snd.sync_loops()
	assert_true(snd.is_playing("engine"), "and the engine is back")
