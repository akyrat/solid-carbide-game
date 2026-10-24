extends Node
## Recording fixture (task T-286): one weapon at tier 1 on the street, then its size tiers
## picked one after the other (through upgrade(), as a level-up card does) so it grows on screen.
## Which weapon: the environment variable SIZE_GROW_WEAPON (wiper, underglow or flamethrower).
## The car stands still, except for the flamethrower's, which drifts in a circle.
## Recorded with Godot's movie maker (see the ticket's result notes); not part of the test suite.

const PICKS := {
	"wiper": [[1.0, 2], [3.0, 6]],
	"underglow": [[1.0, 2], [3.0, 5]],
	"flamethrower": [[1.0, 2], [3.0, 4]],
}
const START := Vector2(-62, -30)

var run: Node2D
var weapon
var id := "wiper"
var label: Label
var time := 0.0
var picks: Array = []


func _ready() -> void:
	var env := OS.get_environment("SIZE_GROW_WEAPON")
	if PICKS.has(env):
		id = env
	picks = PICKS[id].duplicate(true)
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	run.minions.enabled = false
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	car.model.set_position(START)
	car.model.rotation = -PI / 4.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	run.weapons.gun.set_tier(0)
	weapon = run.weapons.get_weapon(id)
	run.weapons.upgrade(id)
	run.camera_follow.dynamic = false
	run.set_zoom(5.5 if id == "wiper" else 8.0)  # the wiper's art is thin: closer
	car.scripted_input = [id == "flamethrower", false, 1.0] if id == "flamethrower" else [false, false, 0.0]
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	var layer := CanvasLayer.new()
	layer.layer = 100
	label = Label.new()
	label.position = Vector2(16, 12)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	layer.add_child(label)
	add_child(layer)
	_label()
	set_physics_process(true)


func _label() -> void:
	label.text = "%s tier %d" % [id, weapon.tier]


func _physics_process(delta: float) -> void:
	if run == null:
		return
	time += delta
	if not picks.is_empty() and time >= float(picks[0][0]):
		var want: int = picks[0][1]
		picks.pop_front()
		while weapon.tier < want:
			run.weapons.upgrade(id)
		_label()
