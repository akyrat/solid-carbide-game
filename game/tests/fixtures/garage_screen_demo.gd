extends Node
## Test fixture for a screenshot of the garage screen (task T-058): a save file with some
## coins and one upgrade at its last level, so every state shows.

func _ready() -> void:
	PlayerProgress.path = RunPaths.file("garage_demo.json")
	var p := PlayerProgress.new()
	p.coins = 120
	p.levels["damage_bonus"] = GarageData.new().max_level()
	var screen: GarageScreen = preload("res://scenes/menu/garage_screen.tscn").instantiate()
	screen.progress = p
	add_child(screen)
