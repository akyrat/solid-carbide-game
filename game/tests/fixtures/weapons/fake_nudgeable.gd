extends "res://tests/fixtures/weapons/fake_enemy.gd"
## A kaiju stand-in for the underglow's rule (T-409): it can be nudged, not knocked back.

var nudges: Array = []


func _init() -> void:
	super._init()
	add_to_group("kaiju")


func apply_nudge(direction: Vector2, distance: float) -> void:
	nudges.append([direction, distance])
