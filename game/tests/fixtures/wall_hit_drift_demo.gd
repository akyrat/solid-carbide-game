extends "res://tests/fixtures/crash_pays_gif_demo.gd"
## Screenshot fixture (task T-438): crash_pays_gif_demo (a drift into a building's south face)
## with the tutorial slides off, so Start begins the run. It saves the viewport on the step
## of the hit (WALL_HIT_PNG) and popup_frame frames later (CRASH_PAYS_POPUP_PNG).

func _ready() -> void:
	GameFlow.tutorial_enabled = false
	await super._ready()
