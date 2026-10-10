class_name GameData
extends RefCounted
## Loads game data (JSON under res://data/). Every function returns a Dictionary
## {"ok": bool, "data": Variant, "error": String}, so callers can show a clear error.
## Use `GameData.unwrap(result)` to get the data and fail loudly (push_error) if it is missing.

const DATA_DIR := "res://data/"


static func _fail(msg: String) -> Dictionary:
	return {"ok": false, "data": null, "error": msg}


## Loads `res://data/<name>.json` (or a full path if `name` starts with "res://" or "user://").
static func load_file(name: String) -> Dictionary:
	var path := name if name.begins_with("res://") or name.begins_with("user://") else DATA_DIR + name + ".json"
	if not FileAccess.file_exists(path):
		return _fail("Game data file not found: %s" % path)
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		return _fail("Game data file %s is not valid JSON (line %d): %s" % [path, json.get_error_line(), json.get_error_message()])
	return {"ok": true, "data": json.data, "error": ""}


## Reads a value by dotted path ("car.starting_health"; array indexes as numbers, "levels.0.xp_needed").
static func get_value(data: Variant, key_path: String) -> Dictionary:
	var cur: Variant = data
	for part in key_path.split("."):
		if cur is Dictionary and cur.has(part):
			cur = cur[part]
		elif cur is Array and part.is_valid_int() and int(part) >= 0 and int(part) < cur.size():
			cur = cur[int(part)]
		else:
			return _fail("Game data value missing: '%s' (stopped at '%s')" % [key_path, part])
	return {"ok": true, "data": cur, "error": ""}


## Returns result.data, or null after push_error(result.error) when it failed.
static func unwrap(result: Dictionary) -> Variant:
	if not result.ok:
		push_error(result.error)
		return null
	return result.data
