class_name PracticeSession
extends Node2D
## A tutorial practice window's live session (task T-561; HUD and menus, Decisions, "Interactive
## tutorial slides"; Game loop architecture, Content, "The practice session"). The tutorial slide
## (T-562) embeds this scene (scenes/run/practice_session.tscn) in a SubViewport: the real car,
## with the real driving, combo and trick signals, on the practice playground, counting one trick
## until it has been done GOAL (3) times. No enemies, kaiju, clock, damage, gift packs, weapons,
## sounds or HUD, only the real mission notebook (MissionPage) in the window with the goal, and,
## for the grind, the real power-up gift overlay (PowerUpScreen) offering Jump.
##
## The API the slide uses:
## - setup(trick): one of TRICKS ("drift", "alt_drift", "air_spin", "grind"); starts the practice
##   over for that trick (count 0, car at its start point, the gift ready for the grind).
## - start() / pause() / is_running(): the session runs only between start() and pause() (and
##   never while its gift is open). It starts paused, so a slide that isn't showing costs nothing.
##   It pauses itself only (its World node), never the tree, so the slide keeps working.
## - restart(): the same trick from the start again; reset_car(): only the car back to its start
##   point (the count stays). R does reset_car() while the window has focus (RESET_KEY).
## - set_focused(on): the car reads the keyboard only while its window has focus (the car's
##   input_enabled); without focus it coasts, as with no key held. Off at first.
## - take_gift(): takes the highlighted card of the open gift (the overlay's own keys and click
##   work too, when the window gets the input).
## - Signals: trick_counted(trick_id, done) for each success (trick_id is the car's own trick id,
##   for example "air_three_sixty"), progress(done, goal), completed() on the third success,
##   car_reset(), gift_opened(), gift_taken(id).
##
## What counts (proposals for the playtest): a trick counts when it pays, the moment the combo
## hears it (RunState.combo_trick), so it is exactly what the player sees pop up:
## - drift: LONG DRIFT! ("extended_drift"), which the trick detector pays for one unbroken drift of
##   combo.json's drift_pay.min_seconds (1 s) or more, when the drift ends;
## - alt drift: ALT DRIFT! ("alternate_drift");
## - air spin: AIR 180! or AIR 360! ("air_one_eighty", "air_three_sixty"); one landing counts
##   once, also a 540 that pays both;
## - grind: GRIND! ("rail_grind"), a grind long enough to pay (combo.json rail_grind.min_seconds).
## Nothing else counts. After the third success the count stays at 3 and the car can go on driving.
##
## The car resets to its start point when it leaves the playground (the map's rectangle and
## AREA_MARGIN; the map's hard edges normally keep it in) or on R.
##
## SEAMS for the tickets built alongside (T-561's result notes):
## - PLAYGROUND_PATH: the level file. Until T-560's practice playground is in, a stand-in,
##   data/level/practice_stand_in.json. The start point of each trick is the level's
##   "practice_starts" entry for it ({x, y, heading} like "spawn"), else the level's spawn.
##   A level with no painted "ground" gets the drift prototype's grid ground (ground_grid.gd).
## - The notebook's goal lines are T-559's (GOAL_TEXT_KEYS, data/tutorial_text.json tutorial.goal.*).

const MapScene := preload("res://scenes/level/mvp_map.tscn")
const MapScript := preload("res://scripts/level/mvp_map.gd")
const CarScript := preload("res://scripts/driving/car.gd")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const CarShadowScript := preload("res://scripts/driving/car_shadow.gd")
const RunStateScript := preload("res://scripts/run/run_state.gd")
const TrickPopupsScript := preload("res://scripts/hud/trick_popups.gd")
const DriftMarksScene := preload("res://scenes/driving/drift_marks.tscn")
const DriftSmokeScene := preload("res://scenes/driving/drift_smoke.tscn")
const BoostEffectScript := preload("res://scripts/driving/boost_effect.gd")
const FacingArrowScript := preload("res://scripts/driving/facing_arrow.gd")
const JumpEffectScript := preload("res://scripts/driving/jump_effect.gd")
const CameraFollowScript := preload("res://scripts/driving/camera_follow.gd")
const GroundGridScript := preload("res://scripts/driving/ground_grid.gd")
const ElevationLayerScript := preload("res://scripts/level/elevation_layer.gd")
const RailsScript := preload("res://scripts/level/rails.gd")
const RailDrawingScript := preload("res://scripts/level/rail_drawing.gd")
const RailSparksScript := preload("res://scripts/driving/rail_sparks.gd")
const PowerUpScreenScript := preload("res://scripts/ui/power_up_screen.gd")
const PracticeOffersScript := preload("res://scripts/run/practice_offers.gd")

