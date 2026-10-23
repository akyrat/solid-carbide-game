extends GutTest
## Task T-272: the thread the needle trick in a run. Crossing the gap between a paired pair of
## obstacles pays the trick once, with combo.json's amount and T-271's popup ("THREAD THE NEEDLE!"
## and "+{amount}"); a touch of either obstacle pays nothing (and the crash cuts the combo as
## always); the same pair pays again only after repeat_seconds; a pass in the air counts as
## combo.json says. The game's own map has no pairs and is unchanged.

const RunScene := preload("res://scenes/run/run.tscn")
const DT := 0.02

## Two boulders 3 across, centred at (-3, -40) and (3, -40): a 3-unit gap from x -1.5 to 1.5.
func _layout() -> Dictionary:
	var d := LevelDocument.new_level_data("T-272 needle")
	d.pattern_copies = [
		{"id": "boulder-1", "boulders": [{"x": -3.0, "y": -40.0, "diameter": 3.0, "variant": "a"}]},
		{"id": "boulder-2", "boulders": [{"x": 3.0, "y": -40.0, "diameter": 3.0, "variant": "b"}]},
	]
	d["pairs"] = [{"id": "pair-1", "a": "boulder-1", "b": "boulder-2"}]
	return d


func _rules(extra: Dictionary = {}) -> Dictionary:
	var r := ComboData.new().needle_rules()
	r.merge(extra, true)
	return r


## Moves the car's centre from `from` to `to` in steps of 0.2 units, then `after` seconds still.
func _drive(n: ThreadTheNeedle, from: Vector2, to: Vector2, airborne := false, after := 0.5) -> Array:
	var paid: Array = []
	n.last_position = null  # a new drive: no jump from where the last one ended
	var steps := int(ceil(from.distance_to(to) / 0.2))
	for i in steps + 1:
		paid.append_array(n.observe(from.lerp(to, float(i) / steps), airborne, DT))
	for i in int(after / DT):
		paid.append_array(n.observe(to, airborne, DT))
	return paid


# ---- The rules, on their own -------------------------------------------------------------------

func test_the_numbers_live_in_combo_json() -> void:
	var c := ComboData.new()
	assert_eq(c.trick_add("thread_the_needle"), 0.5, "worth an ALT DRIFT!")
	assert_eq(c.trick_add("thread_the_needle"), c.trick_add("alternate_drift"))
	assert_eq(c.trick_add("thread_the_needle"), c.trick_add("air_three_sixty"))
	var r := c.needle_rules()
	assert_eq(r.repeat_seconds, 3.0)
	assert_true(r.counts_in_air)
	assert_eq(r.touch_window_seconds, 0.5)
	assert_eq(r.clear_seconds, 0.25)
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/combo.json"))
	assert_true(raw.thread_the_needle.has("_comment"), "with its reasons")


func test_a_pass_through_the_gap_pays_once() -> void:
	var n := ThreadTheNeedle.new(_layout(), _rules())
	assert_eq(n.gates.size(), 1)
	var hits: Array = []
	n.threaded.connect(func(id): hits.append(id))
	var paid := _drive(n, Vector2(0, -30), Vector2(0, -50))
	assert_eq(paid, ["pair-1"])
	assert_eq(hits, ["pair-1"])


func test_it_pays_clear_seconds_after_the_crossing() -> void:
	var n := ThreadTheNeedle.new(_layout(), _rules())
	n.observe(Vector2(0, -39.9), false, DT)
	assert_eq(n.observe(Vector2(0, -40.1), false, DT), [], "not yet at the crossing")
	var steps := 0
	while n.observe(Vector2(0, -40.2), false, DT).is_empty():
		steps += 1
		assert_lt(steps, 100)
	assert_almost_eq(steps * DT + DT, n.rules.clear_seconds, DT + 0.0001)


func test_passing_beside_the_pair_pays_nothing() -> void:
	var n := ThreadTheNeedle.new(_layout(), _rules())
	assert_eq(_drive(n, Vector2(8, -30), Vector2(8, -50)), [], "east of both")
	assert_eq(_drive(n, Vector2(-8, -30), Vector2(-8, -50)), [], "west of both")
	assert_eq(_drive(n, Vector2(-8, -30), Vector2(8, -30)), [], "along, not across")


