extends "res://tests/fixtures/enemies_heights_demo.gd"
## Recording fixture (task T-226): T-207's screenshot fixture, then the
## minions (and the kaiju, if set) keep chasing the parked car live, one
## spawner step per physics frame, so they drop off the rooftop's edge in
## front of the camera. `stop_at_seconds` >= 0 stops them there for a still
## (with the falling animation frozen as it is); `quit_after_seconds` quits
## the scene (for Godot's movie maker):
## "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/drop/f.png res://tests/fixtures/enemies_drop_gif.tscn
## then crop the frames into a GIF (T-226 used a box round the rooftop's edge,
## every second frame, 40 ms; game/tools/make_turn_gif.py crops round the car).

@export var stop_at_seconds := -1.0
@export var quit_after_seconds := -1.0

var _live_t := 0.0
var _live := false


func _ready() -> void:
	await super._ready()
	_live = true


func _physics_process(_delta: float) -> void:
	if not _live:
		return
	_live_t += DT
	if quit_after_seconds >= 0.0 and _live_t >= quit_after_seconds:
		get_tree().quit()
		return
	if stop_at_seconds >= 0.0 and _live_t > stop_at_seconds:
		for m in run.minions.minions:
			if m.sprite != null:
				m.sprite.set_process(false)
		return
	var spawner = run.minions
	spawner.move_step(DT)
	spawner.update_drawing()
	var boss = run.kaiju_boss
	if boss.kaiju != null and is_instance_valid(boss.kaiju):
		boss.enabled = true
		boss.step(DT)
		boss.enabled = false
	run.state.health = run.state.max_health
	var k = boss.kaiju
	if k != null and is_instance_valid(k) and int(round(_live_t / DT)) % 25 == 0:
		print("enemies_drop_demo: kaiju at %.2f s: %s ground %.1f body %.2f falling %s sprite %s %s" % [
			_live_t, k.position_units().snapped(Vector2(0.1, 0.1)), k.ground_height(), k.body_height(),
			k.is_falling(), k.sprite.position.round(), k.sprite.animation()])
	if stop_at_seconds >= 0.0 and _live_t + DT > stop_at_seconds:
		var falling := []
		for m in spawner.minions:
			falling.append("%s h%.1f %s" % [m.position_units().round(), m.body_height(), m.sprite.animation()])
		print("enemies_drop_demo: at %.2f s: %s" % [_live_t, ", ".join(falling)])
