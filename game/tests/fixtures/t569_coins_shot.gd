extends Node
## Screenshot fixture (T-569): the Cosmetics screen with coins from the environment variable SHOT_COINS.
func _ready() -> void:
	var p := PlayerProgress.new(null, RunPaths.file("shot_cosmetics_t569.json"))
	p.coins = int(OS.get_environment("SHOT_COINS"))
	var s: CosmeticsScreen = load("res://scenes/menu/cosmetics_screen.tscn").instantiate()
	s.progress = p
	add_child(s)
