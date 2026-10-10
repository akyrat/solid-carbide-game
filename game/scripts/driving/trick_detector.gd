extends RefCounted
## Detects the MVP's three tricks (Drifting, Decisions, 2026-10-10) from the
## car's own driving, task T-079. It only reads the car: it never changes the
## car's speed, position or rotation. No nodes, so tests can run it directly.
##
## The car (car.gd) calls observe() once per physics step, right after the
## driving model's update, with the keys used for that step. Each trick found
## emits `trick` once, with the trick's id:
##
## - "extended_drift": every full second of one unbroken drift. "Drifting" is
##   the model's own is_drifting (W, or S without W, held together with A or D).
## - "three_sixty": the heading has turned a full 360 degrees in one direction
##   during one unbroken drift; 720 gives two. A break in the drift, or turning
##   back the other way, starts the count again.
## - "alternate_drift": a switch between a forward drift (W + A or D) and a
##   backward drift (S + A or D) with the same steering direction. See the
##   alternate_* values in car_tuning.gd for its timing limits.
##
## A "break" is any physics step on which the car is not drifting.

const TRICK_EXTENDED_DRIFT := "extended_drift"
const TRICK_THREE_SIXTY := "three_sixty"
const TRICK_ALTERNATE_DRIFT := "alternate_drift"
const TRICK_IDS := [TRICK_EXTENDED_DRIFT, TRICK_THREE_SIXTY, TRICK_ALTERNATE_DRIFT]

## Seconds of unbroken drift per extended-drift trick (Drifting, Decisions).
const EXTENDED_DRIFT_SECONDS := 1.0
## Heading change per 360 trick, in radians (Drifting, Decisions).
const FULL_TURN := TAU
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


## One physics step. model is the CarModel after its update_velocity() for this
## step; w, s and steer are the keys it used (steer +1 = A, -1 = D);
## rotation_before is the model's rotation before that update.
func observe(model, w: bool, s: bool, steer: float, rotation_before: float) -> void:
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
		if turned != 0.0:
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