## SEAM (T-560): the practice playground's level file.
const PLAYGROUND_PATH := "res://data/level/practice_stand_in.json"
const TEXTS_PATH := "res://data/tutorial_text.json"

## The tricks a practice can count, as the slides name them.
const TRICKS := ["drift", "alt_drift", "air_spin", "grind"]
## The car's trick ids (RunState.combo_trick) that count for each.
const COUNTED := {
	"drift": ["extended_drift"],
	"alt_drift": ["alternate_drift"],
	"air_spin": ["air_one_eighty", "air_three_sixty"],
	"grind": ["rail_grind"],
}
## The notebook goal's trick id for each (RunMissions; the trick's own id where there is one).
const GOAL_TRICK := {
	"drift": "extended_drift",
	"alt_drift": "alternate_drift",
	"air_spin": "air_spin",
	"grind": "rail_grind",
}
## Where each goal line's text is in tutorial_text.json (T-559's keys, tutorial.goal.*): a
## template with {done} and {total}. No text lives in code.
const GOAL_TEXT_KEYS := {
	"drift": ["tutorial", "goal", "drift"],
	"alt_drift": ["tutorial", "goal", "altdrift"],
	"air_spin": ["tutorial", "goal", "airspin"],
	"grind": ["tutorial", "goal", "grind"],
}
## How many successes the goal asks (HUD and menus, Decisions, "Interactive tutorial slides").
const GOAL := 3
## The power-up gift a practice opens with (the grind's Jump).
const GIFT := {"grind": "jump"}
## The key that puts the car back at its start point while the window has focus (a proposal).
const RESET_KEY := KEY_R
## How far past the playground's rectangle the car may go before it is put back (units).
const AREA_MARGIN := 2.0
## The camera's zoom (Unity's orthographic size): the run's (run.gd ZOOM), so the window frames
## the car as the game does at the window's own height.
const ZOOM := 14.4
## The notebook's layout page, scaled to the window as UiScale scales a screen: 70% of the HUD's
## (UiScale.BASE), so the page is drawn about 1.4 times the run's size for the window, to read in a
## small window (a proposal: at the HUD's own size, in a 704 x 440 window, its line was tiny).
const NOTEBOOK_BASE := Vector2(806.4, 453.6)
## Where the notebook page sits on that layout page: the top left corner (a proposal; the run's
## HUD has it lower, under the weapon icons).
const NOTEBOOK_POS := Vector2(12, 12)
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const PX := 16.0

signal trick_counted(trick_id: String, done: int)
signal progress(done: int, goal: int)
signal completed
signal car_reset
signal gift_opened
signal gift_taken(id: String)

## The trick this practice counts (one of TRICKS).
var trick := "drift"
## The level file; set before the session enters the tree to use another.
var layout_path := PLAYGROUND_PATH
## Successes so far (0 to GOAL).
var successes := 0
## Whether the window has focus (the car reads the keyboard).
var focused := false

