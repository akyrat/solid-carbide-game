extends GutTest
## Task T-589: tests/helpers/pause_guard.gd unpauses a tree a test left paused and names the test.


func test_a_paused_tree_is_unpaused_and_named() -> void:
	var gut_ref = PauseGuard._gut
	PauseGuard._gut = null  # no error line from this test's own leak
	var before := PauseGuard.leaks.size()
	get_tree().paused = true
	assert_true(PauseGuard.check(get_tree(), "fake:test_leaks"))
	assert_false(get_tree().paused)
	assert_eq(PauseGuard.leaks.size(), before + 1)
	assert_eq(PauseGuard.leaks[-1], "fake:test_leaks")
	PauseGuard.leaks.pop_back()  # the fake leak must not fail this run
	PauseGuard._gut = gut_ref


func test_an_unpaused_tree_is_left_alone() -> void:
	var before := PauseGuard.leaks.size()
	assert_false(PauseGuard.check(get_tree(), "fake:test_clean"))
	assert_false(get_tree().paused)
	assert_eq(PauseGuard.leaks.size(), before)


func test_the_run_hooks_watch_every_test() -> void:
	assert_not_null(PauseGuard._gut, "pre_run.gd called PauseGuard.watch(gut)")
	assert_true(PauseGuard._gut.end_test.is_connected(PauseGuard._on_end_test))
