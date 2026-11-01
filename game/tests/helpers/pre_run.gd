extends GutHookScript
## Runs once before the whole GUT run (set in .gutconfig.json): points the saves at test files.

func run() -> void:
	TestSave.isolate()
	# T-468: no test run records performance, even with SC_RECORD_PERF set; its own tests turn it on.
	PerfRecorder.enabled_override = 0
	# The main menu's Start goes straight into the run in tests that only need a run; the
	# tutorial's own tests (tests/unit/game/test_tutorial_flow.gd, T-387) turn the slides on.
	GameFlow.tutorial_enabled = false
