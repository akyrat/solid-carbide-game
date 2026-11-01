extends Node
## Screenshot fixture for T-446: the garage (garage_screen_demo's save state) in a 1600 x 900
## window, wide enough that the Buy buttons at the end of each row are on screen (at the
## screenshot tool's 1152 x 648 they sit past the right edge, as before T-446).

func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	PlayerProgress.path = RunPaths.file("garage_demo.json")
	var p := PlayerProgress.new()
	p.coins = 120
	p.levels["damage_bonus"] = GarageData.new().max_level()
	p.levels["pickup_magnet"] = 3
	p.levels["air_turn"] = 6
	var screen: GarageScreen = preload("res://scenes/menu/garage_screen.tscn").instantiate()
	screen.progress = p
	add_child(screen)
