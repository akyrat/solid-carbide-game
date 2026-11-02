extends GutTest
## T-513: each trick pays subs straight away (combo.json trick_subs), on top of its multiplier add.

const RunStateScript := preload("res://scripts/run/run_state.gd")

var combo_data := ComboData.new()
var state: RunState
var paid: Array = []


func before_each() -> void:
	state = RunStateScript.new()
	add_child_autofree(state)
	paid = []
	state.trick_subs_paid.connect(func(id: String, s: float) -> void: paid.append([id, s]))
	state.start_run()
	state.xp = 0.0


func test_each_trick_pays_its_subs_and_its_multiplier_add() -> void:
	for id in combo_data._data["trick_add"].keys():
		state.start_run()
		state.xp = 0.0
		paid.clear()
		var subs := combo_data.trick_subs(id)
		assert_gt(subs, 0.0, "%s pays subs" % id)
		if id == "thread_the_needle":
			state.add_needle_trick()
		else:
			state.add_trick(id)
		assert_almost_eq(state.xp, subs, 0.001, "%s subs reach the XP" % id)
		assert_almost_eq(state.combo, 1.0 + combo_data.trick_add(id), 0.001, "%s still raises the multiplier" % id)
		assert_eq(paid.size(), 1)
		assert_eq(paid[0][0], id)
		assert_almost_eq(float(paid[0][1]), subs, 0.001)


func test_subs_are_multiplied_by_the_multiplier_before_the_trick() -> void:
	state.combo = 2.0
	state.add_trick("alternate_drift")
	assert_almost_eq(state.xp, combo_data.trick_subs("alternate_drift") * 2.0, 0.001)


func test_a_trick_with_no_subs_pays_none() -> void:
	state.add_trick("extended_drift", 2.0)
	assert_eq(paid.size(), 0)
	assert_almost_eq(state.xp, 0.0, 0.001)


func test_multiplier_behaviour_unchanged() -> void:
	state.add_trick("three_sixty")
	assert_almost_eq(state.combo, 1.25, 0.001)
	state.add_xp(10.0)  # drift pay is still multiplied
	assert_almost_eq(state.xp, combo_data.trick_subs("three_sixty") + 12.5, 0.001)
	state.combo = 4.0
	state.collision()
	assert_almost_eq(state.combo, 2.5, 0.001)
