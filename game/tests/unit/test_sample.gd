extends GutTest
## Sample test that proves the headless test pipeline works.
## It checks the test runner itself, not any game behavior.


func test_pipeline_runs() -> void:
	assert_true(true, "The test runner executes tests.")


func test_engine_is_godot_4_6() -> void:
	var info := Engine.get_version_info()
	assert_eq(info.major, 4, "Major engine version is 4.")
	assert_eq(info.minor, 6, "Minor engine version is 6.")
