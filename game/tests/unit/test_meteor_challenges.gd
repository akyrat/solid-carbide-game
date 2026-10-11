extends GutTest
## Checks the challenges created during a run for the kaiju's meteors (task
## T-035): creating each design at a position and angle, the same completion rule
## with its own signal, the placement check, and several at once.

const MapScene := preload("res://scenes/level/mvp_map.tscn")
const MvpMap := preload("res://scripts/level/mvp_map.gd")

const U := 16.0
const DESIGNS := ["single-boulder/arrow-1", "single-boulder/arrow-2", "two-boulders/arrow-1"]


func make_map() -> Node2D:
	var map: Node2D = MapScene.instantiate()
	add_child_autofree(map)
	return map


func make_stand_in(map: Node2D) -> CharacterBody2D:
	# A stand-in for the T-012 car: a 1 x 1 unit body in the same flat world pixels.
	var body := CharacterBody2D.new()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(U, U)
	cs.shape = shape
	body.add_child(cs)
	add_child_autofree(body)
	map.car = body
	return body


## Positions (units) and headings along a centre line, every `step` units.
func path_poses(line: PackedVector2Array, step := 0.25) -> Array:
	var out := []
	for i in range(1, line.size()):
		var a := line[i - 1]
		var b := line[i]
		var heading := (b - a).angle()
		var n := maxi(1, ceili(a.distance_to(b) / step))
		for k in n:
			out.append([a.lerp(b, float(k) / float(n)), heading])
	out.append([line[line.size() - 1], (line[line.size() - 1] - line[line.size() - 2]).angle()])
	return out


## Moves the stand-in body through the poses, one physics step each.
func drive(map: Node2D, body: Node2D, poses: Array) -> void:
	for pose in poses:
		body.position = pose[0] * U
		body.rotation = pose[1]
		map._physics_process(1.0 / 50.0)


func drive_challenge(map: Node2D, body: Node2D, id: String) -> void:
	var line: PackedVector2Array = map.get_meteor_challenge(id).centre_line \
			if map.is_meteor_challenge(id) else MvpMap.points_of(map.get_challenge(id).centre_line)
	drive(map, body, path_poses(line))


## How many boulders the map's own pattern copies have.
func preset_boulder_count(map: Node2D) -> int:
	var n := 0
	for copy in map.layout.pattern_copies:
		n += copy.boulders.size()
	return n


func is_green(c: Color) -> bool:
	return c.g > 0.6 and c.g > c.r + 0.2 and c.g > c.b + 0.2


# ---- Criterion 1: creating each design --------------------------------------------------------

func test_the_three_designs_are_the_fitted_versions() -> void:
	var map := make_map()
	assert_eq(map.challenge_design_ids(), DESIGNS)
	for id in DESIGNS:
		var d: Dictionary = map.get_challenge_design(id)
		var fitted_path := ProjectSettings.globalize_path("res://").path_join("..").path_join(d.fitted).simplify_path()
		var fitted = JSON.parse_string(FileAccess.get_file_as_string(fitted_path))
		assert_true(fitted is Dictionary, fitted_path)
		assert_eq(d.boulders.size(), fitted.boulders.size(), id)
		for i in d.boulders.size():
			assert_almost_eq(float(d.boulders[i].x), float(fitted.boulders[i].x), 0.001)
			assert_almost_eq(float(d.boulders[i].y), float(fitted.boulders[i].y), 0.001)
			assert_eq(float(d.boulders[i].diameter), 3.0, "3-unit boulders")
		assert_eq(float(d.corridor_width), 3.0)
		assert_eq(d.points.size(), fitted.arrow.points.size())


