extends RefCounted
## The car's handling values, copied from the board's Unity prototype.
##
## Defaults are the "Value in project files (used)" column of the Unity prototype
## report, section 5 (docs/drifting/unity-prototype-report.md), except top speed
## multiplier, which the board set to 3.0 after playtesting (Drifting, Decisions,
## 2026-10-09). UNITY keeps the Unity values for reference. SETTINGS lists the
## tuning sliders from the report's section 8 ("Proposed settings for the Godot
## prototype"), except off-road damping and the physics rate.
##
## Speeds are in units per second; one unit is the car's width (and the length of
## its 1 x 1 physics body).

## Speed W snaps to instantly; base for top speed (units/s).
var forward_speed := 11.0
## Body rotation rate before the sensitivity multiplier (degrees/s).
var turn_speed := 202.0
## Top speed = forward_speed * top_speed_multiplier.
var top_speed_multiplier := 1.5
## Sets the ramp rate top / time, used for speeding up, braking and reverse (s).
var time_to_top_speed := 2.3
## Coasting loses top speed * this per second.
var coast_decel_multiplier := 0.3
## Rotation rate = turn_speed * steer_sensitivity.
var steer_sensitivity := 0.95
## Sideways speed kept per physics step when not drifting.
var drift_factor := 0.98
## Sideways speed kept per step while fully drifting, at low speed.
var drift_grip_low_speed := 0.98
## Same, at or above drift_speed_reference.
var drift_grip_high_speed := 0.98
## Forward speed where the high-speed drift grip fully applies (units/s).
var drift_speed_reference := 20.0
## How fast the drift amount rises to 1 (per s).
var drift_enter_rate := 12.0
## How fast the drift amount falls to 0 (per s).
var drift_exit_rate := 3.0
## How much of its speed into a wall or boulder the car keeps, bouncing back
## off it (0 = no bounce, it slides along; 1 = full bounce). Not from the Unity
## prototype (no bounce there); proposed for the board's playtest (task T-033).
var wall_bounce := 0.25
## The side slip out of a drift (task T-278, board 2026-10-22; Drifting,
## Decisions, "A little side slip out of a drift"; car_model.gd,
## _exit_slip_turn). Proposals for the board's own playtest; not from the Unity
## prototype, where the body stops turning dead the moment A or D is let go
## (UNITY sets the slip off, so reset_to_unity gives the Unity car exactly).
## How hard the body keeps turning when a drift ends, as a share of the turn
## rate (191.9 deg/s), for a full sideways drift. Proposed 0.35: 67 deg/s.
var exit_slip_turn := 0.35
## Seconds the slip takes to fade to nothing with no input. Proposed 0.4: with
## 0.35 the body turns about 14 degrees more after a full drift, a little
## over half of one of the car sprite's 16 directions (22.5 degrees).
var exit_slip_seconds := 0.4
## How many times faster counter-steering fades the slip. Proposed 4: caught
## within 0.1 s (5 physics steps).
var exit_slip_catch := 4.0
## The drift angle (degrees) that gives the full slip. Below it the slip
## shrinks with the square of the angle, so small steering touches barely
## slip. Proposed 60: a held drift settles at about 68 degrees.
var exit_slip_full_angle := 60.0
## Alternate-drift trick (task T-079; trick_detector.gd). Proposed limits for
## the board to tune; not from the Unity prototype, and they never change how
## the car drives.
## Longest time between the end of one drift and the start of the opposite one
## (forward to backward or back), in seconds.
var alternate_max_switch_seconds := 0.5
## Shortest time each of the two drifts must last, in seconds. The trick fires
## when the new drift reaches it.
var alternate_min_drift_seconds := 0.3
## When true, A or D must stay held on the same side during the switch.
var alternate_keep_steering := true
## Turning in the air (task T-219, board 2026-10-21: the car turns faster in
## the air than on the ground, so an air 360 fits in a jump off the tallest
## rooftop). The body's rotation rate while airborne, as a multiple of the
## ground rate (turn_rate()). Proposed 2.5: 479.75 deg/s, 9.6 degrees a
## physics step, so a 360 takes 38 steps (0.76 s) of the 49 a fall off a
## height-6 rooftop counts, leaving about 0.2 s to spare, and a 180 takes 19
## (0.38 s). Ground steering is unchanged.
var air_turn_multiplier := 2.5

