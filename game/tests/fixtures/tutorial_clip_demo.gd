extends Node
## Tutorial clip fixture (task T-483; HUD and menus, Decisions, "The tutorial
## slides are redrawn, with clips of the real car"): the real car on a plain
## background, driven by a script of inputs, for the tutorial slides' four
## GIFs. Nothing else is on screen: no HUD, popups, enemies or city.
##
## clip (set in the clip's scene, tutorial_clip_<name>.tscn):
## - "drift": the drift prototype's plain grid, zoomed out, the camera held
##   still, the car driving straight, then W + A so it breaks into a drift (its
##   tyre marks and smoke trace the path), then out of frame.
## - "long_drift": one long unbroken drift, the camera following.
## - "alt_drift": a forward drift (W + A), then a backward one (S + A, W released
##   and S pressed with the steering kept), which the ALT DRIFT! trick counts.
## - "ramp_jump": the elevation test's ramp up to a short rooftop (tutorial_ramp_scene.gd,
##   a copy of the elevation test scene reading tests/fixtures/data/tutorial_ramp.json): the car
##   takes the ramp at speed, flies over the rooftop, spins in the air (W + A held) and lands on the street.
##
## Record with game/tools/record_tutorial_clips.py (it runs Godot's movie maker
## with one physics step per frame, then crops 480 x 320 and makes the GIFs). When the
## script is done the scene quits. The detected tricks are printed as
## "tutorial_clip_demo: trick ..." lines so the recorder can check them.

@export var clip := "drift"
## Camera size (Unity's orthographic size: half the visible height in units).
@export var zoom := 14.4
## Where the car starts (flat units, x east, y south) and its heading (radians).
@export var start_units := Vector2.ZERO
@export var start_rotation := 0.0
## Steps driven (W held) before the first frame, so the car is at speed.
@export var warm_steps := 0
## Speed the car starts with along its heading (units/s; 0 = at rest, W then brings it to cruise).
@export var start_speed := 0.0
## When true the camera holds still at camera_units (flat units) instead of following.
@export var fixed_camera := false
@export var camera_units := Vector2.ZERO
## Seconds the drift marks stay fully visible before fading (the scene's is 6).
@export var ground_color := Color(0.55, 0.57, 0.62)
@export var minor_color := Color(0.60, 0.62, 0.67)
@export var major_color := Color(0.66, 0.68, 0.74)
@export var marks_lifetime := 6.0
## Steps after the last part before the scene quits.
@export var tail_steps := 0
## ramp clips: the ground file (empty: the scene's own, tutorial_ramp.json).
@export var ramp_data := ""

## [steps, W, steer, S]. A = +1, D = -1; S (optional 4th entry) is the reverse key.
## A part with the 4th entry "aim", then x and y (units), steers toward that point.
## A part with the 4th entry "heading", then a target heading and a lead (radians), holds
## its steer until the heading is within the lead of the target (or its steps run out).
## A part with the 4th entry "air" and a 5th, the steer to hold in the air, runs
## W held until the car has taken off and landed (at least `steps` steps).
@export var parts: Array = []

var scene: Node2D
var car: CharacterBody2D
var _part := -1
var _left := 0
var _frames := 0
var _air_steps := 0
var _turned := 0.0
var _was_air := false
var _airtime := 0.0
var _tail := -1
var _rot_before := 0.0
var _camera_px := Vector2.ZERO
var _needle: ThreadTheNeedle
## thread_the_needle: the two boulders' centres (units) and their diameter.
@export var needle_boulders: Array[Vector2] = []
@export var needle_diameter := 3.0
## The key timeline (T-490): per physics step, which of W, A, S, D the script held ("" for none);
## printed once at the end as "keys ..." for the recorder.
var _keys: Array[String] = []


