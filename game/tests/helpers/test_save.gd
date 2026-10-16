class_name TestSave
extends RefCounted
## Keeps tests away from the player's real save (task T-148).
## user://progress.json and user://settings.cfg are the board's real save. Before the first test
## (tests/helpers/pre_run.gd) PlayerProgress.path and GameSettings.path are pointed at files in
## this run's RunPaths folder, and a test that finishes puts them back with restore(), never with
## DEFAULT_PATH. After the run, post_run.gd fails the run if either path is the real one.

static func progress_path() -> String:
	return RunPaths.file("test_save_progress.json")


static func settings_path() -> String:
	return RunPaths.file("test_save_settings.cfg")


## Points both saves at fresh, empty test files.
static func isolate() -> void:
	DirAccess.remove_absolute(progress_path())
	DirAccess.remove_absolute(settings_path())
	restore()


## Back to the run-wide test files (what a test's after_each calls instead of DEFAULT_PATH).
static func restore() -> void:
	restore_progress()
	restore_settings()


static func restore_progress() -> void:
	PlayerProgress.path = progress_path()


static func restore_settings() -> void:
	GameSettings.path = settings_path()


## True when either save path is the real player save.
static func touches_real_save() -> bool:
	return PlayerProgress.path == PlayerProgress.DEFAULT_PATH or GameSettings.path == GameSettings.DEFAULT_PATH
