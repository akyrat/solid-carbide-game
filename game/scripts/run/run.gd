extends Node2D
## The run scene (task T-036): the MVP map with the drift car on it, the camera
## following the car as in the drift prototype, and the run's state
## (RunState, child "RunState").
##
## Physics runs in the flat top-down world (the map's Physics node and the
## car, under PhysicsWorld; neither is drawn). The map draws itself, and the
## View node draws the car on top of it, in the isometric view the drift
## prototype starts in. By default the camera sits exactly on the drawn car
## (no rotation, no smoothing); the camera options (task T-123, `camera_follow`)
## can add smoothing and the dynamic camera.
##
## The run scene connects the map's challenge signals and the car's drift
## state to the state's likes (XP) and levels (task T-037), and the car's
## tricks and collisions to the combo (task T-081), and plays the level-up
## effect on the car at every level-up (task T-112); since task T-144 each
## level-up sends the gift pack's helicopter (gift_drops.gd), and driving over
## its package opens the level-up screen. While the car drifts,
## its rear tyres leave drift marks (task T-117) on the map's ground, under
## the buildings and the car, and puffs of drift smoke (task T-121) come off
## them, drawn with the car. Buildings that cover the car fade (task T-034,
## in the map); sync_view() puts the car's drawing into the buildings' depth
## order through View's z_index. The minions (task T-044) spawn at the
## screen's edges and chase the car; see minion_spawner.gd.
##
## Other agents reach the run's state through `state`, or from anywhere in the
## tree with get_tree().get_first_node_in_group("run_state").
##
## The run's map (task T-206; Level design, Decisions, "The elevation sample
## map becomes the run's map"): with USE_ELEVATION_MAP true (the default) the
## map is built from the elevation sample map's layout
## (data/level/elevation_sample_map.json) with its rooftops and ramps
## (elevation_layer.gd, the same code the drive-only sample scene uses): the
## car has its real height on them (car_height.gd), is drawn lifted by it with
## its round shadow on the ground under it and its shadowless frames in the
## air, and the rooftops, ramps and buildings covering it fade. Enemies,
## coins, pickups and effects are drawn at street level (height 0) in the
## depth order. Set USE_ELEVATION_MAP to false for the MVP map (mvp_map.json),
## as before T-206.

const MapScene := preload("res://scenes/level/mvp_map.tscn")
const MapScript := preload("res://scripts/level/mvp_map.gd")
const CarScript := preload("res://scripts/driving/car.gd")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const RunStateScript := preload("res://scripts/run/run_state.gd")
const HudScene := preload("res://scenes/hud/hud.tscn")
const TrickPopupsScript := preload("res://scripts/hud/trick_popups.gd")
## The level-up effect (task T-112); its look and tuning live in the scene.
const LevelUpBurstScene := preload("res://scenes/run/level_up_burst.tscn")
## The drift marks (task T-117); their look and tuning live in the scene.
const DriftMarksScene := preload("res://scenes/driving/drift_marks.tscn")
## The camera options (task T-123): smoothing and the dynamic camera.
const CameraFollowScript := preload("res://scripts/driving/camera_follow.gd")
## The drift smoke (task T-121); its look and tuning live in the scene.
const DriftSmokeScene := preload("res://scenes/driving/drift_smoke.tscn")
## The placeholder boost effect (task T-008, boost_effect.gd).
const BoostEffectScript := preload("res://scripts/driving/boost_effect.gd")
## The minions (task T-044): spawning, chasing, contact damage, coins.
const MinionSpawnerScript := preload("res://scripts/enemies/minion_spawner.gd")
## The kaiju (task T-045): arrives at boss time, chases the car, ends the run when killed.
const KaijuBossScript := preload("res://scripts/enemies/kaiju_boss.gd")
## The kaiju's health bar above it (task T-050).
const KaijuHealthBarScript := preload("res://scripts/hud/kaiju_health_bar.gd")
## The car's weapons (task T-041): the weapon rack, see weapons.gd.
const WeaponsScript := preload("res://scripts/weapons/weapons.gd")
## The sound effects (task T-077): the engine, drift, guns, hits, coins and meteors.
const RunSoundsScript := preload("res://scripts/run/run_sounds.gd")
## The level-up screen (task T-052): shows the weapon choices when the run pauses for a level-up.
const LevelUpScreenScript := preload("res://scripts/ui/level_up_screen.gd")
## The gift pack drop (task T-144): a helicopter drops a package per level-up; driving over it opens the level-up screen.
const GiftDropsScript := preload("res://scripts/run/gift_drops.gd")
## The map's rooftops and ramps (task T-206): depth order, see-through, ground height.
const ElevationLayerScript := preload("res://scripts/level/elevation_layer.gd")
## The car's round shadow on the ground (task T-187), drawn with the elevation map only.
const CarShadowScript := preload("res://scripts/driving/car_shadow.gd")

