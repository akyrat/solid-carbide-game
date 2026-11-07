extends RefCounted
## The tilt (task T-551; Drifting, Decisions, "The grind overhaul"; how it behaves and its
## numbers: Drifting, Content, "The grind overhaul (task T-551)"): while Space (car_jump) is held
## with the car in the air (or on a rail, where the grind keeps the held pose), the car is tilted:
## its front left wheel down, its back right wheel up. A 3-frame transition plays into the held
## pose, and the same 3 frames play backwards when Space is let go in the air, and on landing.
##
## `step` is the frame shown: 0 the normal car, 1 and 2 the in-betweens, 3 (FRAMES) the held
## pose. Each frame shows for `frame_seconds` (rail_grind.json `tilt_frame_seconds`): the first
## frame of a transition shows on the step the hold (or release) starts, then one frame more every
## frame_seconds, so frames 1, 2, 3 each show for the same time. A turn round mid-transition goes
## back from the frame it is on. The car's drawing (car_sprite.gd set_tilt_step) picks the tilted
## frame for the car's direction and this step; T-555's art replaces the placeholder there.
## Node-free: the car (car.gd) steps it after every physics step; tests drive it directly.

const FRAMES := 3
const DATA_FILE := "rail_grind"
const DEFAULT_FRAME_SECONDS := 0.06

## Seconds each transition frame shows.
var frame_seconds := DEFAULT_FRAME_SECONDS
## The frame shown now: 0 (normal) to FRAMES (the held pose).
var step := 0
## True while the tilt is wanted (the last update's `tilted`).
var holding := false
var _left := 0.0
var _dir := 0


func _init() -> void:
	load_numbers()


## Reads `tilt_frame_seconds` from data/rail_grind.json (missing: the default).
func load_numbers(file: String = DATA_FILE) -> void:
	var r := GameData.load_file(file)
	var d: Dictionary = r.data if r.ok and r.data is Dictionary else {}
	frame_seconds = maxf(float(d.get("tilt_frame_seconds", DEFAULT_FRAME_SECONDS)), 0.001)


## One physics step of dt seconds. tilted: Space held and the car in the air or on a rail.
func update(tilted: bool, dt: float) -> void:
	holding = tilted
	var goal := FRAMES if tilted else 0
	if step == goal:
		_left = 0.0
		_dir = 0
		return
	var dir := 1 if goal > step else -1
	if dir != _dir:  # a new transition (or a turn round): its first frame shows at once
		_dir = dir
		_left = 0.0
	if _left <= 1e-9:
		step += dir
		_left = frame_seconds
	_left -= dt


## Back to the normal car at once (a new car, the wreck).
func reset() -> void:
	step = 0
	holding = false
	_left = 0.0
	_dir = 0


## 0 (normal) to 1 (the held pose): how far the tilt is (the placeholder's shear).
func amount() -> float:
	return float(step) / float(FRAMES)


## True in the held pose.
func is_tilted() -> bool:
	return step == FRAMES
