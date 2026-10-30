extends Node
## A node with the knockback call, for the underglow's push rule (T-409).
## With `nudge_only` true it has the kaiju's apply_nudge() instead (the script
## cannot drop a method, so the test uses fake_nudgeable.gd for that).

func apply_knockback(_direction: Vector2, _strength: float) -> void:
	pass
