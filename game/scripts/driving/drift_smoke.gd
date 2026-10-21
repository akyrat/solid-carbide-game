extends Node2D
## Drift smoke (task T-121; Visual style, Decisions, "Drift smoke"): while the
## car drifts, puffs of smoke come off its two rear tyres.
##
## - When: only while the car's own drift state is on (CarModel.is_drifting,
##   the same one the drift marks and the likes use). None while driving
##   straight or standing still.
## - Where: at each rear tyre's place on the ground. The tyre places come from
##   the drift marks (T-117, `rear_tyres()`), when bind() is given them, so
##   the smoke and the marks always start at the same spot. A puff stays where
##   it was left in the world (its spot is kept in flat world pixels and drawn
##   through `view_transform`), and drifts a little up and outward on screen.
## - Life: each puff grows, then shrinks, following `size_curve` over its
##   life, and pops out when its life ends. No puff fades: its colour's alpha
##   stays 1 and the texture has no semi-transparent pixels (Visual style,
##   Decisions, "See-through rule").
## - Cap: at most `max_puffs` at once; a new puff past the cap replaces the
##   oldest one.
## - Drawing: one node drawing every puff (_draw), upright in screen pixels
##   (not skewed by the isometric projection), with nearest filtering. It is
##   meant to sit in the car's own drawing (the run's View, under the car
##   sprite), so it shares the car's place in the buildings' depth order
##   (T-034): a building that covers the car also covers the smoke.
##
## Every look and tuning value lives in scenes/driving/drift_smoke.tscn (the
## exported variables below), so the art task (T-073) swaps the texture and
## retunes without touching this code.
##
## Use: instantiate the scene, add it under the drawn view (identity
## transform), set `view_transform` to the view's projection, call
## bind(car, drift_marks). Or call emit_step() yourself after each physics
## step. It ages in _process (the default, pausable process mode), so puffs
## stand still while the game is paused.

## Pixels per unit in the flat world (Car.PX_PER_UNIT).
const PX_PER_UNIT := 16.0

## The puff's sprite. Opaque or fully clear pixels only.
@export var puff_texture: Texture2D
## Tint multiplied with the texture. Keep alpha at 1 (no fading).
@export var puff_color: Color = Color(1, 1, 1, 1)
## The texture's drawn scale at size 1 (0.5 = the car art's density, 32 texels per unit).
@export var puff_scale: float = 0.5
## The puff's size over its life (x: 0 = born, 1 = popped; y: times puff_scale).
@export var size_curve: Curve
## Seconds a puff lives, on average.
@export var lifetime: float = 0.8
## How much each puff's life varies, as a fraction of `lifetime` (0.25 = +-25%).
@export var lifetime_randomness: float = 0.25
## New puffs per second from each rear tyre while drifting.
@export var puffs_per_second: float = 14.0
## The most puffs at once, both tyres together.
@export var max_puffs: int = 32
## How fast a puff rises on screen, in drawn pixels per second.
@export var rise_speed: float = 10.0
## The most a puff drifts outward (a random direction on screen), in drawn pixels per second.
@export var spread_speed: float = 8.0
## How far from the tyre a puff may start (random), in units.
@export var spawn_jitter_units: float = 0.15
## Fallback tyre geometry when no drift marks are given to bind() (the same
## values as the drift marks scene): units behind the centre, units to each side.
@export var rear_axle_units: float = 0.9
@export var half_track_units: float = 0.375

## Flat world pixels -> this node's drawn pixels (the view's projection). Set
## by the scene that owns it: the run's isometric projection, or the drift
## prototype's current view.
var view_transform := Transform2D.IDENTITY:
	set(value):
		view_transform = value
		queue_redraw()
## Seconds since this node started (only advances while not paused).
var time := 0.0
## How many puffs have been made so far.
var puffs_made := 0
## Where the tyre places come from: a node with rear_tyres(position, rotation)
## (the drift marks), or null for this node's own geometry.
var tyre_source: Object = null

## Puffs, oldest first: {world: Vector2 (flat px), velocity: Vector2 (drawn
## px/s), born: float, life: float, tyre: int}.
var _puffs: Array = []
## Puffs owed to each tyre (fractions carry over between steps).
var _owed: Array = [0.0, 0.0]
var _was_drifting := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func _process(delta: float) -> void:
	advance(delta)


