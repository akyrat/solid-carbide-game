class_name WeaponData
extends RefCounted
## The two MVP weapons' numbers from res://data/weapons.json, worked out per tier.
## A weapon's tier is 1 (just got it) to max_tier(); effects add up in tier order.

var _data: Dictionary = {}
var error: String = ""


func _init(file: String = "weapons") -> void:
	var r := GameData.load_file(file)
	if r.ok:
		_data = r.data
	else:
		error = r.error


func is_ok() -> bool:
	return error == ""


func max_tier() -> int:
	return int(_data["max_tier"])


## The raw tier list of "gun" or "flamethrower" (tiers 2 to 8).
func tiers(weapon: String) -> Array:
	return _data[weapon]["tiers"]


## What the gun does at `tier`: damage, range, fire_interval, bullets, bullet_speed,
## bullet_hit_radius, delay_between_bullets, pierce_hits, missed_bullet_max_travel.
func gun_at(tier: int) -> Dictionary:
	var g: Dictionary = _data["gun"]
	var bullets := int(g["bullets_per_volley"])
	var rate := 1.0
	var rng := float(g["range"])
	var pierce := 0
	for t in tiers("gun"):
		if int(t["tier"]) > tier:
			continue
		match String(t["effect"]):
			"add_bullets": bullets += int(t["value"])
			"fire_rate_multiplier": rate *= float(t["value"])
			"range_multiplier": rng *= float(t["value"])
			"pierce": pierce += int(t["value"])
	return {
		"damage": float(g["damage"]),
		"range": rng,
		"fire_interval": float(g["base_fire_interval"]) / rate + float(g["extra_delay_between_volleys"]),
		"bullets": bullets,
		"bullet_speed": float(g["bullet_speed"]),
		"bullet_hit_radius": float(g["bullet_hit_radius"]),
		"delay_between_bullets": float(g["delay_between_bullets"]),
		"pierce_hits": pierce,
		"missed_bullet_max_travel": rng,
	}


## What the flamethrower does at `tier`: damage, tick_interval, size_multiplier, area_width,
## area_depth (full size, in units), inner_edge, burn_flash_seconds, turn_speed_multiplier,
## always_on, min_speed, linger, ramp_start_fraction, ramp_seconds.
func flame_at(tier: int) -> Dictionary:
	var f: Dictionary = _data["flamethrower"]
	var size := float(f["base_size_multiplier"])
	var damage := float(f["damage"])
	var flash := float(f["burn_flash_seconds"])
	var turn := 1.0
	var always_on := bool(f["always_on"])
	for t in tiers("flamethrower"):
		if int(t["tier"]) > tier:
			continue
		match String(t["effect"]):
			"size_multiplier": size *= float(t["value"])
			"damage_multiplier": damage *= float(t["value"])
			"add_burn_flash_seconds": flash += float(t["value"])
			"turn_speed_multiplier": turn *= float(t["value"])
			"always_on": always_on = true
	var half := float(f["car_half_size"])
	return {
		"damage": damage,
		"tick_interval": float(f["tick_interval"]),
		"size_multiplier": size,
		"area_width": 2.0 * float(f["half_width_multiplier"]) * half * size,
		"area_depth": float(f["depth_multiplier"]) * half * size,
		"inner_edge": maxf(float(f["inner_edge_multiplier"]) * half, 0.05),
		"burn_flash_seconds": flash,
		"turn_speed_multiplier": turn,
		"always_on": always_on,
		"min_speed": float(f["min_speed"]),
		"linger": float(f["linger"]),
		"ramp_start_fraction": float(f["ramp_start_fraction"]),
		"ramp_seconds": float(f["ramp_seconds"]),
	}