func _ready() -> void:
	if _is_ramp():
		scene = preload("res://tests/fixtures/tutorial_ramp_scene.gd").new()
		if ramp_data != "":
			scene.data_path = ramp_data
		add_child(scene)
		scene.place_car(start_units, start_rotation)
		scene.camera_follow.dynamic = false
		scene.camera_follow.set_base_size(zoom)
		scene.sync_view()
	else:
		scene = preload("res://scenes/drift_prototype/drift_prototype.tscn").instantiate()
		add_child(scene)
		scene.set_view("iso")
		scene.panel.visible = false
		scene.hint.visible = false
		scene.trick_popups.visible = false
		# The test room's walls and boulder: gone (drawing and bodies), so the plain grid is all there is.
		scene.test_room.walls_body.free()
		scene.test_room.boulder_body.free()
		scene.test_room.free()
		scene.camera_follow.dynamic = false
		scene.set_zoom(zoom)
		scene.drift_marks.lifetime = marks_lifetime
		scene.car.model.set_position(start_units)
		scene.car.model.rotation = start_rotation
		scene.car._sync_from_model()
	if clip == "thread_the_needle":
		_build_needle()
	# A lighter plain ground (the grid's own colours are dark navy, where the dark tyre marks do not read);
	# the grid's origin dot takes the ground's colour. Drawing only.
	scene.ground.ground_color = ground_color
	scene.ground.minor_color = minor_color
	scene.ground.major_color = major_color
	scene.ground.origin_color = ground_color
	car = scene.car
	car.use_keyboard = false
	car.detect_tricks = true
	car.trick.connect(func(id: String) -> void:
		print("tutorial_clip_demo: trick %s at step %d" % [id, _frames]))
	car.height_model.took_off.connect(func(from_ramp: bool, vz: float) -> void:
		print("tutorial_clip_demo: takeoff %s at step %d at %s, vertical speed %.2f, flat speed %.1f" % [
			"off the ramp's top" if from_ramp else "off an edge", _frames, car.model.get_position(), vz, car.model.get_velocity().length()]))
	car.airtime_trick.connect(func(seconds: float) -> void:
		_airtime = seconds
		print("tutorial_clip_demo: airtime %.2f s (HANG TIME! pays from %.2f s)" % [seconds, car.tricks.airtime_min_seconds]))
	if fixed_camera:
		_camera_px = _drawn(camera_units)
	if start_speed > 0.0:
		car.model.set_velocity(Vector2.from_angle(start_rotation) * start_speed)
	# Warm-up: the car already at speed on the first frame.
	car.scripted_input = [true, false, 0.0]
	for i in warm_steps:
		car.physics_step()
	_fix_camera()
	scene.sync_view()
	_fix_camera()
	_reset_interp()
	_frames = 0
	car.stepped.connect(_on_stepped)
	_next_part()


## thread_the_needle: two paired boulders on the plain grid (script-drawn like the test room's), a gap
## between them; the real ThreadTheNeedle (thread_the_needle.gd) watches the car's line across the gap.
func _build_needle() -> void:
	var layout := {"pattern_copies": [], "pairs": [{"id": "pair-1", "a": "boulder-1", "b": "boulder-2"}]}
	var u := 16.0
	var body := StaticBody2D.new()
	body.name = "NeedleBoulders"
	body.collision_layer = scene.CarScript.LAYER_OBSTACLES
	body.collision_mask = 0
	scene.physics_world.add_child(body)
	var drawing := Node2D.new()
	drawing.set_script(preload("res://tests/fixtures/tutorial_needle_drawing.gd"))
	drawing.transform = scene.view_transform()
	scene.view_root.add_child(drawing)
	var i := 0
	for c in needle_boulders:
		i += 1
		layout.pattern_copies.append({"id": "boulder-%d" % i, "boulders": [{"x": c.x, "y": c.y, "diameter": needle_diameter}]})
		var cs := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = needle_diameter / 2.0 * u
		cs.shape = circle
		cs.position = c * u
		body.add_child(cs)
		drawing.circles.append([c * u, needle_diameter / 2.0 * u])
	drawing.queue_redraw()
	_needle = ThreadTheNeedle.new(layout, ComboData.new().needle_rules())
	_needle.threaded.connect(func(_id: String) -> void:
		print("tutorial_clip_demo: trick thread_the_needle at step %d" % _frames))


func _is_ramp() -> bool:
	return clip in ["ramp_jump", "airtime", "air_three_sixty"]


