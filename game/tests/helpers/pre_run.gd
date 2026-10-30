extends GutHookScript
## Runs once before the whole GUT run (set in .gutconfig.json): points the saves at test files.

func run() -> void:
	TestSave.isolate()
	# The main menu's Start goes straight into the run in tests that only need a run; the
	# tutorial's own tests (tests/unit/game/test_tutorial_flow.gd, T-387) turn the slides on.
	GameFlow.tutorial_enabled = false
