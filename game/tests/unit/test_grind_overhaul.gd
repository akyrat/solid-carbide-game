extends GutTest
## Task T-551, the grind overhaul (Drifting, Decisions, "The grind overhaul", "Jump has no
## cooldown", "A jump effect around the car"; HUD and menus, Decisions, "The jump arrow"): the tilt
## while Space is held in the air (3 frames in, the same backwards out), the jump effect played on
## a jump (the equipped one, the dash cloud by default), the facing arrow while grinding with the
## setting on, and the drawing's tilt hook. The grind itself (start, hold, launch): test_rail_grind.gd.

const CarScript := preload("res://scripts/driving/car.gd")
const Rails := preload("res://scripts/level/rails.gd")
const CarTilt := preload("res://scripts/driving/car_tilt.gd")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const JumpEffectScript := preload("res://scripts/driving/jump_effect.gd")
const JumpEffectChoice := preload("res://scripts/driving/jump_effect_choice.gd")
const FacingArrowScript := preload("res://scripts/driving/facing_arrow.gd")

const LAYOUT := {"rails": [{"id": "long", "x1": 0.0, "y1": 0.0, "x2": 200.0, "y2": 0.0, "z1": 1.0, "z2": 1.0}]}
var TEST_PATH := RunPaths.file("test_settings_t551.cfg")
var _world: Node2D


func before_each() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	JumpEffectChoice.override_id = ""
	JumpEffectChoice.provider = Callable()
	_world = Node2D.new()
	add_child_autofree(_world)


func after_each() -> void:
	JumpEffectChoice.override_id = ""
	JumpEffectChoice.provider = Callable()
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()


## A car on a flat street (no ground source), the long rail, Jump at `tier`; at `height` (> 0: in
## the air, falling from there) moving east at 10.
func _car(height := 0.0, tier := 0) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	car.model.set_position(Vector2(2, 0.3) if height > 0.0 else Vector2(2, 10))
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.model.set_velocity(Vector2(10, 0))
	car.grind.rails = Rails.from_layout(LAYOUT)
	car.jump.set_tier(tier)
	if height > 0.0:
		car.height_model.height = height
		car.height_model.leave_rail(0.0)
	return car


## The tilt step after each of `n` steps.
func _steps(car, n: int) -> Array:
	var out: Array = []
	for i in n:
		car.physics_step()
		out.append(car.tilt.step)
	return out


# --- The tilt ---------------------------------------------------------------------------------

func test_the_tilt_frame_time_is_in_the_data() -> void:
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/rail_grind.json"))
	assert_true(json.has("tilt_frame_seconds"))
	assert_almost_eq(CarTilt.new().frame_seconds, float(json.tilt_frame_seconds), 1e-9)
	assert_eq(CarTilt.FRAMES, 3, "a 3-frame transition")


func test_holding_space_in_the_air_tilts_through_three_frames_and_back_on_release() -> void:
	# A high drop over the street, away from the rail, so the car stays in the air throughout.
	var car := _car(8.0)
	car.model.set_position(Vector2(2, 30))
	var per := roundi(car.tilt.frame_seconds / car.model.dt)  # physics steps per frame (3)
	car.scripted_jump_held = true
	var into := _steps(car, 3 * per + 2)
	var want_in: Array = []
	for f in [1, 2, 3]:
		for i in per:
			want_in.append(f)
	want_in.append_array([3, 3])
	assert_eq(into, want_in, "frames 1, 2, 3, each for %d steps, then held" % per)
	assert_true(car.airborne, "all in the air")
	assert_true(car.tilt.is_tilted())
	car.scripted_jump_held = false
	var back := _steps(car, 3 * per + 1)
	var want_out: Array = []
	for f in [2, 1, 0]:
		for i in per:
			want_out.append(f)
	want_out.append(0)
	assert_eq(back, want_out, "the same frames backwards, then the normal car")
	assert_true(car.airborne)


func test_on_the_ground_holding_space_does_not_tilt() -> void:
	var car := _car(0.0)
	car.scripted_jump_held = true
	car.scripted_input = [true, false, 0.0]
	assert_eq(_steps(car, 30).max(), 0, "never tilts on the ground")


