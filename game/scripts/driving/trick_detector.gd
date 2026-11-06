extends RefCounted
## Detects the MVP's three tricks (Drifting, Decisions, 2026-10-10) from the
## car's own driving, task T-079. It only reads the car: it never changes the
## car's speed, position or rotation. No nodes, so tests can run it directly.
##
## The car (car.gd) calls observe() once per physics step, after the driving
## model's update and its height step (T-219), with the keys used for that step. Each trick found
## emits `trick` once, with the trick's id:
##
## - "extended_drift": one whole unbroken drift, found when it ends (task T-246,
##   Drifting, Decisions, "Drift pays once, at its end"), if it lasted at least
##   combo.json's drift_pay.min_seconds. Nothing is emitted while it lasts. The
##   drift's length in seconds is in `last_trick_seconds` while `trick` is
##   emitted; the combo scales its amount by it (ComboData.drift_amount).
##   "Drifting" is the model's own is_drifting (W, or S without W, held
##   together with A or D). A takeoff ends the drift, so it pays there.
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
## - "reverse_drift" (task T-536; Drifting, Decisions, "A reverse drift
##   trick"): a drift on S without W (the model's is_drifting with reverse)
##   while the car's velocity points backwards relative to its nose
##   (forward_speed() below 0), unbroken for combo.json's
##   reverse_drift.min_seconds. Paid once per unbroken reverse drift, at the
##   step it reaches that time; any step that is not such a drift starts it
##   again from zero.
## - "aura" (task T-536; Drifting, Decisions, "An aura trick"): the car on the
##   ground with its speed at most combo.json's aura.still_speed. After
##   aura.wait_seconds still, one aura is paid every aura.every_seconds for as
##   long as it stays still (5 s and 1 s: the first at 6 s, then 7 s, ...).
##   Moving faster, or leaving the ground, starts the count again. It counts
##   only observed steps, so a paused tree (pause, level-up, time's up) adds
##   nothing, and the run turns detection off and resets it while wrecked.
##
## A "break" is any physics step on which the car is not drifting.
##
## A crash pays the trick in progress (task T-315; Game loop architecture,
## Decisions, "A crash pays the trick in progress"): settle() pays, at once,
## the tricks that build up over time and would otherwise pay only at their
## end: the drift so far (its extended_drift, if it reached drift_min_seconds)
## and, in the air, the aerial spins and the airtime so far. Each then starts
## again from zero, so the rest of the drift or of the airtime after the crash
## is a new one. The run calls it when the car crashes (RunState.crashed).
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
##   Proposals for the board's playtest (Drifting, Decisions, "Aerial tricks").
##
## The airtime trick (task T-242; Drifting, Decisions, "Airtime trick"): every
## airtime is a trick of its own. On the landing step, after the aerial
## tricks, the detector counts it ("airtime" in `counts`, and last_trick) and
## emits `airtime_trick` with the seconds in the air (the sum of the `dt` of
## the steps that ended in the air). It is not one of TRICK_IDS: its combo
## amount depends on the seconds (ComboData.airtime_add), so it has its own
## signal. Callers that give no `dt` (older tests) get no airtime.

const TRICK_EXTENDED_DRIFT := "extended_drift"
const TRICK_THREE_SIXTY := "three_sixty"
const TRICK_ALTERNATE_DRIFT := "alternate_drift"
const TRICK_AIR_ONE_EIGHTY := "air_one_eighty"
const TRICK_AIR_THREE_SIXTY := "air_three_sixty"
## Task T-536: the reverse drift and the aura.
const TRICK_REVERSE_DRIFT := "reverse_drift"
const TRICK_AURA := "aura"
const TRICK_IDS := [TRICK_EXTENDED_DRIFT, TRICK_THREE_SIXTY, TRICK_ALTERNATE_DRIFT,
	TRICK_REVERSE_DRIFT, TRICK_AURA,
	TRICK_AIR_ONE_EIGHTY, TRICK_AIR_THREE_SIXTY]
## The airtime trick's id (task T-242), in `counts`, last_trick and the popups.
const TRICK_AIRTIME := "airtime"
## The two aerial tricks (task T-219).
const AIR_TRICK_IDS := [TRICK_AIR_ONE_EIGHTY, TRICK_AIR_THREE_SIXTY]

## Heading change per 360 trick, in radians (Drifting, Decisions).
const FULL_TURN := TAU
## Heading change per air 180, in radians (Drifting, Decisions, "Aerial tricks").
const HALF_TURN := PI
## Slack for adding up floating-point step times and angles.
const EPSILON := 1e-6

## Emitted once per trick, with one of TRICK_IDS.
signal trick(trick_id: String)
## Emitted once per landing, with the seconds the car was in the air (task T-242).
## Whether it pays is the combo's decision (combo.json, airtime).
signal airtime_trick(seconds: float)

## The last trick found ("" before the first), and seconds of observed steps
## since then. For the drift prototype's readout.
var last_trick := ""
## The length in seconds of the drift that paid, set just before `trick` is
## emitted for "extended_drift" (task T-246); 0 for every other trick.
var last_trick_seconds := 0.0
## Shortest drift that pays, seconds (combo.json, drift_pay.min_seconds).
var drift_min_seconds: float = ComboData.new().drift_min_seconds()
## Shortest airtime that pays, seconds (combo.json, airtime.min_seconds). Only
## settle() reads it (task T-315): a crash in the air pays the airtime so far
## from this length on.
var airtime_min_seconds: float = ComboData.new().airtime_min_seconds()
## Task T-536 (combo.json, reverse_drift and aura; proposals for the playtest):
## how long a reverse drift must last, the speed at or under which the car is
## still (units/s), the seconds still before the aura starts, and the seconds
## per aura after that.
var reverse_drift_min_seconds: float = ComboData.new().reverse_drift_min_seconds()
var aura_still_speed: float = ComboData.new().aura_still_speed()
var aura_wait_seconds: float = ComboData.new().aura_wait_seconds()
var aura_every_seconds: float = ComboData.new().aura_every_seconds()
var seconds_since_last := 0.0
## trick id -> how many have been found since the last reset().
var counts := {}

