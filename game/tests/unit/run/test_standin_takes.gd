extends GutTest
## T-574 tweak 10, step 2: the demo takes in data/tutorial_takes (the stand-ins that
## tools/make_standin_takes.gd recorded, or the board's own): one for every trick slide, each a
## take for its trick that does the trick when it replays on the real car, and the stand-ins
## marked as stand-ins so the board's recordings replace them.

const SessionScene := preload("res://scenes/run/practice_session.tscn")
const StandinTool := preload("res://tools/make_standin_takes.gd")

var session: PracticeSession


func before_each() -> void:
	session = SessionScene.instantiate()
	add_child_autofree(session)


func _replay(trick: String) -> PracticeTake:
	session.setup(trick)
	session.start()
	session.set_focused(true)
	var t := session.saved_take()
	assert_not_null(t, "%s has a take in %s" % [trick, PracticeTake.TAKES_DIR])
	if t == null:
		return null
	assert_true(session.play_take(t))
	var guard := 0
	while session.is_replaying() and guard < 5000:
		session.car.physics_step()
		guard += 1
	assert_false(session.is_replaying(), "%s's take played to its end" % trick)
	return t


func test_every_trick_slide_has_a_take_for_its_trick() -> void:
	for trick in PracticeSession.TRICKS:
		var t := PracticeTake.load_take(trick)
		assert_not_null(t, trick)
		if t != null:
			assert_eq(t.trick, trick)
			assert_gt(t.steps(), 0)


func test_the_stand_ins_are_marked_as_stand_ins() -> void:
	var marked := 0
	for trick in PracticeSession.TRICKS:
		var t := PracticeTake.load_take(trick)
		if t != null and StandinTool.is_standin(t):
			marked += 1
			assert_string_contains(t.comment, "F6")
			var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PracticeTake.path_for(trick)))
			assert_true(String(d.get("_comment", "")).begins_with("STAND-IN"), "%s's file says so" % trick)
	assert_gte(marked, 3, "alt drift, air spin and grind are stand-ins")


func test_the_drift_take_drifts_past_the_goal_on_replay() -> void:
	_replay("drift")
	assert_gte(session.drift_seconds, PracticeSession.DRIFT_SECONDS, "3 s of drifting")
	assert_true(session.is_completed())


func test_the_alt_drift_take_does_an_alt_drift_on_replay() -> void:
	_replay("alt_drift")
	assert_gte(session.successes, 1)


func test_the_air_spin_take_does_an_air_spin_on_replay() -> void:
	_replay("air_spin")
	assert_gte(session.successes, 1)


func test_the_grind_take_takes_jump_and_grinds_on_replay() -> void:
	var t := _replay("grind")
	assert_eq(t.gift, "jump")
	assert_eq(session.car.jump.tier, 1)
	assert_gte(session.successes, 1)


func test_each_replay_follows_its_takes_checkpoints() -> void:
	for trick in PracticeSession.TRICKS:
		_replay(trick)
		assert_lt(session.replay_drift, 0.01, "%s follows its take" % trick)