## Everything that moves, paused as one (process_mode).
var world: Node2D
var ground: Node2D
var map: Node2D
var elevation = null
var physics_world: Node2D
var car: CharacterBody2D
var view_root: Node2D
var car_sprite: Sprite2D
var shadow: Node2D
var drift_marks: Node2D
var drift_smoke: Node2D
var boost_effect: Node2D
var jump_effect: Node2D
var facing_arrow: Node2D
var rail_sparks: Node2D
var rail_drawing: Node2D
var rails: Array = []
var trick_popups: Node2D
var camera: Camera2D
var camera_follow = CameraFollowScript.new()
## The run's state, for the combo (and the power-ups): its clock never runs (no time, no end).
var state: RunState
## The notebook's tracker: one mission, one goal, the trick GOAL times.
var missions: RunMissions
var notebook_layer: CanvasLayer
var notebook: MissionPage
var offers: PracticeOffers
var gift_screen: PowerUpScreen

var _paused := true
var _gift_paused := false
var _gift_pending := false
## Counts the car's steps, so the two air spins of one landing count once.
var _steps := 0
var _air_counted_step := -1
var _built := false


func _ready() -> void:
	_build()
	setup(trick)


## Sets the trick to count (one of TRICKS) and starts the practice over. Unknown names are refused.
func setup(trick_name: String) -> void:
	if not TRICKS.has(trick_name):
		push_error("PracticeSession: unknown trick '%s'" % trick_name)
		return
	trick = trick_name
	if _built:
		restart()


## The same trick from the start: count 0, the combo and power-ups fresh, the car at its start
## point, the gift ready to open again (the grind). Keeps the session paused or running.
func restart() -> void:
	successes = 0
	_air_counted_step = -1
	if offers.is_showing():
		offers.current_offers = []
		gift_screen.close()
		_set_gift_paused(false)
	state.start_run()
	missions.start_with([[{"trick": GOAL_TRICK[trick], "kind": RunMissions.KIND_COUNT, "amount": GOAL}]])
	notebook.goal_templates = {GOAL_TRICK[trick]: goal_template(trick)}
	notebook.show_current()
	reset_car(false)
	_gift_pending = GIFT.has(trick)
	if not _paused:
		_open_gift_if_pending()
	progress.emit(successes, GOAL)


## Runs the practice (and opens the grind's gift the first time).
func start() -> void:
	_paused = false
	_apply_pause()
	_open_gift_if_pending()


## Stops everything in the window where it is (the slide isn't showing).
func pause() -> void:
	_paused = true
	_apply_pause()


## True while the car drives: started, and no gift on show.
func is_running() -> bool:
	return not _paused and not _gift_paused


func is_completed() -> bool:
	return successes >= GOAL


## The car reads the keyboard only while the window has focus.
func set_focused(on: bool) -> void:
	focused = on
	if car != null:
		car.input_enabled = on


func is_gift_open() -> bool:
	return offers != null and offers.is_showing()


## Takes the highlighted card of the open gift (nothing while it builds up or when none is open).
func take_gift() -> void:
	if is_gift_open():
		gift_screen.take_highlighted()


## The start point of `trick_name` on the level: {"position": units, "rotation": radians}. The
## level's practice_starts entry, else its spawn.
func start_point(trick_name: String = "") -> Dictionary:
	var t := trick_name if trick_name != "" else trick
	var starts = map.layout.get("practice_starts", {})
	var s = starts.get(t) if starts is Dictionary else null
	if s is Dictionary and s.has("x") and s.has("y"):
		return {"position": Vector2(float(s.x), float(s.y)),
			"rotation": deg_to_rad(float(s.get("heading", LevelSpawn.DEFAULT_HEADING)))}
	return {"position": LevelSpawn.position_of(map.layout), "rotation": LevelSpawn.rotation_of(map.layout)}


## The notebook's goal line for `trick_name`: T-559's text in tutorial_text.json (an error and ""
## when it is missing).
static func goal_template(trick_name: String) -> String:
	var node: Variant = _texts()
	for part in GOAL_TEXT_KEYS.get(trick_name, []):
		node = node.get(part) if node is Dictionary else null
	if node is String and node != "":
		return node
	push_error("PracticeSession: no goal line for '%s' in %s" % [trick_name, TEXTS_PATH])
	return ""


static func _texts() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(TEXTS_PATH))
	return parsed if parsed is Dictionary else {}


