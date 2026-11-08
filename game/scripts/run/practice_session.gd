class_name PracticeSession
extends Node2D
## A tutorial practice window's live session (task T-561; HUD and menus, Decisions, "Interactive
## tutorial slides"; Game loop architecture, Content, "The practice session"). The tutorial slide
## (T-562) embeds this scene (scenes/run/practice_session.tscn) in a SubViewport: the real car,
## with the real driving, combo and trick signals, on the practice playground, counting one trick
## until it has been done GOAL (3) times (the drift: DRIFT_SECONDS, 3 seconds of drifting in total,
## T-565). No enemies, kaiju, clock, damage, gift packs, weapons,
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
##   car_reset(), gift_opened(), gift_taken(id). The drift sends seconds_progress(done, goal)
##   instead of trick_counted and progress, and completed() when its total reaches 3 s.
##
## What counts (proposals for the playtest): a trick counts when it pays, the moment the combo
## hears it (RunState.combo_trick), so it is exactly what the player sees pop up:
## - drift (T-565; HUD and menus, Decisions, "The drift slide counts drift seconds"): not a trick
##   but time: every physics step the car drifts (its model's is_drifting, the same flag the run's
##   drift counter reads) adds its seconds to one total over all drifts, which the notebook shows
##   live (RunMissions.add_seconds: no name box for each fraction of a second, a proposal), and
##   the goal is done when the total reaches DRIFT_SECONDS. A drift too short to pay counts too;
## - alt drift: ALT DRIFT! ("alternate_drift");
## - air spin: AIR 180! or AIR 360! ("air_one_eighty", "air_three_sixty"); one landing counts
##   once, also a 540 that pays both;
## - grind: GRIND! ("rail_grind"), a grind long enough to pay (combo.json rail_grind.min_seconds).
## Nothing else counts. T-574 (the board): the count overfills, it goes on past the goal (5/3, the
## drift's total past 3 s, 4.7/3.0) in the notebook too; completed() is sent once, at the goal, and
## the car can go on driving.
##
## The car resets to its start point when it leaves the playground (the map's rectangle and
## AREA_MARGIN; the map's hard edges normally keep it in) or on R.
##
## The level and the texts (T-560 and T-559, both in):
## - PLAYGROUND_PATH: the practice playground, data/level/practice_playground.json (the board's
##   layout since T-574). Every trick starts on the level's spawn (T-574, start_point()). The level
##   draws its own grid ground ("ground_style").
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
const ElevationLayerScript := preload("res://scripts/level/elevation_layer.gd")
const RailsScript := preload("res://scripts/level/rails.gd")
const RailDrawingScript := preload("res://scripts/level/rail_drawing.gd")
const RailSparksScript := preload("res://scripts/driving/rail_sparks.gd")
const PowerUpScreenScript := preload("res://scripts/ui/power_up_screen.gd")
const PracticeOffersScript := preload("res://scripts/run/practice_offers.gd")

## The practice playground (T-560; Level design, Content, "The practice playground").
const PLAYGROUND_PATH := "res://data/level/practice_playground.json"
const TEXTS_PATH := "res://data/tutorial_text.json"
## T-574 tweak 9: the practice's settings (show_keys_to_player: the live keys while the player drives).
const SETTINGS_PATH := "res://data/tutorial_practice.json"
## The live keys' keycap size, a share of the window's height, and their margin from its corner.
const KEYS_SIZE_SHARE := 0.065
const KEYS_MARGIN := 10.0
## How many steps R stays lit after the board's R (or its replay).
const R_LIT_STEPS := 12