# Extended drift: seconds of the current unbroken drift so far.
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
# Seconds of the current airtime so far (task T-242).
var _air_seconds := 0.0
# Task T-536: seconds of the current unbroken reverse drift and whether it has
# paid; seconds the car has been still and the auras paid in that stillness.
var _reverse_time := 0.0
var _reverse_paid := false
var _still_time := 0.0
var _auras_paid := 0


func _init() -> void:
	reset()


## Forgets every drift in progress, the last trick and the counts.
func reset() -> void:
	last_trick = ""
	last_trick_seconds = 0.0
	seconds_since_last = 0.0
	counts = {}
	for id in TRICK_IDS:
		counts[id] = 0
	counts[TRICK_AIRTIME] = 0
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
	_air_seconds = 0.0
	_reverse_time = 0.0
	_reverse_paid = false
	_still_time = 0.0
	_auras_paid = 0


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
	_observe_reverse_drift(model, drifting and s and not w and not airborne, dt)  # T-536
	_observe_aura(model, airborne, dt)  # T-536

	# Extended drift.
	if drifting:
		_drift_time += dt
	else:
		# The drift ends: it pays once, by its length (task T-246).
		if _drift_time >= drift_min_seconds - EPSILON and _drift_time > 0.0:
			last_trick_seconds = _drift_time
			_emit(TRICK_EXTENDED_DRIFT)
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
## the step the car lands (see the top of this file). `dt` is the step's
## length in seconds, for the airtime trick (task T-242).
func observe_air(airborne: bool, turned: float, dt := 0.0) -> void:
	if not airborne:
		if _air:
			_land()
		return
	if not _air:
		_air = true
		_air_turn = 0.0
		_air_best = 0.0
		_air_seconds = 0.0
	_air_seconds += dt
	if turned != 0.0:
		if _air_turn != 0.0 and signf(turned) != signf(_air_turn):
			_air_turn = 0.0
		_air_turn += turned
		_air_best = maxf(_air_best, absf(_air_turn))


## A crash (task T-315): pays the drift in progress and, in the air, the
## aerial spins and the airtime so far, as if they ended now, then starts that
## count again from zero (the car may still be drifting or in the air). A
## drift or an airtime too short to pay yet is left alone, so a crash with no
## trick in progress changes nothing. The drift 360 and the alternate drift are
## not touched: they pay only once complete, so nothing of them is in progress.
func settle() -> void:
	if _drift_time >= drift_min_seconds - EPSILON and _drift_time > 0.0:
		last_trick_seconds = _drift_time
		_emit(TRICK_EXTENDED_DRIFT)
		_drift_time = 0.0
	if _air and (half_turns(_air_best) > 0 or _air_seconds >= airtime_min_seconds - EPSILON):
		_land()
		_air = true  # still in the air: the rest of the airtime counts from now


## Half turns in an airtime's best turn of `radians` (180 degrees each).
static func half_turns(radians: float) -> int:
	return int(floorf((absf(radians) + EPSILON) / HALF_TURN))


func _land() -> void:
	var halves := half_turns(_air_best)
	var seconds := _air_seconds
	_air = false
	_air_seconds = 0.0
	_air_turn = 0.0
	_air_best = 0.0
	for i in halves / 2:
		_emit(TRICK_AIR_THREE_SIXTY)
	if halves % 2 == 1:
		_emit(TRICK_AIR_ONE_EIGHTY)
	if seconds > 0.0:
		last_trick = TRICK_AIRTIME
		seconds_since_last = 0.0
		counts[TRICK_AIRTIME] = int(counts.get(TRICK_AIRTIME, 0)) + 1
		airtime_trick.emit(seconds)


## Task T-536: the reverse drift. `reversing` is a drift on S without W this
## step; it counts while the velocity points backwards from the nose.
func _observe_reverse_drift(model, reversing: bool, dt: float) -> void:
	if not reversing or model.forward_speed() >= 0.0:
		_reverse_time = 0.0
		_reverse_paid = false
		return
	_reverse_time += dt
	if not _reverse_paid and _reverse_time >= reverse_drift_min_seconds - EPSILON:
		_reverse_paid = true
		_emit(TRICK_REVERSE_DRIFT)


## Task T-536: the aura. Still = on the ground at or under aura_still_speed.
func _observe_aura(model, airborne: bool, dt: float) -> void:
	if airborne or model.total_speed() > aura_still_speed:
		_still_time = 0.0
		_auras_paid = 0
		return
	_still_time += dt
	var every := maxf(aura_every_seconds, 0.01)
	while _still_time >= aura_wait_seconds + every * float(_auras_paid + 1) - EPSILON:
		_auras_paid += 1
		_emit(TRICK_AURA)


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
	if trick_id != TRICK_EXTENDED_DRIFT:
		last_trick_seconds = 0.0
	seconds_since_last = 0.0
	counts[trick_id] = int(counts.get(trick_id, 0)) + 1
	trick.emit(trick_id)
