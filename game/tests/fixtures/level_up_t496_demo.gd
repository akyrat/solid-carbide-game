extends Node
## Screenshot fixture for T-496: the level-up screen offering changed cards of the
## board's trees. `tiers` sets weapon tiers first ({"gun": 7, ...}); then the
## screen shows `offer_ids` (screenshot only; nothing is taken).

@export var tiers: Dictionary = {}
@export var offer_ids: Array[String] = []


func _ready() -> void:
	var run: Node2D = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	run.minions.enabled = false
	await get_tree().process_frame
	for id in tiers:
		run.weapons.get_weapon(id).set_tier(int(tiers[id]))
	run.state.add_xp(run.state.xp_needed())
	run.gift_drops.pick_up_all()
	run.level_up_screen.show_offers(offer_ids)
	run.level_up_screen.skip_animation()
