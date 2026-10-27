extends GutTest
## Task T-234: every label of the level creator comes from data/level/creator_texts.json. Scans the
## creator's scripts and scenes and fails on a string literal assigned to a label property.
## Later creator tickets keep it true: put the text in the JSON and read it with CreatorTexts.

const DIRS := ["res://scripts/level_creator/", "res://scenes/level_creator/"]
## Properties that show text to the user.
const PROPS := "text|title|placeholder_text|tooltip_text|dialog_text|hint_tooltip"


func _files() -> Array:
	var out: Array = []
	for d in DIRS:
		for f in DirAccess.get_files_at(d):
			if f.get_extension() in ["gd", "tscn"]:
				out.append(d + f)
	return out


## Lines with a hard-coded label string: `x.text = "..."`, `text = "..."` (scenes), or a
## `.text` / `.title` etc. set to a literal. "" is allowed (it shows nothing).
func scan(source: String) -> Array:
	var re := RegEx.new()
	re.compile("(^|[\\s.])(" + PROPS + ")\\s*=\\s*\"[^\"]")
	var bad: Array = []
	var n := 0
	for line in source.split("\n"):
		n += 1
		if line.strip_edges().begins_with("#"):
			continue
		if re.search(line) != null:
			bad.append("%d: %s" % [n, line.strip_edges()])
	return bad


func test_there_are_creator_files_to_scan() -> void:
	assert_gt(_files().size(), 3)


func test_no_hard_coded_labels() -> void:
	for path in _files():
		var bad := scan(FileAccess.get_file_as_string(path))
		assert_eq(bad, [], path)


func test_the_scan_catches_a_literal() -> void:
	assert_eq(scan("button.text = \"Go\"").size(), 1)
	assert_eq(scan("text = \"Go\"").size(), 1)
	assert_eq(scan("button.text = CreatorTexts.get_text(\"x\")").size(), 0)
	assert_eq(scan("b.text = \"\"").size(), 0)


func test_every_text_key_used_exists() -> void:
	var re := RegEx.new()
	re.compile("CreatorTexts\\.get_text\\(\"([a-z0-9_]+)\"\\)")
	for path in _files():
		for m in re.search_all(FileAccess.get_file_as_string(path)):
			assert_ne(CreatorTexts.get_text(m.get_string(1)), "", path + " " + m.get_string(1))
