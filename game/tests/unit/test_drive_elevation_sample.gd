extends GutTest
## Task T-195: the scripted reachability drive (tools/drive_elevation_sample.gd)
## in the elevation sample map scene, the same drive the command line runs: from
## the street up a 0-to-3 ramp, up a 3-to-6 ramp, then off a height-6 edge. It
## passes when the car reaches all three layers, in order, and lands.

const Drive := preload("res://tools/drive_elevation_sample.gd")
const SampleScene := preload("res://scenes/elevation_sample/elevation_sample_map.tscn")
const EPS := 1e-6

var scene: Node2D


func before_each() -> void:
	scene = SampleScene.instantiate()
	add_child_autofree(scene)
	Drive.prepare(scene)
	# The map's buildings and boulders join the physics space on the next physics frame.
	await wait_physics_frames(2)


func test_the_route_comes_from_the_file_by_heights() -> void:
	var route: Dictionary = Drive.plan(scene.ground_height)
	assert_false(route.is_empty(), "a 0-to-3 ramp with a 3-to-6 ramp on its rooftop")
	var g = scene.ground_height
	assert_eq(g.height_at(route.start), 0.0, "starts on the street")
	assert_eq(float(g.ramp_at(route.waypoints[0].point).get("bottom_height", -1.0)), 0.0, "the 0-to-3 ramp's foot")
	assert_eq(float(g.ramp_at(route.waypoints[3].point).get("bottom_height", -1.0)), 3.0, "the 3-to-6 ramp's foot")
	assert_almost_eq(g.height_at(route.waypoints[1].point), 3.0, EPS, "on the height-3 rooftop")
	assert_almost_eq(g.height_at(route.waypoints[2].point), 3.0, EPS, "the run-up is on height 3")
	assert_almost_eq(g.height_at(route.waypoints[4].point), 6.0, 0.01, "the 3-to-6 ramp's top")
	assert_almost_eq(g.height_at(route.waypoints[5].point), 6.0, EPS, "the edge's last point is on height 6")
	assert_lt(g.height_at(route.waypoints[6].point), 6.0, "past the edge is lower")
	# The scene's own start is the same place, facing the same way.
	assert_almost_eq(route.start.distance_to(scene.START_UNITS), 0.0, 0.001)
	assert_almost_eq(route.rotation, scene.START_ROTATION, 0.001)


func test_the_drive_reaches_the_street_3_and_6_and_lands() -> void:
	var route: Dictionary = Drive.plan(scene.ground_height)
	var result: Dictionary = Drive.drive(scene, route)
	for line in Drive.log_lines(result):
		gut.p(line)
	assert_true(result.passed, "passed: %s" % [result.problems])
	var order := []
	for l in result.layers:
		order.append(l[0])
	assert_eq(order.slice(0, 3), [0, 3, 6], "street, then 3, then 6")
	assert_true(order.has(0) and order.rfind(0) > order.find(6), "back on the street after 6")
	assert_eq(result.waypoints.size(), route.waypoints.size(), "every waypoint reached")
	var e: Dictionary = result.jumps[result.edge_jump]
	assert_false(e.from_ramp, "the edge jump is a fall")
	assert_almost_eq(e.h0, 6.0, EPS, "from height 6")
	assert_true(e.landed)
	assert_almost_eq(e.land_h, 0.0, EPS, "onto the street")
	# Falling 6 units under GRAVITY from a vertical speed of 0: sqrt(2 x 6 / 12) = 1 s.
	assert_almost_eq(e.airtime, 1.0, 0.05, "about 1 s in the air")
	assert_gte(result.max_height, 6.0)
	# No wall on the way up (a boulder past the edge may still be met: they block
	# in the air too, the log lists it).
	for h in result.hit_list:
		assert_gt(h.t, e.t0, "no wall or obstacle before the height-6 edge: %s" % [h])
	var last: Array = result.samples[-1]
	assert_almost_eq(last[3], 0.0, EPS, "ends on the street")


func test_the_log_names_the_layers_the_maximum_height_and_the_airtime() -> void:
	var result: Dictionary = Drive.drive(scene, Drive.plan(scene.ground_height))
	var text := "\n".join(Drive.log_lines(result))
	assert_string_contains(text, "Layers reached, in order: 0 at 0.00 s, 3 at")
	assert_string_contains(text, ", 6 at")
	assert_string_contains(text, "Maximum height: ")
	assert_string_contains(text, "Airtime of the jump off the height-6 edge: ")
	assert_string_contains(text, "PASS")


func test_the_csv_and_the_plot() -> void:
	var result: Dictionary = Drive.drive(scene, Drive.plan(scene.ground_height))
	var csv: String = Drive.csv_text(result)
	var lines := csv.strip_edges().split("\n")
	assert_eq(lines[0], "t_s,x,y,height,ground,airborne,w,steer")
	assert_eq(lines.size(), result.samples.size() + 1)
	var img: Image = Drive.plot_image(result, false)
	assert_eq(img.get_size(), Vector2i(Drive.PLOT_W, Drive.PLOT_H))
	var light: Image = Drive.plot_image(result, true)
	assert_ne(img.get_pixel(1, 1), light.get_pixel(1, 1), "dark and light backgrounds")
