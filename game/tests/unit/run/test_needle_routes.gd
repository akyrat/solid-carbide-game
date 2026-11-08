extends GutTest
## Task T-592: needle routes in a run (Level design, Decisions, "Needle routes"). Only each route's
## active pair pays thread the needle; threading it makes the next one active (in order, back to the
## first after the last; random, never the same pair twice in a row); a waiting pair pays nothing (the
## proposal); pairs in no route work as before; the active pair's marker is bright, the waiting ones
## faint; the flash of T-451 is unchanged. The proposals are in data/level/needle_routes.json.

const RunScene := preload("res://scenes/run/run.tscn")
const DT := 0.02


## Four boulder pairs, each a 3-unit gap across x -1.5 to 1.5, at y -40, -60, -80 and -100.
func _layout(routes: Array = []) -> Dictionary:
	var d := LevelDocument.new_level_data("T-592 routes")
	d.pattern_copies = []
	d["pairs"] = []
	for i in 4:
		var y := -40.0 - 20.0 * i
		d.pattern_copies.append({"id": "boulder-%d" % (2 * i + 1), "boulders": [{"x": -3.0, "y": y, "diameter": 3.0, "variant": "a"}]})
		d.pattern_copies.append({"id": "boulder-%d" % (2 * i + 2), "boulders": [{"x": 3.0, "y": y, "diameter": 3.0, "variant": "b"}]})
		d.pairs.append({"id": "pair-%d" % (i + 1), "a": "boulder-%d" % (2 * i + 1), "b": "boulder-%d" % (2 * i + 2)})
	if not routes.is_empty():
		d["routes"] = routes
	return d


## Through gap `i` (0 to 3) northwards, then still for 0.5 s: the pairs paid.
func _thread(n: ThreadTheNeedle, i: int) -> Array:
	var y := -40.0 - 20.0 * i
	var paid: Array = []
	n.last_position = null
	for k in 21:
		paid.append_array(n.observe(Vector2(0, y + 2.0 - 0.2 * k), false, DT))
	for k in 25:
		paid.append_array(n.observe(Vector2(0, y - 2.0), false, DT))
	# past the repeat cool-down, so the next pass is judged on the route alone
	for k in int(ComboData.new().needle_rules().repeat_seconds / DT) + 1:
		n.observe(Vector2(0, y - 2.0), false, DT)
	return paid


func _index_of(id: String) -> int:
	return int(id.substr(5)) - 1


func test_the_proposals_live_in_data_with_their_reasons() -> void:
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/level/needle_routes.json"))
	assert_true(raw is Dictionary and raw.has("_comment"))
	var s := NeedleRoutes.load_settings()
	assert_gt(float(s.active.alpha), float(s.free.alpha), "the active pair brighter than a pair in no route")
	assert_lt(float(s.waiting.alpha), float(s.free.alpha), "the waiting ones fainter")
	assert_eq(str(s.waiting_threaded), "nothing")
	assert_almost_eq(float(s.free.alpha), ThreadTheNeedle.MARKER_COLOR.a, 0.001, "a pair in no route looks as before")


func test_without_routes_every_pair_pays_as_before() -> void:
	var n := ThreadTheNeedle.new(_layout())
	for i in 4:
		assert_eq(n.routes.state_of("pair-%d" % (i + 1)), NeedleRoutes.FREE)
		assert_eq(_thread(n, i), ["pair-%d" % (i + 1)])


func test_in_order_only_the_active_pair_pays_and_it_cycles_back() -> void:
	var n := ThreadTheNeedle.new(_layout([{"id": "route-1", "order": "in_order", "pairs": ["pair-3", "pair-1", "pair-2"]}]))
	assert_eq(n.routes.active_of("route-1"), "pair-3", "an in-order route starts at its first pair")
	assert_eq(n.routes.state_of("pair-1"), NeedleRoutes.WAITING)
	assert_eq(n.routes.state_of("pair-4"), NeedleRoutes.FREE)
	assert_eq(_thread(n, 0), [], "pair-1 waits: threading it pays nothing")
	assert_eq(n.routes.active_of("route-1"), "pair-3", "and does not move the route on")
	assert_eq(_thread(n, 2), ["pair-3"])
	assert_eq(n.routes.active_of("route-1"), "pair-1")
	assert_eq(_thread(n, 2), [], "pair-3 waits now")
	assert_eq(_thread(n, 0), ["pair-1"])
	assert_eq(_thread(n, 1), ["pair-2"])
	assert_eq(n.routes.active_of("route-1"), "pair-3", "back to the first after the last")
	assert_eq(_thread(n, 2), ["pair-3"])
	assert_eq(_thread(n, 3), ["pair-4"], "a pair in no route pays as before")


func test_random_never_repeats_the_same_pair_twice_in_a_row() -> void:
	var layout := _layout([{"id": "route-1", "order": "random", "pairs": ["pair-1", "pair-2", "pair-3", "pair-4"]}])
	for seed_value in [1, 2, 3, 7, 42]:
		var r := NeedleRoutes.new(layout, [], seed_value)
		var seen := {}
		var last := r.active_of("route-1")
		seen[last] = true
		for k in 200:
			var now := r.threaded(last)
			assert_ne(now, "", "a route of four moves on")
			assert_ne(now, last, "never the same pair twice in a row (seed %d)" % seed_value)
			last = now
			seen[now] = true
		assert_eq(seen.size(), 4, "every pair comes up")


