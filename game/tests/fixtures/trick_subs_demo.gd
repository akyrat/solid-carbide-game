extends Node
## Screenshot fixture for T-513: a trick fills the sub goal (the bar nearly full, then ALT DRIFT
## and THREAD THE NEEDLE pay their subs).


func _ready() -> void:
	var run: Node2D = GameFlow.add_run(self, PlayerProgress.new())
	for i in 10:
		await get_tree().process_frame
	run.state.xp = run.state.xp_needed() - 8.0
	run.state.add_trick("alternate_drift")
	run.state.add_needle_trick()
