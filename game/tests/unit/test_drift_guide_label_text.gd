extends GutTest
## T-516: the Drift Guide checkbox's label is in data/pause_text.json, short, plain, sentence case.


func _text() -> Dictionary:
	var f := FileAccess.open("res://data/pause_text.json", FileAccess.READ)
	return JSON.parse_string(f.get_as_text())


func test_drift_guide_label_exists_and_is_plain() -> void:
	var label: String = _text().get("drift_guide_label", "")
	assert_eq(label, "Drift Guide")
	assert_true(label.length() <= 30, "short settings label")
	assert_false(label.ends_with("."), "no end punctuation")
