class_name GameFlow
extends Node
## The screen flow (task T-055): the game's main scene. It opens on the main
## menu; Start begins a fresh run; when the run ends, win or loss, the recap
## screen shows the run's stats (T-320), and its Continue or X goes back to the main
## menu; Exit closes the game.
## Garage opens the garage screen (task T-089); its back button returns to the menu.
## Game loop architecture, Decisions and Content.
##
## The tutorial slides (T-387): the main menu's Start shows them first, unless the player
## ticked "Don't show again" (GameSettings tutorial_hidden); the slides' Start begins the run.
## The pause screen's Restart starts a fresh run directly, without the slides.
##
## Only one screen exists at a time, as a child of this node: `menu`, `garage`, `tutorial`,
## `run` or `recap`. During a run the pause screen (Escape) is a child of the run.

const MainMenuScene := preload("res://scenes/menu/main_menu.tscn")
const TutorialScene := preload("res://scenes/menu/tutorial_slides.tscn")
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
## Emitted after the tutorial slides are shown (T-387).
signal tutorial_shown

## Whether the main menu's Start can show the tutorial slides (T-387). Always true in the
## game; the test run turns it off (tests/helpers/pre_run.gd) so tests that only need a run
## get one from Start, and the tutorial's own tests turn it back on.
static var tutorial_enabled := true

## The main menu while it is on screen, otherwise null.
var menu: Control
## The tutorial slides while they are on screen, otherwise null (T-387).
var tutorial: TutorialSlides
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
	menu.start_pressed.connect(_on_menu_start)
	menu.exit_pressed.connect(_on_exit_pressed)
	menu.garage_pressed.connect(show_garage)
	menu_shown.emit()


## The main menu's Start (T-387): the tutorial slides first, unless they were hidden.
func _on_menu_start() -> void:
	if tutorial_enabled and not GameSettingsScript.load_tutorial_hidden():
		show_tutorial()
	else:
		start_run()


## Replaces the main menu with the tutorial slides (T-387). No run exists while they are up;
## their Start saves "Don't show again" when ticked, then begins the run.
func show_tutorial() -> void:
	_clear_screens()
	tutorial = TutorialScene.instantiate()
	tutorial.name = "TutorialSlides"
	add_child(tutorial)
	tutorial.start_pressed.connect(_on_tutorial_start)
	tutorial_shown.emit()


func _on_tutorial_start(dont_show_again: bool) -> void:
	if dont_show_again:
		GameSettingsScript.save_tutorial_hidden(true)
	start_run()


## Replaces the main menu with the garage screen (T-089).
func show_garage() -> void:
	_clear_screens()
	garage = GarageScene.instantiate()
	garage.name = "Garage"
	garage.progress = progress
	add_child(garage)
	garage.back_pressed.connect(show_menu)


## Replaces the screen on show with a fresh run, without the tutorial slides (the slides'
## Start, the main menu's Start when they are hidden, and the pause screen's Restart).
func start_run() -> void:
	_clear_screens()
	run = add_run(self, progress, "", history)
	pause_screen = run.get_node("PauseScreenLayer")
	run.state.run_ended.connect(_on_run_ended)
	pause_screen.restart_pressed.connect(_on_pause_restart)
	pause_screen.exit_pressed.connect(_on_pause_exit)
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
	r.hud.set_hud_size(GameSettingsScript.load_hud_size())  # the HUD size slider's value (T-431)
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


## Restart from the pause screen: cancels the run (board, 2026-10-30, T-416): its coins are
## lost, nothing goes into the runs list, no recap. Then a fresh run.
func _on_pause_restart() -> void:
	start_run()


## Exit from the pause screen: cancels the run the same way, then the main menu.
func _on_pause_exit() -> void:
	show_menu()


## The window's close request (T-416; Game loop architecture, Decisions, "Restart, Exit or
## closing cancels the run"): a run still going is cancelled, so its coins are lost and
## nothing goes into the runs list; the game just quits. Losing focus (switching to another
## window) pauses the run, except during the level-up choice and the time's up screen
## (toggle() refuses there) and once the run has ended.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game.call()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if run != null and run.state.result == "" and pause_screen != null and not pause_screen.is_paused():
			pause_screen.toggle()


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
	if tutorial != null:
		remove_child(tutorial)
		tutorial.queue_free()
		tutorial = null
	if recap != null:
		remove_child(recap)
		recap.queue_free()
		recap = null
	if run != null:
		remove_child(run)
		run.queue_free()
		run = null
		pause_screen = null