func test_a_release_mid_transition_goes_back_from_the_frame_it_is_on() -> void:
	var t = CarTilt.new()
	var dt := 0.02
	t.update(true, dt)
	assert_eq(t.step, 1)
	for i in 3:
		t.update(true, dt)
	assert_eq(t.step, 2)
	t.update(false, dt)
	assert_eq(t.step, 1, "back from 2 to 1 at once")
	for i in 3:
		t.update(false, dt)
	assert_eq(t.step, 0)


func test_landing_while_holding_plays_the_tilt_back_out() -> void:
	# The proposal: on landing the 3 frames play backwards as the car drives off (no snap).
	var car := _car(0.6)
	car.model.set_position(Vector2(2, 30))
	car.scripted_jump_held = true
	var guard := 0
	while car.airborne and guard < 200:
		car.physics_step()
		guard += 1
	assert_false(car.airborne, "landed")
	var at_landing: int = car.tilt.step
	assert_gt(at_landing, 0, "it was tilted in the air")
	var after := _steps(car, 12)
	assert_eq(after[after.size() - 1], 0, "back to the normal car on the ground, Space still held")
	for i in range(1, after.size()):
		assert_true(after[i] <= after[i - 1], "only ever going back")


func test_the_car_stays_tilted_while_grinding_and_can_still_spin() -> void:
	var car := _car(1.6)
	car.scripted_jump_held = true
	var guard := 0
	while not car.grind.active and guard < 100:
		car.physics_step()
		guard += 1
	assert_true(car.grind.active)
	var h0: float = car.model.rotation
	car.scripted_input = [false, false, 1.0]
	_steps(car, 15)
	assert_eq(car.tilt.step, CarTilt.FRAMES, "the held pose on the rail")
	assert_ne(car.model.rotation, h0, "A still spins it")


func test_the_car_can_spin_in_the_air_while_tilted() -> void:
	var car := _car(8.0)
	car.model.set_position(Vector2(2, 30))
	car.scripted_jump_held = true
	_steps(car, 10)
	assert_true(car.tilt.is_tilted())
	var h0: float = car.model.rotation
	car.scripted_input = [false, false, -1.0]
	_steps(car, 10)
	assert_true(car.tilt.is_tilted())
	assert_gt(car.model.rotation, h0 + 0.1, "D spins it, tilted")


# --- The drawing's hook -----------------------------------------------------------------------

func test_the_sprite_hook_takes_the_tilt_step_with_a_placeholder_look() -> void:
	var sprite: Sprite2D = CarSpriteScript.new()
	_world.add_child(sprite)
	sprite.use_sheet("iso")
	sprite.set_heading(0.7)
	var dir_frame: int = sprite.frame
	var base_scale: Vector2 = sprite.scale
	assert_eq(sprite.skew, 0.0)
	if sprite.has_tilt_art:
		pass_test("T-555's art is in: the sheet frames are checked below")
	else:
		sprite.set_tilt_step(3)
		assert_gt(absf(sprite.skew), 0.1, "the placeholder: sheared at the held pose")
		assert_lt(sprite.scale.y, base_scale.y)
		sprite.set_tilt_step(1)
		assert_almost_eq(sprite.skew, CarSpriteScript.TILT_PLACEHOLDER_SKEW / 3.0, 1e-6, "a third at step 1")
		assert_eq(sprite.frame, dir_frame, "the car's own direction frame")
		sprite.set_tilt_step(0)
		assert_eq(sprite.skew, 0.0)
		assert_eq(sprite.scale, base_scale, "back to normal")
	# The tilt sheet's layout (T-555): one row per step, one column per direction.
	assert_eq(CarSpriteScript.tilt_frame_index(5, 1, 32), 5)
	assert_eq(CarSpriteScript.tilt_frame_index(5, 2, 32), 37)
	assert_eq(CarSpriteScript.tilt_frame_index(5, 3, 32), 69)


# --- The jump effect --------------------------------------------------------------------------

func _effect(car) -> Node2D:
	var e: Node2D = JumpEffectScript.new()
	_world.add_child(e)
	e.bind(car)
	return e