func test_each_design_is_created_at_the_given_position_and_angle() -> void:
	var centre := Vector2(2.0, -1.0)
	var angle := deg_to_rad(30.0)
	for design_id in DESIGNS:
		var map := make_map()
		assert_true(map.can_place_meteor_challenge(design_id, centre, angle), "a free spot in the gravel")
		var id: String = map.add_meteor_challenge(design_id, centre, angle)
		assert_eq(id, "meteor-1")
		assert_true(map.is_meteor_challenge(id))
		assert_eq(map.meteor_challenge_ids(), [id])
		var d: Dictionary = map.get_challenge_design(design_id)
		var ch: Dictionary = map.get_meteor_challenge(id)
		assert_eq(ch.design, design_id)
		# Boulders: in the data and as colliders on layer 1, moved and turned.
		assert_eq(ch.boulders.size(), d.boulders.size())
		var body: StaticBody2D = map.meteor_boulder_bodies[0]
		assert_true(body.is_inside_tree())
		assert_eq(body.collision_layer, 1)
		assert_eq(body.get_child_count(), d.boulders.size())
		for i in d.boulders.size():
			var want := Vector2(float(d.boulders[i].x), float(d.boulders[i].y)).rotated(angle) + centre
			assert_almost_eq(Vector2(ch.boulders[i].x, ch.boulders[i].y), want, Vector2(0.001, 0.001))
			var cs: CollisionShape2D = body.get_child(i)
			assert_almost_eq(cs.position, want * U, Vector2(0.01, 0.01))
			assert_almost_eq((cs.shape as CircleShape2D).radius, 1.5 * U, 0.001)
		# The arrow corridor: the design's centre line, moved and turned, drawn green.
		var local := MvpMap.points_of(d.centre_line)
		var line: PackedVector2Array = ch.centre_line
		assert_eq(line.size(), local.size())
		for i in local.size():
			assert_almost_eq(line[i], local[i].rotated(angle) + centre, Vector2(0.001, 0.001))
		var arrow: Node2D = map.arrows[id]
		assert_true(arrow.is_inside_tree() and arrow.visible)
		assert_eq(arrow.centre_line, line)
		assert_eq(arrow.corridor_width, 3.0)
		assert_true(is_green(arrow.band_color), "green band")
		assert_true(is_green(arrow.line_color), "green line")
		# The preset arrows stay blue.
		for preset in map.challenge_ids():
			assert_true(map.arrows[preset].band_color.b > map.arrows[preset].band_color.g)
		# The drawing includes the new boulders.
		assert_eq(map.all_boulders().size(), preset_boulder_count(map) + d.boulders.size())


func test_unknown_design_is_refused() -> void:
	var map := make_map()
	assert_false(map.can_place_meteor_challenge("no-such/arrow", Vector2.ZERO, 0.0))
	assert_eq(map.add_meteor_challenge("no-such/arrow", Vector2.ZERO, 0.0), "")
	assert_push_error("Unknown challenge design")
	assert_eq(map.meteor_challenge_ids(), [])


# ---- Criterion 2: completion and its signal ---------------------------------------------------

func test_driving_a_meteor_challenge_sends_its_signal_once() -> void:
	for design_id in DESIGNS:
		var map := make_map()
		var body := make_stand_in(map)
		var id: String = map.add_meteor_challenge(design_id, Vector2(0.0, 0.0), deg_to_rad(45.0))
		watch_signals(map)
		drive_challenge(map, body, id)
		assert_signal_emit_count(map, "meteor_challenge_completed", 1, design_id)
		assert_signal_emitted_with_parameters(map, "meteor_challenge_completed", [id])
		assert_signal_not_emitted(map, "challenge_completed", "not the preset signal")
		assert_true(map.is_challenge_completed(id))
		assert_false(map.arrows[id].visible, "the arrow disappears")
		assert_eq(map.open_meteor_challenge_ids(), [])
		# The boulders stay as plain obstacles.
		var bodies: Array = map.meteor_boulder_bodies
		assert_eq(bodies.size(), 1)
		assert_true(is_instance_valid(bodies[0]) and bodies[0].is_inside_tree())
		assert_eq(bodies[0].get_child_count(), map.get_meteor_challenge(id).boulders.size())
		assert_eq(map.all_boulders().size(), preset_boulder_count(map) + map.get_meteor_challenge(id).boulders.size())
		# Driving it again sends nothing more.
		drive_challenge(map, body, id)
		assert_signal_emit_count(map, "meteor_challenge_completed", 1)


