class_name GameFlow
extends Node
## The screen flow (task T-055): the game's main scene. It opens on the main
## menu; Start begins a fresh run; when the run ends, win or loss, it goes
## straight back to the main menu with no message; Exit closes the game.
## Garage does nothing yet (task T-089 wires it to the garage screen).
## Game loop architecture, Decisions and Content.
##
## Only one screen exists at a time, as a child of this node: `menu` or `run`.
## During a run the pause screen (Escape) is a child of the run.

const MainMenuScene := preload("res://scenes/menu/main_menu.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const PauseScreenScript := preload("res://scripts/ui/pause_screen.gd")
const GameSettingsScript := preload("res://scripts/ui/game_settings.gd")

## Emitted after the main menu is shown (at launch and after every run).
signal menu_shown
## Emitted after a fresh run has started.
signal run_shown

## The main menu while it is on screen, otherwise null.
var menu: Control
## The run while one is on screen, otherwise null.
var run: Node2D
## The player's saved coins and upgrade levels (task T-057). A run's coins are banked
## into it when the run ends, win or loss.
var progress: PlayerProgress
## The run's pause screen, while a run is on screen.
var pause_screen: CanvasLayer
## What Exit does. Tests replace it so the test run is not closed.
var quit_game: Callable = func(): get_tree().quit()


func _ready() -> void:
	progress = PlayerProgress.new()
	show_menu()


## Shows the main menu, removing the run if there is one.
func show_menu() -> void:
	_clear_screens()
	menu = MainMenuScene.instantiate()
	menu.name = "MainMenu"
	add_child(menu)
	menu.start_pressed.connect(start_run)
	menu.exit_pressed.connect(_on_exit_pressed)
	# garage_pressed is left unconnected until the garage screen exists (T-089).
	menu_shown.emit()


## Replaces the main menu with a fresh run.
func start_run() -> void:
	_clear_screens()
	run = RunScene.instantiate()
	run.name = "Run"
	run.progress = progress  # the car health upgrade applies at the run's start (T-061)
	add_child(run)  # the run starts itself in _ready()
	run.car.tuning.apply_acceleration_upgrade(progress)  # garage upgrade (T-060)
	run.weapons.set_damage_bonus(progress.current_value("damage_bonus"))  # garage upgrade (T-062)
	run.set_zoom(GameSettingsScript.load_zoom())
	run.load_camera_options()  # smoothing and the dynamic camera (T-123)
	pause_screen = PauseScreenScript.new()
	pause_screen.name = "PauseScreenLayer"
	run.add_child(pause_screen)
	pause_screen.setup(run)
	progress.connect_run(run.state)  # banks the coins before the screen swaps
	run.state.run_ended.connect(_on_run_ended)
	run_shown.emit()


func _on_run_ended(_result: String, _coins: int) -> void:
	# The run ends from inside its own processing; swap screens afterwards.
	show_menu.call_deferred()


func _on_exit_pressed() -> void:
	quit_game.call()


func _clear_screens() -> void:
	get_tree().paused = false
	if menu != null:
		remove_child(menu)
		menu.queue_free()
		menu = null
	if run != null:
		remove_child(run)
		run.queue_free()
		run = null
		pause_screen = null