## Puts the car back at the trick's start point, standing still (a new car: no drift, grind or
## jump in progress). The count stays. Sends car_reset when `announce`.
func reset_car(announce := true) -> void:
	_build_car()
	if announce:
		car_reset.emit()


func _unhandled_input(event: InputEvent) -> void:
	if focused and event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == RESET_KEY:
		reset_car()
		get_viewport().set_input_as_handled()


# ---- Building --------------------------------------------------------------------------------

func _build() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)

	map = MapScene.instantiate()
	map.name = "Map"
	map.challenges_enabled = false
	map.alert_signs_enabled = false
	map.layout_path = layout_path
	world.add_child(map)
	map.set_view("iso")
	elevation = ElevationLayerScript.new()
	elevation.name = "Elevation"
	map.add_child(elevation)
	elevation.setup(map, layout_path)
	if not map.layout.has("ground"):
		# No painted ground: the drift prototype's grid (the stand-in; T-560 may paint its own).
		map.ground_draw.visible = false
		map.ground_tiles.visible = false
		ground = GroundGridScript.new()
		ground.name = "Ground"
		ground.px_per_unit = PX
		ground.transform = ISO_TRANSFORM
		ground.z_index = -1000
		world.add_child(ground)
		world.move_child(ground, 0)
		var edge := _Edge.new()
		edge.rect = MapScript.rect_of(map.layout.map.rect)
		ground.add_child(edge)

	drift_marks = DriftMarksScene.instantiate()
	drift_marks.name = "DriftMarks"
	map.view_root.add_child(drift_marks)
	map.view_root.move_child(drift_marks, map.ground_tiles.get_index() + 1)
	var layer: Node2D = elevation
	drift_marks.view_basis = ISO_TRANSFORM
	drift_marks.height_at = func(units: Vector2) -> float: return layer.ground_height.height_at(units)
	drift_marks.depth_for = func(units: Vector2, rot: float, height: float) -> int:
		return layer.z_for(units, rot, height) - 1

	rails = RailsScript.from_layout(map.layout)
	if not rails.is_empty():
		rail_drawing = RailDrawingScript.new()
		rail_drawing.build(map, rails,
			func(units: Vector2) -> float: return layer.ground_height.height_at(units),
			func(units: Vector2, rot: float, h: float) -> int: return layer.z_for(units, rot, h))

	physics_world = Node2D.new()
	physics_world.name = "PhysicsWorld"
	physics_world.visible = false
	world.add_child(physics_world)

	shadow = CarShadowScript.new()
	shadow.name = "CarShadow"
	shadow.view_basis = ISO_TRANSFORM
	world.add_child(shadow)

	view_root = Node2D.new()
	view_root.name = "View"
	world.add_child(view_root)
	car_sprite = CarSpriteScript.new()
	car_sprite.name = "CarSprite"
	car_sprite.world_px_per_unit = PX
	view_root.add_child(car_sprite)
	car_sprite.use_sheet("iso")
	drift_smoke = DriftSmokeScene.instantiate()
	drift_smoke.name = "DriftSmoke"
	drift_smoke.view_transform = ISO_TRANSFORM
	view_root.add_child(drift_smoke)
	view_root.move_child(drift_smoke, car_sprite.get_index())
	boost_effect = BoostEffectScript.new()
	boost_effect.name = "BoostEffect"
	boost_effect.view_transform = ISO_TRANSFORM
	view_root.add_child(boost_effect)
	view_root.move_child(boost_effect, car_sprite.get_index())
	jump_effect = JumpEffectScript.new()
	jump_effect.view_transform = ISO_TRANSFORM
	view_root.add_child(jump_effect)
	rail_sparks = RailSparksScript.new()
	rail_sparks.name = "RailSparks"
	view_root.add_child(rail_sparks)
	facing_arrow = FacingArrowScript.new()
	facing_arrow.view_transform = ISO_TRANSFORM
	view_root.add_child(facing_arrow)
	trick_popups = TrickPopupsScript.new()
	trick_popups.name = "TrickPopups"
	view_root.add_child(trick_popups)
	camera = Camera2D.new()
	camera.name = "Camera"
	camera.ignore_rotation = true
	camera.position_smoothing_enabled = false
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	view_root.add_child(camera)
	camera.make_current()
	camera_follow.base_size = ZOOM
	camera_follow.size = ZOOM
	get_viewport().size_changed.connect(_apply_zoom)

	# The run's state for the combo and the power-ups. Its clock never runs: no time, no end.
	state = RunStateScript.new()
	state.name = "RunState"
	state.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(state)
	state.crashed.connect(func() -> void:
		if car != null and is_instance_valid(car):
			car.settle_tricks())
	state.combo_trick.connect(_on_combo_trick)
	state.power_ups_changed.connect(_apply_power_ups)
	trick_popups.bind_score(state, func() -> Vector2: return car_sprite.position)
	trick_popups.bind_combo(state, func() -> Vector2: return car_sprite.position)

	# The notebook: the real mission page, its own one-goal tracker.
	missions = RunMissions.new()
	notebook_layer = CanvasLayer.new()
	notebook_layer.name = "Notebook"
	notebook_layer.layer = 10
	add_child(notebook_layer)
	var root := Control.new()
	root.name = "NotebookRoot"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notebook_layer.add_child(root)
	UiScale.keep(root, NOTEBOOK_BASE)
	notebook = MissionPage.new()
	root.add_child(notebook)
	notebook.position = NOTEBOOK_POS
	notebook.bind(missions)
	state.combo_changed.connect(drift_marks.set_multiplier)  # hype marks (T-249), as in the run

	# The gift: the real overlay, pausing only this session.
	offers = PracticeOffersScript.new()
	offers.name = "PracticeOffers"
	add_child(offers)
	offers.bind(state)
	offers.pause_with = _set_gift_paused
	offers.offer_taken.connect(func(id: String) -> void: gift_taken.emit(id))
	gift_screen = PowerUpScreenScript.new()
	gift_screen.name = "GiftScreen"
	add_child(gift_screen)
	gift_screen.setup(offers)

	_built = true
	_apply_pause()


