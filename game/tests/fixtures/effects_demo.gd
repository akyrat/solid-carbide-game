extends Node
## Screenshot-sequence fixture (task T-072): a minion beside the car is hit, dies and drops coins,
## then the car takes damage. Saves PNGs of the whole window at set frames into the folder in the
## environment variable EFFECTS_OUT, then quits. Needs a real window (not --headless):
##   EFFECTS_OUT=C:/some/folder godot --path game res://tests/fixtures/effects_demo.tscn

const SHOTS := {9: "00_before", 13: "01_hit_a", 17: "02_hit_b", 21: "03_hit_c", 25: "04_hit_d",
	41: "10_death_a", 47: "11_death_b", 53: "12_death_c", 59: "13_death_d", 66: "14_death_e",
	73: "15_death_f", 100: "20_coins", 121: "30_damage_a", 125: "31_damage_b", 129: "32_damage_c",
	133: "33_damage_d"}

var _n := 0
var _run: Node2D
var _minion: Node
var _out := ""


func _ready() -> void:
	_out = OS.get_environment("EFFECTS_OUT")
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	_run = game.run
	_run.car.use_keyboard = false
	_run.minions.rng.seed = 72
	_run.minions.enabled = false
	_run.minions._coins["drop_chance"] = 1.0


func _process(_delta: float) -> void:
	if _run == null:
		return
	_n += 1
	var car_units: Vector2 = _run.car.position / 16.0
	if _n == 6:
		_minion = _run.minions.spawn_minion_at(car_units + Vector2(2.5, 0.0))
		_run.minions.update_drawing()
	if _n == 12:
		_minion.take_damage(1.0)
	if _n == 40:
		_minion.take_damage(100.0)
	if _n == 120:
		_run.state.damage_car(5.0)
	if SHOTS.has(_n) and _out != "":
		_save.call_deferred(SHOTS[_n])
	if _n >= 140:
		get_tree().quit()


func _save(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, shot_name])