## The tricks a practice can count, as the slides name them.
const TRICKS := ["drift", "alt_drift", "air_spin", "grind"]
## The car's trick ids (RunState.combo_trick) that count for each.
const COUNTED := {
	"drift": [],  # T-565: the drift counts seconds of drifting (_on_car_stepped), not tricks
	"alt_drift": ["alternate_drift"],
	"air_spin": ["air_one_eighty", "air_three_sixty"],
	"grind": ["rail_grind"],
}
## The notebook goal's trick id for each (RunMissions; the trick's own id where there is one).
const GOAL_TRICK := {
	"drift": "drift_seconds",  # T-565: a practice goal of seconds added up, not the unbroken drift
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
## The drift slide's goal line (T-564's text, HUD and menus, Decisions, "The drift slide counts
## drift seconds"): a template with {done} and {total}, both seconds with one decimal. T-564 wrote
## it in place of T-559's drift line, so it is the same key as GOAL_TEXT_KEYS' drift.
const DRIFT_SECONDS_TEXT_KEYS := ["tutorial", "goal", "drift"]
## How many successes the goal asks (HUD and menus, Decisions, "Interactive tutorial slides").
const GOAL := 3
## The drift slide's goal: seconds of drifting in total (HUD and menus, Decisions, "The drift slide
## counts drift seconds", T-565).
const DRIFT_SECONDS := 3.0
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
## T-574 (the board, 2026-11-08: "stop putting the message on the big label on the center of the
## screen when the objective is done. Just put a green checkmark stamp on the objective notepad"):
## the goal done, a green check stamp lands on the notebook page, drawn in code (no text). Its
## centre on the page, size, tilt and ink, and the stamp's landing time (proposals for the playtest).
const STAMP_CENTRE := Vector2(118, 112)
const STAMP_SIZE := 92.0
const STAMP_TILT_DEG := -12.0
const STAMP_INK := Color(0.16, 0.66, 0.3, 0.9)
const STAMP_TIME := 0.18
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const PX := 16.0

## T-574 tweak 8 (dev builds only): the take tools' state changed ("ready", "recording",
## "saved", "playing", "played", "no_take", "error").
signal take_state_changed(state: String)
signal trick_counted(trick_id: String, done: int)
signal progress(done: int, goal: int)
## The drift's total grew (T-565): `done` seconds of drifting so far out of `goal`.
signal seconds_progress(done: float, goal: float)
signal completed
signal car_reset
signal gift_opened
signal gift_taken(id: String)

## The trick this practice counts (one of TRICKS).
var trick := "drift"
## The level file; set before the session enters the tree to use another.
var layout_path := PLAYGROUND_PATH
## Successes so far (0 and up, past GOAL too, T-574); the drift's stays 0 (it counts drift_seconds).
var successes := 0
## The drift's seconds of drifting so far, over all drifts (0 and up, past DRIFT_SECONDS too, T-574; T-565).
var drift_seconds := 0.0
## Whether the window has focus (the car reads the keyboard).
var focused := false

## Everything that moves, paused as one (process_mode).
var world: Node2D
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
## Thread the needle (T-574 tweak 6; T-272, as in the run): the level's pairs of obstacles, their
## faint markers and the flash; threading a pair pays THREAD THE NEEDLE! into the combo, as in a run.
## It counts toward no slide's goal (COUNTED).
var needle: ThreadTheNeedle
var needle_flash: NeedleFlash
## T-574 tweak 8, the takes (the slides' recording controls were removed in tweak 12; the demos
## replay the takes): where the takes are saved, the take being recorded or played, and its state.
var takes_dir := PracticeTake.TAKES_DIR
var take: PracticeTake
var take_state := "ready"
## While a take plays: the step about to run; and how far the replay went from the take's
## checkpoints (the largest distance in units, -1 before any checkpoint).
var replay_step := 0
var replay_drift := -1.0
var _recording := false
var _replaying := false
## T-574 tweak 9: the live keys pad (KeyPad, top right of the window) and whether the player sees it.
var keys_pad: KeyPad
var keys_layer: CanvasLayer
var show_keys_to_player := true
var _r_lit := 0
var _hops_before := 0
## The green check stamp on the notebook page (T-574), shown once the goal is done.
var stamp: Control

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
	drift_seconds = 0.0
	_air_counted_step = -1
	if offers.is_showing():
		offers.current_offers = []
		gift_screen.close()
		_set_gift_paused(false)
	state.start_run()
	if trick == "drift":
		missions.start_with([[{"trick": GOAL_TRICK[trick], "kind": RunMissions.KIND_SECONDS, "amount": DRIFT_SECONDS}]])
	else:
		missions.start_with([[{"trick": GOAL_TRICK[trick], "kind": RunMissions.KIND_COUNT, "amount": GOAL}]])
	notebook.goal_templates = {GOAL_TRICK[trick]: goal_template(trick)}
	notebook.show_current()
	if stamp != null:
		stamp.visible = false
	reset_car(false)
	_gift_pending = GIFT.has(trick)
	if not _paused:
		_open_gift_if_pending()
	if trick == "drift":
		seconds_progress.emit(drift_seconds, DRIFT_SECONDS)
	else:
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
	if trick == "drift":
		return drift_seconds >= DRIFT_SECONDS - RunMissions.EPSILON
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


## Where the car starts: {"position": units, "rotation": radians}. T-574 (the board, 2026-11-08:
## "the spawnpoint is different for each slide please fix it"): every slide starts on the level's
## own spawn, the one the board sets in the level creator, whatever the trick (`trick_name` is kept
## for the callers; the level's per-trick start_points, T-560, are no longer read here).
func start_point(_trick_name: String = "") -> Dictionary:
	return {"position": LevelSpawn.position_of(map.layout), "rotation": LevelSpawn.rotation_of(map.layout)}


## The notebook's goal line for `trick_name`: T-559's text in tutorial_text.json, for the drift
## T-564's (DRIFT_SECONDS_TEXT_KEYS) when it is there (an error and "" when it is missing).
static func goal_template(trick_name: String) -> String:
	var texts := _texts()
	if trick_name == "drift":
		var seconds_line := _text_at(texts, DRIFT_SECONDS_TEXT_KEYS)
		if seconds_line != "":
			return seconds_line
	var line := _text_at(texts, GOAL_TEXT_KEYS.get(trick_name, []))
	if line != "":
		return line
	push_error("PracticeSession: no goal line for '%s' in %s" % [trick_name, TEXTS_PATH])
	return ""


static func _text_at(texts: Dictionary, keys: Array) -> String:
	var node: Variant = texts
	for part in keys:
		node = node.get(part) if node is Dictionary else null
	return node if node is String else ""


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
	if focused and not _replaying and event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == RESET_KEY:
		if _recording:
			take.resets.append(take.steps())  # a take replays the board's R too
		_r_lit = R_LIT_STEPS
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

	# Thread the needle (T-574 tweak 6), as run.gd builds it: the gates, the markers, the flash.
	needle = ThreadTheNeedle.new(map.layout, ComboData.new().needle_rules())
	if not needle.gates.is_empty():
		needle.build_markers(map,
			func(units: Vector2) -> float: return layer.ground_height.height_at(units),
			func(units: Vector2, rot: float, h: float) -> int: return layer.z_for(units, rot, h))
		needle_flash = NeedleFlash.new()
		needle_flash.name = "NeedleFlash"
		world.add_child(needle_flash)
		needle_flash.bind(needle, map)

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
	needle.threaded.connect(func(_pair_id: String) -> void: state.add_needle_trick())
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
	stamp = Control.new()
	stamp.name = "DoneStamp"
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.size = Vector2(STAMP_SIZE, STAMP_SIZE)
	stamp.pivot_offset = stamp.size / 2.0
	stamp.position = STAMP_CENTRE - stamp.pivot_offset
	stamp.rotation = deg_to_rad(STAMP_TILT_DEG)
	stamp.visible = false
	stamp.draw.connect(_draw_stamp)
	notebook.add_child(stamp)
	completed.connect(_show_stamp.bind(true))
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

	# T-574 tweak 9: the live keys, top right of the window, over the game.
	var settings = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH)) if FileAccess.file_exists(SETTINGS_PATH) else null
	if settings is Dictionary:
		show_keys_to_player = bool(settings.get("show_keys_to_player", true))
	keys_layer = CanvasLayer.new()
	keys_layer.name = "Keys"
	keys_layer.layer = 11
	add_child(keys_layer)
	keys_pad = KeyPad.full()
	keys_layer.add_child(keys_pad)
	get_viewport().size_changed.connect(_place_keys)
	_place_keys()
	_update_keys()

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
	_keys_hops = car.jump.hops  # T-574 tweak 9: a new car's hops start again
	car.input_enabled = focused or _replaying
	if _replaying:
		car.use_keyboard = false
	car.grind.rails = rails
	car.grind.grind_ended.connect(func(_reason: String, seconds: float, _length: float) -> void:
		state.add_grind_trick(seconds))
	car.trick.connect(func(trick_id: String) -> void: state.add_trick(trick_id, car.tricks.last_trick_seconds))
	car.airtime_trick.connect(state.add_airtime_trick)
	car.hit_obstacle.connect(func(c: Object, s: int, _n: Vector2, _v: float) -> void:
		needle.touched(c, s)  # T-574 tweak 6: a touch voids a pass through a pair, as in the run
		state.collision())
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


