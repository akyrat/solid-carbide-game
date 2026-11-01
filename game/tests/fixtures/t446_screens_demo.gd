extends Node
## Screenshot fixture for T-446 (the shared button): `mode` "recap" shows the recap
## screen with a sample run's summary (t446_recap_demo.tscn); "level_up" opens the
## level-up screen with two cards in a run (t446_level_up_demo.tscn).

@export var mode := "recap"


func _ready() -> void:
	if mode == "level_up":
		var run: Node2D = preload("res://scenes/run/run.tscn").instantiate()
		add_child(run)
		run.minions.enabled = false
		await get_tree().process_frame
		run.state.add_xp(run.state.xp_needed())
		run.gift_drops.pick_up_all()
		run.level_up_screen.show_offers(["upgrade_gun", "get_wiper"])
		run.level_up_screen.skip_animation()
		return
	var screen: RecapScreen = preload("res://scenes/menu/recap_screen.tscn").instantiate()
	add_child(screen)
	screen.show_summary({
		"result": "win", "loss_reason": "", "time_survived": 300.0, "coins": 40,
		"likes": 900, "level": 5,
		"enemies_slain": {"minion": 42, "kaiju": 1},
		"tricks": {"three_sixty": 3, "airtime": 7, "thread_the_needle": 1},
		"highest_combo": 3.4, "peak_viewers": 236026.0,
		"weapons": {"gun": {"tier": 4, "kills": 30}, "wiper": {"tier": 2, "kills": 12}},
	})