func test_the_same_pair_pays_again_after_the_cool_down() -> void:
	var n := ThreadTheNeedle.new(_layout(), _rules())
	assert_eq(_drive(n, Vector2(0, -35), Vector2(0, -45), false, 0.3).size(), 1)
	assert_eq(_drive(n, Vector2(0, -45), Vector2(0, -35), false, 0.3), [], "straight back: still cooling down")
	n.time += n.rules.repeat_seconds
	assert_eq(_drive(n, Vector2(0, -35), Vector2(0, -45)).size(), 1, "after repeat_seconds, either way")


func test_a_touch_before_the_crossing_pays_nothing() -> void:
	var n := ThreadTheNeedle.new(_layout(), _rules())
	var body := StaticBody2D.new()
	body.set_meta("copy_id", "boulder-2")
	autofree(body)
	n.observe(Vector2(0, -36), false, DT)
	n.touched(body, 0)
	assert_eq(_drive(n, Vector2(0, -38.5), Vector2(0, -45)), [], "a touch just before")


func test_a_touch_just_after_the_crossing_pays_nothing() -> void:
	var n := ThreadTheNeedle.new(_layout(), _rules())
	var body := StaticBody2D.new()
	body.set_meta("copy_id", "boulder-1")
	autofree(body)
	n.observe(Vector2(0, -39.9), false, DT)
	n.observe(Vector2(0, -40.1), false, DT)
	n.touched(body, 0)
	assert_eq(_drive(n, Vector2(0, -40.1), Vector2(0, -45)), [], "scraped on the way out")


func test_a_touch_of_another_obstacle_does_not_count() -> void:
	var n := ThreadTheNeedle.new(_layout(), _rules())
	var body := StaticBody2D.new()
	body.set_meta("prop_id", "prop-7")
	autofree(body)
	n.observe(Vector2(0, -38), false, DT)
	n.touched(body, 0)
	assert_eq(_drive(n, Vector2(0, -38), Vector2(0, -45)).size(), 1)


func test_in_the_air_it_counts_as_combo_json_says() -> void:
	var n := ThreadTheNeedle.new(_layout(), _rules())
	assert_eq(_drive(n, Vector2(0, -35), Vector2(0, -45), true).size(), 1, "counts_in_air: true (the proposal)")
	var off := ThreadTheNeedle.new(_layout(), _rules({"counts_in_air": false}))
	assert_eq(_drive(off, Vector2(0, -35), Vector2(0, -45), true), [], "off: not in the air")
	assert_eq(_drive(off, Vector2(0, -45), Vector2(0, -35), false).size(), 1, "off: still on the ground")


func test_prop_pairs_and_several_boulder_copies() -> void:
	var d := _layout()
	d.pattern_copies = [{"id": "copy-02", "boulders": [{"x": -3.0, "y": -40.0, "diameter": 3.0},
		{"x": 30.0, "y": 0.0, "diameter": 3.0}]}]
	d["props"] = [{"id": "prop-1", "asset": "prop-barrier", "rotation": "north", "x": 2.0, "y": -40.5, "w": 4.0, "h": 1.0}]
	d.pairs = [{"id": "pair-1", "a": "copy-02/0", "b": "prop-1"}]
	var n := ThreadTheNeedle.new(d, _rules())
	assert_eq(n.gates.size(), 1)
	var body := StaticBody2D.new()
	body.set_meta("copy_id", "copy-02")
	autofree(body)
	assert_eq(n.ref_of_body(body, 0), "copy-02/0")
	assert_eq(_drive(n, Vector2(0.5, -35), Vector2(0.5, -45)).size(), 1)


func test_a_pair_naming_a_missing_obstacle_is_left_out() -> void:
	var d := _layout()
	d.pairs = [{"id": "pair-1", "a": "boulder-1", "b": "prop-9"}]
	assert_eq(ThreadTheNeedle.new(d, _rules()).gates.size(), 0)


