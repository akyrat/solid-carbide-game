extends GutHookScript
## Runs once after the whole GUT run (set in .gutconfig.json): fails the run if a test left a save
## path on the player's real save, then removes this run's test files.

func run() -> void:
	if TestSave.touches_real_save():
		gut.logger.error("A test left PlayerProgress.path or GameSettings.path on the real save (task T-148). Use TestSave.restore().")
		set_exit_code(1)
	RunPaths.cleanup()