## Which map a run plays on (task T-206): true, the elevation sample map's
## layout with its rooftops and ramps; false, the MVP map (as before T-206).
const USE_ELEVATION_MAP := true
## The elevation sample map's layout file (Level design, Content, "Elevation sample map").
const ELEVATION_LAYOUT_PATH := "res://data/level/elevation_sample_map.json"

## Same 2:1 isometric projection as the drift prototype and the map.
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## Where the car starts, in units from the map's centre: the centre of the
## gravel square, the one open space on the map. The same on the elevation
## map, whose gravel square is the MVP map's (a proposal, T-206).
const START_POSITION_UNITS := Vector2.ZERO
## The car's heading at the start, in radians: nose along -y (up in the flat
## view), as in the drift prototype (CarModel's default).
const START_ROTATION := -PI / 2.0
## Camera zoom as Unity's orthographic size, the drift prototype's default.
const ZOOM := 14.4
const VIEW := "iso"

## Emitted after start_run() has rebuilt the map and the car, before the
## state's run_started, so listeners can pick up the new `map` and `car`.
signal world_rebuilt

var state: RunState
## The player's saved upgrades (T-061). GameFlow sets it before adding the run; passed on to the state.
var progress: PlayerProgress = null
var hud: Hud
var map: Node2D
var physics_world: Node2D
var car: CharacterBody2D
var view_root: Node2D
var car_sprite: Sprite2D
var camera: Camera2D
var trick_popups: Node2D
## The level-up effect on the car (task T-112), drawn over the car and kept on it.
var level_up_burst: CPUParticles2D
## The drift marks (task T-117), inside the map's drawing: over the ground,
## under the buildings, boulders and the car. A new run's map brings new ones.
var drift_marks: Node2D
## The drift smoke (task T-121), in the car's drawing (View), under the car
## sprite: over the map (ground, marks, boulders), in the car's place in the
## buildings' depth order, under the HUD. Kept across runs, emptied by each new run.
var drift_smoke: Node2D
## The placeholder boost effect (task T-008): streaks behind the car when W
## snaps it to cruise speed. Child "BoostEffect" of the View, under the car.
var boost_effect: Node2D
## The camera zoom now, as Unity's orthographic size. The pause screen's zoom
## slider changes it through set_zoom() (task T-055).
var zoom := ZOOM
## The pause screen refreshes a tuning panel when there is one; the run has none.
var panel: CanvasLayer = null
## The camera options (task T-123): where the camera is and its size. Off by
## default; game_flow.gd reads the saved ones through load_camera_options().
## The pause screen's controls (task T-124) call its API directly.
var camera_follow = CameraFollowScript.new()
## Whether the run's map has challenges. Off in the MVP (Level design,
## Decisions, 2026-10-11); the default follows the map's CHALLENGES_ENABLED.
## Read by start_run() each time it builds a new map.
var challenges_enabled: bool = MapScript.CHALLENGES_ENABLED
## The minions (task T-044, minion_spawner.gd): child "Minions". Their bodies
## are in PhysicsWorld, their drawings in the "Enemies" node just before View.
## A new run clears them. Set `minions.enabled = false` to stop them (tests).
var minions: Node
## The kaiju (task T-045, kaiju_boss.gd): child "Kaiju". `kaiju_boss.kaiju` is
## the live kaiju (null before boss time). A new run removes it.
var kaiju_boss: Node
## The kaiju's health bar above it (task T-050, kaiju_health_bar.gd), in the world view.
var kaiju_health_bar: Node2D
## The car's weapons (task T-041, weapons.gd): child "Weapons". A new run
## starts with the starting gun at tier 1 and nothing else.
var weapons: Node
## The level-up screen (task T-052, level_up_screen.gd): child "LevelUpScreen".
var level_up_screen: CanvasLayer
## The sound effects (task T-077, run_sounds.gd): child "Sounds".
var sounds: Node
## The gift pack drop (task T-144, gift_drops.gd): child "GiftDrops", drawn
## just before View. Its off-screen arrows are the child "GiftArrows".
var gift_drops: GiftDrops
## Whether the next map built is the elevation map (USE_ELEVATION_MAP by
## default). Read by start_run() each time it builds a new map; tests set it.
var use_elevation_map: bool = USE_ELEVATION_MAP
## The map's rooftops and ramps (elevation_layer.gd), a child "Elevation" of
## the map; null on the MVP map. A new run's map brings a new one.
var elevation = null
## The car's round shadow (car_shadow.gd), child "CarShadow" of the run, just
## before View; shown on the elevation map only.
var shadow: Node2D


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.03, 0.03, 0.06))
	get_tree().physics_interpolation = true

	physics_world = Node2D.new()
	physics_world.name = "PhysicsWorld"
	physics_world.visible = false
	add_child(physics_world)

	shadow = CarShadowScript.new()
	shadow.name = "CarShadow"
	shadow.view_basis = ISO_TRANSFORM
	shadow.visible = false
	add_child(shadow)

	view_root = Node2D.new()
	view_root.name = "View"
	add_child(view_root)
	car_sprite = CarSpriteScript.new()
	car_sprite.name = "CarSprite"
	car_sprite.world_px_per_unit = CarScript.PX_PER_UNIT
	view_root.add_child(car_sprite)
	car_sprite.use_sheet(VIEW)

	drift_smoke = DriftSmokeScene.instantiate()
	drift_smoke.name = "DriftSmoke"
	drift_smoke.view_transform = ISO_TRANSFORM
	view_root.add_child(drift_smoke)
	view_root.move_child(drift_smoke, car_sprite.get_index())  # under the car

	boost_effect = BoostEffectScript.new()
	boost_effect.name = "BoostEffect"
	boost_effect.view_transform = ISO_TRANSFORM
	view_root.add_child(boost_effect)
	view_root.move_child(boost_effect, car_sprite.get_index())  # under the car

	level_up_burst = LevelUpBurstScene.instantiate()
	level_up_burst.name = "LevelUpBurst"
	view_root.add_child(level_up_burst)

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

	state = RunStateScript.new()
	state.name = "RunState"
	state.progress = progress
	state.add_to_group("run_state")
	add_child(state)
	state.level_up.connect(_on_level_up)
	state.car_damaged.connect(_on_car_damaged)

	trick_popups.bind_score(state, func() -> Vector2: return car_sprite.position)
	trick_popups.bind_combo(state, func() -> Vector2: return car_sprite.position)

	hud = HudScene.instantiate()
	add_child(hud)
	hud.bind(state)

	camera_follow.base_size = zoom
	camera_follow.size = zoom
	camera_follow.changed.connect(_apply_zoom)
	get_viewport().size_changed.connect(_apply_zoom)
	_apply_zoom()

	minions = MinionSpawnerScript.new()
	minions.name = "Minions"
	add_child(minions)
	minions.bind(self)
	kaiju_boss = KaijuBossScript.new()
	kaiju_boss.name = "Kaiju"
	add_child(kaiju_boss)
	kaiju_boss.bind(self)
	kaiju_health_bar = KaijuHealthBarScript.new()
	view_root.add_child(kaiju_health_bar)
	kaiju_health_bar.bind(kaiju_boss)
	weapons = WeaponsScript.new()
	weapons.name = "Weapons"
	add_child(weapons)
	weapons.bind(self)
	# The level-up screen (T-052) opens when the car drives over the gift pack's
	# package (T-144, gift_drops below), which pauses the run for the weapon
	# choice; a level-up itself no longer pauses (the switch stays off).
	state.pause_on_level_up = false
	level_up_screen = LevelUpScreenScript.new()
	level_up_screen.name = "LevelUpScreen"
	add_child(level_up_screen)
	level_up_screen.setup(weapons)
	# The gift pack drop (T-144): a helicopter drops a package per level-up.
	gift_drops = GiftDropsScript.new()
	gift_drops.name = "GiftDrops"
	add_child(gift_drops)
	move_child(gift_drops, view_root.get_index())  # drawn with the world, under the car
	gift_drops.bind(self)
	# The sound effects (task T-077, run_sounds.gd; files and volumes in data/sfx.json).
	sounds = RunSoundsScript.new()
	add_child(sounds)
	sounds.bind(self)
	start_run()


