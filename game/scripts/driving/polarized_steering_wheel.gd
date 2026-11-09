extends RefCounted
## The Polarized Steering Wheel (task T-502; T-603: Drifting, Decisions, "The Polarized
## Steering Wheel bursts after an alternate drift"; how it behaves: Drifting, Content,
## "The Polarized Steering Wheel"). With the power-up owned (tier > 0), each alternate
## drift the trick system pays (ALT DRIFT!) gives the car a short speed burst, on the
## ground and outside the cooldown. Tier 2 also sets off an impact shock where the car
## is (the `shock` signal; the run sends Bricks' tier 1 wave there, polarized_shock.gd).
## The old trigger (let go of W, steer, press W) is gone (T-603).
##
## At tier 0 it does nothing at all.
##
## The burst scales the car's whole velocity: the car moves `factor` times as fast as
## it would have without the wheel, along its travel, whichever way the nose points (a
## switch into a backward drift pushes the car the way it moves, not the way it faces).
## The factor jumps to `burst_speed_multiplier` at the payout, holds `burst_seconds`,
## then falls back to 1 in a straight line over `fade_seconds`: the car ends at exactly
## the speed it would have had. The car (car.gd) calls before_step() before the model's
## update_velocity() (it takes the factor out, so the model drives the speed the car
## would have had) and step() right after it (it puts the factor back in).
## on_alternate_drift() is called when the trick detector pays an alternate drift.
##
## Cooldown (T-527): a burst starts a cooldown of `cooldown_seconds`; while it runs an
## alternate drift gives no burst. The HUD draws it with cooldown_fraction_left() /
## is_ready() / ready_again (T-528).

const PowerUpDataScript := preload("res://scripts/data/power_up_data.gd")

const ID := "polarized_steering_wheel"
const EPS := 1e-6

## A burst began: speed = the car's speed with the burst (units/s), seconds = its hold,
## direction = the unit direction of travel at the payout (the way the burst pushes;
## the nose's direction when the car stood still).
signal fired(speed: float, seconds: float, direction: Vector2)
## The burst has faded out, or a wall hit, a rail or the wreck ended it.
signal burst_ended
## The cooldown ran out: the next alternate drift gives a burst again (T-528 fills the slot icon).
signal ready_again
## Tier 2: a burst went off at `centre` (flat world, units): the shock's place.
signal shock(centre: Vector2)

## Owned tier, 0 = not owned.
var tier := 0
## The tier's numbers.
var burst_speed_multiplier := 1.0
var burst_seconds := 0.0
## Seconds the factor takes to fall back from the multiplier to 1 after the hold (T-603).
var fade_seconds := 0.0
## Seconds between bursts, counted from the burst (T-527).
var cooldown_seconds := 0.0
## Bricks' tier whose wave the burst sets off (0 = none; tier 2: 1).
var shock_bricks_tier := 0

## Seconds of the hold left; > 0 while the full burst is held.
var burst_left := 0.0
## Seconds of the fade left; > 0 while the burst fades out (counted after the hold).
var fade_left := 0.0
## The burst's length, hold and fade (burst_fraction_left()).
var burst_total := 0.0
## The factor the car's velocity carries now (1 = no burst).
var factor := 1.0
## The car's speed with the burst at the payout.
var burst_speed := 0.0
## The direction of travel at the last payout (unit vector, flat world).
var burst_direction := Vector2.RIGHT
## Seconds of cooldown left; > 0 while the wheel is reloading.
var cooldown_left := 0.0
## Bursts and shocks so far (tests, effects).
var bursts_fired := 0
var shocks_sent := 0
## Alternate drifts paid while owned, burst or not (tests, the speed bot).
var alternate_drifts := 0

var _data = null


## Sets the owned tier (0 = not owned) and reads its numbers. Dropping to 0 ends a burst.
func set_tier(new_tier: int, data = null) -> void:
	if data != null:
		_data = data
	if _data == null:
		_data = PowerUpDataScript.new()
	tier = clampi(new_tier, 0, _data.max_tier(ID))
	if tier == 0:
		burst_speed_multiplier = 1.0
		burst_seconds = 0.0
		fade_seconds = 0.0
		cooldown_seconds = 0.0
		shock_bricks_tier = 0
		reset()
		return
	var t: Dictionary = _data.at(ID, tier)
	burst_speed_multiplier = maxf(float(t.get("burst_speed_multiplier", 1.0)), 1.0)
	burst_seconds = maxf(float(t.get("burst_seconds", 0.0)), 0.0)
	fade_seconds = maxf(float(t.get("fade_seconds", 0.0)), 0.0)
	cooldown_seconds = maxf(float(t.get("cooldown_seconds", 0.0)), 0.0)
	shock_bricks_tier = maxi(int(t.get("shock_bricks_tier", 0)), 0)


