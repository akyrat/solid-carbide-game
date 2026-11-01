extends Control
## Screenshot fixture (task T-454): shadows that shrink with height, in the run
## on its default elevation map. `what`:
## - "car": the car held `above` units over the ground at `at` (its physics off).
## - "gift": a gift pack dropped at frame 20 by the car parked at `at`, held at gift_progress of its fall.
## - "minion" / "kaiju": one held `above` units over the street at `at`, falling.
@export var what := "car"
@export var at := Vector2(0, 0)
@export var above := 0.0
@export var zoom := 10.0
## "gift": how far through its fall the package is held (0 just dropped, 1 landed).
@export var gift_progress := 0.0

const RunScene := preload("res://scenes/run/run.tscn")
var run: Node2D
var enemy: Node = null
var _frames := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	run = RunScene.instantiate()
	add_child(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	run.car.set_physics_process(false)
	run.camera_follow.dynamic = false
	run.set_zoom(zoom)


func _process(_delta: float) -> void:
	_frames += 1
	run.state.health = run.state.max_health
	match what:
		"car":
			_park(at, above)
		"gift":
			if _frames <= 20:
				_park(at, 0.0)
			if _frames == 20:
				run.state.add_xp(run.state.xp_needed())
				run.gift_drops._drop(run.gift_drops.helicopters[-1])  # falls at once
				run.gift_drops.set_process(false)  # held at gift_progress below
			if _frames >= 20 and not run.gift_drops.packages.is_empty():
				var pkg: GiftPackage = run.gift_drops.packages[-1]
				if pkg.is_falling():
					pkg.fall_t = gift_progress * pkg.fall_seconds
					run.gift_drops._fall(pkg, 0.0)
		"minion", "kaiju":
			_park(at + Vector2(-6, 0), 0.0)
			if enemy == null:
				if what == "minion":
					enemy = run.minions.spawn_minion_at(at)
				else:
					run.kaiju_boss.enabled = true
					enemy = run.kaiju_boss.appear_at(at)
			enemy.fall.start(above)
			if what == "minion":
				run.minions.update_drawing()
			else:
				run.kaiju_boss.update_drawing()


func _park(units: Vector2, h_above: float) -> void:
	var car = run.car
	car.model.set_position(units)
	car.model.rotation = 0.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	var g: float = run.elevation.ground_height.height_at(units)
	car.height_model.height = g + h_above
	car.height_model.airborne = h_above > 0.0
	run.sync_view()