# ---- The live keys (T-574 tweak 9) --------------------------------------------------------------

## The keys the car used on its last step, as the pad lights them: W, S, A (steer left), D (steer
## right), "_" Space (held, or the press that hopped), R for a moment after a reset by R.
func held_keys() -> String:
	var out := ""
	if car == null:
		return out
	var li: Array = car.last_input
	if li[0]:
		out += "W"
	if li[1]:
		out += "S"
	if float(li[2]) > 0.0:
		out += "A"
	elif float(li[2]) < 0.0:
		out += "D"
	if car.jump_held or (car.jump.hops != _keys_hops):
		out += KeyPad.SPACE
	if _r_lit > 0:
		out += "R"
	return out


var _keys_hops := 0


func _update_keys() -> void:
	if keys_pad == null:
		return
	keys_pad.visible = show_keys_to_player or _recording or _replaying
	keys_pad.set_held(held_keys())
	if car != null:
		_keys_hops = car.jump.hops
	_r_lit = maxi(_r_lit - 1, 0)


func _place_keys() -> void:
	if keys_pad == null or not is_inside_tree():
		return
	var vs := get_viewport().get_visible_rect().size
	keys_pad.set_key_size(maxf(12.0, roundf(vs.y * KEYS_SIZE_SHARE)))
	keys_pad.position = Vector2(vs.x - keys_pad.size.x - KEYS_MARGIN, KEYS_MARGIN)


