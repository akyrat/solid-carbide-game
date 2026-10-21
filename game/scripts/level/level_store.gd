class_name LevelStore
extends RefCounted
## Storage for the level creator (task T-231): the levels folder and saving, listing and loading
## levels. A level is a map file in the elevation sample map's format
## (data/level/elevation_sample_map.json: map, legend, ground_rows, buildings, pattern_copies for
## the boulders, platforms, ramps), so the run, GroundHeight and the enemies' pathfinding read it
## unchanged. Check a file with game/tools/check_level.py. The folder is a proposal for the board.

const LEVELS_DIR := "res://data/levels"


## Every level (a .json file) in the folder: [{ "name": ..., "path": ... }], sorted by name, then
## path. "name" is the file's "name" field, or the file name without .json when it has none.
## A missing folder gives an empty list. A file that isn't a JSON object is skipped.
static func list_levels(dir: String = LEVELS_DIR) -> Array:
	var out: Array = []
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
		return out
	for f in DirAccess.get_files_at(dir):
		if f.get_extension().to_lower() != "json":
			continue
		var path := dir.path_join(f)
		var data := load_level(path)
		if data.is_empty():
			continue
		out.append({"name": str(data.get("name", f.get_basename())), "path": path})
	out.sort_custom(func(a, b):
		if a.name != b.name:
			return a.name < b.name
		return a.path < b.path)
	return out


## The level's data, or an empty Dictionary when the file is missing or isn't a JSON object.
static func load_level(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var json := JSON.new()  # parse() reports a bad file by its return value, without an engine error
	if json.parse(f.get_as_text()) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data


## Writes the level as indented JSON, creating the folder when needed. Returns OK or an Error.
static func save_level(path: String, data: Dictionary) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if err != OK:
		return err
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data, " "))
	f.close()
	return OK
