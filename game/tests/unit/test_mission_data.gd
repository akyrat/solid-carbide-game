extends GutTest
## Data check for missions.json and power_ups.json (T-455).


func test_fixed_missions_are_the_boards() -> void:
	var m := MissionData.new()
	assert_true(m.is_ok(), m.error)
	assert_eq(m.total(), 30)
	assert_eq(m.fixed().size(), 5)
	var want := [["extended_drift", 2], ["alternate_drift", 10], ["airtime", 3], ["air_one_eighty", 3], ["air_three_sixty", 1]]
	for i in 5:
		var g: Dictionary = m.fixed()[i]["goals"][0]
		assert_eq(m.fixed()[i]["goals"].size(), 1)
		assert_eq(String(g["trick"]), want[i][0])
		assert_eq(int(g["amount"]), want[i][1])


func test_generator_rules_use_known_tricks_and_carry_proposals() -> void:
	var m := MissionData.new()
	for r in m.trick_rules():
		assert_true(m.known_tricks().has(r["trick"]), "known: %s" % r["trick"])
		assert_true(bool(r["proposal"]))
		assert_ne(String(r["reason"]), "")
		assert_gt(float(r["max"]), float(r["base"]))
	for g in m.fixed():
		for goal in g["goals"]:
			assert_true(m.known_tricks().has(goal["trick"]))


func test_amounts_grow_and_goal_counts_grow() -> void:
	var m := MissionData.new()
	for r in m.trick_rules():
		assert_gte(m.amount_for(r, 30), m.amount_for(r, 6))
		assert_lte(m.amount_for(r, 30), float(r["max"]))
	assert_eq(m.goals_for(6), 1)
	assert_eq(m.goals_for(20), 2)
	assert_eq(m.goals_for(30), 3)


func test_generated_mission_has_distinct_tricks() -> void:
	var m := MissionData.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for n in range(6, 31):
		var goals := m.mission(n, rng)
		assert_eq(goals.size(), m.goals_for(n))
		var seen := {}
		for g in goals:
			assert_false(seen.has(g["trick"]))
			seen[g["trick"]] = true


func test_power_ups_present_with_tiers() -> void:
	var p := PowerUpData.new()
	assert_true(p.is_ok(), p.error)
	for id in PowerUpData.IDS:
		assert_true(p.ids().has(id), id)
		assert_gte(p.tiers(id).size(), 1)
		assert_true(p.icon(id).begins_with("res://art/power_ups/"))
		for t in p.tiers(id):
			assert_true(bool(t["proposal"]))
			assert_ne(String(t["reason"]), "")
	assert_eq(p.offer_when_exhausted(), "skip_gift")
	assert_gt(float(p.at("jump", 4)["takeoff_speed"]), float(p.at("jump", 1)["takeoff_speed"]))
	assert_lt(float(p.at("rev_charge", 4)["charge_seconds"]), float(p.at("rev_charge", 1)["charge_seconds"]))
