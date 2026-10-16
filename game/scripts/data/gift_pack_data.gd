class_name GiftPackData
extends RefCounted
## The gift pack drop's numbers from res://data/gift_pack.json (task T-144):
## the helicopter's speed, height and start/end margin, and the package's fall
## time, landing distance, clearance and pickup radius.

var _data: Dictionary = {}
var error: String = ""


func _init(file: String = "gift_pack") -> void:
	var r := GameData.load_file(file)
	if r.ok:
		_data = r.data
	else:
		error = r.error


func is_ok() -> bool:
	return error == ""


func _num(section: String, key: String) -> float:
	var r := GameData.get_value(_data, section + "." + key)
	if not r.ok:
		push_error(r.error)
		return 0.0
	return float(r.data)


## Drawn pixels per second the helicopter flies across the screen.
func helicopter_speed() -> float:
	return _num("helicopter", "speed_px_per_second")


## Drawn pixels above the landing spot the helicopter flies (the package's fall).
func drop_height() -> float:
	return _num("helicopter", "drop_height_px")


## Drawn pixels beyond the screen's edges where the helicopter starts and ends.
func offscreen_margin() -> float:
	return _num("helicopter", "offscreen_margin_px")


## Seconds from the drop to the landing.
func fall_seconds() -> float:
	return _num("package", "fall_seconds")


## Units ahead of the car where the package lands.
func land_ahead_units() -> float:
	return _num("package", "land_ahead_units")


## Units of open road needed around the landing spot.
func clearance_units() -> float:
	return _num("package", "clearance_units")


## Units from the package's centre within which the car's centre picks it up.
func pickup_radius_units() -> float:
	return _num("package", "pickup_radius_units")
