extends GutTest
## Task T-341: the coins counter sits at the bottom left, just above the clock
## (board's layout at 1152 x 648: x16 y496, 108 x 36), anchored to that corner.

const RUN := preload("res://scenes/run/run.tscn")


func _box() -> Array:
	var r: Node2D = RUN.instantiate()
	add_child_autofree(r)
	return [r.hud, r.hud.coins_label.get_parent() as Control]


func test_anchored_to_the_bottom_left_corner() -> void:
	var b: Control = _box()[1]
	assert_eq(b.anchor_left, 0.0)
	assert_eq(b.anchor_right, 0.0)
	assert_eq(b.anchor_top, 1.0)
	assert_eq(b.anchor_bottom, 1.0)


func test_position_at_1152_x_648() -> void:
	var b: Control = _box()[1]
	assert_eq(b.offset_left, 16.0)
	assert_eq(648.0 + b.offset_top, 496.0)
	assert_eq(b.offset_right - b.offset_left, 108.0)
	assert_eq(b.offset_bottom - b.offset_top, 36.0)


func test_keeps_margins_at_a_larger_window() -> void:
	var b: Control = _box()[1]
	var hud: Hud = _box()[0]
	# 1000 tall: still 16 right of the left edge, 28 px above the clock's top.
	assert_eq(1000.0 + b.offset_bottom + 28.0, 1000.0 + hud.timer_clock.offset_top)


func test_gap_of_28_above_the_clock_and_no_overlap_in_offsets() -> void:
	var hud: Hud = _box()[0]
	var b: Control = _box()[1]
	assert_eq(hud.timer_clock.offset_top - b.offset_bottom, 28.0)
	assert_eq(b.offset_left, hud.timer_clock.offset_left)


func test_not_at_the_top_right() -> void:
	var b: Control = _box()[1]
	assert_ne(b.anchor_right, 1.0)
	assert_ne(b.anchor_top, 0.0)