## Starts a fresh run: a new map (every challenge open again, when challenges
## are on; meteor boulders from the last run gone), the car back
## at the start, and the state reset (full health, 8:00, 0 coins).
func start_run() -> void:
	_build_world()
	world_rebuilt.emit()
	state.start_run()


func _build_world() -> void:
	if map != null:
		remove_child(map)
		map.queue_free()
	if car != null:
		physics_world.remove_child(car)
		car.queue_free()

	map = MapScene.instantiate()
	map.name = "Map"
	map.challenges_enabled = challenges_enabled
	if use_elevation_map:
		map.layout_path = ELEVATION_LAYOUT_PATH
	add_child(map)
	move_child(map, 0)  # drawn under the car
	map.set_view(VIEW)
	elevation = null
	if use_elevation_map:
		# The rooftops and ramps (T-206), sorted with the map's buildings.
		elevation = ElevationLayerScript.new()
		elevation.name = "Elevation"
		map.add_child(elevation)
		elevation.setup(map, ELEVATION_LAYOUT_PATH)
	shadow.visible = elevation != null
	# Back to the street's drawing until sync_view() places them (T-206).
	drift_smoke.position = Vector2.ZERO
	boost_effect.position = Vector2.ZERO
	car_sprite.set_in_air(false)
	# Drift marks go on the ground: right after the ground tiles in the map's
	# drawing, so the buildings, boulders and the car (View) are drawn over them.
	drift_marks = DriftMarksScene.instantiate()
	drift_marks.name = "DriftMarks"
	map.view_root.add_child(drift_marks)
	map.view_root.move_child(drift_marks, map.ground_tiles.get_index() + 1)

	car = CarScript.new()
	car.name = "Car"
	car.model.x = START_POSITION_UNITS.x
	car.model.y = START_POSITION_UNITS.y
	car.model.rotation = START_ROTATION
	physics_world.add_child(car)
	if elevation != null:
		car.ground = elevation.ground_height  # the car's height on the rooftops and ramps
	car.stepped.connect(_on_car_moved)
	car.stepped.connect(_on_car_stepped)
	drift_marks.bind(car)
	# Drift smoke (T-121): from the same rear tyre places as the marks.
	drift_smoke.clear()
	drift_smoke.bind(car, drift_marks)
	# Boost effect (T-008): when W snaps the car to cruise speed.
	boost_effect.clear()
	boost_effect.bind(car)
	# Likes (XP): every completed challenge, preset or meteor (T-037).
	map.challenge_completed.connect(state.challenge_completed)
	map.meteor_challenge_completed.connect(state.challenge_completed)
	# The combo (T-081): tricks raise it, hitting a wall, building, map edge
	# or boulder cuts it (damage to the car cuts it inside the state).
	car.trick.connect(state.add_trick)
	car.hit_obstacle.connect(_on_car_hit_obstacle)
	trick_popups.bind(car, func() -> Vector2: return car_sprite.position)
	map.car = car
	sync_view(true)
	car_sprite.reset_physics_interpolation()
	shadow.reset_physics_interpolation()
	camera.reset_physics_interpolation()


