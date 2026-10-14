extends GutHookScript
## Runs once after the whole GUT run (set in .gutconfig.json): removes this run's test files.

func run() -> void:
	RunPaths.cleanup()
