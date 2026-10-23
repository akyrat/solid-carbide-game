extends RefCounted
## The car's driving and drift physics, copied step by step from the board's
## Unity prototype (Unity prototype report, section 4). Pure maths, no nodes, so
## tests can run it step by step.
##
## World: flat top-down, Godot axes (x right, y down), in units (1 unit = the
## car's width). rotation is in radians, 0 = nose along +x, growing clockwise on
## screen. Unity's angle grows counter-clockwise with 0 = nose up, so A
## (counter-clockwise) subtracts from rotation here.
##
## Velocity and rotation are kept as 64-bit floats (not Vector2, which is 32-bit).

const CarTuning := preload("res://scripts/driving/car_tuning.gd")

## Below this many units/s from cruise speed, a forward speed counts as being at
## cruise speed. See CRUISE_EPSILON in the Result notes of task T-012: without
## it, rounding (forward read back as 10.999999999999998 after being set to 11)
## makes W snap to cruise every step at some headings and never climb.
const CRUISE_EPSILON := 1e-9

## Emitted when W makes the forward speed jump up to cruise speed (from a
## standstill, from coasting below cruise, or from reversing). from_speed is the
## forward speed before the jump; w_just_pressed is true when W was not held on
## the step before. While W and A or D are held the slide pulls the forward
## speed below cruise, so the jump also happens on most steps of a held drift
## (with w_just_pressed false).
signal cruise_jump(from_speed: float, w_just_pressed: bool)

var tuning = CarTuning.new()
## Length of one physics step in seconds (50 steps per second).
var dt := 0.02

var x := 0.0
var y := 0.0
var vx := 0.0
var vy := 0.0
## Starts nose up, like the Unity car.
var rotation := -PI / 2.0
## The coded drift amount, 0 to 1 (report section 4, step 2).
var drift_amount := 0.0
## True while W or S is held together with A or D.
var is_drifting := false
## True while the car is in the air (task T-219, the board's tweaks): car.gd
## sets it before each step from the car's height model. In the air the
## velocity is kept as it is and the keys only spin the body, at
## tuning.air_turn_multiplier times the ground rate; on the ground nothing
## changes.
var airborne := false
## The side slip out of a drift (task T-278, Drifting, Decisions, "A little side
## slip out of a drift"): the extra turn the body still has after a drift ends,
## in degrees per second, signed like steer (positive = turning the way A
## turns). 0 = no slip. It fades to 0 in tuning.exit_slip_seconds, faster while
## the player counter-steers; it is only ever on the ground.
var exit_slip := 0.0

var _w_was_held := false
## The slip's size when it started (degrees per second), for its straight-line fade.
var _exit_slip_start := 0.0
## Steer on the step before (for the direction a drift was turning when it ended).
var _last_steer := 0.0


func get_position() -> Vector2:
	return Vector2(x, y)


func set_position(p: Vector2) -> void:
	x = p.x
	y = p.y


func get_velocity() -> Vector2:
	return Vector2(vx, vy)


func set_velocity(v: Vector2) -> void:
	vx = v.x
	vy = v.y


## Forward speed: along the nose. Negative = moving backwards.
func forward_speed() -> float:
	return vx * cos(rotation) + vy * sin(rotation)


## Sideways speed: across the nose, positive to the car's right.
func sideways_speed() -> float:
	return -vx * sin(rotation) + vy * cos(rotation)


func total_speed() -> float:
	return sqrt(vx * vx + vy * vy)


## Angle between the nose and the direction of travel, in degrees
## (positive = sliding to the car's right).
func drift_angle_deg() -> float:
	var f := forward_speed()
	var s := sideways_speed()
	if absf(f) < 1e-9 and absf(s) < 1e-9:
		return 0.0
	return rad_to_deg(atan2(s, f))


## One full physics step: steer, drive, grip, then move. w = W held, s = S held,
## steer = +1 for A, -1 for D, 0 for none.
func step(w: bool, s: bool, steer: float) -> void:
	update_velocity(w, s, steer)
	x += vx * dt
	y += vy * dt


