extends GutTest
## T-570: the Settings screen's texts are in data/pause_text.json, short and plain.


func _text() -> Dictionary:
	var f := FileAccess.open("res://data/pause_text.json", FileAccess.READ)
	return JSON.parse_string(f.get_as_text())


func test_settings_texts_exist_and_are_plain() -> void:
	var data := _text()
	for key in ["settings_button", "settings_title", "settings_back"]:
		var t: String = data.get(key, "")
		assert_ne(t, "", key + " exists")
		assert_true(t.length() <= 30, key + " is short")
		assert_false(t.ends_with("."), key + " has no end punctuation")
	assert_eq(data["settings_button"], "Settings")
	assert_eq(data["settings_back"], "Back")
