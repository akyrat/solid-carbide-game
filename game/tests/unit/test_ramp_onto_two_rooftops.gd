extends GutTest
## Task T-549 (Level design, Decisions, "A ramp may climb onto several rooftops"): a ramp whose top
## end meets two rooftops of its top height side by side (the board's Kaiju City, ramp-2 and
## ramp-13, copied into tests/fixtures/height/ramp_onto_two_rooftops.json with "platform" empty):
## the car drives up it and ends on the rooftop it drives onto, either one. The game reads the
## heights, not the ramp's "platform" link (game/docs/level/game-map.md, "A ramp onto several rooftops").

const CarScript := preload("res://scripts/driving/car.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const FIXTURE := "res://tests/fixtures/height/ramp_onto_two_rooftops.json"

var _world: Node2D
var _ground


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	_ground = GroundHeightScript.from_file(FIXTURE)


func _car(start: Vector2, rotation: float) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	car.model.set_position(start)
	car.model.rotation = rotation
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.detect_tricks = false
	car.scripted_input = [true, false, 0.0]
	car.ground = _ground
	return car


func _area_id(point: Vector2) -> String:
	var i: int = _ground.area_index_at(point)
	if i < 0:
		return "street"
	if i >= _ground.platforms.size():
		return str(_ground.ramps[i - _ground.platforms.size()].id)
	return str(_ground.platforms[i].id)


## Drives W held from `start` heading `rotation` until the car is past `done` (along its heading)
## and on the ground; returns where it is and what it saw.
func _drive(start: Vector2, rotation: float, done: Callable) -> Dictionary:
	var car := _car(start, rotation)
	var on_ramp := 0
	for i in 600:
		car.physics_step()
		var pos: Vector2 = car.model.get_position()
		if _ground.is_ramp(pos):
			on_ramp += 1
		if done.call(pos) and not car.airborne:
			break
	return {"pos": car.model.get_position(), "height": car.height, "airborne": car.airborne,
		"on_ramp": on_ramp, "area": _area_id(car.model.get_position())}


func test_the_fixture_loads_with_both_ramps_unlinked() -> void:
	assert_eq(_ground.error, "")
	assert_eq(_ground.ramps.size(), 2)
	for r in _ground.ramps:
		assert_eq(str(r.platform), "", "%s names no rooftop, as in the board's file" % r.id)
	assert_almost_eq(_ground.height_at(Vector2(-76.5, -102)), 6.0 - 0.5 * 3.0 / 12.0, 1e-4, "ramp-2's top end")


func test_up_ramp_2_onto_roof_6_or_roof_7() -> void:
	# ramp-2 climbs the west sides of roof-6 (y -108..-96) and roof-7 (y -96..-66), east from 3 to 6.
	for lane in [[-102.0, "roof-6"], [-93.0, "roof-7"]]:
		var out := _drive(Vector2(-92, lane[0]), 0.0, func(p: Vector2) -> bool: return p.x > -70.0)
		assert_gt(out.on_ramp, 5, "%s: it drove up the ramp" % lane[1])
		assert_false(out.airborne, "%s: on the ground" % lane[1])
		assert_eq(out.area, lane[1], "ends on the rooftop it drove onto (%s)" % str(out.pos))
		assert_almost_eq(float(out.height), 6.0, 1e-4, "%s: at the rooftop's height" % lane[1])


func test_up_ramp_13_onto_roof_3_or_roof_6() -> void:
	# ramp-13 climbs the east sides of roof-3 (y -120..-108) and roof-6 (y -108..-96), west from 3 to 6.
	for lane in [[-114.0, "roof-3"], [-101.0, "roof-6"]]:
		var out := _drive(Vector2(-10, lane[0]), PI, func(p: Vector2) -> bool: return p.x < -36.0)
		assert_gt(out.on_ramp, 5, "%s: it drove up the ramp" % lane[1])
		assert_false(out.airborne, "%s: on the ground" % lane[1])
		assert_eq(out.area, lane[1], "ends on the rooftop it drove onto (%s)" % str(out.pos))
		assert_almost_eq(float(out.height), 6.0, 1e-4, "%s: at the rooftop's height" % lane[1])


func test_the_seam_between_the_two_rooftops_is_no_edge() -> void:
	# Across the line where roof-6 meets roof-7 (y -96), both at 6: no drop, no wall.
	var edge: Dictionary = _ground.edge_between(Vector2(-70, -100), Vector2(-70, -92))
	assert_false(edge.drop)
