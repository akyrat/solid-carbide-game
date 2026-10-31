extends RefCounted
## Rev Charge (task T-460; Drifting, Decisions, "Driving power-ups"; how it
## behaves: Drifting, Content, "Rev Charge (task T-460)"). With the power-up
## owned (tier > 0), holding W and S together charges a boost, which fires when
## S is released. The charge time and the boost come from the owned tier in
## power_ups.json (PowerUpData).
##
## At tier 0 it does nothing at all: the car drives exactly as before (W wins
## over S, CarModel step 1).
##
## The car (car.gd) calls step() once per physics step, right after the
## model's own update_velocity(), with the keys and the heading the model used.
## It only reads and writes the model's velocity along that heading:
## - while charging, on the ground: the car keeps driving as with W held
##   (steering and drifting as normal), but brakes down to cruise speed at the
##   ramp rate and is held there (no climbing towards top speed);
## - while boosting, on the ground: the forward speed is held at least at the
##   boost speed (top speed x the boost multiplier) for the boost's seconds;
##   afterwards the car slows back to its top speed on its own (W's ramp).
## Every number but the tier's own is a proposal for the playtest (constants).

const PowerUpDataScript := preload("res://scripts/data/power_up_data.gd")

const ID := "rev_charge"
## A release below this share of a full charge fires nothing (a short W+S
## overlap while switching keys is not a boost). Proposal.
const MIN_FIRE_FRACTION := 0.25

## The charge began (both keys held, on the ground).
signal charge_started
## The charge was dropped with no boost (W let go first, S released in the air,
## too short a charge, the wreck).
signal charge_cancelled
## S released: the boost fires. fraction = share of a full charge (0..1),
## boost_speed in units/s, seconds = how long it is held.
signal fired(fraction: float, boost_speed: float, seconds: float)
## The boost's time is over, or a wall hit or the wreck ended it.
signal boost_ended

## Owned tier, 0 = not owned.
var tier := 0
## The tier's numbers (0 when not owned).
var charge_seconds := 0.0
var boost_speed_multiplier := 1.0
var boost_seconds := 0.0

## True while W and S are held together with the power-up owned.
var charging := false
## Seconds charged so far (grows only on the ground, up to charge_seconds).
var charge_time := 0.0
## Seconds of boost left; > 0 while boosting.
var boost_left := 0.0
## The running boost's length and its multiplier (after a partial charge).
var boost_total := 0.0
var boost_multiplier := 1.0
## The share of a full charge the last boost fired with.
var last_fraction := 0.0
## How many boosts have fired (tests, effects).
var boosts_fired := 0

var _data = null
## The forward speed at the start of this step (before_step).
var _fwd_before := 0.0


## Sets the owned tier (0 = not owned) and reads its numbers. Dropping to 0
## cancels any charge and boost.
func set_tier(new_tier: int, data = null) -> void:
	tier = maxi(new_tier, 0)
	if tier == 0:
		charge_seconds = 0.0
		boost_speed_multiplier = 1.0
		boost_seconds = 0.0
		reset()
		return
	if data != null:
		_data = data
	if _data == null:
		_data = PowerUpDataScript.new()
	var t: Dictionary = _data.at(ID, tier)
	charge_seconds = maxf(float(t.get("charge_seconds", 1.0)), 0.01)
	boost_speed_multiplier = maxf(float(t.get("boost_speed_multiplier", 1.0)), 1.0)
	boost_seconds = maxf(float(t.get("boost_seconds", 0.0)), 0.0)


func is_owned() -> bool:
	return tier > 0


## Share of a full charge, 0..1.
func charge_fraction() -> float:
	if charge_seconds <= 0.0:
		return 0.0
	return clampf(charge_time / charge_seconds, 0.0, 1.0)


func is_boosting() -> bool:
	return boost_left > 0.0


## Share of the running boost still to go, 1 -> 0 (0 when not boosting).
func boost_fraction_left() -> float:
	if boost_total <= 0.0:
		return 0.0
	return clampf(boost_left / boost_total, 0.0, 1.0)


## Drops the charge and the boost at once, with no boost (the wreck, a new car).
func reset() -> void:
	if charging:
		charging = false
		charge_time = 0.0
		charge_cancelled.emit()
	charge_time = 0.0
	end_boost()


## Ends a running boost (a wall hit, the wreck). The charge is kept.
func end_boost() -> void:
	if boost_left > 0.0:
		boost_left = 0.0
		boost_total = 0.0
		boost_multiplier = 1.0
		boost_ended.emit()


## One physics step, after model.update_velocity(w, s, steer). heading is the
## rotation the model built this step's velocity on (the rotation before the
## step). Changes nothing when the power-up is not owned.
func step(model, w: bool, s: bool, heading: float, airborne: bool, dt: float) -> void:
	if tier <= 0:
		return
	# The charge.
	if w and s:
		if not charging:
			charging = true
			charge_time = 0.0
			charge_started.emit()
		if not airborne:
			charge_time = minf(charge_time + dt, charge_seconds)
	elif charging:
		charging = false
		if not s and not airborne and charge_fraction() >= MIN_FIRE_FRACTION:
			_fire(model)
		else:
			# W let go first, S released in the air, or too short: no boost.
			charge_time = 0.0
			charge_cancelled.emit()
		charge_time = 0.0
	# The boost's clock runs in the air too; it only holds the speed on the ground.
	if boost_left > 0.0:
		if not airborne:
			_hold_forward_at_least(model, heading, model.tuning.top_speed() * boost_multiplier)
		boost_left = maxf(boost_left - dt, 0.0)
		if boost_left <= 0.0:
			boost_total = 0.0
			boost_multiplier = 1.0
			boost_ended.emit()
	elif charging and not airborne:
		_brake_to_cruise(model, heading, dt)


func _fire(model) -> void:
	var fraction := charge_fraction()
	last_fraction = fraction
	boost_multiplier = 1.0 + (boost_speed_multiplier - 1.0) * fraction
	boost_total = boost_seconds * fraction
	boost_left = boost_total
	boosts_fired += 1
	fired.emit(fraction, model.tuning.top_speed() * boost_multiplier, boost_total)


## Raises the forward speed along heading to at least `speed` (units/s); the
## sideways part is left alone.
static func _hold_forward_at_least(model, heading: float, speed: float) -> void:
	var c := cos(heading)
	var sn := sin(heading)
	var fwd: float = model.vx * c + model.vy * sn
	if fwd >= speed:
		return
	var side: float = -model.vx * sn + model.vy * c
	model.vx = c * speed - sn * side
	model.vy = sn * speed + c * side


## Call before model.update_velocity(): remembers the forward speed the step
## starts from (only used while charging). Nothing when not owned.
func before_step(model) -> void:
	if tier > 0:
		_fwd_before = model.forward_speed()


## While charging: a forward speed above cruise brakes down at the ramp rate
## from where this step started (so W's own climb does not cancel it).
func _brake_to_cruise(model, heading: float, dt: float) -> void:
	var cruise: float = model.tuning.forward_speed
	var c := cos(heading)
	var sn := sin(heading)
	var fwd: float = model.vx * c + model.vy * sn
	var cap := maxf(cruise, move_toward(_fwd_before, cruise, model.tuning.ramp_delta(dt)))
	if fwd <= cap:
		return
	var side: float = -model.vx * sn + model.vy * c
	fwd = cap
	model.vx = c * fwd - sn * side
	model.vy = sn * fwd + c * side
