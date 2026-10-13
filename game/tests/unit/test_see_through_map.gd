extends GutTest
## Task T-034: buildings on the MVP map turn see-through while they cover the
## car (Visual style, Decisions: the whole building fades to 15% visible over
## 0.15 seconds, fades back when the car comes out, and only buildings
## actually covering the car fade).

const MapScene := preload("res://scenes/level/mvp_map.tscn")
const MvpMap := preload("res://scripts/level/mvp_map.gd")
const RunScene := preload("res://scenes/run/run.tscn")
const GameScene := preload("res://scenes/game/game.tscn")

## The block south of the gravel centre, and a point on the road just north
## of it (behind it, 6 units from its back wall).
const BLOCK := Rect2(12, 66, 30, 30)
const BEHIND := Vector2(27, 60)
## On the road just south of the same block: in front of it.
const IN_FRONT := Vector2(27, 99)
## A block far from both points.
const FAR_BLOCK := Rect2(-96, -96, 30, 30)
## The centre of the gravel square: the open, where the run starts.
const OPEN := Vector2.ZERO
## Nose up (-y), as at the run's start.
const NOSE_UP := -PI / 2.0
const NOTHING := [false, false, 0.0]


func make_map(view := "iso") -> Node2D:
	var map: Node2D = MapScene.instantiate()
	add_child_autofree(map)
	map.set_view(view)
	return map


func building_at(map: Node2D, footprint: Rect2) -> Node2D:
	for b in map.buildings:
		if b.footprint == footprint:
			return b
	return null


## Moves the fade along by `seconds`, in steps of 15 ms (about one 60 fps frame).
func advance(map: Node2D, car_at: Vector2, seconds: float) -> void:
	var dt := 0.015
	var t := 0.0
	while t < seconds - 0.0001:
		map.update_see_through(car_at, NOSE_UP, dt)
		t += dt


func test_values_follow_visual_style_decisions() -> void:
	assert_eq(MvpMap.SEE_THROUGH_ALPHA, 0.15, "fades to 15% visible")
	assert_eq(MvpMap.SEE_THROUGH_FADE_TIME, 0.15, "over 0.15 seconds")
	var map := make_map()
	assert_eq(map.buildings.size(), map.layout.buildings.size(), "one node per building")
	for b in map.buildings:
		assert_eq(b.see_through_alpha, 0.15)
		assert_eq(b.fade_time, 0.15)
		assert_eq(b.get_parent(), map.buildings_draw)


func test_building_covering_the_car_fades_and_one_not_covering_stays_opaque() -> void:
	var map := make_map()
	var block := building_at(map, BLOCK)
	var far := building_at(map, FAR_BLOCK)
	assert_not_null(block)
	assert_not_null(far)
	advance(map, BEHIND, 0.3)
	assert_true(block.covering, "the block covers the car behind it")
	assert_almost_eq(block.alpha(), 0.15, 0.001, "faded to 15% visible")
	assert_false(far.covering)
	assert_eq(far.alpha(), 1.0, "a building not covering the car stays fully opaque")
	assert_eq(map.covering_buildings(), [block], "only the building covering the car fades")
	for b in map.buildings:
		if b != block:
			assert_eq(b.alpha(), 1.0, "%s stays opaque" % b.name)


func test_building_becomes_fully_opaque_again_when_the_car_comes_out() -> void:
	var map := make_map()
	var block := building_at(map, BLOCK)
	advance(map, BEHIND, 0.3)
	assert_almost_eq(block.alpha(), 0.15, 0.001)
	advance(map, OPEN, 0.3)
	assert_false(block.covering)
	assert_eq(block.alpha(), 1.0, "fully opaque again in the open")
	advance(map, BEHIND, 0.3)
	advance(map, IN_FRONT, 0.3)
	assert_eq(block.alpha(), 1.0, "fully opaque again with the car in front of it")


func test_the_fade_takes_0_15_seconds_each_way() -> void:
	var map := make_map()
	var block := building_at(map, BLOCK)
	advance(map, BEHIND, 0.075)
	assert_almost_eq(block.alpha(), 0.575, 0.01, "halfway after half the time")
	advance(map, BEHIND, 0.075)
	assert_almost_eq(block.alpha(), 0.15, 0.001, "all the way after 0.15 s")
	advance(map, OPEN, 0.075)
	assert_almost_eq(block.alpha(), 0.575, 0.01, "halfway back")
	advance(map, OPEN, 0.075)
	assert_almost_eq(block.alpha(), 1.0, 0.001, "solid after 0.15 s")


func test_car_in_front_or_in_the_open_fades_nothing() -> void:
	var map := make_map()
	for at in [IN_FRONT, OPEN]:
		advance(map, at, 0.3)
		assert_eq(map.covering_buildings(), [], "nothing covers the car at %s" % at)
		for b in map.buildings:
			assert_eq(b.alpha(), 1.0)


func test_behind_means_hidden_on_screen_not_just_further_back() -> void:
	var map := make_map()
	var block := building_at(map, BLOCK)
	assert_true(block.is_behind(OPEN), "the gravel centre is further back than the block")
	assert_false(block.covers(OPEN, map.car_screen_shape(OPEN, NOSE_UP)), "but the block does not hide it")
	assert_false(block.is_behind(IN_FRONT))


