extends RefCounted
## An enemy's fall off a rooftop's edge (task T-226; Enemies, Decisions,
## "Enemies jump down off ledges"). Every enemy that chases the car owns one
## (minion.gd, kaiju.gd). While it falls, the enemy's body is in the air at
## `height` (units), above the lower ground it has walked out over; it keeps
## walking on the flat at its usual speed, and its height drops under the
## car's own gravity (car_height.gd, GRAVITY) from where it left the edge
## until it reaches the ground under it, where it lands.
##
## Proposal for the playtest: falling like the car does (the same gravity, no
## jump upwards, starting at rest): a 3-unit drop takes about 0.7 s and a
## 6-unit drop 1 s.

const CarHeightScript := preload("res://scripts/driving/car_height.gd")

## Units/s^2: the car's gravity, so enemies fall like the car.
const GRAVITY: float = CarHeightScript.GRAVITY

## True from leaving the edge until landing.
var falling := false
## The body's height while falling, units.
var height := 0.0
## Vertical speed, units/s, up positive.
var vertical_speed := 0.0
## Seconds since it left the edge (for the falling animation).
var seconds := 0.0
## How many falls it has landed (tests).
var landings := 0


## Starts a fall from `from_height` (the ground it walked off).
func start(from_height: float) -> void:
	falling = true
	height = from_height
	vertical_speed = 0.0
	seconds = 0.0


## One step of `dt` seconds over ground `ground_h`. Returns true on the step
## it lands (its height reached the ground).
func step(dt: float, ground_h: float) -> bool:
	if not falling:
		return false
	seconds += dt
	vertical_speed -= GRAVITY * dt
	height += vertical_speed * dt
	if height <= ground_h:
		falling = false
		height = ground_h
		vertical_speed = 0.0
		landings += 1
		return true
	return false


## The body's height: in the air while falling, else the ground's `ground_h`.
func body_height(ground_h: float) -> float:
	return height if falling else ground_h


## Ends any fall (a new run, a test placing the enemy).
func reset() -> void:
	falling = false
	vertical_speed = 0.0
	seconds = 0.0
