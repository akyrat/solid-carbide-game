extends Node
## Screenshot fixture for T-470: the garage in a window of the size given by the environment variable
## GARAGE_SHOT_SIZE ("1920x1080"), to show it fits every window size.

func _ready() -> void:
	var parts := OS.get_environment("GARAGE_SHOT_SIZE").split("x")
	if parts.size() == 2:
		get_window().size = Vector2i(int(parts[0]), int(parts[1]))
	PlayerProgress.path = RunPaths.file("garage_demo.json")
	var p := PlayerProgress.new()
	p.coins = 120
	p.levels["damage_bonus"] = GarageData.new().max_level()
	p.levels["pickup_magnet"] = 3
	p.levels["air_turn"] = 6
	var screen: GarageScreen = preload("res://scenes/menu/garage_screen.tscn").instantiate()
	screen.progress = p
	add_child(screen)
