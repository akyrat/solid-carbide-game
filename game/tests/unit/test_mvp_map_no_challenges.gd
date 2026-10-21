extends GutTest
## Task T-097: challenges are left out of the MVP (Level design, Decisions,
## 2026-10-11). The map in a run started from the main menu has no challenges
## and draws no arrows, every pattern copy's boulders stay where they were, the
## run never sends `score` while drifting still gives likes; and the meteor
## boulders the kaiju's meteors leave (add_meteor_boulder and its placement check).

const GameScene := preload("res://scenes/game/game.tscn")
const MapScene := preload("res://scenes/level/mvp_map.tscn")
const MvpMap := preload("res://scripts/level/mvp_map.gd")
const ChallengeArrow := preload("res://scripts/level/challenge_arrow.gd")
var TEST_PATH := RunPaths.file("test_settings_t097.cfg")
const U := 16.0

var game: Node
var run: Node2D
var scores: Array = []
var _hits: Array = []


func before_each() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	scores = []
	_hits = []


func after_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()
	get_tree().paused = false


## Opens the game, presses Start and returns the run.
func start_from_menu() -> Node2D:
	game = GameScene.instantiate()
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	await wait_process_frames(1)
	run = game.run
	# This file checks the MVP map (T-206: the run's default is the elevation map).
	run.use_elevation_map = false
	run.start_run()
	run.state.score.connect(func(a: float, id: String) -> void: scores.append([a, id]))
	return run


## Every ChallengeArrow node under `node`.
func find_arrows(node: Node) -> Array:
	var out := []
	if node.get_script() == ChallengeArrow:
		out.append(node)
	for c in node.get_children():
		out.append_array(find_arrows(c))
	return out


## The centre (units) of every boulder shape in the given bodies, rounded to 0.001.
func shape_centres(bodies: Array) -> Array:
	var out := []
	for body in bodies:
		for cs in body.get_children():
			var p: Vector2 = cs.position / U
			out.append([snappedf(p.x, 0.001), snappedf(p.y, 0.001), snappedf(cs.shape.radius * 2.0 / U, 0.001)])
	out.sort()
	return out


## Positions (units) and headings along a centre line, every `step` units.
func path_poses(line: PackedVector2Array, step := 0.25) -> Array:
	var out := []
	for i in range(1, line.size()):
		var a := line[i - 1]
		var b := line[i]
		var n := maxi(1, ceili(a.distance_to(b) / step))
		for k in n:
			out.append([a.lerp(b, float(k) / float(n)), (b - a).angle()])
	out.append([line[line.size() - 1], (line[line.size() - 1] - line[line.size() - 2]).angle()])
	return out


## Puts the run's car on each pose in turn and lets the map check it, one step each.
func drive_car_along(r: Node2D, line: PackedVector2Array) -> void:
	for pose in path_poses(line):
		r.car.model.x = pose[0].x
		r.car.model.y = pose[0].y
		r.car.model.rotation = pose[1]
		r.car._sync_from_model()
		r.map._physics_process(1.0 / 50.0)


# ---- Criterion 1: no challenges and no arrows in a run from the main menu -------------------

func test_run_from_the_main_menu_has_no_challenges_and_no_arrows() -> void:
	await start_from_menu()
	var map: Node2D = run.map
	assert_false(MvpMap.CHALLENGES_ENABLED, "challenges are off in the MVP")
	assert_false(run.challenges_enabled)
	assert_false(map.challenges_enabled)
	assert_eq(map.challenge_ids(), [], "no challenges")
	assert_eq(map.trackers.size(), 0, "no challenge is tracked")
	assert_eq(map.arrows.size(), 0, "no arrows")
	assert_eq(map.arrows_root.get_child_count(), 0, "nothing drawn on the arrow layer")
	assert_eq(find_arrows(game), [], "no challenge arrow anywhere in the game")
	assert_eq(map.get_challenge(str(map.layout.challenges[0].id)), {}, "no challenge to look up")
	# The data and code are kept for when challenges come back.
	assert_eq(map.layout.challenges.size(), 18, "the 18 challenges are still in the data")
	assert_eq(map.challenge_design_ids().size(), 3, "the 3 fitted designs are still in the data")


func test_a_new_run_from_the_menu_still_has_no_challenges() -> void:
	await start_from_menu()
	run.start_run()
	assert_eq(run.map.challenge_ids(), [])
	assert_eq(run.map.arrows.size(), 0)
	await wait_process_frames(1)  # let the old map go


