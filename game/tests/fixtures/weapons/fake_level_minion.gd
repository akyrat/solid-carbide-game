extends "res://tests/fixtures/weapons/fake_minion.gd"
## A test minion at a height (task T-326): a fake minion (with the knockback
## call) that reports its body's height, as the real minions do on the
## elevation map (minion.gd body_height()), so tests can put it on the car's
## level or another one without a map.

## Its body's height, units (0 the street, 3 a low rooftop, 6 a high one).
var level_height := 0.0


func body_height() -> float:
	return level_height
