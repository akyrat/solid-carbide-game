class_name CosmeticsData
extends RefCounted
## The cosmetics from res://data/cosmetics.json (T-552): the jump effects, in menu order,
## each with its price in coins. Price 0 = free and unlocked from the start. No texts here.

var _data: Dictionary = {}
var error: String = ""


func _init(file: String = "cosmetics") -> void:
	var r := GameData.load_file(file)
	if r.ok:
		_data = r.data
	else:
		error = r.error


func is_ok() -> bool:
	return error == ""


## The jump effect ids, in menu order.
func jump_effect_ids() -> Array:
	var out: Array = []
	for row in _data.get("jump_effects", []):
		out.append(String(row["id"]))
	return out


func has_jump_effect(id: String) -> bool:
	return jump_effect_ids().has(id)


## Coins to unlock the jump effect (0 = free); -1 for an unknown id.
func price(id: String) -> int:
	for row in _data.get("jump_effects", []):
		if String(row["id"]) == id:
			return int(row["price"])
	return -1


## The jump effect picked by a new player and by an old save.
func default_jump_effect() -> String:
	return String(_data.get("default_jump_effect", "dash_cloud"))
