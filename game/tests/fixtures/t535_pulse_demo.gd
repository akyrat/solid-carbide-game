extends Node
## T-535 screenshots: the main menu with a throwaway save. `coins` picks the case.
@export var coins := 0


func _ready() -> void:
	var p := PlayerProgress.new(null, RunPaths.file("t535_demo.json"))
	p.coins = coins
	var m: MainMenu = load("res://scenes/menu/main_menu.tscn").instantiate()
	m.progress = p
	add_child(m)
