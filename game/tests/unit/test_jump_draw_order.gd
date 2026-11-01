extends GutTest
## Task T-478 (the board's playtest, 2026-11-01: "the obstacles are drawn over the car when jumping
## over them"): in the real run a car above a boulder or a prop is drawn over it, a car standing
## on the ground behind it stays under it, and a car landed on top is drawn over it.

const GameScene := preload("res://scenes/game/game.tscn")

var game: Node
var run: Node2D


func before_each() -> void:
	game = GameScene.instantiate()
	add_child_autofree(game)
	game.start_run()
	run = game.run
	await wait_physics_frames(2)


## A car position behind `sp` (smaller x + y) whose drawn shape overlaps the sprite, or INF.
func _behind(sp) -> Vector2:
	var layer = run.elevation
	for d in [0.4, 0.8, 1.2, 1.6, 2.0]:
		for off in [Vector2(-d, -d), Vector2(-d, 0.0), Vector2(0.0, -d)]:
			var p: Vector2 = sp.centre_units + off
			var shape: PackedVector2Array = layer.car_shape_at(p, 0.0, 0.0)
			if sp.covers(p, shape, run.map._bounds(shape)):
				return p
	return Vector2.INF


func _check(sp) -> void:
	var p := _behind(sp)
	assert_ne(p, Vector2.INF, "%s: a car spot the sprite covers" % sp.name)
	var layer = run.elevation
	var on_ground: int = layer.z_for(p, 0.0, sp.ground_units)
	assert_lt(on_ground, sp.z_index, "%s: on the ground behind it the car is under it" % sp.name)
	var above: int = layer.z_for(p, 0.0, sp.top_units + 0.5)
	assert_gt(above, sp.z_index, "%s: above it the car is drawn over it" % sp.name)
	var on_top: int = layer.z_for(p, 0.0, sp.top_units)
	assert_gt(on_top, sp.z_index, "%s: landed on top it is drawn over it" % sp.name)
	var rising: int = layer.z_for(p, 0.0, sp.ground_units + 0.5 * (sp.top_units - sp.ground_units) + 0.05)
	assert_gt(rising, sp.z_index, "%s: past half of its rise it is drawn over it" % sp.name)


func test_the_car_is_drawn_over_a_boulder_it_is_above() -> void:
	var done := 0
	for sp in run.map.boulder_sprites:
		if sp.ground_units == 0.0:
			_check(sp)
			done += 1
			break
	assert_eq(done, 1)


func test_the_car_is_drawn_over_a_barrier_it_is_above() -> void:
	var done := 0
	for sp in run.map.prop_sprites:
		if sp.ground_units == 0.0 and sp.top_units < INF and sp.top_units < 1.0:
			_check(sp)
			done += 1
			break
	assert_eq(done, 1)


func test_a_sprite_with_no_height_keeps_the_normal_order() -> void:
	var layer = run.elevation
	var n := Node2D.new()
	assert_false(layer.car_over_sprite(n, 5.0))
	n.free()