func test_leaving_a_meteor_challenge_midway_does_not_complete_it() -> void:
	var map := make_map()
	var body := make_stand_in(map)
	var id: String = map.add_meteor_challenge("two-boulders/arrow-1", Vector2.ZERO, 0.0)
	watch_signals(map)
	var poses := path_poses(map.get_meteor_challenge(id).centre_line)
	var half := poses.size() / 2
	drive(map, body, poses.slice(0, half))
	drive(map, body, [[Vector2(-30.0, -30.0), 0.0]])  # off the corridor
	drive(map, body, poses.slice(half))
	assert_signal_not_emitted(map, "meteor_challenge_completed")
	assert_true(map.arrows[id].visible)


# ---- Criterion 3: preset challenges do not send it --------------------------------------------

func test_completing_a_preset_challenge_does_not_send_the_meteor_signal() -> void:
	var map := make_map()
	var body := make_stand_in(map)
	var meteor: String = map.add_meteor_challenge("single-boulder/arrow-1", Vector2.ZERO, 0.0)
	watch_signals(map)
	for preset in map.challenge_ids():
		drive_challenge(map, body, preset)
	assert_signal_emit_count(map, "challenge_completed", map.challenge_ids().size())
	assert_signal_not_emitted(map, "meteor_challenge_completed")
	assert_false(map.is_challenge_completed(meteor))
	assert_true(map.arrows[meteor].visible)


# ---- Criterion 4: the placement check ---------------------------------------------------------

func test_placement_accepts_a_free_spot() -> void:
	var map := make_map()
	for design_id in DESIGNS:
		for deg in [0.0, 45.0, 90.0, 200.0]:
			assert_true(map.can_place_meteor_challenge(design_id, Vector2.ZERO, deg_to_rad(deg)),
					"%s at the gravel centre, %d degrees" % [design_id, deg])
	# A straight stretch of the perimeter road, between two pattern copies.
	assert_true(map.can_place_meteor_challenge("two-boulders/arrow-1", Vector2(-54.0, -117.0), deg_to_rad(90.0)))
	# An empty road crossing (crossings 2, 1), along the road.
	assert_true(map.can_place_meteor_challenge("two-boulders/arrow-1", Vector2(-63.0, -81.0), deg_to_rad(90.0)))


func test_placement_rejects_a_building() -> void:
	var map := make_map()
	for design_id in DESIGNS:
		# On a building block (-77..-67).
		assert_false(map.can_place_meteor_challenge(design_id, Vector2(-72.0, -72.0), 0.0), design_id)
	# The Two Boulders fits along an 8-unit road (0.25 units from the blocks on
	# either side), but laid across one, it reaches into the blocks.
	assert_true(map.can_place_meteor_challenge("two-boulders/arrow-1", Vector2(-81.0, -63.0), 0.0))
	assert_false(map.can_place_meteor_challenge("two-boulders/arrow-1", Vector2(-81.0, -72.0), deg_to_rad(90.0)))
	# A Single Boulder fits on an empty crossing, but not pushed against a block's corner.
	assert_true(map.can_place_meteor_challenge("single-boulder/arrow-1", Vector2(-45.0, -63.0), 0.0))
	assert_false(map.can_place_meteor_challenge("single-boulder/arrow-1", Vector2(-47.0, -65.0), 0.0))