## A new car at the trick's start point, with every effect bound to it.
func _build_car() -> void:
	if car != null and is_instance_valid(car):
		physics_world.remove_child(car)
		car.queue_free()
	var start := start_point()
	car = CarScript.new()
	car.name = "Car"
	car.model.x = start.position.x
	car.model.y = start.position.y
	car.model.rotation = start.rotation
	physics_world.add_child(car)
	car.ground = elevation.ground_height
	car.input_enabled = focused
	car.grind.rails = rails
	car.grind.grind_ended.connect(func(_reason: String, seconds: float, _length: float) -> void:
		state.add_grind_trick(seconds))
	car.trick.connect(func(trick_id: String) -> void: state.add_trick(trick_id, car.tricks.last_trick_seconds))
	car.airtime_trick.connect(state.add_airtime_trick)
	car.hit_obstacle.connect(func(_c: Object, _s: int, _n: Vector2, _v: float) -> void: state.collision())
	car.stepped.connect(_on_car_stepped)
	var the_map: Node2D = map
	var the_car = car
	car.floor_query = func() -> float: return the_map.obstacle_floor(the_car, the_car.height, the_car.vertical_speed)
	map.car = car
	drift_marks.bind(car)
	drift_marks.set_multiplier(state.combo)
	drift_smoke.clear()
	drift_smoke.bind(car, drift_marks)
	boost_effect.clear()
	boost_effect.bind(car)
	jump_effect.bind(car)
	facing_arrow.bind(car)
	trick_popups.bind(car, func() -> Vector2: return car_sprite.position)
	_apply_power_ups()
	_sync_view(true)
	car_sprite.reset_physics_interpolation()
	shadow.reset_physics_interpolation()
	camera.reset_physics_interpolation()


# ---- Running ---------------------------------------------------------------------------------