# ---- The takes (T-574 tweak 8). Since tweak 12 no player can record: start_recording(),
# stop_and_save() and reset_stage() are called only by tools/standin_recorder.gd and the tests;
# the slides' demos use play_take(). ---------------------------------------------------------------

## True in a dev build (run from the editor or the project folder), never in an exported game.
static func dev_tools() -> bool:
	return OS.has_feature("editor")


func is_recording() -> bool:
	return _recording


func is_replaying() -> bool:
	return _replaying


## Everything back as at the slide's start: the count, the stamp, the combo, the notebook and its
## falling boxes, the gift, the car at the spawn standing still, its tyre marks and the popups, the
## pairs' cool-downs. Stops a recording (unsaved) or a replay.
func reset_stage() -> void:
	_recording = false
	_stop_replay()
	restart()
	drift_marks.clear()
	for p in trick_popups.popups():
		p.queue_free()
	needle.setup(map.layout, ComboData.new().needle_rules())
	_set_take_state("ready")


## Resets the stage and records the driving from now on (the grind's Jump gift is taken first).
func start_recording() -> void:
	reset_stage()
	var g := _take_gift_now()
	take = PracticeTake.new()
	take.trick = trick
	take.physics_fps = Engine.physics_ticks_per_second
	var sp := start_point()
	take.start = {"x": sp.position.x, "y": sp.position.y, "heading": rad_to_deg(sp.rotation)}
	take.gift = g
	_hops_before = car.jump.hops
	_recording = true
	_set_take_state("recording")


