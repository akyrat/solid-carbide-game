extends GutTest
## Task T-468: Perf's timed zones (perf.gd): off by default and silent, nesting, self time,
## each-zones summed into blocks inside the zone that holds them, and a missed end.


func before_each() -> void:
	Perf.on = false
	Perf.reset()


func after_each() -> void:
	Perf.on = false
	Perf.reset()


func _busy(usec: int) -> void:
	var t := Time.get_ticks_usec()
	while Time.get_ticks_usec() - t < usec:
		pass


## Events as dictionaries: name, t0, t1, depth, calls.
func _events() -> Array:
	var out := []
	var ev := Perf.events
	for i in range(0, ev.size(), 5):
		out.append({"name": Perf.names[ev[i]], "t0": ev[i + 1], "t1": ev[i + 2], "depth": ev[i + 3], "calls": ev[i + 4]})
	return out


func _find(events: Array, zone: String) -> Dictionary:
	for e in events:
		if e.name == zone:
			return e
	return {}


func test_off_records_nothing() -> void:
	Perf.begin(&"test.a")
	Perf.each_begin(&"test.b")
	Perf.each_end(&"test.b")
	Perf.end(&"test.a")
	assert_eq(Perf.events.size(), 0)
	assert_eq(Perf.touched.size(), 0)
	assert_eq(Perf.depth(), 0)


func test_nested_zones_and_self_time() -> void:
	Perf.on = true
	Perf.begin(&"test.outer")
	_busy(300)
	Perf.begin(&"test.inner")
	_busy(500)
	Perf.end(&"test.inner")
	Perf.end(&"test.outer")
	var outer := Perf.id_of(&"test.outer")
	var inner := Perf.id_of(&"test.inner")
	assert_true(Perf.tot_us[outer] >= 800, "outer holds both")
	assert_true(Perf.tot_us[inner] >= 500)
	assert_true(Perf.self_us[outer] < Perf.tot_us[outer] - 400, "self time leaves the inner zone out")
	var ev := _events()
	var o := _find(ev, "test.outer")
	var i := _find(ev, "test.inner")
	assert_eq(o.depth, 0)
	assert_eq(i.depth, 1)
	assert_true(i.t0 >= o.t0 and i.t1 <= o.t1, "the inner zone lies inside the outer one")


func test_each_zones_are_summed_into_one_block() -> void:
	Perf.on = true
	Perf.begin(&"test.loop")
	for k in 50:
		Perf.each_begin(&"test.item")
		Perf.begin(&"test.inside_item")  # an each-zone too, being inside one
		Perf.end(&"test.inside_item")
		Perf.each_end(&"test.item")
	Perf.end(&"test.loop")
	assert_eq(Perf.calls[Perf.id_of(&"test.item")], 50)
	assert_eq(Perf.calls[Perf.id_of(&"test.inside_item")], 50)
	var ev := _events()
	var items := ev.filter(func(e: Dictionary) -> bool: return e.name == "test.item")
	assert_eq(items.size(), 1, "one block, not 50 events")
	assert_eq(items[0].calls, 50)
	var loop := _find(ev, "test.loop")
	var inside := _find(ev, "test.inside_item")
	assert_true(items[0].t0 >= loop.t0 and items[0].t1 <= loop.t1, "the block lies inside its zone")
	assert_eq(items[0].depth, loop.depth + 1)
	assert_eq(inside.depth, items[0].depth, "a zone inside an each-zone is a block of its own beside it")
	assert_true(inside.t0 >= items[0].t1 or inside.t1 <= items[0].t0, "the blocks do not overlap")
	assert_true(inside.t0 >= loop.t0 and inside.t1 <= loop.t1)
	var item_id := Perf.id_of(&"test.item")
	var inside_id := Perf.id_of(&"test.inside_item")
	assert_true(Perf.tot_us[item_id] >= Perf.tot_us[inside_id], "the each-zone's time includes the zone inside it")
	assert_eq(Perf.self_us[item_id], Perf.tot_us[item_id] - Perf.tot_us[inside_id], "its self time leaves it out")


func test_blocks_go_after_the_last_real_child() -> void:
	Perf.on = true
	Perf.begin(&"test.parent")
	Perf.each_begin(&"test.each")
	_busy(100)
	Perf.each_end(&"test.each")
	Perf.begin(&"test.real")
	_busy(200)
	Perf.end(&"test.real")
	_busy(150)
	Perf.end(&"test.parent")
	var ev := _events()
	var real := _find(ev, "test.real")
	var block := _find(ev, "test.each")
	assert_true(block.t0 >= real.t1, "the block does not overlap the real child")


func test_a_missed_end_is_closed_by_the_outer_end() -> void:
	Perf.on = true
	Perf.begin(&"test.outer")
	Perf.begin(&"test.forgotten")
	Perf.end(&"test.outer")
	assert_eq(Perf.depth(), 0)
	assert_eq(Perf.unbalanced, 1)
	Perf.end(&"test.never_begun")  # ignored
	assert_eq(Perf.depth(), 0)
	var ev := _events()
	assert_eq(ev.size(), 2)


func test_clear_frame_empties_the_totals() -> void:
	Perf.on = true
	Perf.begin(&"test.a")
	Perf.end(&"test.a")
	assert_eq(Perf.touched.size(), 1)
	Perf.clear_frame()
	assert_eq(Perf.touched.size(), 0)
	assert_eq(Perf.events.size(), 0)
	assert_eq(Perf.calls[Perf.id_of(&"test.a")], 0)