func is_owned() -> bool:
	return tier > 0


## True while the burst is held or fading (the factor is above 1).
func is_bursting() -> bool:
	return burst_left > 0.0 or fade_left > 0.0


## True during the fade after the hold.
func is_fading() -> bool:
	return burst_left <= 0.0 and fade_left > 0.0


## Share of the running burst (hold and fade) still to go, 1 -> 0 (0 when not bursting).
func burst_fraction_left() -> float:
	if burst_total <= 0.0:
		return 0.0
	return clampf((burst_left + fade_left) / burst_total, 0.0, 1.0)


## True when an alternate drift would give a burst (no cooldown running).
func is_ready() -> bool:
	return cooldown_left <= 0.0


## Share of the cooldown still to go, 1 just after a burst -> 0 when ready.
func cooldown_fraction_left() -> float:
	if cooldown_seconds <= 0.0:
		return 0.0
	return clampf(cooldown_left / cooldown_seconds, 0.0, 1.0)


## Drops any burst and the cooldown (the wreck, a new car).
func reset() -> void:
	cooldown_left = 0.0
	end_burst()


## Ends a running burst at once (a wall hit, a rail, the wreck). The car keeps the
## velocity it has now: from here on the model drives it as its own.
func end_burst() -> void:
	var was := is_bursting()
	burst_left = 0.0
	fade_left = 0.0
	burst_total = 0.0
	factor = 1.0
	if was:
		burst_ended.emit()


## Call before model.update_velocity(): takes the burst out of the velocity, so the
## model drives the speed the car would have had.
func before_step(model) -> void:
	if factor != 1.0:
		model.vx /= factor
		model.vy /= factor


## One physics step, after model.update_velocity(): counts the cooldown, the hold and
## the fade down and puts the burst's factor back into the velocity.
func step(model, dt: float) -> void:
	if cooldown_left > 0.0:
		cooldown_left = maxf(cooldown_left - dt, 0.0)
		if cooldown_left <= 0.0:
			ready_again.emit()
	if not is_bursting():
		factor = 1.0
		return
	var left := dt
	if burst_left > 0.0:
		var used := minf(left, burst_left)
		burst_left -= used
		left -= used
		if burst_left <= EPS:
			burst_left = 0.0
	if burst_left <= 0.0 and left > 0.0:
		fade_left = maxf(fade_left - left, 0.0)
	if fade_left <= EPS:
		fade_left = 0.0
	factor = factor_now()
	model.vx *= factor
	model.vy *= factor
	if not is_bursting():
		factor = 1.0
		burst_total = 0.0
		burst_ended.emit()


## The factor for the burst's place now: the multiplier during the hold, then a
## straight line down to 1 over the fade.
func factor_now() -> float:
	if burst_left > 0.0:
		return burst_speed_multiplier
	if fade_left > 0.0 and fade_seconds > 0.0:
		return 1.0 + (burst_speed_multiplier - 1.0) * fade_left / fade_seconds
	return 1.0


## The trick detector paid an alternate drift (car.gd connects it). On the ground and
## outside the cooldown it starts a burst at once: the velocity is scaled on this step.
func on_alternate_drift(model, airborne: bool, centre := Vector2.ZERO) -> void:
	if tier <= 0:
		return
	alternate_drifts += 1
	if airborne or cooldown_left > 0.0:
		return
	var base := Vector2(model.vx, model.vy) / factor  # the speed the car would have had
	if base.length() > EPS:
		burst_direction = base.normalized()
	else:
		burst_direction = Vector2.from_angle(model.rotation)
	factor = burst_speed_multiplier
	model.vx = base.x * factor
	model.vy = base.y * factor
	burst_left = burst_seconds
	fade_left = fade_seconds
	burst_total = burst_seconds + fade_seconds
	burst_speed = base.length() * factor
	bursts_fired += 1
	cooldown_left = cooldown_seconds
	fired.emit(burst_speed, burst_seconds, burst_direction)
	if shock_bricks_tier > 0:
		shocks_sent += 1
		shock.emit(centre)