## The acceleration garage upgrade (task T-060): sets the time to top speed to
## the upgrade's value at the player's saved level (level 0 is the base, 2.3 s,
## the same as the default). Only the run calls it; the drift prototype never
## does, so it keeps its own tuning.
func apply_acceleration_upgrade(progress: PlayerProgress) -> void:
	time_to_top_speed = progress.current_value("acceleration")


## The Unity prototype's values, by setting key (report section 5).
const UNITY := {
	"forward_speed": 11.0,
	"turn_speed": 202.0,
	"top_speed_multiplier": 2.5,
	"time_to_top_speed": 2.3,
	"coast_decel_multiplier": 0.3,
	"steer_sensitivity": 0.95,
	"drift_factor": 0.98,
	"drift_grip_low_speed": 0.98,
	"drift_grip_high_speed": 0.98,
	"drift_speed_reference": 20.0,
	"drift_enter_rate": 12.0,
	"drift_exit_rate": 3.0,
	# Task T-278: the Unity car has no side slip out of a drift.
	"exit_slip_turn": 0.0,
}

## One entry per slider. "key" is the property above. "label" is the
## plain-language label from the report's section 8; "name" is the setting's
## name there. "tip" explains the slider for its tooltip.
const SETTINGS := [
	{"key": "forward_speed", "name": "Cruise speed", "unit": "units/s",
		"label": "Speed you jump to when you press W",
		"tip": "W snaps the car straight to this speed, then it climbs to top speed. Also the speed S snaps to when reversing.",
		"min": 4.0, "max": 25.0, "step": 0.1},
	{"key": "top_speed_multiplier", "name": "Top speed multiplier", "unit": "x cruise",
		"label": "Top speed as a multiple of cruise speed",
		"tip": "Top speed = cruise speed x this. Game default: 11 x 1.5 = 16.5 units/s (board experiment 2026-10-14; was 3.0 = 33) (Unity: 11 x 2.5 = 27.5).",
		"min": 1.0, "max": 4.0, "step": 0.05},
	{"key": "time_to_top_speed", "name": "Time to top speed", "unit": "s",
		"label": "Bigger = slower climb from cruise to top, and slower braking",
		"tip": "Sets one rate (top speed / this time) used for speeding up, braking with S and speeding up in reverse.",
		"min": 0.5, "max": 5.0, "step": 0.05},
	{"key": "coast_decel_multiplier", "name": "Coast slowdown", "unit": "x top speed per s",
		"label": "How fast you slow down with no key held",
		"tip": "With no key held the car loses top speed x this, every second, in a straight line. 0 = it never slows down.",
		"min": 0.0, "max": 1.5, "step": 0.01},
	{"key": "turn_speed", "name": "Turn speed", "unit": "deg/s",
		"label": "How fast the car rotates while A or D is held",
		"tip": "The body's rotation rate before the steering sensitivity multiplier. Speed plays no part: the car turns as fast standing still.",
		"min": 60.0, "max": 360.0, "step": 1.0},
	{"key": "steer_sensitivity", "name": "Steering sensitivity", "unit": "x turn speed",
		"label": "Multiplier on turn speed",
		"tip": "Rotation rate = turn speed x this. Unity: 202 x 0.95 = 191.9 deg/s. The Unity prototype kept both values.",
		"min": 0.5, "max": 1.5, "step": 0.01},
	{"key": "drift_factor", "name": "Base sideways grip (drift factor)", "unit": "kept per step",
		"label": "How much of the slide you keep each step when not drifting. Lower = grippier",
		"tip": "The share of sideways speed kept every physics step (50 per second) while not drifting. 1 = the slide never fades, 0.8 = it dies almost at once.",
		"min": 0.8, "max": 1.0, "step": 0.001},
	{"key": "drift_grip_low_speed", "name": "Drift grip, low speed", "unit": "kept per step",
		"label": "Slide kept per step while drifting slowly",
		"tip": "Sideways speed kept per step while drifting (W or S held with A or D) at low forward speed. Lower = grippier.",
		"min": 0.8, "max": 1.0, "step": 0.001},
	{"key": "drift_grip_high_speed", "name": "Drift grip, high speed", "unit": "kept per step",
		"label": "Slide kept per step while drifting fast",
		"tip": "Sideways speed kept per step while drifting at or above the drift speed reference. Lower = grippier.",
		"min": 0.8, "max": 1.0, "step": 0.001},
	{"key": "drift_speed_reference", "name": "Drift speed reference", "unit": "units/s",
		"label": "Speed at which \"high speed\" drift grip fully applies",
		"tip": "Between standstill and this forward speed, drift grip blends from the low-speed to the high-speed value.",
		"min": 5.0, "max": 40.0, "step": 0.5},
	{"key": "drift_enter_rate", "name": "Drift enter rate", "unit": "per s",
		"label": "How fast drift grip takes over when you start drifting",
		"tip": "How fast the drift amount (0 to 1) rises while W or S is held with A or D. 12 = full in 0.08 s.",
		"min": 1.0, "max": 30.0, "step": 0.5},
	{"key": "drift_exit_rate", "name": "Drift exit rate", "unit": "per s",
		"label": "How fast normal grip comes back when you stop",
		"tip": "How fast the drift amount falls back to 0 after you stop drifting. 3 = gone in 0.33 s.",
		"min": 1.0, "max": 30.0, "step": 0.5},
]


