extends Node2D
## A test enemy (task T-042): in the group "enemies", with take_damage() and a
## large health, so tests can count every hit. Position in flat world pixels
## (16 per unit), like the minions.

var health := 1000.0
var damage_taken: Array = []
var sprite: Node2D = null


func _init() -> void:
	add_to_group("enemies")
	sprite = Node2D.new()
	add_child(sprite)


func position_units() -> Vector2:
	return position / 16.0


func take_damage(amount: float) -> void:
	damage_taken.append(amount)
	health -= amount


func is_dead() -> bool:
	return health <= 0.0


func total_damage() -> float:
	var t := 0.0
	for a in damage_taken:
		t += a
	return t
