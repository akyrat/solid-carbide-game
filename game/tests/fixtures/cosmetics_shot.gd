extends Control
## Screenshot fixture (T-553): the Cosmetics submenu in a chosen state, or the pause screen. The state
## comes from the environment variable COSMETICS_SHOT: locked, bought, picked or pause.

func _ready() -> void:
	var mode := OS.get_environment("COSMETICS_SHOT")
	if mode == "pause":
		var p: Node2D = load("res://scenes/drift_prototype/drift_prototype.tscn").instantiate()
		add_child(p)
		p.car.use_keyboard = false
		p.pause_screen.pause()
		return
	var progress := PlayerProgress.new(null, "user://cosmetics_shot.json")
	progress.coins = 300
	if mode == "bought" or mode == "picked":
		progress.coins = 1000
		progress.buy_cosmetic("spring")
	if mode == "picked":
		progress.equip("spring")
	var s: CosmeticsScreen = load("res://scenes/menu/cosmetics_screen.tscn").instantiate()
	s.progress = progress
	add_child(s)
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
