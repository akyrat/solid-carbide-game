extends Node
## Screenshot fixture (task T-595): a run with Jump at tier 1, the car standing still, stepped once
## per frame. A tap at `tap_step` (-1: none), Space held from `charge_step` for `charge_steps` (-1: no
## charge) then let go. At `stop_step` everything freezes (the jump effect too), so the screenshot
## tool's frame count only has to be larger than the steps needed.

@export var tap_step := 10
@export var charge_step := -1
@export var charge_steps := 150
@export var stop_step := 24

var game: Node
var car: CharacterBody2D
var _step := 0


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()
	game.run.state.grant_power_up("jump")
	car = game.run.car
	car.use_keyboard = false
	car.set_physics_process(false)
	process_mode = Node.PROCESS_MODE_ALWAYS
	game.run.jump_effect.set_process(false)  # advanced by hand, one step per frame, below


func _process(_delta: float) -> void:
	# A window that is not in focus pauses the run (game_flow.gd): undo it, the picture is of the world.
	if game.pause_screen != null and game.pause_screen.is_paused():
		game.pause_screen.toggle()
	if car == null or not is_instance_valid(car) or _step >= stop_step:
		return
	game.run.state.health = game.run.state.max_health
	if _step == tap_step:
		car.press_jump()
	if _step == charge_step:
		car.press_jump()
		car.scripted_jump_held = true
	if charge_step >= 0 and _step == charge_step + charge_steps:
		car.scripted_jump_held = false
	car.scripted_input = [false, false, 0.0]
	car.physics_step()
	game.run.jump_effect.advance(1.0 / 60.0)
	_step += 1
