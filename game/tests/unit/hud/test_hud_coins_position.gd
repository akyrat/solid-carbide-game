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
	# 1000 tall: still 16 right of the left edge, 152 px above the bottom edge (T-611: the coins
	# stay where they were when the clock left the bottom left).
	assert_eq(1000.0 + b.offset_bottom, 1000.0 - 116.0)
	assert_eq(b.offset_left, 16.0)


func test_the_clock_is_no_longer_below_the_coins() -> void:
	var hud: Hud = _box()[0]
	var b: Control = _box()[1]
	assert_eq(hud.timer_clock.anchor_top, 0.0, "the clock moved to the top centre (T-611)")
	assert_false(hud.piece_rect("coins").intersects(hud.piece_rect("clock")))
	assert_eq(b.offset_left, 16.0)


func test_not_at_the_top_right() -> void:
	var b: Control = _box()[1]
	assert_ne(b.anchor_right, 1.0)
	assert_ne(b.anchor_top, 0.0)