## Stops the recording and saves it as this trick's take (the last one kept as the backup).
## Returns the error (OK when saved; ERR_UNAVAILABLE when nothing was being recorded).
func stop_and_save() -> Error:
	if not _recording:
		return ERR_UNAVAILABLE
	_recording = false
	take.result = {"successes": successes, "drift_seconds": snappedf(drift_seconds, 0.01)}
	var err := take.save(takes_dir)
	_set_take_state("saved" if err == OK else "error")
	return err


## This trick's saved take (data/tutorial_takes/<trick>.json in takes_dir), or null when there is
## none. The slides play it as the slide's demo first (T-574 tweak 10, step 2).
func saved_take() -> PracticeTake:
	return PracticeTake.load_take(trick, takes_dir)


## Resets the stage and plays this trick's saved take (or `the_take`) on the real car; the keyboard
## is off while it plays. Returns false when there is no take.
func play_take(the_take: PracticeTake = null) -> bool:
	var t := the_take if the_take != null else PracticeTake.load_take(trick, takes_dir)
	reset_stage()
	if t == null or t.steps() == 0:
		_set_take_state("no_take")
		return false
	take = t
	if t.gift != "":
		_take_gift_now()
	_replaying = true
	replay_step = 0
	replay_drift = -1.0
	_hops_before = car.jump.hops
	car.input_enabled = true
	_apply_replay_frame()
	_set_take_state("playing")
	return true


func _take_gift_now() -> String:
	if not GIFT.has(trick):
		return ""
	if not is_gift_open():
		_open_gift_if_pending()
	if is_gift_open():
		gift_screen.skip_animation()
		take_gift()
	return String(GIFT[trick])


## After each car step: a recording keeps the step's keys and a checkpoint every second; a replay
## checks the checkpoint and sets the next step's keys.
func _take_step() -> void:
	if _recording:
		# T-574 tweak 11: the step's Space press (not its hop: since T-590's charged jump a held
		# press charges and hops on release, so a replay presses where the board pressed).
		var hop: bool = car.last_jump_press
		_hops_before = car.jump.hops
		take.add_frame(car.last_input[0], car.last_input[1], car.last_input[2], car.jump_held, hop)
		var n := take.steps()
		if n % PracticeTake.CHECKPOINT_EVERY == 0:
			take.add_checkpoint(n, car.model.get_position(), car.model.rotation, car.height)
	elif _replaying:
		replay_step += 1
		var c := take.checkpoint_at(replay_step)
		if not c.is_empty():
			var d: float = car.model.get_position().distance_to(Vector2(float(c.x), float(c.y)))
			replay_drift = maxf(replay_drift, d)
		if replay_step >= take.steps():
			_stop_replay()
			_set_take_state("played")
			return
		if take.resets.has(replay_step):
			_r_lit = R_LIT_STEPS
			reset_car()  # the board's R, before this step as when it was recorded
		_apply_replay_frame()


func _apply_replay_frame() -> void:
	if not _replaying or car == null:
		return
	var f: Array = take.frames[replay_step]
	car.use_keyboard = false
	car.scripted_input = [f[0], f[1], f[2]]
	car.scripted_jump_held = f[3]
	if f[4]:
		car.press_jump()


func _stop_replay() -> void:
	if not _replaying:
		return
	_replaying = false
	if car != null:
		car.scripted_input = [false, false, 0.0]
		car.scripted_jump_held = false
		car.use_keyboard = true
		car.input_enabled = focused


func _set_take_state(state_name: String) -> void:
	take_state = state_name
	take_state_changed.emit(state_name)


