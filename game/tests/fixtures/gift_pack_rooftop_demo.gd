extends Control
## Screenshot fixture (task T-402): a gift pack dropped while the car is parked in the middle of a
## rooftop, far from any street, on the board's Kaiju City level (the untracked read-only copy in
## data/levels/kaiju_city.json; never saved; without it the run's default elevation map, roof-nw-6).
## Before the fix the package was drawn at street level, below the rooftop; now on its top.
## bash game/tools/screenshot.sh res://tests/fixtures/gift_pack_rooftop_demo.tscn art-archive/T-402/screenshots/after.png 40

const RunScene := preload("res://scenes/run/run.tscn")
const LEVEL := "res://data/levels/kaiju_city.json"
## The car's spot (units): roof-1's centre on Kaiju City (height 3), roof-nw-6's on the default map.
const SPOT_KAIJU := Vector2(-32, 36)
const SPOT_DEFAULT := Vector2(-27, -81)

## true: the run's default map (the elevation sample map, roof-nw-6 at height 6) even with Kaiju City there.
@export var default_map := false

var run: Node2D
var spot := SPOT_DEFAULT
var _frames := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	run = RunScene.instantiate()
	if not default_map and FileAccess.file_exists(LEVEL):
		run.layout_path = LEVEL
		spot = SPOT_KAIJU
	add_child(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false


func _process(_delta: float) -> void:
	_frames += 1
	_park(spot if _frames <= 3 else spot + Vector2(-5, 0))
	if _frames == 3:
		run.state.add_xp(run.state.xp_needed())
		run.gift_drops.land_all()
		# After the drop the car backs off 5 units, so a package on its own spot is not picked up.
		_park(spot + Vector2(-5, 0))


func _park(at: Vector2) -> void:
	run.car.model.set_position(at)
	run.car.model.rotation = 0.0
	run.car.model.set_velocity(Vector2.ZERO)
	run.car._sync_from_model()
	run.sync_view()
