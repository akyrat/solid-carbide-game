extends RefCounted
## The car's handling values, copied from the board's Unity prototype.
##
## Defaults are the "Value in project files (used)" column of the Unity prototype
## report, section 5 (docs/drifting/unity-prototype-report.md). SETTINGS lists the
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
var top_speed_multiplier := 2.5
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
		"tip": "Top speed = cruise speed x this. Unity: 11 x 2.5 = 27.5 units/s.",
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


## The Unity values, by setting key.
static func unity_values() -> Dictionary:
	var fresh = load("res://scripts/driving/car_tuning.gd").new()
	var out := {}
	for s in SETTINGS:
		out[s.key] = fresh.get(s.key)
	return out


## Puts every setting back to its Unity value.
func reset_to_unity() -> void:
	var values := unity_values()
	for key in values:
		set(key, values[key])
