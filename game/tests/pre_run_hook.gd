extends GutHookScript
## Runs once before the GUT suite (game/.gutconfig.json, pre_run_script):
## switches every dev setting off (scripts/run/dev_settings.gd), so the tests
## run the game as players get it, whatever data/playtest.json says.

const DevSettings := preload("res://scripts/run/dev_settings.gd")


func run() -> void:
	DevSettings.enabled = false