## Makes smoke after the car's every physics step. `marks` (optional) is the
## drift marks node whose rear_tyres() gives the tyre places. No smoke while
## the car is airborne, even with the drift keys held; it comes back on landing
## (Drifting, Decisions, "No drift smoke in the air", task T-206).
func bind(car: Node, marks: Object = null) -> void:
	tyre_source = marks
	car.stepped.connect(func() -> void:
		emit_step(smokes(car), car.model.get_position(), car.model.rotation, car.model.dt))


## Whether `car` makes smoke this step: drifting and not airborne (a car
## without a height, `airborne` missing, is always on the ground).
static func smokes(car: Node) -> bool:
	return car.model.is_drifting and car.get("airborne") != true


## The two rear tyres' places on the ground, in units: [left, right].
func rear_tyres(position_units: Vector2, rotation_rad: float) -> Array:
	if tyre_source != null and is_instance_valid(tyre_source) and tyre_source.has_method("rear_tyres"):
		return tyre_source.rear_tyres(position_units, rotation_rad)
	var forward := Vector2(cos(rotation_rad), sin(rotation_rad))
	var side := Vector2(-forward.y, forward.x)
	var axle := position_units - forward * rear_axle_units
	return [axle - side * half_track_units, axle + side * half_track_units]


## One physics step of the car (`dt` seconds): puffs from both rear tyres while drifting.
func emit_step(drifting: bool, position_units: Vector2, rotation_rad: float, dt: float) -> void:
	if not drifting:
		_was_drifting = false
		_owed = [0.0, 0.0]
		return
	if not _was_drifting:
		_owed = [1.0, 1.0]  # a puff from each tyre as soon as the drift starts
	else:
		for t in 2:
			_owed[t] += puffs_per_second * dt
	_was_drifting = true
	var tyres := rear_tyres(position_units, rotation_rad)
	for t in 2:
		while _owed[t] >= 1.0:
			_owed[t] -= 1.0
			_add_puff(t, tyres[t])


## Moves time on: puffs past their life pop out.
func advance(delta: float) -> void:
	time += delta
	var keep: Array = []
	for p in _puffs:
		if time - p.born < p.life:
			keep.append(p)
	_puffs = keep
	queue_redraw()


## How many puffs there are now.
func puff_count() -> int:
	return _puffs.size()


## The puffs now, oldest first: {world: flat px where it was left, drawn: where
## it is drawn now, size: its scale now, age, life, tyre}.
func puffs() -> Array:
	var out: Array = []
	for p in _puffs:
		var age: float = time - p.born
		out.append({
			"world": p.world,
			"drawn": _drawn_at(p, age),
			"size": _size_at(p, age),
			"age": age,
			"life": p.life,
			"tyre": p.tyre,
		})
	return out


## Removes every puff (a new run).
func clear() -> void:
	_puffs.clear()
	_owed = [0.0, 0.0]
	_was_drifting = false
	queue_redraw()


func _add_puff(tyre: int, at_units: Vector2) -> void:
	var jitter := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * spawn_jitter_units
	var out := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * spread_speed
	var life := lifetime * (1.0 + _rng.randf_range(-lifetime_randomness, lifetime_randomness))
	_puffs.append({
		"world": (at_units + jitter) * PX_PER_UNIT,
		"velocity": Vector2(0.0, -rise_speed) + out,
		"born": time,
		"life": maxf(life, 0.01),
		"tyre": tyre,
	})
	puffs_made += 1
	while _puffs.size() > max_puffs:
		_puffs.pop_front()
	queue_redraw()


func _drawn_at(p: Dictionary, age: float) -> Vector2:
	return view_transform * Vector2(p.world) + Vector2(p.velocity) * age


func _size_at(p: Dictionary, age: float) -> float:
	var k := 1.0
	if size_curve != null:
		k = size_curve.sample(clampf(age / float(p.life), 0.0, 1.0))
	return maxf(k, 0.0) * puff_scale


func _draw() -> void:
	if puff_texture == null:
		return
	var tex_size := puff_texture.get_size()
	for p in _puffs:
		var age: float = time - p.born
		var s := _size_at(p, age)
		if s <= 0.0:
			continue
		var size := tex_size * s
		draw_texture_rect(puff_texture, Rect2(_drawn_at(p, age) - size * 0.5, size), false, puff_color)