## The side slip out of a drift (task T-278). Not part of the Unity prototype;
## the tuning panel shows them in their own group, "Out of a drift". Same
## fields as COLLISION_SETTINGS.
const SLIP_SETTINGS := [
	{"key": "exit_slip_turn", "name": "Side slip: strength", "unit": "x turn rate",
		"label": "Side slip out of a drift: how hard the car keeps turning",
		"tip": "When you let go of A or D to end a drift, the car's tail keeps swinging out a little instead of stopping dead: the body keeps turning the drift's way at this share of the turn rate (191.9 deg/s), then fades to nothing. Catch it with a touch of the other key. Game default 0.35 (67 deg/s). 0 = off, the car stops turning the moment you let go.",
		"unity_note": "Unity: no slip, 0",
		"min": 0.0, "max": 0.75, "step": 0.01},
	{"key": "exit_slip_seconds", "name": "Side slip: length", "unit": "s",
		"label": "Side slip: how long it lasts if you do nothing",
		"tip": "The slip fades in a straight line to nothing in this time with no input, so it always settles on its own. With the default strength, a full drift's slip turns the car about 14 degrees more in 0.4 s. Game default 0.4.",
		"unity_note": "Unity: no slip",
		"min": 0.05, "max": 0.75, "step": 0.01},
	{"key": "exit_slip_catch", "name": "Side slip: catch", "unit": "x faster",
		"label": "Side slip: how much faster counter-steer catches it",
		"tip": "While you hold the key against the slip (D after a left drift, A after a right one), the slip fades this many times faster. Game default 4: caught within 0.1 s. 1 = counter-steer only turns the car, the slip fades at its own pace.",
		"unity_note": "Unity: no slip",
		"min": 1.0, "max": 10.0, "step": 0.5},
	{"key": "exit_slip_full_angle", "name": "Side slip: full at drift angle", "unit": "deg",
		"label": "Side slip: drift angle that gives the full slip",
		"tip": "How sideways the car must be when the drift ends for the full slip. Less sideways gives less slip, with the square of the angle (half this angle = a quarter of the slip), so small steering touches barely slip. A held drift settles at about 68 degrees. Game default 60.",
		"unity_note": "Unity: no slip",
		"min": 10.0, "max": 90.0, "step": 1.0},
]


