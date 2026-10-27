extends GutTest
## Task T-335: the timer is a digital clock at the bottom left whose digits go
## green, yellow, orange and red at the switch points in res://data/hud.json.

const RUN := preload("res://scenes/run/run.tscn")


func _hud() -> Hud:
	var r: Node2D = RUN.instantiate()
	add_child_autofree(r)
	return r.hud


func test_clock_sits_at_the_boards_layout_at_1152_x_648() -> void:
	var hud := _hud()
	var c := hud.timer_clock
	assert_eq(c.anchor_left, 0.0)
	assert_eq(c.anchor_top, 1.0, "anchored to the bottom-left corner")
	assert_eq(c.anchor_bottom, 1.0)
	# Offsets from the corner give the page's x16 y560 w200 h72 at 648 tall.
	assert_eq(c.offset_left, 16.0)
	assert_eq(c.offset_right, 216.0)
	assert_eq(648.0 + c.offset_top, 560.0)
	assert_eq(648.0 + c.offset_bottom, 632.0)


func test_clock_keeps_its_corner_margins_at_other_sizes() -> void:
	var hud := _hud()
	var c := hud.timer_clock
	assert_eq(1000.0 + c.offset_bottom, 1000.0 - 16.0, "16 px above the bottom edge at any height")
	assert_eq(c.offset_left, 16.0)


func test_clock_is_not_at_the_top_centre() -> void:
	var hud := _hud()
	assert_ne(hud.timer_clock.anchor_top, 0.0)
	assert_ne(hud.timer_clock.anchor_left, 0.5)
	assert_true(hud.timer_clock.label == hud.timer_label)
	assert_eq(hud.timer_label.get_parent(), hud.timer_clock)


func test_colour_at_each_switch_point() -> void:
	var c := _hud().timer_clock
	var cases := [[480.0, "green"], [180.1, "green"], [180.0, "yellow"], [90.1, "yellow"],
		[90.0, "orange"], [30.1, "orange"], [30.0, "red"], [0.0, "red"]]
	for case in cases:
		assert_eq(String(c.step_for(case[0])["name"]), case[1], "%s s left" % case[0])


func test_colours_are_green_yellow_orange_red() -> void:
	var c := _hud().timer_clock
	var g := c.color_for(300.0)
	var y := c.color_for(120.0)
	var o := c.color_for(60.0)
	var r := c.color_for(10.0)
	assert_gt(g.g, g.r)
	assert_true(y.r > 0.9 and y.g > 0.8)
	assert_true(o.r > 0.9 and o.g > 0.4 and o.g < 0.7)
	assert_true(r.r > 0.9 and r.g < 0.3)


func test_label_colour_follows_the_run() -> void:
	var r: Node2D = RUN.instantiate()
	add_child_autofree(r)
	var hud: Hud = r.hud
	assert_eq(hud.timer_clock.color_name, "green")
	r.state.advance(r.state.time_left - 100.0)
	assert_eq(hud.timer_clock.color_name, "yellow")
	assert_eq(hud.timer_label.get_theme_color("font_color"), hud.timer_clock.color_for(100.0))
	r.state.advance(r.state.time_left - 60.0)
	assert_eq(hud.timer_clock.color_name, "orange")
	r.state.advance(r.state.time_left - 5.0)
	assert_eq(hud.timer_clock.color_name, "red")
	r.start_run()
	assert_eq(hud.timer_clock.color_name, "green", "a fresh run starts green")
