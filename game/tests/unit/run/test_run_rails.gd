extends GutTest
## Task T-541: rails in a run on the game's map (data/level/kaiju_city_map.json). The run gives
## the map's rails to the car, draws them in the map's depth order, and a grind pays the GRIND!
## trick into the combo and the subs. A Jump from the street lands on rail-3, and a Jump with D
## held hops from rail-3 to rail-4, the pair placed a first-tier Jump apart.

const GameScene := preload("res://scenes/game/game.tscn")
const Rails := preload("res://scripts/level/rails.gd")
const RailDrawing := preload("res://scripts/level/rail_drawing.gd")

var game: GameFlow
var run: Node2D


func before_each() -> void:
	TestSave.isolate()
	game = GameScene.instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	run = game.run
	run.car.use_keyboard = false
	run.car.set_physics_process(false)
	run.minions.set_physics_process(false)
	run.kaiju_boss.set_physics_process(false)


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	TestSave.restore()


## Puts the car on the street at `pos` heading north at `speed` units/s.
func _place(pos: Vector2, speed: float) -> void:
	var car = run.car
	car.model.set_position(pos)
	car.model.rotation = -PI / 2.0
	car.ground = run.elevation.ground_height
	car.model.set_velocity(Vector2(0, -speed))
	car.position = pos * 16.0
	car.scripted_input = [false, false, 0.0]


func _rail(id: String) -> int:
	for i in run.car.grind.rails.size():
		if run.car.grind.rails[i].id == id:
			return i
	return -1


func test_the_run_gives_the_maps_rails_to_the_car_and_draws_them() -> void:
	var rails: Array = run.car.grind.rails
	assert_eq(rails.size(), Rails.from_layout(run.map.layout).size())
	assert_gte(rails.size(), 4)
	assert_not_null(run.rail_drawing)
	var expected := 0
	for r in rails:
		expected += maxi(1, ceili(float(r.length) / RailDrawing.PIECE_UNITS))
	assert_eq(run.rail_drawing.pieces.size(), expected)
	assert_eq(run.rail_drawing.get_parent(), run.map.view_root)
	assert_eq(run.rail_drawing.shadows.get_index(), run.map.ground_tiles.get_index() + 1,
		"the shadows lie on the ground, right after the ground tiles")


func test_each_rail_piece_is_drawn_at_the_cars_depth_for_its_place_and_height() -> void:
	for p in run.rail_drawing.pieces:
		var r: Dictionary = run.car.grind.rails[_rail(p.rail_id)]
		var want: int = run.elevation.z_for(p.mid, atan2(r.dir.y, r.dir.x), p.mid_height) - 1
		assert_eq(p.base_z, want, "%s at %s" % [p.rail_id, p.mid])


func test_a_rail_piece_behind_a_building_is_drawn_under_it() -> void:
	# rail-2's pieces over roof-10 (a raised area at height 3, the bar at 6.1) are over the
	# rooftop; a piece the depth order puts under something has a lower z than the open top.
	var top: int = run.elevation.top_z_index()
	var lower := 0
	for p in run.rail_drawing.pieces:
		assert_lte(p.base_z, top - 1)
		if p.base_z < top - 1:
			lower += 1
	assert_gt(lower, 0, "some pieces go under what covers them")


func test_a_jump_from_the_street_lands_on_rail_3_and_the_grind_pays_grind() -> void:
	run.state.set_power_up_tier("jump", 1)
	assert_eq(run.car.jump.tier, 1)
	_place(Vector2(5.0, 0.0), 11.0)
	var tricks: Array = []
	run.state.combo_trick.connect(func(id: String, added: float, _m: float) -> void: tricks.append([id, added]))
	var before: float = run.state.combo
	run.car.press_jump()
	for i in 80:
		run.car.physics_step()
		if run.car.grind.active:
			break
	assert_true(run.car.grind.active, "caught rail-3 from a hop")
	assert_eq(run.car.grind.rail_index, _rail("rail-3"))
	for i in 600:
		run.car.physics_step()
		if not run.car.grind.active:
			break
	assert_false(run.car.grind.active, "left at the end")
	# The hop's landing on the rail pays its HANG TIME! too (a landing is a landing).
	var grinds := tricks.filter(func(t: Array) -> bool: return t[0] == "rail_grind")
	assert_eq(grinds.size(), 1, "one GRIND! for the grind")
	assert_gt(float(grinds[0][1]), 0.0)
	assert_gt(run.state.combo, before)


func test_jump_with_d_held_hops_from_rail_3_to_rail_4() -> void:
	run.state.set_power_up_tier("jump", 1)
	_place(Vector2(5.0, 0.0), 11.0)
	run.car.press_jump()
	for i in 80:
		run.car.physics_step()
		if run.car.grind.active:
			break
	assert_eq(run.car.grind.rail_index, _rail("rail-3"))
	# Wait for the Jump's cooldown, then D (right of a car going north: east, rail-4's side).
	run.car.scripted_input = [false, false, -1.0]
	for i in int(ceil(run.car.jump.cooldown_seconds / run.car.model.dt)) + 1:
		run.car.physics_step()
	assert_true(run.car.grind.active)
	run.car.press_jump()
	run.car.physics_step()
	assert_false(run.car.grind.active)
	for i in 80:
		run.car.physics_step()
		if run.car.grind.active or not run.car.airborne:
			break
	assert_true(run.car.grind.active, "landed on the second rail")
	assert_eq(run.car.grind.rail_index, _rail("rail-4"))
