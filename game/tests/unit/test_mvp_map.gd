extends GutTest
## Checks the MVP map (task T-019): its layout data against Level design, the
## fitted patterns against the board's sketches, the preset challenges, and the
## challenge completion rule driven by a stand-in body.

const MapScene := preload("res://scenes/level/mvp_map.tscn")
const MvpMap := preload("res://scripts/level/mvp_map.gd")
const ChallengeTracker := preload("res://scripts/level/challenge_tracker.gd")

const U := 16.0

var layout: Dictionary


func before_all() -> void:
	layout = MvpMap.load_layout()


## Absolute path of a file under the repo's docs/ folder (outside the Godot project).
func docs_path(rel: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("..").path_join(rel).simplify_path()


func read_json(abs_path: String) -> Dictionary:
	var data = JSON.parse_string(FileAccess.get_file_as_string(abs_path))
	return data if data is Dictionary else {}


func rect_distance(p: Vector2, r: Rect2) -> float:
	var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
	var dy := maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
	return Vector2(dx, dy).length()


## Turns a point clockwise on screen (y down) by whole quarter turns.
func rotate_quarter(p: Vector2, degrees: int) -> Vector2:
	var q := posmod(degrees / 90, 4)
	for i in q:
		p = Vector2(-p.y, p.x)
	return p


## Signed degrees a path sweeps around a point, positive clockwise on screen (y down).
func turn_around(points: PackedVector2Array, c: Vector2) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += wrapf((points[i] - c).angle() - (points[i - 1] - c).angle(), -PI, PI)
	return rad_to_deg(total)


func make_map() -> Node2D:
	var map: Node2D = MapScene.instantiate()
	add_child_autofree(map)
	return map


# ---- Criterion 1: the city grid -----------------------------------------------------------

## Level design (task T-096): 240 by 240, the first plan's layout with
## everything three times bigger: a 24-unit perimeter road, a 4 by 4 grid of
## 30 by 30 blocks and 24-unit roads (24 + 4 x 30 + 3 x 24 + 24 = 240).
const SIZE := 240
const HALF := 120
const BLOCKS := 4
const BLOCK := 30
const ROAD := 24
const PERIMETER := 24
## The gravel centre: the middle 2 by 2 blocks and the road between them.
const GRAVEL := Rect2(-42, -42, 84, 84)


## Start of each block along one axis: after the 24-unit perimeter road, a block
## of 30 then a road of 24, repeated.
func block_starts() -> Array:
	var starts := []
	for i in BLOCKS:
		starts.append(-HALF + PERIMETER + i * (BLOCK + ROAD))
	return starts


func test_map_is_240_by_240_centred_on_the_origin() -> void:
	assert_eq(PERIMETER + BLOCKS * BLOCK + (BLOCKS - 1) * ROAD + PERIMETER, SIZE, "perimeter road, blocks and roads fill the map")
	assert_eq(int(layout.map.width), SIZE)
	assert_eq(int(layout.map.height), SIZE)
	assert_eq(MvpMap.rect_of(layout.map.rect), Rect2(-HALF, -HALF, SIZE, SIZE))
	assert_eq(layout.ground_rows.size(), SIZE)
	for row in layout.ground_rows:
		assert_eq(row.length(), SIZE)


func test_blocks_are_the_4_by_4_grid_minus_the_centre() -> void:
	# Level design: 24-unit perimeter road, then blocks of 30 with 24-unit roads between.
	var starts := block_starts()
	assert_eq(starts, [-96, -42, 12, 66])
	assert_eq(starts[BLOCKS - 1] + BLOCK, HALF - PERIMETER)
	var expected := {}
	for y in starts:
		for x in starts:
			var r := Rect2(x, y, BLOCK, BLOCK)
			if not GRAVEL.encloses(r):
				expected[r] = true
	assert_eq(expected.size(), 4 * 4 - 2 * 2)
	var got := {}
	for b in layout.buildings:
		got[MvpMap.rect_of(b)] = true
	assert_eq(got.size(), layout.buildings.size(), "no block twice")
	assert_eq(got.size(), expected.size())
	for r in expected:
		assert_true(got.has(r), "block %s" % r)
	# The gravel centre has no blocks at all.
	for r in got:
		assert_false(GRAVEL.intersects(r), "block %s in the gravel" % r)


## What a 1-unit cell should be, by the rules: building inside a block, gravel
## in the centre square, road everywhere else.
func expected_cell(i: int, j: int, starts: Array) -> String:
	var c := Vector2(i - HALF + 0.5, j - HALF + 0.5)
	var in_x := false
	var in_y := false
	for s in starts:
		if c.x > s and c.x < s + BLOCK:
			in_x = true
		if c.y > s and c.y < s + BLOCK:
			in_y = true
	if GRAVEL.has_point(c):
		return "G"
	return "B" if in_x and in_y else "R"


func test_ground_cells_match_the_rules() -> void:
	var gravel := MvpMap.rect_of(layout.gravel)
	assert_eq(gravel, GRAVEL)
	var starts := block_starts()
	var counts := {"R": 0, "G": 0, "B": 0}
	for j in SIZE:
		var row: String = layout.ground_rows[j]
		for i in SIZE:
			var got := row[i]
			var want := expected_cell(i, j, starts)
			if got != want:
				fail_test("cell %d, %d is %s, want %s" % [i, j, got, want])
				return
			counts[got] += 1
	assert_eq(counts.B, 12 * BLOCK * BLOCK)
	assert_eq(counts.G, 84 * 84)
	assert_eq(counts.R, SIZE * SIZE - 12 * BLOCK * BLOCK - 84 * 84)


func test_perimeter_road_is_24_wide_and_roads_are_24_wide() -> void:
	assert_eq(int(layout.perimeter_road_width), PERIMETER)
	assert_eq(int(layout.road_width), ROAD)
	assert_eq(int(layout.block_size), BLOCK)
	for j in SIZE:
		var row: String = layout.ground_rows[j]
		for i in SIZE:
			var edge := mini(mini(i, SIZE - 1 - i), mini(j, SIZE - 1 - j))
			if edge < PERIMETER and row[i] != "R":
				fail_test("cell %d, %d on the perimeter road is %s" % [i, j, row[i]])
				return
	# Every block is 30 by 30, and the gap between neighbouring blocks along a row is 24 units.
	var xs := []
	for b in layout.buildings:
		assert_eq(MvpMap.rect_of(b).size, Vector2(BLOCK, BLOCK))
		if float(b.y) == -96.0:
			xs.append(float(b.x))
	xs.sort()
	assert_eq(xs.size(), BLOCKS)
	assert_eq(xs[0], -96.0, "24 units of perimeter road on the left")
	assert_eq(xs[BLOCKS - 1] + BLOCK, 96.0, "24 units of perimeter road on the right")
	for k in range(1, xs.size()):
		assert_eq(xs[k] - (xs[k - 1] + BLOCK), float(ROAD))


func test_buildings_and_edges_block_the_car() -> void:
	var map := make_map()
	var shapes: Array = map.walls.get_children()
	assert_eq(shapes.size(), layout.buildings.size() + 4)
	for b in layout.buildings:
		var r := MvpMap.rect_of(b)
		var found := false
		for cs in shapes:
			if cs.position == r.get_center() * U and cs.shape.size == r.size * U:
				found = true
		assert_true(found, "building collider %s" % r)
	assert_eq(map.walls.collision_layer & 1, 1)


# ---- Criterion 2: boulders and fitted patterns ---------------------------------------------

func test_every_boulder_is_3_units_across() -> void:
	var n := 0
	for copy in layout.pattern_copies:
		for b in copy.boulders:
			assert_eq(float(b.diameter), 3.0)
			n += 1
	assert_gt(n, 0)
	var map := make_map()
	for body in map.boulder_bodies:
		for cs in body.get_children():
			assert_eq(cs.shape.radius, 1.5 * U)


func test_every_pattern_copy_matches_its_fitted_version() -> void:
	for copy in layout.pattern_copies:
		var centre := Vector2(float(copy.centre[0]), float(copy.centre[1]))
		var deg := int(copy.rotation_degrees)
		assert_eq(posmod(deg, 90), 0, "quarter turns only")
		assert_gt(copy.fitted_versions.size(), 0)
		for rel in copy.fitted_versions:
			var fitted := read_json(docs_path(rel))
			assert_false(fitted.is_empty(), rel)
			assert_eq(fitted.boulders.size(), copy.boulders.size())
			for k in fitted.boulders.size():
				var fb: Dictionary = fitted.boulders[k]
				var want := rotate_quarter(Vector2(float(fb.x), float(fb.y)), deg) + centre
				var got := Vector2(float(copy.boulders[k].x), float(copy.boulders[k].y))
				assert_almost_eq(got, want, Vector2(0.001, 0.001), "%s boulder %d" % [copy.id, k])
	# Each challenge's arrow is its copy's fitted arrow, moved and turned the same way.
	for ch in layout.challenges:
		var copy: Dictionary = {}
		for c in layout.pattern_copies:
			if c.id == ch.copy:
				copy = c
		var fitted := read_json(docs_path(ch.fitted))
		var centre := Vector2(float(copy.centre[0]), float(copy.centre[1]))
		var pts := MvpMap.points_of(fitted.arrow.points)
		var got := MvpMap.points_of(ch.points)
		assert_eq(got.size(), pts.size())
		for k in pts.size():
			assert_almost_eq(got[k], rotate_quarter(pts[k], int(copy.rotation_degrees)) + centre,
				Vector2(0.001, 0.001), "%s point %d" % [ch.id, k])


func test_fitted_versions_keep_the_sketches_boulders_and_directions() -> void:
	var pairs := [
		["docs/level-design/single-boulder/arrow-1.json", "docs/level-design/single-boulder/arrow-1.fitted.json"],
		["docs/level-design/single-boulder/arrow-2.json", "docs/level-design/single-boulder/arrow-2.fitted.json"],
		["docs/level-design/two-boulders/arrow-1.json", "docs/level-design/two-boulders/arrow-1.fitted.json"],
	]
	for pair in pairs:
		var sketch := read_json(docs_path(pair[0]))
		var fitted := read_json(docs_path(pair[1]))
		assert_false(sketch.is_empty(), pair[0])
		assert_false(fitted.is_empty(), pair[1])
		assert_eq(fitted.boulders.size(), sketch.boulders.size(), pair[1])
		var sp := MvpMap.points_of(sketch.arrow.points)
		var fp := MvpMap.points_of(fitted.arrow.points)
		for k in sketch.boulders.size():
			var sb := Vector2(float(sketch.boulders[k].x), float(sketch.boulders[k].y))
			var fb := Vector2(float(fitted.boulders[k].x), float(fitted.boulders[k].y))
			var s_turn := turn_around(sp, sb)
			var f_turn := turn_around(fp, fb)
			# Same direction around each boulder, and still all the way around it.
			assert_eq(signf(f_turn), signf(s_turn), "%s boulder %d" % [pair[1], k])
			assert_gt(absf(f_turn), 270.0, "%s boulder %d goes around" % [pair[1], k])
			assert_eq(fitted.arrow.around_boulders[k].direction, sketch.arrow.around_boulders[k].direction)


# ---- Criterion 3: 30% of the copies are challenges, the same every run ----------------------

func test_challenges_are_30_percent_rounded_half_up() -> void:
	var copies: int = layout.pattern_copies.size()
	var want := maxi(1, floori(copies * 0.3 + 0.5))
	assert_eq(layout.challenges.size(), want)
	assert_eq(int(layout.challenge_rule.copies), copies)
	assert_eq(int(layout.challenge_rule.challenges), want)
	var marked := 0
	for copy in layout.pattern_copies:
		if copy.challenge != null:
			marked += 1
	assert_eq(marked, want)


func test_challenges_are_the_same_every_run() -> void:
	var a := make_map()
	var b := make_map()
	assert_eq(a.challenge_ids(), b.challenge_ids())
	assert_eq(a.layout.challenges, b.layout.challenges)
	var want := []
	for k in layout.challenges.size():
		want.append("challenge-%d" % (k + 1))
	assert_eq(a.challenge_ids(), want)
	# The choice is fixed in the layout data: which copy each challenge is on.
	assert_eq(a.layout.challenges[0].copy, b.layout.challenges[0].copy)


func test_single_boulder_challenges_use_one_of_its_arrows() -> void:
	for ch in layout.challenges:
		if ch.pattern == "single-boulder":
			assert_true(ch.arrow in ["arrow-1", "arrow-2"])


# ---- Criterion 4: nothing overlaps a building or leaves the map -----------------------------

func test_corridors_and_boulders_clear_of_buildings_and_inside_the_map() -> void:
	var map_rect := MvpMap.rect_of(layout.map.rect)
	var rects := []
	for b in layout.buildings:
		rects.append(MvpMap.rect_of(b))
	for ch in layout.challenges:
		var tracker = ChallengeTracker.new()
		tracker.setup(ch.id, MvpMap.points_of(ch.centre_line), float(ch.corridor_width))
		var r := float(ch.corridor_width) / 2.0
		var worst := INF
		for p in tracker.samples:
			assert_true(map_rect.grow(-r).has_point(p) or map_rect.grow(-r + 0.0001).has_point(p),
				"%s point %s inside the map" % [ch.id, p])
			for rect in rects:
				worst = minf(worst, rect_distance(p, rect) - r)
		assert_gte(worst, 0.0, "%s corridor clear of buildings" % ch.id)
	for copy in layout.pattern_copies:
		for b in copy.boulders:
			var c := Vector2(float(b.x), float(b.y))
			var r := float(b.diameter) / 2.0
			assert_true(map_rect.grow(-r).has_point(c), "%s boulder inside the map" % copy.id)
			for rect in rects:
				assert_gte(rect_distance(c, rect), r, "%s boulder clear of buildings" % copy.id)


# ---- Criterion 5: completing a challenge -----------------------------------------------------

## Positions (units) and headings along a centre line, every `step` units, from
## from_ratio to to_ratio of its length (reversed when to_ratio < from_ratio).
func path_poses(line: PackedVector2Array, from_ratio: float, to_ratio: float, step := 0.25) -> Array:
	var cum := [0.0]
	for i in range(1, line.size()):
		cum.append(cum[i - 1] + line[i - 1].distance_to(line[i]))
	var total: float = cum[cum.size() - 1]
	var out := []
	var s0 := from_ratio * total
	var s1 := to_ratio * total
	var n := ceili(absf(s1 - s0) / step)
	var seg := 0
	for k in n + 1:
		var s := lerpf(s0, s1, float(k) / float(n))
		seg = 0
		while seg < line.size() - 2 and cum[seg + 1] < s:
			seg += 1
		var a := line[seg]
		var b := line[seg + 1]
		var t: float = 0.0 if cum[seg + 1] == cum[seg] else (s - cum[seg]) / (cum[seg + 1] - cum[seg])
		var heading := (b - a).angle() if s1 >= s0 else (a - b).angle()
		out.append([a.lerp(b, clampf(t, 0.0, 1.0)), heading])
	return out


## Moves the stand-in body through the poses, one physics step each.
func drive(map: Node2D, body: Node2D, poses: Array) -> void:
	for pose in poses:
		body.position = pose[0] * U
		body.rotation = pose[1]
		map._physics_process(1.0 / 50.0)


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


func line_of(map: Node2D, id: String) -> PackedVector2Array:
	return MvpMap.points_of(map.get_challenge(id).centre_line)


func test_driving_a_challenge_completes_it_once() -> void:
	var map := make_map()
	var body := make_stand_in(map)
	watch_signals(map)
	var id: String = map.challenge_ids()[0]
	var boulders_before: int = map.boulder_bodies.size()
	assert_true(map.arrows[id].visible)
	drive(map, body, path_poses(line_of(map, id), 0.0, 1.0))
	assert_signal_emit_count(map, "challenge_completed", 1)
	assert_signal_emitted_with_parameters(map, "challenge_completed", [id])
	assert_true(map.is_challenge_completed(id))
	assert_false(map.arrows[id].visible, "the arrow disappears")
	# The boulders stay, as plain obstacles.
	assert_eq(map.boulder_bodies.size(), boulders_before)
	for b in map.boulder_bodies:
		assert_true(is_instance_valid(b) and b.is_inside_tree())
		assert_gt(b.get_child_count(), 0)
	# Driving it again does nothing more.
	drive(map, body, path_poses(line_of(map, id), 0.0, 1.0))
	assert_signal_emit_count(map, "challenge_completed", 1)
	# The other challenges are untouched.
	for other in map.challenge_ids():
		if other != id:
			assert_true(map.arrows[other].visible)
			assert_false(map.is_challenge_completed(other))


func test_every_challenge_can_be_completed_along_its_arrow() -> void:
	var map := make_map()
	var body := make_stand_in(map)
	watch_signals(map)
	for id in map.challenge_ids():
		drive(map, body, path_poses(line_of(map, id), 0.0, 1.0))
		assert_true(map.is_challenge_completed(id), id)
	assert_signal_emit_count(map, "challenge_completed", map.challenge_ids().size())


func test_leaving_midway_means_starting_again() -> void:
	var map := make_map()
	var body := make_stand_in(map)
	watch_signals(map)
	var id := ""
	for ch in layout.challenges:  # a figure-eight
		if ch.pattern == "two-boulders" and id == "":
			id = ch.id
	assert_ne(id, "")
	var line := line_of(map, id)
	drive(map, body, path_poses(line, 0.0, 0.5))
	assert_gt(map.trackers[id].progress_ratio(), 0.4)
	# One step off the corridor (in the gravel centre)...
	drive(map, body, [[Vector2.ZERO, 0.0]])
	assert_eq(map.trackers[id].progress_ratio(), 0.0)
	# ...then back where it left and on to the end: not completed.
	drive(map, body, path_poses(line, 0.5, 1.0))
	assert_signal_emit_count(map, "challenge_completed", 0)
	assert_true(map.arrows[id].visible)
	# From the start again: completed.
	drive(map, body, [[Vector2.ZERO, 0.0]])
	drive(map, body, path_poses(line, 0.0, 1.0))
	assert_signal_emit_count(map, "challenge_completed", 1)


func test_driving_against_the_arrow_does_not_complete_it() -> void:
	var map := make_map()
	var body := make_stand_in(map)
	watch_signals(map)
	for id in map.challenge_ids():
		drive(map, body, [[Vector2.ZERO, 0.0]])
		drive(map, body, path_poses(line_of(map, id), 1.0, 0.0))
	assert_signal_emit_count(map, "challenge_completed", 0)


func test_starting_midway_does_not_complete_it() -> void:
	var map := make_map()
	var body := make_stand_in(map)
	watch_signals(map)
	for id in map.challenge_ids():
		drive(map, body, [[Vector2.ZERO, 0.0]])
		drive(map, body, path_poses(line_of(map, id), 0.3, 1.0))
	assert_signal_emit_count(map, "challenge_completed", 0)


func test_touching_with_the_drawn_car_counts() -> void:
	# The drawn car is 3 x 1 units: its nose can touch the corridor while its
	# centre is 1.5 + 1.5 units away along its heading.
	var t = ChallengeTracker.new()
	t.setup("t", PackedVector2Array([Vector2(0, 0), Vector2(10, 0)]), 3.0)
	assert_true(t.car_touches(Vector2(5, 2.9), PI / 2))      # nose pointing at the line
	assert_false(t.car_touches(Vector2(5, 3.1), PI / 2))
	assert_true(t.car_touches(Vector2(5, 1.9), 0.0))         # side-on: half width 0.5
	assert_false(t.car_touches(Vector2(5, 2.1), 0.0))


func test_map_drawing_switches_view_without_moving_physics() -> void:
	var map := make_map()
	var before: Vector2 = map.walls.get_child(0).global_position
	map.set_view("iso")
	assert_eq(map.view_root.transform, MvpMap.ISO_TRANSFORM)
	assert_eq(map.walls.get_child(0).global_position, before)
	map.set_view("flat")
	assert_eq(map.view_root.transform, Transform2D.IDENTITY)
