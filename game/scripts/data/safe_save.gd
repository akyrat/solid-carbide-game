class_name SafeSave
extends RefCounted
## Safe reading and writing of the JSON save files (task T-417): progress.json and
## run_history.json. Garage design, Decisions, "A broken save never wipes progress".
##
## - write(): the text goes to "<file>.tmp" first; the last good file is copied to
##   "<file>.bak"; then the temp file is renamed over the file. A save cut off before the
##   rename leaves the old file as it was.
## - read(): a file that fails to load is never overwritten: it is renamed aside to
##   "<file>.broken-<unix time>", and the backup is loaded in its place (none: a new player).
## - Every save carries "version" (CURRENT_VERSION); a file without one is version 1.

const CURRENT_VERSION := 1
const TMP := ".tmp"
const BACKUP := ".bak"
const BROKEN := ".broken-"


## Parses one file into a Dictionary. Returns {} when it is missing, unreadable, not JSON
## or not a JSON object.
static func _parse(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var json := JSON.new()
	if json.parse(f.get_as_text()) != Error.OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data


static func _is_valid(path: String, required_key: String) -> bool:
	var d := _parse(path)
	return not d.is_empty() and (required_key == "" or d.has(required_key))


## Loads the save at `path`. `required_key` is a key a good file always holds ("" = any
## object). Returns {"data": Dictionary, "source": "main" | "backup" | "none",
## "version": int}. "none" means a new player (data is empty). A broken main file is
## renamed aside, never left to be overwritten.
static func read(path: String, required_key: String = "") -> Dictionary:
	if _is_valid(path, required_key):
		return _result(_parse(path), "main")
	if FileAccess.file_exists(path):
		_move_aside(path)
	var bak := path + BACKUP
	if _is_valid(bak, required_key):
		return _result(_parse(bak), "backup")
	return {"data": {}, "source": "none", "version": CURRENT_VERSION}


static func _result(data: Dictionary, source: String) -> Dictionary:
	return {"data": data, "source": source, "version": int(data.get("version", 1))}


## Renames a broken file to "<file>.broken-<unix time>" (a number is added if that name
## is taken). Returns the new path, or "" if it could not be moved.
static func _move_aside(path: String) -> String:
	var base := path + BROKEN + str(int(Time.get_unix_time_from_system()))
	var target := base
	var n := 2
	while FileAccess.file_exists(target):
		target = "%s-%d" % [base, n]
		n += 1
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(target)) != OK:
		push_error("Could not move the broken save %s aside" % path)
		return ""
	push_warning("The save %s could not be read; kept as %s" % [path, target])
	return target


## Writes `data` (a Dictionary, with "version" added) to `path` safely. Returns true on
## success. `stop_before_rename` only exists so a test can simulate a save cut off
## after the temp file was written.
static func write(path: String, data: Dictionary, required_key: String = "", stop_before_rename: bool = false) -> bool:
	var out := data.duplicate()
	out["version"] = CURRENT_VERSION
	var tmp := path + TMP
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Could not write the save file %s" % tmp)
		return false
	f.store_string(JSON.stringify(out, "\t"))
	f.close()
	if not _is_valid(tmp, required_key):
		push_error("The save file %s did not read back; the old file was kept" % tmp)
		return false
	if stop_before_rename:
		return false
	# Keep the last good file as the backup (only a file that loads becomes the backup).
	if _is_valid(path, required_key):
		var g := ProjectSettings.globalize_path(path)
		if DirAccess.copy_absolute(g, g + BACKUP) != OK:
			push_warning("Could not update the backup of %s" % path)
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path)) != OK:
		push_error("Could not move the new save into place: %s" % path)
		return false
	return true


## Removes a save and everything kept beside it (temp file, backup, broken files). For tests.
static func remove_all(path: String) -> void:
	var dir := path.get_base_dir()
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		if f == path.get_file() or f.begins_with(path.get_file() + "."):
			DirAccess.remove_absolute(dir.path_join(f))
