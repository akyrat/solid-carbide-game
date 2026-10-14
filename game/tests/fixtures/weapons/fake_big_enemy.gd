extends "res://tests/fixtures/weapons/fake_enemy.gd"
## A big test enemy (task T-042), a stand-in for the kaiju: it reports its
## body size with hit_radius_units(), as T-041's targeting reads it.

var radius_units := 3.0


func hit_radius_units() -> float:
	return radius_units
