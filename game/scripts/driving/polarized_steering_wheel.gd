extends RefCounted
## The Polarized Steering Wheel (task T-502; Drifting, Decisions, "Rusty Paintjob
## and the Polarized Steering Wheel"; how it behaves: Drifting, Content, "The
## Polarized Steering Wheel (task T-502)"). With the power-up owned (tier > 0):
## let go of W (a coast), steer, then press W again with the car's nose at least
## `min_angle_degrees` away from the direction the car is moving, and the car gets
## a short speed burst. Tier 4 also sets off an impact shock where the car is
## (the `shock` signal; the run sends Bricks' tier 1 wave there, polarized_shock.gd).
##
## At tier 0 it does nothing at all.
##
## The car (car.gd) calls before_step() before the model's update_velocity() (it
## remembers the velocity and heading the press is judged on) and step() right
## after it. It only reads and writes the model's velocity along that heading:
## while bursting, on the ground, the forward speed is held at least at the burst
## speed; afterwards the car slows back to its top speed on its own (W's ramp).
##
## The rules (every number from power_ups.json, proposals for the playtest):
## - a coast starts on the step W is let go (on the ground or in the air) and lasts
##   while W stays up; S held during it cancels it (braking or reversing is not a
##   coast, so a reverse then W is no burst);
## - W pressed again counts when the coast is at most `max_coast_seconds` long, the
##   car is on the ground, moving at least `min_speed` units/s, with its nose at
##   least `min_angle_degrees` from its direction of travel;
## - the burst: forward speed held at least at `burst_speed_multiplier` x the speed
##   the car carried into the press (cruise speed at the least) for `burst_seconds`;
## - cooldown (T-527): a burst starts a cooldown of `cooldown_seconds`; while it runs a
##   trigger gives no burst (the coast is still spent). The HUD draws it with
##   cooldown_fraction_left() / is_ready() / ready_again (T-528).

const PowerUpDataScript := preload("res://scripts/data/power_up_data.gd")

const ID := "polarized_steering_wheel"
const EPS := 1e-6

## A burst began: speed = the forward speed held (units/s), seconds = its length,
## angle_deg = the angle between nose and travel that earned it.
signal fired(speed: float, seconds: float, angle_deg: float)
## The burst's time is over, or a wall hit or the wreck ended it.
signal burst_ended
## The cooldown ran out: the next trigger gives a burst again (T-528 fills the slot icon).
signal ready_again
## Tier 4: a burst went off at `centre` (flat world, units): the shock's place.
signal shock(centre: Vector2)

## Owned tier, 0 = not owned.
var tier := 0
## The tier's numbers.
var burst_speed_multiplier := 1.0
var burst_seconds := 0.0
var min_angle_degrees := 60.0
var max_coast_seconds := 0.0
var min_speed := 0.0
## Seconds between bursts, counted from the burst (T-527).
var cooldown_seconds := 0.0
## Bricks' tier whose wave the burst sets off (0 = none; tier 4: 1).
var shock_bricks_tier := 0

## Seconds of the coast so far; < 0 when there is no coast to count.
var coast := -1.0
## Seconds of burst left; > 0 while bursting.
var burst_left := 0.0
var burst_total := 0.0
## The forward speed the running burst holds.
var burst_speed := 0.0
## Seconds of cooldown left; > 0 while the wheel is reloading.
var cooldown_left := 0.0
## Bursts and shocks so far (tests, effects).
var bursts_fired := 0
var shocks_sent := 0
## The angle (degrees) of the last press of W after a coast, burst or not (tests, tuning).
var last_press_angle := 0.0

var _data = null
var _w_was := false
## The velocity and heading at the start of this step (before_step).
var _v_before := Vector2.ZERO
var _heading_before := 0.0


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
		cooldown_seconds = 0.0
		shock_bricks_tier = 0
		reset()
		return
	var t: Dictionary = _data.at(ID, tier)
	burst_speed_multiplier = maxf(float(t.get("burst_speed_multiplier", 1.0)), 1.0)
	burst_seconds = maxf(float(t.get("burst_seconds", 0.0)), 0.0)
	min_angle_degrees = clampf(float(t.get("min_angle_degrees", 60.0)), 0.0, 180.0)
	max_coast_seconds = maxf(float(t.get("max_coast_seconds", 0.0)), 0.0)
	min_speed = maxf(float(t.get("min_speed", 0.0)), 0.0)
	cooldown_seconds = maxf(float(t.get("cooldown_seconds", 0.0)), 0.0)
	shock_bricks_tier = maxi(int(t.get("shock_bricks_tier", 0)), 0)


