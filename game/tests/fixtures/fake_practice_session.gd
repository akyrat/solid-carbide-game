extends Node2D
## Task T-562: a stand-in for T-561's practice session (scripts/run/practice_session.gd) with the
## same API the tutorial slides use, for the slides' tests: it records what the slides ask of it
## and the keys that reach its SubViewport. succeed() plays one success, as the real one does
## when its trick pays.

signal trick_counted(trick_id: String, done: int)
signal progress(done: int, goal: int)
signal completed

const GOAL := 3

var trick := ""
var setup_calls: Array = []
var running := false
var focused := false
var successes := 0
## Every fresh key press that reached this session's viewport (its _unhandled_input), by keycode.
var keys: Array = []


func setup(trick_name: String) -> void:
	trick = trick_name
	setup_calls.append(trick_name)
	successes = 0


func start() -> void:
	running = true


func pause() -> void:
	running = false


func is_running() -> bool:
	return running


func is_completed() -> bool:
	return successes >= GOAL


func set_focused(on: bool) -> void:
	focused = on


func succeed() -> void:
	if successes >= GOAL:
		return
	successes += 1
	trick_counted.emit(trick, successes)
	progress.emit(successes, GOAL)
	if successes == GOAL:
		completed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		keys.append((event as InputEventKey).keycode)
