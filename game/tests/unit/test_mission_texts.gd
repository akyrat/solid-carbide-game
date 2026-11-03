extends GutTest
## Task T-456: the mission notebook page's and the driving power-up overlay's texts in
## screen_texts.json (HUD and menus, Content, "Mission notebook and power-up texts").
## Every key the UI reads is present and non-empty; every trick type in missions.json has a
## goal template (count goals hold {done}/{total}, duration goals do not); the four power-ups
## have a name and a description; none says "Greenbull says".

const TEXTS_PATH := "res://data/screen_texts.json"
const MISSIONS_PATH := "res://data/missions.json"
const POWER_UPS_PATH := "res://data/power_ups.json"

var texts: Dictionary
var missions: Dictionary
var power_ups: Dictionary


func _load(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func before_each() -> void:
	texts = _load(TEXTS_PATH)
	missions = _load(MISSIONS_PATH)
	power_ups = _load(POWER_UPS_PATH)


func _non_empty(value, what: String) -> void:
	assert_true(value is String, "%s is a string" % what)
	assert_true(String(value).strip_edges() != "", "%s is not empty" % what)


func _goal_kinds() -> Dictionary:
	# trick id -> kind ("count" or "seconds"), from the fixed missions and the generator's rules
	var kinds := {}
	for mission in missions.fixed:
		for goal in mission.goals:
			kinds[goal.trick] = goal.kind
	for rule in missions.generator.tricks:
		kinds[rule.trick] = rule.kind
	return kinds


func test_notebook_header_and_overlay_texts_exist() -> void:
	_non_empty(texts.missions.header, "missions.header")
	_non_empty(texts.power_ups.overlay_header, "power_ups.overlay_header")
	_non_empty(texts.power_ups.take_button, "power_ups.take_button")


func test_every_trick_type_has_a_goal_template() -> void:
	var kinds := _goal_kinds()
	assert_gt(kinds.size(), 0)
	for trick in missions.known_tricks:
		assert_true(kinds.has(trick), "%s is used by a mission" % trick)
	for trick in kinds:
		assert_true(texts.missions.goals.has(trick), "a goal template for %s" % trick)
		var template = texts.missions.goals.get(trick, "")
		_non_empty(template, "missions.goals.%s" % trick)
		if kinds[trick] == "count":
			assert_true(String(template).contains("{done}/{total}"), "%s holds {done}/{total}" % trick)
		else:
			assert_false(String(template).contains("{done}"), "%s has no count" % trick)
			assert_true(String(template).contains("{seconds}"), "%s holds {seconds}" % trick)


func test_every_power_up_has_a_name_and_a_description() -> void:
	for id in power_ups.power_ups:
		assert_true(texts.power_ups.names.has(id), "a name for %s" % id)
		_non_empty(texts.power_ups.names.get(id, ""), "name of %s" % id)
		assert_true(texts.power_ups.descriptions.has(id), "a description for %s" % id)
		_non_empty(texts.power_ups.descriptions.get(id, ""), "description of %s" % id)
	assert_eq(texts.power_ups.names.rev_charge, "Rev Charge")
	assert_eq(texts.power_ups.names.jump, "Jump")
	assert_eq(texts.power_ups.names.bouncy_bumpers, "Bouncy Bumpers")
	assert_eq(texts.power_ups.names.rusty_overcoat, "Rusty Paintjob")


func test_descriptions_have_known_slots_and_no_greenbull_says() -> void:
	# T-526: the board's own words dropped most numbers, so a card may have no slot; every slot
	# a description does hold must be one the power-up screen fills.
	var known := ["charge_seconds", "boost_seconds", "boost_speed_multiplier", "cooldown_seconds",
		"bounce_multiplier", "contact_damage", "repeat_cooldown_seconds", "burst_percent"]
	var rx := RegEx.new()
	rx.compile("\\{([a-z_]+)\\}")
	for group in ["descriptions", "descriptions_last_tier"]:
		for id in texts.power_ups[group]:
			for m in rx.search_all(String(texts.power_ups[group][id])):
				assert_true(known.has(m.get_string(1)), "%s.%s: slot %s is known" % [group, id, m.get_string(1)])
	assert_true(String(texts.power_ups.descriptions["bouncy_bumpers"]).contains("{bounce_multiplier}"))
	var all := JSON.stringify(texts.missions) + JSON.stringify(texts.power_ups)
	assert_false(all.to_lower().contains("greenbull says"), "no 'Greenbull says' line")