func test_a_jump_plays_the_dash_cloud_by_default() -> void:
	assert_eq(JumpEffectChoice.equipped_id(), "dash_cloud", "no saved choice yet: the default")
	var car := _car(0.0, 1)
	var e := _effect(car)
	car.press_jump()
	car.physics_step()
	assert_true(car.airborne)
	assert_eq(e.started, [["dash_cloud", "hop"]])
	assert_true(e.is_playing())
	e.advance(e.seconds + 0.01)
	assert_false(e.is_playing(), "over after jump_effect_seconds")


func test_a_rail_launch_plays_the_equipped_effect() -> void:
	JumpEffectChoice.override_id = "shockwave_ring"
	var car := _car(1.6)
	car.scripted_jump_held = true
	var e := _effect(car)
	var guard := 0
	while not car.grind.active and guard < 100:
		car.physics_step()
		guard += 1
	assert_true(car.grind.active)
	assert_eq(e.started, [], "catching a rail is not a jump")
	car.scripted_jump_held = false
	car.physics_step()
	assert_eq(e.started, [["shockwave_ring", "rail_launch"]])


func test_the_saved_choice_reaches_the_effect_through_the_seam() -> void:
	JumpEffectChoice.provider = func() -> String: return "jet_thrust"
	assert_eq(JumpEffectChoice.equipped_id(), "jet_thrust")
	JumpEffectChoice.provider = func() -> String: return "no_such_effect"
	assert_eq(JumpEffectChoice.equipped_id(), "dash_cloud", "an unknown id falls back to the default")


func test_falling_off_an_edge_or_a_rails_end_plays_no_effect() -> void:
	var car := _car(0.0, 1)
	var e := _effect(car)
	car.height_model.height = 2.0
	car.height_model.leave_rail(0.0)  # as off a drop-off edge
	for i in 30:
		car.physics_step()
	assert_eq(e.started, [])


func test_every_effect_placeholder_draws() -> void:
	var car := _car(0.0, 1)
	var e := _effect(car)
	for id in JumpEffectChoice.IDS:
		e.play(id, "hop", Vector2(2, 10), 0.0, 0.0)
	e.advance(0.1)
	await get_tree().process_frame
	assert_eq(e.playing.size(), JumpEffectChoice.IDS.size(), "all five playing (drawn without errors)")


# --- The facing arrow -------------------------------------------------------------------------

func test_the_arrow_setting_is_on_by_default_and_saved() -> void:
	assert_true(GameSettings.load_jump_arrow_enabled(), "on by default (the proposal)")
	GameSettings.save_jump_arrow_enabled(false)
	assert_false(GameSettings.load_jump_arrow_enabled())
	GameSettings.save_jump_arrow_enabled(true)
	assert_true(GameSettings.load_jump_arrow_enabled())


func test_the_arrow_shows_while_grinding_only_when_the_setting_is_on() -> void:
	var car := _car(3.0)
	car.scripted_jump_held = true
	var arrow: Node2D = FacingArrowScript.new()
	_world.add_child(arrow)
	arrow.bind(car)
	assert_true(arrow.enabled)
	car.physics_step()
	assert_false(arrow.showing, "in the air, not grinding: no arrow")
	var guard := 0
	while not car.grind.active and guard < 100:
		car.physics_step()
		guard += 1
	assert_true(car.grind.active)
	assert_true(arrow.showing, "grinding, setting on: shown")
	GameSettings.save_jump_arrow_enabled(false)  # the pause screen's checkbox (T-553) saves this
	assert_false(arrow.showing, "switched off at once")
	car.physics_step()
	assert_false(arrow.showing, "and stays off while grinding")
	GameSettings.save_jump_arrow_enabled(true)
	assert_true(arrow.showing)
	car.scripted_jump_held = false
	car.physics_step()
	assert_false(car.grind.active)
	assert_false(arrow.showing, "gone once off the rail")


func test_the_arrow_points_where_the_car_faces() -> void:
	var arrow: Node2D = FacingArrowScript.new()
	_world.add_child(arrow)
	var pts: PackedVector2Array = arrow.points_units(Vector2(5, 5), PI)  # facing west
	var tip: Vector2 = pts[0]
	assert_lt(tip.x, 5.0 - float(arrow.config.arrow_distance), "past the nose, to the west")
	assert_almost_eq(tip.y, 5.0, 1e-6)
	assert_almost_eq((pts[1] + pts[2]).x * 0.5, 5.0 - float(arrow.config.arrow_distance), 1e-6, "its base")