## Collision settings (task T-033). Not part of the Unity prototype, so they are
## kept apart from SETTINGS and have no Unity value; the tuning panel shows them
## in their own group. Same fields as SETTINGS, plus "unity_note".
const COLLISION_SETTINGS := [
	{"key": "wall_bounce", "name": "Wall bounce", "unit": "x impact speed",
		"label": "How hard the car bounces off walls and boulders",
		"tip": "Share of the speed going into a wall, building or boulder that the car keeps, bouncing back off it. The speed along the wall is kept. 0 = no bounce (it slides along), 1 = it bounces back as fast as it hit. Game default 0.25.",
		"unity_note": "Unity: no bounce, it stops against the wall (0)",
		"min": 0.0, "max": 1.0, "step": 0.01},
]


## Settings for the car in the air (task T-219). Not part of the Unity
## prototype (no height there); the tuning panel shows them in their own group.
## Same fields as COLLISION_SETTINGS.
const AIR_SETTINGS := [
	{"key": "air_turn_multiplier", "name": "Air turn speed", "unit": "x ground turn rate",
		"label": "How much faster the car turns while in the air",
		"tip": "In the air the car rotates this many times faster than on the ground (191.9 deg/s there). Game default 2.5 = 479.75 deg/s: an air 360 takes 0.76 s and an air 180 0.38 s, and a fall off a height-6 rooftop lasts 1.0 s. 1 = the same as on the ground.",
		"unity_note": "Unity: no height, the car never leaves the ground",
		"min": 1.0, "max": 4.0, "step": 0.05},
]


## Trick detection settings (task T-079). Not handling values: they only
## decide when trick_detector.gd counts an alternate drift. The tuning panel
## shows them in their own group. "toggle": true marks an on/off setting.
const TRICK_SETTINGS := [
	{"key": "alternate_max_switch_seconds", "name": "Alternate drift: switch time", "unit": "s",
		"label": "Alternate drift: longest switch between W and S",
		"tip": "Longest time from the end of the forward drift (W released) to the start of the backward drift (S held), or the other way round. 0 = S must already be held when W is released. Proposed 0.5 s.",
		"min": 0.0, "max": 2.0, "step": 0.05},
	{"key": "alternate_min_drift_seconds", "name": "Alternate drift: shortest drift", "unit": "s",
		"label": "Alternate drift: how long each drift must last",
		"tip": "Both the drift before the switch and the drift after it must last at least this long; the trick counts when the new drift reaches it. Stops quick W / S taps from counting. Proposed 0.3 s (a half circle takes about 0.94 s).",
		"min": 0.0, "max": 2.0, "step": 0.05},
	{"key": "alternate_keep_steering", "name": "Alternate drift: keep steering", "toggle": true,
		"label": "Alternate drift: A or D must stay held during the switch",
		"tip": "On: letting go of A or D (or pressing the other one) between the two drifts cancels the trick. Off: only the two drifts need the same steering. Proposed on."},
]


## Top speed in units/s.
func top_speed() -> float:
	return forward_speed * top_speed_multiplier


## Speed change per step for speeding up, braking and the reverse climb.
func ramp_delta(dt: float) -> float:
	return top_speed() / maxf(0.1, time_to_top_speed) * dt


## Speed lost per step while coasting.
func coast_delta(dt: float) -> float:
	return top_speed() * coast_decel_multiplier * dt


## Degrees per second the body rotates while A or D is held.
func turn_rate() -> float:
	return turn_speed * steer_sensitivity


## Degrees per second the body rotates while A or D is held, on the ground or
## (task T-219) in the air, air_turn_multiplier times faster.
func turn_rate_for(airborne: bool) -> float:
	return turn_rate() * (air_turn_multiplier if airborne else 1.0)


## The Unity values, by setting key.
static func unity_values() -> Dictionary:
	return UNITY.duplicate()


## The game's default values, by setting key.
static func default_values() -> Dictionary:
	var fresh = load("res://scripts/driving/car_tuning.gd").new()
	var out := {}
	for s in SETTINGS + SLIP_SETTINGS + COLLISION_SETTINGS + AIR_SETTINGS + TRICK_SETTINGS:
		out[s.key] = fresh.get(s.key)
	return out


## Puts every setting back to its Unity value.
func reset_to_unity() -> void:
	for key in UNITY:
		set(key, UNITY[key])


## Puts every setting back to the game's default value.
func reset_to_defaults() -> void:
	var values := default_values()
	for key in values:
		set(key, values[key])
