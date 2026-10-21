class_name CreatorTexts
extends RefCounted
## Every label of the level creator comes from data/level/creator_texts.json, word for word
## (task T-233). The creator's scripts never hold a label string themselves; a test
## (tests/unit/level_creator/test_creator_texts_only.gd) scans them.

const PATH := "res://data/level/creator_texts.json"

static var _cache: Dictionary = {}


## The text of the entry `key`, or "" when the entry is missing.
static func get_text(key: String) -> String:
	if _cache.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_cache = data if data is Dictionary else {}
	var entry = _cache.get(key, {})
	return str(entry.get("text", "")) if entry is Dictionary else ""