## The car hit a wall, building, map edge or boulder: a collision for the combo.
func _on_car_hit_obstacle(_collider: Object, _shape_index: int, _normal: Vector2, _impact_speed: float) -> void:
	state.collision()


## Feeds the car's drift state to the run's likes after each physics step.
func _on_car_stepped() -> void:
	state.drift_step(car.model.is_drifting, car.model.dt)


## T-072: the car took damage: the drawn car shakes briefly (its drawing only).
func _on_car_damaged(_amount: float) -> void:
	car_sprite.shake()


## The player levelled up: the car gives off the level-up burst (T-112).
func _on_level_up(_new_level: int) -> void:
	level_up_burst.position = car_sprite.position
	level_up_burst.play()


## After each physics step: the drawn car, and the camera one step on.
func _on_car_moved() -> void:
	sync_view(false)


## Places the drawn car on the car's current position, and the camera: straight
## on it when snap_camera is true (or both camera options are off), otherwise
## one physics step of the camera options toward it.
func sync_view(snap_camera: bool = true) -> void:
	if elevation != null:
		_sync_view_elevation(snap_camera)
		return
	var drawn := ISO_TRANSFORM * car.position
	car_sprite.position = drawn
	car_sprite.set_heading(car.rotation)
	var frac: float = CameraFollowScript.speed_fraction_of(car.model)
	if snap_camera:
		camera_follow.snap(drawn, frac)
	else:
		camera_follow.step(drawn, frac, car.model.dt)
	camera.position = camera_follow.position
	if snap_camera or camera_follow.dynamic:
		_apply_zoom()
	# See-through buildings (T-034): the car's drawing (with its effects and
	# popups) goes under the buildings that cover it and over the rest.
	view_root.z_index = map.car_z_index(car.position / CarScript.PX_PER_UNIT, car.rotation)
	if level_up_burst != null:
		level_up_burst.position = drawn


