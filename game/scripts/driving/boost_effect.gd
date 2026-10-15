extends Node2D
## Placeholder boost effect (task T-008): a short burst of streaks behind the
## car when W snaps it up to cruise speed (Car.boost). The final animation
## comes from task T-009 and replaces the drawing here, hooked to the same
## signal.
##
## Streaks are opaque (no fading, Visual style, "See-through rule"), light
## grey-blue (never Redgull red), stay where they were made in the world, and
## shrink to nothing over `lifetime`. Drawn in the view like the drift smoke:
## set `view_transform` to the view's projection and call bind(car).

const PX_PER_UNIT := 16.0

## Seconds the burst lasts.
@export var lifetime := 0.35
## Streaks per burst, spread side to side behind the car.
@export var streak_count := 5
## Streak length in units at the start (shrinks to 0).
@export var streak_length_units := 4.0
## Distance between neighbouring streaks, in units.
@export var streak_spacing_units := 0.3
## Drawn line width in pixels.
@export var line_width := 3.0
@export var color := Color(0.8, 0.9, 1.0, 1.0)

var view_transform := Transform2D.IDENTITY:
	set(value):
		view_transform = value
		queue_redraw()
## Seconds since this node started (only advances while not paused).
var time := 0.0
## How many bursts have been made.
var bursts_made := 0
## Bursts now: {position: Vector2 (units, behind the car), heading: float, born: float}.
var _bursts: Array = []


func _process(delta: float) -> void:
	advance(delta)


## Plays a burst each time the car's boost signal fires.
func bind(car: Node) -> void:
	car.boost.connect(func(_from_speed: float) -> void:
		play(car.model.get_position(), car.model.rotation))


## Starts a burst at a place (units) for a car pointing at heading (radians).
func play(position_units: Vector2, heading: float) -> void:
	_bursts.append({"position": position_units, "heading": heading, "born": time})
	bursts_made += 1
	queue_redraw()


func advance(delta: float) -> void:
	time += delta
	var keep: Array = []
	for b in _bursts:
		if time - b.born < lifetime:
			keep.append(b)
	_bursts = keep
	queue_redraw()


## Bursts playing now.
func burst_count() -> int:
	return _bursts.size()


func clear() -> void:
	_bursts.clear()
	queue_redraw()


func _draw() -> void:
	for b in _bursts:
		var k := 1.0 - clampf((time - b.born) / lifetime, 0.0, 1.0)
		if k <= 0.0:
			continue
		var forward := Vector2.from_angle(b.heading)
		var side := Vector2(-forward.y, forward.x)
		var tail: Vector2 = b.position - forward * 0.6
		for i in streak_count:
			var offset := (float(i) - (streak_count - 1) * 0.5) * streak_spacing_units
			var start := tail + side * offset
			var end := start - forward * streak_length_units * k * (1.0 - absf(offset) * 0.4)
			draw_line(view_transform * (start * PX_PER_UNIT), view_transform * (end * PX_PER_UNIT), color, line_width)
