extends Node2D
## The two paired boulders of the thread_the_needle tutorial clip (T-490): flat circles in map pixels
## ([centre, radius] each), drawn in the test room's boulder colours; the view transform is the node's.

var circles: Array = []


func _draw() -> void:
	for c in circles:
		draw_circle(c[0], c[1], Color(0.13, 0.12, 0.15))
		draw_arc(c[0], c[1] - 1.0, 0.0, TAU, 32, Color(0.95, 0.45, 0.25), 2.0)
