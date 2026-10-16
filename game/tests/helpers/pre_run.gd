extends GutHookScript
## Runs once before the whole GUT run (set in .gutconfig.json): points the saves at test files.

func run() -> void:
	TestSave.isolate()
