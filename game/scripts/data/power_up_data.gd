class_name PowerUpData
extends RefCounted
## The five driving power-ups (the fifth, polarized_steering_wheel, T-502) from res://data/power_ups.json, with per-tier numbers
## (all proposals for the playtest). Same style as WeaponData.

const IDS := ["rev_charge", "jump", "bouncy_bumpers", "rusty_overcoat", "polarized_steering_wheel"]

var _data: Dictionary = {}
var error: String = ""


func _init(file: String = "power_ups") -> void:
	var r := GameData.load_file(file)
	if r.ok:
		_data = r.data
	else:
		error = r.error


func is_ok() -> bool:
	return error == ""


func ids() -> Array:
	return _data["power_ups"].keys()


## The icon path (res://art/power_ups/<id>.png; the file comes with the art ticket).
func icon(id: String) -> String:
	return String(_data["power_ups"][id]["icon"])


func max_tier(id: String = "") -> int:
	if id != "":
		return tiers(id).size()
	return int(_data["max_tier"])


func tiers(id: String) -> Array:
	return _data["power_ups"][id]["tiers"]


## The numbers at `tier` (1 to max_tier(id)) without the proposal/reason notes.
func at(id: String, tier: int) -> Dictionary:
	var t: Dictionary = tiers(id)[clampi(tier, 1, max_tier(id)) - 1].duplicate()
	t.erase("proposal")
	t.erase("reason")
	return t


## What the overlay does when every power-up is at its last tier ("skip_gift").
func offer_when_exhausted() -> String:
	return String(_data["offer_when_exhausted"]["action"])
