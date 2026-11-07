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
## - no cooldown (T-551; the board, 2026-11-07, Drifting, Decisions, "Jump has no
##   cooldown"): a press on the ground always hops, at either tier, so the car can
##   jump again as soon as it is back on the ground. Tier 2 keeps its higher takeoff.
## Leaving a rail is not this power-up's any more (T-551, the grind overhaul): any
## car releases Space on a rail to launch (car.gd _leave_grind).

const PowerUpDataScript := preload("res://scripts/data/power_up_data.gd")

const ID := "jump"

## The car hopped: vertical speed at takeoff, units/s.
signal jumped(takeoff_speed: float)

## Owned tier, 0 = not owned.
var tier := 0
## The tier's numbers (0 when not owned).
var takeoff_speed := 0.0
## How many hops (tests, effects).
var hops := 0

var _data = null


## Sets the owned tier (0 = not owned) and reads its numbers.
func set_tier(new_tier: int, data = null) -> void:
	tier = maxi(new_tier, 0)
	if tier == 0:
		takeoff_speed = 0.0
		return
	if data != null:
		_data = data
	if _data == null:
		_data = PowerUpDataScript.new()
	var t: Dictionary = _data.at(ID, tier)
	takeoff_speed = maxf(float(t.get("takeoff_speed", 0.0)), 0.0)


func is_owned() -> bool:
	return tier > 0


## The hop's time in the air on flat ground with gravity g (units/s^2), seconds
## (the closed form; the 50 Hz steps land within a step of it).
static func airtime_for(vz: float, g: float) -> float:
	return 2.0 * vz / g if g > 0.0 else 0.0


## The hop's peak above the takeoff height, units (closed form).
static func peak_for(vz: float, g: float) -> float:
	return vz * vz / (2.0 * g) if g > 0.0 else 0.0


## One physics step. pressed: Space was pressed since the last step. Returns
## true when the car hopped. Nothing at all when the power-up is not owned.
func step(height_model, pressed: bool, _dt: float) -> bool:
	if tier <= 0:
		return false
	if not pressed or height_model.airborne:
		return false
	if not height_model.hop(takeoff_speed):
		return false
	hops += 1
	jumped.emit(takeoff_speed)
	return true