## sync_view() on the elevation map (T-206), as the drive-only sample scene:
## the car drawn lifted by its height (its shadowless frames in the air), its
## round shadow on the ground under it, both in the depth order with the
## rooftops, ramps, buildings and boulders, the see-through, and the camera
## following the car's map position at street level. The car's own effects
## (drift smoke, boost) are lifted with the ground under the car, so they stay
## at its tyres on a rooftop (a proposal).
func _sync_view_elevation(snap_camera: bool) -> void:
	var units: Vector2 = car.model.get_position()
	var at_ground := ISO_TRANSFORM * (units * CarScript.PX_PER_UNIT)
	var ground_h: float = elevation.ground_height.height_at(units)
	car_sprite.place(at_ground, car.height)
	car_sprite.set_in_air(CarSpriteScript.is_in_air(car.height, ground_h))
	car_sprite.set_heading(car.rotation)
	shadow.place(units, ground_h)
	var lift: Vector2 = CarSpriteScript.lift_for_height(ground_h, CarScript.PX_PER_UNIT)
	drift_smoke.position = lift
	boost_effect.position = lift
	view_root.z_index = elevation.z_for(units, car.rotation, car.height)
	shadow.z_index = elevation.z_for(units, car.rotation, ground_h) - 1
	elevation.update_see_through(units, car.rotation, car.height, car.model.dt)
	var frac: float = CameraFollowScript.speed_fraction_of(car.model)
	if snap_camera:
		camera_follow.snap(at_ground, frac)
	else:
		camera_follow.step(at_ground, frac, car.model.dt)
	camera.position = camera_follow.position
	if snap_camera or camera_follow.dynamic:
		_apply_zoom()
	if level_up_burst != null:
		level_up_burst.position = car_sprite.position


## Sets the camera zoom (Unity's orthographic size), as the pause screen's slider does.
func set_zoom(orthographic_size: float) -> void:
	zoom = orthographic_size
	camera_follow.set_base_size(orthographic_size)  # applies the zoom


## Reads the saved camera options (task T-123) and applies them at once.
func load_camera_options() -> void:
	camera_follow.load_saved(CameraFollowScript.speed_fraction_of(car.model) if car != null else 0.0)


## Godot's zoom is a magnification: visible height in pixels / (2 * size * px per unit).
## The size is the slider's zoom, or the dynamic camera's when it is on.
func _apply_zoom() -> void:
	var height := get_viewport().get_visible_rect().size.y
	var z: float = height / (2.0 * camera_follow.size * CarScript.PX_PER_UNIT)
	camera.zoom = Vector2(z, z)
