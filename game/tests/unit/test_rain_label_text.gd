extends GutTest
## T-506: the rain checkbox's label is in data/pause_text.json, short, plain, sentence case.


func _text() -> Dictionary:
	var f := FileAccess.open("res://data/pause_text.json", FileAccess.READ)
	return JSON.parse_string(f.get_as_text())


func test_rain_label_exists_and_is_plain() -> void:
	var label: String = _text().get("rain_label", "")
	assert_eq(label, "Rain")
	assert_true(label.length() <= 30, "short settings label")
	assert_false(label.ends_with("."), "no end punctuation")