## The green check stamp (T-574): shown on the notebook once the goal is done; `land` plays the
## stamp's landing (it drops from a bit bigger and fades in), else it just shows.
func _show_stamp(land: bool) -> void:
	if stamp == null or stamp.visible:
		return
	notebook.move_child(stamp, notebook.get_child_count() - 1)
	stamp.visible = true
	if land and is_inside_tree():
		stamp.scale = Vector2(1.8, 1.8)
		stamp.modulate.a = 0.0
		var t := create_tween().set_parallel(true)
		t.tween_property(stamp, "scale", Vector2.ONE, STAMP_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(stamp, "modulate:a", 1.0, STAMP_TIME * 0.6)
	else:
		stamp.scale = Vector2.ONE
		stamp.modulate.a = 1.0


func is_stamped() -> bool:
	return stamp != null and stamp.visible


## A rubber stamp's look in code: a ring with a thick check inside, in green ink.
func _draw_stamp() -> void:
	var c := stamp.size / 2.0
	var r := STAMP_SIZE / 2.0 - 4.0
	stamp.draw_arc(c, r, 0.0, TAU, 40, STAMP_INK, 5.0, false)
	stamp.draw_arc(c, r - 7.0, 0.0, TAU, 40, STAMP_INK, 2.0, false)
	var pts := PackedVector2Array([c + Vector2(-r * 0.5, 0.0), c + Vector2(-r * 0.12, r * 0.4),
		c + Vector2(r * 0.55, -r * 0.42)])
	stamp.draw_polyline(pts, STAMP_INK, 11.0, false)
	for p in pts:
		stamp.draw_circle(p, 5.5, STAMP_INK)


# ---- Running ---------------------------------------------------------------------------------

## A trick paid into the combo: one more success when it is this practice's trick.
func _on_combo_trick(trick_id: String, _added: float, _multiplier: float) -> void:
	if not COUNTED[trick].has(trick_id):
		return
	if trick == "air_spin":
		if _air_counted_step == _steps:
			return  # the other spin of the same landing (a 540)
		_air_counted_step = _steps
	successes += 1
	if successes <= GOAL:
		missions.on_trick(GOAL_TRICK[trick])
	else:
		# T-574: past the goal the count goes on (5/3); the tracker stops at the goal, so the
		# notebook is told here, as the tracker would: the name box falls, the line counts on.
		notebook.drop_trick(0, GOAL_TRICK[trick])
		notebook.show_progress(0, float(successes))
	trick_counted.emit(trick_id, successes)
	progress.emit(successes, GOAL)
	if successes == GOAL:
		completed.emit()


## The drift slide (T-565): `seconds` more of drifting, added to the total; the notebook follows it
## and the goal is done at DRIFT_SECONDS. Nothing after that, or on another slide.
func add_drift_seconds(seconds: float) -> void:
	if trick != "drift" or seconds <= 0.0:
		return
	var was_done := is_completed()
	drift_seconds += seconds  # T-574: no cap, the total runs on past the goal (4.7/3.0)
	if not was_done:
		missions.add_seconds(GOAL_TRICK[trick], seconds)  # the tracker stops at the goal
	if is_completed() and drift_seconds > DRIFT_SECONDS:
		notebook.show_progress(0, drift_seconds)
	seconds_progress.emit(drift_seconds, DRIFT_SECONDS)
	if is_completed() and not was_done:
		completed.emit()


## After each of the car's physics steps: the drawing, the combo's hype speed, the rails and
## the playground's edge.
func _on_car_stepped() -> void:
	_steps += 1
	var dt: float = car.model.dt
	if not needle.gates.is_empty():  # T-574 tweak 6: thread the needle, as run.gd's _on_car_needle_step
		needle.touching(car.held_contacts())
		needle.observe(car.model.get_position(), car.airborne, dt)
	map.update_car_obstacles(car, car.height, car.vertical_speed)
	state.advance_combo_only(dt)  # T-574 tweak 7: the combo drains and breaks as in a run
	state.drift_step(car.model.is_drifting, dt)
	if trick == "drift" and car.model.is_drifting:
		add_drift_seconds(dt)
	car.tuning.hype_speed_bonus = state.eased_hype_speed(car.tuning.hype_speed_bonus, dt)
	rail_sparks.step(car, dt)
	if rail_drawing != null:
		rail_drawing.update_for_car(car.model.get_position(), car.height, view_root.z_index)
	_sync_view(false)
	if not in_area(car.model.get_position()):
		reset_car.call_deferred()
	_take_step()  # T-574 tweak 8: last, after the step's own work
	_update_keys()


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
