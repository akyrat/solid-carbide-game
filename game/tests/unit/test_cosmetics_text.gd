extends GutTest
## T-550: the Cosmetics menu's texts (data/cosmetics_text.json) and the jump arrow checkbox's label
## (data/pause_text.json), and that no text still teaches the old grind.

const EFFECTS := ["dash_cloud", "spring", "jet_thrust", "stunt_sparks", "shockwave_ring"]


func _json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(f.get_as_text())


func test_cosmetics_texts_exist() -> void:
	var t := _json("res://data/cosmetics_text.json")
	for k in ["menu_button", "title", "locked", "buy", "pick", "equipped", "not_enough_coins"]:
		assert_true(str(t.get(k, "")).length() > 0, k)
	assert_true(str(t["locked"]).contains("{price}"), "locked has the price slot")
	for id in EFFECTS:
		var e: Dictionary = t["effects"][id]
		assert_true(str(e["name"]).length() > 0 and str(e["name"]).length() <= 25, id + " name")
		assert_true(str(e["description"]).length() > 0 and str(e["description"]).length() <= 80, id + " description")


func test_jump_arrow_label() -> void:
	var label: String = _json("res://data/pause_text.json").get("jump_arrow_label", "")
	assert_true(label.length() > 0 and label.length() <= 30)
	assert_false(label.ends_with("."))


func test_grind_texts_follow_the_overhaul() -> void:
	var t := _json("res://data/tutorial_text.json")
	var rule: String = t["trick_rule"]["rail_grind"]
	assert_true(rule.contains("hold Space"))
	assert_false(rule.contains("drop onto"))
	assert_true(str(t["trick_recipe"]["rail_grind"]["step1_note"]).length() <= 20)
