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
##
## The charged jump (T-590, a playtest; Drifting, Decisions, "A charged jump, for a
## playtest"; how it behaves: Drifting, Content, "The charged jump (task T-590)"): a
## press on the ground starts a charge instead of hopping at once; while Space stays
## held on the ground the charge grows, and the car hops when Space is let go, at
## takeoff_speed x charge_multiplier(): x1 at once, linearly up to x max_multiplier
## after charge_seconds (power_ups.json, jump.charge: 1.5 over 3 s), then held there.
## A tap (pressed and let go at once) hops at x1, as before T-590. Proposals:
## - only a press on the ground starts a charge (a Space held through a landing
##   does not: it is the air's tilt, and a press in the air is still not kept);
## - the car leaving the ground while charging (off a ramp or a roof's edge) drops
##   the charge with no hop; Space is then the air's (tilt and grind) as before;
## - the dead keys (input off: the wreck, a pause screen) drop the charge (reset()).

const PowerUpDataScript := preload("res://scripts/data/power_up_data.gd")

const ID := "jump"
const DEFAULT_CHARGE_SECONDS := 3.0
const DEFAULT_MAX_MULTIPLIER := 1.5

## The car hopped: vertical speed at takeoff, units/s.
signal jumped(takeoff_speed: float)

## Owned tier, 0 = not owned.
var tier := 0
## The tier's numbers (0 when not owned).
var takeoff_speed := 0.0
## How many hops (tests, effects).
var hops := 0
## T-590: the charge's numbers (power_ups.json, jump.charge; the same at every tier).
var charge_seconds := DEFAULT_CHARGE_SECONDS
var max_multiplier := DEFAULT_MAX_MULTIPLIER
## T-590: true while Space, pressed on the ground, is held there (the charge grows).
var charging := false
## T-590: seconds held so far in this charge.
var charge_time := 0.0
## T-590: the multiplier of the last hop (1 for a tap; tests, readouts).
var last_multiplier := 1.0

var _data = null


## Sets the owned tier (0 = not owned) and reads its numbers.
func set_tier(new_tier: int, data = null) -> void:
	tier = maxi(new_tier, 0)
	if tier == 0:
		takeoff_speed = 0.0
		reset()
		return
	if data != null:
		_data = data
	if _data == null:
		_data = PowerUpDataScript.new()
	var t: Dictionary = _data.at(ID, tier)
	takeoff_speed = maxf(float(t.get("takeoff_speed", 0.0)), 0.0)
	var c: Dictionary = _data.jump_charge() if _data.has_method("jump_charge") else {}
	charge_seconds = maxf(float(c.get("charge_seconds", DEFAULT_CHARGE_SECONDS)), 0.001)
	max_multiplier = maxf(float(c.get("max_multiplier", DEFAULT_MAX_MULTIPLIER)), 1.0)


func is_owned() -> bool:
	return tier > 0


## The hop's time in the air on flat ground with gravity g (units/s^2), seconds
## (the closed form; the 50 Hz steps land within a step of it).
static func airtime_for(vz: float, g: float) -> float:
	return 2.0 * vz / g if g > 0.0 else 0.0


## The hop's peak above the takeoff height, units (closed form).
static func peak_for(vz: float, g: float) -> float:
	return vz * vz / (2.0 * g) if g > 0.0 else 0.0


## T-590: the takeoff multiplier for a charge held `seconds`: 1 at 0, linearly up to
## max_multiplier at charge_seconds, then held there.
func multiplier_for(seconds: float) -> float:
	return 1.0 + (max_multiplier - 1.0) * clampf(seconds / charge_seconds, 0.0, 1.0)


## T-590: how full the charge is now, 0 to 1 (0 when not charging; the cue reads it).
func charge_fraction() -> float:
	return clampf(charge_time / charge_seconds, 0.0, 1.0) if charging else 0.0


## T-590: drops a charge in progress (no hop).
func reset() -> void:
	charging = false
	charge_time = 0.0


## One physics step. pressed: Space was pressed since the last step; held: Space is
## held now (T-590: a charge grows while it is, and the hop comes when it is let go;
## held false with pressed true is a tap, which hops this step at x1). Returns true
## when the car hopped. Nothing at all when the power-up is not owned.
func step(height_model, pressed: bool, dt: float, held: bool = false) -> bool:
	if tier <= 0:
		reset()
		return false
	if height_model.airborne:
		reset()  # off the ground while charging: the charge is dropped (no hop)
		return false
	if pressed and not charging:
		charging = true
		charge_time = 0.0
	if charging and held:  # every step Space is held counts, the press's own step too
		charge_time += dt
	if not charging or held:
		return false
	var m := multiplier_for(charge_time)
	reset()
	var vz := takeoff_speed * m
	if not height_model.hop(vz):
		return false
	last_multiplier = m
	hops += 1
	jumped.emit(vz)
	return true

