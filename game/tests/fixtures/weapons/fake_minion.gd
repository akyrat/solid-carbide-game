extends "res://tests/fixtures/weapons/fake_enemy.gd"
## A test minion (task T-170): a fake enemy with the minion's knockback call
## (minion.gd apply_knockback(), T-167). It records every push and moves at
## once by it, so tests can check who pushes and who does not. `as_kaiju`
## puts it in the "kaiju" group instead of "minions", with a body size, as a
## stand-in for a big enemy that would accept a push.

## Every push: [direction (normalized), strength].
var pushes: Array = []
## Its body radius (units), the minion's.
var radius_units := 0.5


func _init() -> void:
	super._init()
	add_to_group("minions")


## Makes it a stand-in for the kaiju: in the "kaiju" group, reporting its size.
func as_kaiju(size: float = 3.0) -> void:
	remove_from_group("minions")
	add_to_group("kaiju")
	radius_units = size


func hit_radius_units() -> float:
	return radius_units


func apply_knockback(direction: Vector2, strength: float) -> void:
	if strength <= 0.0 or direction.length() < 0.000001:
		return
	pushes.append([direction.normalized(), strength])
	position += direction.normalized() * strength * 16.0