## A trick paid into the combo: one more success when it is this practice's trick.
func _on_combo_trick(trick_id: String, _added: float, _multiplier: float) -> void:
	if is_completed() or not COUNTED[trick].has(trick_id):
		return
	if trick == "air_spin":
		if _air_counted_step == _steps:
			return  # the other spin of the same landing (a 540)
		_air_counted_step = _steps
	successes += 1
	missions.on_trick(GOAL_TRICK[trick])
	trick_counted.emit(trick_id, successes)
	progress.emit(successes, GOAL)
	if is_completed():
		completed.emit()


## After each of the car's physics steps: the drawing, the combo's hype speed, the rails and
## the playground's edge.
func _on_car_stepped() -> void:
	_steps += 1
	var dt: float = car.model.dt
	map.update_car_obstacles(car, car.height, car.vertical_speed)
	state.drift_step(car.model.is_drifting, dt)
	car.tuning.hype_speed_bonus = state.eased_hype_speed(car.tuning.hype_speed_bonus, dt)
	rail_sparks.step(car, dt)
	if rail_drawing != null:
		rail_drawing.update_for_car(car.model.get_position(), car.height, view_root.z_index)
	_sync_view(false)
	if not in_area(car.model.get_position()):
		reset_car.call_deferred()


## True when `units` is on the playground (its map rectangle grown by AREA_MARGIN).
func in_area(units: Vector2) -> bool:
	return MapScript.rect_of(map.layout.map.rect).grow(AREA_MARGIN).has_point(units)


## The drawn car, its shadow and the camera on the car's place (run.gd's elevation view).
func _sync_view(snap_camera: bool) -> void:
	var units: Vector2 = car.model.get_position()
	var at_ground := ISO_TRANSFORM * (units * PX)
	var ground_h: float = elevation.ground_height.height_at(units)
	car_sprite.place(at_ground, car.height)
	car_sprite.set_in_air(CarSpriteScript.is_in_air(car.height, ground_h))
	car_sprite.set_heading(car.rotation)
	car_sprite.set_tilt_step(car.tilt.step)
	shadow.place(units, ground_h, car.height)
	var lift: Vector2 = CarSpriteScript.lift_for_height(ground_h, PX)
	drift_smoke.position = lift
	boost_effect.position = lift
	view_root.z_index = elevation.z_for(units, car.rotation, car.height)
	shadow.z_index = elevation.shadow_z_for(units, car.rotation, car.height, ground_h)
	elevation.update_see_through(units, car.rotation, car.height, car.model.dt)
	if ground != null:
		ground.follow(units * PX)
	var frac: float = CameraFollowScript.speed_fraction_of(car.model)
	var car_lift: Vector2 = CarSpriteScript.lift_for_height(car.height, PX)
	if snap_camera:
		camera_follow.snap(at_ground, frac, car_lift)
	else:
		camera_follow.step(at_ground, frac, car.model.dt, car_lift)
	camera.position = camera_follow.position
	if snap_camera or camera_follow.dynamic:
		_apply_zoom()


func _apply_zoom() -> void:
	if camera == null or not is_inside_tree():
		return
	var height := get_viewport().get_visible_rect().size.y
	var z: float = height / (2.0 * camera_follow.size * PX)
	camera.zoom = Vector2(z, z)


## The power-ups the state owns, on the car (the grind's Jump).
func _apply_power_ups() -> void:
	if car != null and is_instance_valid(car):
		car.jump.set_tier(state.power_up_tier("jump"))


func _open_gift_if_pending() -> void:
	if _gift_pending and not offers.is_showing():
		_gift_pending = false
		if offers.offer_only(String(GIFT[trick])):
			gift_opened.emit()


func _set_gift_paused(on: bool) -> void:
	_gift_paused = on
	_apply_pause()


func _apply_pause() -> void:
	if world != null:
		world.process_mode = Node.PROCESS_MODE_INHERIT if is_running() else Node.PROCESS_MODE_DISABLED


## The playground's edge, drawn on the grid ground (flat pixels; the ground has the iso transform).
class _Edge extends Node2D:
	var rect := Rect2()

	func _draw() -> void:
		draw_rect(Rect2(rect.position * 16.0, rect.size * 16.0), Color(0.85, 0.35, 0.65), false, 3.0)
