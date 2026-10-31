extends GutTest
## Task T-438 (Drifting, Decisions, "A wall hit ends the drift", board 2026-10-31): the real
## car (car.gd) drifts into a building side; the drift ends on the hit step and pays once for
## the time up to the hit, the hit's combo cut applies once, and a new drift can start after
## the bounce. A drift that never touches a wall still ends and pays when the player ends it.
## The run's wiring (run.gd) is rebuilt here: hit_obstacle -> state.collision(), crashed ->
## settle_tricks(), trick -> add_trick(), stepped -> drift_step().

const CarScript := preload("res://scripts/driving/car.gd")
const U := 16.0
const W_LEFT := [true, false, 1.0]
const W := [true, false, 0.0]

var _world: Node2D
var _state: RunState
var _hits := 0
var _paid: Array = []       # [step, seconds] of each extended_drift
var _cuts := 0
var _step := 0


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	_state = RunState.new()
	add_child_autofree(_state)
	_state.start_run()
	_hits = 0
	_paid = []
	_cuts = 0
	_step = 0


func _wall() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = CarScript.LAYER_OBSTACLES
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 2) * U
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(0, -11) * U
	body.add_child(cs)
	_world.add_child(body)


func _car(start: Vector2) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	car.model.set_position(start)
	car.model.rotation = -PI / 2.0
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.detect_tricks = true
	car.tricks.drift_min_seconds = 0.1
	car.hit_obstacle.connect(func(_c, _i, _n, _s) -> void:
		_hits += 1
		_state.collision())
	_state.crashed.connect(car.settle_tricks)
	_state.combo_broken.connect(func() -> void: _cuts += 1)
	car.trick.connect(func(id: String) -> void:
		if id == "extended_drift":
			_paid.append([_step + 1, car.tricks.last_trick_seconds])
		_state.add_trick(id, car.tricks.last_trick_seconds))
	car.stepped.connect(func() -> void: _state.drift_step(car.model.is_drifting, car.model.dt))
	return car


func _go(car, input: Array) -> void:
	car.scripted_input = input
	car.physics_step()
	_step += 1


func test_a_wall_hit_ends_the_drift_and_pays_once_before_the_cut() -> void:
	_wall()
	var car = _car(Vector2(0, -6.5))
	await wait_physics_frames(2)
	_state.combo = 3.0
	var hit_step := -1
	var drifting_before_hit := 0
	for i in 200:
		_go(car, W_LEFT)
		if _hits > 0:
			hit_step = _step
			break
		assert_true(car.model.is_drifting, "drifting before the hit")
		drifting_before_hit += 1
	assert_gt(hit_step, 0, "the car hit the wall")
	assert_false(car.model.is_drifting, "the drift ended on the hit step")
	assert_eq(_paid.size(), 1, "paid once, on the hit step")
	assert_eq(_paid[0][0], hit_step, "paid on the hit step")
	assert_almost_eq(float(_paid[0][1]), drifting_before_hit * car.model.dt, 1e-6, "for the time up to the hit")
	assert_eq(_cuts, 1, "the combo cut applied once")
	assert_lt(_state.combo, 3.0 + 0.5, "cut")
	assert_eq(_state.drift_seconds, 0.0, "the run's drift seconds stopped counting")


func test_a_new_drift_starts_after_the_bounce() -> void:
	_wall()
	var car = _car(Vector2(0, -6.5))
	await wait_physics_frames(2)
	while _hits == 0 and _step < 200:
		_go(car, W_LEFT)
	assert_false(car.model.is_drifting, "ended at the hit")
	_go(car, W_LEFT)
	assert_true(car.model.is_drifting, "still holding W and A: drifting again on the next step")
	for i in 5:
		_go(car, W_LEFT)
		if _hits > 1:
			break
	assert_eq(_paid.size(), 1, "the new drift has not paid yet")


func test_a_drift_that_never_touches_a_wall_pays_when_the_player_ends_it() -> void:
	var car = _car(Vector2(0, 0))
	await wait_physics_frames(2)
	for i in 30:
		_go(car, W_LEFT)
		assert_true(car.model.is_drifting)
	assert_eq(_paid.size(), 0, "nothing paid while it lasts")
	var end_step := _step + 1
	_go(car, W)
	assert_false(car.model.is_drifting)
	assert_eq(_paid.size(), 1, "pays once when the player lets go")
	assert_eq(_paid[0][0], end_step)
	assert_almost_eq(float(_paid[0][1]), 30 * car.model.dt, 1e-6, "for its whole length")
	assert_eq(_hits, 0)
	assert_eq(_cuts, 0)
