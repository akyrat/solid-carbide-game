class_name WeaponData
extends RefCounted
## The five MVP weapons' numbers from res://data/weapons.json, worked out per tier.
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


## The raw tier list of "gun", "flamethrower", "underglow", "molotov" or "wiper" (tiers 2 to 8).
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


## What the flamethrower does at `tier`: damage, tick_interval, size_multiplier (the drawn
## flame's scale at full size; its hit area is the drawn flame, T-267, so there is no separate
## area), burn_flash_seconds, turn_speed_multiplier, always_on, min_speed, linger,
## ramp_start_fraction, ramp_seconds.
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
	return {
		"damage": damage,
		"tick_interval": float(f["tick_interval"]),
		"size_multiplier": size,
		"burn_flash_seconds": flash,
		"turn_speed_multiplier": turn,
		"always_on": always_on,
		"min_speed": float(f["min_speed"]),
		"linger": float(f["linger"]),
		"ramp_start_fraction": float(f["ramp_start_fraction"]),
		"ramp_seconds": float(f["ramp_seconds"]),
	}


## What the neon underglow does at `tier`: damage (on entering and per tick), radius,
## tick_interval, damage_on_enter.
func underglow_at(tier: int) -> Dictionary:
	var u: Dictionary = _data["underglow"]
	var damage := float(u["damage"])
	var radius := float(u["radius"])
	var tick := float(u["tick_interval"])
	for t in tiers("underglow"):
		if int(t["tier"]) > tier:
			continue
		match String(t["effect"]):
			"radius_multiplier": radius *= float(t["value"])
			"damage_multiplier": damage *= float(t["value"])
			"tick_interval_multiplier": tick *= float(t["value"])
	return {
		"damage": damage,
		"radius": radius,
		"tick_interval": tick,
		"damage_on_enter": bool(u["damage_on_enter"]),
	}


## What the molotovs do at `tier`: damage, throw_interval, molotovs_per_throw, throw_distance_min,
## throw_distance_max, fire_radius, fire_duration, tick_interval, damage_on_enter.
func molotov_at(tier: int) -> Dictionary:
	var m: Dictionary = _data["molotov"]
	var damage := float(m["damage"])
	var interval := float(m["throw_interval"])
	var count := int(m["molotovs_per_throw"])
	var radius := float(m["fire_radius"])
	var duration := float(m["fire_duration"])
	for t in tiers("molotov"):
		if int(t["tier"]) > tier:
			continue
		match String(t["effect"]):
			"fire_radius_multiplier": radius *= float(t["value"])
			"throw_interval_multiplier": interval *= float(t["value"])
			"damage_multiplier": damage *= float(t["value"])
			"add_molotovs": count += int(t["value"])
			"add_fire_duration_seconds": duration += float(t["value"])
	return {
		"damage": damage,
		"throw_interval": interval,
		"molotovs_per_throw": count,
		"throw_distance_min": float(m["throw_distance_min"]),
		"throw_distance_max": float(m["throw_distance_max"]),
		"fire_radius": radius,
		"fire_duration": duration,
		"tick_interval": float(m["tick_interval"]),
		"damage_on_enter": bool(m["damage_on_enter"]),
	}


## What the windshield wiper does at `tier`: damage, length, sweep_arc_degrees,
## sweep_degrees_per_second, hit_cooldown, knockback_distance, knockback_kaiju.
func wiper_at(tier: int) -> Dictionary:
	var w: Dictionary = _data["wiper"]
	var damage := float(w["damage"])
	var length := float(w["length"])
	var speed := float(w["sweep_degrees_per_second"])
	var knock := float(w["knockback_distance"])
	for t in tiers("wiper"):
		if int(t["tier"]) > tier:
			continue
		match String(t["effect"]):
			"length_multiplier": length *= float(t["value"])
			"damage_multiplier": damage *= float(t["value"])
			"sweep_speed_multiplier": speed *= float(t["value"])
			"knockback_multiplier": knock *= float(t["value"])
	return {
		"damage": damage,
		"length": length,
		"sweep_arc_degrees": float(w["sweep_arc_degrees"]),
		"sweep_degrees_per_second": speed,
		"hit_cooldown": float(w["hit_cooldown"]),
		"knockback_distance": knock,
		"knockback_kaiju": bool(w["knockback_kaiju"]),
	}
