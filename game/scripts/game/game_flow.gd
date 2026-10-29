class_name GameFlow
extends Node
## The screen flow (task T-055): the game's main scene. It opens on the main
## menu; Start begins a fresh run; when the run ends, win or loss, the recap
## screen shows the run's stats (T-320), and its Continue or X goes back to the main
## menu; Exit closes the game.
## Garage opens the garage screen (task T-089); its back button returns to the menu.
## Game loop architecture, Decisions and Content.
##
## Only one screen exists at a time, as a child of this node: `menu`, `garage`, `run` or `recap`.
## During a run the pause screen (Escape) is a child of the run.

const MainMenuScene := preload("res://scenes/menu/main_menu.tscn")
const GarageScene := preload("res://scenes/menu/garage_screen.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const RecapScene := preload("res://scenes/menu/recap_screen.tscn")
const PauseScreenScript := preload("res://scripts/ui/pause_screen.gd")
const TimeUpScreenScript := preload("res://scripts/ui/time_up_screen.gd")
const MusicPlayerScript := preload("res://scripts/game/music_player.gd")
const GameSettingsScript := preload("res://scripts/ui/game_settings.gd")

## Emitted after the main menu is shown (at launch and after every run).
signal menu_shown
## Emitted after a fresh run has started.
signal run_shown
## Emitted after the recap screen is shown (T-320).
signal recap_shown

## The main menu while it is on screen, otherwise null.
var menu: Control
## The garage screen while it is on screen, otherwise null.
var garage: Control
## The run while one is on screen, otherwise null.
var run: Node2D
## The recap screen while it is on screen, otherwise null (T-320).
var recap: RecapScreen
## The music, from launch to exit (task T-209). Not a screen.
var music: Node
## The player's saved coins and upgrade levels (task T-057). A run's coins are banked
## into it when the run ends, win or loss.
var progress: PlayerProgress
var history: RunHistory  # every finished run's recap stats (T-363)
## The run's pause screen, while a run is on screen.
var pause_screen: CanvasLayer
## What Exit does. Tests replace it so the test run is not closed.
var quit_game: Callable = func(): get_tree().quit()


func _ready() -> void:
	progress = PlayerProgress.new()
	history = RunHistory.new()
	# The music (T-209) is a child of this node, so it outlives every screen change.
	music = MusicPlayerScript.new()
	add_child(music)
	show_menu()


## Shows the main menu, removing the run if there is one.
func show_menu() -> void:
	_clear_screens()
	menu = MainMenuScene.instantiate()
	menu.name = "MainMenu"
	add_child(menu)
	menu.start_pressed.connect(start_run)
	menu.exit_pressed.connect(_on_exit_pressed)
	menu.garage_pressed.connect(show_garage)
	menu_shown.emit()


## Replaces the main menu with the garage screen (T-089).
func show_garage() -> void:
	_clear_screens()
	garage = GarageScene.instantiate()
	garage.name = "Garage"
	garage.progress = progress
	add_child(garage)
	garage.back_pressed.connect(show_menu)


## Replaces the main menu with a fresh run.
func start_run() -> void:
	_clear_screens()
	run = add_run(self, progress, "", history)
	pause_screen = run.get_node("PauseScreenLayer")
	run.state.run_ended.connect(_on_run_ended)
	run_shown.emit()


## Adds a fresh run under `parent`, set up as the game's own run: the garage upgrades from
## `progress`, the saved zoom and camera options, the pause screen (child "PauseScreenLayer"),
## the time's up screen (child "TimeUpScreenLayer", T-317),
## and the run's coins banked into `progress` when it ends. `layout_path`, when given, is the
## map file it plays (T-230); empty is the game's own map. The level creator's Play uses it
## too (T-239). The run starts itself when it enters the tree.
static func add_run(parent: Node, progress: PlayerProgress, layout_path: String = "", history: RunHistory = null) -> Node2D:
	var r: Node2D = RunScene.instantiate()
	r.name = "Run"
	if layout_path != "":
		r.layout_path = layout_path
	r.progress = progress  # the car health upgrade applies at the run's start (T-061)
	parent.add_child(r)  # the run starts itself in _ready()
	r.car.tuning.apply_acceleration_upgrade(progress)  # garage upgrade (T-060)
	r.car.tuning.apply_air_turn_upgrade(progress)  # garage upgrade (T-270)
	r.weapons.set_damage_bonus(progress.current_value("damage_bonus"))  # garage upgrade (T-062)
	r.set_zoom(GameSettingsScript.load_zoom())
	r.load_camera_options()  # smoothing and the dynamic camera (T-123)
	var ps: CanvasLayer = PauseScreenScript.new()
	ps.name = "PauseScreenLayer"
	r.add_child(ps)
	ps.setup(r)
	# The time's up screen (T-317): plays over the frozen run when the timer runs out.
	var tu: CanvasLayer = TimeUpScreenScript.new()
	tu.name = "TimeUpScreenLayer"
	r.add_child(tu)
	tu.bind(r.state)
	progress.connect_run(r.state)  # banks the coins before the screen swaps
	if history != null:
		history.connect_run(r.state)  # saves the run's recap (T-363)
	return r


## Replaces the screen on show with the recap of `summary` (a RunState.recap(),
## T-319); its Continue and X go to the main menu (T-320).
func show_recap(summary: Dictionary) -> void:
	_clear_screens()
	recap = RecapScene.instantiate()
	recap.name = "Recap"
	add_child(recap)
	recap.show_summary(summary)
	recap.closed.connect(show_menu)
	recap_shown.emit()


func _on_run_ended(_result: String, _coins: int) -> void:
	# The run ends from inside its own processing; swap screens afterwards. The
	# summary is read now (it stays readable after run_ended) for the recap (T-320).
	show_recap.call_deferred(run.state.recap())


func _on_exit_pressed() -> void:
	quit_game.call()


func _clear_screens() -> void:
	get_tree().paused = false
	if menu != null:
		remove_child(menu)
		menu.queue_free()
		menu = null
	if garage != null:
		remove_child(garage)
		garage.queue_free()
		garage = null
	if recap != null:
		remove_child(recap)
		recap.queue_free()
		recap = null
	if run != null:
		remove_child(run)
		run.queue_free()
		run = null
		pause_screen = null
