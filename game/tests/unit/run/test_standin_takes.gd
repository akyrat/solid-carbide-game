extends GutTest
## T-574 tweaks 10 and 11: the demo takes. The stand-in recorder (tools/standin_recorder.gd, run by
## tools/make_standin_takes.gd) records a take for each trick slide on the real car with today's
## driving and charged jump (T-590: a tap hops, Space held in the air catches the rail), each one
## marked as a stand-in and doing its trick when it replays. The takes in data/tutorial_takes (the
## board's own, or stand-ins): one for every trick slide; a stand-in among them must do its trick.

const SessionScene := preload("res://scenes/run/practice_session.tscn")
const Recorder := preload("res://tools/standin_recorder.gd")
const DIR := "user://t574_test_standins"

var session: PracticeSession


func before_each() -> void:
	session = SessionScene.instantiate()
	add_child_autofree(session)


func after_all() -> void:
	var d := DirAccess.open(DIR)
	if d != null:
		for f in d.get_files():
			d.remove(f)


## Replays `trick`'s take from `dir` on the session; returns it.
func _replay(trick: String, dir := PracticeTake.TAKES_DIR) -> PracticeTake:
	session.takes_dir = dir
	session.setup(trick)
	session.start()
	session.set_focused(true)
	var t := session.saved_take()
	assert_not_null(t, "%s has a take in %s" % [trick, dir])
	if t == null:
		return null
	assert_true(session.play_take(t))
	var guard := 0
	while session.is_replaying() and guard < 5000:
		session.car.physics_step()
		guard += 1
	assert_false(session.is_replaying(), "%s's take played to its end" % trick)
	return t


func _did_trick(trick: String) -> bool:
	return session.is_completed() if trick == "drift" else session.successes >= 1


func test_the_recorder_makes_a_stand_in_for_each_trick_that_does_its_trick() -> void:
	for trick in PracticeSession.TRICKS:
		var r: Dictionary = Recorder.new().record(trick, DIR, self)
		assert_true(r.saved, "%s saved: %s" % [trick, r])
		var t := PracticeTake.load_take(trick, DIR)
		assert_true(Recorder.is_standin(t), "%s marked as a stand-in" % trick)
		_replay(trick, DIR)
		assert_true(_did_trick(trick), "%s's stand-in does its trick on replay: %s" % [trick, r])
		# the route steers in fractions, which a take keeps to 0.001: a few hundredths over 11 s
		assert_lt(session.replay_drift, 0.05, "%s follows its take" % trick)


func test_the_grind_stand_in_taps_then_holds_space_in_the_air() -> void:
	Recorder.new().record("grind", DIR, self)
	var t := PracticeTake.load_take("grind", DIR)
	assert_eq(t.gift, "jump")
	var press := -1
	for i in t.frames.size():
		if t.frames[i][4]:
			press = i
			break
	assert_gt(press, -1, "a Space press")
	assert_false(t.frames[press][3], "a tap: let go on the press's own step (no charge)")
	assert_true(t.frames[press + 1][3], "then held, in the air")
	_replay("grind", DIR)
	assert_eq(session.car.jump.tier, 1)
	assert_gte(session.successes, 1)


func test_every_trick_slide_has_a_take_for_its_trick() -> void:
	for trick in PracticeSession.TRICKS:
		var t := PracticeTake.load_take(trick)
		assert_not_null(t, trick)
		if t != null:
			assert_eq(t.trick, trick)
			assert_gt(t.steps(), 0)


func test_a_stand_in_in_the_game_does_its_trick() -> void:
	for trick in PracticeSession.TRICKS:
		var t := PracticeTake.load_take(trick)
		if t == null or not Recorder.is_standin(t):
			continue  # the board's own take: the board judges it in the playtest
		_replay(trick)
		assert_true(_did_trick(trick), "%s's stand-in does its trick" % trick)
	pass_test("checked")