func _drawn(units: Vector2) -> Vector2:
	var px: Vector2 = units * 16.0
	return scene.ISO_TRANSFORM * px if _is_ramp() else scene.view_transform() * px


func _fix_camera() -> void:
	if fixed_camera:
		scene.camera.position = _camera_px


func _reset_interp() -> void:
	scene.camera.reset_physics_interpolation()
	if _is_ramp():
		scene.car_sprite.reset_physics_interpolation()
		scene.shadow.reset_physics_interpolation()
	else:
		scene.car_sprite.reset_physics_interpolation()


func _next_part() -> void:
	_part += 1
	if _part >= parts.size():
		_tail = tail_steps
		car.scripted_input = [true, false, 0.0]
		return
	var p: Array = parts[_part]
	_left = p[0]
	car.scripted_input = [p[1], p.size() > 3 and p[3] is bool and p[3], p[2]]
	print("tutorial_clip_demo: part %d at step %d: %s, at %s heading %.0f deg" % [
		_part, _frames, str(p), car.model.get_position(), rad_to_deg(car.model.rotation)])


func _keys_now() -> String:
	var inp: Array = car.scripted_input
	var k := ""
	if inp[0]:
		k += "W"
	if float(inp[2]) > 0.3:
		k += "A"
	if inp[1]:
		k += "S"
	if float(inp[2]) < -0.3:
		k += "D"
	return k


func _quit() -> void:
	print("tutorial_clip_demo: keys " + ",".join(_keys))
	get_tree().quit()


func _on_stepped() -> void:
	_keys.append(_keys_now())
	if _needle != null:
		_needle.touching(car.held_contacts())
		_needle.observe(car.model.get_position(), car.airborne, car.model.dt)
	_frames += 1
	_fix_camera()
	if car.airborne:
		_air_steps += 1
		_turned += wrapf(car.model.rotation - _rot_before, -PI, PI)
	_rot_before = car.model.rotation
	if _was_air and not car.airborne:
		print("tutorial_clip_demo: landed at step %d after %d air steps (%.2f s), turned %.0f degrees" % [
			_frames, _air_steps, _air_steps * car.model.dt, rad_to_deg(absf(_turned))])
	_was_air = car.airborne
	if _frames % 5 == 0:
		print("tutorial_clip_demo: step %d at %s height %.2f speed %.1f heading %.0f" % [_frames, car.model.get_position(), car.height, car.model.get_velocity().length(), rad_to_deg(car.model.rotation)])
	if _tail >= 0:
		_tail -= 1
		if _tail <= 0:
			_quit()
		return
	var p: Array = parts[_part]
	# An "aim" part: W held, steering toward the point (4th entry "aim", then x and y in units) until the car
	# is within 1.5 units of it or past it along its line; for the run-up to the ramp.
	if p.size() > 5 and p[3] is String and p[3] == "aim":
		var target := Vector2(float(p[4]), float(p[5]))
		var pos: Vector2 = car.model.get_position()
		var err := wrapf((target - pos).angle() - car.model.rotation, -PI, PI)
		car.scripted_input = [true, false, clampf(-err * 2.5, -1.0, 1.0)]
		_left -= 1
		if pos.distance_to(target) < 1.5 or _left <= 0:
			_next_part()
		return
	# A "heading" part: the steer is held until the heading is within the 6th entry (a margin, radians) of the 5th (a target heading).
	if p.size() > 5 and p[3] is String and p[3] == "heading":
		_left -= 1
		if p.size() > 6 and int(p[0]) - _left < int(p[6]):
			return
		var err := absf(wrapf(car.model.rotation - float(p[4]), -PI, PI))
		if err < float(p[5]) or _left <= 0:
			_next_part()
		return
	# An "air" part: W + steer from takeoff to landing, then done.
	if p.size() > 3 and p[3] is String and p[3] == "air":
		if car.airborne:
			car.scripted_input = [true, false, p[4]]
		_left -= 1
		if _air_steps > 0 and _left <= 0 and not car.airborne:
			_next_part()
		return
	_left -= 1
	if _left <= 0:
		_next_part()