# ---- Criterion 2: every pattern copy's boulders stay where they were ------------------------

func test_every_pattern_copy_keeps_its_boulders_in_place() -> void:
	await start_from_menu()
	var map: Node2D = run.map
	var copies: Array = map.layout.pattern_copies
	assert_eq(copies.size(), 60, "the 60 pattern copies (T-096)")
	assert_eq(map.boulder_bodies.size(), copies.size(), "one body per copy")
	var want := []
	for i in copies.size():
		var copy: Dictionary = copies[i]
		var body: StaticBody2D = map.boulder_bodies[i]
		assert_eq(body.get_meta("copy_id"), copy.id)
		assert_eq(body.collision_layer, 1, "an obstacle the car bounces off")
		assert_eq(body.get_child_count(), copy.boulders.size(), copy.id)
		for b in copy.boulders:
			want.append([snappedf(float(b.x), 0.001), snappedf(float(b.y), 0.001), snappedf(float(b.diameter), 0.001)])
	want.sort()
	assert_eq(want.size(), 96, "24 Single Boulder + 36 x 2 Two Boulders")
	assert_eq(shape_centres(map.boulder_bodies), want, "the bodies are where the layout data puts them")
	# The same boulders, in the same places, as a map with challenges on (as
	# before this task).
	var with_challenges: Node2D = MapScene.instantiate()
	with_challenges.challenges_enabled = true
	add_child_autofree(with_challenges)
	assert_eq(shape_centres(map.boulder_bodies), shape_centres(with_challenges.boulder_bodies))
	assert_eq(map.all_boulders(), with_challenges.all_boulders(), "the same boulders drawn")


# ---- Criterion 3: driving where the challenges were never sends score -----------------------

func test_driving_where_the_challenges_were_never_sends_score() -> void:
	await start_from_menu()
	watch_signals(run.map)
	for ch in run.map.layout.challenges:
		drive_car_along(run, MvpMap.points_of(ch.centre_line))
	assert_signal_emit_count(run.map, "challenge_completed", 0)
	assert_signal_emit_count(run.map, "meteor_challenge_completed", 0)
	assert_eq(scores, [], "the run never sends score")
	# The same drive on a run with challenges on completes them all, so the
	# drive did follow the arrows.
	var other_scores := []
	run.challenges_enabled = true
	run.start_run()
	run.state.score.connect(func(a: float, id: String) -> void: other_scores.append(id))
	for ch in run.map.layout.challenges:
		drive_car_along(run, MvpMap.points_of(ch.centre_line))
	assert_eq(other_scores.size(), 18, "with challenges on, the same drive completes all 18")
	await wait_process_frames(1)  # let the old map go


func test_drifting_still_gives_likes_in_a_run_from_the_menu() -> void:
	await start_from_menu()
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 1.0]  # W with D: drifting
	await wait_physics_frames(int(ceil(1.0 / run.car.model.dt)) + 3)
	assert_true(run.car.model.is_drifting)
	assert_gt(run.state.xp, 0.0, "drifting gives likes")
	assert_eq(scores, [], "still no score")


# ---- Criterion 4: meteor boulders -----------------------------------------------------------

func make_map() -> Node2D:
	var map: Node2D = MapScene.instantiate()
	add_child_autofree(map)
	return map


func test_placement_check_rejects_buildings_boulders_and_the_edge() -> void:
	var map := make_map()
	assert_eq(map.boulder_diameter(), 3.0, "the map's boulders are 3 units across")
	assert_true(map.can_place_meteor_boulder(Vector2(20, 20)), "free: in the gravel")
	assert_true(map.can_place_meteor_boulder(Vector2(-108, -94)), "free: on the perimeter road")
	# A building: inside the top-left block, and overlapping its edge.
	assert_false(map.can_place_meteor_boulder(Vector2(-81, -81)), "inside a building")
	assert_false(map.can_place_meteor_boulder(Vector2(-95, -81)), "overlapping a building's edge")
	assert_true(map.can_place_meteor_boulder(Vector2(-97.5, -81)), "just touching it is fine")
	# A boulder of the map's own (copy-01 at -108, -108).
	assert_false(map.can_place_meteor_boulder(Vector2(-108, -108)), "on a boulder")
	assert_false(map.can_place_meteor_boulder(Vector2(-106, -108)), "overlapping a boulder")
	assert_true(map.can_place_meteor_boulder(Vector2(-105, -108)), "just touching it is fine")
	# The map's edge (the map runs from -120 to 120).
	assert_false(map.can_place_meteor_boulder(Vector2(119, 0)), "over the right edge")
	assert_false(map.can_place_meteor_boulder(Vector2(0, -119)), "over the top edge")
	assert_false(map.can_place_meteor_boulder(Vector2(-130, 0)), "outside the map")
	assert_true(map.can_place_meteor_boulder(Vector2(118.5, -94)), "inside, touching the edge")
	# Another meteor boulder.
	map.add_meteor_boulder(Vector2(20, 20))
	assert_false(map.can_place_meteor_boulder(Vector2(20, 20)), "on another meteor boulder")
	assert_false(map.can_place_meteor_boulder(Vector2(22, 20)), "overlapping another meteor boulder")
	assert_true(map.can_place_meteor_boulder(Vector2(23, 20)), "beside it")


