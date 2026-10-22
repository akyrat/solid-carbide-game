class_name DriftCounter
extends AirtimeCounter
## The HUD's live drift counter (task T-247; HUD and menus, Decisions, "Drift
## counter"): while the car is drifting, a plain number with two decimals
## (seconds, no unit) counts the drift's length up next to a small icon of two
## curving skid marks. It appears when the drift starts and disappears when it
## ends, which is when it pays out (T-246).
##
## It is the airtime counter's look and code with another icon: Hud.bind_car()
## feeds step() the car's own drift state (car.model.is_drifting), one physics
## step at a time. The icon is a placeholder drawn in code, white with a black
## outline, never Redgull red. Its place is a proposal for the playtest.

## The two skid marks in a 30 x 22 box: curves bending to the right.
const MARK_A := [Vector2(2, 21), Vector2(4, 14), Vector2(9, 8), Vector2(17, 4), Vector2(27, 2)]
const MARK_B := [Vector2(9, 21), Vector2(11, 16), Vector2(15, 12), Vector2(21, 10), Vector2(28, 9)]

## Seconds drifted so far in this drift.
var drift_time: float:
	get:
		return airtime


func _make_icon() -> Control:
	return _SkidIcon.new()


## Two white skid marks with a black outline.
class _SkidIcon extends Control:
	func _draw() -> void:
		for mark: Array in [DriftCounter.MARK_A, DriftCounter.MARK_B]:
			var pts := PackedVector2Array(mark)
			draw_polyline(pts, DriftCounter.OUTLINE_COLOR, 7.0)
		for mark: Array in [DriftCounter.MARK_A, DriftCounter.MARK_B]:
			draw_polyline(PackedVector2Array(mark), DriftCounter.NUMBER_COLOR, 3.0)
