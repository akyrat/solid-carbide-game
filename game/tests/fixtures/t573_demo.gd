extends Node
## T-573 screenshots: the garage and the Cosmetics screen just opened (nothing selected), and after one
## arrow press (the first Buy or action selected). Throwaway save and settings files.
@export var show := "garage"  # "garage", "garage_key", "cosmetics" or "cosmetics_key"


func _ready() -> void:
	GameSettings.path = RunPaths.file("t573_demo.cfg")
	DirAccess.remove_absolute(GameSettings.path)
	var p := PlayerProgress.new(null, RunPaths.file("t573_demo.json"))
	p.coins = 5000
	var s: Control
	if show.begins_with("garage"):
		s = load("res://scenes/menu/garage_screen.tscn").instantiate()
	else:
		s = load("res://scenes/menu/cosmetics_screen.tscn").instantiate()
	s.progress = p
	add_child(s)
	if show.ends_with("_key"):
		await get_tree().process_frame
		var e := InputEventKey.new()
		e.keycode = KEY_DOWN
		e.physical_keycode = KEY_DOWN
		e.pressed = true
		get_viewport().push_input(e)