func test_add_meteor_boulder_matches_the_map_boulders() -> void:
	var map := make_map()
	var before: int = map.all_boulders().size()
	var body: StaticBody2D = map.add_meteor_boulder(Vector2(10, -20))
	assert_not_null(body)
	assert_true(body.is_inside_tree())
	assert_eq(body.get_parent(), map.physics_root, "with the map's other bodies")
	assert_eq(body.collision_layer, map.boulder_bodies[0].collision_layer, "same layer as the map's boulders")
	assert_eq(body.collision_layer, 1)
	assert_eq(body.collision_mask, map.boulder_bodies[0].collision_mask)
	assert_eq(body.get_child_count(), 1, "one boulder")
	var cs: CollisionShape2D = body.get_child(0)
	assert_true(cs.shape is CircleShape2D, "round, like the map's")
	assert_eq(cs.shape.radius, map.boulder_bodies[0].get_child(0).shape.radius, "the same size")
	assert_eq(cs.position, Vector2(10, -20) * U)
	assert_true(map.meteor_boulder_bodies.has(body))
	assert_eq(map.meteor_boulders, [{"x": 10.0, "y": -20.0, "diameter": 3.0}])
	assert_eq(map.all_boulders().size(), before + 1, "drawn with the other boulders")
	assert_eq(map.all_boulders().back(), {"x": 10.0, "y": -20.0, "diameter": 3.0})
	# No challenge or arrow comes with it.
	assert_eq(map.trackers.size(), 0)
	assert_eq(map.arrows.size(), 0)
	map.add_meteor_boulder(Vector2(-10, -20))
	assert_eq(map.meteor_boulders.size(), 2, "several can be placed")


func test_the_car_bounces_off_a_meteor_boulder_in_a_run() -> void:
	await start_from_menu()
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
	run.car.hit_obstacle.connect(func(c: Object, s: int, n: Vector2, v: float) -> void: _hits.append([c, s, n, v]))
	# The car starts at 0, 0 with its nose up (-y); the meteor lands ahead of it.
	var centre := Vector2(0, -11.5)
	assert_true(run.map.can_place_meteor_boulder(centre))
	var body: StaticBody2D = run.map.add_meteor_boulder(centre)
	await wait_physics_frames(2)  # new bodies join the physics space next frame
	run.car.scripted_input = [true, false, 0.0]
	var hit := false
	for i in 200:
		run.car.physics_step()
		if not _hits.is_empty():
			hit = true
			break
	assert_true(hit, "the car hit the meteor boulder")
	assert_eq(_hits[0][0], body, "the meteor boulder's body")
	assert_gt(run.car.model.get_velocity().y, 0.0, "bounced back off it (down)")
	for i in 150:
		run.car.physics_step()
	assert_gt(run.car.position.y / U - 0.5, centre.y + 1.5 - 0.01, "W held: never through it")
	assert_eq(scores, [], "no challenge came with it")


func test_a_new_run_leaves_the_meteor_boulders_behind() -> void:
	await start_from_menu()
	run.map.add_meteor_boulder(Vector2(20, 20))
	assert_eq(run.map.meteor_boulders.size(), 1)
	run.start_run()
	assert_eq(run.map.meteor_boulders, [], "a new map without them")
	assert_eq(run.map.meteor_boulder_bodies, [])
	assert_true(run.map.can_place_meteor_boulder(Vector2(20, 20)), "the spot is free again")
	await wait_process_frames(1)  # let the old map go
