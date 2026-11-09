extends GutTest
## T-604: the board's alt drift take, recorded on the board's new practice playground, pays ALT DRIFT!
## when it replays (the slide's demo), and tools/check_takes.gd reports every take.

const Checker := preload("res://tools/check_takes.gd")


func test_the_alt_drift_take_pays_alt_drift_on_the_playground() -> void:
	var r := Checker.check("alt_drift", self)
	assert_true(r.has_take, "the alt drift slide has a take")
	assert_gte(int(r.successes), 1, "ALT DRIFT! at least once")
	assert_true(r.did_trick)
	assert_almost_eq(float(r.drift), 0.0, 0.05, "it follows its own path on this playground")


func test_the_checker_reports_every_trick() -> void:
	for trick in PracticeSession.TRICKS:
		var r := Checker.check(trick, self)
		assert_true(r.has_take, trick)
		for key in ["seconds", "successes", "completed", "did_trick", "drift"]:
			assert_true(r.has(key), "%s reports %s" % [trick, key])


func test_no_take_is_reported_as_none() -> void:
	var r := Checker.check("alt_drift", self, "user://t604_no_takes_here")
	assert_false(r.has_take)