func test_random_starts_at_a_random_pair() -> void:
	var layout := _layout([{"id": "route-1", "order": "random", "pairs": ["pair-1", "pair-2", "pair-3", "pair-4"]}])
	var starts := {}
	for seed_value in 40:
		starts[NeedleRoutes.new(layout, [], seed_value).active_of("route-1")] = true
	assert_gt(starts.size(), 1)


func test_random_in_a_run_pays_only_the_active_pair() -> void:
	var n := ThreadTheNeedle.new(_layout([{"id": "route-1", "order": "random", "pairs": ["pair-1", "pair-2", "pair-3"]}]))
	for k in 8:
		var active := n.routes.active_of("route-1")
		for other in ["pair-1", "pair-2", "pair-3"]:
			if other != active:
				assert_eq(_thread(n, _index_of(other)), [], "%s waits" % other)
		assert_eq(_thread(n, _index_of(active)), [active])
		assert_ne(n.routes.active_of("route-1"), active)


func test_a_route_of_one_pair_pays_like_a_free_pair() -> void:
	var n := ThreadTheNeedle.new(_layout([{"id": "route-1", "order": "random", "pairs": ["pair-2"]}]))
	assert_eq(n.routes.state_of("pair-2"), NeedleRoutes.ACTIVE)
	assert_eq(_thread(n, 1), ["pair-2"])
	assert_eq(_thread(n, 1), ["pair-2"], "still active")


func test_a_route_pair_whose_obstacles_are_gone_is_skipped() -> void:
	var d := _layout([{"id": "route-1", "order": "in_order", "pairs": ["pair-9", "pair-2", "pair-1"]}])
	var n := ThreadTheNeedle.new(d)
	assert_eq(n.routes.active_of("route-1"), "pair-2")
	assert_eq(_thread(n, 1), ["pair-2"])
	assert_eq(n.routes.active_of("route-1"), "pair-1")


func test_two_routes_move_on_their_own() -> void:
	var n := ThreadTheNeedle.new(_layout([
		{"id": "route-1", "order": "in_order", "pairs": ["pair-1", "pair-2"]},
		{"id": "route-2", "order": "in_order", "pairs": ["pair-3", "pair-4"]}]))
	assert_eq(_thread(n, 0), ["pair-1"])
	assert_eq(n.routes.active_of("route-1"), "pair-2")
	assert_eq(n.routes.active_of("route-2"), "pair-3")
	assert_eq(_thread(n, 2), ["pair-3"])
	assert_eq(n.routes.active_of("route-2"), "pair-4")


# ---- The markers: bright active, faint waiting ---------------------------------------------------

## A run on `layout` (its markers and flash as the run builds them).
func _run_on(layout: Dictionary) -> Node2D:
	var path := RunPaths.file("t592_run_level.json")
	assert_eq(LevelStore.save_level(path, layout), OK)
	var run: Node2D = RunScene.instantiate()
	run.layout_path = path
	add_child_autofree(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	return run


func test_the_active_marker_is_bright_and_the_waiting_ones_faint() -> void:
	var run := _run_on(_layout([{"id": "route-1", "order": "in_order", "pairs": ["pair-1", "pair-2", "pair-3"]}]))
	var n: ThreadTheNeedle = run.needle
	var s := NeedleRoutes.load_settings()
	assert_almost_eq(n.markers["pair-1"].alpha, float(s.active.alpha), 0.001)
	assert_almost_eq(n.markers["pair-1"].width_factor, float(s.active.width), 0.001)
	assert_almost_eq(n.markers["pair-2"].alpha, float(s.waiting.alpha), 0.001)
	assert_almost_eq(n.markers["pair-3"].alpha, float(s.waiting.alpha), 0.001)
	assert_almost_eq(n.markers["pair-4"].alpha, ThreadTheNeedle.MARKER_COLOR.a, 0.001, "in no route: as before")
	_thread(n, 0)
	assert_almost_eq(n.markers["pair-1"].alpha, float(s.waiting.alpha), 0.001, "threaded: it waits now")
	assert_almost_eq(n.markers["pair-2"].alpha, float(s.active.alpha), 0.001, "the next one is bright")


func test_the_flash_still_comes_only_for_the_pair_that_paid() -> void:
	var run := _run_on(_layout([{"id": "route-1", "order": "in_order", "pairs": ["pair-1", "pair-2"]}]))
	var n: ThreadTheNeedle = run.needle
	var fl: NeedleFlash = run.needle_flash
	_thread(n, 1)
	assert_false(fl.is_flashing("pair-2"), "a waiting pair makes no flash")
	n.last_position = null
	for k in 21:
		n.observe(Vector2(0, -38.0 - 0.2 * k), false, DT)
	for k in 13:
		n.observe(Vector2(0, -42.0), false, DT)
	assert_true(fl.is_flashing("pair-1"), "the active pair flashes when it pays")