func test_fade_changes_only_the_whole_buildings_alpha() -> void:
	var map := make_map()
	var block := building_at(map, BLOCK)
	advance(map, BEHIND, 0.3)
	assert_eq(Color(block.modulate.r, block.modulate.g, block.modulate.b), Color(1, 1, 1), "no tint")
	assert_eq(block.self_modulate, Color(1, 1, 1, 1), "the node's whole modulate fades, not its own drawing only")
	assert_null(block.material, "no shader")
	assert_eq(block.top_color.a, 1.0, "the drawing's colours stay opaque")


func test_draw_order_puts_the_car_under_covering_buildings_only() -> void:
	var map := make_map()
	var block := building_at(map, BLOCK)
	var z_behind: int = map.car_z_index(BEHIND, NOSE_UP)
	assert_lt(z_behind, block.z_index, "drawn under the block covering it")
	assert_gt(map.car_z_index(IN_FRONT, NOSE_UP), block.z_index, "drawn over the block it is in front of")
	assert_eq(map.car_z_index(OPEN, NOSE_UP), map.top_z_index())
	for b in map.buildings:
		assert_gt(b.z_index, 0, "over the ground, drift marks and boulders")
		assert_lt(b.z_index, map.top_z_index())


func test_buildings_nearer_the_viewer_are_drawn_later() -> void:
	var map := make_map()
	for p in map.buildings:
		for q in map.buildings:
			if p.depth_key() < q.depth_key():
				assert_lt(p.z_index, q.z_index)


func test_flat_view_never_fades() -> void:
	var map := make_map("flat")
	advance(map, BEHIND, 0.3)
	for b in map.buildings:
		assert_eq(b.alpha(), 1.0)
	assert_eq(map.car_z_index(BEHIND, NOSE_UP), map.top_z_index())


func test_iso_buildings_rise_and_flat_ones_do_not() -> void:
	var map := make_map()
	var block := building_at(map, BLOCK)
	var s: PackedVector2Array = block.silhouette()
	assert_eq(s.size(), 6)
	var top := INF
	for p in s:
		top = minf(top, p.y)
	var a: Vector2 = MvpMap.ISO_TRANSFORM * (BLOCK.position * MvpMap.PX_PER_UNIT)
	assert_almost_eq(top, a.y - MvpMap.BUILDING_HEIGHT_UNITS * MvpMap.PX_PER_UNIT, 0.001)
	map.set_view("flat")
	assert_eq(block.silhouette().size(), 0)


func test_map_with_car_fades_on_its_own_each_frame() -> void:
	var map := make_map()
	var stand_in := Node2D.new()
	add_child_autofree(stand_in)
	stand_in.position = BEHIND * MvpMap.PX_PER_UNIT
	stand_in.rotation = NOSE_UP
	map.car = stand_in
	await wait_seconds(0.4)
	assert_almost_eq(building_at(map, BLOCK).alpha(), 0.15, 0.001)


func _place_run_car(run: Node2D, at: Vector2) -> void:
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.scripted_input = NOTHING
	car.model.x = at.x
	car.model.y = at.y
	car._sync_from_model()
	run.sync_view()


func test_in_a_run_from_the_main_menu_the_building_fades_and_comes_back() -> void:
	var game: Node = GameScene.instantiate()
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	await wait_process_frames(2)
	var run: Node2D = game.run
	var block := building_at(run.map, BLOCK)
	_place_run_car(run, BEHIND)
	await wait_seconds(0.4)
	assert_almost_eq(block.alpha(), 0.15, 0.001, "faded while the car is behind it")
	assert_lt(run.view_root.z_index, block.z_index, "the car is drawn under it")
	assert_eq(building_at(run.map, FAR_BLOCK).alpha(), 1.0)
	_place_run_car(run, OPEN)
	await wait_seconds(0.4)
	assert_eq(block.alpha(), 1.0, "solid again once the car is in the open")
	assert_gt(run.view_root.z_index, block.z_index)


func test_drift_marks_stay_on_the_ground_under_the_buildings() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var marks: Node2D = run.drift_marks
	assert_eq(marks.z_index, 0)
	assert_lt(marks.get_index(), run.map.buildings_draw.get_index())
	for b in run.map.buildings:
		assert_gt(b.z_index, marks.z_index, "every building is drawn over the marks")
	assert_gt(run.view_root.z_index, marks.z_index, "the car is drawn over the marks")


func test_art_under_a_building_fades_with_it() -> void:
	var map := make_map()
	var block := building_at(map, BLOCK)
	var art := Sprite2D.new()
	block.add_child(art)
	block.draw_placeholder = false
	advance(map, BEHIND, 0.3)
	assert_eq(art.modulate, Color(1, 1, 1, 1), "the art itself is untouched")
	assert_almost_eq(block.modulate.a, 0.15, 0.001, "its parent fades, so the art is drawn at 15%")
	assert_true(block.covering, "the cover test does not depend on the placeholder drawing")
