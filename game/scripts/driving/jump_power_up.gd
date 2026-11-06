extends RefCounted
## Jump (task T-461; Drifting, Decisions, "Driving power-ups"; how it behaves:
## Drifting, Content, "Jump (task T-461)"). With the power-up owned (tier > 0),
## a press of Space on the ground makes a small hop: the car's own height model
## (car_height.gd, hop()) takes off straight up at the tier's takeoff_speed from
## power_ups.json, and everything after is the existing air: gravity, landing,
## the ground's sides met at height, the airtime and air-spin tricks.
##
## At tier 0 it does nothing at all: Space changes nothing in the car.
##
## The car (car.gd) calls step() once per physics step, before the model's own
## update, with whether Space was pressed since the last step.
## Proposals (Drifting, Content, "Jump (task T-461)"), constants here:
## - only on the ground: a press in the air does nothing (no double jump), and
##   is not kept for the landing;
## - the tier's cooldown_seconds count from the takeoff, in the air too; a
##   press while it runs does nothing and is not kept.

const PowerUpDataScript := preload("res://scripts/data/power_up_data.gd")

const ID := "jump"

## The car hopped: vertical speed at takeoff, units/s.
signal jumped(takeoff_speed: float)

## Owned tier, 0 = not owned.
var tier := 0
## The tier's numbers (0 when not owned).
var takeoff_speed := 0.0
var cooldown_seconds := 0.0
## Seconds of cooldown left; a hop needs it at 0.
var cooldown_left := 0.0
## How many hops (tests, effects).
var hops := 0

var _data = null


## Sets the owned tier (0 = not owned) and reads its numbers.
func set_tier(new_tier: int, data = null) -> void:
	tier = maxi(new_tier, 0)
	if tier == 0:
		takeoff_speed = 0.0
		cooldown_seconds = 0.0
		cooldown_left = 0.0
		return
	if data != null:
		_data = data
	if _data == null:
		_data = PowerUpDataScript.new()
	var t: Dictionary = _data.at(ID, tier)
	takeoff_speed = maxf(float(t.get("takeoff_speed", 0.0)), 0.0)
	cooldown_seconds = maxf(float(t.get("cooldown_seconds", 0.0)), 0.0)
	cooldown_left = minf(cooldown_left, cooldown_seconds)


func is_owned() -> bool:
	return tier > 0


## Forgets a running cooldown (the wreck, a new car).
func reset() -> void:
	cooldown_left = 0.0


## The hop's time in the air on flat ground with gravity g (units/s^2), seconds
## (the closed form; the 50 Hz steps land within a step of it).
static func airtime_for(vz: float, g: float) -> float:
	return 2.0 * vz / g if g > 0.0 else 0.0


## The hop's peak above the takeoff height, units (closed form).
static func peak_for(vz: float, g: float) -> float:
	return vz * vz / (2.0 * g) if g > 0.0 else 0.0


## One physics step. pressed: Space was pressed since the last step. Returns
## true when the car hopped. Nothing at all when the power-up is not owned.
func step(height_model, pressed: bool, dt: float) -> bool:
	if tier <= 0:
		return false
	cooldown_left = maxf(cooldown_left - dt, 0.0)
	if not pressed or cooldown_left > 0.0 or height_model.airborne:
		return false
	if not height_model.hop(takeoff_speed):
		return false
	cooldown_left = cooldown_seconds
	hops += 1
	jumped.emit(takeoff_speed)
	return true


## Task T-541 (rail grinding; the board's quick tuning 2, 2026-11-06): a Jump off a rail. It hops
## like step() at the tier's takeoff speed, but ignores the cooldown and leaves it as it was (it
## neither starts nor extends it), so a Jump off a rail always fires and the next rail can be
## jumped off at once; off the rails the regular Jump keeps its cooldown. Nothing when not owned.
## Returns true when the car hopped.
func hop_off_rail(height_model) -> bool:
	if tier <= 0:
		return false
	if not height_model.hop(takeoff_speed):
		return false
	hops += 1
	jumped.emit(takeoff_speed)
	return true
