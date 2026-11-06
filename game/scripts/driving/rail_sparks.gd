extends Node2D
## Sparks while the car grinds a rail (task T-541; the old wall grind's sparks, trick_grind.gd on
## hold/trick-prototype): small pixel squares in yellows and oranges (never Greenbull's colours)
## fly back from where the car touches the bar, SPARK_RATE a second for each unit/s of speed.
## They are only made while grinding; those in the air finish their short life after it ends.
##
## The run puts it in its car view (beside the car's drawing, so it shares the car's depth) and
## calls step(car, dt) after each physics step. Positions are the view's screen pixels.

const RailDrawing := preload("res://scripts/level/rail_drawing.gd")

## All numbers are proposals for the board's playtest (the wall grind's, kept).
## How many sparks a second for each unit/s of speed (cruise 11 makes 55 a second)...
const SPARK_RATE := 5.0
## ...how long each lives, seconds...
const SPARK_LIFE := 0.3
## ...how fast they fly back and up from the contact point, and fall, pixels/s (and /s each s).
const SPARK_SPEED_PX := 70.0
const SPARK_RISE_PX := 50.0
const SPARK_GRAVITY_PX := 260.0
const SPARK_COLORS := [
	Color(1.0, 0.97, 0.70),
	Color(1.0, 0.86, 0.25),
	Color(1.0, 0.68, 0.12),
	Color(0.98, 0.50, 0.08),
]

## Sparks in the air: [{"pos", "vel", "age", "color", "size"}], screen pixels.
var sparks: Array = []
## Sparks made so far (tests).
var spawned := 0

var _carry := 0.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 541


## One physics step: new sparks while `car` grinds, then the sparks in the air move on by dt.
func step(car, dt: float) -> void:
	var g = car.grind
	if g.active:
		_spawn(RailDrawing.screen_of(g.position_units(), g.height()),
			RailDrawing.ISO_TRANSFORM.basis_xform(g.travel()), float(g.speed), dt)
	else:
		_carry = 0.0
	var keep: Array = []
	for s in sparks:
		s.age += dt
		if s.age >= SPARK_LIFE:
			continue
		s.vel.y += SPARK_GRAVITY_PX * dt
		s.pos += s.vel * dt
		keep.append(s)
	sparks = keep
	queue_redraw()


func _spawn(at: Vector2, travel_screen: Vector2, speed: float, dt: float) -> void:
	_carry += SPARK_RATE * speed * dt
	var back := -travel_screen.normalized() if travel_screen.length() > 0.0 else Vector2.LEFT
	var side := Vector2(-back.y, back.x)
	while _carry >= 1.0:
		_carry -= 1.0
		var vel := back * SPARK_SPEED_PX * _rng.randf_range(0.4, 1.0) \
			+ side * SPARK_SPEED_PX * _rng.randf_range(-0.35, 0.35) \
			+ Vector2(0.0, -SPARK_RISE_PX * _rng.randf_range(0.3, 1.0))
		sparks.append({
			"pos": at,
			"vel": vel,
			"age": 0.0,
			"color": SPARK_COLORS[_rng.randi() % SPARK_COLORS.size()],
			"size": 1.0 if _rng.randf() < 0.5 else 2.0,
		})
		spawned += 1


func _draw() -> void:
	for s in sparks:
		draw_rect(Rect2((s.pos as Vector2).floor(), Vector2.ONE * float(s.size)), s.color)