## Everything in one step except moving the car: sets the new velocity and
## rotation. The car node then moves the body with this velocity.
func update_velocity(w: bool, s: bool, steer: float) -> void:
	var t = tuning
	# Step 1. Input: S counts only when W is not held.
	var reverse := s and not w
	var w_just_pressed := w and not _w_was_held
	_w_was_held = w

	# In the air (task T-219, board: no drifting in the air): the car keeps the
	# speed and direction it took off with. The keys only spin the body, at the
	# air turn rate; no speeding up, braking, steering of the path, grip or
	# drift. It is not drifting, so the drift amount fades as it does whenever
	# the car stops drifting. Driving resumes from the landing step on.
	if airborne:
		is_drifting = false
		# No side slip in the air (task T-278): a slip that was running stops.
		_clear_exit_slip()
		_last_steer = steer
		drift_amount = move_toward(drift_amount, 0.0, maxf(0.0, t.drift_exit_rate) * dt)
		rotation -= deg_to_rad(steer * t.turn_rate_for(true) * dt)
		return

	# Step 2. Drift amount.
	var was_drifting := is_drifting
	is_drifting = (w or reverse) and absf(steer) > 0.01
	var rate: float = t.drift_enter_rate if is_drifting else t.drift_exit_rate
	drift_amount = move_toward(drift_amount, 1.0 if is_drifting else 0.0, maxf(0.0, rate) * dt)

	# Step 2b (task T-278). The side slip out of a drift: the extra turn this
	# step, degrees per second, signed like steer.
	var slip := _exit_slip_turn(was_drifting, steer)

	# Step 3. Steer. The new angle only applies after this step's velocity is
	# built (Unity's MoveRotation), so the velocity lags the body by one step.
	var new_rotation := rotation - deg_to_rad((steer * t.turn_rate_for(airborne) + slip) * dt)

	# Step 4. Split the velocity along the current (old) heading.
	var c := cos(rotation)
	var sn := sin(rotation)
	var fwd := vx * c + vy * sn
	var side := -vx * sn + vy * c

	# Step 5. New forward speed.
	var cruise: float = t.forward_speed
	var top: float = t.top_speed()
	var ramp: float = t.ramp_delta(dt)
	if w:
		if fwd < cruise - CRUISE_EPSILON:
			cruise_jump.emit(fwd, w_just_pressed)
			fwd = cruise
		else:
			fwd = move_toward(fwd, top, ramp)
	elif reverse:
		if fwd > 0.0:
			fwd = move_toward(fwd, 0.0, ramp)
		elif fwd > -cruise + CRUISE_EPSILON:
			fwd = -cruise
		else:
			fwd = move_toward(fwd, -top, ramp)
	else:
		fwd = move_toward(fwd, 0.0, t.coast_delta(dt))

	# Step 6. Sideways grip.
	side *= sideways_grip(fwd)

	# Step 7. Write the velocity back (still on the old heading).
	vx = c * fwd - sn * side
	vy = sn * fwd + c * side
	rotation = new_rotation


## The side slip out of a drift (task T-278; game/README.md, "Side slip out of
## a drift"). Returns this step's extra body turn in degrees per second, signed
## like steer, and fades the slip. Called once per ground step, after is_drifting
## is set for this step.
##
## When a drift ends because A or D is let go (W or S may still be held), the
## body does not stop turning dead: it keeps turning the same way at
## tuning.exit_slip_turn x the turn rate, scaled by how sideways the car was
## (the square of its drift angle over tuning.exit_slip_full_angle, capped at
## 1, so small steering touches barely slip), and that extra turn fades in a
## straight line to 0 in tuning.exit_slip_seconds. It starts only when the
## drift's turn was swinging the car's tail out (making the slide bigger), so a
## turn that was already straightening the car never slips. Counter-steering
## (A or D against the slip) fades it tuning.exit_slip_catch times faster;
## steering the slip's own way ends it (the player is turning that way anyway).
## Its whole extra turn is at most turn rate x exit_slip_turn x
## (exit_slip_seconds + one step) / 2 degrees (14.1 at the defaults, 55 at the
## sliders' ends), so with no input it always settles and never spins the car.
func _exit_slip_turn(was_drifting: bool, steer: float) -> float:
	var t = tuning
	var steer_sign := _sign_of(steer)
	var last_sign := _sign_of(_last_steer)
	_last_steer = steer
	if was_drifting and not is_drifting and steer_sign == 0.0:
		_start_exit_slip(last_sign)
	if exit_slip != 0.0 and steer_sign == signf(exit_slip):
		_clear_exit_slip()
	if exit_slip == 0.0:
		return 0.0
	var turn := exit_slip
	var fade := _exit_slip_start / maxf(0.01, float(t.exit_slip_seconds)) * dt
	if steer_sign == -signf(exit_slip):
		fade *= maxf(1.0, float(t.exit_slip_catch))
	exit_slip = move_toward(exit_slip, 0.0, fade)
	if exit_slip == 0.0:
		_exit_slip_start = 0.0
	return turn


## Starts the slip for a drift that ended turning the way dir (+1 = A, -1 = D).
func _start_exit_slip(dir: float) -> void:
	var t = tuning
	_clear_exit_slip()
	var share := clampf(float(t.exit_slip_turn), 0.0, 1.0)
	if share <= 0.0 or dir == 0.0:
		return
	var f := forward_speed()
	var s := sideways_speed()
	# Turning by dir changes the sideways speed by forward x dir (per radian):
	# the slip only carries on a turn that was making the slide bigger.
	if s * f * dir <= 0.0:
		return
	var angle := rad_to_deg(atan2(absf(s), absf(f)))
	var k := clampf(angle / maxf(1.0, float(t.exit_slip_full_angle)), 0.0, 1.0)
	exit_slip = dir * share * t.turn_rate() * k * k
	_exit_slip_start = absf(exit_slip)


func _clear_exit_slip() -> void:
	exit_slip = 0.0
	_exit_slip_start = 0.0


static func _sign_of(steer: float) -> float:
	return signf(steer) if absf(steer) > 0.01 else 0.0


## Share of sideways speed kept this step (report section 4, step 6). Unity
## clamps the three grip values to 0..1.
func sideways_grip(fwd: float) -> float:
	var t = tuning
	var speed01 := clampf(absf(fwd) / maxf(0.01, t.drift_speed_reference), 0.0, 1.0)
	var low := clampf(t.drift_grip_low_speed, 0.0, 1.0)
	var high := clampf(t.drift_grip_high_speed, 0.0, 1.0)
	var base := clampf(t.drift_factor, 0.0, 1.0)
	var grip_at_speed := lerpf(low, high, speed01)
	return lerpf(base, grip_at_speed, clampf(drift_amount, 0.0, 1.0))
