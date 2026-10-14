class_name RunPaths
extends RefCounted
## Per-run files under user:// for tests (task T-137).
## Godot's user folder is shared by every task folder, so two GUT runs at once must not use the
## same file names. Every test file path comes from here: it sits in a folder named after this
## run's process id, so parallel runs never touch each other's files.
## The folder is removed when the run ends (tests/helpers/post_run.gd).

const ROOT := "user://test_runs"

## The folder for this run (created on first use).
static func dir() -> String:
	var d := ROOT.path_join(str(OS.get_process_id()))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))
	return d


## A file (or sub-folder) path inside this run's folder.
static func file(name: String) -> String:
	return dir().path_join(name)


## Removes this run's folder and everything in it.
static func cleanup() -> void:
	_remove_tree(ProjectSettings.globalize_path(ROOT.path_join(str(OS.get_process_id()))))


static func _remove_tree(abs_dir: String) -> void:
	if not DirAccess.dir_exists_absolute(abs_dir):
		return
	for f in DirAccess.get_files_at(abs_dir):
		DirAccess.remove_absolute(abs_dir.path_join(f))
	for d in DirAccess.get_directories_at(abs_dir):
		_remove_tree(abs_dir.path_join(d))
	DirAccess.remove_absolute(abs_dir)
