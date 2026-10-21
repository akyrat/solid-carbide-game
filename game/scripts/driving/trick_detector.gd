extends RefCounted
## Detects the MVP's three tricks (Drifting, Decisions, 2026-10-10) from the
## car's own driving, task T-079. It only reads the car: it never changes the
## car's speed, position or rotation. No nodes, so tests can run it directly.
##
## The car (car.gd) calls observe() once per physics step, after the driving
## model's update and its height step (T-219), with the keys used for that step. Each trick found
## emits `trick` once, with the trick's id:
##
## - "extended_drift": every full second of one unbroken drift. "Drifting" is
##   the model's own is_drifting (W, or S without W, held together with A or D).
## - "three_sixty": the heading has turned a full 360 degrees in one direction
##   during one unbroken drift; 720 gives two. A break in the drift, or turning
##   back the other way, starts the count again. Turning on a step that ends in
##   the air does not count (task T-219, board: each spin pays once; it counts
##   for the aerial tricks instead). Since the board's "no drifting in the
##   air" the model is not drifting while airborne, so a takeoff is a break:
##   a drift 360 in progress starts again from zero after landing.
## - "alternate_drift": a switch between a forward drift (W + A or D) and a
##   backward drift (S + A or D) with the same steering direction. See the
##   alternate_* values in car_tuning.gd for its timing limits.
##
## A "break" is any physics step on which the car is not drifting.
##
## The aerial tricks (task T-219; Drifting, Decisions, "Aerial tricks") come
## from observe_air(), which car.gd calls once per physics step after the
## car's height step, with whether the car is in the air and how far its
## heading turned on that step:
##
## - "air_one_eighty" and "air_three_sixty": the heading turned during one
##   airtime, either direction the same. The turn is counted in one direction;
##   turning back starts a new count, and the airtime keeps its largest one.
##   On the landing step that turn is paid out in half turns (HALF_TURN): every
##   two make one air 360, an odd one left over makes one air 180. So 180 gives
##   an air 180, 360 an air 360 (not its 180 too), 540 an air 360 and an air
##   180, 720 two air 360s. Only heading turned while in the air counts.
##   Proposals for the board's playtest (Drifting, Content, "Aerial tricks").

const TRICK_EXTENDED_DRIFT := "extended_drift"
const TRICK_THREE_SIXTY := "three_sixty"
const TRICK_ALTERNATE_DRIFT := "alternate_drift"
const TRICK_AIR_ONE_EIGHTY := "air_one_eighty"
const TRICK_AIR_THREE_SIXTY := "air_three_sixty"
const TRICK_IDS := [TRICK_EXTENDED_DRIFT, TRICK_THREE_SIXTY, TRICK_ALTERNATE_DRIFT,
	TRICK_AIR_ONE_EIGHTY, TRICK_AIR_THREE_SIXTY]
## The two aerial tricks (task T-219).
const AIR_TRICK_IDS := [TRICK_AIR_ONE_EIGHTY, TRICK_AIR_THREE_SIXTY]

## Seconds of unbroken drift per extended-drift trick (Drifting, Decisions).
const EXTENDED_DRIFT_SECONDS := 1.0
## Heading change per 360 trick, in radians (Drifting, Decisions).
const FULL_TURN := TAU
## Heading change per air 180, in radians (Drifting, Decisions, "Aerial tricks").
const HALF_TURN := PI
## Slack for adding up floating-point step times and angles.
const EPSILON := 1e-6

## Emitted once per trick, with one of TRICK_IDS.
signal trick(trick_id: String)

## The last trick found ("" before the first), and seconds of observed steps
## since then. For the drift prototype's readout.
var last_trick := ""
var seconds_since_last := 0.0
## trick id -> how many have been found since the last reset().
var counts := {}

# Extended drift: seconds of the current unbroken drift not yet counted.
var _drift_time := 0.0
# 360: heading turned in the current unbroken drift, in one direction (radians, signed).
var _turn := 0.0
# Alternate drift. The current drift segment: one direction (+1 forward, -1
# backward, 0 = not drifting) and one steering side (+1 A, -1 D).
var _seg_dir := 0
var _seg_steer := 0
var _seg_time := 0.0
var _seg_long_enough := false
# True when the current segment, once long enough, completes a switch.
var _seg_is_switch := false
# The last segment that was long enough, while a switch from it is still
# possible: {"dir", "steer"}, or empty.
var _prev := {}
# Seconds since _prev ended, and whether the steering stayed on its side.
var _gap_time := 0.0
var _gap_steer_kept := true
# Aerial tricks: whether the car was in the air on the last observe_air(), the
# turn of the current one-direction count (radians, signed) and the largest
# such turn this airtime (radians, unsigned).
var _air := false
var _air_turn := 0.0
var _air_best := 0.0


func _init() -> void:
	reset()