func is_owned() -> bool:
	return tier > 0


func is_bursting() -> bool:
	return burst_left > 0.0


## Share of the running burst still to go, 1 -> 0 (0 when not bursting).
func burst_fraction_left() -> float:
	if burst_total <= 0.0:
		return 0.0
	return clampf(burst_left / burst_total, 0.0, 1.0)


## True when a trigger would give a burst (no cooldown running).
func is_ready() -> bool:
	return cooldown_left <= 0.0


## Share of the cooldown still to go, 1 just after a burst -> 0 when ready.
func cooldown_fraction_left() -> float:
	if cooldown_seconds <= 0.0:
		return 0.0
	return clampf(cooldown_left / cooldown_seconds, 0.0, 1.0)


## Drops the coast, any burst and the cooldown (the wreck, a new car).
func reset() -> void:
	coast = -1.0
	cooldown_left = 0.0
	end_burst()


## Ends a running burst (a wall hit, the wreck).
func end_burst() -> void:
	if burst_left > 0.0:
		burst_left = 0.0
		burst_total = 0.0
		burst_ended.emit()


## Call before model.update_velocity(): remembers the velocity and heading the
## press of W is judged on.
func before_step(model) -> void:
	_v_before = Vector2(model.vx, model.vy)
	_heading_before = model.rotation


## The angle in degrees (0..180) between a heading (radians) and a velocity.
static func angle_between(heading: float, v: Vector2) -> float:
	if v.length() < EPS:
		return 0.0
	return rad_to_deg(absf(Vector2.from_angle(heading).angle_to(v)))


## One physics step, after model.update_velocity(w, s, steer). heading is the
## rotation the model built this step's velocity on. `centre` is the car's place
## (flat world, units) for the tier 4 shock.
func step(model, w: bool, s: bool, heading: float, airborne: bool, dt: float, centre := Vector2.ZERO) -> void:
	if cooldown_left > 0.0:
		cooldown_left = maxf(cooldown_left - dt, 0.0)
		if cooldown_left <= 0.0:
			ready_again.emit()
	var w_pressed := w and not _w_was
	var w_released := _w_was and not w
	_w_was = w
	if tier <= 0:
		return
	if w_pressed:
		if coast >= 0.0:
			last_press_angle = angle_between(_heading_before, _v_before)
			if cooldown_left <= 0.0 and coast <= max_coast_seconds + EPS and not airborne \
					and _v_before.length() >= min_speed - EPS \
					and last_press_angle >= min_angle_degrees - EPS:
				_fire(model, centre)
		coast = -1.0
	elif not w:
		if s:
			coast = -1.0
		elif w_released:
			coast = 0.0
		elif coast >= 0.0:
			coast += dt
	if burst_left > 0.0:
		if not airborne:
			_hold_forward_at_least(model, heading, burst_speed)
		burst_left = maxf(burst_left - dt, 0.0)
		if burst_left <= 0.0:
			burst_total = 0.0
			burst_ended.emit()


func _fire(model, centre: Vector2) -> void:
	var carried := maxf(_v_before.length(), float(model.tuning.forward_speed))
	burst_speed = carried * burst_speed_multiplier
	burst_total = burst_seconds
	burst_left = burst_seconds
	bursts_fired += 1
	cooldown_left = cooldown_seconds
	fired.emit(burst_speed, burst_seconds, last_press_angle)
	if shock_bricks_tier > 0:
		shocks_sent += 1
		shock.emit(centre)


## Raises the forward speed along heading to at least `speed` (units/s); the
## sideways part is left alone (Rev Charge's rule).
static func _hold_forward_at_least(model, heading: float, speed: float) -> void:
	var c := cos(heading)
	var sn := sin(heading)
	var fwd: float = model.vx * c + model.vy * sn
	if fwd >= speed:
		return
	var side: float = -model.vx * sn + model.vy * c
	model.vx = c * speed - sn * side
	model.vy = sn * speed + c * side