# ---- In a run ----------------------------------------------------------------------------------

func _run_on(layout: Dictionary) -> Node2D:
	var path := RunPaths.file("t272_run_level.json")
	assert_eq(LevelStore.save_level(path, layout), OK)
	var run: Node2D = RunScene.instantiate()
	run.layout_path = path
	add_child_autofree(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	return run


## Drives the car north from `start` (full throttle, no steering) for up to `steps` physics steps,
## or until it is north of `stop_y`; then lets it roll on for `after` steps. Returns the crashes.
func _drive_north(run: Node2D, start: Vector2, stop_y: float, steps := 600, after := 30) -> Array:
	var car = run.car
	car.model.set_position(start)
	car.model.rotation = -PI / 2.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	run.needle.last_position = null
	var hits: Array = []
	car.hit_obstacle.connect(func(c, _i, _n, _s): hits.append(c))
	car.scripted_input = [true, false, 0.0]
	for i in steps:
		car.physics_step()
		if car.model.get_position().y < stop_y:
			break
	car.scripted_input = [false, false, 0.0]
	for i in after:
		car.physics_step()
	return hits


func test_a_run_pays_the_trick_with_the_popup() -> void:
	var run := _run_on(_layout())
	var tricks: Array = []
	run.state.combo_trick.connect(func(id, added, _m): tricks.append([id, added]))
	var before: float = run.state.combo
	var hits := _drive_north(run, Vector2(0, -25), -44.0)
	assert_eq(hits, [], "clean through the gap")
	assert_eq(tricks.size(), 1, "paid once")
	assert_eq(tricks[0][0], "thread_the_needle")
	assert_almost_eq(float(tricks[0][1]), ComboData.new().trick_add("thread_the_needle"), 0.000001)
	assert_almost_eq(run.state.combo, before + 0.5, 0.000001)
	var pop = run.trick_popups.popups().back()
	assert_eq(pop.text, "THREAD THE NEEDLE! +0.5", "T-271's text word for word, with +{amount}")


func test_a_run_crash_into_either_obstacle_pays_nothing_and_cuts_the_combo() -> void:
	for x in [-3.0, 3.0]:
		var run := _run_on(_layout())
		run.state.add_trick("alternate_drift")
		run.state.add_trick("alternate_drift")
		var before: float = run.state.combo
		var tricks: Array = []
		run.state.combo_trick.connect(func(id, _a, _m): tricks.append(id))
		var hits := _drive_north(run, Vector2(x, -25), -44.0, 300)
		assert_eq(hits.size(), 1, "crashed into the boulder at x %s" % x)
		assert_false("thread_the_needle" in tricks, "nothing paid")
		assert_almost_eq(run.state.combo, ComboData.new().after_collision(before), 0.02, "cut as today")
		run.queue_free()


func test_the_popup_text_word_for_word() -> void:
	assert_eq(TrickPopups.TEXTS["thread_the_needle"], "THREAD THE NEEDLE!")
	assert_eq(TrickPopups.trick_text("thread_the_needle", 0.5), "THREAD THE NEEDLE! +0.5")
	assert_eq(TrickPopups.trick_text("thread_the_needle", 0.0), "THREAD THE NEEDLE!", "at the cap: the name only")


func test_the_run_draws_a_faint_marker_across_the_gap() -> void:
	var run := _run_on(_layout())
	var root: Node2D = run.map.view_root.get_node_or_null("NeedleMarkers")
	assert_not_null(root)
	assert_eq(root.get_child_count(), 1)
	var c := ThreadTheNeedle.MARKER_COLOR
	assert_lt(c.a, 0.5, "faint")
	assert_false(c.r8 >= 150 and c.g8 <= 100 and c.b8 <= 100, "not Redgull red")


func test_the_games_own_map_is_unchanged() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	assert_eq(run.current_layout_path(), "res://data/level/elevation_sample_map.json")
	assert_eq(run.needle.gates.size(), 0, "no pairs")
	assert_null(run.map.view_root.get_node_or_null("NeedleMarkers"), "no marker")