## Forgets every drift in progress, the last trick and the counts.
func reset() -> void:
	last_trick = ""
	seconds_since_last = 0.0
	counts = {}
	for id in TRICK_IDS:
		counts[id] = 0
	_drift_time = 0.0
	_turn = 0.0
	_seg_dir = 0
	_seg_steer = 0
	_seg_time = 0.0
	_seg_long_enough = false
	_seg_is_switch = false
	_prev = {}
	_gap_time = 0.0
	_gap_steer_kept = true
	_air = false
	_air_turn = 0.0
	_air_best = 0.0


## One physics step. model is the CarModel after its update_velocity() for this
## step; w, s and steer are the keys it used (steer +1 = A, -1 = D);
## rotation_before is the model's rotation before that update; airborne is
## true when the step ends with the car in the air (task T-219).
func observe(model, w: bool, s: bool, steer: float, rotation_before: float, airborne := false) -> void:
	var dt: float = model.dt
	var t = model.tuning
	seconds_since_last += dt
	var drifting: bool = model.is_drifting
	var steer_side := 0
	if absf(steer) > 0.01:
		steer_side = 1 if steer > 0.0 else -1

	# Extended drift.
	if drifting:
		_drift_time += dt
		while _drift_time >= EXTENDED_DRIFT_SECONDS - EPSILON:
			_drift_time -= EXTENDED_DRIFT_SECONDS
			_emit(TRICK_EXTENDED_DRIFT)
	else:
		_drift_time = 0.0

	# 360.
	if drifting:
		var turned: float = model.rotation - rotation_before
		# In the air the turn is the aerial tricks' (observe_air), not the drift 360's.
		if turned != 0.0 and not airborne:
			if _turn != 0.0 and signf(turned) != signf(_turn):
				_turn = 0.0
			_turn += turned
			while absf(_turn) >= FULL_TURN - EPSILON:
				_turn -= signf(_turn) * FULL_TURN
				_emit(TRICK_THREE_SIXTY)
	else:
		_turn = 0.0

	# Alternate drift.
	var dir := 0
	if drifting:
		dir = 1 if w else -1
	if dir != _seg_dir or (dir != 0 and steer_side != _seg_steer):
		_end_segment()
		if dir != 0:
			_start_segment(dir, steer_side, t)
	if dir != 0:
		_seg_time += dt
		if not _seg_long_enough and _seg_time >= float(t.alternate_min_drift_seconds) - EPSILON:
			_seg_long_enough = true
			if _seg_is_switch:
				_emit(TRICK_ALTERNATE_DRIFT)
	elif not _prev.is_empty():
		_gap_time += dt
		if steer_side != int(_prev.steer):
			_gap_steer_kept = false
		if _gap_time > float(t.alternate_max_switch_seconds) + EPSILON:
			_prev = {}


## The aerial tricks' part of one physics step (task T-219): car.gd calls it
## after the car's height step, with `airborne` (the car is in the air at the
## end of the step) and `turned`, the heading's change on that step (radians).
## Turning on a step that ends in the air counts; the tricks are paid out on
## the step the car lands (see the top of this file).
func observe_air(airborne: bool, turned: float) -> void:
	if not airborne:
		if _air:
			_land()
		return
	if not _air:
		_air = true
		_air_turn = 0.0
		_air_best = 0.0
	if turned != 0.0:
		if _air_turn != 0.0 and signf(turned) != signf(_air_turn):
			_air_turn = 0.0
		_air_turn += turned
		_air_best = maxf(_air_best, absf(_air_turn))


## Half turns in an airtime's best turn of `radians` (180 degrees each).
static func half_turns(radians: float) -> int:
	return int(floorf((absf(radians) + EPSILON) / HALF_TURN))


func _land() -> void:
	var halves := half_turns(_air_best)
	_air = false
	_air_turn = 0.0
	_air_best = 0.0
	for i in halves / 2:
		_emit(TRICK_AIR_THREE_SIXTY)
	if halves % 2 == 1:
		_emit(TRICK_AIR_ONE_EIGHTY)


func _end_segment() -> void:
	if _seg_dir == 0:
		return
	if _seg_long_enough:
		_prev = {"dir": _seg_dir, "steer": _seg_steer}
	else:
		# A drift too short to count breaks the chain of switches.
		_prev = {}
	_gap_time = 0.0
	_gap_steer_kept = true
	_seg_dir = 0
	_seg_steer = 0


func _start_segment(dir: int, steer_side: int, t) -> void:
	_seg_dir = dir
	_seg_steer = steer_side
	_seg_time = 0.0
	_seg_long_enough = false
	_seg_is_switch = (not _prev.is_empty()
		and int(_prev.dir) == -dir
		and int(_prev.steer) == steer_side
		and _gap_time <= float(t.alternate_max_switch_seconds) + EPSILON
		and (_gap_steer_kept or not bool(t.alternate_keep_steering)))


func _emit(trick_id: String) -> void:
	last_trick = trick_id
	seconds_since_last = 0.0
	counts[trick_id] = int(counts.get(trick_id, 0)) + 1
	trick.emit(trick_id)