func test_placement_rejects_another_boulder() -> void:
	var map := make_map()
	# On a pattern copy's boulder (a Single Boulder at -63, -63).
	assert_false(map.can_place_meteor_challenge("single-boulder/arrow-1", Vector2(-63.0, -63.0), 0.0))
	# In the gravel near its edge, so its corridor reaches the boulder of the
	# Two Boulders copy at -45, -9 (its boulders at -48.5 and -41.5).
	assert_false(map.can_place_meteor_challenge("single-boulder/arrow-1", Vector2(-36.5, -9.0), 0.0))
	# On a meteor challenge's boulder: free before, not after.
	assert_true(map.can_place_meteor_challenge("single-boulder/arrow-2", Vector2(6.0, 0.0), 0.0))
	map.add_meteor_challenge("single-boulder/arrow-1", Vector2(6.0, 0.0), 0.0)
	assert_false(map.can_place_meteor_challenge("single-boulder/arrow-2", Vector2(6.0, 0.0), 0.0))
	assert_false(map.can_place_meteor_challenge("two-boulders/arrow-1", Vector2(3.0, 0.0), 0.0))


func test_placement_rejects_the_map_edge() -> void:
	var map := make_map()
	for design_id in DESIGNS:
		# The map runs from -121 to 121.
		assert_false(map.can_place_meteor_challenge(design_id, Vector2(-120.0, -72.0), 0.0), design_id)
		assert_false(map.can_place_meteor_challenge(design_id, Vector2(-72.0, 120.0), 0.0), design_id)
		assert_false(map.can_place_meteor_challenge(design_id, Vector2(125.0, 0.0), 0.0), design_id)


# ---- Criterion 5: several at once -------------------------------------------------------------

func test_two_meteor_challenges_complete_separately() -> void:
	var map := make_map()
	var body := make_stand_in(map)
	assert_true(map.can_place_meteor_challenge("single-boulder/arrow-2", Vector2(-6.0, -4.0), 0.0))
	var a: String = map.add_meteor_challenge("single-boulder/arrow-2", Vector2(-6.0, -4.0), 0.0)
	assert_true(map.can_place_meteor_challenge("two-boulders/arrow-1", Vector2(6.0, 2.0), 0.0))
	var b: String = map.add_meteor_challenge("two-boulders/arrow-1", Vector2(6.0, 2.0), 0.0)
	assert_ne(a, b)
	assert_eq(map.meteor_challenge_ids(), [a, b])
	assert_eq(map.open_meteor_challenge_ids(), [a, b])
	watch_signals(map)
	# The second one first.
	drive_challenge(map, body, b)
	assert_signal_emit_count(map, "meteor_challenge_completed", 1)
	assert_signal_emitted_with_parameters(map, "meteor_challenge_completed", [b])
	assert_false(map.is_challenge_completed(a))
	assert_true(map.arrows[a].visible)
	assert_false(map.arrows[b].visible)
	assert_eq(map.open_meteor_challenge_ids(), [a])
	drive_challenge(map, body, a)
	assert_signal_emit_count(map, "meteor_challenge_completed", 2)
	assert_signal_emitted_with_parameters(map, "meteor_challenge_completed", [a], 1)
	assert_eq(map.open_meteor_challenge_ids(), [])
	assert_signal_not_emitted(map, "challenge_completed")
	assert_eq(map.meteor_boulder_bodies.size(), 2)


# ---- Criterion 6: the screenshot fixture ------------------------------------------------------

func test_screenshot_fixture_shows_a_meteor_challenge_beside_a_preset_one() -> void:
	var demo: Node2D = load("res://tests/fixtures/meteor_challenge_demo.tscn").instantiate()
	add_child_autofree(demo)
	assert_eq(demo.meteor_id, "meteor-1")
	var map: Node2D = demo.map
	assert_true(map.arrows["meteor-1"].visible and is_green(map.arrows["meteor-1"].band_color))
	var preset: String = demo.PRESET_ID
	assert_true(map.arrows[preset].visible)
	assert_false(is_green(map.arrows[preset].band_color), "the preset arrow stays blue")
	assert_eq(map.get_meteor_challenge("meteor-1").design, map.get_challenge(preset).pattern + "/" + map.get_challenge(preset).arrow)
