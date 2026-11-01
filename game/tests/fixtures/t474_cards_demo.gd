extends Node
## Screenshot fixture for T-474 (gift cards clicked directly): opens the level-up
## screen with two cards in a run. `select` moves the keyboard highlight that many
## cards right; `hover_card` hovers that card (-1 none); `press_hovered` presses it down.

@export var select := 0
@export var hover_card := -1
@export var press_hovered := false


func _ready() -> void:
	var run: Node2D = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	run.minions.enabled = false
	await get_tree().process_frame
	run.state.add_xp(run.state.xp_needed())
	run.gift_drops.pick_up_all()
	run.level_up_screen.show_offers(["upgrade_gun", "get_wiper"])
	run.level_up_screen.skip_animation()
	run.level_up_screen.move_highlight(select)
	if hover_card >= 0:
		run.level_up_screen.cards[hover_card].click.mouse_entered.emit()
		if press_hovered:
			run.level_up_screen.cards[hover_card].click.button_down.emit()
