extends Control
## GIF fixture (task T-407): gift packs falling with their shadow, first on the street, then onto a rooftop
## (the run's default elevation map, roof-nw-6 at height 6). Env GIFT_SHADOW_SPOT = street | roof.
const RunScene := preload("res://scenes/run/run.tscn")
var run: Node2D
var roof := false
var _frames := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	roof = OS.get_environment("GIFT_SHADOW_SPOT") == "roof"
	run = RunScene.instantiate()
	add_child(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false


func _process(_delta: float) -> void:
	_frames += 1
	var at := Vector2(-27, -81) if roof else Vector2(0, 0)
	if _frames <= 20:
		_park(at)
	if _frames == 20:
		run.state.add_xp(run.state.xp_needed())
		run.gift_drops.landing_spot()
		_park(at + Vector2(-5, 0))


func _park(at: Vector2) -> void:
	run.car.model.set_position(at)
	run.car.model.rotation = 0.0
	run.car.model.set_velocity(Vector2.ZERO)
	run.car._sync_from_model()
	run.sync_view()
